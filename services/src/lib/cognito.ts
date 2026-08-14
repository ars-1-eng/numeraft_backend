import {
CognitoIdentityProviderClient,
AdminUpdateUserAttributesCommand,
} from "@aws-sdk/client-cognito-identity-provider";
import type { Role } from "./auth.ts";

const cognito=new CognitoIdentityProviderClient({maxAttempts:3});

export async function writeTenancyAttributes(args:{
userPoolId: string;
username: string;
agencyId: string;
role: Role;
onboardingStage?: string;}):Promise<void>{
    await cognito.send(
        new AdminUpdateUserAttributesCommand({
            Username:args.username,
            UserPoolId:args.userPoolId,
            UserAttributes:[
                {Name:"custom:agency_id",Value:args.agencyId},
                {Name:"custom:role",Value:args.role},
                {Name:"custom:onboarding_stage",Value:args.onboardingStage??"connect_ga4"},
            ]
        })
    )
}