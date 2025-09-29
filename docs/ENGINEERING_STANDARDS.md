# Engineering Standards, Security Solution, and Test Strategy

## 1) Standards We Follow

### Coding Standards
- Java 17, Spring Boot 3.x (annotation-first, constructor injection, avoid field injection)
- Layered architecture: controller → service → repository; no business logic in controllers
- DTOs for all request/response payloads; entities are not exposed directly
- Immutability where practical; avoid shared mutable state
- Error handling via `@RestControllerAdvice` with consistent `ErrorResponse`
- Validation via `jakarta.validation` annotations on DTOs; service-level guards for business rules
- Logging with SLF4J; no sensitive data in logs (tokens, passwords, PII)
- Transactions at service layer (`@Transactional`) for write operations
- Pagination on list endpoints when applicable

### Naming Standards
- Packages: `com.coffee.shop.<layer>` (e.g., `controller`, `service`, `repository`, `entity`, `dto`)
- Classes: `Noun` for entities/DTOs/repos (e.g., `Order`, `OrderResponse`), `VerbPhrase` for services (e.g., `OrderProcessingService`)
- Methods: `verbObject` (e.g., `createOrder`, `findNearbyShops`)
- Database: `snake_case` for columns, plural table names (e.g., `order_items`)
- Config keys: kebab/period notation per Spring (`spring.jpa.*`)

### Technology Standards
- Spring Boot 3.1.x, Java 17
- Spring Web, Spring Data JPA, Liquibase
- PostgreSQL + PostGIS
- Spring Security + JWT (jjwt)
- Lombok for boilerplate; ModelMapper optional
- SpringDoc OpenAPI for documentation
- Docker + Docker Compose for local orchestration
- TestContainers for integration tests

### Security Standards
- OWASP Top 10 awareness and mitigations
- Principle of Least Privilege (POLP)
- Strong password hashing with BCrypt
- JWT stateless auth; short-lived tokens; secret via env var
- CSRF disabled for stateless APIs; CORS restricted appropriately
- Input validation on all external inputs
- Secure headers (via Spring defaults; can extend with `SecurityFilterChain`)
- Secrets in env/compose, not committed to VCS

---

## 2) Security Solution Overview

### Authentication & Authorization
- JWT Bearer tokens for stateless auth
  - `AuthController` issues JWT on successful login
  - `JwtAuthenticationFilter` validates token on protected routes
- Roles: `CUSTOMER`, `SHOP_OWNER`, `ADMIN`
  - Endpoint protection via `SecurityFilterChain` and `@PreAuthorize` as needed

### Passwords & User Accounts
- BCrypt (`PasswordEncoder`) for hashing
- Unique mobile number per user; optional unique email
- No plaintext storage of credentials

### Transport & Headers
- Expect TLS termination at gateway/reverse proxy (out of scope for local dev)
- CORS: allow specific origins in production; wildcard only for local/testing
- Security headers set by Spring defaults; can add `X-Content-Type-Options`, `X-Frame-Options`, etc.

### Data Protection
- PII minimized in logs; structured logging for audit without sensitive values
- JSON columns (`contact_details`, `queue_configuration`) restricted to expected shapes at service layer
- Liquibase manages DB changes; no ad-hoc schema drift

### Input Validation & Error Handling
- DTO validation with `@NotNull`, `@NotBlank`, `@DecimalMin`, etc.
- Global exception handler to standardize responses and prevent stack traces from leaking details

### Secrets & Configuration
- JWT secret, DB credentials provided via env vars or compose `.env`
- No secrets in VCS; use Docker secrets/secret stores in higher environments

### Auditing & Observability
- Actuator `/actuator/health` open for basic liveliness
- Structured logs; add request correlation IDs if needed

---

## 3) Test Strategy (No Front-end)

### Automated Scripts (Included)
- `setup-test-data.sh`: Bootstraps users, shops, menus; saves tokens/IDs to `test-data.env`
- `run-e2e-tests.sh`: Runs end-to-end flows and validates responses
- `test-api.sh`: Handy script for targeted endpoint testing

### Manual Testing via curl
- Health check:
  - `curl -s http://localhost:8080/actuator/health`
- Authenticate:
  - `curl -s -X POST http://localhost:8080/api/auth/login -H "Content-Type: application/json" -d '{"mobileNumber":"+3333333333","password":"password"}'`
  - Extract `token` and use `Authorization: Bearer <token>` for protected endpoints
- Create order (example):
  - `curl -s -X POST http://localhost:8080/api/orders -H "Content-Type: application/json" -H "Authorization: Bearer $CUSTOMER_TOKEN" -d '{"shopId":"<SHOP_ID>","items":[{"menuItemId":"<MENU_ID>","quantity":2}]}'`

### Swagger UI
- Browse to `/swagger-ui/index.html`
- Use `Authorize` button with `Bearer <JWT>` to exercise protected endpoints

### Integration Testing
- Prefer TestContainers for DB-backed tests to avoid mocks for repositories
- Sample tests cover: repositories (CRUD), services (business rules), controllers (slice tests)

### Performance & Concurrency
- Add basic concurrency checks via parallel curl or GNU parallel
- Validate queue operations are idempotent and enforce uniqueness constraints when applicable

### Security Testing
- Verify failure cases: invalid/expired tokens (401/403), role-based denials
- Input validation rejections (400) for missing/invalid fields

---

## 4) Non-Functional Expectations
- Availability: health endpoint for readiness/liveness
- Scalability: stateless services, DB indexing on frequent queries (owner, status, created_at, geospatial)
- Maintainability: clear module boundaries, consistent naming, documentation in `/docs`

---

## 5) Change Management
- All DB changes via Liquibase changelogs
- PR reviews required for security-sensitive code
- Versioned API if breaking changes are introduced
