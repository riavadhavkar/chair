# chair — iPhone app build brief

> **Status:** implemented in `chair/` and `backend/`. This brief is the spec, and the code follows it.

chair shows where movies and TV are filming in NYC today, based on the city's public film permits. It also turns the most-filmed blocks into spots people can collect by physically visiting them. Every spot shows how many people have been there, so a visit feels either validated ("a classic") or like a find ("secret spot").

The design reference is the **"chair iPhone app"** canvas (https://claude.ai/artifact/Mq6WmAvEq7i7pErSihnP17, private until the owner shares it). Match its layout, spacing and colors. The collection screen follows the same pattern as Apple's pins sample app (WWDC26 session 382).

---

## Platform

- **iOS 26, iPhone only. SwiftUI, MapKit, CoreLocation, AVFoundation.** No third-party packages, no UIKit views unless SwiftUI has no equivalent.
- Create a **new iOS App project** in this repo (e.g. `chair/`). The old macOS notch app in `sair/` is retired, so delete it once the new target builds.
- Networking: `URLSession` + `async/await` + `Codable`.
- `Info.plist`: `NSLocationWhenInUseUsageDescription` = "chair uses your location to show nearby shoots and to confirm you're at a spot when you check in."
- No accounts. Each install gets an anonymous id: a `UUID` created on first launch and stored in `UserDefaults`.

## Build it against mock data first

The backend is being built in parallel. Put all data access behind one protocol so the app runs fully on mock data before the backend exists:

```swift
protocol ChairService {
    func filmingToday(near: CLLocationCoordinate2D) async throws -> [Shoot]
    func collection() async throws -> [Spot]
    func spot(id: String) async throws -> Spot
    func checkIn(spotID: String, at: CLLocationCoordinate2D) async throws -> CheckInResult   // the service knows the device id
    func walk(from: CLLocationCoordinate2D, minutes: Int) async throws -> Walk
    func narration(for walk: Walk) async throws -> Data   // audio/mpeg
}
```

Ship `MockChairService` (hardcoded sample data that matches the canvas) and `RemoteChairService` (the HTTP API below). Choose between them with one flag.

---

## Screens

A floating tab bar with three tabs: **Today** (`film`), **Walk** (`figure.walk`), **Collection** (`square.grid.2x2`).

### 1 · Today (home)

- A full-screen Apple Map centered on the user, with one pin per permit filming today. A pin is a small red circle with a white `movieclapper` glyph.
- A glass chip at the top: "Filming today · 14 shoots within 1 mi".
- A bottom sheet (detents: peek and medium) lists today's shoots, nearest first. Each row shows:
  - the block ("W 20 St between 5 & 6 Av")
  - the category ("Television · Episodic series")
  - the hours ("until 9 PM")
  - the distance ("2 blocks")
- Tapping a pin or a row opens the **Spot sheet** for that block.

### 2 · Spot sheet

Opens from the map, a walk stop, or the collection grid. It is a `.sheet` with medium and large detents. It contains:

- The block name as the title, and neighborhood + cross streets as the subtitle.
- A large badge (120 pt): gray if you haven't collected it, red with a white check if you have.
- Facts from the permits: "Filmed 63 times since 2012" · "Last shoot Mar 2026 · Television". If the block is filming today, add a red "Filming now · until 9 PM" line.
- The **visitor counter**: a capsule with the count and a vibe label (thresholds below).
- Buttons:
  - **Not collected, within 100 m:** a red "Check in here" button that is enabled, with a caption like "You're 40 m away".
  - **Not collected, farther than 100 m:** the same button disabled, captioned "Get within 100 m to check in · 0.3 mi away", plus a "Directions" button that opens Apple Maps walking directions (`MKMapItem.openInMaps` with walking mode).
  - **Collected:** no button. Show "Collected Sep 26, 2026" and "You're one of 213 people who've been here".
- A successful check-in plays a success haptic and animates the badge from gray to red (a crossfade under Reduce Motion). The counter then updates from the server response.

### 3 · Walk ("near me now")

- A "Plan a walk" button with a 15 / 30 / 45 min picker. The server picks the most-filmed blocks within reach (3 / 5 / 6 stops) and orders them into a loop, and Gemini writes the spoken narration.
- A map with the walking route as a line (use `MKDirections` walking routes between the stops) and numbered stop markers.
- A card containing:
  - "30-min walk · 5 filmed blocks"
  - a **Listen** button that plays the ElevenLabs narration with `AVAudioPlayer`, showing a small animated waveform while playing
  - the stop list, each stop with "filmed N times since 2012"
- Tapping a stop opens its Spot sheet, so you can check in on the walk.
- Footer: "Stops from NYC film permits · narration written by Gemini".
- If ElevenLabs audio isn't available, Listen falls back to the device voice (AVSpeechSynthesizer), so it always works in a demo.

### 4 · Collection

Follow the pins-app sketch exactly:

- A segmented control: **All / Collected / Missing**.
- Sections by **neighborhood**. Each header shows the name, a count like "3 of 12", and a chevron that collapses or expands the section.
- A 3-column grid of badges, each with the block name under it (2 lines max).
- **Inside each section, collected spots come first, then missing ones. Both groups are sorted by name.**
- Missing badges are grayed out. Collected badges are red with a small white check in the corner.
- Tapping any badge opens the Spot sheet (missing → with check-in, collected → with collected date + counter).
- The collectible set is the **12 most-filmed blocks in each neighborhood**; the server decides this.

## Visitor counter vibe labels

| Check-ins at this spot | Label |
|---|---|
| 0 | "Be the first here" |
| 1–9 | "Secret spot" |
| 10–99 | "Local favorite" |
| 100+ | "A classic" |

Never show made-up counts in release builds. Mock data may use placeholder numbers.

## Check-in rules

- The client checks the distance first: `CLLocation.distance(from:) <= 100` and `horizontalAccuracy <= 65`.
- The server checks the distance again, with 150 m of slack for GPS drift, and rejects duplicates. The rule is one check-in per device per spot.
- Only the device id, spot id and time are stored, never a location trail.

---

## Data model

```swift
struct Shoot: Codable, Identifiable {        // one permit filming today
    let id: String                            // permit event id
    let spotID: String
    let block: String                         // "W 20 St between 5 & 6 Av"
    let category: String                      // "Television"
    let subcategory: String?                  // "Episodic series"
    let startsAt: Date
    let endsAt: Date
    let lat: Double
    let lon: Double
}

struct Spot: Codable, Identifiable {          // a street block, aggregated from all permits since 2012
    let id: String
    let name: String                          // "Perry St"
    let crossStreets: String?                 // "Bleecker St – W 4 St"
    let neighborhood: String                  // "West Village"
    let lat: Double?                          // nil if the block couldn't be geocoded
    let lon: Double?
    let timesFilmed: Int
    let lastFilmed: Date?
    let lastCategory: String?
    let visitorCount: Int
    let collectedAt: Date?                    // for this device; nil = missing
}

struct CheckInResult: Codable {
    let spotID: String
    let visitorCount: Int
    let collectedAt: Date
}

struct Walk: Codable, Identifiable {
    let id: String
    let minutes: Int
    let stops: [Spot]
    let narrationText: String
}
```

Put the vibe label in one place:

```swift
extension Spot {
    var vibe: String {
        switch visitorCount {
        case 0: "Be the first here"
        case 1...9: "Secret spot"
        case 10...99: "Local favorite"
        default: "A classic"
        }
    }
}
```

## HTTP API (the backend implements this)

Base URL comes from `Secrets.xcconfig` (`CHAIR_BACKEND_BASE_URL`). Dates are ISO-8601 without fractional seconds.

| Method | Path | Body / query | Returns |
|---|---|---|---|
| GET | `/today` | `lat, lon, radius` | `[Shoot]` |
| GET | `/collection` | `deviceID` | `[Spot]` |
| GET | `/spots/:id` | `deviceID` | `Spot` |
| POST | `/checkins` | `{ spotID, deviceID, lat, lon }` | `CheckInResult` (201 new, 409 already collected with the same body, 422 `{ error, distanceMeters }` = too far) |
| POST | `/walks` | `{ lat, lon, minutes, deviceID }` | `Walk` (404 = not enough filmed blocks nearby) |
| GET | `/walks/:id/narration` | — | `audio/mpeg` |

All API keys (Gemini, ElevenLabs, MongoDB) stay on the server. The app holds none.

---

## Look & feel

- **Light mode first, dark mode must also work.** Use system backgrounds (`.systemGroupedBackground` for Collection, the map for Today/Walk).
- **One accent color:** film red `#FF3B30`, i.e. `Color.red`. It's used for pins, collected badges, the "Filming now" dot and the primary buttons. Missing badges are `Color(.systemGray4)`.
- SF Pro and SF Symbols only. Use semantic font styles (`.largeTitle`, `.headline`, `.caption`) so Dynamic Type works.
- **Badge:** a circle with a `movieclapper` glyph. Collected = red fill, white glyph, white `checkmark.circle.fill` in the bottom-right corner. Missing = gray fill, white glyph.
- **Liquid Glass (`glassEffect`) only for floating chrome:** the tab bar, the top chip on Today, and floating map buttons. Content (sheets, lists, cards) uses standard materials and backgrounds.
- Touch targets ≥ 44 pt. `accessibilityLabel` on every icon-only button and badge (e.g. "Perry St, collected" / "Perry St, not collected").
- Respect Reduce Motion (crossfade instead of the badge flip and spring).

## Build order

1. New iOS project, tab bar, `MockChairService`, models.
2. Collection screen and Spot sheet on mock data. This is the core, so match the sketch exactly.
3. Today map with pins and the list sheet.
4. Location permission and the check-in flow (distance gate, haptic, badge animation).
5. Walk screen: route drawing, then narration playback.
6. Swap in `RemoteChairService` once the backend is up.
7. Polish: empty states ("Nothing filming near you today" should feel calm), offline state, accessibility.

## Future improvements (not now)

- Matching permits to actual show/movie titles (TMDB), and walks built around your favorite show.
- More walk types: most-filmed blocks, by category, secret-spots-only.
- A Photon iMessage bot ("what's filming near me?") that uses the same backend.
