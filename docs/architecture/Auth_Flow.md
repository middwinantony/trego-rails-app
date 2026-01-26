Auth Flow — Trego Backend

Status: Phase 0 / Phase 1
Scope: Authentication mechanics only
Out of scope: Authorization logic, UI flows, OAuth, refresh tokens

1. Purpose
This document defines how authentication works in the Trego backend.

Goals:
* Secure API access
* Stateless authentication
* Mobile-friendly token usage
* Clear separation between authentication and authorization
This document does not define permissions.
Permissions are defined in Roles_And_Permissions.md.

2. Authentication Strategy
Method
Trego uses JWT (JSON Web Tokens) for authentication.

Key Properties
* Stateless
* Token-based
* Client-stored
* Sent with every protected request

Non-Goals
* No session-based authentication
* No cookies
* No OAuth providers
* No API keys
* No refresh tokens (Phase 1)

3. Token Types
Access Token
Only one token type exists in Phase 1:
* Access Token (JWT)

There are:
* ❌ No refresh tokens
* ❌ No rotating tokens
* ❌ No token revocation list
Expired tokens require re-login.

4. Token Issuance Flow
Signup Flow
1. Client submits signup request
2. Backend validates input
3. User record is created
4. JWT is issued
5. JWT is returned in response body

Login Flow
1. Client submits login credentials
2. Backend validates credentials
3. JWT is issued
4. JWT is returned in response body

POST /api/v1/auth/login

5. JWT Structure

* Authentication uses email + password.
* email + password is the primary user identifier and must be unique.

Token Payload (Minimum)
{
  "user_id": 123,
  "role": "driver",
  "exp": 1712345678
}

Required Claims
Claim	                    Purpose
user_id	         Identify authenticated user
role	          Used for authorization checks
exp	             Token expiry (Unix timestamp)

No additional claims are allowed in Phase 1.

6. Token Lifetime
Expiry Policy
* Access token expiry: 24 hours
* Expiry is enforced server-side
* Expired tokens are rejected automatically

Rationale
* Simplicity
* Reduced attack surface
* Acceptable UX tradeoff for MVP

7. Token Storage (Client Responsibility)
Clients are responsible for securely storing the JWT.

Allowed Storage
* Web: memory or secure storage
* Mobile: secure keychain / keystore

Disallowed Storage
* ❌ Cookies
* ❌ LocalStorage for sensitive contexts

Backend does not manage or validate storage method.

8. Authenticated Requests
Authorization Header Format
All authenticated requests must include:
Authorization: Bearer <jwt_token>

Enforcement Rule
* Missing token → 401 Unauthorized
* Invalid token → 401 Unauthorized
* Expired token → 401 Unauthorized

9. Backend Authentication Enforcement
Global Rule
All endpoints are protected by default.

Exceptions:
* POST /api/v1/auth/signup
* POST /api/v1/auth/login

Every other endpoint requires a valid JWT.

Controller Enforcement Pattern (Conceptual)
before_action :authenticate_request!

Responsibilities:
* Decode JWT
* Validate signature
* Check expiration
* Set current_user
No authorization logic lives here.

10. Failure Scenarios
Scenario	                Result
Missing token	       401 Unauthorized
Invalid signature	   401 Unauthorized
Expired token	       401 Unauthorized
Malformed token	     401 Unauthorized

Error responses are consistent and non-descriptive.

11. Security Considerations
Phase 1 Assumptions
* JWT secret is stored securely (ENV)
* HTTPS is enforced at deployment level
* Token rotation is deferred

Explicit Tradeoffs
* No token revocation
* No device tracking
* No forced logout

These are accepted risks for MVP.

12. Responsibilities Summary
Backend
* Issue JWT
* Validate JWT
* Enforce expiry
* Identify user

Client
* Store JWT securely
* Send JWT on every request
* Handle 401 responses
* Re-authenticate when needed

13. Future Extensions (Not in Phase 1)
* Refresh tokens
* Token revocation
* OAuth providers
* Multi-device sessions

These require a new architecture review.

14. Locked Statement

Authentication in Trego is stateless, JWT-based, and enforced exclusively by the backend.
All protected endpoints require a valid access token.
