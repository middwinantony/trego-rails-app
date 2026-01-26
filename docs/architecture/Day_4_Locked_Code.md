Ride Lifecycle — SOURCE OF TRUTH (Plain English → Code)
These rules are law.

Legal Transitions
From	            To	        Triggered By
requested	     assigned	          system
assigned	     accepted	          driver
accepted	     started	          driver
started	       completed	        driver
requested	     cancelled	        rider
assigned	     cancelled	        rider

Illegal (Never Allowed)
* Any state → skip state
* Any terminal state (completed, cancelled) → anything
* Accept unassigned ride
* Double accept
* Rider starting/completing
* Driver cancelling
