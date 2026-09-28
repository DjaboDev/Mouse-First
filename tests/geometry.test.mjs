// Run with: node --test tests/*.test.mjs
import { test } from "node:test"
import assert from "node:assert/strict"
import { readFileSync } from "node:fs"
import vm from "node:vm"

// geometry.js is a QML `.pragma library` script; drop the pragma and run it
// as a CommonJS-style module.
const source = readFileSync(new URL("../src/js/geometry.js", import.meta.url), "utf8")
  .replace(/^\.pragma library\s*$/m, "")
const sandbox = { module: { exports: {} } }
vm.runInNewContext(source, sandbox)
const G = sandbox.module.exports
const plain = (v) => JSON.parse(JSON.stringify(v))

const monitor = { name: "A", x: 0, y: 0, w: 2560, h: 1440 }
const reserved = { left: 0, top: 26, right: 0, bottom: 69 }
const area = G.usableArea(monitor, reserved, 6)

test("usable area subtracts reserved space on every side and the gap", () => {
  assert.deepEqual(plain(area), { x: 6, y: 32, w: 2548, h: 1333 })
  const side = G.usableArea({ x: 100, y: 50, w: 1000, h: 800 }, { left: 30, top: 0, right: 10, bottom: 0 }, 0)
  assert.deepEqual(plain(side), { x: 130, y: 50, w: 960, h: 800 })
})

test("zone rects tile the usable area without overlap", () => {
  const g = 6
  const l = G.zoneRect("left", area, g)
  const r = G.zoneRect("right", area, g)
  assert.equal(l.x, area.x)
  assert.equal(l.x + l.w + g, r.x)
  assert.equal(r.x + r.w, area.x + area.w)
  const tl = G.zoneRect("top-left", area, g)
  const bl = G.zoneRect("bottom-left", area, g)
  assert.equal(tl.y + tl.h + g, bl.y)
  assert.equal(bl.y + bl.h, area.y + area.h)
  assert.deepEqual(plain(G.zoneRect("maximize", area, g)), plain(area))
  assert.equal(G.zoneRect("nope", area, g), null)
})

test("zones follow a monitor with an offset", () => {
  const second = { x: 2560, y: -200, w: 1920, h: 1080 }
  const a2 = G.usableArea(second, { left: 0, top: 26, right: 0, bottom: 0 }, 0)
  const r = G.zoneRect("right", a2, 0)
  assert.equal(r.x + r.w, 2560 + 1920)
  assert.equal(r.y, -200 + 26)
})

test("monitorAt finds the monitor under a point, or the nearest one", () => {
  const b = { name: "B", x: 2560, y: 0, w: 1920, h: 1080 }
  assert.equal(G.monitorAt([monitor, b], 3000, 500).name, "B")
  assert.equal(G.monitorAt([monitor, b], 100, 100).name, "A")
  assert.equal(G.monitorAt([monitor, b], 5000, 500).name, "B")
  assert.equal(G.monitorAt([], 0, 0), null)
})

test("dragTarget clamps inside the usable area", () => {
  const raw = { x: -20, y: 5, w: 800, h: 600 }
  const t = G.dragTarget(raw, area, monitor, { x: 300, y: 40 })
  assert.equal(t.x, area.x)
  assert.equal(t.y, area.y)
})

test("dragTarget lets the window go when pushed past the break margin", () => {
  const raw = { x: 2000, y: 400, w: 800, h: 600 }
  const t = G.dragTarget(raw, area, monitor, { x: 2600, y: 500 })
  assert.equal(t.x, 2000)
})

test("snapZone: edges, corners and free space", () => {
  const w = 800, h = 600
  const cur = (x, y) => ({ x, y })
  assert.equal(G.snapZone({ x: area.x, y: 400, w, h }, area, monitor, cur(300, 420)), "left")
  assert.equal(G.snapZone({ x: area.x + area.w - w, y: 400, w, h }, area, monitor, cur(2400, 420)), "right")
  assert.equal(G.snapZone({ x: 900, y: area.y, w, h }, area, monitor, cur(1200, 40)), "top")
  assert.equal(G.snapZone({ x: 900, y: area.y + area.h - h, w, h }, area, monitor, cur(1200, 900)), "bottom")
  assert.equal(G.snapZone({ x: area.x, y: area.y, w, h }, area, monitor, cur(300, 40)), "top-left")
  assert.equal(G.snapZone({ x: 900, y: 400, w, h }, area, monitor, cur(5, 45)), "top-left")
  assert.equal(G.snapZone({ x: 900, y: 400, w, h }, area, monitor, cur(1200, 420)), "")
})

test("snapZone ignores the far side for windows as wide as the area", () => {
  const raw = { x: area.x, y: 400, w: area.w, h: 600 }
  assert.equal(G.snapZone(raw, area, monitor, { x: 2500, y: 420 }), "right")
  assert.equal(G.snapZone(raw, area, monitor, { x: 100, y: 420 }), "left")
})

test("snapZone is off while breaking out of the monitor", () => {
  const raw = { x: 2300, y: 400, w: 800, h: 600 }
  assert.equal(G.snapZone(raw, area, monitor, { x: 2600, y: 420 }), "")
})

test("restoreSize keeps a remembered size, shrinks it to fit, or falls back", () => {
  assert.deepEqual(plain(G.restoreSize({ w: 900, h: 700 }, area)), { w: 900, h: 700 })
  assert.deepEqual(plain(G.restoreSize({ w: 9000, h: 7000 }, area)), { w: area.w, h: area.h })
  assert.deepEqual(plain(G.restoreSize(null, area)), plain(G.defaultRestoreSize(area)))
})

test("restoreUnderCursor keeps the grabbed point under the pointer", () => {
  const size = { w: 1000, h: 700 }
  const r = G.restoreUnderCursor(size, { x: 1200, y: 40 }, 0.5, 4, area)
  assert.equal(r.x, 700)
  assert.equal(r.y, 36)
  const high = G.restoreUnderCursor(size, { x: 1200, y: 10 }, 0.5, 4, area)
  assert.equal(high.y, area.y)
  const edge = G.restoreUnderCursor(size, { x: 2550, y: 600 }, 0.9, 4, area)
  assert.equal(edge.x + edge.w, area.x + area.w)
})

test("fitInside shrinks oversized windows and pulls them below the bar", () => {
  assert.equal(G.fitInside({ x: 100, y: 100, w: 800, h: 600 }, area), null)
  const big = G.fitInside({ x: 0, y: 0, w: 4000, h: 3000 }, area)
  assert.ok(big.w <= area.w && big.h <= area.h)
  const under = G.fitInside({ x: 100, y: 0, w: 800, h: 600 }, area)
  assert.equal(under.y, area.y)
})

test("rectsMatch tolerates a few pixels", () => {
  assert.ok(G.rectsMatch({ x: 0, y: 0, w: 10, h: 10 }, { x: 3, y: -2, w: 12, h: 9 }))
  assert.ok(!G.rectsMatch({ x: 0, y: 0, w: 10, h: 10 }, { x: 30, y: 0, w: 10, h: 10 }))
})

test("clampInto keeps the size and pulls the rect inside", () => {
  const r = G.clampInto({ x: 2400, y: 1300, w: 800, h: 600 }, area)
  assert.deepEqual(plain(r), { x: area.x + area.w - 800, y: area.y + area.h - 600, w: 800, h: 600 })
})

test("followEdge keeps a side-by-side neighbour against the moved edge", () => {
  const g = 6
  const left = G.zoneRect("left", area, g)
  const right = G.zoneRect("right", area, g)
  const wider = { ...left, w: left.w + 200 }
  const r = G.followEdge(left, wider, right, g)
  assert.equal(r.x, wider.x + wider.w + g)
  assert.equal(r.x + r.w, right.x + right.w)
  // Resizing the right window from its left edge shrinks the left one.
  const narrower = { ...right, x: right.x + 100, w: right.w - 100 }
  const l = G.followEdge(right, narrower, left, g)
  assert.equal(l.x, left.x)
  assert.equal(l.x + l.w + g, narrower.x)
})

test("followEdge handles stacked quarters and ignores unrelated windows", () => {
  const g = 6
  const tl = G.zoneRect("top-left", area, g)
  const bl = G.zoneRect("bottom-left", area, g)
  const br = G.zoneRect("bottom-right", area, g)
  const taller = { ...tl, h: tl.h + 100 }
  const b = G.followEdge(tl, taller, bl, g)
  assert.equal(b.y, taller.y + taller.h + g)
  assert.equal(b.y + b.h, bl.y + bl.h)
  assert.equal(G.followEdge(tl, taller, br, g), null)   // only touches at a corner
  assert.equal(G.followEdge(tl, tl, bl, g), null)       // nothing moved
})
