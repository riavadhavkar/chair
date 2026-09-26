# Set Watch backend

Turns NYC's public film permits into collectible street blocks, and serves the Set Watch iPhone app.

```
NYC Open Data film permits (2012 → today)
        │  npm run import (once)
        ▼
one spot per street block ── times filmed, last shoot, neighborhood
        │  top 12 blocks per neighborhood = the collectible set, geocoded
        ▼
MongoDB Atlas (spots, checkins, walks)  ◀── GET /today reads today's permits live
        │
        ├─ POST /checkins   GPS-checked, one per device per spot → shared visitor count
        ├─ POST /walks      nearby most-filmed blocks, ordered as a loop; Gemini writes the narration
        └─ GET  /walks/:id/narration   ElevenLabs MP3
```

## Run it

```bash
cd backend
npm install
cp .env.example .env     # fill in what you have; everything is optional
npm run import           # Manhattan since 2012 → data/spots.json (+ MongoDB if configured)
npm run dev
npm test
```

Without `MONGODB_URI` the server uses an in-memory store seeded from `data/spots.json`, and check-ins are lost on restart. Use Atlas for the demo.

## API

Dates are ISO-8601 without fractional seconds. `deviceID` is the app's anonymous per-install UUID.

| Method | Path | Input | Output |
|---|---|---|---|
| GET | `/health` | — | `{ ok, store }` |
| GET | `/today` | `lat, lon, radius` (m, default 1600) | `[Shoot]`, nearest first |
| GET | `/collection` | `deviceID` | `[Spot]`: the collectible set, plus any other block this device checked in at |
| GET | `/spots/:id` | `deviceID` | `Spot` |
| POST | `/checkins` | `{ spotID, deviceID, lat, lon }` | `201` new / `409` already collected, both with `{ spotID, visitorCount, collectedAt }`. `422 { error: "too_far", distanceMeters }` |
| POST | `/walks` | `{ lat, lon, minutes: 15\|30\|45, deviceID? }` | `{ id, minutes, stops: [Spot], narrationText }`. `404` if there are fewer than 2 filmed blocks nearby |
| GET | `/walks/:id/narration` | — | `audio/mpeg`. `503` without an ElevenLabs key; the app falls back to the device voice |

`Shoot`: `{ id, spotID, block, category, subcategory, startsAt, endsAt, lat, lon }`

`Spot`: `{ id, name, crossStreets, neighborhood, lat, lon, timesFilmed, lastFilmed, lastCategory, visitorCount, collectedAt }`

## How the pieces work

- **Spots.** A permit's `parkingheld` field lists the street blocks it holds ("W 20 St between 5 Av and 6 Av, …"). Each block is one spot, identified by a hash of its street and sorted cross streets. `timesFilmed` counts permits that held the block. The neighborhood comes from the permit's ZIP (`src/config/neighborhoods.js`, Manhattan only).
- **Collectible set.** Each neighborhood's 12 most-filmed blocks, at most one per street (`SPOTS_PER_NEIGHBORHOOD`).
- **Geocoding.** A block's point is the midpoint of its two end intersections. With `NYC_GEOCLIENT_KEY` (free, api-portal.nyc.gov) this uses NYC Geoclient's intersection endpoint; otherwise it uses the keyless GeoSearch, which handles intersections less reliably. **Get the Geoclient key before the demo.**
- **Check-ins.** The server allows 150 m (`CHECKIN_RADIUS_METERS`); the app requires 100 m and a fix accurate to 65 m. It stores only `{ spotID, deviceID, at }`. Device ids can be spoofed, so treat counts as a fun signal, not proof.
- **Walks.** The server picks the most-filmed blocks within reach (15 → 3 stops, 30 → 5, 45 → 6) and orders them as a nearest-neighbor loop. Gemini writes the spoken narration from permit facts only, and is told never to name a show. Without `GEMINI_API_KEY`, a template narration is used.

## Deploy (DigitalOcean App Platform)

1. Create an app from this repo with source directory `backend/` (the Dockerfile works as-is), or run `npm start` on a Droplet.
2. Set the env vars from `.env.example`, including `MONGODB_URI` from Atlas. Allow DigitalOcean's egress IPs in Atlas network access.
3. Run the import once with the same `.env` (locally is fine, as long as it writes to the same Atlas database).
4. Point your `.tech` domain at the app, then set `SETWATCH_BACKEND_BASE_URL` in the app's `Secrets.xcconfig`.

## Known limitations

- The permits don't say which show or movie was filming, and the app never guesses. Title matching is a future improvement.
- Only Manhattan has neighborhood names; other boroughs group under the borough name.
- "Today" only shows permits whose first held block can be geocoded.
