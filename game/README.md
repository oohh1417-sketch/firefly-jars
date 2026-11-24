# Firefly Jars (v0.6)

Firefly Jars is a calm offline puzzle game. You tap a jar, then tap another jar to pour the top fireflies across. A level is solved when every color has its own jar.

![Menu](screenshot-menu.png) ![Level screenshot](screenshot-level.png)

## What works now
- Endless levels. Level 1 has 3 colors, and one color is added every 4 levels, up to 10. The same level number always produces the same puzzle.
- A built-in solver checks every level before you see it, so no level is impossible. Levels 1 to 120 were tested and all can be solved.
- Undo up to 3 times per level, restart the level, and use hints that point out the next good move.
- Progress and hints are saved on the phone. No internet is needed.
- Fireflies that come alive. Tapping a jar sends its top fireflies flying out to hover and circle above it. Pours fly across in an arc and leave a sparkle trail. A finished jar gets a cork that pops on with a burst of sparkles. Each level starts with the fireflies swarming in, and when you win they fly off into the sky. Wild fireflies drift in the background.
- Original music and sound effects, all made by `tools/make_audio.py`, so there is nothing to license. You can turn music and sounds on or off in the ≡ menu.
- All the art is drawn by code, so there are no image files to license.

## New look (v0.4 to v0.6)
- An animated main menu: a night scene with a big jar of fireflies, the Firefly Jars logo, chapter progress, a gold Play button and the daily puzzle card with your streak.
- Chapters of 10 levels, each with its own night scene: Meadow Glow, Willow Pond, Moonlit Garden, Lantern Woods, Starfall Hills, Misty Marsh, Crystal Creek and Aurora Ridge.
- Mason jars on wooden shelves. Color jars wear a ribbon in their color. Finished jars get a golden lid that screws itself on, with ticks, a click, a wobble and a shine.
- Glass buttons with line icons drawn in code. The Fredoka and Baloo 2 fonts are bundled under the free SIL Open Font License (see `fonts/OFL-*.txt`).
- v0.6 bug sweep: music starts on the first tap, smoother on phones, and fixes for Restart, Home and Undo during the win moment. Stress tests tap randomly through both versions and check every firefly lands in the right jar.

## Twists (new in v0.3)
- **Color jars** appear from level 10, on every third level. A jar with a colored outline and tag only accepts that color.
- **Lidded jars** appear from level 16, with two lids from level 30. The fireflies inside sleep until the lid's countdown reaches zero, and every pour counts it down by one.
- **Daily puzzle** (menu): one puzzle per date, with 7 colors, a color jar and a lid. Solving it grows your streak and gives +1 hint.
- A short explainer card appears the first time you meet each twist.
- Tested: levels 1 to 200 and 90 days of daily puzzles were all solved by the built-in solver, which follows the game's own rules. Playthroughs checked the blocked moves, undo with lids, and the streak.

## Try it on your computer (about 10 minutes, free)
1. Download **Godot 4.7.2** or newer (the "Standard" version) from godotengine.org. The project moved from 4.3 to 4.7 on 2026-11-23, so its Android build targets Android 16 (API 36), which Google Play requires.
2. Open Godot, click **Import**, and choose the `project.godot` file in this folder.
3. Press **F5**, or click the ▶ button at the top right. The game opens in a phone-shaped window, and your mouse works as your finger.

## Put it on an Android phone (later)
1. In Godot, go to **Editor > Manage Export Templates > Download**.
2. Install Android Studio, which provides the Android SDK, and point Godot to it under **Editor Settings > Export > Android**.
3. Go to **Project > Export**. The "Android" preset is already set up. Export it.

To upload to Google Play you will also need a signing key and the $25 developer account. We'll do that together when you're ready, and nothing gets published without your OK.

## Guesses I made (please check)
| Guess | Where to change it |
|---|---|
| The difficulty curve: 3 colors at the start, +1 color every 4 levels, 2 empty jars | `scripts/puzzle.gd`, `colors_for_level` |
| When twists appear (color jars from level 10, lids from 16) and lid counts of 3 to 6 | `scripts/puzzle.gd`, `spec_for_level` |
| Players start with 3 free hints and earn +1 every 5 levels | `scripts/save.gd` |
| Ads: a video ad gives +1 hint or +1 undo when you run out; a short ad between levels at most every 3 levels, from level 6, and at least 90 seconds apart. "Remove ads" turns off the between-level ads only | `scripts/ads.gd` |
| 3 undos per level, refilled when you restart. When they run out, the Undo button offers a rewarded ad for +1 (free in test builds) | `scripts/main.gd`, `UNDOS_PER_LEVEL` |
| The package name is `com.hatem.fireflyjars`. It can't be changed after the first Play upload | `export_presets.cfg` |
| The color palette is 10 colors. Some may be hard to tell apart for color-blind players | `scripts/board.gd`, `COLORS` |
| The app still uses Godot's default icon, and there is no splash screen | Next version |

## Ideas for the next version
A proper app icon, a $2.99 "Remove ads" purchase, and a color-blind mode with a pattern on each firefly.

## iPhone test version
There is a web copy of the game in `web/` for testing on an iPhone. It's published as a private link in the project. When you change the game rules, change them in both versions.

## Loading screen
On start, a jar fills with fireflies, its golden lid screws on, and the menu fades in. The phone's own launch image is `splash.png` (made from the same scene), so the Godot logo never shows.

## Turning on real ads (AdMob)
`scripts/ads.gd` already contains everything: Google's test ad IDs, the rules above, and a stand-in that gives rewards at once when no ad plugin is installed. To switch on real ads:
1. **Hatem:** create the AdMob account, add the Android and iOS apps, and make a Rewarded and an Interstitial ad unit for each. Then send the App IDs (they contain `~`) and the ad unit IDs (they contain `/`).
2. **Engine:** done. The project runs on Godot 4.7.2.
3. **Plugin:** in Godot, install "AdMob" by Poing Studios from the Asset Library and enable it under Project Settings > Plugins. Under Project Settings > Admob > General, turn on Android and iOS and paste the App IDs.
4. **IDs:** done. All of Hatem's ad unit IDs are in `REAL_IDS` at the top of `scripts/ads.gd`, and the App IDs are written in the comment above them. Debug builds keep using test ads, so nobody taps your real ads by mistake, which Google can ban an account for.
5. **Android:** choose Project > Install Android Build Template, then turn on "Use Gradle Build" in the Android export preset. This needs Android Studio on the computer that builds it.
6. **iPhone:** export from a Mac with Xcode. The plugin sets up the iOS side itself.
7. **Privacy:** set up the consent message in AdMob under Privacy & messaging. Both stores also need the privacy policy link.

## Tests
The `tests/` folder is left out of the exported game. Run each test from the project folder:
- `godot --headless -s tests/test_levels.gd`: solves levels 1 to 200 and checks every one is possible.
- `godot res://tests/run_test_ui.tscn`: plays levels 10 and 17 and a daily puzzle through the real screen, including blocked moves and undo with lids.
- `godot res://tests/run_fuzz.tscn`: a stress test of fast random taps, Undo, Hint, Restart and Home, checking that every firefly ends up in the right jar.
- `godot res://tests/run_undo.tscn` checks the 3-undo limit, and `godot res://tests/run_adtest.tscn` checks how often ads appear.

## App icon and first-level tutorial (v0.7)
- **App icon:** icon.png (1024, iPhone and App Store), icon_android_192.png plus icon_android_fg.png and icon_android_bg.png (Android adaptive icon, jar kept inside the safe zone). It's drawn in code by tools/make_icon.tscn, so you can regenerate it at any time.
- **Tutorial:** on level 1, a hand points at the jar to pick up, then at the jar to pour into, for the first 2 pours (TUT_GUIDED). Other jars ignore taps while it's guiding. After that the player finishes alone. It's saved as seen once level 1 is solved, and it's in both versions (main.gd `_tut_*`, Art.hand). Test: tests/run_tut.tscn.

## Hard levels (v0.8)
Every 5th level from level 10 (10, 15, 20, ...) is a **Hard level** (`Puzzle.is_hard`, `isHard` on the web).
- It has 2 more colors than the levels around it. Once 10 colors is reached, it gets a color jar and 2 lids instead.
- The game tries 5 solvable layouts and keeps the one the solver found hardest. Hard levels never introduce a new twist, so the color jar intro moved from level 10 to level 13.
- It shows a pink "Hard level" banner, a red-violet glow around the edges, a "HARD LEVEL" header and "Level N · Hard" on the Play button.
- Beating it gives +1 hint. That replaces the old "+1 hint every 5 levels", which stays only for levels 4 and 9.
- Levels 1 to 200 are verified solvable in both versions. Test: tests/run_hard.tscn.

## Drag and drop (v0.9)
After tapping a jar, the lifted fireflies can be **dragged** with a finger. They follow it one behind another, leaving a glowing trail, and the jar they would land in glows (red if they can't go there).
- Let go over a jar to pour. Let go in the air, or over a jar that can't take them, and they fly home.
- Tap-then-tap still works too.
- The level 1 tutorial teaches a tap for the first pour, then shows the hand dragging a firefly for the second.
- Code: board.gd `_press/_release/_drag_pos/_draw_drag/_draw_drag_demo`, main.gd `_on_drag_dropped`. The web version has the same logic. Test: tests/run_drag.tscn.

## Move limit on Hard levels (v0.10)
- Hard levels allow the fewest possible pours (found by an exact A* search, `Puzzle.shortest_path`) plus 35%, at least 5 more. This is a GUESS that's easy to tune in `move_limit`.
- A pill under the level number counts the moves left. It turns amber at 5 and red at 2.
- Undo gives the move back.
- At 0 moves an "Out of moves" card offers "+5 moves" (a rewarded video) or "Try again".
- On Hard levels, hints follow the shortest route. Normal levels and the daily puzzle have no limit.
- In Godot the limit is worked out on a background thread when the level starts (under 1.5 s on a desktop).
- Test: tests/run_limit.tscn.

## Settings (v0.11)
The gear button on the menu opens Settings, with these options:
- Music, Sounds and Vibration switches.
- **Color-blind mode:** every firefly color also gets its own dark shape (dot, triangle, square, plus, diamond, cross, ring, bars, chevron, line), and color-jar ribbons show the shape too. Code: `Art.symbol` and `paintSymbol`.
- **Show tutorial again:** replays the level 1 tutorial in a practice mode that doesn't touch saved progress.
- **Privacy policy:** shown in the game, so it works offline. web/privacy.html is the same text as a web page for the store listings.
- Contact email in the privacy policy: fireflyjars.support@gmail.com.
- All hints now follow the shortest solution, so following hints always makes progress.
- Test: tests/run_settings.tscn.

## Bug and lag sweep (v0.12)
- **Hints:** a hint now follows one planned route (`hintPlan` / `_hint_plan`). Pressing Hint again and again always finishes the level, and the route is searched again only when the player leaves it. Before this, a deep search on every press could freeze the game for up to half a second.
- **Hard level start:** the exact move-limit search, and in Godot the whole next level, are now prepared ahead of time, while the win card or menu is showing. So starting a level doesn't stutter.
- **Godot solver:** it no longer uses a shared counter, so it's safe on background threads and the same level number always gives the same puzzle.
- **New sweep tests:** shots/sweep.js on the web and tests/run_sweep.tscn in Godot. They mix random taps, drags, undo, hints, restarts, out-of-moves, settings, practice and daily, and check the game rules after every few actions.

## Coins, Remove ads, cracked jar, trophies, analytics (v0.14)
- Coins: +10 per level, +25 hard level, +30 daily puzzle (first solve of the day). The win card can double them with a video.
  Prices: hint 150, extra undo 100, +5 moves 120, mending the cracked jar 200. The free video stays available everywhere.
- Cracked jar (from level 3 and in the daily puzzle): tap it, then a video or 200 coins sends two golden helper fireflies
  to mend it. It is one more empty jar for that level (it stays mended after a restart).
- Remove ads ($2.99): scripts/store.gd (Google Play Billing / StoreKit plugins, or a test store without them). Settings has
  Remove ads and Restore purchases. It stops between-level ads only.
- Trophies (12) and leaderboards (3), plus a cloud copy of progress: scripts/services.gd (Game Center + iCloud, Play Games).
  Everything works offline without sign-in.
- Analytics: scripts/analytics.gd sends events to Firebase when the plugin is in the build; otherwise nothing is sent.
- New sounds from tools/make_audio.py: twinkle (fireflies flying), coin, repair.
- Tests: tests/run_v14.tscn.

## Chapter map and 20 chapter scenes (v0.17)

- 20 chapters of 10 levels, each with its own night scene (200 levels before a scene repeats; after that the
  names get a number, like "Meadow Glow 2"). New scenes: Cherry Blossom Grove, Desert Oasis, Firefly Falls,
  Mushroom Hollow, Autumn Orchard, Frozen Lake, Lighthouse Shore, Bamboo Valley, Sunflower Fields,
  Glowing Lagoon, Floating Isles, Rainbow Sky.
- Scenes are drawn in `scripts/scenes.gd` (web: `paintSky`, `paintLand`, `paintLive`), into any W x H area, so the
  same drawing is used behind the jars and in the map.
- Tapping Play opens the chapter map (`scripts/map_view.gd`, web: `drawMap`): a winding trail with one stone per
  level, level 1 at the bottom. Finished stones glow, the current one pulses with a firefly on it (tap it or the
  Play button to start), hard levels have a pink star, locked chapters are dimmed with a lock on their sign.
- Finishing a chapter (the 10th level) opens the map instead of the next level: it climbs to the new chapter and
  shows "New chapter!" with sparkles. `Save.map_ch` (web `save.mapCh`) remembers the last celebrated chapter.
