// MVP scope: one borough, one default center. Override via env for the demo venue.
const DEFAULT_CENTER = {
  lat: Number(process.env.DEFAULT_LAT ?? 40.7397),
  lon: Number(process.env.DEFAULT_LON ?? -73.9925),
  label: process.env.DEFAULT_LABEL ?? "Chelsea"
};

const DEMO_BOROUGH = process.env.DEMO_BOROUGH ?? "Manhattan";
const DEFAULT_RADIUS_METERS = Number(process.env.DEFAULT_RADIUS_METERS ?? 1500);

// Approximate neighborhood centers, used only to resolve "anything shooting in SoHo?"
// style questions from the text/voice front-ends. Not survey-grade.
const NEIGHBORHOODS = {
  soho: { lat: 40.7233, lon: -74.003, label: "SoHo" },
  tribeca: { lat: 40.7163, lon: -74.0086, label: "Tribeca" },
  chelsea: { lat: 40.7465, lon: -74.0014, label: "Chelsea" },
  "west village": { lat: 40.7358, lon: -74.0036, label: "West Village" },
  "east village": { lat: 40.7265, lon: -73.9815, label: "East Village" },
  "lower east side": { lat: 40.715, lon: -73.9843, label: "Lower East Side" },
  "financial district": { lat: 40.7075, lon: -74.0113, label: "Financial District" },
  midtown: { lat: 40.7549, lon: -73.984, label: "Midtown" },
  "upper west side": { lat: 40.787, lon: -73.9754, label: "Upper West Side" },
  "upper east side": { lat: 40.7736, lon: -73.9566, label: "Upper East Side" },
  harlem: { lat: 40.8116, lon: -73.9465, label: "Harlem" },
  "morningside heights": { lat: 40.8098, lon: -73.9625, label: "Morningside Heights" }
};

function neighborhoodIn(text) {
  const lower = (text ?? "").toLowerCase();
  const key = Object.keys(NEIGHBORHOODS).find((name) => lower.includes(name));
  return key ? NEIGHBORHOODS[key] : null;
}

module.exports = { DEFAULT_CENTER, DEMO_BOROUGH, DEFAULT_RADIUS_METERS, NEIGHBORHOODS, neighborhoodIn };
