import { Logger } from "@aws-lambda-powertools/logger";
import { env } from "./env.ts";
const LEVELS = ["DEBUG", "INFO", "WARN", "ERROR"] as const;
type Level = (typeof LEVELS)[number];
function level(raw: string): Level {
const upper = raw.toUpperCase();
return (LEVELS as readonly string[]).includes(upper) ? (upper as Level) : "INFO";
}
export const logger = new Logger({
serviceName: `${env.appName}-${env.environment}`,
logLevel: level(env.logLevel),
persistentKeys: {
environment: env.environment,
},
});
/**
* Attach per-request context so every log line for this invocation carries
* it. In Book 1 this is where agencyId and userId are added, which is what
* makes "show me everything that happened for this customer" a one-line
* CloudWatch Logs Insights query.
*/
export function withRequestContext(fields: Record<string, string>): void {
logger.appendKeys(fields);
}
/**
* MUST be called in a finally block. Lambda reuses execution environments,
* so keys appended during one invocation are still attached during the
* next one on the same container. Without this reset, a request from one
* agency emits log lines tagged with another agency's ID, and you end up
* debugging a support ticket using logs that lie to you.
*/
export function clearRequestContext(): void {
logger.resetKeys();
}