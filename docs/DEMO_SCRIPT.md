# chair — demo script (≈3:30)

slides: "chair — divhacks 2026" deck. the same lines are in each slide's speaker notes.

## before you go on

- [ ] phone or simulator charged, volume **up**, do not disturb **on**.
- [ ] **real data:** backend running (`npm start`, with `MONGODB_URI` set so check-ins survive a restart) and `CHAIR_USE_MOCK_DATA = NO` in `Secrets.xcconfig`, rebuilt with ⌘R.
- [ ] **pick your check-in block:** run `curl -s localhost:8080/collection | head -c 600` and choose one block. note its `name`, `lat` and `lon`.
- [ ] simulator: features ▸ location ▸ custom location → that block's **`lat, lon`** (so check-in unlocks).
- [ ] **seed my map:** check in at 2 other blocks beforehand (set the location to each, then check in), so the replay has something to play. those are real check-ins, so their counts are honest.
- [ ] expect **today** to be empty on a weekend. that's the point of step 1 below.
- [ ] have a **screen recording of the demo** ready as a backup.

## script

| # | slide | time | say |
|---|---|---|---|
| 1 | cover | 0:10 | "hi, i'm [name], and this is **chair**: an iphone app that turns new york's public film permits into a map of where the city gets filmed, and lets you collect those blocks by actually walking to them." |
| 2 | pivot | 0:25 | "quick confession: chair isn't what i started building. on day one i was building a mac app that lived in the macbook notch and showed live subway arrivals and delays from the mta's real-time feeds. **at 3 pm on saturday i pivoted.** transit trackers are everywhere, and i wanted something only new york has. i also wanted people to prove they'd actually been somewhere, which a laptop can't do. so i threw out the notch and rebuilt as an iphone app around the city's film permits." |
| 3 | problem | 0:15 | "new york is one of the most-filmed cities in the world, but most of us only find out when we walk past the trucks. every shoot files a public permit with the city, and nobody reads them." |
| 4 | data | 0:20 | "this is a real permit: a category, a time window, and the street blocks the crew holds. we import every manhattan permit since 2012 and fold them into one record per block. permits don't say which show it was, so chair never guesses. everything on screen is real city data." |
| 5 | app | 0:15 | "three tabs. **today**: every shoot happening right now. **walk**: a narrated loop through the most-filmed blocks near you. **collection**: pins you earn by showing up." |
| 6 | collection | 0:25 | "you collect a block by standing on it. the button only unlocks within 100 meters, and the server checks again. every block has its own icon, picked by gemini from the street itself. and it's shared: hundreds of visitors makes it *a classic*, three makes it a *secret spot*." |
| 7 | my map | 0:15 | "my map shows a glow around every block you've collected and a trail through your visits. you can replay them one by one. counts are shared, the trail stays private: we store an anonymous id, the block and the time. nothing else." |
| 8 | **live demo** | 0:50 | see the demo steps below. |
| 9 | how it's built | 0:20 | "a node importer pulls the permits from nyc open data into mongodb atlas. an express api on digitalocean serves the swiftui app on apple maps. gemini picks the icons and writes the narration, and it's told never to name a show. elevenlabs voices the walk, with the phone's own voice as a fallback." |
| 10 | what's next | 0:15 | "next, the big one is **vr scene replay**: stand on the block and watch the scene that was filmed there. that needs licensing from studios. closer in: matching titles carefully and with sources, all five boroughs, and an imessage version." |
| 11 | close | 0:05 | "new york already writes down where it gets filmed. chair lets you go collect it. thank you!" |

### live demo (0:50)
1. **today** shows *"nothing filming near you today."* say: "this is live city data, and right now it's honest: it's the weekend, and the city publishes permits with a lag. on a weekday this map fills up with shoots. but the permit history is where it gets fun." → go to collection.
2. **collection** → tap **[your block]** (gray) → **check in here** → *let the spin and sparkles play, pause a beat.* its counter shows real visits, probably "be the first here" or a small number, and that's the secret-spot feeling.
3. **drag the red pin** → it turns in 3d with the holographic sheen.
4. tap the map button → **my map** → press **play** on the replay.
5. **walk** → 30 min → **plan my walk** → **listen** for about 5 seconds → stop.

if anything fails, switch to the recording and keep talking: "here's the same flow recorded earlier." if the backend itself is down, flip `CHAIR_USE_MOCK_DATA = YES`, rebuild, and demo on sample data (say so if asked).

## likely questions

- **"how do you know which show it is?"** "we don't. permits don't include titles. we decided showing real data beat guessing wrong. matching titles with sources is on the roadmap."
- **"can people fake check-ins?"** "the app gates on gps accuracy and 100 m, and the server re-checks the distance. device ids could be spoofed, so treat the count as a fun signal, not proof. rate-limiting and device attestation would come next."
- **"privacy?"** "no accounts, no location history. we store only an anonymous device id, the block and the time."
- **"why iphone and not web?"** "gps-verified check-ins need a phone in your pocket, and apple maps is built in."
- **"what did gemini actually do?"** "it picks an sf symbol for each block from a fixed allowlist, so it can't make up an icon that doesn't exist, and it writes the walk narration from permit facts only."

## devpost video (≤ 2 min): shot list
1. 0:00: the cover slide plus one line of pitch.
2. 0:10: the pivot slide (5 seconds).
3. 0:15: screen recording of today → check-in → spin and sparkles.
4. 0:45: holographic drag, then my map replay.
5. 1:10: walk + narration audio.
6. 1:30: the "how it's built" slide.
7. 1:45: the "what's next" slide and the closing line.
