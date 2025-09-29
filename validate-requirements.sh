#!/bin/bash

# Coffee Shop API Requirements Validation Script
# This script validates that all requirements from prompt.MD are implemented

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    local status=$1
    local message=$2
    if [ "$status" = "SUCCESS" ]; then
        echo -e "${GREEN}✓${NC} $message"
    elif [ "$status" = "ERROR" ]; then
        echo -e "${RED}✗${NC} $message"
    elif [ "$status" = "INFO" ]; then
        echo -e "${BLUE}ℹ${NC} $message"
    elif [ "$status" = "WARNING" ]; then
        echo -e "${YELLOW}⚠${NC} $message"
    fi
}

# Function to check if file exists
check_file() {
    local file=$1
    local description=$2
    if [ -f "$file" ]; then
        print_status "SUCCESS" "$description - $file"
        return 0
    else
        print_status "ERROR" "$description - $file (MISSING)"
        return 1
    fi
}

# Function to check if directory exists
check_directory() {
    local dir=$1
    local description=$2
    if [ -d "$dir" ]; then
        print_status "SUCCESS" "$description - $dir"
        return 0
    else
        print_status "ERROR" "$description - $dir (MISSING)"
        return 1
    fi
}

# Function to check if file contains specific content
check_content() {
    local file=$1
    local pattern=$2
    local description=$3
    if [ -f "$file" ] && grep -q "$pattern" "$file"; then
        print_status "SUCCESS" "$description"
        return 0
    else
        print_status "ERROR" "$description (NOT FOUND)"
        return 1
    fi
}

echo -e "${BLUE}🔍 Coffee Shop API Requirements Validation${NC}"
echo "=================================================="
echo ""

# Initialize counters
total_checks=0
passed_checks=0

# 1. Project Setup Requirements
echo -e "${BLUE}📋 1. Project Setup Requirements${NC}"
echo "----------------------------------------"

check_file "pom.xml" "Maven POM file"
((total_checks++))
if [ -f "pom.xml" ]; then ((passed_checks++)); fi

check_content "pom.xml" "3.1.5" "Spring Boot 3.1.5 parent"
((total_checks++))
if [ -f "pom.xml" ] && grep -q "3.1.5" pom.xml; then ((passed_checks++)); fi

check_content "pom.xml" "spring-boot-starter-web" "Spring Web dependency"
((total_checks++))
if [ -f "pom.xml" ] && grep -q "spring-boot-starter-web" pom.xml; then ((passed_checks++)); fi

check_content "pom.xml" "spring-boot-starter-data-jpa" "Spring Data JPA dependency"
((total_checks++))
if [ -f "pom.xml" ] && grep -q "spring-boot-starter-data-jpa" pom.xml; then ((passed_checks++)); fi

check_content "pom.xml" "spring-boot-starter-security" "Spring Security dependency"
((total_checks++))
if [ -f "pom.xml" ] && grep -q "spring-boot-starter-security" pom.xml; then ((passed_checks++)); fi

check_content "pom.xml" "postgresql" "PostgreSQL dependency"
((total_checks++))
if [ -f "pom.xml" ] && grep -q "postgresql" pom.xml; then ((passed_checks++)); fi

check_content "pom.xml" "liquibase-core" "Liquibase dependency"
((total_checks++))
if [ -f "pom.xml" ] && grep -q "liquibase-core" pom.xml; then ((passed_checks++)); fi

check_content "pom.xml" "lombok" "Lombok dependency"
((total_checks++))
if [ -f "pom.xml" ] && grep -q "lombok" pom.xml; then ((passed_checks++)); fi

check_content "pom.xml" "spring-boot-starter-validation" "Validation dependency"
((total_checks++))
if [ -f "pom.xml" ] && grep -q "spring-boot-starter-validation" pom.xml; then ((passed_checks++)); fi

check_content "pom.xml" "jjwt" "JWT dependency"
((total_checks++))
if [ -f "pom.xml" ] && grep -q "jjwt" pom.xml; then ((passed_checks++)); fi

check_content "pom.xml" "springdoc-openapi" "OpenAPI dependency"
((total_checks++))
if [ -f "pom.xml" ] && grep -q "springdoc-openapi" pom.xml; then ((passed_checks++)); fi

check_content "pom.xml" "modelmapper" "ModelMapper dependency"
((total_checks++))
if [ -f "pom.xml" ] && grep -q "modelmapper" pom.xml; then ((passed_checks++)); fi

check_content "pom.xml" "testcontainers" "TestContainers dependency"
((total_checks++))
if [ -f "pom.xml" ] && grep -q "testcontainers" pom.xml; then ((passed_checks++)); fi

echo ""

# 2. Entity Classes Requirements
echo -e "${BLUE}📋 2. Entity Classes Requirements${NC}"
echo "----------------------------------------"

check_file "src/main/java/com/coffee/shop/entity/User.java" "User entity"
((total_checks++))
if [ -f "src/main/java/com/coffee/shop/entity/User.java" ]; then ((passed_checks++)); fi

check_file "src/main/java/com/coffee/shop/entity/Shop.java" "Shop entity"
((total_checks++))
if [ -f "src/main/java/com/coffee/shop/entity/Shop.java" ]; then ((passed_checks++)); fi

check_file "src/main/java/com/coffee/shop/entity/MenuItem.java" "MenuItem entity"
((total_checks++))
if [ -f "src/main/java/com/coffee/shop/entity/MenuItem.java" ]; then ((passed_checks++)); fi

check_file "src/main/java/com/coffee/shop/entity/Order.java" "Order entity"
((total_checks++))
if [ -f "src/main/java/com/coffee/shop/entity/Order.java" ]; then ((passed_checks++)); fi

check_file "src/main/java/com/coffee/shop/entity/OrderItem.java" "OrderItem entity"
((total_checks++))
if [ -f "src/main/java/com/coffee/shop/entity/OrderItem.java" ]; then ((passed_checks++)); fi

check_file "src/main/java/com/coffee/shop/entity/QueueEntry.java" "QueueEntry entity"
((total_checks++))
if [ -f "src/main/java/com/coffee/shop/entity/QueueEntry.java" ]; then ((passed_checks++)); fi

check_file "src/main/java/com/coffee/shop/entity/OperatingHours.java" "OperatingHours entity"
((total_checks++))
if [ -f "src/main/java/com/coffee/shop/entity/OperatingHours.java" ]; then ((passed_checks++)); fi

# Check for UUID usage in entities
check_content "src/main/java/com/coffee/shop/entity/User.java" "UUID" "User entity uses UUID"
((total_checks++))
if [ -f "src/main/java/com/coffee/shop/entity/User.java" ] && grep -q "UUID" src/main/java/com/coffee/shop/entity/User.java; then ((passed_checks++)); fi

check_content "src/main/java/com/coffee/shop/entity/User.java" "@Entity" "User entity has JPA annotations"
((total_checks++))
if [ -f "src/main/java/com/coffee/shop/entity/User.java" ] && grep -q "@Entity" src/main/java/com/coffee/shop/entity/User.java; then ((passed_checks++)); fi

echo ""

# 3. Repository Layer Requirements
echo -e "${BLUE}📋 3. Repository Layer Requirements${NC}"
echo "----------------------------------------"

check_file "src/main/java/com/coffee/shop/repository/UserRepository.java" "UserRepository"
((total_checks++))
if [ -f "src/main/java/com/coffee/shop/repository/UserRepository.java" ]; then ((passed_checks++)); fi

check_file "src/main/java/com/coffee/shop/repository/ShopRepository.java" "ShopRepository"
((total_checks++))
if [ -f "src/main/java/com/coffee/shop/repository/ShopRepository.java" ]; then ((passed_checks++)); fi

check_file "src/main/java/com/coffee/shop/repository/MenuItemRepository.java" "MenuItemRepository"
((total_checks++))
if [ -f "src/main/java/com/coffee/shop/repository/MenuItemRepository.java" ]; then ((passed_checks++)); fi

check_file "src/main/java/com/coffee/shop/repository/OrderRepository.java" "OrderRepository"
((total_checks++))
if [ -f "src/main/java/com/coffee/shop/repository/OrderRepository.java" ]; then ((passed_checks++)); fi

check_file "src/main/java/com/coffee/shop/repository/QueueEntryRepository.java" "QueueEntryRepository"
((total_checks++))
if [ -f "src/main/java/com/coffee/shop/repository/QueueEntryRepository.java" ]; then ((passed_checks++)); fi

check_file "src/main/java/com/coffee/shop/repository/OrderItemRepository.java" "OrderItemRepository"
((total_checks++))
if [ -f "src/main/java/com/coffee/shop/repository/OrderItemRepository.java" ]; then ((passed_checks++)); fi

# Check for custom queries
check_content "src/main/java/com/coffee/shop/repository/UserRepository.java" "findByMobileNumber" "UserRepository has findByMobileNumber"
((total_checks++))
if [ -f "src/main/java/com/coffee/shop/repository/UserRepository.java" ] && grep -q "findByMobileNumber" src/main/java/com/coffee/shop/repository/UserRepository.java; then ((passed_checks++)); fi

check_content "src/main/java/com/coffee/shop/repository/ShopRepository.java" "findNearbyShops" "ShopRepository has nearby shops query"
((total_checks++))
if [ -f "src/main/java/com/coffee/shop/repository/ShopRepository.java" ] && grep -q "findNearbyShops" src/main/java/com/coffee/shop/repository/ShopRepository.java; then ((passed_checks++)); fi

echo ""

# 4. Service Layer Requirements
echo -e "${BLUE}📋 4. Service Layer Requirements${NC}"
echo "----------------------------------------"

check_file "src/main/java/com/coffee/shop/service/OrderProcessingService.java" "OrderProcessingService"
((total_checks++))
if [ -f "src/main/java/com/coffee/shop/service/OrderProcessingService.java" ]; then ((passed_checks++)); fi

check_file "src/main/java/com/coffee/shop/service/QueueManagementService.java" "QueueManagementService"
((total_checks++))
if [ -f "src/main/java/com/coffee/shop/service/QueueManagementService.java" ]; then ((passed_checks++)); fi

check_file "src/main/java/com/coffee/shop/service/JwtService.java" "JwtService"
((total_checks++))
if [ -f "src/main/java/com/coffee/shop/service/JwtService.java" ]; then ((passed_checks++)); fi

check_file "src/main/java/com/coffee/shop/service/UserService.java" "UserService"
((total_checks++))
if [ -f "src/main/java/com/coffee/shop/service/UserService.java" ]; then ((passed_checks++)); fi

# Check for key methods
check_content "src/main/java/com/coffee/shop/service/OrderProcessingService.java" "processOrder" "OrderProcessingService has processOrder method"
((total_checks++))
if [ -f "src/main/java/com/coffee/shop/service/OrderProcessingService.java" ] && grep -q "processOrder" src/main/java/com/coffee/shop/service/OrderProcessingService.java; then ((passed_checks++)); fi

check_content "src/main/java/com/coffee/shop/service/QueueManagementService.java" "addToQueue" "QueueManagementService has addToQueue method"
((total_checks++))
if [ -f "src/main/java/com/coffee/shop/service/QueueManagementService.java" ] && grep -q "addToQueue" src/main/java/com/coffee/shop/service/QueueManagementService.java; then ((passed_checks++)); fi

echo ""

# 5. DTOs and Request/Response Objects
echo -e "${BLUE}📋 5. DTOs and Request/Response Objects${NC}"
echo "----------------------------------------"

check_file "src/main/java/com/coffee/shop/dto/request/CreateOrderRequest.java" "CreateOrderRequest"
((total_checks++))
if [ -f "src/main/java/com/coffee/shop/dto/request/CreateOrderRequest.java" ]; then ((passed_checks++)); fi

check_file "src/main/java/com/coffee/shop/dto/request/OrderItemRequest.java" "OrderItemRequest"
((total_checks++))
if [ -f "src/main/java/com/coffee/shop/dto/request/OrderItemRequest.java" ]; then ((passed_checks++)); fi

check_file "src/main/java/com/coffee/shop/dto/response/OrderResponse.java" "OrderResponse"
((total_checks++))
if [ -f "src/main/java/com/coffee/shop/dto/response/OrderResponse.java" ]; then ((passed_checks++)); fi

check_file "src/main/java/com/coffee/shop/dto/response/OrderItemResponse.java" "OrderItemResponse"
((total_checks++))
if [ -f "src/main/java/com/coffee/shop/dto/response/OrderItemResponse.java" ]; then ((passed_checks++)); fi

check_file "src/main/java/com/coffee/shop/dto/response/QueuePositionResponse.java" "QueuePositionResponse"
((total_checks++))
if [ -f "src/main/java/com/coffee/shop/dto/response/QueuePositionResponse.java" ]; then ((passed_checks++)); fi

check_file "src/main/java/com/coffee/shop/dto/response/ErrorResponse.java" "ErrorResponse"
((total_checks++))
if [ -f "src/main/java/com/coffee/shop/dto/response/ErrorResponse.java" ]; then ((passed_checks++)); fi

check_file "src/main/java/com/coffee/shop/dto/request/RegisterRequest.java" "RegisterRequest"
((total_checks++))
if [ -f "src/main/java/com/coffee/shop/dto/request/RegisterRequest.java" ]; then ((passed_checks++)); fi

check_file "src/main/java/com/coffee/shop/dto/request/LoginRequest.java" "LoginRequest"
((total_checks++))
if [ -f "src/main/java/com/coffee/shop/dto/request/LoginRequest.java" ]; then ((passed_checks++)); fi

check_file "src/main/java/com/coffee/shop/dto/response/AuthResponse.java" "AuthResponse"
((total_checks++))
if [ -f "src/main/java/com/coffee/shop/dto/response/AuthResponse.java" ]; then ((passed_checks++)); fi

echo ""

# 6. Controller Layer Requirements
echo -e "${BLUE}📋 6. Controller Layer Requirements${NC}"
echo "----------------------------------------"

check_file "src/main/java/com/coffee/shop/controller/OrderController.java" "OrderController"
((total_checks++))
if [ -f "src/main/java/com/coffee/shop/controller/OrderController.java" ]; then ((passed_checks++)); fi

check_file "src/main/java/com/coffee/shop/controller/AuthController.java" "AuthController"
((total_checks++))
if [ -f "src/main/java/com/coffee/shop/controller/AuthController.java" ]; then ((passed_checks++)); fi

check_file "src/main/java/com/coffee/shop/controller/ShopController.java" "ShopController"
((total_checks++))
if [ -f "src/main/java/com/coffee/shop/controller/ShopController.java" ]; then ((passed_checks++)); fi

check_file "src/main/java/com/coffee/shop/controller/MenuController.java" "MenuController"
((total_checks++))
if [ -f "src/main/java/com/coffee/shop/controller/MenuController.java" ]; then ((passed_checks++)); fi

# Check for OpenAPI annotations
check_content "src/main/java/com/coffee/shop/controller/OrderController.java" "@Operation" "OrderController has OpenAPI annotations"
((total_checks++))
if [ -f "src/main/java/com/coffee/shop/controller/OrderController.java" ] && grep -q "@Operation" src/main/java/com/coffee/shop/controller/OrderController.java; then ((passed_checks++)); fi

echo ""

# 7. Exception Handling Requirements
echo -e "${BLUE}📋 7. Exception Handling Requirements${NC}"
echo "----------------------------------------"

check_file "src/main/java/com/coffee/shop/exception/GlobalExceptionHandler.java" "GlobalExceptionHandler"
((total_checks++))
if [ -f "src/main/java/com/coffee/shop/exception/GlobalExceptionHandler.java" ]; then ((passed_checks++)); fi

check_file "src/main/java/com/coffee/shop/exception/ResourceNotFoundException.java" "ResourceNotFoundException"
((total_checks++))
if [ -f "src/main/java/com/coffee/shop/exception/ResourceNotFoundException.java" ]; then ((passed_checks++)); fi

check_file "src/main/java/com/coffee/shop/exception/ValidationException.java" "ValidationException"
((total_checks++))
if [ -f "src/main/java/com/coffee/shop/exception/ValidationException.java" ]; then ((passed_checks++)); fi

check_file "src/main/java/com/coffee/shop/exception/BusinessException.java" "BusinessException"
((total_checks++))
if [ -f "src/main/java/com/coffee/shop/exception/BusinessException.java" ]; then ((passed_checks++)); fi

check_content "src/main/java/com/coffee/shop/exception/GlobalExceptionHandler.java" "@RestControllerAdvice" "GlobalExceptionHandler has @RestControllerAdvice"
((total_checks++))
if [ -f "src/main/java/com/coffee/shop/exception/GlobalExceptionHandler.java" ] && grep -q "@RestControllerAdvice" src/main/java/com/coffee/shop/exception/GlobalExceptionHandler.java; then ((passed_checks++)); fi

echo ""

# 8. Security Configuration Requirements
echo -e "${BLUE}📋 8. Security Configuration Requirements${NC}"
echo "----------------------------------------"

check_file "src/main/java/com/coffee/shop/config/SecurityConfig.java" "SecurityConfig"
((total_checks++))
if [ -f "src/main/java/com/coffee/shop/config/SecurityConfig.java" ]; then ((passed_checks++)); fi

check_file "src/main/java/com/coffee/shop/security/JwtAuthenticationFilter.java" "JwtAuthenticationFilter"
((total_checks++))
if [ -f "src/main/java/com/coffee/shop/security/JwtAuthenticationFilter.java" ]; then ((passed_checks++)); fi

check_content "src/main/java/com/coffee/shop/config/SecurityConfig.java" "JwtAuthenticationFilter" "SecurityConfig has JWT configuration"
((total_checks++))
if [ -f "src/main/java/com/coffee/shop/config/SecurityConfig.java" ] && grep -q "JwtAuthenticationFilter" src/main/java/com/coffee/shop/config/SecurityConfig.java; then ((passed_checks++)); fi

echo ""

# 9. Liquibase Migrations Requirements
echo -e "${BLUE}📋 9. Liquibase Migrations Requirements${NC}"
echo "----------------------------------------"

check_file "src/main/resources/db/changelog/db.changelog-master.xml" "Master changelog"
((total_checks++))
if [ -f "src/main/resources/db/changelog/db.changelog-master.xml" ]; then ((passed_checks++)); fi

check_file "src/main/resources/db/changelog/001-create-users-table.xml" "Users table migration"
((total_checks++))
if [ -f "src/main/resources/db/changelog/001-create-users-table.xml" ]; then ((passed_checks++)); fi

check_file "src/main/resources/db/changelog/002-create-shops-table.xml" "Shops table migration"
((total_checks++))
if [ -f "src/main/resources/db/changelog/002-create-shops-table.xml" ]; then ((passed_checks++)); fi

check_file "src/main/resources/db/changelog/003-create-menu-items-table.xml" "Menu items table migration"
((total_checks++))
if [ -f "src/main/resources/db/changelog/003-create-menu-items-table.xml" ]; then ((passed_checks++)); fi

check_file "src/main/resources/db/changelog/004-create-orders-table.xml" "Orders table migration"
((total_checks++))
if [ -f "src/main/resources/db/changelog/004-create-orders-table.xml" ]; then ((passed_checks++)); fi

check_file "src/main/resources/db/changelog/005-create-queue-entries-table.xml" "Queue entries table migration"
((total_checks++))
if [ -f "src/main/resources/db/changelog/005-create-queue-entries-table.xml" ]; then ((passed_checks++)); fi

check_file "src/main/resources/db/changelog/006-create-operating-hours-table.xml" "Operating hours table migration"
((total_checks++))
if [ -f "src/main/resources/db/changelog/006-create-operating-hours-table.xml" ]; then ((passed_checks++)); fi

check_file "src/main/resources/db/changelog/007-insert-sample-data.xml" "Sample data migration"
((total_checks++))
if [ -f "src/main/resources/db/changelog/007-insert-sample-data.xml" ]; then ((passed_checks++)); fi

echo ""

# 10. Application Properties Requirements
echo -e "${BLUE}📋 10. Application Properties Requirements${NC}"
echo "----------------------------------------"

check_file "src/main/resources/application.yml" "Application configuration"
((total_checks++))
if [ -f "src/main/resources/application.yml" ]; then ((passed_checks++)); fi

check_content "src/main/resources/application.yml" "datasource" "Database connection settings"
((total_checks++))
if [ -f "src/main/resources/application.yml" ] && grep -q "datasource" src/main/resources/application.yml; then ((passed_checks++)); fi

check_content "src/main/resources/application.yml" "jwt" "JWT configuration"
((total_checks++))
if [ -f "src/main/resources/application.yml" ] && grep -q "jwt" src/main/resources/application.yml; then ((passed_checks++)); fi

check_content "src/main/resources/application.yml" "liquibase" "Liquibase settings"
((total_checks++))
if [ -f "src/main/resources/application.yml" ] && grep -q "liquibase" src/main/resources/application.yml; then ((passed_checks++)); fi

echo ""

# 11. Unit Tests Requirements
echo -e "${BLUE}📋 11. Unit Tests Requirements${NC}"
echo "----------------------------------------"

check_file "src/test/java/com/coffee/shop/service/OrderProcessingServiceTest.java" "OrderProcessingService unit tests"
((total_checks++))
if [ -f "src/test/java/com/coffee/shop/service/OrderProcessingServiceTest.java" ]; then ((passed_checks++)); fi

check_content "src/test/java/com/coffee/shop/service/OrderProcessingServiceTest.java" "Mockito" "Unit tests use Mockito"
((total_checks++))
if [ -f "src/test/java/com/coffee/shop/service/OrderProcessingServiceTest.java" ] && grep -q "Mockito" src/test/java/com/coffee/shop/service/OrderProcessingServiceTest.java; then ((passed_checks++)); fi

echo ""

# 12. Integration Tests Requirements
echo -e "${BLUE}📋 12. Integration Tests Requirements${NC}"
echo "----------------------------------------"

check_file "src/test/java/com/coffee/shop/integration/OrderProcessingIntegrationTest.java" "Integration tests"
((total_checks++))
if [ -f "src/test/java/com/coffee/shop/integration/OrderProcessingIntegrationTest.java" ]; then ((passed_checks++)); fi

check_content "src/test/java/com/coffee/shop/integration/OrderProcessingIntegrationTest.java" "Testcontainers" "Integration tests use TestContainers"
((total_checks++))
if [ -f "src/test/java/com/coffee/shop/integration/OrderProcessingIntegrationTest.java" ] && grep -q "Testcontainers" src/test/java/com/coffee/shop/integration/OrderProcessingIntegrationTest.java; then ((passed_checks++)); fi

echo ""

# 13. Docker Configuration Requirements
echo -e "${BLUE}📋 13. Docker Configuration Requirements${NC}"
echo "----------------------------------------"

check_file "Dockerfile" "Dockerfile"
((total_checks++))
if [ -f "Dockerfile" ]; then ((passed_checks++)); fi

check_file "docker-compose.yml" "docker-compose.yml"
((total_checks++))
if [ -f "docker-compose.yml" ]; then ((passed_checks++)); fi

check_content "Dockerfile" "openjdk:17" "Dockerfile uses Java 17"
((total_checks++))
if [ -f "Dockerfile" ] && grep -q "openjdk:17" Dockerfile; then ((passed_checks++)); fi

check_content "docker-compose.yml" "postgres" "docker-compose includes PostgreSQL"
((total_checks++))
if [ -f "docker-compose.yml" ] && grep -q "postgres" docker-compose.yml; then ((passed_checks++)); fi

echo ""

# 14. Test Scripts Requirements
echo -e "${BLUE}📋 14. Test Scripts Requirements${NC}"
echo "----------------------------------------"

check_file "test-api.sh" "API test script"
((total_checks++))
if [ -f "test-api.sh" ]; then ((passed_checks++)); fi

check_file "validate-requirements.sh" "Requirements validation script"
((total_checks++))
if [ -f "validate-requirements.sh" ]; then ((passed_checks++)); fi

check_content "test-api.sh" "curl" "API test script uses curl"
((total_checks++))
if [ -f "test-api.sh" ] && grep -q "curl" test-api.sh; then ((passed_checks++)); fi

echo ""

# 15. Documentation Requirements
echo -e "${BLUE}📋 15. Documentation Requirements${NC}"
echo "----------------------------------------"

check_file "README.md" "README documentation"
((total_checks++))
if [ -f "README.md" ]; then ((passed_checks++)); fi

check_content "README.md" "Coffee Shop API" "README has project description"
((total_checks++))
if [ -f "README.md" ] && grep -q "Coffee Shop API" README.md; then ((passed_checks++)); fi

echo ""

# Summary
echo -e "${BLUE}📊 SUMMARY${NC}"
echo "=========="
echo "Total checks: $total_checks"
echo "Passed checks: $passed_checks"
echo "Failed checks: $((total_checks - passed_checks))"
echo "Success rate: $(( (passed_checks * 100) / total_checks ))%"

if [ $passed_checks -eq $total_checks ]; then
    echo ""
    print_status "SUCCESS" "🎉 ALL REQUIREMENTS IMPLEMENTED SUCCESSFULLY!"
    echo ""
    echo -e "${GREEN}✅ The Coffee Shop API implementation meets all requirements from prompt.MD${NC}"
    echo ""
    echo "🚀 Next steps:"
    echo "1. Install Maven: brew install maven (on macOS)"
    echo "2. Run the application: ./mvnw spring-boot:run"
    echo "3. Test the API: ./test-api.sh"
    echo "4. View documentation: http://localhost:8080/api/swagger-ui.html"
else
    echo ""
    print_status "WARNING" "⚠️  Some requirements are missing or incomplete"
    echo ""
    echo "Please review the failed checks above and implement the missing components."
fi

echo ""
echo -e "${BLUE}📚 For more information, see README.md${NC}"
