const express = require("express");
const { nearbyProductions } = require("../services/productionsService");
const { DEFAULT_CENTER, DEFAULT_RADIUS_METERS } = require("../config/area");
const { isoSeconds } = require("../lib/nyTime");

const router = express.Router();

function centerFrom(query) {
  const lat = Number(query.lat);
  const lon = Number(query.lon);
  if (Number.isFinite(lat) && Number.isFinite(lon)) return { lat, lon, label: query.label ?? null };
  return DEFAULT_CENTER;
}

// GET /nearby?lat=40.74&lon=-73.99&radius=1500
router.get("/nearby", async (req, res) => {
  const center = centerFrom(req.query);
  const radius = Number(req.query.radius);
  const radiusMeters = Number.isFinite(radius) && radius > 0 ? Math.min(radius, 5000) : DEFAULT_RADIUS_METERS;

  try {
    const productions = await nearbyProductions({ center, radiusMeters });
    res.json({ generatedAt: isoSeconds(new Date()), center, radiusMeters, productions });
  } catch (error) {
    console.error("GET /nearby failed:", error);
    res.status(502).json({ error: "Film permit data unavailable." });
  }
});

module.exports = { router };
