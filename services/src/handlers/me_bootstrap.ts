import { ok } from "../lib/http.ts";
import { authedIdentity } from "../lib/handler.ts";
import { provisionTenancy } from "../lib/tenancy.ts";
import { writeTenancyAttributes } from "../lib/cognito.ts";
import { logger } from "../lib/logger.ts";
import type { BootstrapResponse } from "../contracts/me.ts";
const USER_POOL_ID = process.env["USER_POOL_ID"];
export const handler = authedIdentity(async (_event, { identity, requestId }) => {
if (USER_POOL_ID === undefined || USER_POOL_ID === "") {
throw new Error("Missing required environment variable: USER_POOL_ID");
}
// Idempotent. Returns the existing agency if there already is one.
const { agencyId, created } = await provisionTenancy({
userId: identity.userId,
email: identity.email,
});
// Always write the attributes, even when the records already existed:
// the usual reason for calling this endpoint is that the records exist
// but the Cognito attributes were never set, which is exactly what
// happens for a user created with admin-create-user.
await writeTenancyAttributes({
userPoolId: USER_POOL_ID,
username: identity.username,
agencyId,
role: "owner",
onboardingStage: "connect_ga4",
});
logger.info("tenancy bootstrap complete", { agencyId, created });
const body: BootstrapResponse = {
created,
agencyId,
// The caller's current token predates these claims, so it must refresh
// before GET /me will succeed. Saying so explicitly saves Suhani from
// guessing why the retry still 403s.
tokenRefreshRequired: true,
};
return ok(body, requestId);
});