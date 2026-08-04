import type { APIGatewayProxyStructuredResultV2 } from "aws-lambda";


// Base Header
const BASE_HEADERS: Record<string, string> = {
  "content-type": "application/json; charset=utf-8",
  "cache-control": "no-store",
  "x-content-type-options": "nosniff",
};

// Error Code
export type ErrorCode =
| "BAD_REQUEST"
| "UNAUTHORIZED"
| "FORBIDDEN"
| "NO_AGENCY"
| "NOT_FOUND"
| "CONFLICT"
| "UNPROCESSABLE"
| "RATE_LIMITED"
| "INTERNAL";


// APIERROR type
export interface ApiError{
    error:{
        code:ErrorCode;
        message:string;
        requestId?:string;
        details?:unknown;
    }
}


// Status Code
const STATUS: Record<ErrorCode, number> = {
BAD_REQUEST: 400,
UNAUTHORIZED: 401,
FORBIDDEN: 403,
// A distinct code on the same status, so the Flutter app can branch on
// it and call POST /me/bootstrap instead of showing a generic error.
NO_AGENCY: 403,
NOT_FOUND: 404,
CONFLICT: 409,
UNPROCESSABLE: 422,
RATE_LIMITED: 429,
INTERNAL: 500,
};

// json function

export function json<T>(
    statusCode:number,
    body:T,
    headers:Record<string,string>={}
):APIGatewayProxyStructuredResultV2{
    return {
        statusCode,
        body:JSON.stringify(body),
        headers:{...BASE_HEADERS,...headers}
    };
}

//

export function ok<T>(body:T,requestId?:string):APIGatewayProxyStructuredResultV2{
return json(200, body, requestId === undefined ? {} : { "x-request-id": requestId });
}

export function created<T>(body: T, location?: string): APIGatewayProxyStructuredResultV2 {
return json(201, body, location === undefined ? {} : { location });
}
export function accepted<T>(body: T): APIGatewayProxyStructuredResultV2 {
return json(202, body);
}
export function noContent(): APIGatewayProxyStructuredResultV2 {
return { statusCode: 204, headers: BASE_HEADERS };
}

export function fail(
code: ErrorCode,
message: string,
requestId?: string,
details?: unknown
): APIGatewayProxyStructuredResultV2 {
const body: ApiError = { error: { code, message } };
if (requestId !== undefined) body.error.requestId = requestId;
if (details !== undefined) body.error.details = details;
return json(STATUS[code], body, requestId === undefined ? {} : { "x-request-id": requestId });
}
export const badRequest = (m = "Bad request", r?: string, d?: unknown) =>
fail("BAD_REQUEST", m, r, d);
export const unauthorized = (m = "Unauthorized", r?: string) => fail("UNAUTHORIZED", m, r);
export const forbidden = (m = "Forbidden", r?: string) => fail("FORBIDDEN", m, r);
export const notFound = (m = "Not found", r?: string) => fail("NOT_FOUND", m, r);
export const conflict = (m = "Conflict", r?: string) => fail("CONFLICT", m, r);
/**
* Never leaks the underlying exception. A stack frame or a table name in a
* browser response is an information disclosure; the requestId is the
* bridge between what the caller sees and what you can find in the logs.
*/
export const serverError = (r?: string) =>
fail("INTERNAL", "Something went wrong on our side.", r);