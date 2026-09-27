const crypto = require("crypto");
const express = require("express");
const { parseSegments, spotIdFor, blockText } = require("./lib/blocks");
const { distanceMeters, hasCoordinates } = require("./lib/geo");
const { isoSeconds } = require("./lib/nyTime");
const { neighborhoodFor } = require("./config/neighborhoods");
const { newSpot } = require("./services/spots");
const { planWalk, STOPS_FOR_MINUTES } = require("./services/walks");
const { fallbackSymbol } = require("./services/symbols");

const DEVICE_ID = /^[A-Za-z0-9-]{8,64}$/;
const GEOCODE_CONCURRENCY = 8;

function parsePoint(source) {
  const lat = Number(source?.lat);
  const lon = Number(source?.lon);
  return Number.isFinite(lat) && Number.isFinite(lon) && Math.abs(lat) <= 90 && Math.abs(lon) <= 180 ? { lat, lon } : null;
}

function validDeviceID(value) {
  return typeof value === "string" && DEVICE_ID.test(value) ? value : null;
}

function spotJSON(spot, visitorCount, collectedAt) {
  return {
    id: spot.id,
    name: spot.name,
    crossStreets: spot.crossStreets ?? null,
    neighborhood: spot.neighborhood,
    symbol: spot.symbol ?? fallbackSymbol(spot.lastCategory),
    lat: spot.lat,
    lon: spot.lon,
    timesFilmed: spot.timesFilmed,
    lastFilmed: isoSeconds(spot.lastFilmed ? new Date(spot.lastFilmed) : null),
    lastCategory: spot.lastCategory ?? null,
    visitorCount: visitorCount ?? 0,
    collectedAt: isoSeconds(collectedAt ? new Date(collectedAt) : null)
  };
}

async function mapLimited(items, limit, fn) {
  const results = [];
  for (let i = 0; i < items.length; i += limit) {
    results.push(...(await Promise.all(items.slice(i, i + limit).map(fn))));
  }
  return results;
}

function createApp({
  store,
  permits = require("./services/permits"),
  geocoder = require("./services/geocoder"),
  gemini = require("./services/gemini"),
  tts = require("./services/elevenlabs"),
  config = {}
}) {
  const borough = config.borough ?? process.env.TODAY_BOROUGH ?? "Manhattan";
  const checkInRadius = config.checkInRadiusMeters ?? Number(process.env.CHECKIN_RADIUS_METERS ?? 150);
  const narrationCache = new Map();

  const app = express();
  app.use(express.json({ limit: "10kb" }));
  const route = (handler) => (req, res, next) => handler(req, res).catch(next);

  async function withCoordinates(spot) {
    if (hasCoordinates(spot)) return spot;
    const point = await geocoder.geocodeSegment(spot, spot.borough ?? borough);
    if (!point) return spot;
    const located = { ...spot, ...point };
    await store.upsertSpot(located);
    return located;
  }

  async function presentSpots(spots, deviceID) {
    const ids = spots.map((s) => s.id);
    const [counts, collected] = await Promise.all([
      store.visitorCounts(ids),
      deviceID ? store.collectedAt(deviceID) : new Map()
    ]);
    return spots.map((s) => spotJSON(s, counts.get(s.id), collected.get(s.id)));
  }

  app.get("/health", (_req, res) => res.json({ ok: true, store: store.kind }));

  // GET /today?lat=&lon=&radius= — permits filming today, nearest first when a location is given.
  app.get(
    "/today",
    route(async (req, res) => {
      const center = parsePoint(req.query);
      const radius = Math.min(Number(req.query.radius) || 1600, 10000);
      const todays = await permits.todaysPermits({ borough });

      const shoots = await mapLimited(todays, GEOCODE_CONCURRENCY, async (permit) => {
        const segment = parseSegments(permit.parkingHeld)[0];
        if (!segment) return null;
        let spot = await store.getSpot(spotIdFor(segment));
        if (!spot) {
          spot = {
            ...newSpot(segment, permit.borough),
            neighborhood: neighborhoodFor(permit.zipCodes, permit.borough),
            timesFilmed: 1,
            lastFilmed: permit.startsAt,
            lastCategory: permit.category
          };
        }
        spot = await withCoordinates(spot);
        if (!hasCoordinates(spot)) return null;
        return {
          id: permit.id,
          spotID: spot.id,
          block: blockText(segment),
          category: permit.category,
          subcategory: permit.subcategory,
          startsAt: isoSeconds(permit.startsAt),
          endsAt: isoSeconds(permit.endsAt),
          lat: spot.lat,
          lon: spot.lon,
          distance: center ? distanceMeters(center, spot) : null
        };
      });

      const result = shoots
        .filter(Boolean)
        .filter((s) => s.distance === null || s.distance <= radius)
        .sort((a, b) => (a.distance ?? 0) - (b.distance ?? 0) || (a.startsAt ?? "").localeCompare(b.startsAt ?? ""))
        .map(({ distance, ...shoot }) => shoot);
      res.json(result);
    })
  );

  // GET /collection?deviceID= — the collectible blocks, plus any other block this device checked in at.
  app.get(
    "/collection",
    route(async (req, res) => {
      const deviceID = validDeviceID(req.query.deviceID);
      const collectible = await store.collectibleSpots();
      const collected = deviceID ? await store.collectedAt(deviceID) : new Map();
      const known = new Set(collectible.map((s) => s.id));
      const extras = await store.spotsByIds([...collected.keys()].filter((id) => !known.has(id)));
      res.json(await presentSpots([...collectible, ...extras], deviceID));
    })
  );

  // GET /spots/:id?deviceID=
  app.get(
    "/spots/:id",
    route(async (req, res) => {
      const spot = await store.getSpot(req.params.id);
      if (!spot) return res.status(404).json({ error: "not_found" });
      const [json] = await presentSpots([await withCoordinates(spot)], validDeviceID(req.query.deviceID));
      res.json(json);
    })
  );

  // POST /checkins { spotID, deviceID, lat, lon }
  // 201 new check-in · 409 already collected (same body) · 422 too far / unlocatable.
  app.post(
    "/checkins",
    route(async (req, res) => {
      const deviceID = validDeviceID(req.body?.deviceID);
      const point = parsePoint(req.body);
      const spotID = typeof req.body?.spotID === "string" ? req.body.spotID : null;
      if (!deviceID || !point || !spotID) return res.status(400).json({ error: "bad_request" });

      const stored = await store.getSpot(spotID);
      if (!stored) return res.status(404).json({ error: "not_found" });
      const spot = await withCoordinates(stored);
      if (!hasCoordinates(spot)) return res.status(422).json({ error: "spot_unlocated" });

      const distance = Math.round(distanceMeters(point, spot));
      if (distance > checkInRadius) return res.status(422).json({ error: "too_far", distanceMeters: distance });

      const { created, at } = await store.addCheckIn({ spotID, deviceID, at: new Date() });
      const counts = await store.visitorCounts([spotID]);
      res.status(created ? 201 : 409).json({
        spotID,
        visitorCount: counts.get(spotID),
        collectedAt: isoSeconds(new Date(at))
      });
    })
  );

  // POST /walks { lat, lon, minutes: 15|30|45, deviceID? }
  app.post(
    "/walks",
    route(async (req, res) => {
      const center = parsePoint(req.body);
      const minutes = Number(req.body?.minutes);
      if (!center || !STOPS_FOR_MINUTES[minutes]) return res.status(400).json({ error: "bad_request" });

      const plan = await planWalk({ store, generateText: gemini.generateText, center, minutes });
      if (!plan) return res.status(404).json({ error: "not_enough_spots" });

      const walk = {
        id: crypto.randomUUID(),
        minutes,
        stopIDs: plan.stops.map((s) => s.id),
        narrationText: plan.narrationText,
        createdAt: new Date()
      };
      await store.saveWalk(walk);
      res.json({
        id: walk.id,
        minutes,
        stops: await presentSpots(plan.stops, validDeviceID(req.body?.deviceID)),
        narrationText: walk.narrationText
      });
    })
  );

  // GET /walks/:id/narration — ElevenLabs MP3 of the walk's narration.
  app.get(
    "/walks/:id/narration",
    route(async (req, res) => {
      const walk = await store.getWalk(req.params.id);
      if (!walk) return res.status(404).json({ error: "not_found" });
      if (!tts.isConfigured()) return res.status(503).json({ error: "narration_unavailable" });
      if (!narrationCache.has(walk.id)) narrationCache.set(walk.id, await tts.synthesize(walk.narrationText));
      res.type("audio/mpeg").send(narrationCache.get(walk.id));
    })
  );

  app.use((error, _req, res, _next) => {
    console.error(error);
    res.status(502).json({ error: "upstream_unavailable" });
  });

  return app;
}

module.exports = { createApp };
