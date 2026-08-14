import type { AgencyDto,Branding,Plan } from "../contracts/me.ts";

export const DEFAULT_PRIMARY_COLOR = "#4B45D4";

export const DEFAULT_BRANDING={
    primary_color: DEFAULT_PRIMARY_COLOR,
    accent_color: null,
    logo_key:null
} as const;


const PLANS:readonly string[]=["founding","starter","growth"];

function asString(value:unknown,fallback:string):string{
    return typeof value==="string" && value!==""?value:fallback
}
function asNullableString(value:unknown):string|null{
    return typeof value==="string" && value!==""?value:null
}


export function toAgencyDto(
    item:Record<string,unknown>,
    logoUrl:string | null=null
):AgencyDto{
    const rawBranding=(item["branding"]??{})as Record<string,unknown>;

    const branding:Branding={
        logoUrl,
        primaryColor: asString(rawBranding["primary_color"], DEFAULT_PRIMARY_COLOR),
        accentColor: asNullableString(rawBranding["accent_color"]),
    };

    const plan=asString(item["plan"],"founding");

    return {
        id: asString(item["agency_id"], ""),
        name: asString(item["name"], "My agency"),
        plan: (PLANS.includes(plan) ? plan : "founding") as Plan,
        branding,
        onboardingStage: asString(item["onboarding_stage"], "connect_ga4"),
        createdAt: asString(item["created_at"], new Date(0).toISOString()),
    };
}
export function deriveAgencyName(email: string): string {
  const domain = email.split("@")[1] ?? "";

  if (domain === "") return "My agency";

  const firstLabel = domain.split(".")[0] ?? "";

  // Generic mailbox providers tell you nothing about the agency.
  const GENERIC = ["gmail", "outlook", "hotmail", "yahoo", "icloud", "proton"];

  if (GENERIC.includes(firstLabel.toLowerCase())) {
    return "My agency";
  }

  let name = domain.toLowerCase();

  if (name.endsWith(".co.uk")) {
    name = name.slice(0, -6);
  } else if (name.endsWith(".com")) {
    name = name.slice(0, -4);
  }

  return name
    .replace(/[.\-_]+/g, " ")
    .replace(/\b\w/g, (character) => character.toUpperCase());
}
