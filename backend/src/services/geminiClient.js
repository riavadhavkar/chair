const crypto = require("crypto");
const { formatClock } = require("../lib/nyTime");

const CACHE_TTL_MS = 6 * 60 * 60 * 1000;
const cache = new Map();

function hashOf(text) {
  return crypto.createHash("sha256").update(text).digest("hex");
}

/// Deterministic sentence used when Gemini is unconfigured or fails — the UI
/// always gets something readable, never raw permit legalese.
function templateSummary({ permit, match, title, location }) {
  const what = match?.title ?? title ?? `A ${(permit.subcategory ?? permit.category ?? "production").toLowerCase()}`;
  const until = permit.endsAt ? ` until ${formatClock(permit.endsAt)}` : " today";
  return `${what} is filming on ${location}${until}.`;
}

/// One plain sentence describing the shoot. The prompt only contains fields we
/// actually have, and forbids inventing anything (cast sightings, scenes, etc.).
async function summarizeProduction({ permit, match, title, location }) {
  const fallback = templateSummary({ permit, match, title, location });
  const apiKey = process.env.GEMINI_API_KEY;
  if (!apiKey) return fallback;

  const facts = {
    title: match?.title ?? title ?? null,
    genres: match?.genres ?? [],
    category: permit.category,
    subcategory: permit.subcategory,
    location,
    rawStreetHolds: permit.parkingHeld,
    endsAt: permit.endsAt ? formatClock(permit.endsAt) : null
  };
  const prompt =
    "Write ONE short, friendly sentence (max 25 words) telling a New Yorker what is filming near them, " +
    "using only these facts from a city film permit. Do not invent cast, scenes, or anything not listed. " +
    "If title is null, describe it by category (e.g. 'A TV series').\n\n" +
    JSON.stringify(facts);

  const key = hashOf(prompt);
  const hit = cache.get(key);
  if (hit && Date.now() - hit.at < CACHE_TTL_MS) return hit.text;

  const model = process.env.GEMINI_MODEL || "gemini-2.5-flash";
  const url = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent`;
  try {
    const response = await fetch(url, {
      method: "POST",
      headers: { "Content-Type": "application/json", "x-goog-api-key": apiKey },
      body: JSON.stringify({ contents: [{ parts: [{ text: prompt }] }] }),
      signal: AbortSignal.timeout(8000)
    });
    if (!response.ok) {
      console.error(`Gemini request failed: ${response.status}`);
      return fallback;
    }
    const data = await response.json();
    const text = data.candidates?.[0]?.content?.parts?.[0]?.text?.trim() || fallback;
    cache.set(key, { text, at: Date.now() });
    return text;
  } catch (error) {
    console.error("Gemini request errored:", error.message);
    return fallback;
  }
}

module.exports = { summarizeProduction };
