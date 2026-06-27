# Batch Minecraft Launcher

A command-line Minecraft launcher: `launcher.bat` calls a few PowerShell
scripts to download a version, log you in with your Microsoft account, and
launch the game.

## Setup

1. **Java** - install Java (17+ for modern Minecraft, 8 for very old
   versions) and make sure `java` is on your PATH, or set the full path to
   `javaw.exe`/`java.exe` in `config.json` under `java_path`.

2. Run `launcher.bat` once - it creates `config.json`.

3. Run `launcher.bat`, enter a version ID (e.g. `1.21`), then choose a mode:
   - **Offline / guest profile** - just type a username, no account needed.
     Works for singleplayer and offline-mode servers. Skip straight to step 5.
   - **Microsoft account login** - see step 4 first.

4. *(Microsoft login only)* Register a free Azure app - required by
   Microsoft for any third-party app that logs in with a Microsoft account,
   official launcher included:
   - Go to https://portal.azure.com -> "App registrations" -> "New registration"
   - Name: anything, e.g. "BLauncher"
   - Supported account types: "Personal Microsoft accounts only"
   - Redirect URI: leave blank for now -> Register
   - Copy the **Application (client) ID** shown on the overview page
   - Go to "Authentication" -> "Add a platform" -> "Mobile and desktop
     applications" -> check `https://login.microsoftonline.com/common/oauth2/nativeclient` -> Configure
   - Still on the Authentication page, set "Allow public client flows" to
     **Yes** -> Save
   - Paste the client ID into `config.json` -> `client_id`

5. It downloads the version (first time only), then either shows a device
   login code (Microsoft mode) or launches straight away (offline mode).

Your Microsoft login is cached in `data\` so you won't need to repeat the
device-code step every time (until the refresh token itself expires).
Offline profiles aren't cached - it's just a deterministic UUID generated
from the username each time, same as the official launcher does.

## Known limitations

- Only the "modern" version JSON format (1.13+) is supported for libraries
  and arguments. Older versions use a different libraries layout and will
  be rejected with an error rather than silently failing.
- No automatic Java version selection - if the wrong Java version is on
  your PATH, the game may fail to start; point `java_path` at the right one.
- No mod loader support (Forge/Fabric/Quilt), no GUI.
- Offline profiles can't join online-mode multiplayer servers - there's no
  real account behind them, so the server can't verify who you are.
- `data\auth-cache.json` and `data\session.json` hold your Microsoft login
  tokens in plain text - don't share that folder.

## Folder layout after running

```
MCLauncher/
  launcher.bat
  config.json
  scripts/
    Common.ps1
    Download.ps1
    Auth.ps1
    Launch.ps1
  data/
    auth-cache.json
    session.json
  game/
    versions/<id>/...
    libraries/...
    assets/...
```
## Credits
- Made by baconroaster23 on discord 
Made with love from CLDevs Team
