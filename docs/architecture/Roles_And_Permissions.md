Roles & Permissions — Trego Backend

Status: Phase 0 / Phase 1
Scope: Authorization model and enforcement rules
Out of scope: UI permissions, auth mechanics, pricing logic

1. Purpose
This document defines who can do what in the Trego system.

Goals:
* Enforce access control consistently
* Prevent role escalation
* Keep authorization logic centralized
* Avoid frontend-driven security decisions

Authorization is always enforced by the backend.

2. Authorization Model
Strategy
Trego uses Role-Based Access Control (RBAC).

Key Principles
* Every user has exactly one role
* Roles are mutually exclusive
* Roles are stored on the user record
* Roles are embedded in JWTs
* Permissions are enforced server-side

3. Roles (Locked)

The system defines three roles only in Phase 1:

Role	             Description
rider	       Requests and pays for rides
driver	     Accepts and completes rides
admin	         Manages the platform

No additional roles are allowed in Phase 1.

4. Role Storage
Users Table
* Role is stored as an enum on users.role
* Allowed values:
  * rider
  * driver
  * admin

Role Immutability
* Users cannot change their own role
* Role changes require admin action
* Role changes invalidate existing sessions (future)

5. Authorization Enforcement Rules
Backend Authority Rule
The backend is the sole authority for authorization decisions.

The frontend:
* Does NOT determine permissions
* Does NOT hide or show logic for security
* May only display based on API responses

6. Permission Scope by Role
Rider Permissions
A rider can:
* Create ride requests
* View own ride history
* View pricing breakdown
* Cancel eligible rides

A rider cannot:
* Accept rides
* View other riders' data
* View driver-only endpoints
* Access admin endpoints

Driver Permissions
A driver can:
* View assigned rides
* Accept or reject assigned rides
* Start and complete rides
* View own earnings (Phase 1: basic)

A driver cannot:
* Request rides
* Assign themselves rides
* View other drivers’ data
* Access admin endpoints

Admin Permissions
An admin can:
* View platform metrics
* View all users
* Suspend users
* Access admin-only dashboards

An admin cannot:
* Request rides
* Accept rides
* Act as rider or driver
Admins are not dual-role users.

7. Endpoint-Level Authorization
Authorization Pattern
Each controller enforces role access explicitly.

Conceptual example:
before_action :authorize_driver!

Authorization checks:
* Run after authentication
* Use current_user.role
* Reject unauthorized access early

8. Cross-Role Access Rules
Ownership Rules
Even with correct role:
* Riders can only access their own rides
* Drivers can only access their assigned rides
* Admins can access all records

This prevents horizontal privilege escalation.

9. Forbidden Role Behavior
The following are explicitly forbidden:
* Rider accepting rides
* Driver requesting rides
* Driver seeing unassigned rides
* Frontend enforcing permissions
* Role switching via API

Any attempt results in 403 Forbidden.

10. Error Handling
Authorization Failure Response
Condition	                                Response
Authenticated but unauthorized	        403 Forbidden
Unauthenticated	                        401 Unauthorized

Error messages are generic and non-descriptive.

11. Future Role Extensions (Not Phase 1)
The following are intentionally deferred:
* Dual-role users
* Fleet managers
* Support agents
* Driver tiers
* Sub-admin roles

Any role expansion requires:
* New role definitions
* Permission matrix update
* Architecture review

12. Responsibilities Summary
Backend
* Enforce all permissions
* Validate ownership
* Prevent escalation
* Return correct HTTP status codes

Frontend
* Consume API responses
* Display based on backend output
* Never assume permissions

13. Locked Statement

Role-based permissions in Trego are enforced exclusively by the backend.
Users have exactly one role, and permissions are immutable without admin action.
