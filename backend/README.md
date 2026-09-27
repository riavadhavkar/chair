# chair backend

turns nyc's public film permits into collectible street blocks, and serves the chair iphone app.

```
NYC Open Data film permits (2012 → today)
        │  npm run import (once)
        ▼
one spot per street block ── times filmed, last shoot, neighborhood
        │  top 12 blocks per neighborhood = the collectible set, geocoded, Gemini picks each an icon
        ▼
MongoDB Atlas (spots, checkins, walks)  ◀── GET /today reads today's permits live
        │
        ├─ POST /checkins   GPS-checked, one per device per spot → shared visitor count
        ├─ POST /walks      nearby most-filmed blocks, ordered as a loop; Gemini writes the narration
        └─ GET  /walks/:id/narration   ElevenLabs MP3
```

## run it

```bash
cd backend
npm install
cp .env.example .env     # fill in what you have; everything is optional
npm run import           # Manhattan since 2012 → data/spots.json (+ MongoDB if configured)
npm run dev
npm test
```

without `MONGODB_URI` the server uses an in-memory store seeded from `data/spots.json`, and check-ins are lost on restart. use atlas for the demo.

## api

dates are iso-8601 without fractional seconds. `deviceID` is the app's anonymous per-install uuid.

| method | path | input | output |
|---|---|---|---|
| get | `/health` | — | `{ ok, store }` |
| get | `/today` | `lat, lon, radius` (m, default 1600) | `[Shoot]`, nearest first |
| get | `/collection` | `deviceID` | `[Spot]`: the collectible set, plus any other block this device checked in at |
| get | `/spots/:id` | `deviceID` | `Spot` |
| post | `/checkins` | `{ spotID, deviceID, lat, lon }` | `201` new / `409` already collected, both with `{ spotID, visitorCount, collectedAt }`. `422 { error: "too_far", distanceMeters }` |
| post | `/walks` | `{ lat, lon, minutes: 15\|30\|45, deviceID? }` | `{ id, minutes, stops: [Spot], narrationText }`. `404` if there are fewer than 2 filmed blocks nearby |
| get | `/walks/:id/narration` | — | `audio/mpeg`. `503` without an elevenlabs key; the app falls back to the device voice |

`Shoot`: `{ id, spotID, block, category, subcategory, startsAt, endsAt, lat, lon }`

`Spot`: `{ id, name, crossStreets, neighborhood, symbol, lat, lon, timesFilmed, lastFilmed, lastCategory, visitorCount, collectedAt }`. `symbol` is an sf symbol name.

## how the pieces work

- **spots.** a permit's `parkingheld` field lists the street blocks it holds ("w 20 st between 5 av and 6 av, …"). each block is one spot, identified by a hash of its street and sorted cross streets. `timesFilmed` counts permits that held the block. the neighborhood comes from the permit's zip (`src/config/neighborhoods.js`, manhattan only).
- **collectible set.** each neighborhood's 12 most-filmed blocks, at most one per street (`SPOTS_PER_NEIGHBORHOOD`).
- **icons.** during the import, gemini picks an sf symbol for each collectible block from a fixed allowlist (`src/services/symbols.js`), based on the street itself, never a show. anything not on the list (or no `GEMINI_API_KEY`) falls back to an icon for the last shoot's category (tv, film, megaphone…).
- **geocoding.** a block's point is the midpoint of its two end intersections. with `NYC_GEOCLIENT_KEY` (free, api-portal.nyc.gov) this uses nyc geoclient's intersection endpoint; otherwise it uses the keyless geosearch, which handles intersections less reliably. **get the geoclient key before the demo.**
- **check-ins.** the server allows 150 m (`CHECKIN_RADIUS_METERS`); the app requires 100 m and a fix accurate to 65 m. it stores only `{ spotID, deviceID, at }`. device ids can be spoofed, so treat counts as a fun signal, not proof.
- **walks.** the server picks the most-filmed blocks within reach (15 → 3 stops, 30 → 5, 45 → 6) and orders them as a nearest-neighbor loop. gemini writes the spoken narration from permit facts only, and is told never to name a show. without `GEMINI_API_KEY`, a template narration is used.

## deploy (digitalocean app platform)

1. create an app from this repo with source directory `backend/` (the dockerfile works as-is), or run `npm start` on a droplet.
2. set the env vars from `.env.example`, including `MONGODB_URI` from atlas. allow digitalocean's egress ips in atlas network access.
3. run the import once with the same `.env` (locally is fine, as long as it writes to the same atlas database).
4. point your `.tech` domain at the app, then set `CHAIR_BACKEND_BASE_URL` in the app's `Secrets.xcconfig`.

## known limitations

- the permits don't say which show or movie was filming, and the app never guesses. title matching is a future improvement.
- only manhattan has neighborhood names; other boroughs group under the borough name.
- "today" only shows permits whose first held block can be geocoded.
