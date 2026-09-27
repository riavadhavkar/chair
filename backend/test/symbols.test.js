const test = require("node:test");
const assert = require("node:assert/strict");
const { assignSymbols, fallbackSymbol } = require("../src/services/symbols");

const spots = () => [
  { id: "a", name: "Bleecker St", crossStreets: "x", neighborhood: "West Village", lastCategory: "Television" },
  { id: "b", name: "Perry St", crossStreets: "y", neighborhood: "West Village", lastCategory: "Film" },
  { id: "c", name: "Bank St", crossStreets: "z", neighborhood: "West Village", lastCategory: "Commercial" }
];

test("keeps allowed picks, falls back for unknown or missing ones", async () => {
  const reply = '```json\n{"a": "guitars", "b": "not.a.symbol"}\n```';
  const [a, b, c] = await assignSymbols(spots(), async () => reply);
  assert.equal(a.symbol, "guitars");
  assert.equal(b.symbol, "film");
  assert.equal(c.symbol, "megaphone");
});

test("without Gemini every spot gets its category icon", async () => {
  const result = await assignSymbols(spots(), async () => null);
  assert.deepEqual(result.map((s) => s.symbol), ["tv", "film", "megaphone"]);
  assert.equal(fallbackSymbol(null), "movieclapper");
});
