#!/bin/bash

# Coffee Shop API Test Script
# This script tests the coffee shop API endpoints

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
BASE_URL="http://localhost:8080/api"
CUSTOMER_MOBILE="+1234567890"
CUSTOMER_PASSWORD="password123"
SHOP_ID="550e8400-e29b-41d4-a716-446655440003"

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

# Function to make HTTP requests
make_request() {
    local method=$1
    local url=$2
    local data=$3
    local headers=$4
    
    if [ -n "$data" ]; then
        curl -s -X $method "$url" \
            -H "Content-Type: application/json" \
            -H "$headers" \
            -d "$data"
    else
        curl -s -X $method "$url" \
            -H "Content-Type: application/json" \
            -H "$headers"
    fi
}

# Function to extract JWT token from response
extract_token() {
    echo "$1" | grep -o '"token":"[^"]*"' | cut -d'"' -f4
}

# Function to extract order ID from response
extract_order_id() {
    echo "$1" | grep -o '"id":"[^"]*"' | cut -d'"' -f4
}

echo -e "${BLUE}🚀 Starting Coffee Shop API Tests${NC}"
echo "=================================="

# Test 1: Health Check
print_status "INFO" "Testing health check..."
health_response=$(make_request "GET" "http://localhost:8080/actuator/health")
if echo "$health_response" | grep -q "UP"; then
    print_status "SUCCESS" "Health check passed"
else
    print_status "ERROR" "Health check failed"
    echo "Response: $health_response"
    exit 1
fi

# Test 2: Register Customer (if not exists)
print_status "INFO" "Testing customer registration..."
register_data='{
    "mobileNumber": "'$CUSTOMER_MOBILE'",
    "password": "'$CUSTOMER_PASSWORD'",
    "name": "Test Customer",
    "email": "test@example.com"
}'

register_response=$(make_request "POST" "$BASE_URL/auth/register" "$register_data")
if echo "$register_response" | grep -q "token"; then
    print_status "SUCCESS" "Customer registration successful"
    JWT_TOKEN=$(extract_token "$register_response")
elif echo "$register_response" | grep -q "already exists"; then
    print_status "WARNING" "Customer already exists, attempting login..."
    
    # Test 3: Login
    login_data='{
        "mobileNumber": "'$CUSTOMER_MOBILE'",
        "password": "'$CUSTOMER_PASSWORD'"
    }'
    
    login_response=$(make_request "POST" "$BASE_URL/auth/login" "$login_data")
    if echo "$login_response" | grep -q "token"; then
        print_status "SUCCESS" "Customer login successful"
        JWT_TOKEN=$(extract_token "$login_response")
    else
        print_status "ERROR" "Customer login failed"
        echo "Response: $login_response"
        exit 1
    fi
else
    print_status "ERROR" "Customer registration failed"
    echo "Response: $register_response"
    exit 1
fi

# Test 4: Find Nearby Shops
print_status "INFO" "Testing nearby shops search..."
shops_response=$(make_request "GET" "$BASE_URL/shops/nearby?latitude=40.7128&longitude=-74.0060&radius=1000" "" "Authorization: Bearer $JWT_TOKEN")
if echo "$shops_response" | grep -q "Coffee Corner"; then
    print_status "SUCCESS" "Found nearby shops"
else
    print_status "WARNING" "No nearby shops found or error occurred"
    echo "Response: $shops_response"
fi

# Test 5: Get Menu Items
print_status "INFO" "Testing menu items retrieval..."
menu_response=$(make_request "GET" "$BASE_URL/menu/shop/$SHOP_ID" "" "Authorization: Bearer $JWT_TOKEN")
if echo "$menu_response" | grep -q "Espresso"; then
    print_status "SUCCESS" "Retrieved menu items"
else
    print_status "WARNING" "No menu items found or error occurred"
    echo "Response: $menu_response"
fi

# Test 6: Create Order
print_status "INFO" "Testing order creation..."
order_data='{
    "shopId": "'$SHOP_ID'",
    "items": [
        {
            "menuItemId": "550e8400-e29b-41d4-a716-446655440004",
            "quantity": 2,
            "specialInstructions": "Extra hot"
        },
        {
            "menuItemId": "550e8400-e29b-41d4-a716-446655440005",
            "quantity": 1
        }
    ],
    "specialInstructions": "Please prepare quickly"
}'

order_response=$(make_request "POST" "$BASE_URL/orders" "$order_data" "Authorization: Bearer $JWT_TOKEN")
if echo "$order_response" | grep -q "id"; then
    print_status "SUCCESS" "Order created successfully"
    ORDER_ID=$(extract_order_id "$order_response")
    echo "Order ID: $ORDER_ID"
else
    print_status "ERROR" "Order creation failed"
    echo "Response: $order_response"
    exit 1
fi

# Test 7: Get Order Details
print_status "INFO" "Testing order retrieval..."
order_details=$(make_request "GET" "$BASE_URL/orders/$ORDER_ID" "" "Authorization: Bearer $JWT_TOKEN")
if echo "$order_details" | grep -q "Coffee Corner"; then
    print_status "SUCCESS" "Order details retrieved successfully"
else
    print_status "WARNING" "Order details retrieval failed"
    echo "Response: $order_details"
fi

# Test 8: Test Error Scenarios
print_status "INFO" "Testing error scenarios..."

# Test invalid order ID
invalid_order_response=$(make_request "GET" "$BASE_URL/orders/00000000-0000-0000-0000-000000000000" "" "Authorization: Bearer $JWT_TOKEN")
if echo "$invalid_order_response" | grep -q "not found"; then
    print_status "SUCCESS" "Invalid order ID handled correctly"
else
    print_status "WARNING" "Invalid order ID not handled as expected"
fi

# Test unauthorized access
unauthorized_response=$(make_request "GET" "$BASE_URL/orders/$ORDER_ID")
if echo "$unauthorized_response" | grep -q "Unauthorized\|401"; then
    print_status "SUCCESS" "Unauthorized access properly blocked"
else
    print_status "WARNING" "Unauthorized access not properly handled"
fi

# Test 9: Cancel Order (if supported)
print_status "INFO" "Testing order cancellation..."
cancel_response=$(make_request "PUT" "$BASE_URL/orders/$ORDER_ID/cancel" "" "Authorization: Bearer $JWT_TOKEN")
if echo "$cancel_response" | grep -q "CANCELLED"; then
    print_status "SUCCESS" "Order cancelled successfully"
else
    print_status "WARNING" "Order cancellation failed or not supported"
    echo "Response: $cancel_response"
fi

echo ""
echo -e "${GREEN}🎉 API Testing Complete!${NC}"
echo "=================================="
print_status "INFO" "All major API endpoints have been tested"
print_status "INFO" "Check the responses above for any issues"

# Optional: Test Swagger UI
print_status "INFO" "Swagger UI should be available at: http://localhost:8080/api/swagger-ui.html"
print_status "INFO" "API documentation at: http://localhost:8080/api/v3/api-docs"
