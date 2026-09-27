const ZONE = "America/New_York";

/// "2026-09-26T07:00:00.000" (a Socrata floating timestamp, NYC local) -> Date.
function nyLocalToDate(floating) {
  if (!floating) return null;
  const asIfUTC = new Date(`${floating.replace(/\.\d+$/, "")}Z`);
  if (Number.isNaN(asIfUTC.getTime())) return null;
  return new Date(asIfUTC.getTime() - offsetMinutes(asIfUTC) * 60000);
}

/// Current NYC wall-clock time as a Socrata floating timestamp.
function nowAsNyFloating(date = new Date()) {
  const parts = Object.fromEntries(
    new Intl.DateTimeFormat("en-US", {
      timeZone: ZONE,
      hourCycle: "h23",
      year: "numeric",
      month: "2-digit",
      day: "2-digit",
      hour: "2-digit",
      minute: "2-digit",
      second: "2-digit"
    })
      .formatToParts(date)
      .map((p) => [p.type, p.value])
  );
  return `${parts.year}-${parts.month}-${parts.day}T${parts.hour}:${parts.minute}:${parts.second}`;
}

/// NYC's UTC offset in minutes at the given instant (e.g. -240 during EDT).
function offsetMinutes(date) {
  const name = new Intl.DateTimeFormat("en-US", { timeZone: ZONE, timeZoneName: "longOffset" })
    .formatToParts(date)
    .find((p) => p.type === "timeZoneName")?.value;
  const match = /GMT([+-])(\d{2}):(\d{2})/.exec(name ?? "");
  if (!match) return 0;
  const sign = match[1] === "-" ? -1 : 1;
  return sign * (Number(match[2]) * 60 + Number(match[3]));
}

/// ISO-8601 without fractional seconds, so Swift's `.iso8601` decoder accepts it.
function isoSeconds(date) {
  return date ? date.toISOString().replace(/\.\d{3}Z$/, "Z") : null;
}

module.exports = { nyLocalToDate, nowAsNyFloating, isoSeconds };
