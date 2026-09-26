const EARTH_RADIUS_METERS = 6371000;
// A Manhattan north–south block is ~80 m; close enough for "N blocks away" copy.
const METERS_PER_BLOCK = 80;

function distanceMeters(a, b) {
  const toRad = (deg) => (deg * Math.PI) / 180;
  const dLat = toRad(b.lat - a.lat);
  const dLon = toRad(b.lon - a.lon);
  const h = Math.sin(dLat / 2) ** 2 + Math.cos(toRad(a.lat)) * Math.cos(toRad(b.lat)) * Math.sin(dLon / 2) ** 2;
  return 2 * EARTH_RADIUS_METERS * Math.asin(Math.sqrt(h));
}

function blocksAway(meters) {
  return Math.max(1, Math.round(meters / METERS_PER_BLOCK));
}

function appleMapsWalkingURL({ lat, lon }) {
  return `https://maps.apple.com/?daddr=${lat},${lon}&dirflg=w`;
}

module.exports = { distanceMeters, blocksAway, appleMapsWalkingURL };
