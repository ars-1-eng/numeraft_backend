# Numeraft API contract
The source of truth for the interface between the backend and the Flutter app.
`services/src/contracts/*.ts` must match this file exactly.
## Rules
1. **Additive only.** Never rename or remove a field the app reads. Add a new
one and mark the old one deprecated in a comment.
2. **Timestamps** are ISO 8601 UTC strings: `"2026-06-30T00:00:00.000Z"`.
Never epoch numbers.
3. **Numbers are numbers.** Send `12.4`, not `"12.4%"`. The client formats.
4. **Enums** are lowercase snake strings, never integers.
5. **Lists are wrapped**: `{ "items": [...], "nextCursor": null }`. Never a
bare array, so pagination and totals can be added later without breaking
the parser.
6. **Mutations return the full updated object.**
## Errors
Every non-2xx response, from every endpoint, has this shape:
```json
{
"error": {
"code": "NOT_FOUND",
"message": "Report not found.",
"requestId": "abcd1234",
"details": { "field": "why it failed" }
}
}
```
`details` is present only for validation failures. `requestId` is what a
customer pastes into a support message so it can be found in CloudWatch.
| code | status | client should |
|---|---|---|
| `BAD_REQUEST` | 400 | Show field errors from `details` |
| `UNAUTHORIZED` | 401 | Refresh tokens once, then sign out |
| `FORBIDDEN` | 403 | Show "no access" |
| `NO_AGENCY` | 403 | Call `POST /me/bootstrap`, refresh tokens, retry once |
| `NOT_FOUND` | 404 | Show empty or missing state |
| `CONFLICT` | 409 | Reload and retry |
| `RATE_LIMITED` | 429 | Back off and retry |
| `INTERNAL` | 500 | Show retry, include `requestId` in any report |
## Authentication
Set by Book 1. Summary: `Authorization: Bearer <Cognito ID token>`.
The **ID token**, not the access token, because custom claims such as
`custom:agency_id` exist only in the ID token.
## Endpoints
### GET /health
Public. No authentication.
```json
{
"status": "ok",
"service": "numeraft-api",
"environment": "dev",
"timestamp": "2026-07-27T09:12:04.117Z",
"requestId": "abcd1234"
}
```

### Later
`GET /me`, `POST /me/bootstrap` in Book 1.
`GET /reports`, `GET /reports/{reportId}`, `PATCH /branding`,
`POST /clients` in Book 2.
`GET|POST|DELETE /connections` in Book 3.
`POST /reports` in Book 4.