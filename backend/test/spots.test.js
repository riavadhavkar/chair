const test = require("node:test");
const assert = require("node:assert/strict");
const { parseSegments, spotIdFor, blockText, displayStreet } = require("../src/lib/blocks");
const { aggregateSpots, markCollectible } = require("../src/services/spots");
const { orderLoop, pickStops, templateNarration } = require("../src/services/walks");

const permit = (overrides) => ({
  id: "1",
  category: "Television",
  borough: "Manhattan",
  zipCodes: ["10014"],
  parkingHeld: "PERRY STREET between BLEECKER STREET and WEST 4 STREET",
  startsAt: new Date("2024-03-01T12:00:00Z"),
  ...overrides
});

test("parses every held block and treats cross-street order as the same block", () => {
  const a = parseSegments("WEST 20 STREET between 5 AVENUE and 6 AVENUE, 5 AVENUE between WEST 19 STREET and WEST 20 STREET");
  assert.equal(a.length, 2);
  const [b] = parseSegments("west 20 street between 6 avenue and 5 avenue");
  assert.equal(spotIdFor(a[0]), spotIdFor(b));
  assert.deepEqual(parseSegments("VARIOUS LOCATIONS"), []);
});

test("formats streets for display", () => {
  assert.equal(displayStreet("WEST 20 STREET"), "W 20 St");
  assert.equal(blockText(parseSegments("WEST 20 STREET between 5 AVENUE and 6 AVENUE")[0]), "W 20 St between 5 Av & 6 Av");
});

test("aggregates times filmed, last shoot and neighborhood per block", () => {
  const spots = aggregateSpots([
    permit({ id: "1", startsAt: new Date("2023-01-01T12:00:00Z"), category: "Film" }),
    permit({ id: "2", startsAt: new Date("2025-06-01T12:00:00Z"), category: "Television" }),
    permit({ id: "3", parkingHeld: "BANK STREET between GREENWICH STREET and WASHINGTON STREET" })
  ]);
  const perry = spots.find((s) => s.name === "Perry St");
  assert.equal(perry.timesFilmed, 2);
  assert.equal(perry.lastCategory, "Television");
  assert.equal(perry.neighborhood, "West Village");
  assert.equal(perry.crossStreets, "Bleecker St – W 4 St");
});

test("a permit holding the same block twice counts once", () => {
  const [spot] = aggregateSpots([
    permit({ parkingHeld: "PERRY STREET between BLEECKER STREET and WEST 4 STREET, PERRY STREET between WEST 4 STREET and BLEECKER STREET" })
  ]);
  assert.equal(spot.timesFilmed, 1);
});

test("collectible = top blocks per neighborhood, one per street", () => {
  const spots = [
    { id: "a", street: "PERRY", name: "Perry St", neighborhood: "West Village", timesFilmed: 50 },
    { id: "b", street: "PERRY", name: "Perry St", neighborhood: "West Village", timesFilmed: 40 },
    { id: "c", street: "BANK", name: "Bank St", neighborhood: "West Village", timesFilmed: 30 },
    { id: "d", street: "GROVE", name: "Grove St", neighborhood: "West Village", timesFilmed: 10 },
    { id: "e", street: "W 20", name: "W 20 St", neighborhood: "Chelsea", timesFilmed: 5 }
  ];
  const ids = markCollectible(spots, 2).map((s) => s.id).sort();
  assert.deepEqual(ids, ["a", "c", "e"]);
});

test("walk picks the most-filmed stops and orders them as a nearest-neighbor loop", () => {
  const start = { lat: 40.735, lon: -74.0 };
  const candidates = [
    { id: "far", name: "Far", timesFilmed: 90, lat: 40.745, lon: -74.0 },
    { id: "near", name: "Near", timesFilmed: 80, lat: 40.736, lon: -74.0 },
    { id: "mid", name: "Mid", timesFilmed: 70, lat: 40.74, lon: -74.0 },
    { id: "skip", name: "Skip", timesFilmed: 1, lat: 40.735, lon: -74.0 }
  ];
  const ordered = orderLoop(start, pickStops(candidates, 3));
  assert.deepEqual(ordered.map((s) => s.id), ["near", "mid", "far"]);
});

test("template narration never invents a title", () => {
  const text = templateNarration(30, [
    { name: "Perry St", crossStreets: "Bleecker St – W 4 St", neighborhood: "West Village", timesFilmed: 12, lastFilmed: null }
  ]);
  assert.match(text, /Perry St/);
  assert.match(text, /Filmed 12 times since 2012/);
});
