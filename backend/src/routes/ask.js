const express = require("express");
const { nearbyProductions } = require("../services/productionsService");
const { DEFAULT_CENTER, DEFAULT_RADIUS_METERS, neighborhoodIn } = require("../config/area");
const { blocksAway } = require("../lib/geo");
const { formatClock } = require("../lib/nyTime");

const router = express.Router();

function replyFor(production, place) {
  if (!production) return `Nothing is filming near ${place.label ?? "you"} right now.`;
  const what = production.match?.title ?? production.titleHint ?? `A ${(production.subcategory ?? "production").toLowerCase()}`;
  const until = production.endsAt ? ` until ${formatClock(new Date(production.endsAt))}` : "";
  const blocks = blocksAway(production.distanceMeters);
  return `${what} is filming on ${production.location.display}${until}, about ${blocks} block${blocks === 1 ? "" : "s"} from ${place.label ?? "you"}.`;
}

// POST /ask { "text": "anything shooting in SoHo?", "lat"?: n, "lon"?: n }
// The single entry point the Photon iMessage handler and the ElevenLabs call
// script both use, so every front-end answers from the same pipeline.
router.post("/ask", express.json(), async (req, res) => {
  const { text, lat, lon } = req.body ?? {};
  const place =
    neighborhoodIn(text) ??
    (Number.isFinite(lat) && Number.isFinite(lon) ? { lat, lon, label: null } : DEFAULT_CENTER);

  try {
    const [top] = await nearbyProductions({ center: place, radiusMeters: DEFAULT_RADIUS_METERS, limit: 1 });
    res.json({ reply: replyFor(top, place), production: top ?? null });
  } catch (error) {
    console.error("POST /ask failed:", error);
    res.status(502).json({ reply: "I can't reach the city's film permit data right now.", production: null });
  }
});

module.exports = { router };
