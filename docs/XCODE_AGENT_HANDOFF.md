# chair — handoff to the Xcode agent

All features are implemented in `chair/` and `backend/`, but **the Swift has never been compiled** because it was written without Xcode. Your job is to get it building, run it, and tune how it looks and feels. Read `CLAUDE.md` first.

## 1. Build

- Open `chair.xcodeproj` (iOS 26, target `chair`). Set the signing team. The project file was written by hand, so if Xcode offers to update project settings, accept.
- Fix compile errors with the smallest change that works, and keep the behavior. The APIs most likely to need a tweak:
  - `keyframeAnimator` + `KeyframeTrack` in `CollectibleBadge` and `SparkleBurst` (`Views/Components/SpotBadge.swift`)
  - `.gesture(_:including:)` and the double `rotation3DEffect` in `HolographicBadge`
  - MapKit content builders in `VisitMapView` / `WalkView` (`MapCircle`, `MapPolyline`, `if` inside `Map { }`)
  - `CLServiceSession` / `CLLocationUpdate.liveUpdates()` in `LocationModel`
  - `nonisolated struct` on the models (the project defaults to MainActor isolation)
  - `MKMapItem(placemark:)` is deprecated in iOS 26; a warning is fine

## 2. Run through every flow on mock data (the default)

- [ ] **today:** pins + list; tapping a pin or row opens the spot sheet
- [ ] **collection:** all / collected / missing filter; neighborhood sections collapse; inside each section collected come first, then missing, both a–z; every badge shows its own street icon
- [ ] **check-in:** set Simulator ▸ Features ▸ Location ▸ Custom Location to Grove St `40.7330, -74.0040`, open grove st, tap "check in here"
  - [ ] the pin shrinks, spins 3× on its vertical axis while turning red, pops past full size and settles
  - [ ] sparkles and a ring burst behind it, with a success haptic
  - [ ] with Reduce Motion on, it's a simple crossfade instead
- [ ] **holographic pin:** on a collected pin's sheet, dragging turns it in 3D, the rainbow foil sheen follows the drag, and it springs back on release
- [ ] **my map** (map button, top right of collection): red explored-area circles, a dashed trail in visit order, stats, the replay slider and play button, the recent-visits chips, and the "show blocks you haven't collected" toggle
- [ ] **walk:** 15/30/45 picker → "plan my walk" → route + numbered stops; "listen" speaks with the device voice on mock data
- [ ] **lowercase:** every piece of text in the app is lowercase

## 3. Polish

- Tune the animation timings and foil intensity on a real device.
- Compare each screen against the "chair iPhone app" design canvas (the owner shares it).
- Add an app icon (`Assets.xcassets/AppIcon`, 1024×1024). A director's chair or a clapper in white on red fits.

## 4. Real backend

When the backend is deployed: create `Secrets.xcconfig` from `Secrets.example.xcconfig`, set `CHAIR_USE_MOCK_DATA = NO` and `CHAIR_BACKEND_BASE_URL`, then re-run section 2 with real data.

## Don't

- Don't add third-party packages, API keys in the app, or show/movie titles anywhere.
- Don't change the backend API shape without updating `backend/README.md` and `RemoteChairService`.
