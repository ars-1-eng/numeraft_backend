import { test } from "node:test";
import assert from "node:assert/strict";
import { extractIdentity, extractPrincipal, requireAdmin } from "../src/lib/auth.ts";
import type { APIGatewayProxyEventV2WithJWTAuthorizer } from "aws-lambda";
function eventWith(
claims: Record<string, unknown> | undefined
): APIGatewayProxyEventV2WithJWTAuthorizer {
return {
requestContext: {
requestId: "req-test",
routeKey: "GET /me",
authorizer: claims === undefined ? undefined : { jwt: { claims } },
},
} as unknown as APIGatewayProxyEventV2WithJWTAuthorizer;
}
const validClaims = {
sub: "8f2c1e34-5a7b-4c9d-b1e2-3f4a5b6c7d8e",
email: "hello@tidewater.studio",
"cognito:username": "8f2c1e34-5a7b-4c9d-b1e2-3f4a5b6c7d8e",
"custom:agency_id": "agc_01HQ8ZK4M2E5N7P9R1S3T5V7W9",
"custom:role": "owner",
};
test("rejects a request with no verified claims", () => {
assert.throws(() => extractIdentity(eventWith(undefined)), /No verified claims/);
});
test("rejects a token missing sub or email", () => {
assert.throws(() => extractIdentity(eventWith({ sub: "u1" })), /missing required claims/i);
assert.throws(() => extractIdentity(eventWith({ email: "a@b.co" })), /missing required claims/i);
});
test("a confirmed user with no agency gets NO_AGENCY, not a generic 403", () => {
try {
extractPrincipal(eventWith({ sub: "u1", email: "a@b.co" }));
assert.fail("should have thrown");
} catch (error) {
assert.equal((error as { code: string }).code, "NO_AGENCY");
}
});
test("agencyId comes from the claims and nowhere else", () => {
const principal = extractPrincipal(eventWith(validClaims));
assert.equal(principal.agencyId, "agc_01HQ8ZK4M2E5N7P9R1S3T5V7W9");
assert.equal(principal.role, "owner");
assert.equal(principal.email, "hello@tidewater.studio");
});
test("an unknown role is rejected rather than defaulted upward", () => {
assert.throws(
() => extractPrincipal(eventWith({ ...validClaims, "custom:role": "superadmin" })),
/Unrecognised role/
);
});
test("a missing role defaults to the least privileged", () => {
const claims = { ...validClaims } as Record<string, unknown>;
delete claims["custom:role"];
assert.equal(extractPrincipal(eventWith(claims)).role, "member");
});
test("username falls back to sub when cognito:username is absent", () => {
const claims = { ...validClaims } as Record<string, unknown>;
delete claims["cognito:username"];

assert.equal(extractIdentity(eventWith(claims)).username, validClaims.sub);
});
test("requireAdmin blocks members and allows owners and admins", () => {
const base = extractPrincipal(eventWith(validClaims));
assert.doesNotThrow(() => requireAdmin({ ...base, role: "owner" }));
assert.doesNotThrow(() => requireAdmin({ ...base, role: "admin" }));
assert.throws(() => requireAdmin({ ...base, role: "member" }), /requires an admin/);
});
