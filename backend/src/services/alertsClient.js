const GtfsRealtimeBindings = require("gtfs-realtime-bindings");
const { ALERTS_FEED_URL } = require("../config/feeds");

const CACHE_TTL_MS = 60_000;
let cached = null;

async function getAlertsFeed() {
  if (cached && Date.now() - cached.fetchedAt < CACHE_TTL_MS) {
    return cached.feedMessage;
  }

  const response = await fetch(ALERTS_FEED_URL, { signal: AbortSignal.timeout(8000) });
  if (!response.ok) {
    throw new Error(`Alerts feed request failed: ${response.status} ${response.statusText}`);
  }
  const buffer = Buffer.from(await response.arrayBuffer());
  const feedMessage = GtfsRealtimeBindings.transit_realtime.FeedMessage.decode(buffer);

  cached = { fetchedAt: Date.now(), feedMessage };
  return feedMessage;
}

function englishText(translatedString) {
  const translations = translatedString?.translation;
  if (!translations?.length) return null;
  const match = translations.find((t) => !t.language || t.language === "en");
  return (match ?? translations[0]).text ?? null;
}

/// Returns the first active alert's raw description affecting this line, or
/// null if there's nothing currently posted for it.
async function delayReasonForLine(line) {
  const feedMessage = await getAlertsFeed();

  for (const entity of feedMessage.entity) {
    const alert = entity.alert;
    if (!alert) continue;

    const affectsLine = (alert.informedEntity ?? []).some(
      (informed) => (informed.routeId ?? "").toUpperCase() === line.toUpperCase()
    );
    if (!affectsLine) continue;

    return englishText(alert.descriptionText) ?? englishText(alert.headerText);
  }

  return null;
}

module.exports = { delayReasonForLine };
