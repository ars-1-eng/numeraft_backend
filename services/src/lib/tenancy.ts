import { GetCommand, TransactWriteCommand } from "@aws-sdk/lib-dynamodb";
import { ddb } from "./ddb.ts";
import { tables } from "./env.ts";
import { logger } from "./logger.ts";
import { newAgencyId } from "./ids.ts";
import { deriveAgencyName, DEFAULT_BRANDING } from "../domain/agency.ts";


// 
export interface ProvisionResult{
    agencyId:string;
    created:boolean
}


export async function provisionTenancy(args:{
    userId:string,
    email:string
}):Promise<ProvisionResult>{
    const existing=await ddb.send(
        new GetCommand({
            TableName:tables.users,
            Key:{user_id:args.userId},
            ConsistentRead:true,
            ProjectionExpression:"agency_id"
        })
    );
    
    const existingAgencyId:unknown=existing.Item?.["agency_id"];
    if(typeof existingAgencyId==="string"&& existingAgencyId!==""){
        return {agencyId:existingAgencyId,created:false};
    }

const agencyId = newAgencyId();
const now = new Date().toISOString();
try {
await ddb.send(
new TransactWriteCommand({
TransactItems: [
{
Put: {
TableName: tables.agencies,
Item: {
agency_id: agencyId,
name: deriveAgencyName(args.email),
plan: "founding",
owner_user_id: args.userId,
branding: DEFAULT_BRANDING,
onboarding_stage: "connect_ga4",
created_at: now,
updated_at: now,
},
ConditionExpression: "attribute_not_exists(agency_id)",
},
},
{
Put: {
TableName: tables.users,
Item: {
user_id: args.userId,

agency_id: agencyId,
email: args.email,
role: "owner",
created_at: now,
},
// If two requests race, exactly one transaction succeeds.
ConditionExpression: "attribute_not_exists(user_id)",
},
},
],
})
);
logger.info("provisioned agency", { agencyId });
return { agencyId, created: true };
} catch (error) {
// A cancelled transaction almost always means a concurrent request
// won the race. Re-read rather than failing the caller.
const name = error instanceof Error ? error.name : "";
if (name === "TransactionCanceledException") {
const retry = await ddb.send(
new GetCommand({
TableName: tables.users,
Key: { user_id: args.userId },
ProjectionExpression: "agency_id",
ConsistentRead: true,
})
);
const raced: unknown = retry.Item?.["agency_id"];
if (typeof raced === "string" && raced !== "") {
logger.info("lost provisioning race, reusing existing agency", {
agencyId: raced,
});
return { agencyId: raced, created: false };
}
}
throw error;
}

}