# Set Watch Backend

Turns NYC's public film permits into "what's filming near me right now" JSON for
the Set Watch notch app (and the stretch iMessage / voice-call front-ends).

```
NYC Open Data film permits ─┐
                            ├─ geocode first held block (NYC GeoSearch)
config/titleHints.json ─────┼─ curated title for this permit id (if any)
                            ├─ TMDB exact-title match → poster, synopsis, genres, cast
                            ├─ Gemini → one plain sentence (template fallback)
                            └─ cache (MongoDB Atlas, or in-memory) → /nearby, /ask, /go/:id
```

## Setup

```bash
cd backend
npm install
cp .env.example .env   # every key is optional; see below
npm run dev
npm run prefetch       # warm the cache before a demo
```

## Endpoints

| Route | What it returns |
|---|---|
| `GET /health` | `{ ok: true }` |
| `GET /nearby?lat=&lon=&radius=` | `{ generatedAt, center, radiusMeters, productions: [...] }`: TMDB-matched shoots first, then nearest first. Omit `lat`/`lon` to use `DEFAULT_LAT`/`DEFAULT_LON`. |
| `POST /ask` `{ text, lat?, lon? }` | `{ reply, production }`: one text answer. The Photon iMessage handler and the ElevenLabs call script call this. Neighborhood names in `text` ("SoHo", "Chelsea"…) set the center. |
| `GET /go/:id` | A tiny HTML page with Open Graph tags (Mapbox static map) that forwards to Apple Maps walking directions, so a link sent in iMessage renders as a map card. |

A production looks like:

```json
{
  "id": "812345",
  "category": "Television",
  "subcategory": "Episodic series",
  "borough": "Manhattan",
  "startsAt": "2026-09-26T11:00:00Z",
  "endsAt": "2026-09-27T01:00:00Z",
  "location": { "raw": "WEST 20 STREET between 5 AVENUE and 6 AVENUE", "display": "W 20 St between 5 & 6 Av", "lat": 40.74, "lon": -73.99, "precision": "intersection" },
  "titleHint": "The Night Desk",
  "match": { "source": "tmdb", "tmdbId": 1, "mediaType": "tv", "title": "…", "year": 2025, "overview": "…", "genres": ["Drama"], "cast": ["…"], "posterURL": "https://image.tmdb.org/…", "backdropURL": null },
  "summary": "The Night Desk is filming on W 20 St between 5 & 6 Av until 9 PM.",
  "directionsURL": "https://maps.apple.com/?daddr=40.74,-73.99&dirflg=w",
  "distanceMeters": 160,
  "shareURL": "https://yourdomain.tech/go/812345"
}
```

`match` is `null` when there's no confident TMDB match. `titleHint` is `null` when nobody curated a title.

## The permit dataset has no title column

The Film Permits dataset (`tg4x-b46p`) lists event id, times, category, subcategory,
borough, zip codes and the held street blocks. It **does not include the production's name.**
So titles come from `src/config/titleHints.json`, which you fill in by hand for the demo:

```json
{ "byEventId": { "812345": { "title": "Exact TMDB Title", "source": "https://link-to-public-report" } } }
```

Only put in titles you can source publicly (press or the production's own announcement).
TMDB only counts **exact** normalized title matches, because a fuzzy match would put the
wrong poster on a working title. Everything else shows up as the permit-only fallback card,
which is why that card has to look intentional.

## Environment variables

All optional. Without them the service still runs and gets less rich:

| Variable | Without it |
|---|---|
| `TMDB_READ_TOKEN` or `TMDB_API_KEY` | No posters/synopses; every card is the permit-only fallback |
| `GEMINI_API_KEY` | `summary` uses a template sentence |
| `MONGODB_URI` | Cache is in-memory only (lost on restart) |
| `NYC_OPEN_DATA_APP_TOKEN` | Lower Socrata rate limit |
| `PUBLIC_BASE_URL` | `shareURL` is `null` |
| `MAPBOX_ACCESS_TOKEN` | `/go/:id` has no preview image |
| `DEFAULT_LAT` / `DEFAULT_LON` / `DEFAULT_LABEL` / `DEMO_BOROUGH` / `DEFAULT_RADIUS_METERS` | Chelsea, Manhattan, 1.5 km |

TMDB requires attribution: show "This product uses the TMDB API but is not endorsed or certified by TMDB." in the app's about/credits.

## Known limitations

- **Location precision varies.** Only the first held block is geocoded (its first cross
  street, else the street). Multi-block permits show one point. Permits that can't be
  geocoded are dropped from `/nearby`.
- **Single borough** (`DEMO_BOROUGH`), per the MVP scope.
- Verify the dataset URL/columns and the GeoSearch endpoint before deploying. Both are
  public services that can change.

## Stretch front-ends (not built yet)

- **Photon iMessage bot:** a separate small Node process scaffolded with
  `npm create spectrum-project@latest -- --yes --platforms imessage --projectId <id>`.
  Its message handler should `POST /ask` with the inbound text and send back `reply`
  plus `production.shareURL`. Keep its `.env` out of git.
- **ElevenLabs + Twilio call:** the call server should build the agent's first message
  from `POST /ask` (or `GET /nearby`). Only call a number its owner opted in.
