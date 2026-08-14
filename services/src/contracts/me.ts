export type Plan = "founding" | "starter" | "growth";
export type Role = "owner" | "admin" | "member";
export interface Branding {
/** Presigned URL, or null until a logo is uploaded. Book 2 fills this in. */
logoUrl: string | null;
primaryColor: string;
accentColor: string | null;
}
export interface AgencyDto {
id: string;
name: string;
plan: Plan;
branding: Branding;
onboardingStage: string;
createdAt: string;
}
export interface UserDto {
id: string;
email: string;
role: Role;
}
export interface MeResponse {
user: UserDto;
agency: AgencyDto;
}
export interface BootstrapResponse {
/** True when this call created the agency, false when it already existed. */
created: boolean;
agencyId: string;
/**
* Always true. The client MUST refresh its tokens before calling GET /me,
* because the new tenancy claims are not in the token it already holds.
*/
tokenRefreshRequired: boolean;
}