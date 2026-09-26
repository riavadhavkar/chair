const { MongoClient } = require("mongodb");

// Key/value cache for geocodes, TMDB matches and enriched productions.
// Uses MongoDB Atlas when MONGODB_URI is set, otherwise an in-process Map,
// so local dev works with zero setup.
let clientPromise = null;
const memory = new Map();

function collection() {
  const uri = process.env.MONGODB_URI;
  if (!uri) return null;
  if (!clientPromise) clientPromise = new MongoClient(uri).connect();
  return clientPromise.then((client) =>
    client.db(process.env.MONGODB_DB_NAME || "setWatch").collection("cache")
  );
}

/// Returns `undefined` on a miss so callers can cache a real `null` ("we looked, nothing matched").
async function cacheGet(key) {
  if (memory.has(key)) return memory.get(key);
  const coll = await collection()?.catch(() => null);
  if (!coll) return undefined;
  const doc = await coll.findOne({ _id: key }).catch(() => null);
  if (!doc) return undefined;
  memory.set(key, doc.value);
  return doc.value;
}

async function cacheSet(key, value) {
  memory.set(key, value);
  const coll = await collection()?.catch(() => null);
  if (!coll) return;
  await coll
    .updateOne({ _id: key }, { $set: { value, updatedAt: new Date() } }, { upsert: true })
    .catch((error) => console.error("Mongo cacheSet failed:", error.message));
}

module.exports = { cacheGet, cacheSet };
