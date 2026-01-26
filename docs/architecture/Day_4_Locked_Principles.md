1. Authorization lives ONLY in backend
2. Controllers never trust params
3. Controllers never trust frontend
4. Controllers never trust JWT role blindly

Flow is always:
JWT → authenticate_request → current_user → role guard
* If a controller skips a role guard, it’s a bug.


RIDE LIFECYCLE
1️⃣ Ride States (LOCKED ENUM)
requested → assigned → accepted → started → completed
                 ↘
                  cancelled

No other states.
No shortcuts.
No skipping.

2️⃣ Who Can Trigger What (SOURCE OF TRUTH)
🧍 Rider Actions
* Can request a ride → requested
* Can cancel a ride:
  * ONLY if state is requested or assigned
* Can never:
  * Assign drivers
  * Start ride
  * Complete ride

🚗 Driver Actions
* Can accept a ride:
  * ONLY if state is assigned
* Can start a ride:
  * ONLY if state is accepted
* Can complete a ride:
  * ONLY if state is started
* Can never:
  * Cancel ride
  * Accept unassigned ride
  * Skip states

⚙️ System Actions (Backend Logic)
* Can assign a driver:
  * requested → assigned
* Can auto-cancel if:
  * No driver accepts within time window (future)
📌 System ≠ admin ≠ driver

3️⃣ Illegal Transitions (EXPLICITLY FORBIDDEN)
These must never be allowed:
❌ requested → started
❌ assigned → completed
❌ accepted → cancelled
❌ started → accepted
❌ completed → anything
❌ cancelled → anything
📌 Once terminal (completed, cancelled) → immutable

4️⃣ Plain-English Rules (MANDATORY — COPY THIS)
* A ride starts in requested
* Only the system can assign a driver
* A driver cannot accept an unassigned ride
* A rider can only cancel before a ride starts
* No role can skip ride states
* Terminal states cannot be changed
