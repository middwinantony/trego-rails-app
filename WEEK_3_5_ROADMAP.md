
# Week 3-5 Roadmap: Advanced Features
**Status:** Foundation Complete ✅ - Ready to Build Advanced Features
**Date:** February 2, 2026

---

## 📋 Assessment of Your Advanced Features List

### ✅ Ready to Start NOW (Foundation Complete)
You can begin implementing ALL of these features immediately because:
- ✅ Core domain models are solid
- ✅ State machine is working correctly
- ✅ Authorization is secure
- ✅ Database schema is complete
- ✅ Service layer exists (RideLifecycleService)

---

## 🎯 Recommended Implementation Order

### **WEEK 3: Stability & Edge Cases First**

#### Priority 1: Edge Case Handling (1-2 days)
**Why First:** Completes core business logic before adding complexity

**Status:** ⚠️ Partially Complete
- ✅ State transitions enforced
- ✅ Ownership checks working
- ❌ Cancellation endpoints missing
- ❌ Timeout logic missing
- ❌ Admin force-cancel missing

**Implementation:**
```ruby
# Add to rides_controller.rb
def cancel
  RideLifecycleService.new(@ride, current_user).cancel!
  render json: { message: "Ride cancelled" }
rescue StandardError => e
  render json: { error: e.message }, status: :unprocessable_entity
end

# Add to driver/rides_controller.rb
def cancel
  RideLifecycleService.new(@ride, current_user).driver_cancel!
  render json: { message: "Ride cancelled by driver" }
rescue StandardError => e
  render json: { error: e.message }, status: :unprocessable_entity
end

# Add to admin/rides_controller.rb
def force_cancel
  ride = Ride.find(params[:id])
  RideLifecycleService.new(ride, current_user).admin_cancel!
  render json: { message: "Ride force-cancelled by admin" }
end

# Add to ride_lifecycle_service.rb
def driver_cancel!
  ensure_driver!
  ensure_driver_owns_ride!

  @ride.with_lock do
    ensure_state_in!(%i[assigned accepted started])
    @ride.update!(status: :cancelled, cancelled_by: 'driver')
  end
end

def admin_cancel!
  raise StandardError, "Admin only action" unless @actor.admin?

  @ride.with_lock do
    @ride.update!(status: :cancelled, cancelled_by: 'admin')
  end
end

# Timeout job (run every 5 minutes)
class RideTimeoutJob < ApplicationJob
  queue_as :default

  def perform
    Ride.where(status: :requested)
        .where('created_at < ?', 10.minutes.ago)
        .find_each do |ride|
      ride.update!(status: :cancelled, cancelled_by: 'timeout')
    end
  end
end
```

**Tasks:**
- [ ] Add cancellation methods to RideLifecycleService
- [ ] Add rider cancel endpoint (PATCH /rides/:id/cancel)
- [ ] Add driver cancel endpoint (POST /driver/rides/:id/cancel)
- [ ] Add admin force-cancel endpoint (POST /admin/rides/:id/force_cancel)
- [ ] Add `cancelled_by` string column to rides (migration)
- [ ] Implement RideTimeoutJob
- [ ] Add Sidekiq scheduler for timeout job

**Estimated Time:** 4-6 hours

---

#### Priority 2: Security Hardening (1 day)
**Why Second:** Protect your API before adding async complexity

**Status:** ❌ Not Started

**Implementation:**

**A. Rate Limiting (rack-attack)**
```ruby
# Gemfile
gem 'rack-attack'

# config/initializers/rack_attack.rb
class Rack::Attack
  # Throttle login attempts
  throttle('auth/login', limit: 5, period: 60.seconds) do |req|
    req.ip if req.path == '/api/v1/auth/login' && req.post?
  end

  # Throttle signup
  throttle('auth/signup', limit: 3, period: 60.seconds) do |req|
    req.ip if req.path == '/api/v1/auth/signup' && req.post?
  end

  # Throttle ride creation
  throttle('rides/create', limit: 10, period: 60.seconds) do |req|
    if req.path == '/api/v1/rides' && req.post?
      req.env['current_user']&.id
    end
  end

  # Throttle driver accept
  throttle('driver/accept', limit: 20, period: 60.seconds) do |req|
    if req.path.match?(/\/api\/v1\/rides\/\d+\/accept/) && req.post?
      req.env['current_user']&.id
    end
  end

  # Custom response
  self.throttled_responder = lambda do |env|
    [429, {'Content-Type' => 'application/json'}, [{
      error: 'Rate limit exceeded',
      message: 'Too many requests. Please try again later.'
    }.to_json]]
  end
end

# config/application.rb
config.middleware.use Rack::Attack
```

**B. JWT Improvements**
```ruby
# app/services/jwt_service.rb
class JwtService
  SECRET_KEY = Rails.application.credentials.secret_key_base

  def self.encode(payload, exp = 1.hour.from_now) # Shorter expiration
    payload[:exp] = exp.to_i
    payload[:jti] = SecureRandom.uuid # Add unique token ID
    JWT.encode(payload, SECRET_KEY)
  end

  def self.decode(token)
    decoded = JWT.decode(token, SECRET_KEY)[0]
    HashWithIndifferentAccess.new(decoded)
  rescue JWT::DecodeError, JWT::ExpiredSignature
    nil
  end

  # Check if token is blacklisted
  def self.blacklisted?(jti)
    Rails.cache.read("blacklist:#{jti}").present?
  end

  # Blacklist token on logout
  def self.blacklist!(jti, exp)
    ttl = exp - Time.current.to_i
    Rails.cache.write("blacklist:#{jti}", true, expires_in: ttl.seconds)
  end
end

# app/controllers/api/v1/auth_controller.rb
def logout
  payload = JwtService.decode(bearer_token)
  if payload && payload[:jti]
    JwtService.blacklist!(payload[:jti], payload[:exp])
    render json: { message: "Logged out successfully" }
  else
    render json: { error: "Invalid token" }, status: :unauthorized
  end
end

# Update authenticate_request
def authenticate_request
  token = bearer_token
  payload = JwtService.decode(token)

  if payload.nil? || JwtService.blacklisted?(payload[:jti])
    render_unauthorized("Invalid or expired token") and return
  end

  @current_user = User.find_by(id: payload[:user_id])
  # ...
end
```

**C. Abuse Prevention**
```ruby
# Add to rides_controller.rb - prevent duplicate requests
def prevent_multiple_active_rides!
  # Check both DB and recent cancellations
  active_ride = Ride.where(
    rider_id: current_user.id,
    status: [:requested, :assigned, :accepted, :started]
  ).exists?

  recent_cancelled = Ride.where(
    rider_id: current_user.id,
    status: :cancelled
  ).where('cancelled_at > ?', 2.minutes.ago).exists?

  if active_ride
    render json: { errors: "You already have an active ride" }, status: :unprocessable_entity
    return
  end

  if recent_cancelled
    render json: { errors: "Please wait before requesting a new ride" }, status: :too_many_requests
    return
  end
end

# Add to driver/rides_controller.rb - prevent accept spamming
def prevent_driver_accept_spam
  recent_accepts = Ride.where(
    driver_id: current_user.id,
    status: [:assigned, :accepted]
  ).where('assigned_at > ?', 10.seconds.ago).count

  if recent_accepts >= 3
    render json: { errors: "Too many accepts. Please wait." }, status: :too_many_requests
    return
  end
end
```

**Tasks:**
- [ ] Install rack-attack gem
- [ ] Configure rate limiting rules
- [ ] Update JwtService with jti and blacklisting
- [ ] Add logout endpoint (POST /auth/logout)
- [ ] Add duplicate ride prevention
- [ ] Add driver accept spam prevention
- [ ] Test rate limiting with curl/Postman

**Estimated Time:** 6-8 hours

---

### **WEEK 4: Background Jobs & Redis**

#### Priority 3: Background Jobs (1-2 days)
**Why Third:** Now that business logic is complete, add async processing

**Status:** ❌ Not Started (but RideLifecycleService is ready)

**Prerequisites:**
- ✅ RideLifecycleService exists (can trigger jobs)
- ✅ State transitions working
- ❌ Need Redis installed
- ❌ Need Sidekiq configured

**Implementation:**

**A. Setup Sidekiq + Redis**
```ruby
# Gemfile
gem 'sidekiq'
gem 'redis'

# config/application.rb
config.active_job.queue_adapter = :sidekiq

# config/initializers/sidekiq.rb
Sidekiq.configure_server do |config|
  config.redis = { url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/0') }
end

Sidekiq.configure_client do |config|
  config.redis = { url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/0') }
end

# config/routes.rb
require 'sidekiq/web'
mount Sidekiq::Web => '/sidekiq' # Protect this in production!
```

**B. Notification Jobs**
```ruby
# app/jobs/ride_status_notification_job.rb
class RideStatusNotificationJob < ApplicationJob
  queue_as :default

  def perform(ride_id, event)
    ride = Ride.find(ride_id)

    case event
    when 'assigned'
      notify_rider(ride, "Driver #{ride.driver.first_name} is on the way!")
      notify_driver(ride, "You accepted ride ##{ride.id}")
    when 'started'
      notify_rider(ride, "Your ride has started")
    when 'completed'
      notify_rider(ride, "Ride completed. Thanks for using Trego!")
      notify_driver(ride, "Ride completed")
    when 'cancelled'
      notify_rider(ride, "Your ride was cancelled")
      notify_driver(ride, "Ride was cancelled") if ride.driver
    end
  end

  private

  def notify_rider(ride, message)
    # TODO: Send SMS/push notification
    Rails.logger.info "[NOTIFICATION] Rider #{ride.rider_id}: #{message}"
  end

  def notify_driver(ride, message)
    # TODO: Send SMS/push notification
    Rails.logger.info "[NOTIFICATION] Driver #{ride.driver_id}: #{message}"
  end
end

# app/jobs/ride_completion_job.rb
class RideCompletionJob < ApplicationJob
  queue_as :default

  def perform(ride_id)
    ride = Ride.find(ride_id)

    # Calculate fare
    # Create payment record
    # Update driver stats
    # Update rider stats
    # Send receipt

    Rails.logger.info "[COMPLETION] Processing ride ##{ride_id}"

    # TODO: Implement payment calculation
    # Payment.create!(
    #   ride: ride,
    #   amount: calculate_fare(ride),
    #   status: :pending
    # )
  end

  private

  def calculate_fare(ride)
    # TODO: Implement fare calculation
    # base_fare + (distance * rate) + (time * rate)
    100.0 # Placeholder
  end
end
```

**C. Trigger Jobs from Service**
```ruby
# Update app/services/ride_lifecycle_service.rb
def accept!
  ensure_driver!

  @ride.with_lock do
    ensure_state!(:requested)

    @ride.update!(
      driver: @actor,
      status: :assigned
    )
  end

  # Trigger notification job
  RideStatusNotificationJob.perform_later(@ride.id, 'assigned')

  @ride
end

def start!
  ensure_driver!
  ensure_driver_owns_ride!

  @ride.with_lock do
    ensure_state!(:assigned)
    @ride.update!(status: :started)
  end

  RideStatusNotificationJob.perform_later(@ride.id, 'started')
end

def complete!
  ensure_driver!
  ensure_driver_owns_ride!

  @ride.with_lock do
    ensure_state!(:started)
    @ride.update!(status: :completed)
  end

  # Trigger both notification and completion jobs
  RideStatusNotificationJob.perform_later(@ride.id, 'completed')
  RideCompletionJob.perform_later(@ride.id)
end

def cancel!
  ensure_rider!

  @ride.with_lock do
    ensure_state_in!(%i[requested assigned])
    @ride.update!(status: :cancelled, cancelled_by: 'rider')
  end

  RideStatusNotificationJob.perform_later(@ride.id, 'cancelled')

  @ride
end
```

**Tasks:**
- [ ] Install Redis locally (`brew install redis`)
- [ ] Add sidekiq and redis gems
- [ ] Configure Sidekiq
- [ ] Create RideStatusNotificationJob
- [ ] Create RideCompletionJob
- [ ] Create RideTimeoutJob
- [ ] Update RideLifecycleService to trigger jobs
- [ ] Add Sidekiq scheduler gem for periodic jobs
- [ ] Test jobs with `rails console` and `Sidekiq` dashboard

**Estimated Time:** 8-10 hours

---

#### Priority 4: Redis Integration (1-2 days)
**Why Fourth:** Optimize after core async is working

**Status:** ❌ Not Started

**Use Cases:**
1. Cache active rides per driver
2. Cache driver availability per city
3. Fast ride lookups

**Implementation:**

**A. Redis Service**
```ruby
# app/services/redis_service.rb
class RedisService
  def self.redis
    @redis ||= Redis.new(url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/1'))
  end

  # Active rides per driver
  def self.cache_active_ride(driver_id, ride_id)
    redis.setex("driver:#{driver_id}:active_ride", 1.hour, ride_id)
  end

  def self.get_active_ride(driver_id)
    ride_id = redis.get("driver:#{driver_id}:active_ride")
    ride_id ? Ride.find(ride_id) : nil
  rescue ActiveRecord::RecordNotFound
    redis.del("driver:#{driver_id}:active_ride")
    nil
  end

  def self.clear_active_ride(driver_id)
    redis.del("driver:#{driver_id}:active_ride")
  end

  # Driver availability per city
  def self.add_available_driver(city_id, driver_id)
    redis.sadd("city:#{city_id}:available_drivers", driver_id)
  end

  def self.remove_available_driver(city_id, driver_id)
    redis.srem("city:#{city_id}:available_drivers", driver_id)
  end

  def self.available_drivers(city_id)
    driver_ids = redis.smembers("city:#{city_id}:available_drivers")
    User.where(id: driver_ids, role: :driver, status: :active)
  end

  # Ride cache
  def self.cache_ride(ride)
    redis.setex("ride:#{ride.id}", 30.minutes, ride.to_json)
  end

  def self.get_ride(ride_id)
    cached = redis.get("ride:#{ride_id}")
    cached ? Ride.new(JSON.parse(cached)) : Ride.find(ride_id)
  rescue => e
    # Fallback to DB on Redis failure
    Rails.logger.warn "[REDIS] Failed to get ride #{ride_id}: #{e.message}"
    Ride.find(ride_id)
  end
end
```

**B. Update Service to Use Redis**
```ruby
# Update ride_lifecycle_service.rb
def accept!
  ensure_driver!

  @ride.with_lock do
    ensure_state!(:requested)

    # Check if driver already has active ride (Redis first, DB fallback)
    existing_ride = RedisService.get_active_ride(@actor.id)
    raise StandardError, "You already have an active ride" if existing_ride

    @ride.update!(driver: @actor, status: :assigned)
  end

  # Update Redis
  RedisService.cache_active_ride(@actor.id, @ride.id)
  RedisService.remove_available_driver(@ride.city_id, @actor.id) if @ride.city_id

  RideStatusNotificationJob.perform_later(@ride.id, 'assigned')

  @ride
end

def complete!
  ensure_driver!
  ensure_driver_owns_ride!

  @ride.with_lock do
    ensure_state!(:started)
    @ride.update!(status: :completed)
  end

  # Clear Redis
  RedisService.clear_active_ride(@actor.id)
  RedisService.add_available_driver(@ride.city_id, @actor.id) if @ride.city_id

  RideStatusNotificationJob.perform_later(@ride.id, 'completed')
  RideCompletionJob.perform_later(@ride.id)
end

def cancel!
  # ... existing code ...

  # Clear Redis if driver was assigned
  if @ride.driver_id
    RedisService.clear_active_ride(@ride.driver_id)
    RedisService.add_available_driver(@ride.city_id, @ride.driver_id) if @ride.city_id
  end

  RideStatusNotificationJob.perform_later(@ride.id, 'cancelled')

  @ride
end
```

**C. Update Controllers**
```ruby
# driver/rides_controller.rb
def index
  # Use Redis cache for available drivers
  if params[:city_id]
    available_drivers = RedisService.available_drivers(params[:city_id])
    driver_ids = available_drivers.pluck(:id)
    rides = Ride.where(status: :requested, city_id: params[:city_id])
  else
    rides = Ride.where(status: :requested)
  end

  render json: rides
end
```

**Redis Failure Strategy:**
```ruby
# Graceful degradation
def self.get_active_ride(driver_id)
  ride_id = redis.get("driver:#{driver_id}:active_ride")
  ride_id ? Ride.find(ride_id) : nil
rescue Redis::BaseError => e
  # Fallback to DB on Redis failure
  Rails.logger.warn "[REDIS] Failed, using DB: #{e.message}"
  Ride.where(driver_id: driver_id, status: [:assigned, :accepted, :started]).first
rescue ActiveRecord::RecordNotFound
  redis.del("driver:#{driver_id}:active_ride")
  nil
end
```

**Tasks:**
- [ ] Create RedisService
- [ ] Update RideLifecycleService to use Redis
- [ ] Add Redis caching for active rides
- [ ] Add Redis sets for available drivers
- [ ] Implement graceful Redis failure handling
- [ ] Add Redis cleanup on cancellation
- [ ] Test Redis with `redis-cli`
- [ ] Document Redis key naming conventions

**Estimated Time:** 8-12 hours

---

### **WEEK 5: Documentation & Polish**

#### Priority 5: API Documentation (1 day)
**Why Fifth:** Document once everything is working

**Status:** ❌ Not Started

**Tasks:**
- [ ] Create Postman collection (Auth, Rider, Driver, Admin)
- [ ] Export collection with examples
- [ ] Configure Postman environments
- [ ] Write comprehensive README
- [ ] Add API endpoint documentation
- [ ] Create setup guide
- [ ] Document environment variables

**Estimated Time:** 6-8 hours

---

#### Priority 6: Refactoring (1-2 days)
**Why Sixth:** Improve code quality after features are stable

**Status:** ⚠️ Partially Started
- ✅ RideLifecycleService exists
- ❌ Pundit not implemented
- ❌ Some controller logic could move to services

**Refactoring Opportunities:**

**A. Extract Payment Service**
```ruby
# app/services/payment_service.rb
class PaymentService
  def initialize(ride)
    @ride = ride
  end

  def calculate_fare
    # Fare calculation logic
  end

  def create_payment
    # Payment creation
  end

  def process_refund
    # Refund logic
  end
end
```

**B. Add Pundit for Authorization**
```ruby
# Gemfile
gem 'pundit'

# app/policies/ride_policy.rb
class RidePolicy < ApplicationPolicy
  def show?
    user.admin? || record.rider_id == user.id || record.driver_id == user.id
  end

  def cancel?
    user.rider? && record.rider_id == user.id && record.can_cancel?
  end
end

# Controllers
def show
  @ride = Ride.find(params[:id])
  authorize @ride
  render json: RideSerializer.new(@ride, current_user).as_json
end
```

**Tasks:**
- [ ] Install Pundit
- [ ] Create policy objects (RidePolicy, UserPolicy)
- [ ] Refactor controllers to use policies
- [ ] Extract payment logic to PaymentService
- [ ] Add meaningful comments to complex logic
- [ ] Run Rubocop for style consistency

**Estimated Time:** 8-10 hours

---

#### Priority 7: Final Validation (1 day)
**Why Last:** Final checks before calling it complete

**Tasks:**
- [ ] Run full Postman workflow
- [ ] Create seed data script
- [ ] Test all edge cases manually
- [ ] Write demo script
- [ ] Security audit
- [ ] Performance testing (Redis vs DB)
- [ ] Documentation review

**Estimated Time:** 6-8 hours

---

## 📊 Detailed Status Assessment

### 1️⃣ Background Jobs & Async Architecture
**Status:** ❌ Not Started (0%)
**Blockers:** Need Redis + Sidekiq installed
**Dependencies:** None (foundation complete)
**Effort:** 8-10 hours

**What You Have:**
- ✅ RideLifecycleService (perfect place to trigger jobs)
- ✅ State transitions working
- ✅ Clear event points (accept, start, complete, cancel)

**What You Need:**
- ❌ Redis installation
- ❌ Sidekiq configuration
- ❌ Job classes
- ❌ Job triggers in service

---

### 2️⃣ Redis Integration & Performance Layer
**Status:** ❌ Not Started (0%)
**Blockers:** Need Redis installed
**Dependencies:** Should do Background Jobs first
**Effort:** 8-12 hours

**What You Have:**
- ✅ Clear use cases defined
- ✅ Service layer to integrate Redis

**What You Need:**
- ❌ Redis gem and service
- ❌ RedisService class
- ❌ Cache invalidation logic
- ❌ Graceful failure handling

---

### 3️⃣ Security Hardening & Abuse Protection
**Status:** ⚠️ Partially Complete (40%)
**Blockers:** None
**Dependencies:** Can start immediately
**Effort:** 6-8 hours

**What You Have:**
- ✅ JWT authentication working
- ✅ Basic authorization working
- ✅ Some abuse prevention (prevent_multiple_active_rides)

**What You Need:**
- ❌ rack-attack gem
- ❌ Rate limiting configuration
- ❌ JWT refresh strategy
- ❌ Token blacklisting
- ❌ Logout endpoint
- ❌ Driver accept spam prevention

---

### 4️⃣ Real-World Edge Case Handling
**Status:** ⚠️ Partially Complete (50%)
**Blockers:** None
**Dependencies:** Can start immediately
**Effort:** 4-6 hours

**What You Have:**
- ✅ State machine working
- ✅ Rider cancellation logic (in service)
- ✅ State validation

**What You Need:**
- ❌ Rider cancel endpoint
- ❌ Driver cancel logic and endpoint
- ❌ Timeout job
- ❌ Admin force-cancel endpoint
- ❌ `cancelled_by` column migration
- ❌ Redis cleanup on cancel

---

### 5️⃣ API Documentation & Developer Experience
**Status:** ❌ Not Started (0%)
**Blockers:** None (but better after features are done)
**Dependencies:** None
**Effort:** 6-8 hours

**What You Have:**
- ✅ All endpoints working
- ✅ Clear API structure

**What You Need:**
- ❌ Postman collections
- ❌ Environment configurations
- ❌ README with examples
- ❌ Setup instructions

---

### 6️⃣ Refactoring & Architecture Cleanup
**Status:** ⚠️ Partially Complete (40%)
**Blockers:** None
**Dependencies:** Better done after features are complete
**Effort:** 8-10 hours

**What You Have:**
- ✅ RideLifecycleService (good service pattern)
- ✅ Serializers
- ✅ Relatively clean controllers

**What You Need:**
- ❌ Pundit for policies
- ❌ More service extraction
- ❌ Better comments
- ❌ Rubocop compliance

---

### 7️⃣ Final Validation & Demo Readiness
**Status:** ❌ Not Started (0%)
**Blockers:** Should be done last
**Dependencies:** All features complete
**Effort:** 6-8 hours

**What You Need:**
- ❌ Comprehensive testing
- ❌ Seed data
- ❌ Demo script
- ❌ Performance testing

---

## 🎯 My Recommendation: 3-Week Plan

### **Week 3 (This Week): Stability & Security**
**Goal:** Complete core features and secure the API

**Days 1-2:** Edge Case Handling
- Implement all cancellation scenarios
- Add timeout job
- Add admin force-cancel

**Days 3-4:** Security Hardening
- Install rack-attack
- Configure rate limiting
- Implement JWT refresh/blacklisting
- Add logout endpoint

**Day 5:** Testing & Validation
- Test all edge cases
- Verify rate limiting works
- Security audit

**Deliverable:** Stable, secure API with complete ride lifecycle

---

### **Week 4: Async & Performance**
**Goal:** Add background jobs and Redis caching

**Days 1-2:** Background Jobs
- Install Redis + Sidekiq
- Create notification jobs
- Create completion job
- Create timeout job
- Integrate with RideLifecycleService

**Days 3-4:** Redis Integration
- Create RedisService
- Implement active ride caching
- Implement driver availability caching
- Add graceful failure handling

**Day 5:** Performance Testing
- Load test with/without Redis
- Verify job processing
- Monitor Sidekiq dashboard

**Deliverable:** Async architecture with Redis optimization

---

### **Week 5: Polish & Documentation**
**Goal:** Production-ready with great DX

**Days 1-2:** API Documentation
- Create Postman collections
- Write comprehensive README
- Document all endpoints
- Create setup guide

**Days 2-3:** Refactoring
- Add Pundit policies
- Extract remaining services
- Add code comments
- Run Rubocop

**Days 4-5:** Final Validation
- Full Postman walkthrough
- Create realistic seed data
- Write demo script
- Final security review

**Deliverable:** Production-ready, well-documented API

---

## ✅ What to Start RIGHT NOW

I recommend starting with **Priority 1: Edge Case Handling** because:
1. ✅ No new dependencies needed
2. ✅ Completes your core business logic
3. ✅ Foundation is solid
4. ✅ Relatively quick (4-6 hours)
5. ✅ Unblocks everything else

Future implementations:
1. **Implement Edge Case Handling** (cancellations, timeouts, force-cancel)
2. **Set up Security Hardening** (rack-attack, rate limiting, JWT improvements)
3. **Configure Background Jobs** (Redis + Sidekiq setup)
4. **Create API Documentation** (Postman collections, README)
