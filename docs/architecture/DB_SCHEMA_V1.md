1️⃣ cities
Purpose
* Defines allowed operating cities. Phase 1 supports Montreal only.

Table: cities
Column	             Type	          Constraints	      Default	       Notes
id	                bigint	             PK	           auto
name	           varchar(100)	    NOT NULL, UNIQUE		           e.g. "Montreal"
active	           boolean	          NOT NULL	       true	      Feature toggle
created_at	      timestamp	          NOT NULL	       now()
updated_at	      timestamp	          NOT NULL	       now()

Indexes
* index_cities_on_name



2️⃣ users
Purpose
* Single table for riders, drivers, admins (RBAC).

Table: users
Column	            Type	           Constraints	      Default	      Notes
id	               bigint	                PK	            auto
email	           varchar(255)	          UNIQUE		               Optional for drivers
phone	           varchar(20)	      UNIQUE, NOT NULL		          Primary identity
password_digest	 varchar(255)	         NOT NULL		                     bcrypt
role	             integer	           NOT NULL		                      enum
status	           integer	           NOT NULL	           0	          enum
city_id	           bigint	          FK → cities(id)
created_at	      timestamp	           NOT NULL	         now()
updated_at	      timestamp	           NOT NULL	         now()

Enums
* role: { rider: 0, driver: 1, admin: 2 }
* status: { active: 0, suspended: 1 }

Indexes
* index_users_on_phone
* index_users_on_email
* index_users_on_role
* index_users_on_city_id



3️⃣ vehicles
Purpose
* Represents a driver’s vehicle used for rides.

Table: vehicles
Column	           Type	            Constraints	        Default	        Notes
id	              bigint	               PK	              auto
driver_id	        bigint	          FK → users(id)	     NOT NULL	   role = driver
make	          varchar(100)	         NOT NULL
model	          varchar(100)	         NOT NULL
year	            integer	             NOT NULL
plate_number	   varchar(20)	      UNIQUE, NOT NULL
active	          boolean	             NOT NULL	          true
created_at	     timestamp	           NOT NULL	          now()
updated_at	     timestamp	           NOT NULL	          now()

Indexes
* index_vehicles_on_driver_id
* index_vehicles_on_plate_number



4️⃣ rides
Purpose
* Core transactional entity. Represents one trip.

Table: rides
Column	          Type	              Constraints	        Default	       Notes
id	             bigint	                   PK	              auto
rider_id	       bigint	             FK → users(id)	      NOT NULL
driver_id	       bigint	             FK → users(id)		                nullable until assigned
vehicle_id	     bigint	             FK → vehicles(id)
city_id	         bigint	             FK → cities(id)	    NOT NULL
status	        integer	                NOT NULL	           0	         enum
pickup_lat	  decimal(10,6)	            NOT NULL
pickup_lng	  decimal(10,6)	            NOT NULL
dropoff_lat	  decimal(10,6)	            NOT NULL
dropoff_lng	  decimal(10,6)	            NOT NULL
base_fare	    decimal(8,2)	            NOT NULL
per_km_rate	  decimal(6,2)	            NOT NULL
per_min_rate	decimal(6,2)	            NOT NULL
distance_km	  decimal(6,2)			                                       set post-ride
duration_min	decimal(6,2)			                                       set post-ride
total_fare	  decimal(8,2)			                                        calculated
created_at	   timestamp	              NOT NULL	          now()
updated_at	   timestamp	              NOT NULL	          now()

Enums
status: {
  requested: 0,
  assigned: 1,
  accepted: 2,
  started: 3,
  completed: 4,
  cancelled: 5
}

Indexes
* index_rides_on_rider_id
* index_rides_on_driver_id
* index_rides_on_status
* index_rides_on_city_id
* index_rides_on_created_at


5️⃣ payments
Purpose
* Represents payment for a completed ride.

Table: payments
Column	            Type	         Constraints	         Default	          Notes
id	               bigint	              PK	               auto
ride_id	           bigint	        FK → rides(id)	   NOT NULL, UNIQUE	  one payment per ride
amount	         decimal(8,2)	        NOT NULL
status	           integer	          NOT NULL	            0	              enum
payment_method	   integer	          NOT NULL		                          enum
external_reference varchar(255)			                                    Stripe/PayPal ID
created_at	      timestamp	          NOT NULL	          now()
updated_at	      timestamp	          NOT NULL	          now()

Enums
* status: { pending: 0, paid: 1, failed: 2 }
* payment_method: { card: 0 }

Indexes
* index_payments_on_ride_id
* index_payments_on_status


🔒 Global Constraints (Important)
* One ride → one rider, one driver, one vehicle
* Ride status transitions enforced in backend
* No soft deletes
* No polymorphism
* No premature optimization


1️⃣ cities
Foreign Keys
❌ None (root table)

Indexes
* CREATE UNIQUE INDEX index_cities_on_name ON cities(name);
* CREATE INDEX index_cities_on_active ON cities(active);

Why
* Name lookup during config
* Active flag for future city toggles
