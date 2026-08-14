import type { PostConfirmationTriggerEvent } from "aws-lambda";
import { provisionTenancy } from "../lib/tenancy.ts";
import { writeTenancyAttributes } from "../lib/cognito.ts";
import { logger } from "../lib/logger.ts";
export const handler = async (
event: PostConfirmationTriggerEvent
): Promise<PostConfirmationTriggerEvent> => {
// The same trigger fires for a confirmed password reset. Only a sign-up
// confirmation should provision a tenant.
if (event.triggerSource !== "PostConfirmation_ConfirmSignUp") {
return event;
}
const userId = event.request.userAttributes["sub"];
const email = event.request.userAttributes["email"];
if (userId === undefined || email === undefined) {
logger.error("post confirmation without sub or email", {
triggerSource: event.triggerSource,
});
return event;
}
logger.appendKeys({ userId });
try {
const { agencyId, created } = await provisionTenancy({ userId, email });
await writeTenancyAttributes({
userPoolId: event.userPoolId,
username: event.userName,
agencyId,
role: "owner",
onboardingStage: "connect_ga4",
});
logger.info("post confirmation provisioning complete", { agencyId, created });
} catch (error) {
// -----------------------------------------------------------------
// DO NOT RETHROW.
//
// Cognito confirms the user BEFORE invoking this trigger. Throwing
// here does not un-confirm them; it returns an error to the client
// for a user who now exists and whose email is taken, so they cannot
// sign up again. That is the worst available outcome.
//
// Instead: log loudly, alarm on it, and let POST /me/bootstrap repair
// the gap on first sign-in. The customer sees nothing.
// -----------------------------------------------------------------
logger.error("provisioning failed, /me/bootstrap will repair", {
error: error instanceof Error ? error.message : String(error),
stack: error instanceof Error ? error.stack : undefined,
});
} finally {
logger.resetKeys();
}
return event;
};