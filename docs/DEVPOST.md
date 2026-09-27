# chair — devpost submission (copy/paste)

fill in anything in [brackets] before submitting.

---

## project name
chair

## elevator pitch
collect the blocks where new york gets filmed. chair turns nyc's public film permits into a live map and gps-verified pins you earn by showing up.

---

## project description (paste into the big box)

## inspiration
this isn't the project we started. on day one we were building a mac app that lived in the macbook notch and showed live subway arrivals and delays from the mta's real-time feeds. at **3 pm on saturday we pivoted**. transit trackers are everywhere, and we wanted to build something only new york has. we also wanted people to be able to prove they'd been somewhere, which a laptop can't do.

new york is one of the most-filmed cities in the world, but most of us only notice when we walk past the trailers and "no parking" signs. every shoot files a permit with the city, and that data is public. nobody reads it because it's a spreadsheet of street closures. we wanted to turn it into something you can go out and experience.

## what it does
chair is an iphone app with three tabs:

- **today**: a map of every film permit active right now, nearest first.
- **walk**: pick 15, 30 or 45 minutes and chair plans a loop through the most-filmed blocks near you. gemini writes the narration and elevenlabs reads it aloud.
- **collection**: each neighborhood's most-filmed blocks become pins. the only way to collect one is to **physically go there**. the check-in unlocks within 100 m and the server verifies it again. collecting plays a spin-and-sparkle animation, and collected pins can be dragged to turn in 3d with a holographic sheen.

every pin shows **how many people have been there**. hundreds of visitors makes it *a classic*, a handful makes it a *secret spot*, so you get either validation or discovery. **my map** shows the area you've explored, a trail through your visits and a replay of your history.

permits never say which show was filming, so chair never guesses. every fact on screen comes from city data.

## how we built it
- **data:** a node importer pulls every manhattan film permit since 2012 from **nyc open data**, parses the held street blocks ("w 20 st between 5 av and 6 av"), and folds them into one record per block: times filmed, last shoot, neighborhood. each neighborhood's 12 most-filmed blocks become the collectible set.
- **geocoding:** **nyc geoclient** turns each block's cross streets into coordinates. we use the midpoint of the two intersections.
- **backend:** express api with **mongodb atlas** for blocks, check-ins (unique per device per block) and walks, hosted on **digitalocean**. tested with node's built-in test runner.
- **ai:** **gemini** picks an sf symbol for every block from a fixed allowlist, so it can't invent an icon that doesn't exist, and writes the walk narration from permit facts. it's instructed never to name a show. **elevenlabs** voices the narration. the app falls back to the phone's built-in voice so the demo never breaks.
- **app:** swiftui, mapkit (apple maps, walking directions) and corelocation on ios 26, with no third-party packages and no api keys in the app. everything runs on mock data too, so the ui could be built before the backend.

## challenges we ran into
- **the pivot.** throwing away a working prototype at 3 pm on saturday and rebuilding the data layer, backend and app in the time left.
- **permits have no titles.** we had to design the whole experience around what the data actually says, instead of the "law & order is filming here" pitch we first imagined.
- **turning street closures into points.** permits describe blocks as text, not coordinates. parsing and geocoding them reliably took several tries.
- **honest gps check-ins** that still work on a phone with a noisy gps signal (100 m in the app, a little more slack on the server).
- **xcode build issues.** swift 6's default main-actor isolation threw warnings on our model classes, and macos's case-insensitive disk made xcode report the project folder as `Chair` in one place and `chair` in another until we renamed everything to lowercase. also, `//` starts a comment in `.xcconfig` files, which silently cut our backend url in half.
- **api key setup.** juggling keys for gemini, elevenlabs, mongodb atlas and nyc geoclient. the geoclient portal's endpoint path didn't match older docs, and we kept every key on the server so the app itself ships with none.
- **mongodb atlas network access.** atlas only accepts connections from allowlisted ips, and our public ip changed every time we switched wifi, went to cellular or used a vpn, so we had to keep re-adding it. for a dev database used from many networks, allowing `0.0.0.0/0` is more practical but less secure, and we had to decide that deliberately rather than default into it.

## accomplishments that we're proud of
- a shared "who's been here" counter that makes a quiet side street feel like a secret and a famous block feel like a pilgrimage.
- the collect moment: the pin spins as it gains color, sparkles burst, and you can turn it in your hand.
- every fact comes from public data. we never invent a title or a visitor count.
- rebuilding end to end after a mid-hackathon pivot.

## what we learned
- public city data is rich but messy. the work is in turning it into something human.
- constraining an llm (an allowlist of icons, "only use these facts") makes it far more reliable.
- design around the data you have, not the data you wish you had.
- [add your own]

## what's next for chair
- **vr scene replay:** stand on the block and watch the scene that was filmed there, in place. this requires licensing from studios.
- matching permits to titles, carefully and with sources.
- all five boroughs.
- an imessage version ("what's filming near me?") via photon.
- stronger anti-spoofing for check-ins.

---

## built with (tags)
swift, swiftui, mapkit, corelocation, avfoundation, ios, xcode, node.js, express.js, javascript, mongodb-atlas, digitalocean, gemini-api, elevenlabs, nyc-open-data, nyc-geoclient, socrata

## "try it out" links
- https://github.com/riavadhavkar/chair
- [https://yourdomain.tech]: only if you deployed it

## image gallery (3:2, ≤5 mb each)
1. app icon on the red background (`chair/Assets.xcassets/AppIcon.appiconset/AppIcon.png`)
2. screenshots: today map, collection grid, spot sheet mid-spin, holographic pin, my map, walk
3. the "how it's built" slide
4. the "pivot" slide

## video demo link
[youtube/vimeo link]. use the shot list in `docs/DEMO_SCRIPT.md`.

## sponsor / special prizes. select:
- ✅ **track winner: know your city** (primary fit)
- ✅ **[mlh] best use of gemini api**
- ✅ **[mlh] best use of elevenlabs**
- ✅ **[mlh] best use of mongodb atlas** (only if check-ins are stored in atlas for the demo)
- ✅ **[mlh] best use of digitalocean** (only if the backend is actually deployed there)
- ✅ **[mlh] best .tech domain name** (only if you registered and use a .tech domain)
- ❌ photon, solana, tiger data, backboard, nessie, ripple, spacexai, deepspace: not used, so don't select

## universities / schools
[your school]

## .tech domains registered
[yourdomain.tech]

## technology feedback (draft — edit to your own words)
- **nyc open data:** great that film permits are public, but there's no production title field, and locations are free text ("x between y and z"), so they're hard to map without extra geocoding.
- **nyc geoclient:** the intersection endpoint is exactly what we needed. the api portal's paths and the older docs didn't quite match, which cost us some time.
- **mongodb atlas:** fast to set up. the ip access list tripped us up: our ip changed when we switched networks, and allowing 0.0.0.0/0 is a tradeoff you have to make deliberately.
- **gemini api:** constraining output to an allowlist worked well. replies sometimes came wrapped in markdown code fences, so we parse defensively.
- **elevenlabs:** the text-to-speech api was simple to call and sounded great for narration.
- **xcode:** a gotcha: `//` starts a comment in `.xcconfig` files, so urls have to be written as `https:/$()/host`.

## ai tools used this weekend
✅ anthropic · ✅ gemini · ✅ elevenlabs · [✅ digitalocean gradient only if you used it]

## did you implement a generative ai model or api?
yes. **gemini** (`[model you used]`) runs during the data import and picks an sf symbol icon for each collectible street block from a fixed allowlist, so every block's pin reflects the street itself and can never be a nonexistent icon. it also writes the spoken narration for each walk, using only facts from the city's film permits, and is explicitly instructed never to name a tv show or movie, because the permits don't include titles. **elevenlabs** turns that narration into audio. we used generative ai to make raw permit data feel personal (icons and a spoken tour) while keeping every fact grounded in city data.

**gemini project number:** [paste from ai studio → get api key → project number]
