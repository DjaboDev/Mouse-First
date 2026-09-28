# Changelog

## 0.2.0

A rewrite of the plugin's internals. Every v0.1 feature is still there, and your existing `~/.config/omarchy/mouse-first.json` keeps working.

### Fixed
- The controls now stay attached to the window during <kbd>SUPER</kbd> + drag, border resizes and keyboard moves.
- Pulling a snapped or maximized window out with <kbd>SUPER</kbd> + drag no longer detaches it from the cursor. The window returns to its previous size when you drop it.
- Dragging a snapped or maximized window from the top strip restores it immediately, with the grabbed point staying under the cursor.
- Maximize and restore no longer race Hyprland, so the button icon always shows the real state. Windows maximized with Hyprland's own keybind are recognized.
- On multi-monitor setups the controls, snapping and dragging now work on every monitor, and windows can be dragged between monitors. Previously each monitor drew its own copy of the controls, positioned in the wrong coordinates.
- Snapping now respects the bar and dock on every side and uses your Hyprland gaps. Reserved space was previously hard-coded.
- "Disable tiling" now uses a window rule, so windows open floating instead of jumping from tiled to floating. Turning it off takes effect right away.
- Opening a special workspace, such as the Omarchy scratchpad, no longer steals focus.
- Minimized windows now use `special:minimized` and appear in omadock. Windows restored after a shell restart return to the workspace they came from, instead of workspace 1.
- The settings file is written atomically and no longer breaks on special characters.
- Memory used for closed windows is now released.

### Added
- Snapping, snap preview and immediate un-snapping also work with <kbd>SUPER</kbd> + drag and app title bars. The plugin takes over drags that Hyprland starts on floating windows.
- Resizing a snapped window by its inner border resizes its snapped neighbour too.
- Bar icons group the windows of each app, with a window count; clicking cycles through them. A right-click menu lists the windows and offers *New window*, *Pin/Unpin* (shared with omadock) and *Close*.
- New options:
  - drag to the top edge to maximize;
  - center new windows (on or off);
  - built-in snapping shortcuts (<kbd>SUPER</kbd> + <kbd>CTRL</kbd> + <kbd>SHIFT</kbd> + arrows, off by default);
  - hide the controls for chosen apps.
- The controls are skipped on picture-in-picture players and windows too narrow for them.
- Spanish translation.
- The icon index is cached on disk and rebuilt only when an icon is missing.

### Changed
- The plugin is now a shell service plus a small bar widget. It is event-driven: no polling and no helper scripts. The seven `bin/` scripts (Python/Bash) are gone.
- Colors come from Omarchy's theme API instead of parsing `colors.toml` every five seconds.
- Added a language selector (English/Português) to the settings panel.
- Added IPC actions for keyboard shortcuts (`snap`, `toggleMaximize`, `minimize`, `restoreLast`, `settings`, `status`).
- Removed `install.sh`. Install with `omarchy plugin add`. The plugin no longer writes to `~/.config/hypr/looknfeel.lua`.

## 0.1.0

- Initial release.
