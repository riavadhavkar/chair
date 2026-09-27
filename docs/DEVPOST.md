# chair — Devpost submission (copy/paste)

Fill in anything in [brackets] before submitting.

---

## Project name
chair

## Elevator pitch
Collect the blocks where New York gets filmed. chair turns NYC's public film permits into a live map and GPS-verified pins you earn by showing up.

---

## Project description (paste into the big box)

## Inspiration
This isn't the project we started. On day one we were building a Mac app that lived in the MacBook notch and showed live subway arrivals and delays from the MTA's real-time feeds. At **3 pm on Saturday we pivoted**. Transit trackers are everywhere, and we wanted to build something only New York has. We also wanted people to be able to prove they'd been somewhere, which a laptop can't do.

New York is one of the most-filmed cities in the world, but most of us only notice when we walk past the trailers and "no parking" signs. Every shoot files a permit with the city, and that data is public. Nobody reads it because it's a spreadsheet of street closures. We wanted to turn it into something you can go out and experience.

## What it does
chair is an iPhone app with three tabs:

- **Today**: a map of every film permit active right now, nearest first.
- **Walk**: pick 15, 30 or 45 minutes and chair plans a loop through the most-filmed blocks near you. Gemini writes the narration and ElevenLabs reads it aloud.
- **Collection**: each neighborhood's most-filmed blocks become pins. The only way to collect one is to **physically go there**. The check-in unlocks within 100 m and the server verifies it again. Collecting plays a spin-and-sparkle animation, and collected pins can be dragged to turn in 3D with a holographic sheen.

Every pin shows **how many people have been there**. Hundreds of visitors makes it *a classic*, a handful makes it a *secret spot*, so you get either validation or discovery. **My Map** shows the area you've explored, a trail through your visits and a replay of your history.

Permits never say which show was filming, so chair never guesses. Every fact on screen comes from city data.

## How we built it
- **Data:** a Node importer pulls every Manhattan film permit since 2012 from **NYC Open Data**, parses the held street blocks ("W 20 St between 5 Av and 6 Av"), and folds them into one record per block: times filmed, last shoot, neighborhood. Each neighborhood's 12 most-filmed blocks become the collectible set.
- **Geocoding:** **NYC Geoclient** turns each block's cross streets into coordinates. We use the midpoint of the two intersections.
- **Backend:** Express API with **MongoDB Atlas** for blocks, check-ins (unique per device per block) and walks, hosted on **DigitalOcean**. Tested with Node's built-in test runner.
- **AI:** **Gemini** picks an SF Symbol for every block from a fixed allowlist, so it can't invent an icon that doesn't exist, and writes the walk narration from permit facts. It's instructed never to name a show. **ElevenLabs** voices the narration. The app falls back to the phone's built-in voice so the demo never breaks.
- **App:** SwiftUI, MapKit (Apple Maps, walking directions) and CoreLocation on iOS 26, with no third-party packages and no API keys in the app. Everything runs on mock data too, so the UI could be built before the backend.

## Challenges we ran into
- **The pivot.** Throwing away a working prototype at 3 pm on Saturday and rebuilding the data layer, backend and app in the time left.
- **Permits have no titles.** We had to design the whole experience around what the data actually says, instead of the "Law & Order is filming here" pitch we first imagined.
- **Turning street closures into points.** Permits describe blocks as text, not coordinates. Parsing and geocoding them reliably took several tries.
- **Honest GPS check-ins** that still work on a phone with a noisy GPS signal (100 m in the app, a little more slack on the server).
- [add your own — e.g. Xcode build issues, API key setup]

## Accomplishments that we're proud of
- A shared "who's been here" counter that makes a quiet side street feel like a secret and a famous block feel like a pilgrimage.
- The collect moment: the pin spins as it gains color, sparkles burst, and you can turn it in your hand.
- Every fact comes from public data. We never invent a title or a visitor count.
- Rebuilding end to end after a mid-hackathon pivot.

## What we learned
- Public city data is rich but messy. The work is in turning it into something human.
- Constraining an LLM (an allowlist of icons, "only use these facts") makes it far more reliable.
- Design around the data you have, not the data you wish you had.
- [add your own]

## What's next for chair
- **VR scene replay:** stand on the block and watch the scene that was filmed there, in place. This requires licensing from studios.
- Matching permits to titles, carefully and with sources.
- All five boroughs.
- An iMessage version ("what's filming near me?") via Photon.
- Stronger anti-spoofing for check-ins.

---

## Built with (tags)
swift, swiftui, mapkit, corelocation, avfoundation, ios, xcode, node.js, express.js, javascript, mongodb-atlas, digitalocean, gemini-api, elevenlabs, nyc-open-data, nyc-geoclient, socrata

## "Try it out" links
- https://github.com/riavadhavkar/chair
- [https://yourdomain.tech]: only if you deployed it

## Image gallery (3:2, ≤5 MB each)
1. App icon on the red background (`Chair/Assets.xcassets/AppIcon.appiconset/AppIcon.png`)
2. Screenshots: today map, collection grid, spot sheet mid-spin, holographic pin, my map, walk
3. The "how it's built" slide
4. The "pivot" slide

## Video demo link
[YouTube/Vimeo link]. Use the shot list in `docs/DEMO_SCRIPT.md`.

## Sponsor / special prizes. Select:
- ✅ **Track Winner: Know Your City** (primary fit)
- ✅ **[MLH] Best Use of Gemini API**
- ✅ **[MLH] Best Use of ElevenLabs**
- ✅ **[MLH] Best Use of MongoDB Atlas** (only if check-ins are stored in Atlas for the demo)
- ✅ **[MLH] Best Use of DigitalOcean** (only if the backend is actually deployed there)
- ✅ **[MLH] Best .Tech Domain Name** (only if you registered and use a .tech domain)
- ❌ Photon, Solana, Tiger Data, Backboard, Nessie, Ripple, SpaceXAI, DeepSpace: not used, so don't select

## Universities / schools
[your school]

## .Tech domains registered
[yourdomain.tech]

## Technology feedback (draft — edit to your own words)
- **NYC Open Data:** great that film permits are public, but there's no production title field, and locations are free text ("X between Y and Z"), so they're hard to map without extra geocoding.
- **NYC Geoclient:** the intersection endpoint is exactly what we needed. The API portal's paths and the older docs didn't quite match, which cost us some time.
- **MongoDB Atlas:** fast to set up. The IP access list tripped us up: our IP changed when we switched networks, and allowing 0.0.0.0/0 is a tradeoff you have to make deliberately.
- **Gemini API:** constraining output to an allowlist worked well. Replies sometimes came wrapped in markdown code fences, so we parse defensively.
- **ElevenLabs:** the text-to-speech API was simple to call and sounded great for narration.
- **Xcode:** a gotcha: `//` starts a comment in `.xcconfig` files, so URLs have to be written as `https:/$()/host`.

## AI tools used this weekend
✅ Anthropic · ✅ Gemini · ✅ ElevenLabs · [✅ DigitalOcean Gradient only if you used it]

## Did you implement a generative AI model or API?
Yes. **Gemini** (`[model you used]`) runs during the data import and picks an SF Symbol icon for each collectible street block from a fixed allowlist, so every block's pin reflects the street itself and can never be a nonexistent icon. It also writes the spoken narration for each walk, using only facts from the city's film permits, and is explicitly instructed never to name a TV show or movie, because the permits don't include titles. **ElevenLabs** turns that narration into audio. We used generative AI to make raw permit data feel personal (icons and a spoken tour) while keeping every fact grounded in city data.

**Gemini Project Number:** [paste from AI Studio → Get API key → Project number]
