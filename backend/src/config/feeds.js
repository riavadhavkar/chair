// MTA public GTFS-realtime feed endpoints, grouped the same way MTA groups them.
// These are keyless as of MTA's current open-data policy. Verify at
// https://api.mta.info/#/subwayRealTimeFeeds before deploying, in case the
// endpoints have moved since this was written.
const FEED_BASE = "https://api-endpoint.mta.info/Dataservice/mtagtfsfeeds";

const LINE_TO_FEED_GROUP = {
  "1": "gtfs", "2": "gtfs", "3": "gtfs", "4": "gtfs", "5": "gtfs", "6": "gtfs", "6X": "gtfs", "S": "gtfs", "GS": "gtfs",
  "7": "gtfs-7", "7X": "gtfs-7",
  A: "gtfs-ace", C: "gtfs-ace", E: "gtfs-ace",
  B: "gtfs-bdfm", D: "gtfs-bdfm", F: "gtfs-bdfm", M: "gtfs-bdfm", FS: "gtfs-bdfm",
  G: "gtfs-g",
  J: "gtfs-jz", Z: "gtfs-jz",
  L: "gtfs-l",
  N: "gtfs-nqrw", Q: "gtfs-nqrw", R: "gtfs-nqrw", W: "gtfs-nqrw",
  SIR: "gtfs-si"
};

function feedURLForLine(line) {
  const group = LINE_TO_FEED_GROUP[line.toUpperCase()];
  if (!group) return null;
  return `${FEED_BASE}/nyct%2F${group}`;
}

const ALERTS_FEED_URL = `${FEED_BASE}/camsys%2Fall-alerts`;

module.exports = { LINE_TO_FEED_GROUP, feedURLForLine, ALERTS_FEED_URL };
