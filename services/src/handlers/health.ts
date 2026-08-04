
import { ok } from "../lib/http.ts";
import { publicRoute } from "../lib/handler.ts";
import { env } from "../lib/env.ts";
import type { HealthResponse } from "../contracts/health.ts";

export const handler = publicRoute((_event, { requestId }) => {
  const body: HealthResponse = {
    status: "ok",
    service: "numeraft-api",
    environment: env.environment,
    timestamp: new Date().toISOString(),
    requestId,
  };

  return ok(body, requestId);
});
