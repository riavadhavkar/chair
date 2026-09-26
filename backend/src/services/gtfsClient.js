const GtfsRealtimeBindings = require("gtfs-realtime-bindings");
const { feedURLForLine } = require("../config/feeds");
const { baseStopId } = require("../config/stations");

const CACHE_TTL_MS = 20_000;
const cache = new Map(); // feed URL -> { fetchedAt, feedMessage }

/// protobufjs decodes int64 fields as Long objects (from the "long" package)
/// rather than plain numbers; normalize both cases to a JS number.
function toNumber(value) {
  if (value == null) return null;
  if (typeof value === "number") return value;
  if (typeof value.toNumber === "function") return value.toNumber();
  return Number(value);
}

async function fetchFeed(url) {
  const response = await fetch(url, { signal: AbortSignal.timeout(8000) });
  if (!response.ok) {
    throw new Error(`Feed request failed: ${response.status} ${response.statusText}`);
  }
  const buffer = Buffer.from(await response.arrayBuffer());
  return GtfsRealtimeBindings.transit_realtime.FeedMessage.decode(buffer);
}

async function getFeedForLine(line) {
  const url = feedURLForLine(line);
  if (!url) throw new Error(`Unknown line: ${line}`);

  const cached = cache.get(url);
  if (cached && Date.now() - cached.fetchedAt < CACHE_TTL_MS) {
    return cached.feedMessage;
  }

  const feedMessage = await fetchFeed(url);
  cache.set(url, { fetchedAt: Date.now(), feedMessage });
  return feedMessage;
}

/// Finds the soonest future arrival for `line` at `stopId` across all trip
/// updates in the feed. Returns null if nothing matches (e.g. no service, or
/// the stopId doesn't exist in this feed group).
function nextArrivalForStop(feedMessage, line, stopId) {
  const nowSeconds = Date.now() / 1000;
  let best = null;

  for (const entity of feedMessage.entity) {
    const tripUpdate = entity.tripUpdate;
    if (!tripUpdate?.trip) continue;
    if ((tripUpdate.trip.routeId ?? "").toUpperCase() !== line.toUpperCase()) continue;

    for (const stopTimeUpdate of tripUpdate.stopTimeUpdate ?? []) {
      if (baseStopId(stopTimeUpdate.stopId ?? "") !== baseStopId(stopId)) continue;

      const event = stopTimeUpdate.arrival ?? stopTimeUpdate.departure;
      const arrivalUnix = toNumber(event?.time);
      if (arrivalUnix == null || arrivalUnix < nowSeconds) continue;

      if (!best || arrivalUnix < best.arrivalUnix) {
        best = {
          arrivalUnix,
          delaySeconds: toNumber(event?.delay) ?? 0,
          tripId: tripUpdate.trip.tripId
        };
      }
    }
  }

  return best;
}

module.exports = { getFeedForLine, nextArrivalForStop };
