import { fail, type ErrorCode } from "./http.ts";
/**
* An expected failure with a known HTTP mapping. Anything thrown that is
* NOT an AppError is a bug, gets logged with its stack, and returns 500.
*
* Note the explicit field assignment rather than constructor parameter
* properties: parameter properties emit runtime code, so they are banned
* by erasableSyntaxOnly in tsconfig.
*/
export class AppError extends Error {
readonly code: ErrorCode;
readonly details: unknown;
constructor(code: ErrorCode, message: string, details?: unknown) {
super(message);
this.name = "AppError";
this.code = code;
this.details = details;
}
toResponse(requestId: string) {
return fail(this.code, this.message, requestId, this.details);
}
}
export const notFoundError = (what: string) =>
new AppError("NOT_FOUND", `${what} not found.`);
export const validationError = (details: unknown) =>
new AppError("BAD_REQUEST", "The request body is not valid.", details);
export const forbiddenError = (why = "You do not have access to this resource.") =>
new AppError("FORBIDDEN", why);
export const conflictError = (why: string) => new AppError("CONFLICT", why);