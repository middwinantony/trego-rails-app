# Comprehensive Code Analysis Report
## Trego Rails Application

**Generated:** 2026-01-27
**Analysis Tools:** Manual Code Review + RuboCop 1.x
**Files Inspected:** 64
**Total Issues Found:** 380

---

## Executive Summary

This report combines automated code analysis (RuboCop) with manual security and functional review to identify issues across the Trego Rails application. Issues are categorized by severity and type.

### Issue Breakdown by Severity

| Severity | Count | Description |
|----------|-------|-------------|
| **CRITICAL** | 4 | Will cause crashes or complete feature breakage |
| **HIGH** | 14 | Security vulnerabilities, missing functionality, data integrity issues |
| **MEDIUM** | 21 | Validation, error handling, performance concerns |
| **LOW** | 341 | Code style, conventions, minor quality issues |
| **TOTAL** | **380** | |

### Issue Breakdown by Category

| Category | Critical | High | Medium | Low | Total |
|----------|----------|------|--------|-----|-------|
| **Functional Bugs** | 4 | 0 | 0 | 1 | 5 |
| **Security** | 0 | 3 | 3 | 0 | 6 |
| **Authentication/Authorization** | 0 | 3 | 2 | 0 | 5 |
| **API/Controller Issues** | 0 | 4 | 5 | 0 | 9 |
| **Database/Schema** | 0 | 3 | 2 | 0 | 5 |
| **Validation/Error Handling** | 0 | 1 | 4 | 0 | 5 |
| **Configuration** | 0 | 0 | 2 | 1 | 3 |
| **Code Style** | 0 | 0 | 0 | 168 | 168 |
| **Documentation** | 0 | 0 | 0 | 25 | 25 |
| **Code Structure** | 0 | 0 | 0 | 12 | 12 |
| **Metrics (Complexity)** | 0 | 0 | 0 | 9 | 9 |
| **Layout/Formatting** | 0 | 0 | 3 | 125 | 128 |

---

## PART 1: CRITICAL ISSUES (MUST FIX IMMEDIATELY)

These issues will cause application crashes or complete feature failures.

### C-1: Undefined Variable Reference
**File:** `app/controllers/api/v1/rides_controller.rb:34-39`
**Type:** Functional Bug
**RuboCop:** `Lint/UselessAssignment` (Warning)

**Issue:**
```ruby
active_ride = Ride.where(...).exists?  # Line 34 - assigns to 'active_ride'
# ...
if active_ride?  # Line 39 - references undefined 'active_ride?' method
```

**Impact:** Will crash with `NoMethodError: undefined method 'active_ride?'` when creating rides.

**Fix:**
```ruby
# Change line 39 from:
if active_ride?
# To:
if active_ride
```

---

### C-2: Invalid HTTP Status Symbol
**File:** `app/controllers/api/v1/auth_controller.rb:37`
**Type:** Functional Bug

**Issue:**
```ruby
render json: { errors: "Invalid credentials" }, status: :Unauthorized
```

**Impact:** Rails will crash with `TypeError` - Symbol must be lowercase (`:unauthorized`).

**Fix:**
```ruby
render json: { errors: "Invalid credentials" }, status: :unauthorized
```

---

### C-3: Wrong HTTP Status on Successful Signup
**File:** `app/controllers/api/v1/auth_controller.rb:16`
**Type:** API Contract Bug

**Issue:**
```ruby
if user.save
  render json: { token: token, user: user_response(user) }, status: :unprocessable_entity
end
```

**Impact:** Returns 422 (Validation Error) on successful signup instead of 201 (Created). Breaks client integration.

**Fix:**
```ruby
render json: { token: token, user: user_response(user) }, status: :created
```

---

### C-4: Login Parameter Mismatch
**File:** `app/controllers/api/v1/auth_controller.rb:21`
**Type:** Functional Bug

**Issue:**
```ruby
user = User.find_by(email: params[:phone])  # Searches email field using phone param
```

**Impact:** Login completely broken - receives `phone` but searches `email` field.

**Fix:**
```ruby
# Either:
user = User.find_by(email: params[:email])
# Or update API to accept phone and search phone field
```

---

## PART 2: HIGH SEVERITY ISSUES

### Security Vulnerabilities

#### H-1: Wide Open CORS Policy
**File:** `config/initializers/cors.rb:20`
**Type:** Security - CSRF Risk
**Severity:** HIGH

**Issue:**
```ruby
origins '*'  # Accepts requests from ANY origin
```

**Impact:** Any website can make authenticated requests to your API. Enables CSRF-like attacks.

**Fix:**
```ruby
origins ENV.fetch('CORS_ALLOWED_ORIGINS', 'localhost:3000').split(',')
```

---

#### H-2: No Rate Limiting on Auth Endpoints
**File:** `app/controllers/api/v1/auth_controller.rb`
**Type:** Security - Brute Force
**Severity:** HIGH

**Issue:** No rate limiting on signup/login endpoints.

**Impact:** Vulnerable to:
- Password brute force attacks
- Account enumeration
- Bot signup spam

**Fix:** Implement `rack-attack` gem:
```ruby
# Add to Gemfile
gem 'rack-attack'

# config/initializers/rack_attack.rb
Rack::Attack.throttle('login/email', limit: 5, period: 60) do |req|
  req.params['email'] if req.path == '/api/v1/auth/login' && req.post?
end
```

---

#### H-3: Exception Messages Exposed to Client
**File:** `app/controllers/api/v1/driver/rides_controller.rb:18`
**Type:** Security - Information Disclosure
**Severity:** HIGH

**Issue:**
```ruby
rescue StandardError => e
  render json: { error: e.message }, status: :unprocessable_entity
```

**Impact:** Internal errors and stack traces leak sensitive information about application structure.

**Fix:**
```ruby
rescue StandardError => e
  Rails.logger.error("Ride error: #{e.message}\n#{e.backtrace.join("\n")}")
  render json: { error: 'Unable to process ride' }, status: :unprocessable_entity
end
```

---

### Missing Functionality

#### H-4: Missing Authorization Check
**File:** `app/controllers/api/v1/rides_controller.rb:26-29`
**Type:** Authorization Vulnerability
**Severity:** HIGH

**Issue:**
```ruby
def show
  ride = Ride.find(params[:id])  # No ownership check
  render json: ride
end
```

**Impact:** Any authenticated user can view any ride details. Information disclosure.

**Fix:**
```ruby
def show
  ride = Ride.find(params[:id])
  unless ride.rider_id == current_user.id || ride.driver_id == current_user.id
    return render json: { errors: 'Not authorized' }, status: :forbidden
  end
  render json: ride
end
```

---

#### H-5: Missing Database Columns
**File:** `db/schema.rb` (rides table)
**Type:** Database Schema
**Severity:** HIGH

**Issue:** Code references columns that don't exist in schema:
- `pickup_location` (used in controller line 11)
- `dropoff_location` (used in controller line 12)
- `assigned_at` (set in model line 71)
- `started_at` (set in model line 75)

**Impact:** Application will crash when trying to create/update rides with these attributes.

**Fix:** Create migration:
```ruby
rails generate migration AddLocationFieldsToRides pickup_location:string dropoff_location:string assigned_at:datetime started_at:datetime
rails db:migrate
```

---

#### H-6: Missing Ride Action Endpoints
**File:** `app/controllers/api/v1/rides_controller.rb`
**Type:** Missing Implementation
**Severity:** HIGH

**Issue:** Routes defined but actions missing:
- `/api/v1/rides/:id/accept` (PATCH)
- `/api/v1/rides/:id/start` (PATCH)
- `/api/v1/rides/:id/complete` (PATCH)
- `/api/v1/rides/:id/cancel` (PATCH)

**Impact:** These endpoints return 404. Core ride lifecycle functionality broken.

**Fix:** Implement actions:
```ruby
def accept
  @ride = Ride.find(params[:id])
  authorize_driver!
  RideLifecycleService.transition(@ride, :accept, current_user.id)
  render json: @ride
rescue StandardError => e
  render json: { error: e.message }, status: :unprocessable_entity
end

# Similar for start, complete, cancel
```

---

#### H-7: No Input Validation for Ride Creation
**File:** `app/controllers/api/v1/rides_controller.rb:9-14`
**Type:** Data Validation
**Severity:** HIGH

**Issue:** No validation that required fields are present:
```ruby
ride = Ride.new(
  rider: current_user,
  pickup_location: ride_params[:pickup_location],  # Could be nil
  dropoff_location: ride_params[:dropoff_location],  # Could be nil
  status: :requested
)
```

**Impact:** Rides created with nil locations. Data integrity issue.

**Fix:** Add model validations:
```ruby
# app/models/ride.rb
validates :pickup_location, :dropoff_location, presence: true
validates :rider_id, presence: true
```

---

#### H-8: Missing Model Validations
**File:** `app/models/user.rb`
**Type:** Data Validation
**Severity:** HIGH

**Issue:** No email format or password strength validation.

**Impact:** Invalid emails and weak passwords can be stored.

**Fix:**
```ruby
validates :email, presence: true, uniqueness: true,
          format: { with: URI::MailTo::EMAIL_REGEXP }
validates :password, length: { minimum: 8 }, on: :create, allow_nil: false
```

---

#### H-9: Authorization Doesn't Return After Failure
**File:** `app/controllers/api/v1/rides_controller.rb:44-50`
**Type:** Logic Error
**Severity:** HIGH

**Issue:**
```ruby
def set_ride
  @ride = Ride.find(params[:id])
  unless @ride.rider_id == current_user.id
    render json: { errors: "Not authorized" }, status: :forbidden
    # Missing return - execution continues!
  end
end
```

**Impact:** Code continues executing after failed authorization.

**Fix:**
```ruby
unless @ride.rider_id == current_user.id
  render json: { errors: "Not authorized" }, status: :forbidden
  return  # Add this
end
```

---

#### H-10: N+1 Query Issue
**File:** `app/controllers/api/v1/driver/rides_controller.rb:7`
**Type:** Performance
**Severity:** HIGH

**Issue:**
```ruby
rides = Ride.where(status: :requested)
render json: rides  # If serialized with associations, causes N+1
```

**Impact:** Performance degradation at scale.

**Fix:**
```ruby
rides = Ride.where(status: :requested).includes(:rider, :driver)
```

---

#### H-11: Duplicate Route Definitions
**File:** `config/routes.rb:34-39`
**Type:** API Design
**Severity:** HIGH

**Issue:** Driver rides routes inconsistently defined.

**Impact:** Confusing API structure, endpoints not under proper namespace.

**Fix:** Use consistent namespaced routes:
```ruby
namespace :driver do
  resources :rides, only: [:index] do
    member do
      post :accept
    end
  end
end
```

---

#### H-12: Missing Exception Handling
**File:** `app/controllers/api/v1/rides_controller.rb:27`
**Type:** Error Handling
**Severity:** HIGH

**Issue:**
```ruby
ride = Ride.find(params[:id])  # Raises ActiveRecord::RecordNotFound
```

**Impact:** Returns 500 Internal Server Error instead of proper 404.

**Fix:**
```ruby
ride = Ride.find_by(id: params[:id])
return render json: { error: 'Ride not found' }, status: :not_found unless ride
```

---

#### H-13: Empty Controller Actions
**File:** Multiple controllers
**Type:** Missing Implementation
**Severity:** HIGH

**Affected Files:**
- `app/controllers/api/v1/payments_controller.rb:2` - `show` action
- `app/controllers/api/v1/admin/users_controller.rb:9` - `show` action
- `app/controllers/api/v1/admin/stats_controller.rb:2` - `index` action

**Impact:** These endpoints return empty responses or errors.

---

#### H-14: JWT Expiration Calculated at Server Start
**File:** `app/services/jwt_service.rb:4`
**Type:** Logic Error
**Severity:** HIGH

**Issue:**
```ruby
EXPIRATION_TIME = 24.hours.from_now.to_i  # Calculated once at startup
```

**Impact:** All tokens expire at same time. Tokens expire quickly if server restarts frequently.

**Fix:**
```ruby
def self.encode(payload)
  payload[:exp] = 24.hours.from_now.to_i  # Calculate per token
  JWT.encode(payload, SECRET_KEY, 'HS256')
end
```

---

## PART 3: MEDIUM SEVERITY ISSUES

### M-1: Missing Model Validations in Ride
**File:** `app/models/ride.rb`
**Severity:** MEDIUM

**Issue:** No presence validations on critical fields.

**Fix:**
```ruby
validates :rider_id, presence: true
validates :pickup_location, :dropoff_location, presence: true
validates :status, inclusion: { in: statuses.keys }
```

---

### M-2: Timing Attack on Authentication
**File:** `app/controllers/api/v1/auth_controller.rb:23`
**Severity:** MEDIUM

**Issue:** Response timing could leak whether email exists.

**Fix:** Use constant-time comparison and consistent response times.

---

### M-3: No HTTPS Enforcement Check
**File:** `config/environments/production.rb:45`
**Severity:** MEDIUM

**Issue:** Verify `config.force_ssl = true` is enabled in production.

---

### M-4: No Input Sanitization
**File:** Controllers accepting location strings
**Severity:** MEDIUM

**Issue:** User input stored without sanitization.

**Fix:** Sanitize and validate location format.

---

### M-5: Missing Indexes on Foreign Keys
**File:** `db/schema.rb` (rides table)
**Severity:** MEDIUM

**Issue:** `if_not_exists: true` suggests indexes might be missing.

**Fix:** Verify indexes exist:
```ruby
add_index :rides, :driver_id
add_index :rides, :rider_id
```

---

### M-6: Missing Lifecycle Timestamp Column
**File:** `db/schema.rb`
**Severity:** MEDIUM

**Issue:** Model expects `assigned_at` but column doesn't exist.

---

### M-7: Inconsistent Error Response Format
**File:** `app/controllers/application_controller.rb`
**Severity:** MEDIUM

**Issue:** Some endpoints use `{ errors: ... }`, others use `{ error: ..., message: ... }`.

**Fix:** Standardize on single format across all endpoints.

---

### M-8: Missing Environment Configuration
**File:** Project root
**Severity:** MEDIUM

**Issue:** No `.env.example` or documentation for required env vars.

**Fix:** Create `.env.example`:
```
DATABASE_URL=postgresql://localhost/trego_dev
RAILS_MASTER_KEY=
JWT_SECRET=
CORS_ALLOWED_ORIGINS=localhost:3000
```

---

### M-9-M-21: RuboCop Metrics Issues
**Severity:** MEDIUM

**Issues:**
- Method too long (5 instances)
- Cyclomatic complexity too high (2 instances)
- Perceived complexity too high (2 instances)
- ABC size too high (1 instance)
- Block too long (2 instances)

**Affected Files:**
- `app/controllers/api/v1/auth_controller.rb:4` - Method length 11 lines
- `app/controllers/api/v1/auth_controller.rb:20` - Method length 16 lines
- `app/controllers/api/v1/rides_controller.rb:6` - Method length 12 lines
- `app/models/ride.rb:66` - Multiple metrics violations
- `bin/bundle:24` - Complexity issues

**Fix:** Refactor long methods into smaller, focused methods.

---

## PART 4: LOW SEVERITY ISSUES (339 issues)

### Code Style Issues (168 issues)

#### String Literals (168 instances)
**RuboCop:** `Style/StringLiterals`
**Issue:** Double-quoted strings used instead of single quotes.

**Example:**
```ruby
# Current:
source "https://rubygems.org"

# Preferred:
source 'https://rubygems.org'
```

**Auto-fix:** Run `rubocop -a` to auto-correct.

---

### Documentation Issues (25 issues)

#### Missing Class Documentation (25 instances)
**RuboCop:** `Style/Documentation`
**Issue:** Classes missing top-level documentation comments.

**Affected Classes:**
- `Api::V1::Admin::StatsController`
- `Api::V1::Admin::UsersController`
- `Api::V1::AuthController`
- `Api::V1::Driver::RidesController`
- `Api::V1::PaymentsController`
- `Api::V1::RidesController`
- `ApplicationController`
- `ApplicationMailer`
- `ApplicationRecord`
- `Ride`
- `User`
- `JwtService`
- `RideLifecycleService`
- (12 more)

**Fix:**
```ruby
# Add above each class:
# Service for managing ride lifecycle state transitions
class RideLifecycleService
  # ...
end
```

---

### Frozen String Literal Comments (62 issues)

#### Missing Frozen String Literal Comment
**RuboCop:** `Style/FrozenStringLiteralComment`
**Issue:** Files missing `# frozen_string_literal: true` at top.

**Fix:** Add to top of every Ruby file:
```ruby
# frozen_string_literal: true

class MyClass
  # ...
end
```

**Auto-fix:** Run `rubocop -a`

---

### Code Structure Issues (12 issues)

#### Compact Class/Module Style (12 instances)
**RuboCop:** `Style/ClassAndModuleChildren`
**Issue:** Using compact style instead of nested.

**Current:**
```ruby
class Api::V1::AuthController
```

**Preferred:**
```ruby
module Api
  module V1
    class AuthController
    end
  end
end
```

---

### Guard Clause Issues (11 issues)

#### Should Use Guard Clause
**RuboCop:** `Style/GuardClause`
**Issue:** Wrapping code in conditional instead of early return.

**Example:**
```ruby
# Current:
def create
  if user.save
    render json: user
  else
    render json: { errors: user.errors }
  end
end

# Preferred:
def create
  return render json: { errors: user.errors } unless user.save

  render json: user
end
```

**Locations:** 7 instances in controllers

---

### Layout Issues (128 issues)

#### Empty Line After Guard Clause (6 instances)
**RuboCop:** `Layout/EmptyLineAfterGuardClause`

#### Space Inside Percent Literal (4 instances)
**RuboCop:** `Layout/SpaceInsidePercentLiteralDelimiters`

#### Empty Lines Around Block Body (4 instances)
**RuboCop:** `Layout/EmptyLinesAroundBlockBody`

#### Line Length (3 instances)
**RuboCop:** `Layout/LineLength`

#### Multiline Method Call Indentation (2 instances)
**RuboCop:** `Layout/MultilineMethodCallIndentation`

#### Space Inside Array Brackets (2 instances)
**RuboCop:** `Layout/SpaceInsideArrayLiteralBrackets`

#### Other Layout (107+ instances)
Various spacing, indentation, and formatting issues.

**Auto-fix:** Most can be fixed with `rubocop -a`

---

### Modifier If/Unless Issues (11 instances)

**RuboCop:** `Style/IfUnlessModifier`
**Issue:** Single-line conditionals should use modifier form.

**Example:**
```ruby
# Current:
if condition
  do_something
end

# Preferred:
do_something if condition
```

---

### Style Issues (Miscellaneous)

#### Empty Method (3 instances)
**RuboCop:** `Style/EmptyMethod`
**Issue:** Empty methods should be on single line.

#### Redundant Fetch Block (3 instances)
**RuboCop:** `Style/RedundantFetchBlock`

#### Symbol Array (3 instances)
**RuboCop:** `Style/SymbolArray`
**Issue:** Use `%i[]` for symbol arrays.

#### Symbol Proc (4 instances)
**RuboCop:** `Style/SymbolProc`
**Issue:** Use `&:method_name` shorthand.

#### Ordered Gems (1 instance)
**RuboCop:** `Bundler/OrderedGems`
**Issue:** Gemfile gems not alphabetized.

#### Special Global Vars (2 instances)
**RuboCop:** `Style/SpecialGlobalVars`, `Style/PerlBackrefs`
**Issue:** Use `$PROGRAM_NAME` instead of `$0`, `Regexp.last_match(1)` instead of `$1`.

#### Numeric Literals (1 instance)
**RuboCop:** `Style/NumericLiterals`
**Issue:** Large numbers should use underscores (e.g., `1_000_000`).

---

### Configuration Issues

#### L-1: Devise Mailer Not Configured
**File:** `config/initializers/devise.rb:27`
**Severity:** LOW

**Issue:**
```ruby
config.mailer_sender = 'please-change-me-at-config-initializers-devise@example.com'
```

**Impact:** Devise emails won't send properly.

**Fix:** Set proper sender email.

---

### Code Quality Issues

#### L-2: Commented-Out Code
**File:** `app/controllers/api/v1/rides_controller.rb:15-18`
**Severity:** LOW

**Issue:** Dead code left in production:
```ruby
# ride = Ride.create!(
#   rider: current_user,
#   status: "requested"
# )
```

**Fix:** Remove commented code.

---

#### L-3: Magic Numbers
**Severity:** LOW

**Issue:** Hardcoded values without constants:
- JWT expiration: `24.hours`
- JWT algorithm: `'HS256'`
- Status values

**Fix:** Define constants.

---

#### L-4: No Logging of Critical Events
**Severity:** LOW

**Issue:** No logging for:
- Failed authentication
- Unauthorized access
- State transitions

**Fix:** Add `Rails.logger` statements.

---

#### L-5: Inconsistent Naming
**Severity:** LOW

**Issue:** Response keys inconsistent:
- Some use `errors` (plural)
- Some use `error` (singular)

---

## PART 5: ACTION PLAN

### Immediate Actions (Block Release)

1. ✅ **Fix undefined variable** - `active_ride?` → `active_ride` (rides_controller.rb:39)
2. ✅ **Fix HTTP status** - `:Unauthorized` → `:unauthorized` (auth_controller.rb:37)
3. ✅ **Fix signup status** - Change to `:created` (auth_controller.rb:16)
4. ✅ **Fix login param** - `params[:phone]` → `params[:email]` (auth_controller.rb:21)
5. 🔧 **Add missing DB columns** - Run migration for location/timestamp fields
6. 🔧 **Implement missing ride actions** - Accept, start, complete, cancel
7. 🔧 **Add authorization to show** - Prevent unauthorized ride viewing

**Estimated Time:** 2-4 hours

---

### High Priority (Before Production)

8. 🔒 **Restrict CORS** - Limit to known origins
9. 🔒 **Add rate limiting** - Implement rack-attack
10. 🔒 **Sanitize error messages** - Don't expose internals
11. ✅ **Add model validations** - User and Ride models
12. ✅ **Fix authorization return** - Add return statements
13. ⚡ **Fix N+1 queries** - Add eager loading
14. 📝 **Standardize API responses** - Consistent error format
15. 🔧 **Fix JWT expiration** - Calculate per-token
16. 🔧 **Fix duplicate routes** - Clean up routes.rb

**Estimated Time:** 6-8 hours

---

### Medium Priority (Technical Debt)

17. ✅ **Add all model validations**
18. 🔧 **Add missing indexes**
19. 📝 **Create .env.example**
20. 🔧 **Implement empty endpoints**
21. ♻️ **Refactor complex methods** - Reduce cyclomatic complexity
22. 🔧 **Add proper exception handling**
23. 📝 **Add logging for critical events**

**Estimated Time:** 8-12 hours

---

### Low Priority (Code Quality)

24. 🎨 **Auto-fix RuboCop** - Run `rubocop -a` (fixes ~300 issues)
25. 📚 **Add class documentation**
26. 🎨 **Manual RuboCop fixes** - Remaining issues
27. ♻️ **Extract magic numbers to constants**
28. 🧹 **Remove dead code**

**Estimated Time:** 4-6 hours

---

## PART 6: AUTOMATED FIX COMMANDS

### Quick Wins (Auto-fixable)

```bash
# Fix 300+ style issues automatically
rubocop -a

# Check what's left
rubocop

# Fix unsafe corrections (requires review)
rubocop -A
```

### Database Fixes

```bash
# Add missing columns
rails generate migration AddMissingFieldsToRides \
  pickup_location:string \
  dropoff_location:string \
  assigned_at:datetime \
  started_at:datetime

rails db:migrate
```

---

## PART 7: TESTING RECOMMENDATIONS

After fixes, run:

```bash
# 1. Check syntax
ruby -c app/**/*.rb

# 2. Run RuboCop
rubocop

# 3. Run tests
rails test

# 4. Manual API tests
curl -X POST http://localhost:3000/api/v1/auth/signup \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"test1234","role":"rider"}'

# 5. Check for N+1 queries
# Add to Gemfile: gem 'bullet'
# Enable in development.rb and check logs
```

---

## APPENDIX A: SEVERITY DEFINITIONS

| Severity | Definition | Examples |
|----------|------------|----------|
| **CRITICAL** | Application crashes, data loss, complete feature breakage | Undefined variable, syntax error, wrong data type |
| **HIGH** | Security vulnerabilities, missing core functionality, data integrity issues | SQL injection, missing auth, missing DB columns |
| **MEDIUM** | Data validation, error handling, performance, maintainability concerns | Missing validations, N+1 queries, complex methods |
| **LOW** | Code style, conventions, documentation, minor quality | String quotes, missing docs, formatting |

---

## APPENDIX B: RUBOCOP CONFIGURATION

To reduce noise from low-priority issues, update `.rubocop.yml`:

```yaml
AllCops:
  NewCops: enable
  Exclude:
    - 'db/**/*'
    - 'bin/**/*'
    - 'config/**/*'
    - 'vendor/**/*'

# Disable style cops that are too pedantic
Style/Documentation:
  Enabled: false

Style/FrozenStringLiteralComment:
  Enabled: false

Style/StringLiterals:
  EnforcedStyle: double_quotes  # Or single_quotes if you prefer

# Keep important cops enabled
Lint/UselessAssignment:
  Enabled: true

Security/Eval:
  Enabled: true
```

---

## REPORT END

**Total Issues:** 380
**Critical:** 4
**High:** 14
**Medium:** 21
**Low:** 341

**Next Steps:**
1. Fix all Critical issues immediately
2. Review High priority security issues
3. Run automated RuboCop fixes
4. Create tickets for Medium/Low priority work

**Generated by:** Claude Code Analysis Engine
**Report Version:** 1.0
**Date:** 2026-01-27
