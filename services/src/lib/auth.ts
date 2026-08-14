import type { APIGatewayProxyEventV2WithJWTAuthorizer } from "aws-lambda";
import { AppError } from "./errors.ts";

//define roles
export type Role="owner"|"admin"|"member";


//define identity
export interface Identity{
    userId:string;
    username:string;
    email:string;
}


//define principal
export interface Principal extends Identity{
    agencyId:string;
    role:Role;
}

// helper to read claim
function claimString(
    claims:Record<string,unknown>|undefined,name:string):
string{
    const value=claims?.[name];
    return typeof value==="string"?value:""
}


// extract identity
export function extractIdentity(
    event:APIGatewayProxyEventV2WithJWTAuthorizer
):Identity{
    const claims=event.requestContext.authorizer?.jwt?.claims as 
    Record<string,unknown>|undefined;

    if(claims===undefined){
throw new AppError("UNAUTHORIZED", "No verified claims on the request.");
    }

    const userId=claimString(claims,"sub")
    const email=claimString(claims,"email")
    const username = claimString(claims, "cognito:username") || userId;
if (userId === "" || email === "") {
throw new AppError("UNAUTHORIZED", "Token is missing required claims.");
}
return { userId, username, email };
}


const ROLES: readonly string[] = ["owner", "admin", "member"];

//extract principal
export function extractPrincipal(
event: APIGatewayProxyEventV2WithJWTAuthorizer
): Principal {
const identity = extractIdentity(event);
const claims = event.requestContext.authorizer?.jwt?.claims as
| Record<string, unknown>
| undefined;

const agencyId = claimString(claims, "custom:agency_id");
const role = claimString(claims, "custom:role") || "member";
if (agencyId === "") {
// A distinct code, not a generic 403, so the client knows to call
// POST /me/bootstrap rather than showing "access denied".
throw new AppError(
"NO_AGENCY",
"Your account is not linked to an agency yet."
);
}
if (!ROLES.includes(role)) {
// Never default an unknown role upward. Unknown means reject.
throw new AppError("FORBIDDEN", "Unrecognised role on token.");
}
return { ...identity, agencyId, role: role as Role };
}

//check admin permission
export function requireAdmin(principal:Principal):void{
    if(principal.role==="member"){
throw new AppError("FORBIDDEN", "This action requires an admin.");
    }
}