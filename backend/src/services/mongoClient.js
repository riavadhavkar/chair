const { MongoClient } = require("mongodb");

let clientPromise = null;

/// Lazily connects on first use; returns null (rather than throwing) when
/// MONGODB_URI isn't configured, so history/trend features degrade
/// gracefully instead of taking down the whole /status endpoint.
function getClient() {
  const uri = process.env.MONGODB_URI;
  if (!uri) return null;
  if (!clientPromise) {
    clientPromise = new MongoClient(uri).connect();
  }
  return clientPromise;
}

function collectionFor(client) {
  const dbName = process.env.MONGODB_DB_NAME || "transitTracker";
  return client.db(dbName).collection("delaySnapshots");
}

async function recordSnapshot({ line, station, delayMinutes }) {
  const client = await getClient();
  if (!client) return;

  await collectionFor(client).insertOne({
    line,
    station,
    delayMinutes,
    recordedAt: new Date()
  });
}

async function delayedCountToday({ line, station }) {
  const client = await getClient();
  if (!client) return null;

  const startOfDay = new Date();
  startOfDay.setHours(0, 0, 0, 0);

  return collectionFor(client).countDocuments({
    line,
    station,
    delayMinutes: { $gt: 0 },
    recordedAt: { $gte: startOfDay }
  });
}

module.exports = { recordSnapshot, delayedCountToday };
