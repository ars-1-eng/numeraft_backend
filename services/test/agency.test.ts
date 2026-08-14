import { test } from "node:test";
import assert from "node:assert/strict";
import { toAgencyDto, deriveAgencyName, DEFAULT_PRIMARY_COLOR } from "../src/domain/agency.ts";
test("maps a complete stored item to the API contract", () => {
const dto = toAgencyDto({
agency_id: "agc_01HQ",
name: "Tidewater Studio",
plan: "founding",
branding: { primary_color: "#B5613A", accent_color: "#2F8F5B" },
onboarding_stage: "connect_ga4",
created_at: "2026-07-27T09:12:04.117Z",
});
assert.deepEqual(dto, {
id: "agc_01HQ",
name: "Tidewater Studio",
plan: "founding",
branding: {
logoUrl: null,
primaryColor: "#B5613A",
accentColor: "#2F8F5B",
},
onboardingStage: "connect_ga4",
createdAt: "2026-07-27T09:12:04.117Z",
});
});
test("a record written by older code never produces undefined in the UI", () => {
const dto = toAgencyDto({ agency_id: "agc_01HQ" });
assert.equal(dto.name, "My agency");
assert.equal(dto.plan, "founding");
assert.equal(dto.branding.primaryColor, DEFAULT_PRIMARY_COLOR);
assert.equal(dto.branding.accentColor, null);
assert.equal(dto.onboardingStage, "connect_ga4");
});
test("an unrecognised plan falls back rather than reaching the client", () => {
assert.equal(toAgencyDto({ agency_id: "a", plan: "enterprise" }).plan, "founding");
});
test("derives a usable agency name from a business domain", () => {
assert.equal(deriveAgencyName("hello@tidewater.studio"), "Tidewater Studio");
assert.equal(deriveAgencyName("ops@velo-cycles.com"), "Velo Cycles");
assert.equal(deriveAgencyName("a@harbor_and_co.co.uk"), "Harbor And Co");
});
test("does not name an agency after a mailbox provider", () => {
assert.equal(deriveAgencyName("someone@gmail.com"), "My agency");
assert.equal(deriveAgencyName("someone@Outlook.com"), "My agency");
assert.equal(deriveAgencyName("nonsense"), "My agency");
});