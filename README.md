# CursorIME [![CI](https://github.com/winebarrel/CursorIME/actions/workflows/ci.yml/badge.svg)](https://github.com/winebarrel/CursorIME/actions/workflows/ci.yml) [![AI Generated](https://img.shields.io/badge/AI%20Generated-Claude-orange?logo=anthropic)](https://claude.ai/claude-code)

CursorIME is a macOS utility that shows an "あ" badge next to the mouse
cursor while Japanese input is active. When you switch back to Roman input
the badge disappears, so a glance at the cursor tells you which mode you are
in.

It reads the current input mode through the Text Input Sources API, so it
works with Japanese IMEs such as Kotoeri, ATOK, and Google Japanese Input
without extra setup.

## Usage

Launch the app. It runs as a menu bar item with no Dock icon. The badge
follows the cursor only while Japanese input is on.

The menu bar icon has these items:

- **Launch at Login** toggles starting CursorIME when you log in.
- **Hide Menu Bar Icon** removes the icon. Click the app in Finder or
  Launchpad again to bring it back.
- **About** shows the standard about panel.
- **Quit** exits.

## Hiding the built-in input indicator

macOS shows its own input mode indicator near the text caret when you switch
input sources. To avoid a double indicator you can turn it off:

```sh
defaults write kCFPreferencesAnyApplication TSMLanguageIndicatorEnabled -bool false
```

Log out and back in for it to take effect. To restore the default:

```sh
defaults delete kCFPreferencesAnyApplication TSMLanguageIndicatorEnabled
```

CursorIME does not change this setting for you. The key lives in the global
preferences domain, which a sandboxed app cannot write, and the change only
applies after a re-login, so it is left as a one-time manual step.
