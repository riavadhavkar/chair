const { cacheGet, cacheSet } = require("./mongoClient");

const API_BASE = "https://api.themoviedb.org/3";
const IMAGE_BASE = "https://image.tmdb.org/t/p";

function authorize(url) {
  const headers = { Accept: "application/json" };
  if (process.env.TMDB_READ_TOKEN) {
    headers.Authorization = `Bearer ${process.env.TMDB_READ_TOKEN}`;
  } else if (process.env.TMDB_API_KEY) {
    url.searchParams.set("api_key", process.env.TMDB_API_KEY);
  } else {
    return null;
  }
  return headers;
}

async function get(path, params = {}) {
  const url = new URL(`${API_BASE}${path}`);
  for (const [k, v] of Object.entries(params)) url.searchParams.set(k, v);
  const headers = authorize(url);
  if (!headers) return null;
  const response = await fetch(url, { headers, signal: AbortSignal.timeout(6000) });
  if (!response.ok) throw new Error(`TMDB ${path} failed: ${response.status}`);
  return response.json();
}

function normalizeTitle(title) {
  return (title ?? "")
    .toLowerCase()
    .replace(/^the\s+/, "")
    .replace(/[^a-z0-9]+/g, " ")
    .trim();
}

/// Only exact (normalized) title matches count. A fuzzy "closest result" would
/// happily put the wrong poster on a working title, which is worse than no poster.
async function matchTitle(title) {
  if (!title) return null;
  const cacheKey = `tmdb:${normalizeTitle(title)}`;
  const cached = await cacheGet(cacheKey);
  if (cached !== undefined) return cached;

  const search = await get("/search/multi", { query: title, include_adult: "false" });
  if (!search) return null;

  const wanted = normalizeTitle(title);
  const hit = (search.results ?? []).find(
    (r) => (r.media_type === "tv" || r.media_type === "movie") && normalizeTitle(r.name ?? r.title) === wanted
  );
  if (!hit) {
    await cacheSet(cacheKey, null);
    return null;
  }

  const details = await get(`/${hit.media_type}/${hit.id}`, { append_to_response: "credits" });
  const match = {
    source: "tmdb",
    tmdbId: hit.id,
    mediaType: hit.media_type,
    title: details.name ?? details.title,
    year: Number((details.first_air_date ?? details.release_date ?? "").slice(0, 4)) || null,
    overview: details.overview || null,
    genres: (details.genres ?? []).map((g) => g.name),
    cast: (details.credits?.cast ?? []).slice(0, 4).map((c) => c.name),
    posterURL: details.poster_path ? `${IMAGE_BASE}/w500${details.poster_path}` : null,
    backdropURL: details.backdrop_path ? `${IMAGE_BASE}/w780${details.backdrop_path}` : null
  };
  await cacheSet(cacheKey, match);
  return match;
}

module.exports = { matchTitle };
