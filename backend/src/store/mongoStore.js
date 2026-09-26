const { MongoClient } = require("mongodb");
const { distanceMeters, boundingBox } = require("../lib/geo");

/// MongoDB Atlas store. Collections:
///   spots    — one doc per street block (_id = spot id)
///   checkins — { spotID, deviceID, at }, unique on (spotID, deviceID)
///   walks    — generated walks, so narration can be fetched later
async function createMongoStore({ uri, dbName }) {
  const client = await new MongoClient(uri).connect();
  const db = client.db(dbName);
  const spots = db.collection("spots");
  const checkins = db.collection("checkins");
  const walks = db.collection("walks");

  await Promise.all([
    checkins.createIndex({ spotID: 1, deviceID: 1 }, { unique: true }),
    checkins.createIndex({ deviceID: 1 }),
    spots.createIndex({ collectible: 1 }),
    spots.createIndex({ lat: 1, lon: 1 })
  ]);

  const fromDoc = (doc) => {
    if (!doc) return null;
    const { _id, ...rest } = doc;
    return { id: _id, ...rest };
  };
  const toDoc = ({ id, ...rest }) => ({ _id: id, ...rest });

  return {
    kind: "mongo",
    async replaceSpots(list) {
      await spots.deleteMany({});
      for (let i = 0; i < list.length; i += 1000) {
        await spots.insertMany(list.slice(i, i + 1000).map(toDoc), { ordered: false });
      }
    },
    async upsertSpot(spot) {
      const { _id, ...fields } = toDoc(spot);
      await spots.updateOne({ _id }, { $set: fields }, { upsert: true });
    },
    async getSpot(id) {
      return fromDoc(await spots.findOne({ _id: id }));
    },
    async collectibleSpots() {
      return (await spots.find({ collectible: true }).toArray()).map(fromDoc);
    },
    async spotsByIds(ids) {
      return (await spots.find({ _id: { $in: ids } }).toArray()).map(fromDoc);
    },
    async spotsNear(center, meters) {
      const box = boundingBox(center, meters);
      const docs = await spots
        .find({ lat: { $gte: box.minLat, $lte: box.maxLat }, lon: { $gte: box.minLon, $lte: box.maxLon } })
        .toArray();
      return docs.map(fromDoc).filter((s) => distanceMeters(center, s) <= meters);
    },
    async visitorCounts(ids) {
      const rows = await checkins
        .aggregate([{ $match: { spotID: { $in: ids } } }, { $group: { _id: "$spotID", count: { $sum: 1 } } }])
        .toArray();
      const counts = new Map(ids.map((id) => [id, 0]));
      for (const row of rows) counts.set(row._id, row.count);
      return counts;
    },
    async collectedAt(deviceID) {
      const rows = await checkins.find({ deviceID }).toArray();
      return new Map(rows.map((row) => [row.spotID, row.at]));
    },
    async addCheckIn({ spotID, deviceID, at }) {
      try {
        await checkins.insertOne({ spotID, deviceID, at });
        return { created: true, at };
      } catch (error) {
        if (error.code !== 11000) throw error;
        const existing = await checkins.findOne({ spotID, deviceID });
        return { created: false, at: existing.at };
      }
    },
    async saveWalk(walk) {
      await walks.insertOne(toDoc(walk));
    },
    async getWalk(id) {
      return fromDoc(await walks.findOne({ _id: id }));
    }
  };
}

module.exports = { createMongoStore };
