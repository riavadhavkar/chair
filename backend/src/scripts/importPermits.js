// One-time (re)import: every film permit since IMPORT_SINCE -> one spot per street
// block -> mark each neighborhood's most-filmed blocks collectible -> geocode those.
// Writes data/spots.json (used by the in-memory store) and, when MONGODB_URI is
// set, replaces the `spots` collection. Check-ins are never touched.
//
//   npm run import                      # Manhattan since 2012
//   IMPORT_SINCE=2024-01-01 npm run import
require("dotenv").config();
const fs = require("fs");
const path = require("path");
const { allPermits } = require("../services/permits");
const { aggregateSpots, markCollectible } = require("../services/spots");
const geocoder = require("../services/geocoder");
const { createMongoStore } = require("../store/mongoStore");
const { SPOTS_FILE } = require("../store");

const SINCE = process.env.IMPORT_SINCE || "2012-01-01";
const BOROUGH = process.env.IMPORT_BOROUGH || "Manhattan";
const PER_NEIGHBORHOOD = Number(process.env.SPOTS_PER_NEIGHBORHOOD || 12);
const GEOCACHE_FILE = path.join(path.dirname(SPOTS_FILE), "geocache.json");

async function main() {
  fs.mkdirSync(path.dirname(SPOTS_FILE), { recursive: true });

  const permits = [];
  for await (const page of allPermits({ since: SINCE, borough: BOROUGH })) {
    permits.push(...page);
    console.log(`Fetched ${permits.length} permits…`);
  }

  const spots = aggregateSpots(permits);
  const collectible = markCollectible(spots, PER_NEIGHBORHOOD);
  console.log(`${spots.length} blocks, ${collectible.length} collectible.`);

  if (fs.existsSync(GEOCACHE_FILE)) geocoder.importCache(JSON.parse(fs.readFileSync(GEOCACHE_FILE, "utf8")));
  let located = 0;
  for (let i = 0; i < collectible.length; i += 4) {
    await Promise.all(
      collectible.slice(i, i + 4).map(async (spot) => {
        const point = await geocoder.geocodeSegment(spot, spot.borough ?? BOROUGH);
        if (point) {
          Object.assign(spot, point);
          located += 1;
        }
      })
    );
    process.stdout.write(`\rGeocoded ${Math.min(i + 4, collectible.length)}/${collectible.length}`);
  }
  console.log(`\n${located}/${collectible.length} collectible blocks located.`);
  fs.writeFileSync(GEOCACHE_FILE, JSON.stringify(geocoder.exportCache()));

  fs.writeFileSync(SPOTS_FILE, JSON.stringify(spots));
  console.log(`Wrote ${SPOTS_FILE}`);

  if (process.env.MONGODB_URI) {
    const store = await createMongoStore({ uri: process.env.MONGODB_URI, dbName: process.env.MONGODB_DB_NAME || "setWatch" });
    await store.replaceSpots(spots);
    console.log("Replaced the spots collection in MongoDB.");
  }
  process.exit(0);
}

main().catch((error) => {
  console.error("Import failed:", error);
  process.exit(1);
});
