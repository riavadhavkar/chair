# Set Watch

An iPhone app that maps where NYC film/TV shoots happen, from the city's public film permits. People collect the most-filmed blocks by physically checking in at them, and each spot shows how many people have been there.

**Read `docs/IOS_APP_BRIEF.md` first.** It is the source of truth for screens, data model, API and look & feel. The design canvas is "Set Watch iPhone app": https://claude.ai/artifact/Mq6WmAvEq7i7pErSihnP17 (the owner shares it).

## Status

- `sair/` + `sair.xcodeproj` is the **retired macOS notch app**. Don't extend it. Delete it once the new iOS target builds.
- `backend/` (Node/Express) still serves the old notch API (`/nearby`, `/ask`, `/go/:id`). It will be reworked to the API in the brief. Until then the app runs on `MockSetWatchService`.

## Rules

- SwiftUI + MapKit + CoreLocation, iOS 26, no third-party packages.
- Permits have no show/movie titles. Never display or imply one (title matching is a future improvement).
- No fabricated visitor counts outside mock data.
- Respect Reduce Motion and Dynamic Type. Liquid Glass only for floating chrome.
- Secrets go in the gitignored `Secrets.xcconfig`. Never commit keys.
