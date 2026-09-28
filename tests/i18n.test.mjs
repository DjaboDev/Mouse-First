// Run with: node --test tests/*.test.mjs
import { test } from "node:test"
import assert from "node:assert/strict"
import { readFileSync } from "node:fs"
import vm from "node:vm"

const source = readFileSync(new URL("../src/js/i18n.js", import.meta.url), "utf8")
  .replace(/^\.pragma library\s*$/m, "")
const I18n = {}
vm.runInNewContext(source, I18n)

test("every language translates every English key", () => {
  const keys = Object.keys(I18n.STRINGS.en)
  for (const { id } of I18n.LANGUAGES) {
    const missing = keys.filter((k) => !(k in I18n.STRINGS[id]))
    assert.deepEqual(missing, [], `${id} is missing keys`)
  }
})

test("tr falls back to English, then to the key", () => {
  assert.equal(I18n.tr("xx", "close"), I18n.STRINGS.en.close)
  assert.equal(I18n.tr("pt", "no-such-key"), "no-such-key")
})
