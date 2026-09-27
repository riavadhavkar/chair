# chair — demo script (≈3:30)

Slides: "chair — divhacks 2026" deck. The same lines are in each slide's speaker notes.

## Before you go on

- [ ] Phone or simulator charged, volume **up**, Do Not Disturb **on**.
- [ ] **Mock mode** (safest) or backend running + `CHAIR_USE_MOCK_DATA = NO`. In mock mode, the counts are sample data. If a judge asks, say so.
- [ ] Simulator: Features ▸ Location ▸ Custom Location → **Grove St `40.7330, -74.0040`** (so check-in unlocks).
- [ ] Relaunch the app right before presenting. Mock data resets, so Grove St is uncollected again.
- [ ] Have a **screen recording of the demo** ready as a backup.

## Script

| # | Slide | Time | Say |
|---|---|---|---|
| 1 | cover | 0:10 | "Hi, I'm [name], and this is **chair**: an iPhone app that turns New York's public film permits into a map of where the city gets filmed, and lets you collect those blocks by actually walking to them." |
| 2 | pivot | 0:25 | "Quick confession: chair isn't what I started building. On day one I was building a Mac app that lived in the MacBook notch and showed live subway arrivals and delays from the MTA's real-time feeds. **At 3 pm on Saturday I pivoted.** Transit trackers are everywhere, and I wanted something only New York has. I also wanted people to prove they'd actually been somewhere, which a laptop can't do. So I threw out the notch and rebuilt as an iPhone app around the city's film permits." |
| 3 | problem | 0:15 | "New York is one of the most-filmed cities in the world, but most of us only find out when we walk past the trucks. Every shoot files a public permit with the city, and nobody reads them." |
| 4 | data | 0:20 | "This is a real permit: a category, a time window, and the street blocks the crew holds. We import every Manhattan permit since 2012 and fold them into one record per block. Permits don't say which show it was, so chair never guesses. Everything on screen is real city data." |
| 5 | app | 0:15 | "Three tabs. **Today**: every shoot happening right now. **Walk**: a narrated loop through the most-filmed blocks near you. **Collection**: pins you earn by showing up." |
| 6 | collection | 0:25 | "You collect a block by standing on it. The button only unlocks within 100 meters, and the server checks again. Every block has its own icon, picked by Gemini from the street itself. And it's shared: hundreds of visitors makes it *a classic*, three makes it a *secret spot*." |
| 7 | my map | 0:15 | "My Map shows a glow around every block you've collected and a trail through your visits. You can replay them one by one. Counts are shared, the trail stays private: we store an anonymous id, the block and the time. Nothing else." |
| 8 | **live demo** | 0:50 | See the demo steps below. |
| 9 | how it's built | 0:20 | "A Node importer pulls the permits from NYC Open Data into MongoDB Atlas. An Express API on DigitalOcean serves the SwiftUI app on Apple Maps. Gemini picks the icons and writes the narration, and it's told never to name a show. ElevenLabs voices the walk, with the phone's own voice as a fallback." |
| 10 | what's next | 0:15 | "Next, the big one is **VR scene replay**: stand on the block and watch the scene that was filmed there. That needs licensing from studios. Closer in: matching titles carefully and with sources, all five boroughs, and an iMessage version." |
| 11 | close | 0:05 | "New York already writes down where it gets filmed. chair lets you go collect it. Thank you!" |

### Live demo (0:50)
1. **today**: "Here's what's filming right now." Tap a pin, show the sheet, close it.
2. **collection** → tap **Grove St** (gray) → **check in here** → *let the spin and sparkles play, pause a beat.*
3. **Drag the red pin** → it turns in 3D with the holographic sheen.
4. Tap the map button → **my map** → press **play** on the replay.
5. **walk** → 30 min → **plan my walk** → **listen** for about 5 seconds → stop.

If anything fails, switch to the recording and keep talking: "here's the same flow recorded earlier."

## Likely questions

- **"How do you know which show it is?"** "We don't. Permits don't include titles. We decided showing real data beat guessing wrong. Matching titles with sources is on the roadmap."
- **"Can people fake check-ins?"** "The app gates on GPS accuracy and 100 m, and the server re-checks the distance. Device ids could be spoofed, so treat the count as a fun signal, not proof. Rate-limiting and device attestation would come next."
- **"Privacy?"** "No accounts, no location history. We store only an anonymous device id, the block and the time."
- **"Why iPhone and not web?"** "GPS-verified check-ins need a phone in your pocket, and Apple Maps is built in."
- **"What did Gemini actually do?"** "It picks an SF Symbol for each block from a fixed allowlist, so it can't make up an icon that doesn't exist, and it writes the walk narration from permit facts only."

## Devpost video (≤ 2 min): shot list
1. 0:00: the cover slide plus one line of pitch.
2. 0:10: the pivot slide (5 seconds).
3. 0:15: screen recording of today → check-in → spin and sparkles.
4. 0:45: holographic drag, then my map replay.
5. 1:10: walk + narration audio.
6. 1:30: the "how it's built" slide.
7. 1:45: the "what's next" slide and the closing line.
