import { GetCommand } from "@aws-sdk/lib-dynamodb";
import { ddb } from "../lib/ddb.ts";
import { tables } from "../lib/env.ts";
import { ok } from "../lib/http.ts";
import { authed } from "../lib/handler.ts";
import { AppError } from "../lib/errors.ts";
import { logger } from "../lib/logger.ts";
import { toAgencyDto } from "../domain/agency.ts";
import type { MeResponse } from "../contracts/me.ts";
export const handler = authed(async (_event, { principal, requestId }) => {
const result = await ddb.send(
new GetCommand({
TableName: tables.agencies,
// The key comes from the verified token. There is no comparison to
// forget and no way to request another agency's record.
Key: { agency_id: principal.agencyId },
// Strongly consistent: a branding change made two seconds ago must
// be visible. One extra read unit on a once-per-session call.
ConsistentRead: true,
})
);
if (result.Item === undefined) {
// The token names an agency that does not exist. That is data
// corruption, not a user error, so log at ERROR and alarm on it.
logger.error("token references a missing agency", {
agencyId: principal.agencyId,
});
throw new AppError("FORBIDDEN", "Your agency record is unavailable.");
}
const body: MeResponse = {
user: {
id: principal.userId,
email: principal.email,
role: principal.role,
},
// logoUrl stays null until Book 2 presigns the stored S3 key.
agency: toAgencyDto(result.Item, null),
};
return ok(body, requestId);
});