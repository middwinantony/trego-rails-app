*******Login Test Plan – Complete Scenario Coverage******

1. Positive / Happy Path
Valid email + valid password
Valid email with leading/trailing spaces (should be trimmed)
Login immediately after signup (fresh account)

2. Email Field Validation
Format & Syntax
Invalid email format (user@, @example.com, userexample.com)
Email with uppercase characters
Email with spaces inside
Email with special characters not allowed
Missing / Empty:
Missing email field
email = ""
email = " "
Boundary:
Extremely long email (1000+ chars)
Email with Unicode characters

3. Password Field Validation
Missing / Empty:
Missing password field
password = ""
password = " "

Invalid Values
Wrong password
Password too short (if rules exist)
Password too long (1000+ chars)

4. Authentication Logic

Email not found in the system
Correct email + wrong password
Locked account
Unverified email (if applicable)
Disabled account
Expired password (if applicable)

5. Security Tests

Injection Attacks
SQL injection attempt in email
SQL injection attempt in password
XSS attempt in email
XSS attempt in password

Brute Force / Rate Limiting
Multiple failed attempts → check lockout
Rapid repeated login attempts
Login from multiple IPs

Other Security
Check if error messages leak sensitive info
Ensure no stack traces in response
Ensure tokens are secure (HTTP-only, expiration, etc.)

6. HTTP Protocol & Headers

Missing Content-Type header
Wrong Content-Type (e.g., text/plain)
Send payload as form-data
Send payload as x-www-form-urlencoded
Send GET instead of POST
Send empty body with POST

7. Response Validation

Correct HTTP status codes
Response time within acceptable limits
Response schema validation
Token returned (if applicable)
Token format validation
Error message consistency

8. Negative / Edge Cases

Null values: "email": null, "password": null
Boolean values instead of strings
Numbers instead of strings
Extra unexpected fields
Duplicate login requests
Login while already logged in (if session-based)



********Complete Signup API Test Scenarios********

1. Positive / Happy Path

Valid email + valid password
Email with uppercase characters (should normalize)
Email with leading/trailing spaces (should trim)
Signup with minimal valid password (if rules exist)

2. Email Field Validation

Format & Syntax
Missing @ symbol
Missing domain (user@)
Missing username (@example.com)
Email with spaces
Email with invalid characters
Email with Unicode characters
Email with multiple @ symbols

Missing / Empty
Missing email field
email = ""
email = " "

Boundary
Extremely long email (e.g., 320+ chars)
Email exceeding backend limit
Email with subdomains

3. Password Field Validation

Missing / Empty
Missing password field
password = ""
password = " "

Invalid Values
Too short password
Too long password (1000+ chars)
Password without required complexity (if rules exist)
Password with spaces
Password with Unicode characters

4. Business Logic Scenarios

Duplicate email (existing user)
Signup with email already registered but not verified
Signup with email registered via social login (if applicable)
Signup rate limiting (too many attempts)

5. Security Tests

Injection Attacks
SQL injection in email
SQL injection in password
XSS attempt in email
XSS attempt in password

Other Security
Ensure no sensitive info leaks in error messages
Ensure no stack traces returned
Ensure password is not returned in response
Ensure secure token returned (if applicable)

6. HTTP Protocol & Headers

Missing Content-Type
Wrong Content-Type (text/plain, multipart/form-data)
Sending payload as form-data
Sending payload as x-www-form-urlencoded
Sending GET instead of POST
Sending empty body

7. Response Validation

Correct HTTP status codes
Response schema validation
Response time within limits
Token returned (if applicable)
Token format validation
Consistent error messages

8. Negative / Edge Cases

Null values: "email": null, "password": null
Boolean values instead of strings
Numbers instead of strings
Extra unexpected fields
Nested objects instead of strings
Duplicate requests
Signup while already authenticated (if session-based)
