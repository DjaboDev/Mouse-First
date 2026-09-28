<h1 align="center">Mouse-First</h1>

<p align="center">
  <b>Mouse-driven window management for Hyprland on Omarchy.</b>
</p>

<p align="center">
  <img src="preview.png" alt="Mouse-First window controls on Omarchy" width="100%">
</p>

Mouse-First adds the desktop conveniences mouse users expect to Hyprland: minimize, maximize and close buttons on the active window, dragging windows by their top edge, edge and corner snapping, and app icons on the system bar. Keyboard workflows keep working as before.

<p align="center">
  <img src="assets/02.png" alt="Mouse-First workflow overview" width="100%">
</p>

## Features

- **Window controls.** A small capsule at the top-right corner of the active window with minimize, maximize/restore and close buttons (plus an optional float/tile button). You can reorder the buttons, hide any of them, and drag the capsule to a different spot.
- **Top-edge dragging.** Grab any window by the strip along its top edge and move it, including onto another monitor. Double-click the strip to maximize or restore.
- **Snapping.** Drop a window against a screen edge to fill half of the screen, or into a corner for a quarter. Snapped and maximized windows respect the bar, the dock and your Hyprland gaps.
- **Natural un-snapping.** Pull a snapped or maximized window away and it returns to its previous size, staying under the cursor. This works from the drag strip and with <kbd>SUPER</kbd> + drag.
- **App icons on the bar.** Pinned and open apps appear on the system bar. Click an icon to focus, minimize, restore or launch the app; middle-click it to close the window. Minimized windows are shared with omadock.
- **Floating by default (optional).** Every window opens floating, like a traditional desktop.
- **Theme-aware.** Follows the Omarchy theme, or uses your own colors.
- **Lightweight.** Event-driven with no polling, and it doesn't spawn processes while you work.

## Requirements

- Omarchy 4 with its Quickshell-based shell.
- Hyprland **0.55 or newer** with a Lua configuration (the Omarchy default).

No extra packages are needed.

## Installation

```bash
omarchy plugin add https://github.com/DjaboDev/Mouse-First.git --enable
omarchy restart shell
```

The plugin is also listed in the [Omarchy plugin store](https://plugins.omarchy.org/plugin.html?id=io.github.mousefirst.controls).

## Usage

| Action | How |
| --- | --- |
| Move a window | Drag the strip along its top edge (or the optional ⠿ grip) |
| Maximize / restore | Maximize button, or double-click the top strip |
| Snap | Drag the window against an edge (half screen) or into a corner (quarter) |
| Un-snap / un-maximize | Drag the window away from its snapped position |
| Minimize | Minimize button, or click the focused app's icon on the bar |
| Restore | Click the app's icon on the bar (or in omadock) |
| Move the control capsule | Drag the thin handle under the buttons; double-click it to reset |
| Settings | Right-click the control capsule |

### Keyboard shortcuts (optional)

Mouse-First exposes its actions over Quickshell IPC, so you can bind them in `~/.config/hypr/bindings.lua`:

```lua
local mf = "qs -p /usr/share/omarchy/shell ipc call mousefirst "
o.bind("SUPER + ALT + LEFT",  "Snap left",          mf .. "snap left")
o.bind("SUPER + ALT + RIGHT", "Snap right",         mf .. "snap right")
o.bind("SUPER + ALT + UP",    "Maximize / restore", mf .. "toggleMaximize")
o.bind("SUPER + ALT + DOWN",  "Minimize",           mf .. "minimize")
```

| Function | Description |
| --- | --- |
| `snap <zone>` | `left`, `right`, `top`, `bottom`, `top-left`, `top-right`, `bottom-left`, `bottom-right`, `maximize` |
| `toggleMaximize` | Maximize or restore the active window |
| `restore` | Restore the active window from a snap or maximize |
| `minimize` / `restoreLast` | Minimize the active window / restore the most recently minimized one |
| `settings` | Open or close the settings panel |
| `status` | Print diagnostic state as JSON (useful for bug reports) |

## Configuration

Settings are changed from the settings panel and saved to `~/.config/omarchy/mouse-first.json`. You can also edit the file by hand; changes apply immediately.

| Key | Default | Description |
| --- | --- | --- |
| `language` | from `$LANG` | `en` or `pt` |
| `disableTiling` | `true` | Open every window floating |
| `alwaysVisible` | `true` | Keep the control capsule visible (otherwise it appears on hover) |
| `dragFullWidth` | `true` | Enable the top-edge drag strip |
| `showDragHandle` | `false` | Show a ⠿ drag grip in the capsule |
| `disableSnapping` | `false` | Turn edge snapping off |
| `ignoreDock` | `false` | Let snapped and maximized windows cover the dock area |
| `minimizeToBar` | `true` | Show app icons on the bar (when off, they appear only if no dock is running) |
| `barSection` | `left` | Bar section for the icons (`left`, `center`, `right`) |
| `enableMenuDrag` | `true` | Allow moving the control capsule |
| `rememberMenuPerWindow` / `rememberMenuGlobal` | `false` | Keep the capsule position per application, or use one position for all windows |
| `alwaysShowMenuDragZone` | `false` | Always show the capsule's move handle |
| `buttonOrder` / `buttonVisible` | | Order and visibility of `float`, `minimize`, `maximize` and `close` |
| `colorMode` | `theme` | `theme` follows Omarchy; `custom` uses `customBg`, `customFg`, `customAccent` and `customRed` |

## How it works

- **`Service.qml`** runs once per shell. It owns the state and draws one transparent overlay per monitor. The overlay only takes input on the controls and the drag strip.
- **`src/lua/mousefirst.lua`** is loaded into Hyprland with `hyprctl eval`. It watches the active window and the monitor layout from inside the compositor and reports changes as custom IPC events, so the shell never polls. It is reloaded automatically after `hyprctl reload`.
- **`src/js/geometry.js`** holds the snapping and placement math as pure functions, covered by the tests in `tests/`.
- **`BarWidget.qml`** only renders the app icons. Omarchy creates one per monitor, and all of them share the service.

Minimized windows live on `special:minimized`, the same workspace omadock uses, and each one's original workspace is remembered in `~/.local/state/mouse-first/`.

## Development

```bash
git clone https://github.com/DjaboDev/Mouse-First.git
cd Mouse-First
scripts/dev-link.sh          # symlink the checkout over the installed plugin
omarchy restart shell        # services reload only on a shell restart
node --test tests/*.test.mjs  # geometry tests
```

## Updating & removal

```bash
omarchy plugin update io.github.mousefirst.controls
omarchy restart shell
```

```bash
omarchy plugin remove io.github.mousefirst.controls --yes
omarchy restart shell
rm -rf ~/.config/omarchy/mouse-first.json ~/.local/state/mouse-first
```

## License

[MIT](LICENSE)
