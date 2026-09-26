# Set Watch

A macOS notch app that shows which film/TV productions are shooting near you right now in NYC, using the city's public film permits. Titles and posters come from TMDB when a title is available.

## Layout

- `sair/`: macOS app (SwiftUI + AppKit, no UIKit, no third-party packages). Xcode uses synchronized folders, so new `.swift` files need no project edits.
  - `AppDelegate.swift`: borderless window above the menu bar level, flush with the top screen edge, sized from the real notch (`NotchWindowState.notchSize`). The window grows before the expand animation starts and shrinks only after the collapse animation ends.
  - `Views/NotchShape.swift`: the single black shape (concave shoulders, animatable bottom radius) plus `NotchLayout` sizes.
  - `Views/RootContentView.swift`: hover 0.4s expands, leaving for 0.6s collapses, tap expands.
  - `Views/NotchPillView.swift`: the notch row. Leading content sits left of the camera, trailing content (REC dot + blocks) sits right. It never moves between states.
  - `Views/ExpandedPanelView.swift`: card or map, controls (Directions / voice / map), pager, attribution, and the empty/offline/loading states.
  - `Views/ProductionCardView.swift`: the matched card (poster) and the permit-only card (dashed slate + raw permit text). These two must look clearly different.
  - `Models/Production.swift`: Codable mirror of the backend `/nearby` JSON, plus fictional `.mock` data (used as the initial state in DEBUG builds).
  - `Models/NearbyFeedModel.swift`: polling (2 min expanded, 5 min idle), selection, stale state.
  - `Models/SavedPlace.swift`: "near me" location, stored in UserDefaults behind a protocol so a Backboard store can replace it.
- `backend/`: Node/Express. `GET /nearby`, `POST /ask`, `GET /go/:id`. See `backend/README.md`.

## Design

The design reference is the "Set Watch notch interface" canvas, with 7 artboards: idle matched, idle permit-only, expanded matched, expanded permit-only, map, empty, iMessage. The owner shares the link.

- Everything is black. The shape blends into the physical notch.
- The only accent color is the red REC dot, which means "filming now".
- Use SF Pro and SF Symbols only. White text, with secondary text at about #aeaeb2.
- Buttons: Directions is a white pill. Voice and map are 36pt circles with a hairline border.
- Always say where each fact came from: TMDB or the NYC film permit.

## Rules

- The permit dataset has no title field. Never imply a match the backend didn't return (`match == nil` means show the permit-only card).
- Respect Reduce Motion. The window must never become key.
- Secrets go in the gitignored `Secrets.xcconfig` (see `Secrets.example.xcconfig`). Never commit keys.
