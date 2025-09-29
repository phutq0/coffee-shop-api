# Coffee Shop API - Endpoint List

Base URL: `http://localhost:8080`

All protected endpoints require the HTTP header: `Authorization: Bearer <JWT>`.

---

## Authentication (Public)
- POST `/api/auth/register`
  - Register a new user
- POST `/api/auth/login`
  - Login and receive JWT

---

## Shops (Protected)
- GET `/api/shops`
  - List all active shops
- POST `/api/shops`
  - Create a new shop (Shop Owner)
- GET `/api/shops/{shopId}`
  - Get shop details
- GET `/api/shops/nearby?latitude={lat}&longitude={lng}&radius={meters}`
  - Find nearby shops
- GET `/api/shops/{shopId}/orders`
  - Get orders for a shop (Shop Owner)

---

## Menu (Protected)
- GET `/api/menu/shop/{shopId}`
  - Get all menu items for a shop
- GET `/api/menu/shop/{shopId}/category/{category}`
  - Get menu items for a shop by category
- POST `/api/menu/shop/{shopId}`
  - Create a new menu item for a shop (Shop Owner)

---

## Orders (Protected)
- POST `/api/orders`
  - Create a new order (Customer)
- GET `/api/orders`
  - List orders for the authenticated customer
- GET `/api/orders/{orderId}`
  - Get order details
- PUT `/api/orders/{orderId}/cancel`
  - Cancel an order (Customer)

---

## Queue (Protected)
- POST `/api/queue/join`
  - Join queue for an existing order (Customer)
- GET `/api/queue/position/{queueEntryId}`
  - Get position and estimated wait time

---

## Observability (Public)
- GET `/actuator/health`
  - Application health
- GET `/v3/api-docs`
  - OpenAPI JSON
- GET `/swagger-ui/index.html`
  - Swagger UI (supports Bearer JWT Authorize)

---

## Headers
- `Content-Type: application/json` for requests with bodies
- `Authorization: Bearer <JWT>` for protected endpoints

---

## Notes
- IDs are UUIDs.
- Monetary values are decimals (2dp).
- Geospatial endpoints use `latitude`, `longitude`, and `radius` (meters).
