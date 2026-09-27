// Each collectible block gets an SF Symbol that evokes the street itself.
// Gemini picks from this fixed list (so the app never gets a symbol name that
// doesn't exist); anything else falls back to an icon for the last shoot's category.
const ALLOWED_SYMBOLS = [
  "building.2", "building.columns", "house", "storefront", "tree", "leaf", "camera.macro",
  "cup.and.saucer", "fork.knife", "wineglass", "birthday.cake", "takeoutbag.and.cup.and.straw",
  "music.note", "guitars", "pianokeys", "books.vertical", "paintpalette", "theatermasks",
  "camera", "film", "tv", "bag", "cart", "hanger", "tshirt", "scissors", "eyeglasses",
  "tram", "bus", "car", "bicycle", "ferry", "sailboat", "figure.walk", "pawprint", "fish",
  "drop", "flame", "umbrella", "sun.max", "moon.stars", "sparkles", "star", "heart", "crown",
  "flag", "key", "trophy", "gift", "balloon", "graduationcap", "cross.case", "dumbbell",
  "globe.americas", "signpost.right", "lightbulb", "bell", "clock", "newspaper", "briefcase"
];

const CATEGORY_SYMBOLS = {
  television: "tv",
  film: "film",
  commercial: "megaphone",
  theater: "theatermasks",
  "still photography": "camera",
  student: "graduationcap",
  documentary: "video",
  "music video": "music.note"
};

const allowed = new Set(ALLOWED_SYMBOLS);

function fallbackSymbol(category) {
  return CATEGORY_SYMBOLS[(category ?? "").toLowerCase()] ?? "movieclapper";
}

/// Gemini sometimes wraps JSON in ```json fences; accept either.
function parseJSONObject(text) {
  const match = /\{[\s\S]*\}/.exec(text ?? "");
  if (!match) return {};
  try {
    return JSON.parse(match[0]);
  } catch {
    return {};
  }
}

function symbolsPrompt(batch) {
  return (
    "Each item below is a street block in New York City. For each, pick ONE SF Symbol name from ALLOWED that " +
    "evokes the street or block itself — its character, landmarks, businesses, history or neighborhood feel. " +
    "Do not base it on any TV show or movie. Vary your picks. Reply with ONLY a JSON object mapping id to symbol.\n\n" +
    `ALLOWED: ${ALLOWED_SYMBOLS.join(", ")}\n\n` +
    batch.map((s) => `${s.id}: ${s.name} (${s.crossStreets}), ${s.neighborhood}`).join("\n")
  );
}

/// Sets `symbol` on every spot. Batches keep prompts small; failures fall back per spot.
async function assignSymbols(spots, generateText, batchSize = 30) {
  for (let i = 0; i < spots.length; i += batchSize) {
    const batch = spots.slice(i, i + batchSize);
    const picks = parseJSONObject(await generateText(symbolsPrompt(batch)));
    for (const spot of batch) {
      spot.symbol = allowed.has(picks[spot.id]) ? picks[spot.id] : fallbackSymbol(spot.lastCategory);
    }
  }
  return spots;
}

module.exports = { assignSymbols, fallbackSymbol, ALLOWED_SYMBOLS };
