const { nowAsNyFloating, nyLocalToDate } = require("../lib/nyTime");

// NYC Open Data "Film Permits" (Mayor's Office of Media and Entertainment).
// Verify the dataset id / column names at https://data.cityofnewyork.us/d/tg4x-b46p
// before the demo. NOTE: this dataset has no production-title column — titles come
// from config/titleHints.json (see productionsService).
const DATASET_URL = process.env.FILM_PERMITS_URL || "https://data.cityofnewyork.us/resource/tg4x-b46p.json";
const CACHE_TTL_MS = 10 * 60 * 1000;

let cache = { key: null, at: 0, permits: [] };

async function fetchActivePermits({ borough }) {
  const now = nowAsNyFloating();
  const key = `${borough}|${now.slice(0, 15)}`;
  if (cache.key === key && Date.now() - cache.at < CACHE_TTL_MS) return cache.permits;

  const where = [`startdatetime <= '${now}'`, `enddatetime >= '${now}'`];
  if (borough) where.push(`borough = '${borough.replace(/'/g, "''")}'`);

  const url = new URL(DATASET_URL);
  url.searchParams.set("$where", where.join(" AND "));
  url.searchParams.set("$limit", "500");
  url.searchParams.set("$order", "startdatetime DESC");

  const headers = {};
  if (process.env.NYC_OPEN_DATA_APP_TOKEN) headers["X-App-Token"] = process.env.NYC_OPEN_DATA_APP_TOKEN;

  const response = await fetch(url, { headers, signal: AbortSignal.timeout(10000) });
  if (!response.ok) throw new Error(`Film permits request failed: ${response.status}`);

  const permits = (await response.json()).map(normalizePermit).filter((p) => p.id);
  cache = { key, at: Date.now(), permits };
  return permits;
}

function normalizePermit(row) {
  return {
    id: String(row.eventid ?? ""),
    eventType: row.eventtype ?? null,
    category: row.category ?? null,
    subcategory: row.subcategoryname ?? null,
    borough: row.borough ?? null,
    zipCodes: (row.zipcode_s ?? "").split(",").map((z) => z.trim()).filter(Boolean),
    parkingHeld: row.parkingheld ?? "",
    startsAt: nyLocalToDate(row.startdatetime),
    endsAt: nyLocalToDate(row.enddatetime)
  };
}

module.exports = { fetchActivePermits };
