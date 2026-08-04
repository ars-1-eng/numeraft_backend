import { test } from "node:test";
import assert from "node:assert/strict";
import type { APIGatewayProxyEventV2, Context } from "aws-lambda";
import { handler } from "../src/handlers/health.ts";
function fakeEvent(requestId = "req-test"): APIGatewayProxyEventV2 {
return {
requestContext: { requestId, routeKey: "GET /health" },
} as unknown as APIGatewayProxyEventV2;
}
function fakeContext(): Context {
return {
getRemainingTimeInMillis: () => 9_000,
} as unknown as Context;
}
void test("health returns 200 and the documented contract", async () => {
const response = await handler(fakeEvent(), fakeContext());
assert.equal(response.statusCode, 200);
const body = JSON.parse(response.body as string) as Record<string, unknown>;
assert.equal(body["status"], "ok");
assert.equal(body["service"], "numeraft-api");
assert.equal(body["requestId"], "req-test");
assert.equal(typeof body["environment"], "string");
// The contract promises ISO 8601 UTC, not an epoch number.
assert.match(body["timestamp"] as string, /^\d{4}-\d{2}-\d{2}T[\d:.]+Z$/);
});
void test("health echoes the request id back as a header", async () => {
const response = await handler(fakeEvent("req-abc"), fakeContext());
assert.equal(response.headers?.["x-request-id"], "req-abc");
})