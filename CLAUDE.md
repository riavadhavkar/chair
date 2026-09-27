# chair

an iphone app that maps nyc film/tv shoots from the city's public film permits. people collect the most-filmed blocks by physically checking in, and each block shows how many people have been there.

`docs/IOS_APP_BRIEF.md` is the product/design spec. the design canvas is "chair iphone app": https://claude.ai/artifact/Mq6WmAvEq7i7pErSihnP17 (the owner shares it).

## layout

- `chair/`: the app. xcode uses a synchronized folder, so new `.swift` files need no project edits.
  - `Models/Models.swift`: `Shoot`, `Spot` (with the `vibe` label), `CheckInResult`, `Walk`
  - `Models/AppModel.swift`: shared observable state for all tabs, plus the check-in gate (`availability(for:)`)
  - `Services/`: `ChairService` protocol; `MockChairService` (canvas data) and `RemoteChairService` (http); `LocationModel` (cllocationupdate); `NarrationPlayer` (elevenlabs mp3 with a device-voice fallback)
  - `Views/`: `TodayView`, `WalkView`, `CollectionView` (+ `CollectionLayout` sorting, grid ↔ `VisitMapView` "my map"), `SpotSheet`
  - `Views/Components/SpotBadge.swift`: `SpotBadge` (street icon), `HolographicBadge` (drag to turn in 3d, foil sheen), `CollectibleBadge` (collect animation: spin ×3, color, scale pop) and `SparkleBurst`
  - `Config/AppConfig.swift`: reads `Chair.xcconfig` → `ChairInfo.plist` (mock flag, backend url); anonymous `DeviceID`
- `backend/`: node/express + mongodb. `npm test` must pass. api contract is in `backend/README.md`.

## rules

- swiftui + mapkit + corelocation, ios 26, no third-party packages. the project defaults to mainactor isolation; mark plain data types `nonisolated`.
- permits have no show/movie titles. never display, guess or generate one (in the app or in gemini prompts).
- no fabricated visitor counts outside `MockChairService`.
- collection order: sections by neighborhood; inside each, collected first, then missing, both sorted by name.
- all ui copy is lowercase (the root also applies `.textCase(.lowercase)`). accessibility labels are lowercase too.
- respect reduce motion (the collect animation becomes a crossfade) and dynamic type. liquid glass only for floating chrome (the tab bar, the top chips).
- the app holds no api keys. keys live in `backend/.env`. never commit `.env` or `Secrets.xcconfig`.
