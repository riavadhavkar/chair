const { parseSegments, segmentKey, spotIdFor, displayStreet, crossStreetsText } = require("../lib/blocks");
const { neighborhoodFor } = require("../config/neighborhoods");

function newSpot(segment, borough) {
  return {
    id: spotIdFor(segment),
    street: segment.street,
    from: segment.from,
    to: segment.to,
    borough: borough ?? null,
    name: displayStreet(segment.street),
    crossStreets: crossStreetsText(segment),
    neighborhood: null,
    timesFilmed: 0,
    lastFilmed: null,
    lastCategory: null,
    lat: null,
    lon: null,
    collectible: false
  };
}

/// Folds permits into one record per street block: how often it was filmed,
/// when last, and which neighborhood most of its permits were in.
function aggregateSpots(permits) {
  const spots = new Map();
  const votes = new Map();

  for (const permit of permits) {
    const neighborhood = neighborhoodFor(permit.zipCodes, permit.borough);
    const segments = new Map(parseSegments(permit.parkingHeld).map((s) => [segmentKey(s), s]));

    for (const [key, segment] of segments) {
      if (!spots.has(key)) {
        spots.set(key, newSpot(segment, permit.borough));
        votes.set(key, {});
      }
      const spot = spots.get(key);
      spot.timesFilmed += 1;
      const tally = votes.get(key);
      tally[neighborhood] = (tally[neighborhood] ?? 0) + 1;
      if (permit.startsAt && (!spot.lastFilmed || permit.startsAt > spot.lastFilmed)) {
        spot.lastFilmed = permit.startsAt;
        spot.lastCategory = permit.category;
      }
    }
  }

  for (const [key, spot] of spots) {
    spot.neighborhood = Object.entries(votes.get(key)).sort((a, b) => b[1] - a[1])[0][0];
  }
  return [...spots.values()];
}

/// The collectible set: each neighborhood's most-filmed blocks, one block per street
/// so the grid isn't twelve blocks of the same avenue.
function markCollectible(spots, perNeighborhood = 12) {
  const byNeighborhood = new Map();
  for (const spot of spots) {
    spot.collectible = false;
    if (!byNeighborhood.has(spot.neighborhood)) byNeighborhood.set(spot.neighborhood, []);
    byNeighborhood.get(spot.neighborhood).push(spot);
  }
  for (const group of byNeighborhood.values()) {
    const seenStreets = new Set();
    const ranked = group.sort((a, b) => b.timesFilmed - a.timesFilmed || a.name.localeCompare(b.name));
    for (const spot of ranked) {
      if (seenStreets.size >= perNeighborhood) break;
      if (seenStreets.has(spot.street)) continue;
      seenStreets.add(spot.street);
      spot.collectible = true;
    }
  }
  return spots.filter((s) => s.collectible);
}

module.exports = { aggregateSpots, markCollectible, newSpot };
