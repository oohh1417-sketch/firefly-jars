# Firefly Jars (test version)

A web copy of the game for testing on phones. It shows pretend ads only.
The real game is built with Godot for Google Play and the App Store.

## Game source and iPhone build

- `game/` is the Godot 4.7.2 project (the real game for the App Store).
- `.github/workflows/ios.yml` builds it for iPhone on a GitHub Mac and sends it to TestFlight.
  Run it from Actions > "iPhone build" > Run workflow. It needs 4 secrets: APPLE_TEAM_ID, ASC_KEY_ID, ASC_ISSUER_ID, ASC_KEY_P8.
  Without them it only checks that the game compiles.
- `support.html` is the App Store support page.
