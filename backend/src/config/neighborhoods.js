// Manhattan ZIP code -> neighborhood, used to group spots in the Collection.
// ZIPs don't follow neighborhood lines exactly; this is a readable approximation.
const MANHATTAN = {
  10001: "Chelsea",
  10011: "Chelsea",
  10002: "Lower East Side",
  10003: "East Village",
  10009: "East Village",
  10004: "Financial District",
  10005: "Financial District",
  10006: "Financial District",
  10038: "Financial District",
  10007: "Tribeca",
  10013: "Tribeca",
  10280: "Battery Park City",
  10282: "Battery Park City",
  10012: "SoHo",
  10014: "West Village",
  10010: "Gramercy",
  10016: "Murray Hill",
  10017: "Midtown East",
  10022: "Midtown East",
  10018: "Midtown",
  10020: "Midtown",
  10036: "Midtown",
  10019: "Hell's Kitchen",
  10021: "Upper East Side",
  10028: "Upper East Side",
  10065: "Upper East Side",
  10075: "Upper East Side",
  10128: "Upper East Side",
  10023: "Upper West Side",
  10024: "Upper West Side",
  10069: "Upper West Side",
  10025: "Morningside Heights",
  10026: "Harlem",
  10027: "Harlem",
  10030: "Harlem",
  10037: "Harlem",
  10039: "Harlem",
  10029: "East Harlem",
  10035: "East Harlem",
  10031: "Hamilton Heights",
  10032: "Washington Heights",
  10033: "Washington Heights",
  10034: "Inwood",
  10040: "Inwood",
  10044: "Roosevelt Island"
};

/// First ZIP on the permit that we can name, else the borough.
function neighborhoodFor(zipCodes, borough) {
  for (const zip of zipCodes ?? []) {
    const name = MANHATTAN[Number(zip)];
    if (name) return name;
  }
  return borough ?? "New York";
}

module.exports = { neighborhoodFor };
