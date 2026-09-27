-- Mouse-First compositor module.
--
-- Loaded into Hyprland's Lua state with `hyprctl eval` by WindowTracker.qml.
-- A 16 ms timer compares the active window and the monitor layout with the
-- last values it reported, and only when something changed it emits a
-- custom IPC event (`custom>>mousefirst>>...` on socket2). The shell listens
-- to those events instead of polling hyprctl, so the controls follow a window
-- during native drags and resizes without spawning a single process.
--
-- Everything lives in the MOUSE_FIRST global so the module can be re-evaluated
-- safely: a reload disables the previous timer before starting a new one.

if MOUSE_FIRST and MOUSE_FIRST.timer then
  MOUSE_FIRST.timer:set_enabled(false)
end

MOUSE_FIRST = MOUSE_FIRST or {}
local M = MOUSE_FIRST
M.generation = MOUSE_FIRST_GENERATION

local SEP = "\31"
local MINIMIZED = "special:minimized"
local BTN_LEFT = 272

local function clean(value)
  return (tostring(value or ""):gsub("[\r\n\31]", " "))
end

local function emit(kind, payload)
  hl.dispatch(hl.dsp.event("mousefirst>>" .. kind .. ">>" .. payload))
end

local function round(n)
  return math.floor((tonumber(n) or 0) + 0.5)
end

local function window_state()
  local w = hl.get_active_window()
  if not w or not w.mapped then return "none" end
  return table.concat({
    w.address,
    round(w.at.x), round(w.at.y), round(w.size.x), round(w.size.y),
    w.floating and 1 or 0,
    tonumber(w.fullscreen) or 0,
    w.pinned and 1 or 0,
    w.monitor and w.monitor.name or "",
    clean(w.workspace and w.workspace.name or ""),
    clean(w.class),
    clean(w.title),
  }, SEP)
end

-- Monitor geometry in logical (layout) coordinates plus reserved space.
local function monitor_state()
  local parts = {}
  for _, m in ipairs(hl.get_monitors()) do
    local scale = (m.scale and m.scale > 0) and m.scale or 1
    local w, h = m.width / scale, m.height / scale
    if (tonumber(m.transform) or 0) % 2 == 1 then w, h = h, w end
    local r = m.reserved or {}
    parts[#parts + 1] = table.concat({
      m.name, round(m.x), round(m.y), round(w), round(h),
      round(r.left), round(r.top), round(r.right), round(r.bottom),
    }, ",")
  end
  return table.concat(parts, ";")
end

-- Whether the left button is held, so the shell knows when a native
-- (SUPER + drag) move ends. Returns nil when the compositor cannot tell.
local function button_state()
  local ok, down = pcall(hl.is_key_down, BTN_LEFT)
  if not ok then return nil end
  return down and 1 or 0
end

function M.resend()
  M.last_window, M.last_monitors, M.last_button = nil, nil, nil
end

function M.tick()
  local mons = monitor_state()
  if mons ~= M.last_monitors then
    M.last_monitors = mons
    emit("monitors", mons)
  end

  local win = window_state()
  if win ~= M.last_window then
    M.last_window = win
    emit("window", win)
  end

  local btn = button_state()
  if btn ~= nil and btn ~= M.last_button then
    M.last_button = btn
    local c = hl.get_cursor_pos() or { x = 0, y = 0 }
    emit("button", table.concat({ btn, round(c.x), round(c.y) }, ","))
  end
end

-- "Disable tiling" is a real window rule, so windows open floating instead of
-- being floated after the fact. Rules are named, so toggling reuses one.
function M.set_float_rule(enabled)
  if not M.float_rule then
    M.float_rule = hl.window_rule({
      name = "mouse-first-float",
      match = { class = ".*" },
      float = true,
      center = true,
    })
  end
  M.float_rule:set_enabled(enabled and true or false)
end

-- Minimize parks the window on special:minimized (shared with omadock) and
-- hands focus to the most recent window left on the origin workspace.
function M.minimize(address)
  local w = hl.get_window("address:" .. address)
  if not w then return end
  local origin = w.workspace and w.workspace.id
  hl.dispatch(hl.dsp.window.move({ workspace = MINIMIZED, window = "address:" .. address, follow = false }))
  if not origin then return end
  local best
  for _, other in ipairs(hl.get_workspace_windows(origin) or {}) do
    if other.address ~= address and other.mapped and not other.hidden then
      if not best or other.focus_history_id < best.focus_history_id then best = other end
    end
  end
  if best then
    hl.dispatch(hl.dsp.focus({ window = "address:" .. best.address }))
  end
end

-- Restore brings the window back to its origin workspace, or to the current
-- one when the origin is unknown, raises it and focuses it.
function M.restore(address, workspace)
  local target = workspace
  if not target or target == "" then
    local ws = hl.get_active_workspace()
    target = ws and tostring(ws.id) or "1"
  end
  hl.dispatch(hl.dsp.window.move({ workspace = target, window = "address:" .. address, follow = true }))
  hl.dispatch(hl.dsp.window.bring_to_top({ window = "address:" .. address }))
  hl.dispatch(hl.dsp.focus({ window = "address:" .. address }))
end

-- v0.1 parked windows on special:mf-minimized; move them to the shared one.
function M.migrate_legacy_minimized()
  for _, w in ipairs(hl.get_windows() or {}) do
    if w.workspace and w.workspace.name == "special:mf-minimized" then
      hl.dispatch(hl.dsp.window.move({ workspace = MINIMIZED, window = "address:" .. w.address, follow = false }))
    end
  end
end

-- `generation` guards against a stale shell instance stopping a newer one.
function M.stop(generation)
  if generation and generation ~= M.generation then return end
  if M.timer then M.timer:set_enabled(false) end
  if M.float_rule then M.float_rule:set_enabled(false) end
end

M.migrate_legacy_minimized()
M.resend()
M.timer = hl.timer(M.tick, { timeout = 16, type = "repeat" })
