#!/bin/bash

# Coffee Shop API - Test Data Setup Script
# This script creates comprehensive test data for E2E testing

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
BASE_URL="http://localhost:8080/api"
ADMIN_MOBILE="+1111111111"
ADMIN_PASSWORD="admin123"
SHOP_OWNER_MOBILE="+2222222222"
SHOP_OWNER_PASSWORD="owner123"
CUSTOMER_MOBILE="+3333333333"
CUSTOMER_PASSWORD="customer123"

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

# Function to extract ID from response
extract_id() {
    echo "$1" | grep -o '"id":"[^"]*"' | cut -d'"' -f4
}

echo -e "${BLUE}🚀 Setting up Coffee Shop API Test Data${NC}"
echo "=============================================="

# Step 1: Create Admin User
print_status "INFO" "Creating admin user..."
admin_data='{
    "mobileNumber": "'$ADMIN_MOBILE'",
    "password": "'$ADMIN_PASSWORD'",
    "name": "Admin User",
    "email": "admin@coffeeshop.com"
}'

admin_response=$(make_request "POST" "$BASE_URL/auth/register" "$admin_data")
if echo "$admin_response" | grep -q "token"; then
    print_status "SUCCESS" "Admin user created successfully"
    ADMIN_TOKEN=$(extract_token "$admin_response")
    ADMIN_ID=$(extract_id "$admin_response")
else
    print_status "WARNING" "Admin user might already exist, attempting login..."
    login_data='{
        "mobileNumber": "'$ADMIN_MOBILE'",
        "password": "'$ADMIN_PASSWORD'"
    }'
    login_response=$(make_request "POST" "$BASE_URL/auth/login" "$login_data")
    if echo "$login_response" | grep -q "token"; then
        print_status "SUCCESS" "Admin login successful"
        ADMIN_TOKEN=$(extract_token "$login_response")
        ADMIN_ID=$(extract_id "$login_response")
    else
        print_status "ERROR" "Failed to create or login admin user"
        echo "Response: $admin_response"
        exit 1
    fi
fi

# Step 2: Create Shop Owner User
print_status "INFO" "Creating shop owner user..."
owner_data='{
    "mobileNumber": "'$SHOP_OWNER_MOBILE'",
    "password": "'$SHOP_OWNER_PASSWORD'",
    "name": "Shop Owner",
    "email": "owner@coffeeshop.com"
}'

owner_response=$(make_request "POST" "$BASE_URL/auth/register" "$owner_data")
if echo "$owner_response" | grep -q "token"; then
    print_status "SUCCESS" "Shop owner user created successfully"
    OWNER_TOKEN=$(extract_token "$owner_response")
    OWNER_ID=$(extract_id "$owner_response")
else
    print_status "WARNING" "Shop owner might already exist, attempting login..."
    login_data='{
        "mobileNumber": "'$SHOP_OWNER_MOBILE'",
        "password": "'$SHOP_OWNER_PASSWORD'"
    }'
    login_response=$(make_request "POST" "$BASE_URL/auth/login" "$login_data")
    if echo "$login_response" | grep -q "token"; then
        print_status "SUCCESS" "Shop owner login successful"
        OWNER_TOKEN=$(extract_token "$login_response")
        OWNER_ID=$(extract_id "$login_response")
    else
        print_status "ERROR" "Failed to create or login shop owner"
        echo "Response: $owner_response"
        exit 1
    fi
fi

# Step 3: Create Customer User
print_status "INFO" "Creating customer user..."
customer_data='{
    "mobileNumber": "'$CUSTOMER_MOBILE'",
    "password": "'$CUSTOMER_PASSWORD'",
    "name": "Test Customer",
    "email": "customer@coffeeshop.com"
}'

customer_response=$(make_request "POST" "$BASE_URL/auth/register" "$customer_data")
if echo "$customer_response" | grep -q "token"; then
    print_status "SUCCESS" "Customer user created successfully"
    CUSTOMER_TOKEN=$(extract_token "$customer_response")
    CUSTOMER_ID=$(extract_id "$customer_response")
else
    print_status "WARNING" "Customer might already exist, attempting login..."
    login_data='{
        "mobileNumber": "'$CUSTOMER_MOBILE'",
        "password": "'$CUSTOMER_PASSWORD'"
    }'
    login_response=$(make_request "POST" "$BASE_URL/auth/login" "$login_data")
    if echo "$login_response" | grep -q "token"; then
        print_status "SUCCESS" "Customer login successful"
        CUSTOMER_TOKEN=$(extract_token "$login_response")
        CUSTOMER_ID=$(extract_id "$login_response")
    else
        print_status "ERROR" "Failed to create or login customer"
        echo "Response: $customer_response"
        exit 1
    fi
fi

# Step 4: Create Coffee Shops
print_status "INFO" "Creating coffee shops..."

# Shop 1: Coffee Corner (New York)
shop1_data='{
    "name": "Coffee Corner",
    "description": "A cozy coffee shop in the heart of New York",
    "latitude": 40.7128,
    "longitude": -74.0060,
    "address": "123 Broadway, New York, NY 10001",
    "contactDetails": {
        "phone": "+1-555-0101",
        "email": "info@coffeecorner.com"
    },
    "queueConfiguration": {
        "maxQueueSize": 50,
        "averageServiceTime": 300
    }
}'

shop1_response=$(make_request "POST" "$BASE_URL/shops" "$shop1_data" "Authorization: Bearer $OWNER_TOKEN")
if echo "$shop1_response" | grep -q "id"; then
    print_status "SUCCESS" "Coffee Corner shop created"
    SHOP1_ID=$(extract_id "$shop1_response")
else
    print_status "ERROR" "Failed to create Coffee Corner shop"
    echo "Response: $shop1_response"
fi

# Shop 2: Java Junction (San Francisco)
shop2_data='{
    "name": "Java Junction",
    "description": "Premium coffee and pastries in San Francisco",
    "latitude": 37.7749,
    "longitude": -122.4194,
    "address": "456 Market St, San Francisco, CA 94102",
    "contactDetails": {
        "phone": "+1-555-0202",
        "email": "hello@javajunction.com"
    },
    "queueConfiguration": {
        "maxQueueSize": 30,
        "averageServiceTime": 240
    }
}'

shop2_response=$(make_request "POST" "$BASE_URL/shops" "$shop2_data" "Authorization: Bearer $OWNER_TOKEN")
if echo "$shop2_response" | grep -q "id"; then
    print_status "SUCCESS" "Java Junction shop created"
    SHOP2_ID=$(extract_id "$shop2_response")
else
    print_status "ERROR" "Failed to create Java Junction shop"
    echo "Response: $shop2_response"
fi

# Step 5: Create Menu Items for Shop 1
print_status "INFO" "Creating menu items for Coffee Corner..."

# Espresso
espresso_data='{
    "name": "Espresso",
    "description": "Rich, full-bodied espresso shot",
    "price": 2.50,
    "category": "COFFEE",
    "isAvailable": true,
    "preparationTime": 120
}'

espresso_response=$(make_request "POST" "$BASE_URL/menu/shop/$SHOP1_ID" "$espresso_data" "Authorization: Bearer $OWNER_TOKEN")
if echo "$espresso_response" | grep -q "id"; then
    print_status "SUCCESS" "Espresso added to menu"
    ESPRESSO_ID=$(extract_id "$espresso_response")
else
    print_status "ERROR" "Failed to add Espresso to menu"
    echo "Response: $espresso_response"
fi

# Cappuccino
cappuccino_data='{
    "name": "Cappuccino",
    "description": "Espresso with steamed milk and foam",
    "price": 4.00,
    "category": "COFFEE",
    "isAvailable": true,
    "preparationTime": 180
}'

cappuccino_response=$(make_request "POST" "$BASE_URL/menu/shop/$SHOP1_ID" "$cappuccino_data" "Authorization: Bearer $OWNER_TOKEN")
if echo "$cappuccino_response" | grep -q "id"; then
    print_status "SUCCESS" "Cappuccino added to menu"
    CAPPUCCINO_ID=$(extract_id "$cappuccino_response")
else
    print_status "ERROR" "Failed to add Cappuccino to menu"
    echo "Response: $cappuccino_response"
fi

# Latte
latte_data='{
    "name": "Latte",
    "description": "Espresso with steamed milk",
    "price": 4.50,
    "category": "COFFEE",
    "isAvailable": true,
    "preparationTime": 200
}'

latte_response=$(make_request "POST" "$BASE_URL/menu/shop/$SHOP1_ID" "$latte_data" "Authorization: Bearer $OWNER_TOKEN")
if echo "$latte_response" | grep -q "id"; then
    print_status "SUCCESS" "Latte added to menu"
    LATTE_ID=$(extract_id "$latte_response")
else
    print_status "ERROR" "Failed to add Latte to menu"
    echo "Response: $latte_response"
fi

# Croissant
croissant_data='{
    "name": "Butter Croissant",
    "description": "Freshly baked buttery croissant",
    "price": 3.50,
    "category": "PASTRY",
    "isAvailable": true,
    "preparationTime": 60
}'

croissant_response=$(make_request "POST" "$BASE_URL/menu/shop/$SHOP1_ID" "$croissant_data" "Authorization: Bearer $OWNER_TOKEN")
if echo "$croissant_response" | grep -q "id"; then
    print_status "SUCCESS" "Butter Croissant added to menu"
    CROISSANT_ID=$(extract_id "$croissant_response")
else
    print_status "ERROR" "Failed to add Butter Croissant to menu"
    echo "Response: $croissant_response"
fi

# Step 6: Create Menu Items for Shop 2
print_status "INFO" "Creating menu items for Java Junction..."

# Cold Brew
coldbrew_data='{
    "name": "Cold Brew",
    "description": "Smooth cold-brewed coffee",
    "price": 3.75,
    "category": "COFFEE",
    "isAvailable": true,
    "preparationTime": 90
}'

coldbrew_response=$(make_request "POST" "$BASE_URL/menu/shop/$SHOP2_ID" "$coldbrew_data" "Authorization: Bearer $OWNER_TOKEN")
if echo "$coldbrew_response" | grep -q "id"; then
    print_status "SUCCESS" "Cold Brew added to menu"
    COLDBREW_ID=$(extract_id "$coldbrew_response")
else
    print_status "ERROR" "Failed to add Cold Brew to menu"
    echo "Response: $coldbrew_response"
fi

# Muffin
muffin_data='{
    "name": "Blueberry Muffin",
    "description": "Fresh blueberry muffin",
    "price": 2.95,
    "category": "PASTRY",
    "isAvailable": true,
    "preparationTime": 30
}'

muffin_response=$(make_request "POST" "$BASE_URL/menu/shop/$SHOP2_ID" "$muffin_data" "Authorization: Bearer $OWNER_TOKEN")
if echo "$muffin_response" | grep -q "id"; then
    print_status "SUCCESS" "Blueberry Muffin added to menu"
    MUFFIN_ID=$(extract_id "$muffin_response")
else
    print_status "ERROR" "Failed to add Blueberry Muffin to menu"
    echo "Response: $muffin_response"
fi

# Step 7: Set Operating Hours
print_status "INFO" "Setting operating hours for shops..."

# Coffee Corner hours
hours1_data='{
    "dayOfWeek": "MONDAY",
    "openTime": "07:00",
    "closeTime": "19:00"
}'

hours1_response=$(make_request "POST" "$BASE_URL/shops/$SHOP1_ID/hours" "$hours1_data" "Authorization: Bearer $OWNER_TOKEN")
if echo "$hours1_response" | grep -q "id"; then
    print_status "SUCCESS" "Monday hours set for Coffee Corner"
else
    print_status "WARNING" "Failed to set Monday hours for Coffee Corner"
fi

# Java Junction hours
hours2_data='{
    "dayOfWeek": "MONDAY",
    "openTime": "06:30",
    "closeTime": "20:00"
}'

hours2_response=$(make_request "POST" "$BASE_URL/shops/$SHOP2_ID/hours" "$hours2_data" "Authorization: Bearer $OWNER_TOKEN")
if echo "$hours2_response" | grep -q "id"; then
    print_status "SUCCESS" "Monday hours set for Java Junction"
else
    print_status "WARNING" "Failed to set Monday hours for Java Junction"
fi

# Save test data to file for E2E tests
cat > test-data.env << EOF
# Test Data Configuration
ADMIN_TOKEN=$ADMIN_TOKEN
ADMIN_ID=$ADMIN_ID
OWNER_TOKEN=$OWNER_TOKEN
OWNER_ID=$OWNER_ID
CUSTOMER_TOKEN=$CUSTOMER_TOKEN
CUSTOMER_ID=$CUSTOMER_ID
SHOP1_ID=$SHOP1_ID
SHOP2_ID=$SHOP2_ID
ESPRESSO_ID=$ESPRESSO_ID
CAPPUCCINO_ID=$CAPPUCCINO_ID
LATTE_ID=$LATTE_ID
CROISSANT_ID=$CROISSANT_ID
COLDBREW_ID=$COLDBREW_ID
MUFFIN_ID=$MUFFIN_ID
EOF

echo ""
echo -e "${GREEN}🎉 Test Data Setup Complete!${NC}"
echo "=============================================="
echo -e "${BLUE}ℹ${NC} Test data saved to test-data.env"
echo -e "${BLUE}ℹ${NC} You can now run E2E tests with: ./run-e2e-tests.sh"
echo ""
echo -e "${GREEN}✅ Created Users:${NC}"
echo "  - Admin: $ADMIN_MOBILE"
echo "  - Shop Owner: $SHOP_OWNER_MOBILE" 
echo "  - Customer: $CUSTOMER_MOBILE"
echo ""
echo -e "${GREEN}✅ Created Shops:${NC}"
echo "  - Coffee Corner (NYC): $SHOP1_ID"
echo "  - Java Junction (SF): $SHOP2_ID"
echo ""
echo -e "${GREEN}✅ Created Menu Items:${NC}"
echo "  - Coffee Corner: Espresso, Cappuccino, Latte, Croissant"
echo "  - Java Junction: Cold Brew, Blueberry Muffin"
