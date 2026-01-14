erDiagram

    CITIES ||--o{ USERS : has
    CITIES ||--o{ RIDES : has

    USERS ||--o{ VEHICLES : owns
    USERS ||--o{ RIDES : "requests (rider)"
    USERS ||--o{ RIDES : "drives (driver)"

    VEHICLES ||--o{ RIDES : used_for
    RIDES ||--|| PAYMENTS : generates

    CITIES {
        bigint id PK
        string name
        boolean active
        datetime created_at
        datetime updated_at
    }

    USERS {
        bigint id PK
        string email
        string phone
        string password_digest
        enum role
        enum status
        bigint city_id FK
        datetime created_at
        datetime updated_at
    }

    VEHICLES {
        bigint id PK
        bigint driver_id FK
        string make
        string model
        int year
        string plate_number
        boolean active
        datetime created_at
        datetime updated_at
    }

    RIDES {
        bigint id PK
        bigint rider_id FK
        bigint driver_id FK
        bigint vehicle_id FK
        bigint city_id FK
        enum status
        decimal pickup_lat
        decimal pickup_lng
        decimal dropoff_lat
        decimal dropoff_lng
        decimal base_fare
        decimal per_km_rate
        decimal per_min_rate
        decimal distance_km
        decimal duration_min
        decimal total_fare
        datetime created_at
        datetime updated_at
    }

    PAYMENTS {
        bigint id PK
        bigint ride_id FK
        decimal amount
        enum status
        enum payment_method
        string external_reference
        datetime created_at
        datetime updated_at
    }

City
 └── has many Users
 └── has many Rides

User
 ├── has many Vehicles (if role = driver)
 ├── has many Rides (as rider)
 ├── has many Rides (as driver)
 └── has many Payments (indirect via rides)

Vehicle
 └── belongs to Driver (User)
 └── has many Rides

Ride
 ├── belongs to Rider (User)
 ├── belongs to Driver (User)
 ├── belongs to Vehicle
 ├── belongs to City
 └── has one Payment

Payment
 └── belongs to Ride


Table-by-Table Breakdown (FINAL)
1️⃣ cities
cities
- id (PK)
- name (string)
- active (boolean, default: true)
- created_at
- updated_at

Notes
* Phase 1: only one row → “Montreal”
* Future-proof without complexity

2️⃣ users
users
- id (PK)
- email (string, unique, indexed)
- phone (string, unique)
- password_digest (string)
- role (enum: rider, driver, admin)
- status (enum: active, suspended)
- city_id (FK → cities.id)
- created_at
- updated_at

Key Rules
* ONE table for all personas
* Role-based access enforced in backend
* Users belong to one city (for now)

3️⃣ vehicles
vehicles
- id (PK)
- driver_id (FK → users.id)
- make (string)
- model (string)
- year (integer)
- plate_number (string, unique)
- active (boolean, default: true)
- created_at
- updated_at

Rules
* Only users with role = driver can own vehicles
* A driver can have multiple vehicles (Subjected to change)
* Only one active vehicle per ride

4️⃣ rides (MOST IMPORTANT TABLE)
rides
- id (PK)
- rider_id (FK → users.id)
- driver_id (FK → users.id)
- vehicle_id (FK → vehicles.id)
- city_id (FK → cities.id)
- status (enum:
  requested,
  assigned,
  accepted,
  started,
  completed,
  cancelled
)
-- Locations (embedded, not separate table)
- pickup_lat (decimal)
- pickup_lng (decimal)
- dropoff_lat (decimal)
- dropoff_lng (decimal)
-- Pricing snapshot (important!)
- base_fare (decimal)
- per_km_rate (decimal)
- per_min_rate (decimal)
- distance_km (decimal)
- duration_min (decimal)
- total_fare (decimal)
- created_at
- updated_at

Why pricing is stored on ride
* Protects against pricing changes
* Enables audits
* Enables dispute resolution
* Ensures deterministic history

5️⃣ payments
payments
- id (PK)
- ride_id (FK → rides.id)
- amount (decimal)
- status (enum: pending, paid, failed)
- payment_method (enum: card, cash)
- external_reference (string, nullable)
- created_at
- updated_at

Notes
* One payment per ride (Phase 1)
* No wallet logic
* No refunds yet

Cardinality Summary
Relationship	Type
City → Users	1 to many
City → Rides	1 to many
User (Driver) → Vehicles	1 to many
User (Rider) → Rides	1 to many
User (Driver) → Rides	1 to many
Vehicle → Rides	1 to many
Ride → Payment	1 to 1
