# Trego – Phase 0 Architecture Decisions (Locked)

> Purpose: Freeze all irreversible technical and product decisions before writing any code.
>
> Scope: Phase 0 only. Any change after this point must be explicitly justified.

---

## 1. Product Definition

**What Trego is**

Trego is a **single-city ride dispatch platform** that connects riders and drivers with **deterministic pricing** and a **strict ride lifecycle**.

**What Trego is NOT**

* Not a marketplace bidding system
* Not surge-based pricing
* Not a multi-city or multi-country platform
* Not a subscription or wallet-based system

**Locked Statement**

> Trego is a single-city ride dispatch platform with fixed pricing rules. Ride matching is system-assigned, not rider-selected.

---

## 2. Client–Server Architecture

**Architecture Style**

* Backend: Rails API-only service
* Clients: React (Web), React Native (Mobile – future)
* Clients are replaceable; backend is the source of truth.

**Rules**

* Backend serves JSON only
* No server-rendered HTML
* All clients communicate via HTTP JSON APIs

**Locked Statement**

> Backend is a pure JSON API consumed by web and mobile clients.

---

## 3. Backend Framework

**Framework**

* Ruby on Rails (API-only)
* PostgreSQL database

**Implications of API-only**

* No ERB views
* No cookies or sessions
* No server-side UI logic

**Locked Statement**

> Trego backend is a Rails API-only service.

---

## 4. Authentication

**Authentication Method**

* JWT (JSON Web Tokens)

JWT Policy (Phase 1 Defaults)
* Access token expiry: 24 hours
* No refresh tokens in MVP
* Subject to revision in future phases

**Token Flow**

1. User logs in
2. Backend issues JWT
3. Client stores JWT
4. JWT sent on every request via Authorization header

**Header Format**

```
Authorization: Bearer <token>
```

**JWT Payload (Minimum)**

```json
{
  "user_id": 123,
  "role": "driver",
  "exp": 1712345678
}
```

**Locked Statement**

> All protected endpoints require JWT authentication.

---

## 5. Authorization (RBAC)

**Model**

* Role-Based Access Control (RBAC)

**Roles**

* rider
* driver
* admin

**Design Choice**

* Single `users` table
* Role stored as enum

**Enforcement Rule**

* Authorization enforced in backend controllers
* Frontend has no authority logic
* Role escalation is not allowed without admin action.

**Locked Statement**

> Authorization is enforced exclusively in the backend.

---

## 6. Geography Scope

**Initial Scope**

* Single city: Montreal

**Future-Safe Model**

```text
cities
- id
- name
- active
```

**Phase 1 Constraint**

* Only Montreal is active

**Locked Statement**

> All rides operate within Montreal for Phase 1.

---

## 7. Core Domain Entities

**Entities**

* User
* Vehicle
* Ride
* Payment
Value object (Not Standalone tables in MVP)
* Location (lat/lng pairs stored on Ride)

Locked Statement:
> Location is a value object embedded in Ride records for MVP.

**Ownership Rules**

* A ride belongs to exactly:

  * One rider
  * One driver
  * One vehicle

**Locked Statement**

> Each ride has exactly one rider and one driver.

---

## 8. Ride Lifecycle

**Allowed States**

```
requested → assigned → accepted → started → completed
                     ↘ cancelled
```

**Rules**

* No skipping states
* No backward transitions
* Cancellation allowed only in specific states
* State transitions are validated server-side and are atomic.
* Only the backend can authorize and execute ride state transitions.
* Clients may request transitions but cannot enforce them.

**Locked Statement**

> Ride state transitions are strictly enforced.

---

## 9. Pricing Model (MVP)

**Pricing Philosophy**

* Deterministic
* Transparent
* Rule-based

**Example Formula**

* Base fare: $3
* Per km: $1.25
* Per minute: $0.30

**Exclusions**

* No surge pricing
* No AI-based pricing

**Locked Statement**

> Pricing is deterministic and predictable for MVP. Pricing is computed server-side and returned as a breakdown.

---

## 10. Explicit Non-Goals (Phase 1)

The following features are explicitly excluded from Phase 1:

* AI pricing
* Subscriptions
* Multi-language
* Wallets
* Tips
* Ratings
* Promotions
* Refund automation

**Locked Statement**

> Features not listed are intentionally excluded.

🔒 Explicit Phase 1 Exclusion — Driver Subscriptions

> Driver subscription billing is intentionally excluded from Phase 1.
> Phase 1 validates dispatch, lifecycle, and unit economics without monetization logic.
> Subscription models will be introduced in Phase 2 after usage data is available.

---

## 11. API Structure & Versioning

**Versioning Rule**

* All APIs are versioned from day one

**Base Path**

```
/api/v1/
```

**Example Endpoints**

```
POST /api/v1/auth/login
POST /api/v1/auth/signup
POST /api/v1/rides
GET  /api/v1/driver/rides
GET  /api/v1/admin/stats
```

**Locked Statement**

> All APIs are versioned.

---

## 12. Phase 0 Completion Criteria

Phase 0 is complete when:

* Architecture decisions are documented
* Roles are finalized
* Ride lifecycle is locked
* Pricing model is defined
* Non-goals are explicitly stated

No code is written before this document is approved.

---

**Status:** LOCKED

This document is frozen as of Phase 0.
Any change requires a written justification and version bump.
