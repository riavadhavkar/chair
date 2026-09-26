# Transit Notch Backend

Decodes MTA's public GTFS-realtime feeds into the simplified JSON the Mac/iOS
apps poll, calls Gemini to turn raw service-alert text into a plain-language
sentence, and logs delay history to MongoDB for the trend indicator.

This is a separate service from the Xcode project — deploy it wherever you
like (DigitalOcean App Platform or a Droplet both work) and point the app's
`Secrets.xcconfig` at its URL.

## Setup

```bash
cd backend
npm install
cp .env.example .env   # fill in the values below
npm run dev
```

`GET http://localhost:8080/status?line=L&station=L03` should return JSON.
`GET http://localhost:8080/health` is a plain liveness check.

## Required environment variables

| Variable | Required? | Where to get it |
|---|---|---|
| `PORT` | No (defaults 8080) | — |
| `GEMINI_API_KEY` | No, but recommended | [Google AI Studio](https://aistudio.google.com/apikey) — free tier available |
| `GEMINI_MODEL` | No (defaults `gemini-2.5-flash`) | Check the [current model list](https://ai.google.dev/gemini-api/docs/models) if this 404s — model ids get renamed/retired over time |
| `MONGODB_URI` | No, but recommended | [MongoDB Atlas](https://www.mongodb.com/cloud/atlas) free (M0) cluster connection string |
| `MONGODB_DB_NAME` | No (defaults `transitTracker`) | — |

Without `GEMINI_API_KEY`, `/status` still works — `delayReasonRaw` just
returns the raw MTA alert text unsummarized. Without `MONGODB_URI`, it still
works too — `delayedCountToday` comes back `null` and no history is recorded.
Nothing about this service requires an MTA API key; the GTFS-realtime and
alerts feeds it polls are public and keyless.

## Known limitations (documented, not silent)

- **Feed URLs** (`src/config/feeds.js`) are MTA's current public
  GTFS-realtime endpoints as of when this was written. Verify against
  <https://api.mta.info/#/subwayRealTimeFeeds> if `/status` starts returning
  502s — MTA has moved these before.
- **Station coordinates** (`src/config/stations.js`) are a small,
  hand-entered lookup for a handful of L train stops, meant to unblock
  wiring/testing. Replace with MTA's authoritative static GTFS bundle
  (stops.txt in <https://rrgtfsfeeds.s3.amazonaws.com/google_transit.zip>)
  before trusting station names/coordinates beyond local dev.
- **`vehiclePosition` is an approximation**, not live GPS. NYCT's standard
  subway GTFS-realtime feed doesn't include continuous vehicle
  latitude/longitude (that requires parsing MTA's `nyct-subway.proto`
  extension for current stop sequence/status, which this service doesn't
  do yet). `vehiclePosition` currently just returns the *upcoming* station's
  coordinates as a stand-in. The Mac app's primary tracker doesn't need this
  at all (it's schematic, driven by `nextArrivalMinutes`) — this field only
  feeds the secondary literal Mapbox view.
- Only subway lines are covered (`src/config/feeds.js` line → feed-group
  map); buses aren't handled.

## Deploying to DigitalOcean

**App Platform** (simplest): create an app from this `backend/` directory
(or point at a Dockerfile build), set the environment variables above as
encrypted app-level secrets, and note the generated public URL.

**Droplet + Docker**: `docker build -t transit-backend .` then
`docker run -d -p 8080:8080 --env-file .env transit-backend`, behind
whatever reverse proxy/TLS termination you're already running.

Either way, give the resulting HTTPS URL to the Mac app's
`Secrets.xcconfig` as `TRANSIT_BACKEND_BASE_URL`.
