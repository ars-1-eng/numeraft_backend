// Prepare → execute → observe → classify errors → respond → clean up.

import type {
APIGatewayProxyEventV2,
APIGatewayProxyStructuredResultV2,
Context,
} from "aws-lambda";
import { logger, withRequestContext, clearRequestContext } from "./logger.ts";
import { serverError } from "./http.ts";
import { AppError } from "./errors.ts";


// Extra information that every business handler receives
export interface RequestContext{
    requestId:string
}

// Define the required structure of a public business handler
type PublicHandler = (
  event: APIGatewayProxyEventV2,
  ctx: RequestContext,
) =>
  | APIGatewayProxyStructuredResultV2
  | Promise<APIGatewayProxyStructuredResultV2>;


// Wrapper that adds common behavior around a public route.

export function publicRoute(handler:PublicHandler){
    return async(
        event:APIGatewayProxyEventV2,
        ctx:Context

    ):Promise<APIGatewayProxyStructuredResultV2>=>{
    const requestId = event.requestContext.requestId;
     const started = Date.now();

     try{
        withRequestContext({
            requestId,route:event.requestContext.requestId
            
        });

        const response= await handler(event,{requestId}        )
  logger.info("request completed", {
        status: response.statusCode,
        durationMs: Date.now() - started,
        remainingMs: ctx.getRemainingTimeInMillis(),
      });


        return response;
     }catch(error){
 if (error instanceof AppError) {
        logger.warn("request failed", {
          code: error.code,
          reason: error.message,
          durationMs: Date.now() - started,
        });

        // Convert the AppError into its correct HTTP response.
        return error.toResponse(requestId);
      }

      // Handle unexpected bugs or infrastructure failures.
      logger.error("unhandled error", {
        error:
          error instanceof Error
            ? error.message
            : String(error),
        stack:
          error instanceof Error
            ? error.stack
            : undefined,
        durationMs: Date.now() - started,
      });

      // Return a safe 500 response without exposing internal details.
      return serverError(requestId);
     }finally {
      // Always remove request-specific log data before Lambda is reused.
      clearRequestContext();
    }
    };
}