const crypto = require("crypto");

// A permit's `parkingheld` field lists the street blocks it holds, e.g.
// "WEST 20 STREET between 5 AVENUE and 6 AVENUE, 5 AVENUE between WEST 19 STREET and WEST 20 STREET".
// Each "X between Y and Z" segment is one block, and one block is one spot.

const ABBREVIATIONS = [
  [/\bWEST\b/g, "W"],
  [/\bEAST\b/g, "E"],
  [/\bNORTH\b/g, "N"],
  [/\bSOUTH\b/g, "S"],
  [/\bSTREET\b/g, "St"],
  [/\bAVENUE\b/g, "Av"],
  [/\bBOULEVARD\b/g, "Blvd"],
  [/\bPLACE\b/g, "Pl"],
  [/\bROAD\b/g, "Rd"],
  [/\bDRIVE\b/g, "Dr"],
  [/\bSQUARE\b/g, "Sq"]
];

function normalize(text) {
  return text.toUpperCase().replace(/\s+/g, " ").trim();
}

/// Cross streets are sorted so "A between B and C" and "A between C and B" are the same block.
function parseSegments(parkingHeld) {
  return (parkingHeld ?? "")
    .split(",")
    .map((segment) => /^(.+?)\s+between\s+(.+?)\s+and\s+(.+)$/i.exec(segment.trim()))
    .filter(Boolean)
    .map((match) => {
      const [from, to] = [normalize(match[2]), normalize(match[3])].sort();
      return { street: normalize(match[1]), from, to };
    });
}

function segmentKey({ street, from, to }) {
  return `${street}|${from}|${to}`;
}

function spotIdFor(segment) {
  return crypto.createHash("sha1").update(segmentKey(segment)).digest("hex").slice(0, 12);
}

/// "WEST 20 STREET" -> "W 20 St"
function displayStreet(raw) {
  let text = normalize(raw);
  for (const [pattern, replacement] of ABBREVIATIONS) text = text.replace(pattern, replacement);
  return text.toLowerCase().replace(/\b([a-z])/g, (c) => c.toUpperCase());
}

function crossStreetsText({ from, to }) {
  return `${displayStreet(from)} – ${displayStreet(to)}`;
}

/// "W 20 St between 5 Av & 6 Av"
function blockText(segment) {
  return `${displayStreet(segment.street)} between ${displayStreet(segment.from)} & ${displayStreet(segment.to)}`;
}

module.exports = { parseSegments, segmentKey, spotIdFor, displayStreet, crossStreetsText, blockText };
