const path = require("path");
const { createMemoryStore } = require("./memoryStore");
const { createMongoStore } = require("./mongoStore");

const SPOTS_FILE = path.join(__dirname, "../../data/spots.json");

async function createStore() {
  if (process.env.MONGODB_URI) {
    return createMongoStore({ uri: process.env.MONGODB_URI, dbName: process.env.MONGODB_DB_NAME || "setWatch" });
  }
  console.warn("MONGODB_URI not set: using the in-memory store (check-ins are lost on restart).");
  return createMemoryStore({ spotsFile: SPOTS_FILE });
}

module.exports = { createStore, SPOTS_FILE };
