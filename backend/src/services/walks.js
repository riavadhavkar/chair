const { distanceMeters } = require("../lib/geo");

const STOPS_FOR_MINUTES = { 15: 3, 30: 5, 45: 6 };
const WALKING_METERS_PER_MINUTE = 80;

/// Stops must be close enough to make a loop in the time: roughly 40% of the
/// distance you could walk in a straight line.
function searchRadiusMeters(minutes) {
  return minutes * WALKING_METERS_PER_MINUTE * 0.4;
}

function pickStops(candidates, count) {
  return [...candidates]
    .sort((a, b) => b.timesFilmed - a.timesFilmed || a.name.localeCompare(b.name))
    .slice(0, count);
}

/// Greedy nearest-neighbor loop from the start point: good enough for 3–6 stops.
function orderLoop(start, stops) {
  const remaining = [...stops];
  const ordered = [];
  let current = start;
  while (remaining.length > 0) {
    let nearest = 0;
    for (let i = 1; i < remaining.length; i += 1) {
      if (distanceMeters(current, remaining[i]) < distanceMeters(current, remaining[nearest])) nearest = i;
    }
    current = remaining.splice(nearest, 1)[0];
    ordered.push(current);
  }
  return ordered;
}

function monthYear(date) {
  return date ? new Date(date).toLocaleDateString("en-US", { month: "long", year: "numeric", timeZone: "America/New_York" }) : null;
}

function stopFacts(spot, index) {
  const last = spot.lastFilmed
    ? `most recently in ${monthYear(spot.lastFilmed)}${spot.lastCategory ? ` (${spot.lastCategory.toLowerCase()})` : ""}`
    : null;
  return `Stop ${index + 1}: ${spot.name}, ${spot.crossStreets}, ${spot.neighborhood}. Filmed ${spot.timesFilmed} times since 2012${last ? `, ${last}` : ""}.`;
}

function templateNarration(minutes, stops) {
  return [
    `Welcome to your ${minutes}-minute chair walk through ${stops.length} of the most-filmed blocks near you.`,
    ...stops.map(stopFacts),
    "That's the loop. Check in at each block to add it to your collection."
  ].join(" ");
}

function narrationPrompt(minutes, stops) {
  return (
    `Write a spoken walking-tour narration for a ${minutes}-minute walk in New York City, about 35 words per stop, ` +
    "warm and conversational, meant to be read aloud. Use ONLY the facts below, which come from NYC film permits. " +
    "The permits do not say which show or movie filmed there, so never name or guess one. " +
    "No headings, no lists, no emoji — just the narration.\n\n" +
    stops.map(stopFacts).join("\n")
  );
}

/// Picks and orders the stops deterministically, then has Gemini write the
/// narration (template fallback). Returns null when there aren't enough filmed
/// blocks nearby for a walk.
async function planWalk({ store, generateText, center, minutes }) {
  const count = STOPS_FOR_MINUTES[minutes];
  const candidates = await store.spotsNear(center, searchRadiusMeters(minutes));
  const stops = orderLoop(center, pickStops(candidates, count));
  if (stops.length < 2) return null;
  const narrationText = (await generateText(narrationPrompt(minutes, stops))) ?? templateNarration(minutes, stops);
  return { minutes, stops, narrationText };
}

module.exports = { planWalk, orderLoop, pickStops, templateNarration, searchRadiusMeters, STOPS_FOR_MINUTES };
