import { test } from "node:test";
import assert from "node:assert/strict";
import { ok, fail, noContent, serverError } from "../src/lib/http.ts";
void test("ok returns 200 with a JSON body and no-store caching", () => {
const response = ok({ hello: "world" });
assert.equal(response.statusCode, 200);
assert.equal(response.headers?.["content-type"], "application/json; charset=utf-8");
assert.equal(response.headers?.["cache-control"], "no-store");
assert.deepEqual(JSON.parse(response.body as string), { hello: "world" });
});
void test("ok echoes the request id only when one is supplied", () => {
assert.equal(ok({}).headers?.["x-request-id"], undefined);
assert.equal(ok({}, "req-123").headers?.["x-request-id"], "req-123");
});
void test("every error code maps to its documented status", () => {
assert.equal(fail("BAD_REQUEST", "x").statusCode, 400);
assert.equal(fail("UNAUTHORIZED", "x").statusCode, 401);
assert.equal(fail("FORBIDDEN", "x").statusCode, 403);
assert.equal(fail("NO_AGENCY", "x").statusCode, 403);
assert.equal(fail("NOT_FOUND", "x").statusCode, 404);
assert.equal(fail("CONFLICT", "x").statusCode, 409);
assert.equal(fail("RATE_LIMITED", "x").statusCode, 429);
assert.equal(fail("INTERNAL", "x").statusCode, 500);
});
void test("the error envelope keeps the shape the Flutter app parses", () => {
const body = JSON.parse(fail("NOT_FOUND", "Report not found.", "req-9").body as string);
assert.deepEqual(body, {
error: { code: "NOT_FOUND", message: "Report not found.", requestId: "req-9" },
});
});
void test("serverError never leaks internal detail", () => {
const body = JSON.parse(serverError("req-9").body as string);
assert.equal(body.error.code, "INTERNAL");
assert.equal(body.error.message, "Something went wrong on our side.");
assert.equal(body.error.details, undefined);
});
void test("noContent has no body", () => {
const response = noContent();
assert.equal(response.statusCode, 204);
assert.equal(response.body, undefined);
});