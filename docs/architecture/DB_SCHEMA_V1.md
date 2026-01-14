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
