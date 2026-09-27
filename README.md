# chair

**Collect the blocks where New York gets filmed.** chair maps where TV and film crews are shooting in NYC today, using the city's public film permits. It also turns more than a decade of permits into a collection of the most-filmed blocks in each neighborhood. You collect a block by physically going there and checking in, and every block shows how many people have been. A block with hundreds of visits is "A classic"; one with a handful is a "Secret spot".

| Tab | What it does |
|---|---|
| **Today** | Map + list of permits filming today, nearest first |
| **Walk** | A 15/30/45-minute loop through the most-filmed blocks near you, narrated (Gemini writes it, ElevenLabs voices it) |
| **Collection** | Neighborhood grid: collected first, missing grayed out, GPS-verified check-ins, shared visitor counts |

## Repo

- `chair/`, `chair.xcodeproj`: iPhone app (SwiftUI, MapKit, CoreLocation, iOS 26). No third-party packages, no API keys in the app.
- `backend/`: Node/Express API, MongoDB Atlas, NYC Open Data import. See [backend/README.md](backend/README.md).
- `docs/IOS_APP_BRIEF.md`: the product and design spec.

## Run the app

1. Open `chair.xcodeproj` in Xcode 26, pick your team under Signing & Capabilities, and run on an iPhone or the simulator.
2. It starts on **mock data** (`CHAIR_USE_MOCK_DATA = YES` in `Chair.xcconfig`), so every screen works without the backend.
3. To try a check-in in the simulator, go to Features ▸ Location ▸ Custom Location and enter a mock spot, e.g. Grove St: `40.7330, -74.0040`.
4. To use the real backend, copy `Secrets.example.xcconfig` to `Secrets.xcconfig` and set `CHAIR_USE_MOCK_DATA = NO` and `CHAIR_BACKEND_BASE_URL` (write `https:/$()/host`, since `//` starts a comment in xcconfig files). The simulator can use `http:/$()/localhost:8080`; a real iPhone needs the deployed URL.

## Built with

NYC Open Data (film permits) · Apple MapKit · MongoDB Atlas · DigitalOcean · Google Gemini · ElevenLabs · a `.tech` domain
