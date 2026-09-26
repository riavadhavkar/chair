const { displayStreet } = require("../lib/blocks");

// Two keyless-or-free NYC geocoders:
// - NYC Geoclient (free key from api-portal.nyc.gov) has a real intersection endpoint. Preferred.
// - NYC Planning Labs GeoSearch (keyless) is the fallback; it handles intersections less reliably.
const GEOCLIENT_URL = "https://api.nyc.gov/geo/geoclient/v2/intersection.json";
const GEOSEARCH_URL = process.env.GEOSEARCH_URL || "https://geosearch.planninglabs.nyc/v2/search";

const cache = new Map();

async function geoclientIntersection(street, cross, borough) {
  const url = new URL(GEOCLIENT_URL);
  url.searchParams.set("crossStreetOne", street);
  url.searchParams.set("crossStreetTwo", cross);
  url.searchParams.set("borough", borough ?? "Manhattan");
  const response = await fetch(url, {
    headers: { "Ocp-Apim-Subscription-Key": process.env.NYC_GEOCLIENT_KEY },
    signal: AbortSignal.timeout(8000)
  });
  if (!response.ok) return null;
  const intersection = (await response.json()).intersection ?? {};
  const lat = Number(intersection.latitude);
  const lon = Number(intersection.longitude);
  return Number.isFinite(lat) && Number.isFinite(lon) ? { lat, lon } : null;
}

async function geosearchIntersection(street, cross, borough) {
  const url = new URL(GEOSEARCH_URL);
  url.searchParams.set("text", `${displayStreet(street)} & ${displayStreet(cross)}, ${borough ?? "Manhattan"}`);
  url.searchParams.set("size", "1");
  const response = await fetch(url, { signal: AbortSignal.timeout(8000) });
  if (!response.ok) return null;
  const coordinates = (await response.json()).features?.[0]?.geometry?.coordinates;
  return coordinates ? { lat: coordinates[1], lon: coordinates[0] } : null;
}

async function intersection(street, cross, borough) {
  const key = `${street}|${cross}|${borough}`;
  if (cache.has(key)) return cache.get(key);
  const lookup = process.env.NYC_GEOCLIENT_KEY ? geoclientIntersection : geosearchIntersection;
  const point = await lookup(street, cross, borough).catch(() => null);
  cache.set(key, point);
  return point;
}

/// The middle of a block: the average of its two end intersections (or whichever one resolved).
async function geocodeSegment(segment, borough) {
  const ends = (
    await Promise.all([intersection(segment.street, segment.from, borough), intersection(segment.street, segment.to, borough)])
  ).filter(Boolean);
  if (ends.length === 0) return null;
  return {
    lat: ends.reduce((sum, p) => sum + p.lat, 0) / ends.length,
    lon: ends.reduce((sum, p) => sum + p.lon, 0) / ends.length
  };
}

function exportCache() {
  return Object.fromEntries(cache);
}

function importCache(entries) {
  for (const [key, value] of Object.entries(entries ?? {})) cache.set(key, value);
}

module.exports = { geocodeSegment, exportCache, importCache };
