const titleHints = require("../config/titleHints.json");
const { DEMO_BOROUGH } = require("../config/area");
const { fetchActivePermits } = require("./permitsClient");
const { geocodePermit, displayLocation } = require("./geocoder");
const { matchTitle } = require("./tmdbClient");
const { summarizeProduction } = require("./geminiClient");
const { cacheGet, cacheSet } = require("./mongoClient");
const { distanceMeters, appleMapsWalkingURL } = require("../lib/geo");
const { isoSeconds } = require("../lib/nyTime");

const ENRICH_CONCURRENCY = 5;

/// Permits carry no title. A title only exists if someone curated it for this
/// event id (titleHints.json) — never guessed from the permit text.
function titleHintFor(permitId) {
  return titleHints.byEventId?.[permitId]?.title ?? null;
}

async function enrich(permit) {
  const cacheKey = `production:${permit.id}`;
  const cached = await cacheGet(cacheKey);
  if (cached) return cached;

  const location = displayLocation(permit.parkingHeld);
  const point = await geocodePermit(permit);
  const titleHint = titleHintFor(permit.id);
  const match = await matchTitle(titleHint).catch((error) => {
    console.error(`TMDB match failed for ${permit.id}:`, error.message);
    return null;
  });
  const summary = await summarizeProduction({ permit, match, title: titleHint, location });

  const production = {
    id: permit.id,
    category: permit.category,
    subcategory: permit.subcategory,
    borough: permit.borough,
    startsAt: isoSeconds(permit.startsAt),
    endsAt: isoSeconds(permit.endsAt),
    location: { raw: permit.parkingHeld, display: location, lat: point.lat, lon: point.lon, precision: point.precision },
    titleHint,
    match,
    summary,
    directionsURL: point.lat != null ? appleMapsWalkingURL(point) : null
  };
  await cacheSet(cacheKey, production);
  return production;
}

async function mapLimited(items, limit, fn) {
  const results = [];
  for (let i = 0; i < items.length; i += limit) {
    results.push(...(await Promise.all(items.slice(i, i + limit).map(fn))));
  }
  return results;
}

async function allActiveProductions() {
  const permits = await fetchActivePermits({ borough: DEMO_BOROUGH });
  return mapLimited(permits, ENRICH_CONCURRENCY, (permit) =>
    enrich(permit).catch((error) => {
      console.error(`Enrich failed for ${permit.id}:`, error.message);
      return null;
    })
  ).then((list) => list.filter(Boolean));
}

/// Productions filming right now within `radiusMeters` of `center`, nearest first.
async function nearbyProductions({ center, radiusMeters, limit = 10 }) {
  const publicBase = process.env.PUBLIC_BASE_URL?.replace(/\/$/, "");
  const all = await allActiveProductions();
  return all
    .filter((p) => p.location.lat != null)
    .map((p) => ({
      ...p,
      distanceMeters: Math.round(distanceMeters(center, { lat: p.location.lat, lon: p.location.lon })),
      shareURL: publicBase ? `${publicBase}/go/${encodeURIComponent(p.id)}` : null
    }))
    .filter((p) => p.distanceMeters <= radiusMeters)
    .sort((a, b) => Number(Boolean(b.match)) - Number(Boolean(a.match)) || a.distanceMeters - b.distanceMeters)
    .slice(0, limit);
}

async function productionById(id) {
  const all = await allActiveProductions();
  return all.find((p) => p.id === id) ?? null;
}

module.exports = { nearbyProductions, productionById, allActiveProductions };
