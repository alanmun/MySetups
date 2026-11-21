# browser-tweaks

## Why
- Windows-style middle-click autoscroll in both browsers.
- Chrome on KDE sometimes fell back to the "basic" password store and lost cookies and logins. Forcing kwallet6 stops that.

## What it does
- `~/.local/share/applications/google-chrome.desktop` overrides the system launcher. All three `Exec` lines add `--password-store=kwallet6 --enable-blink-features=MiddleClickAutoscroll`.
- `firefox/user.js` is linked into each `*.default-release` profile: `general.autoScroll=true`, `middlemouse.paste=false`.

## Notes
- Chrome started directly from `/usr/bin/google-chrome-stable` (not through the launcher) doesn't get the flags. The override can also go stale when Chrome changes its own .desktop file; compare after big updates.
- Idea, not built: a guard that checks KWallet is unlocked before Chrome starts.
- 2026-11-19: Windows Firefox data (logins, places) was copied into the profile. That broke Sync sign-in until the user signed in again. Don't repeat it; use Firefox Sync.

## Status
- 2026-11-19 to 11-20: active on xbox720.
