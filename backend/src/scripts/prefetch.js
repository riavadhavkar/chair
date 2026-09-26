// Warms the cache (Mongo if configured) with today's enriched productions so
// the live demo never depends on a cold TMDB/Gemini/geocoder chain.
require("dotenv").config();
const { allActiveProductions } = require("../services/productionsService");

allActiveProductions()
  .then((productions) => {
    const located = productions.filter((p) => p.location.lat != null).length;
    const matched = productions.filter((p) => p.match).length;
    console.log(`Cached ${productions.length} active permits (${located} located, ${matched} TMDB-matched).`);
    process.exit(0);
  })
  .catch((error) => {
    console.error("Prefetch failed:", error);
    process.exit(1);
  });
