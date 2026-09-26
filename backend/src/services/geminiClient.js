const crypto = require("crypto");

const CACHE_TTL_MS = 30 * 60 * 1000; // 30 min
const cache = new Map(); // sha256(text) -> { text, cachedAt }

function hashOf(text) {
  return crypto.createHash("sha256").update(text).digest("hex");
}

/// Rewrites a raw MTA alert into one plain-language sentence, caching by
/// text hash so repeated identical alerts don't re-hit the API. Falls back
/// to the raw text (rather than failing the request) if no key is
/// configured or the call errors.
async function plainLanguageSummary(rawText) {
  if (!rawText) return null;

  const key = hashOf(rawText);
  const hit = cache.get(key);
  if (hit && Date.now() - hit.cachedAt < CACHE_TTL_MS) {
    return hit.text;
  }

  const apiKey = process.env.GEMINI_API_KEY;
  if (!apiKey) {
    return rawText;
  }

  const model = process.env.GEMINI_MODEL || "gemini-2.5-flash";
  const url = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`;
  const prompt =
    "Rewrite this NYC subway service alert as one short, plain-language sentence a rider would " +
    `understand at a glance. Do not add information that isn't in the alert.\n\nAlert: ${rawText}`;

  try {
    const response = await fetch(url, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ contents: [{ parts: [{ text: prompt }] }] }),
      signal: AbortSignal.timeout(8000)
    });

    if (!response.ok) {
      console.error(`Gemini request failed: ${response.status} ${await response.text()}`);
      return rawText;
    }

    const data = await response.json();
    const summary = data.candidates?.[0]?.content?.parts?.[0]?.text?.trim() || rawText;
    cache.set(key, { text: summary, cachedAt: Date.now() });
    return summary;
  } catch (error) {
    console.error("Gemini request errored:", error);
    return rawText;
  }
}

module.exports = { plainLanguageSummary };
