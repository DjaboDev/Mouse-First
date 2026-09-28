.pragma library

// Builders for Hyprland Lua dispatch strings. Every window-targeting command
// goes through `target()`, which accepts only a real hex address, so nothing
// read from a window title or config can end up inside the Lua expression.

function normalizeAddress(address) {
    var s = String(address || "").trim()
    if (s.indexOf("0x") === 0 || s.indexOf("0X") === 0) s = s.slice(2)
    return /^[0-9a-fA-F]+$/.test(s) ? "0x" + s.toLowerCase() : ""
}

function target(address) {
    var a = normalizeAddress(address)
    return a ? 'window = "address:' + a + '"' : ""
}

function int(n) {
    return Math.round(Number(n) || 0)
}

function move(address, x, y) {
    var t = target(address)
    return t ? "hl.dsp.window.move({ x = " + int(x) + ", y = " + int(y) + ", relative = false, " + t + " })" : ""
}

function resize(address, w, h) {
    var t = target(address)
    return t ? "hl.dsp.window.resize({ x = " + int(w) + ", y = " + int(h) + ", " + t + " })" : ""
}

// Hyprland resizes around the window's center, so the move must come after.
function geometry(address, r) {
    return [resize(address, r.w, r.h), move(address, r.x, r.y)]
}

function setFloating(address, on) {
    var t = target(address)
    return t ? 'hl.dsp.window.float({ action = "' + (on ? "on" : "off") + '", ' + t + " })" : ""
}

function toggleFloating(address) {
    var t = target(address)
    return t ? 'hl.dsp.window.float({ action = "toggle", ' + t + " })" : ""
}

function setMaximizedState(address, on) {
    var t = target(address)
    return t ? 'hl.dsp.window.fullscreen({ mode = "maximized", action = "' + (on ? "set" : "unset") + '", ' + t + " })" : ""
}

// Window animations turn a stream of move dispatches into a rubber band;
// they are paused on the dragged window and restored afterwards.
function setNoAnim(address, on) {
    var t = target(address)
    return t ? 'hl.dsp.window.set_prop({ prop = "no_anim", value = "' + (on ? "1" : "unset") + '", ' + t + " })" : ""
}

function bringToTop(address) {
    var t = target(address)
    return t ? "hl.dsp.window.bring_to_top({ " + t + " })" : ""
}

function focus(address) {
    var t = target(address)
    return t ? "hl.dsp.focus({ " + t + " })" : ""
}

function close(address) {
    var t = target(address)
    return t ? "hl.dsp.window.close({ " + t + " })" : ""
}

// Lua snippets for `hyprctl eval`, calling into src/lua/mousefirst.lua.
function luaString(s) {
    return '"' + String(s).replace(/\\/g, "\\\\").replace(/"/g, '\\"').replace(/\n/g, " ") + '"'
}

function evalMinimize(address) {
    var a = normalizeAddress(address)
    return a ? "MOUSE_FIRST.minimize(" + luaString(a) + ")" : ""
}

function evalRestore(address, workspace) {
    var a = normalizeAddress(address)
    return a ? "MOUSE_FIRST.restore(" + luaString(a) + ", " + luaString(workspace || "") + ")" : ""
}

function evalFloatRule(enabled, center) {
    return "MOUSE_FIRST.set_float_rule(" + (enabled ? "true" : "false") + ", " + (center ? "true" : "false") + ")"
}

function evalShortcuts(enabled) {
    return "MOUSE_FIRST.set_shortcuts(" + (enabled ? "true" : "false") + ")"
}
