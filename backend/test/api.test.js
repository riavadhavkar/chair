const test = require("node:test");
const assert = require("node:assert/strict");
const { createApp } = require("../src/app");
const { createMemoryStore } = require("../src/store/memoryStore");

const DEVICE = "11111111-2222-3333-4444-555555555555";
const OTHER_DEVICE = "99999999-2222-3333-4444-555555555555";
const PERRY = { lat: 40.7355, lon: -74.0035 };

function spot(overrides) {
  return {
    id: "perry",
    street: "PERRY STREET",
    from: "BLEECKER STREET",
    to: "WEST 4 STREET",
    borough: "Manhattan",
    name: "Perry St",
    crossStreets: "Bleecker St – W 4 St",
    neighborhood: "West Village",
    timesFilmed: 63,
    lastFilmed: new Date("2026-03-01T12:00:00Z"),
    lastCategory: "Television",
    ...PERRY,
    collectible: true,
    ...overrides
  };
}

async function startServer({ spots = [spot()], todays = [], tts } = {}) {
  const store = createMemoryStore();
  await store.replaceSpots(spots);
  const app = createApp({
    store,
    permits: { todaysPermits: async () => todays },
    geocoder: { geocodeSegment: async (segment) => (segment.street.startsWith("PERRY") ? PERRY : { lat: 40.74, lon: -73.99 }) },
    gemini: { generateText: async () => "Narration." },
    tts: tts ?? { isConfigured: () => false, synthesize: async () => Buffer.from("") }
  });
  const server = app.listen(0);
  await new Promise((resolve) => server.once("listening", resolve));
  const base = `http://127.0.0.1:${server.address().port}`;
  const call = async (method, path, body) => {
    const response = await fetch(base + path, {
      method,
      headers: body ? { "Content-Type": "application/json" } : {},
      body: body ? JSON.stringify(body) : undefined
    });
    const type = response.headers.get("content-type") ?? "";
    return { status: response.status, body: type.includes("json") ? await response.json() : await response.arrayBuffer() };
  };
  return { call, close: () => server.close(), store };
}

test("check-in: too far, then success, then duplicate", async (t) => {
  const { call, close } = await startServer();
  t.after(close);

  const far = await call("POST", "/checkins", { spotID: "perry", deviceID: DEVICE, lat: 40.75, lon: -74.0 });
  assert.equal(far.status, 422);
  assert.equal(far.body.error, "too_far");

  const ok = await call("POST", "/checkins", { spotID: "perry", deviceID: DEVICE, ...PERRY });
  assert.equal(ok.status, 201);
  assert.equal(ok.body.visitorCount, 1);
  assert.match(ok.body.collectedAt, /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$/);

  const again = await call("POST", "/checkins", { spotID: "perry", deviceID: DEVICE, ...PERRY });
  assert.equal(again.status, 409);
  assert.equal(again.body.visitorCount, 1);

  const other = await call("POST", "/checkins", { spotID: "perry", deviceID: OTHER_DEVICE, ...PERRY });
  assert.equal(other.body.visitorCount, 2);
});

test("check-in rejects bad input", async (t) => {
  const { call, close } = await startServer();
  t.after(close);
  assert.equal((await call("POST", "/checkins", { spotID: "perry", deviceID: "x", ...PERRY })).status, 400);
  assert.equal((await call("POST", "/checkins", { spotID: "nope", deviceID: DEVICE, ...PERRY })).status, 404);
});

test("collection shows counts and this device's collected date", async (t) => {
  const { call, close } = await startServer({ spots: [spot(), spot({ id: "bank", name: "Bank St", street: "BANK STREET" })] });
  t.after(close);
  await call("POST", "/checkins", { spotID: "perry", deviceID: DEVICE, ...PERRY });

  const mine = await call("GET", `/collection?deviceID=${DEVICE}`);
  const perry = mine.body.find((s) => s.id === "perry");
  assert.equal(perry.visitorCount, 1);
  assert.ok(perry.collectedAt);
  assert.equal(mine.body.find((s) => s.id === "bank").collectedAt, null);

  const theirs = await call("GET", `/collection?deviceID=${OTHER_DEVICE}`);
  assert.equal(theirs.body.find((s) => s.id === "perry").collectedAt, null);
});

test("today turns permits into shoots, nearest first", async (t) => {
  const todays = [
    {
      id: "p1",
      category: "Television",
      subcategory: "Episodic series",
      borough: "Manhattan",
      zipCodes: ["10014"],
      parkingHeld: "PERRY STREET between WEST 4 STREET and BLEECKER STREET",
      startsAt: new Date("2026-09-26T11:00:00Z"),
      endsAt: new Date("2026-09-27T01:00:00Z")
    },
    {
      id: "p2",
      category: "Film",
      borough: "Manhattan",
      zipCodes: ["10011"],
      parkingHeld: "WEST 20 STREET between 5 AVENUE and 6 AVENUE",
      startsAt: new Date("2026-09-26T10:00:00Z"),
      endsAt: new Date("2026-09-26T22:00:00Z")
    }
  ];
  const { call, close } = await startServer({ spots: [], todays });
  t.after(close);
  const res = await call("GET", `/today?lat=${PERRY.lat}&lon=${PERRY.lon}&radius=5000`);
  assert.equal(res.status, 200);
  assert.equal(res.body.length, 2);
  assert.equal(res.body[0].block, "Perry St between Bleecker St & W 4 St");
  assert.ok(res.body[0].spotID);

  const spotRes = await call("GET", `/spots/${res.body[0].spotID}`);
  assert.equal(spotRes.status, 200);
  assert.equal(spotRes.body.neighborhood, "West Village");
});

test("walks: plan, then narration is 503 without ElevenLabs", async (t) => {
  const spots = [
    spot(),
    spot({ id: "bank", name: "Bank St", street: "BANK STREET", lat: 40.7365, lon: -74.005, timesFilmed: 40 }),
    spot({ id: "grove", name: "Grove St", street: "GROVE STREET", lat: 40.7335, lon: -74.0045, timesFilmed: 30 })
  ];
  const { call, close } = await startServer({ spots });
  t.after(close);

  const walk = await call("POST", "/walks", { ...PERRY, minutes: 15 });
  assert.equal(walk.status, 200);
  assert.equal(walk.body.stops.length, 3);
  assert.equal(walk.body.narrationText, "Narration.");

  const audio = await call("GET", `/walks/${walk.body.id}/narration`);
  assert.equal(audio.status, 503);

  assert.equal((await call("POST", "/walks", { ...PERRY, minutes: 20 })).status, 400);
  assert.equal((await call("POST", "/walks", { lat: 40.8, lon: -73.95, minutes: 15 })).status, 404);
});
