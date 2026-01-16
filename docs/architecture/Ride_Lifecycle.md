Ride Lifecycle — Trego Backend

Status: Phase 0 / Phase 1
Scope: Ride state machine, transitions, and enforcement rules
Out of scope: Pricing logic, UI behavior, notifications

1. Purpose
This document defines the complete lifecycle of a ride in Trego.

Goals:
* Prevent invalid ride states
* Ensure predictable behavior
* Avoid race conditions
* Enable future real-time updates
* Make rides auditable and debuggable

The ride lifecycle is a strict finite state machine.

2. Core Principle (Locked)

A ride can only move forward through predefined states.
No skipping. No reversing. No ambiguity.

3. Ride States (Locked)

The ride can exist in exactly one of the following states:

State	                  Description
requested	      Rider has created a ride request
assigned	      System has assigned a driver
accepted	      Driver has accepted the ride
started	        Driver has started the trip
completed	      Ride successfully completed
cancelled	      Ride cancelled by rider or system

No additional states are allowed in Phase 1.

4. Visual State Flow
requested → assigned → accepted → started → completed
                     ↘
                      cancelled

5. State Transition Rules (Strict)

Only the following transitions are allowed:
From	          To	          Trigger
requested	   assigned	   System assigns driver
assigned	   accepted	   Driver accepts ride
accepted	   started	   Driver starts trip
started	    completed	   Driver completes trip
requested	  cancelled	   Rider cancels
assigned	  cancelled	   Rider or system cancels
accepted	  cancelled	   Rider or system cancels

All other transitions are invalid.

6. Who Can Trigger Which Transitions
Rider
A rider can:
* Create a ride (requested)
* Cancel a ride before started

A rider cannot:
* Assign drivers
* Accept rides
* Start or complete rides
* Cancel after ride has started

Driver
A driver can:
* Accept a ride (assigned → accepted)
* Start a ride (accepted → started)
* Complete a ride (started → completed)

A driver cannot:
* Cancel rides (Phase 1)
* Skip states
* Accept unassigned rides

System (Backend)
The system can:
* Assign a driver (requested → assigned)
* Cancel rides due to timeout or errors

System actions are logged and auditable.

7. Cancellation Rules
Allowed Cancellation States
Cancellation is allowed only in:
* requested
* assigned
* accepted

Cancellation is not allowed in:
* started
* completed

Cancellation Effects
When a ride is cancelled:
* Final state becomes cancelled
* No further transitions allowed
* Cancellation reason is recorded
* Timestamps are preserved

8. State Immutability
Once a ride reaches:
* completed
* cancelled

It becomes immutable.

No edits allowed to:
* State
* Driver
* Rider
* Vehicle
* Pricing

This ensures auditability.

9. Validation & Enforcement
Server-Side Enforcement
* All state transitions validated server-side
* No trust in frontend input
* Invalid transitions return 422 Unprocessable Entity

Example rule:
A ride in requested cannot be marked as started.

10. Concurrency & Atomicity
State transitions must be:
* Atomic
* Transactional
* Race-condition safe

The backend must ensure:
* A ride is accepted by only one driver
* No double assignment
* No duplicate starts or completions

11. Timestamps (Required)
Each transition records a timestamp:
Field	              Description
requested_at	   When ride was created
assigned_at	     When driver assigned
accepted_at	     When driver accepted
started_at	     When ride started
completed_at	   When ride completed
cancelled_at	   When ride cancelled

Only one terminal timestamp exists per ride.

12. Ownership Enforcement
At every transition:
* Rider must own the ride
* Driver must be the assigned driver
* Admin/system actions must be authorized

Ownership is always verified server-side.

13. API Error Behavior
Condition	                    HTTP Status
Invalid state transition	        422
Unauthorized role	                403
Wrong owner	                      403
Ride not found	                  404

Error messages are generic.

14. Future Extensions (Not Phase 1)

Explicitly excluded for now:
* Pause / resume
* Multi-stop rides
* Driver cancellation
* Rider ratings
* Refund flows
* Dispute states

Any extension requires updating this document.

15. Locked Statement

* Ride state transitions in Trego are strictly enforced, immutable, and validated exclusively by the backend.
* No ride may skip or reverse states.
