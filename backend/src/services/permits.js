const { nowAsNyFloating, nyLocalToDate } = require("../lib/nyTime");

// NYC Open Data "Film Permits" (Mayor's Office of Media and Entertainment).
// https://data.cityofnewyork.us/d/tg4x-b46p — one row per permit, no production title.
const DATASET_URL = process.env.FILM_PERMITS_URL || "https://data.cityofnewyork.us/resource/tg4x-b46p.json";
const FIELDS = "eventid,startdatetime,enddatetime,category,subcategoryname,borough,zipcode_s,parkingheld";
const PAGE_SIZE = 50000;
const TODAY_CACHE_MS = 10 * 60 * 1000;

function quote(value) {
  return `'${String(value).replace(/'/g, "''")}'`;
}

async function fetchPage({ where, limit, offset = 0 }) {
  const url = new URL(DATASET_URL);
  url.searchParams.set("$select", FIELDS);
  url.searchParams.set("$where", where);
  url.searchParams.set("$order", "eventid");
  url.searchParams.set("$limit", String(limit));
  url.searchParams.set("$offset", String(offset));

  const headers = {};
  if (process.env.NYC_OPEN_DATA_APP_TOKEN) headers["X-App-Token"] = process.env.NYC_OPEN_DATA_APP_TOKEN;

  const response = await fetch(url, { headers, signal: AbortSignal.timeout(60000) });
  if (!response.ok) throw new Error(`Film permits request failed: ${response.status}`);
  return (await response.json()).map(normalizePermit).filter((p) => p.id);
}

function normalizePermit(row) {
  return {
    id: String(row.eventid ?? ""),
    category: row.category ?? null,
    subcategory: row.subcategoryname ?? null,
    borough: row.borough ?? null,
    zipCodes: String(row.zipcode_s ?? "")
      .split(/[,\s]+/)
      .filter(Boolean),
    parkingHeld: row.parkingheld ?? "",
    startsAt: nyLocalToDate(row.startdatetime),
    endsAt: nyLocalToDate(row.enddatetime)
  };
}

/// Every permit since `since` (YYYY-MM-DD), paged. Used by the one-time import.
async function* allPermits({ since, borough }) {
  const clauses = [`startdatetime >= ${quote(`${since}T00:00:00`)}`];
  if (borough) clauses.push(`borough = ${quote(borough)}`);
  const where = clauses.join(" AND ");
  for (let offset = 0; ; offset += PAGE_SIZE) {
    const page = await fetchPage({ where, limit: PAGE_SIZE, offset });
    yield page;
    if (page.length < PAGE_SIZE) return;
  }
}

let todayCache = { key: null, at: 0, permits: [] };

/// Permits still running now or starting later today (NYC time).
async function todaysPermits({ borough }) {
  const now = nowAsNyFloating();
  const key = `${borough}|${now.slice(0, 10)}`;
  if (todayCache.key === key && Date.now() - todayCache.at < TODAY_CACHE_MS) return todayCache.permits;

  const clauses = [`startdatetime <= ${quote(`${now.slice(0, 10)}T23:59:59`)}`, `enddatetime >= ${quote(now)}`];
  if (borough) clauses.push(`borough = ${quote(borough)}`);
  const permits = await fetchPage({ where: clauses.join(" AND "), limit: 1000 });
  todayCache = { key, at: Date.now(), permits };
  return permits;
}

module.exports = { allPermits, todaysPermits, normalizePermit };
