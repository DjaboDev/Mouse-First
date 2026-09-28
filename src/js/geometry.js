.pragma library

// Pure geometry helpers. Every rect is { x, y, w, h } in global layout
// (logical) coordinates, the same space Hyprland reports `at`/`size` in.
// Nothing here touches QML or Hyprland, so tests/geometry.test.mjs can run
// these functions under node.

var DRAG_THRESHOLD = 4       // px of pointer travel before a press becomes a drag
var BREAK_MARGIN = 45        // px pushed past an edge to escape clamping/snapping
var EDGE_TOUCH = 6           // px from the usable edge that counts as touching it
var CURSOR_EDGE = 16         // px from the screen edge that arms an edge snap
var CURSOR_CORNER = 32       // px square in each screen corner that arms a quarter
var MATCH_TOLERANCE = 4      // px of slack when comparing requested vs actual rects
var RESTORE_W = 0.6          // default restore size, as a fraction of the usable area
var RESTORE_H = 0.65
var MIN_W = 320
var MIN_H = 240

function rect(x, y, w, h) {
    return { x: Math.round(x), y: Math.round(y), w: Math.round(w), h: Math.round(h) }
}

function clamp(v, lo, hi) {
    return Math.max(lo, Math.min(hi, v))
}

function contains(r, px, py) {
    return px >= r.x && px < r.x + r.w && py >= r.y && py < r.y + r.h
}

function rectsMatch(a, b, tol) {
    var t = tol === undefined ? MATCH_TOLERANCE : tol
    return !!a && !!b &&
        Math.abs(a.x - b.x) <= t && Math.abs(a.y - b.y) <= t &&
        Math.abs(a.w - b.w) <= t && Math.abs(a.h - b.h) <= t
}

function sizesMatch(a, b, tol) {
    var t = tol === undefined ? MATCH_TOLERANCE : tol
    return !!a && !!b && Math.abs(a.w - b.w) <= t && Math.abs(a.h - b.h) <= t
}

// Monitor under a point; falls back to the nearest one so a cursor that is
// momentarily between outputs still resolves.
function monitorAt(monitors, px, py) {
    if (!monitors || monitors.length === 0) return null
    var best = null, bestDist = Infinity
    for (var i = 0; i < monitors.length; i++) {
        var m = monitors[i]
        if (contains(m, px, py)) return m
        var dx = Math.max(m.x - px, 0, px - (m.x + m.w))
        var dy = Math.max(m.y - py, 0, py - (m.y + m.h))
        var d = dx * dx + dy * dy
        if (d < bestDist) { bestDist = d; best = m }
    }
    return best
}

// Area windows may occupy on a monitor: minus reserved space (bar, dock),
// inset by `gap`. `reserved` is { left, top, right, bottom }.
function usableArea(monitor, reserved, gap) {
    var r = reserved || { left: 0, top: 0, right: 0, bottom: 0 }
    var g = gap || 0
    return rect(
        monitor.x + r.left + g,
        monitor.y + r.top + g,
        Math.max(0, monitor.w - r.left - r.right - 2 * g),
        Math.max(0, monitor.h - r.top - r.bottom - 2 * g))
}

// Target rect of a snap zone inside a usable area. `gap` separates tiles.
function zoneRect(zone, area, gap) {
    var g = gap || 0
    var halfW = Math.round((area.w - g) / 2)
    var halfH = Math.round((area.h - g) / 2)
    var right = area.x + halfW + g
    var lower = area.y + halfH + g
    var restW = area.w - halfW - g
    var restH = area.h - halfH - g
    switch (zone) {
    case "maximize":     return rect(area.x, area.y, area.w, area.h)
    case "left":         return rect(area.x, area.y, halfW, area.h)
    case "right":        return rect(right, area.y, restW, area.h)
    case "top":          return rect(area.x, area.y, area.w, halfH)
    case "bottom":       return rect(area.x, lower, area.w, restH)
    case "top-left":     return rect(area.x, area.y, halfW, halfH)
    case "top-right":    return rect(right, area.y, restW, halfH)
    case "bottom-left":  return rect(area.x, lower, halfW, restH)
    case "bottom-right": return rect(right, lower, restW, restH)
    }
    return null
}

// Placement bounds for a window of size w x h inside `area`.
function bounds(area, w, h) {
    return {
        minX: area.x,
        minY: area.y,
        maxX: Math.max(area.x, area.x + area.w - w),
        maxY: Math.max(area.y, area.y + area.h - h)
    }
}

// Move a rect (keeping its size) so it lies inside `area` where possible.
function clampInto(r, area) {
    var b = bounds(area, r.w, r.h)
    return rect(clamp(r.x, b.minX, b.maxX), clamp(r.y, b.minY, b.maxY), r.w, r.h)
}

// True when the user pushes the window (or cursor) well past the usable
// edges: they want to leave the monitor or tuck the window partly off-screen,
// so clamping and snapping step aside.
function isBreaking(raw, area, monitor, cursor) {
    var b = bounds(area, raw.w, raw.h)
    return raw.x < b.minX - BREAK_MARGIN || raw.x > b.maxX + BREAK_MARGIN ||
           raw.y < b.minY - BREAK_MARGIN || raw.y > b.maxY + BREAK_MARGIN ||
           cursor.x < monitor.x - 10 || cursor.x > monitor.x + monitor.w + 10 ||
           cursor.y < monitor.y - 10 || cursor.y > monitor.y + monitor.h + 10
}

// Where a dragged window should be drawn: clamped inside the usable area,
// unless the user is deliberately breaking out of it.
function dragTarget(raw, area, monitor, cursor) {
    if (isBreaking(raw, area, monitor, cursor)) return rect(raw.x, raw.y, raw.w, raw.h)
    return clampInto(raw, area)
}

// Snap zone for a drag in progress, or "" for none. A zone arms when the
// window touches a usable edge or the cursor is thrown against a screen edge;
// touching two edges at once (or the cursor sitting in a corner) picks a
// quarter.
function snapZone(raw, area, monitor, cursor) {
    if (isBreaking(raw, area, monitor, cursor)) return ""
    var b = bounds(area, raw.w, raw.h)
    var usableBottom = area.y + area.h

    var left   = raw.x <= b.minX + EDGE_TOUCH || cursor.x <= monitor.x + CURSOR_EDGE
    var right  = raw.x >= b.maxX - EDGE_TOUCH || cursor.x >= monitor.x + monitor.w - CURSOR_EDGE
    var top    = raw.y <= b.minY + EDGE_TOUCH || cursor.y <= area.y + CURSOR_EDGE
    var bottom = raw.y >= b.maxY - EDGE_TOUCH || cursor.y >= usableBottom - CURSOR_EDGE

    // A window as wide (tall) as the area touches both sides at once; only
    // the side the cursor is nearer to counts.
    if (left && right) {
        var mid = area.x + area.w / 2
        left = cursor.x < mid
        right = !left
    }
    if (top && bottom) {
        var midY = area.y + area.h / 2
        top = cursor.y < midY
        bottom = !top
    }

    var cLeft = cursor.x <= monitor.x + CURSOR_CORNER
    var cRight = cursor.x >= monitor.x + monitor.w - CURSOR_CORNER
    var cTop = cursor.y <= area.y + CURSOR_CORNER
    var cBottom = cursor.y >= usableBottom - CURSOR_CORNER

    if ((cLeft && cTop) || (left && top)) return "top-left"
    if ((cRight && cTop) || (right && top)) return "top-right"
    if ((cLeft && cBottom) || (left && bottom)) return "bottom-left"
    if ((cRight && cBottom) || (right && bottom)) return "bottom-right"
    if (left) return "left"
    if (right) return "right"
    if (top) return "top"
    if (bottom) return "bottom"
    return ""
}

function defaultRestoreSize(area) {
    return { w: Math.round(area.w * RESTORE_W), h: Math.round(area.h * RESTORE_H) }
}

// Size to restore a snapped/maximized window to: the remembered one, shrunk
// to fit the area it is going to, or the default when nothing is remembered.
function restoreSize(remembered, area) {
    var s = (remembered && remembered.w > 0 && remembered.h > 0) ? remembered : defaultRestoreSize(area)
    return {
        w: Math.round(clamp(s.w, Math.min(MIN_W, area.w), area.w)),
        h: Math.round(clamp(s.h, Math.min(MIN_H, area.h), area.h))
    }
}

// Place a restored window so the point the user grabbed stays under the
// cursor: same horizontal ratio, same vertical offset from the top edge.
function restoreUnderCursor(size, cursor, grabRatioX, grabOffsetY, area) {
    var ratio = clamp(grabRatioX, 0.1, 0.9)
    var offY = clamp(grabOffsetY, 0, Math.max(0, size.h - 1))
    var b = bounds(area, size.w, size.h)
    return rect(
        clamp(cursor.x - size.w * ratio, b.minX, b.maxX),
        clamp(cursor.y - offY, b.minY, b.maxY),
        size.w, size.h)
}

// Center a rect of the given size in the area.
function centered(size, area) {
    return rect(area.x + (area.w - size.w) / 2, area.y + (area.h - size.h) / 2, size.w, size.h)
}

// Shrink/move a window that opened larger than the usable area or under the
// bar. Returns null when the window already fits.
function fitInside(win, area) {
    var tooBig = win.w > area.w || win.h > area.h
    var underTop = win.y < area.y
    if (!tooBig && !underTop) return null
    if (tooBig) {
        var size = { w: Math.min(win.w, Math.round(area.w * 0.9)), h: Math.min(win.h, Math.round(area.h * 0.9)) }
        return centered(size, area)
    }
    return rect(win.x, area.y, win.w, Math.min(win.h, area.h))
}

// A snapped window was resized from `before` to `after`. If `other` shares
// the edge that moved (they sat side by side, `gap` apart), return the rect
// that keeps `other` against it; otherwise null. Used to resize snapped
// neighbours together, like a split view.
function followEdge(before, after, other, gap) {
    var g = gap || 0
    var t = MATCH_TOLERANCE * 2
    var r = { x: other.x, y: other.y, w: other.w, h: other.h }
    var changed = false
    var overlapY = other.y < before.y + before.h && other.y + other.h > before.y
    var overlapX = other.x < before.x + before.w && other.x + other.w > before.x

    if (overlapY && Math.abs(other.x - (before.x + before.w + g)) <= t && after.x + after.w !== before.x + before.w) {
        var right = other.x + other.w
        r.x = after.x + after.w + g
        r.w = right - r.x
        changed = true
    }
    if (overlapY && Math.abs(other.x + other.w + g - before.x) <= t && after.x !== before.x) {
        r.w = after.x - g - other.x
        changed = true
    }
    if (overlapX && Math.abs(other.y - (before.y + before.h + g)) <= t && after.y + after.h !== before.y + before.h) {
        var bottom = other.y + other.h
        r.y = after.y + after.h + g
        r.h = bottom - r.y
        changed = true
    }
    if (overlapX && Math.abs(other.y + other.h + g - before.y) <= t && after.y !== before.y) {
        r.h = after.y - g - other.y
        changed = true
    }
    if (!changed || r.w < MIN_W / 2 || r.h < MIN_H / 2) return null
    return rect(r.x, r.y, r.w, r.h)
}

// Exported for node tests; ignored by the QML engine.
if (typeof module !== "undefined") {
    module.exports = {
        DRAG_THRESHOLD: DRAG_THRESHOLD, rect: rect, clamp: clamp, contains: contains,
        rectsMatch: rectsMatch, sizesMatch: sizesMatch, monitorAt: monitorAt,
        usableArea: usableArea, zoneRect: zoneRect, clampInto: clampInto, isBreaking: isBreaking,
        dragTarget: dragTarget, snapZone: snapZone, defaultRestoreSize: defaultRestoreSize,
        restoreSize: restoreSize, restoreUnderCursor: restoreUnderCursor,
        centered: centered, fitInside: fitInside, followEdge: followEdge
    }
}
