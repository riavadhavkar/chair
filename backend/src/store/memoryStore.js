const fs = require("fs");
const { distanceMeters, boundingBox, hasCoordinates } = require("../lib/geo");

/// Zero-setup store for local dev and tests. Spots can be seeded from the JSON
/// file the import script writes; check-ins and walks live only in memory.
function createMemoryStore({ spotsFile } = {}) {
  const spots = new Map();
  const checkins = new Map(); // spotID -> Map(deviceID -> Date)
  const walks = new Map();

  if (spotsFile && fs.existsSync(spotsFile)) {
    for (const spot of JSON.parse(fs.readFileSync(spotsFile, "utf8"))) {
      spots.set(spot.id, { ...spot, lastFilmed: spot.lastFilmed ? new Date(spot.lastFilmed) : null });
    }
  }

  return {
    kind: "memory",
    async replaceSpots(list) {
      spots.clear();
      for (const spot of list) spots.set(spot.id, spot);
    },
    async upsertSpot(spot) {
      spots.set(spot.id, { ...spots.get(spot.id), ...spot });
    },
    async getSpot(id) {
      return spots.get(id) ?? null;
    },
    async collectibleSpots() {
      return [...spots.values()].filter((s) => s.collectible);
    },
    async spotsByIds(ids) {
      return ids.map((id) => spots.get(id)).filter(Boolean);
    },
    async spotsNear(center, meters) {
      const box = boundingBox(center, meters);
      return [...spots.values()].filter(
        (s) =>
          hasCoordinates(s) &&
          s.lat >= box.minLat &&
          s.lat <= box.maxLat &&
          s.lon >= box.minLon &&
          s.lon <= box.maxLon &&
          distanceMeters(center, s) <= meters
      );
    },
    async visitorCounts(ids) {
      return new Map(ids.map((id) => [id, checkins.get(id)?.size ?? 0]));
    },
    async collectedAt(deviceID) {
      const result = new Map();
      for (const [spotID, devices] of checkins) {
        if (devices.has(deviceID)) result.set(spotID, devices.get(deviceID));
      }
      return result;
    },
    async addCheckIn({ spotID, deviceID, at }) {
      if (!checkins.has(spotID)) checkins.set(spotID, new Map());
      const devices = checkins.get(spotID);
      if (devices.has(deviceID)) return { created: false, at: devices.get(deviceID) };
      devices.set(deviceID, at);
      return { created: true, at };
    },
    async saveWalk(walk) {
      walks.set(walk.id, walk);
    },
    async getWalk(id) {
      return walks.get(id) ?? null;
    }
  };
}

module.exports = { createMemoryStore };
