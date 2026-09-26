const express = require("express");
const { getFeedForLine, nextArrivalForStop } = require("../services/gtfsClient");
const { delayReasonForLine } = require("../services/alertsClient");
const { plainLanguageSummary } = require("../services/geminiClient");
const { recordSnapshot, delayedCountToday } = require("../services/mongoClient");
const { stationFor } = require("../config/stations");

const router = express.Router();

// GET /status?line=L&station=L03
router.get("/status", async (req, res) => {
  const { line, station } = req.query;
  if (!line || !station) {
    res.status(400).json({ error: "Query params 'line' and 'station' are required." });
    return;
  }

  try {
    const feedMessage = await getFeedForLine(line);
    const arrival = nextArrivalForStop(feedMessage, line, station);

    if (!arrival) {
      res.status(404).json({ error: `No upcoming arrivals found for ${line} at ${station}.` });
      return;
    }

    const nextArrivalMinutes = Math.max(0, Math.round((arrival.arrivalUnix - Date.now() / 1000) / 60));
    const delayMinutes = Math.max(0, Math.round((arrival.delaySeconds ?? 0) / 60));

    const rawReason = await delayReasonForLine(line);
    const delayReasonRaw = rawReason ? await plainLanguageSummary(rawReason) : null;

    // Approximate: the vehicle's actual continuous GPS position isn't in the
    // standard subway TripUpdate feed, so this snaps to the upcoming
    // station's known coordinates rather than a true live position.
    const upcomingStation = stationFor(station);

    recordSnapshot({ line, station, delayMinutes }).catch((error) => {
      console.error("Failed to record delay snapshot:", error);
    });

    const delayedCountTodayValue = await delayedCountToday({ line, station }).catch(() => null);

    res.json({
      line,
      nextArrivalMinutes,
      delayMinutes,
      delayReasonRaw,
      vehiclePosition: upcomingStation ? { lat: upcomingStation.lat, lon: upcomingStation.lon } : null,
      delayedCountToday: delayedCountTodayValue
    });
  } catch (error) {
    console.error("GET /status failed:", error);
    res.status(502).json({ error: "Upstream transit data unavailable." });
  }
});

module.exports = router;
