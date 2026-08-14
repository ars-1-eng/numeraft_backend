// Prepare → execute → observe → classify errors → respond → clean up.

import type {
APIGatewayProxyEventV2,
APIGatewayProxyEventV2WithJWTAuthorizer,
APIGatewayProxyStructuredResultV2,
Context,
} from "aws-lambda";
import { logger, withRequestContext, clearRequestContext } from "./logger.ts";
import { serverError } from "./http.ts";
import { AppError } from "./errors.ts";
import { extractIdentity, extractPrincipal } from "./auth.ts";
import type { Identity, Principal } from "./auth.ts";

// Extra information that every business handler receives
export interface RequestContext{
    requestId:string
}


export interface AuthedContext extends RequestContext{
  principal:Principal
}
export interface IdentityContext extends RequestContext{
  identity:Identity
}

type Outcome=Promise<APIGatewayProxyStructuredResultV2>;


// Share tail: log the outcome, map errors , always clear log context

async function run(
  requestId:string,
  routeKey:string,
  context: Context,
  work:()=>Outcome
):Outcome{

  // Start timers
  const started=Date.now()

  try{
    // Attach req context
    withRequestContext({requestId,route:routeKey});
// run actual handle work
    const response=await work();

    logger.info(
      "request completed",{
        status:response.statusCode,
        durationMs:Date.now()-started,
        remainingMs:context.getRemainingTimeInMillis()
      }
    );
    // succes-> return response
    return response;
  }
  catch(error){
 // error -> expected AppError
    if(error instanceof AppError){
      logger.warn("request failed",{
        code:error.code,
        reason:error.message,
        durationMs:Date.now()-started
      });
          return error.toResponse(requestId)

    }
    //       -> unexpected Error
    logger.error("unhandled error",{
      error: error instanceof Error?error.message:String(error),
      stack: error instanceof Error ? error.stack : undefined,
durationMs: Date.now()- started,
    })
    return serverError(requestId);

  }
  finally{
  
// Clear Request Context
    clearRequestContext();
  }

}




// Define the required structure of a public business handler
type PublicHandler = (
  event: APIGatewayProxyEventV2,
  ctx: RequestContext,
) =>
  | APIGatewayProxyStructuredResultV2
  | Outcome





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




export function authed(
  handler:(
    event:APIGatewayProxyEventV2WithJWTAuthorizer,
    ctx:AuthedContext
  )=>Outcome
){
  return(
    event:APIGatewayProxyEventV2WithJWTAuthorizer,
    context: Context
  ):Outcome=>
    run(
      event.requestContext.requestId,
      event.requestContext.routeKey,
      context,
      ()=>{
        const principal=extractPrincipal(event);

        withRequestContext({agencyId:principal.agencyId,userId:principal.userId});

        return handler(event,{
          principal,
          requestId:event.requestContext.requestId
        });
      }
    )
}


export function authedIdentity(
  handler:(
    event:APIGatewayProxyEventV2WithJWTAuthorizer,
    ctx:IdentityContext
  )=>Outcome
){
  return(
    event:APIGatewayProxyEventV2WithJWTAuthorizer,
    context:Context
  ):Outcome=>
    run(
    event.requestContext.requestId,
    event.requestContext.routeKey,
    context,()=>{
      const identity=extractIdentity(event);
      withRequestContext({
        userId:identity.userId
      })

      return handler(event,{
        requestId:event.requestContext.requestId,
        identity
      });
        }
    )
}