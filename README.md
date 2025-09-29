# Coffee Shop API

A comprehensive Spring Boot 3.1.5 application for managing coffee shop operations including order processing, queue management, and customer services.

## Features

- **Order Management**: Create, retrieve, and cancel orders
- **Queue Management**: Real-time queue tracking and position management
- **User Management**: Customer and shop owner authentication
- **Menu Management**: Dynamic menu items with categories
- **Location Services**: Find nearby shops using geospatial queries
- **JWT Authentication**: Secure API access with JWT tokens
- **Database Migrations**: Liquibase for schema management
- **Comprehensive Testing**: Unit and integration tests with TestContainers

## Technology Stack

- **Java 17**
- **Spring Boot 3.1.5**
- **Spring Security** with JWT
- **Spring Data JPA**
- **PostgreSQL** with PostGIS extension
- **Liquibase** for database migrations
- **TestContainers** for integration testing
- **OpenAPI/Swagger** for API documentation
- **Docker** for containerization

## Project Structure

```
src/
├── main/java/com/coffee/shop/
│   ├── entity/           # JPA entities
│   ├── repository/        # Data repositories
│   ├── service/          # Business logic services
│   ├── controller/        # REST controllers
│   ├── dto/              # Data transfer objects
│   ├── exception/         # Custom exceptions
│   ├── config/           # Configuration classes
│   └── security/         # Security components
├── main/resources/
│   ├── application.yml    # Application configuration
│   └── db/changelog/     # Liquibase migrations
└── test/                 # Test classes
```

## Getting Started

### Prerequisites

- Java 17 or higher
- Maven 3.6 or higher
- PostgreSQL 12 or higher
- Docker (optional)

### Local Development

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd coffee-shop-api
   ```

2. **Set up PostgreSQL database**
   ```bash
   # Create database
   createdb coffeeshop
   
   # Or use Docker
   docker run --name postgres-coffeeshop -e POSTGRES_DB=coffeeshop -e POSTGRES_USER=coffeeshop -e POSTGRES_PASSWORD=coffeeshop123 -p 5432:5432 -d postgres:15-alpine
   ```

3. **Configure application properties**
   ```yaml
   # Update src/main/resources/application.yml
   spring:
     datasource:
       url: jdbc:postgresql://localhost:5432/coffeeshop
       username: coffeeshop
       password: coffeeshop123
   ```

4. **Run the application**
   ```bash
   ./mvnw spring-boot:run
   ```

### Docker Development

1. **Build and run with Docker Compose**
   ```bash
   docker-compose up --build
   ```

2. **Access the application**
   - API: http://localhost:8080/api
   - Swagger UI: http://localhost:8080/api/swagger-ui.html
   - Health Check: http://localhost:8080/api/actuator/health

## API Endpoints

### Authentication
- `POST /api/auth/register` - Register new user
- `POST /api/auth/login` - User login

### Orders
- `POST /api/orders` - Create new order
- `GET /api/orders/{orderId}` - Get order details
- `PUT /api/orders/{orderId}/cancel` - Cancel order

### Shops
- `GET /api/shops/nearby` - Find nearby shops
- `GET /api/shops/{shopId}` - Get shop details

### Menu
- `GET /api/menu/shop/{shopId}` - Get shop menu items

## Testing

### Run Unit Tests
```bash
./mvnw test
```

### Run Integration Tests
```bash
./mvnw test -Dtest=*IntegrationTest
```

### Run API Tests
```bash
# Make sure the application is running
./test-api.sh
```

## Database Schema

The application uses the following main entities:

- **Users**: Customer and shop owner accounts
- **Shops**: Coffee shop locations and details
- **MenuItems**: Shop menu items with pricing
- **Orders**: Customer orders with items
- **OrderItems**: Individual items within orders
- **QueueEntries**: Queue management for orders
- **OperatingHours**: Shop operating schedules

## Configuration

### Environment Variables

- `DB_USERNAME`: Database username (default: coffeeshop)
- `DB_PASSWORD`: Database password (default: coffeeshop123)
- `JWT_SECRET`: JWT signing secret
- `JWT_EXPIRATION`: JWT token expiration in milliseconds

### Application Properties

Key configuration options in `application.yml`:

```yaml
server:
  port: 8080
  servlet:
    context-path: /api

spring:
  datasource:
    url: jdbc:postgresql://localhost:5432/coffeeshop
    username: ${DB_USERNAME:coffeeshop}
    password: ${DB_PASSWORD:coffeeshop123}

jwt:
  secret: ${JWT_SECRET:mySecretKey...}
  expiration: ${JWT_EXPIRATION:86400000}
```

## Security

- JWT-based authentication
- Password encryption with BCrypt
- CORS configuration for cross-origin requests
- Role-based access control (CUSTOMER, SHOP_OWNER, ADMIN)

## Monitoring

- Health check endpoint: `/api/actuator/health`
- Metrics endpoint: `/api/actuator/metrics`
- Application logs with configurable levels

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Ensure all tests pass
6. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support and questions, please contact the development team or create an issue in the repository.

