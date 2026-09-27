# chair

An iPhone app that maps NYC film/TV shoots from the city's public film permits. People collect the most-filmed blocks by physically checking in, and each block shows how many people have been there.

`docs/IOS_APP_BRIEF.md` is the product/design spec. The design canvas is "chair iPhone app": https://claude.ai/artifact/Mq6WmAvEq7i7pErSihnP17 (the owner shares it).

## Layout

- `chair/`: the app. Xcode uses a synchronized folder, so new `.swift` files need no project edits.
  - `Models/Models.swift`: `Shoot`, `Spot` (with the `vibe` label), `CheckInResult`, `Walk`
  - `Models/AppModel.swift`: shared observable state for all tabs, plus the check-in gate (`availability(for:)`)
  - `Services/`: `ChairService` protocol; `MockChairService` (canvas data) and `RemoteChairService` (HTTP); `LocationModel` (CLLocationUpdate); `NarrationPlayer` (ElevenLabs MP3 with a device-voice fallback)
  - `Views/`: `TodayView`, `WalkView`, `CollectionView` (+ `CollectionLayout` sorting, grid ↔ `VisitMapView` "my map"), `SpotSheet`
  - `Views/Components/SpotBadge.swift`: `SpotBadge` (street icon), `HolographicBadge` (drag to turn in 3D, foil sheen), `CollectibleBadge` (collect animation: spin ×3, color, scale pop) and `SparkleBurst`
  - `Config/AppConfig.swift`: reads `Chair.xcconfig` → `ChairInfo.plist` (mock flag, backend URL); anonymous `DeviceID`
- `backend/`: Node/Express + MongoDB. `npm test` must pass. API contract is in `backend/README.md`.

## Rules

- SwiftUI + MapKit + CoreLocation, iOS 26, no third-party packages. The project defaults to MainActor isolation; mark plain data types `nonisolated`.
- Permits have no show/movie titles. Never display, guess or generate one (in the app or in Gemini prompts).
- No fabricated visitor counts outside `MockChairService`.
- Collection order: sections by neighborhood; inside each, collected first, then missing, both sorted by name.
- All UI copy is lowercase (the root also applies `.textCase(.lowercase)`). Accessibility labels are lowercase too.
- Respect Reduce Motion (the collect animation becomes a crossfade) and Dynamic Type. Liquid Glass only for floating chrome (the tab bar, the top chips).
- The app holds no API keys. Keys live in `backend/.env`. Never commit `.env` or `Secrets.xcconfig`.
