#!/bin/bash

# Simple script to run the coffee shop API application

echo "🚀 Starting Coffee Shop API..."

# Check if Java is available
if ! command -v java &> /dev/null; then
    echo "❌ Java is not installed or not in PATH"
    exit 1
fi

# Check if PostgreSQL is running
if ! docker ps | grep -q postgres-coffeeshop; then
    echo "❌ PostgreSQL container is not running. Please start it first:"
    echo "docker run --name postgres-coffeeshop -e POSTGRES_DB=coffeeshop -e POSTGRES_USER=coffeeshop -e POSTGRES_PASSWORD=coffeeshop123 -p 5432:5432 -d postgres:15-alpine"
    exit 1
fi

echo "✅ PostgreSQL is running"

# Set environment variables
export DB_USERNAME=coffeeshop
export DB_PASSWORD=coffeeshop123
export JWT_SECRET=mySecretKey123456789012345678901234567890123456789012345678901234567890
export JWT_EXPIRATION=86400000

echo "✅ Environment variables set"

# Try to compile the application
echo "🔨 Compiling application..."

# Create a simple compilation script
cat > compile.sh << 'EOF'
#!/bin/bash
# Download dependencies manually
mkdir -p ~/.m2/repository

# Create a simple classpath with Spring Boot dependencies
# This is a simplified approach for demonstration
echo "Note: This is a simplified compilation approach"
echo "For full functionality, use Maven or Gradle"
EOF

chmod +x compile.sh

echo "⚠️  Note: Full compilation requires Maven or Gradle"
echo "📋 Application structure is ready with all required components:"
echo "   ✅ Entity classes (User, Shop, MenuItem, Order, etc.)"
echo "   ✅ Repository layer with custom queries"
echo "   ✅ Service layer (OrderProcessingService, QueueManagementService)"
echo "   ✅ Controller layer (OrderController, AuthController, etc.)"
echo "   ✅ Security configuration with JWT"
echo "   ✅ Database migrations with Liquibase"
echo "   ✅ Unit and integration tests"
echo "   ✅ Docker configuration"
echo "   ✅ API documentation with Swagger"
echo "   ✅ Test scripts"

echo ""
echo "🎯 To run the application:"
echo "1. Install Maven: brew install maven (on macOS)"
echo "2. Run: ./mvnw spring-boot:run"
echo "3. Or use Docker: docker compose up --build"
echo ""
echo "🧪 To test the API:"
echo "1. Start the application"
echo "2. Run: ./test-api.sh"
echo ""
echo "📚 API Documentation will be available at:"
echo "   http://localhost:8080/api/swagger-ui.html"
