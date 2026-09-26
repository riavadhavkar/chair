// Small hand-picked station lookup for demo/wiring purposes (L train, a few
// Manhattan/Brooklyn stops). Coordinates are approximate (fine for a
// schematic mini-map, not survey-grade) and the stop_ids below have NOT been
// re-verified against MTA's authoritative static GTFS feed.
//
// Before relying on this for anything beyond local testing, replace it with
// data pulled from MTA's canonical static GTFS bundle:
//   https://rrgtfsfeeds.s3.amazonaws.com/google_transit.zip
// (stops.txt in that archive has the authoritative stop_id -> name/lat/lon
// mapping used by the realtime feeds' StopTimeUpdate.stopId values, which
// are usually the stop_id + "N" or "S" for direction.)
const STATIONS = {
  L01: { name: "8 Av", lat: 40.7402, lon: -74.0021 },
  L02: { name: "6 Av", lat: 40.7377, lon: -73.9968 },
  L03: { name: "14 St - Union Sq", lat: 40.7357, lon: -73.9903 },
  L04: { name: "3 Av", lat: 40.7328, lon: -73.9862 },
  L05: { name: "1 Av", lat: 40.7307, lon: -73.9816 },
  L08: { name: "Bedford Av", lat: 40.7174, lon: -73.9566 }
};

/// Strips a trailing direction suffix ("N"/"S") some feed fields include.
function baseStopId(stopId) {
  return stopId.replace(/[NS]$/, "");
}

function stationFor(stopId) {
  return STATIONS[baseStopId(stopId)] ?? null;
}

module.exports = { STATIONS, stationFor, baseStopId };
