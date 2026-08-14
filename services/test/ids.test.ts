import { test } from "node:test";
import assert from "node:assert/strict";
import { ulid, newAgencyId, newReportId, hasPrefix } from "../src/lib/ids.ts";
test("a ulid is 26 characters of the Crockford alphabet", () => {
assert.match(ulid(), /^[0-9A-HJKMNP-TV-Z]{26}$/);
});
test("ids sort chronologically, which is what the reports list depends on", () => {
const early = ulid(1_700_000_000_000);
const later = ulid(1_800_000_000_000);
assert.ok(early < later, `${early} should sort before ${later}`);
});
test("ids generated in the same millisecond are still unique", () => {
const now = Date.now();
const generated = new Set(Array.from({ length: 2000 }, () => ulid(now)));
assert.equal(generated.size, 2000);
});
test("prefixes identify the entity type", () => {
assert.ok(newAgencyId().startsWith("agc_"));
assert.ok(newReportId().startsWith("rep_"));
assert.ok(hasPrefix(newReportId(), "rep"));
assert.equal(hasPrefix(newAgencyId(), "rep"), false);
assert.equal(hasPrefix("rep_short", "rep"), false);
});