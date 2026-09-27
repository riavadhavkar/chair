# chair — iphone app build brief

> **status:** implemented in `chair/` and `backend/`. this brief is the spec, and the code follows it.

chair shows where movies and tv are filming in nyc today, based on the city's public film permits. it also turns the most-filmed blocks into spots people can collect by physically visiting them. every spot shows how many people have been there, so a visit feels either validated ("a classic") or like a find ("secret spot").

the design reference is the **"chair iphone app"** canvas (https://claude.ai/artifact/Mq6WmAvEq7i7pErSihnP17, private until the owner shares it). match its layout, spacing and colors. the collection screen follows the same pattern as apple's pins sample app (wwdc26 session 382).

---

## platform

- **ios 26, iphone only. swiftui, mapkit, corelocation, avfoundation.** no third-party packages, no uikit views unless swiftui has no equivalent.
- create a **new ios app project** in this repo (e.g. `chair/`). the old macos notch app in `sair/` is retired, so delete it once the new target builds.
- networking: `URLSession` + `async/await` + `Codable`.
- `Info.plist`: `NSLocationWhenInUseUsageDescription` = "chair uses your location to show nearby shoots and to confirm you're at a spot when you check in."
- no accounts. each install gets an anonymous id: a `UUID` created on first launch and stored in `UserDefaults`.

## build it against mock data first

the backend is being built in parallel. put all data access behind one protocol so the app runs fully on mock data before the backend exists:

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

ship `MockChairService` (hardcoded sample data that matches the canvas) and `RemoteChairService` (the http api below). choose between them with one flag.

---

## screens

a floating tab bar with three tabs: **today** (`film`), **walk** (`figure.walk`), **collection** (`square.grid.2x2`).

### 1 · today (home)

- a full-screen apple map centered on the user, with one pin per permit filming today. a pin is a small red circle with a white `movieclapper` glyph.
- a glass chip at the top: "filming today · 14 shoots within 1 mi".
- a bottom sheet (detents: peek and medium) lists today's shoots, nearest first. each row shows:
  - the block ("w 20 st between 5 & 6 av")
  - the category ("television · episodic series")
  - the hours ("until 9 pm")
  - the distance ("2 blocks")
- tapping a pin or a row opens the **spot sheet** for that block.

### 2 · spot sheet

opens from the map, a walk stop, or the collection grid. it is a `.sheet` with medium and large detents. it contains:

- the block name as the title, and neighborhood + cross streets as the subtitle.
- a large badge (120 pt): gray if you haven't collected it, red with a white check if you have.
- facts from the permits: "filmed 63 times since 2012" · "last shoot mar 2026 · television". if the block is filming today, add a red "filming now · until 9 pm" line.
- the **visitor counter**: a capsule with the count and a vibe label (thresholds below).
- buttons:
  - **not collected, within 100 m:** a red "check in here" button that is enabled, with a caption like "you're 40 m away".
  - **not collected, farther than 100 m:** the same button disabled, captioned "get within 100 m to check in · 0.3 mi away", plus a "directions" button that opens apple maps walking directions (`MKMapItem.openInMaps` with walking mode).
  - **collected:** no button. show "collected sep 26, 2026" and "you're one of 213 people who've been here".
- a successful check-in plays a success haptic and animates the badge from gray to red (a crossfade under reduce motion). the counter then updates from the server response.

### 3 · walk ("near me now")

- a "plan a walk" button with a 15 / 30 / 45 min picker. the server picks the most-filmed blocks within reach (3 / 5 / 6 stops) and orders them into a loop, and gemini writes the spoken narration.
- a map with the walking route as a line (use `MKDirections` walking routes between the stops) and numbered stop markers.
- a card containing:
  - "30-min walk · 5 filmed blocks"
  - a **listen** button that plays the elevenlabs narration with `AVAudioPlayer`, showing a small animated waveform while playing
  - the stop list, each stop with "filmed n times since 2012"
- tapping a stop opens its spot sheet, so you can check in on the walk.
- footer: "stops from nyc film permits · narration written by gemini".
- if elevenlabs audio isn't available, listen falls back to the device voice (avspeechsynthesizer), so it always works in a demo.

### 4 · collection

follow the pins-app sketch exactly:

- a segmented control: **all / collected / missing**.
- sections by **neighborhood**. each header shows the name, a count like "3 of 12", and a chevron that collapses or expands the section.
- a 3-column grid of badges, each with the block name under it (2 lines max).
- **inside each section, collected spots come first, then missing ones. both groups are sorted by name.**
- missing badges are grayed out. collected badges are red with a small white check in the corner.
- tapping any badge opens the spot sheet (missing → with check-in, collected → with collected date + counter).
- the collectible set is the **12 most-filmed blocks in each neighborhood**; the server decides this.

## visitor counter vibe labels

| check-ins at this spot | label |
|---|---|
| 0 | "be the first here" |
| 1–9 | "secret spot" |
| 10–99 | "local favorite" |
| 100+ | "a classic" |

never show made-up counts in release builds. mock data may use placeholder numbers.

## check-in rules

- the client checks the distance first: `CLLocation.distance(from:) <= 100` and `horizontalAccuracy <= 65`.
- the server checks the distance again, with 150 m of slack for gps drift, and rejects duplicates. the rule is one check-in per device per spot.
- only the device id, spot id and time are stored, never a location trail.

---

## data model

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

put the vibe label in one place:

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

## http api (the backend implements this)

base url comes from `Secrets.xcconfig` (`CHAIR_BACKEND_BASE_URL`). dates are iso-8601 without fractional seconds.

| method | path | body / query | returns |
|---|---|---|---|
| GET | `/today` | `lat, lon, radius` | `[Shoot]` |
| GET | `/collection` | `deviceID` | `[Spot]` |
| GET | `/spots/:id` | `deviceID` | `Spot` |
| POST | `/checkins` | `{ spotID, deviceID, lat, lon }` | `CheckInResult` (201 new, 409 already collected with the same body, 422 `{ error, distanceMeters }` = too far) |
| POST | `/walks` | `{ lat, lon, minutes, deviceID }` | `Walk` (404 = not enough filmed blocks nearby) |
| GET | `/walks/:id/narration` | — | `audio/mpeg` |

all api keys (gemini, elevenlabs, mongodb) stay on the server. the app holds none.

---

## look & feel

- **light mode first, dark mode must also work.** use system backgrounds (`.systemGroupedBackground` for collection, the map for today/walk).
- **one accent color:** film red `#FF3B30`, i.e. `Color.red`. it's used for pins, collected badges, the "filming now" dot and the primary buttons. missing badges are `Color(.systemGray4)`.
- sf pro and sf symbols only. use semantic font styles (`.largeTitle`, `.headline`, `.caption`) so dynamic type works.
- **badge:** a circle with a `movieclapper` glyph. collected = red fill, white glyph, white `checkmark.circle.fill` in the bottom-right corner. missing = gray fill, white glyph.
- **liquid glass (`glassEffect`) only for floating chrome:** the tab bar, the top chip on today, and floating map buttons. content (sheets, lists, cards) uses standard materials and backgrounds.
- touch targets ≥ 44 pt. `accessibilityLabel` on every icon-only button and badge (e.g. "perry st, collected" / "perry st, not collected").
- respect reduce motion (crossfade instead of the badge flip and spring).

## build order

1. new ios project, tab bar, `MockChairService`, models.
2. collection screen and spot sheet on mock data. this is the core, so match the sketch exactly.
3. today map with pins and the list sheet.
4. location permission and the check-in flow (distance gate, haptic, badge animation).
5. walk screen: route drawing, then narration playback.
6. swap in `RemoteChairService` once the backend is up.
7. polish: empty states ("nothing filming near you today" should feel calm), offline state, accessibility.

## future improvements (not now)

- matching permits to actual show/movie titles (tmdb), and walks built around your favorite show.
- more walk types: most-filmed blocks, by category, secret-spots-only.
- a photon imessage bot ("what's filming near me?") that uses the same backend.
