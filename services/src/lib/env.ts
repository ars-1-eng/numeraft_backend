function required(name: string): string {
const value = process.env[name];
if (value === undefined || value === "") {
// Thrown at module load, so the cold start fails loudly and CloudWatch
// names the missing variable. Far better than an undefined reaching
// a DynamoDB key and producing a confusing ValidationException.
throw new Error(`Missing required environment variable: ${name}`);
}
return value;
}
function optional(name: string, fallback: string): string {
const value = process.env[name];
return value === undefined || value === "" ? fallback : value;
}
export const env = {
appName: optional("APP_NAME", "numeraft"),
environment: optional("ENVIRONMENT", "unknown"),
region: optional("AWS_REGION", "eu-west-1"),
logLevel: optional("LOG_LEVEL", "INFO"),
} as const;
/**
* Table names are exposed as getters so each handler only pays for what it
* reads. An eager check would crash the health function, which has none.
* Book 1 onward uses these.
*/
export const tables = {
get agencies(): string {
return required("AGENCIES_TABLE");
},
get users(): string {
return required("USERS_TABLE");
},
} as const;