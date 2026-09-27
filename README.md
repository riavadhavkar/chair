# chair

**collect the blocks where new york gets filmed.** chair maps where tv and film crews are shooting in nyc today, using the city's public film permits. it also turns more than a decade of permits into a collection of the most-filmed blocks in each neighborhood. you collect a block by physically going there and checking in, and every block shows how many people have been. a block with hundreds of visits is "a classic"; one with a handful is a "secret spot".

| tab | what it does |
|---|---|
| **today** | map + list of permits filming today, nearest first |
| **walk** | a 15/30/45-minute loop through the most-filmed blocks near you, narrated (gemini writes it, elevenlabs voices it) |
| **collection** | neighborhood grid: collected first, missing grayed out, gps-verified check-ins, shared visitor counts |

## repo

- `chair/`, `chair.xcodeproj`: iphone app (swiftui, mapkit, corelocation, ios 26). no third-party packages, no api keys in the app.
- `backend/`: node/express api, mongodb atlas, nyc open data import. see [backend/readme.md](backend/README.md).
- `docs/IOS_APP_BRIEF.md`: the product and design spec.

## run the app

1. open `chair.xcodeproj` in xcode 26, pick your team under signing & capabilities, and run on an iphone or the simulator.
2. it starts on **mock data** (`CHAIR_USE_MOCK_DATA = YES` in `Chair.xcconfig`), so every screen works without the backend.
3. to try a check-in in the simulator, go to features ▸ location ▸ custom location and enter a mock spot, e.g. grove st: `40.7330, -74.0040`.
4. to use the real backend, copy `Secrets.example.xcconfig` to `Secrets.xcconfig` and set `CHAIR_USE_MOCK_DATA = NO` and `CHAIR_BACKEND_BASE_URL` (write `https:/$()/host`, since `//` starts a comment in xcconfig files). the simulator can use `http:/$()/localhost:8080`; a real iphone needs the deployed url.

## built with

nyc open data (film permits) · apple mapkit · mongodb atlas · digitalocean · google gemini · elevenlabs · a `.tech` domain
