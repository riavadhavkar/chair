const { cacheGet, cacheSet } = require("./mongoClient");

// NYC Planning Labs GeoSearch (keyless, NYC-only Pelias). Verify at
// https://geosearch.planninglabs.nyc before the demo.
const GEOSEARCH_URL = process.env.GEOSEARCH_URL || "https://geosearch.planninglabs.nyc/v2/search";

const ABBREVIATIONS = [
  [/\bWEST\b/g, "W"],
  [/\bEAST\b/g, "E"],
  [/\bNORTH\b/g, "N"],
  [/\bSOUTH\b/g, "S"],
  [/\bSTREET\b/g, "St"],
  [/\bAVENUE\b/g, "Av"],
  [/\bBOULEVARD\b/g, "Blvd"],
  [/\bPLACE\b/g, "Pl"],
  [/\bROAD\b/g, "Rd"],
  [/\bDRIVE\b/g, "Dr"]
];

/// "WEST 20 STREET between 5 AVENUE and 6 AVENUE, ..." -> first segment's parts.
function parseFirstSegment(parkingHeld) {
  const first = (parkingHeld ?? "").split(",")[0].trim();
  const match = /^(.+?)\s+between\s+(.+?)\s+and\s+(.+)$/i.exec(first);
  if (!match) return first ? { street: first, from: null, to: null } : null;
  return { street: match[1].trim(), from: match[2].trim(), to: match[3].trim() };
}

function titleCaseStreet(raw) {
  let text = raw.toUpperCase();
  for (const [pattern, replacement] of ABBREVIATIONS) text = text.replace(pattern, replacement);
  return text
    .toLowerCase()
    .replace(/\b([a-z])/g, (c) => c.toUpperCase())
    .replace(/\b(\d+)(St|Av)\b/g, "$1 $2");
}

/// Short, human label for the UI: "W 20 St between 5 & 6 Av".
function displayLocation(parkingHeld) {
  const segment = parseFirstSegment(parkingHeld);
  if (!segment) return "Various locations";
  const street = titleCaseStreet(segment.street);
  if (!segment.from) return street;
  const from = titleCaseStreet(segment.from);
  const to = titleCaseStreet(segment.to);
  const sameSuffix = from.split(" ").pop() === to.split(" ").pop();
  return sameSuffix
    ? `${street} between ${from.replace(/ \w+$/, "")} & ${to}`
    : `${street} between ${from} & ${to}`;
}

async function geosearch(text) {
  const url = new URL(GEOSEARCH_URL);
  url.searchParams.set("text", text);
  url.searchParams.set("size", "1");
  const response = await fetch(url, { signal: AbortSignal.timeout(6000) });
  if (!response.ok) return null;
  const coordinates = (await response.json()).features?.[0]?.geometry?.coordinates;
  return coordinates ? { lat: coordinates[1], lon: coordinates[0] } : null;
}

/// Best-effort point for a permit: the first held block's first intersection,
/// then the street itself, else null (the UI shows "various locations").
async function geocodePermit({ parkingHeld, borough }) {
  const segment = parseFirstSegment(parkingHeld);
  if (!segment) return { lat: null, lon: null, precision: "unknown" };

  const attempts = [];
  if (segment.from) attempts.push({ query: `${segment.street} and ${segment.from}, ${borough ?? "New York"}`, precision: "intersection" });
  attempts.push({ query: `${segment.street}, ${borough ?? "New York"}`, precision: "street" });

  for (const { query, precision } of attempts) {
    const cacheKey = `geo:${query.toLowerCase()}`;
    const cached = await cacheGet(cacheKey);
    if (cached !== undefined) {
      if (cached) return { ...cached, precision };
      continue;
    }
    const point = await geosearch(query).catch(() => null);
    await cacheSet(cacheKey, point);
    if (point) return { ...point, precision };
  }
  return { lat: null, lon: null, precision: "unknown" };
}

module.exports = { geocodePermit, displayLocation };
