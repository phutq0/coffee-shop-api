package com.coffee.shop.integration;

import com.coffee.shop.CoffeeShopApiApplication;
import com.coffee.shop.dto.request.CreateOrderRequest;
import com.coffee.shop.dto.request.OrderItemRequest;
import com.coffee.shop.entity.*;
import com.coffee.shop.repository.*;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureWebMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

import java.math.BigDecimal;
import java.util.Arrays;
import java.util.UUID;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest(classes = CoffeeShopApiApplication.class)
@AutoConfigureWebMvc
@Testcontainers
@Transactional
class OrderProcessingIntegrationTest {

    @Container
    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:15-alpine")
            .withDatabaseName("coffeeshop_test")
            .withUsername("test")
            .withPassword("test");

    @DynamicPropertySource
    static void configureProperties(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", postgres::getJdbcUrl);
        registry.add("spring.datasource.username", postgres::getUsername);
        registry.add("spring.datasource.password", postgres::getPassword);
    }

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private ShopRepository shopRepository;

    @Autowired
    private MenuItemRepository menuItemRepository;

    @Autowired
    private OrderRepository orderRepository;

    @Autowired
    private QueueEntryRepository queueEntryRepository;

    private User customer;
    private Shop shop;
    private MenuItem menuItem1;
    private MenuItem menuItem2;

    @BeforeEach
    void setUp() {
        // Clean up test data
        queueEntryRepository.deleteAll();
        orderRepository.deleteAll();
        menuItemRepository.deleteAll();
        shopRepository.deleteAll();
        userRepository.deleteAll();

        // Create test customer
        customer = User.builder()
                .mobileNumber("+1234567890")
                .password("$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EHsM8lE9lBOsl7iKTVEFDi")
                .name("Test Customer")
                .email("test@example.com")
                .role(User.UserRole.CUSTOMER)
                .loyaltyScore(100)
                .build();
        customer = userRepository.save(customer);

        // Create shop owner
        User shopOwner = User.builder()
                .mobileNumber("+1234567891")
                .password("$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EHsM8lE9lBOsl7iKTVEFDi")
                .name("Shop Owner")
                .email("owner@example.com")
                .role(User.UserRole.SHOP_OWNER)
                .loyaltyScore(0)
                .build();
        shopOwner = userRepository.save(shopOwner);

        // Create test shop
        shop = Shop.builder()
                .name("Test Coffee Shop")
                .description("A test coffee shop")
                .owner(shopOwner)
                .latitude(40.7128)
                .longitude(-74.0060)
                .address("123 Test St")
                .isActive(true)
                .build();
        shop = shopRepository.save(shop);

        // Create test menu items
        menuItem1 = MenuItem.builder()
                .name("Espresso")
                .description("Rich espresso")
                .price(new BigDecimal("2.50"))
                .category("Coffee")
                .shop(shop)
                .isAvailable(true)
                .preparationTimeMinutes(3)
                .build();
        menuItem1 = menuItemRepository.save(menuItem1);

        menuItem2 = MenuItem.builder()
                .name("Cappuccino")
                .description("Espresso with milk")
                .price(new BigDecimal("3.50"))
                .category("Coffee")
                .shop(shop)
                .isAvailable(true)
                .preparationTimeMinutes(5)
                .build();
        menuItem2 = menuItemRepository.save(menuItem2);
    }

    @Test
    @WithMockUser(username = "550e8400-e29b-41d4-a716-446655440001")
    void testCreateOrder_Success() throws Exception {
        // Given
        CreateOrderRequest request = CreateOrderRequest.builder()
                .shopId(shop.getId().toString())
                .items(Arrays.asList(
                        OrderItemRequest.builder()
                                .menuItemId(menuItem1.getId().toString())
                                .quantity(2)
                                .specialInstructions("Extra hot")
                                .build(),
                        OrderItemRequest.builder()
                                .menuItemId(menuItem2.getId().toString())
                                .quantity(1)
                                .build()
                ))
                .specialInstructions("Please prepare quickly")
                .build();

        // When & Then
        mockMvc.perform(post("/api/orders")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.shopId").value(shop.getId().toString()))
                .andExpect(jsonPath("$.customerId").value(customer.getId().toString()))
                .andExpect(jsonPath("$.status").value("CONFIRMED"))
                .andExpect(jsonPath("$.items").isArray())
                .andExpect(jsonPath("$.items.length()").value(2))
                .andExpect(jsonPath("$.queuePosition").exists());
    }

    @Test
    @WithMockUser(username = "550e8400-e29b-41d4-a716-446655440001")
    void testCreateOrder_InvalidShop() throws Exception {
        // Given
        CreateOrderRequest request = CreateOrderRequest.builder()
                .shopId(UUID.randomUUID().toString())
                .items(Arrays.asList(
                        OrderItemRequest.builder()
                                .menuItemId(menuItem1.getId().toString())
                                .quantity(1)
                                .build()
                ))
                .build();

        // When & Then
        mockMvc.perform(post("/api/orders")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest());
    }

    @Test
    @WithMockUser(username = "550e8400-e29b-41d4-a716-446655440001")
    void testCreateOrder_InvalidMenuItem() throws Exception {
        // Given
        CreateOrderRequest request = CreateOrderRequest.builder()
                .shopId(shop.getId().toString())
                .items(Arrays.asList(
                        OrderItemRequest.builder()
                                .menuItemId(UUID.randomUUID().toString())
                                .quantity(1)
                                .build()
                ))
                .build();

        // When & Then
        mockMvc.perform(post("/api/orders")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest());
    }

    @Test
    @WithMockUser(username = "550e8400-e29b-41d4-a716-446655440001")
    void testCreateOrder_ValidationErrors() throws Exception {
        // Given
        CreateOrderRequest request = CreateOrderRequest.builder()
                .shopId("") // Invalid shop ID
                .items(Arrays.asList()) // Empty items
                .build();

        // When & Then
        mockMvc.perform(post("/api/orders")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.fieldErrors").exists());
    }

    @Test
    @WithMockUser(username = "550e8400-e29b-41d4-a716-446655440001")
    void testGetOrder_Success() throws Exception {
        // Given - Create an order first
        Order order = Order.builder()
                .customer(customer)
                .shop(shop)
                .status(Order.OrderStatus.CONFIRMED)
                .subtotal(new BigDecimal("8.50"))
                .taxAmount(new BigDecimal("0.68"))
                .totalAmount(new BigDecimal("9.18"))
                .build();
        order = orderRepository.save(order);

        // When & Then
        mockMvc.perform(get("/api/orders/{orderId}", order.getId()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(order.getId().toString()))
                .andExpect(jsonPath("$.shopId").value(shop.getId().toString()))
                .andExpect(jsonPath("$.customerId").value(customer.getId().toString()))
                .andExpect(jsonPath("$.status").value("CONFIRMED"));
    }

    @Test
    @WithMockUser(username = "550e8400-e29b-41d4-a716-446655440001")
    void testGetOrder_NotFound() throws Exception {
        // Given
        UUID nonExistentOrderId = UUID.randomUUID();

        // When & Then
        mockMvc.perform(get("/api/orders/{orderId}", nonExistentOrderId))
                .andExpect(status().isBadRequest());
    }

    @Test
    @WithMockUser(username = "550e8400-e29b-41d4-a716-446655440001")
    void testCancelOrder_Success() throws Exception {
        // Given - Create an order first
        Order order = Order.builder()
                .customer(customer)
                .shop(shop)
                .status(Order.OrderStatus.CONFIRMED)
                .subtotal(new BigDecimal("8.50"))
                .taxAmount(new BigDecimal("0.68"))
                .totalAmount(new BigDecimal("9.18"))
                .build();
        order = orderRepository.save(order);

        // When & Then
        mockMvc.perform(put("/api/orders/{orderId}/cancel", order.getId()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(order.getId().toString()))
                .andExpect(jsonPath("$.status").value("CANCELLED"));
    }

    @Test
    @WithMockUser(username = "550e8400-e29b-41d4-a716-446655440001")
    void testCancelOrder_NotFound() throws Exception {
        // Given
        UUID nonExistentOrderId = UUID.randomUUID();

        // When & Then
        mockMvc.perform(put("/api/orders/{orderId}/cancel", nonExistentOrderId))
                .andExpect(status().isBadRequest());
    }

    @Test
    void testUnauthorizedAccess() throws Exception {
        // Given
        CreateOrderRequest request = CreateOrderRequest.builder()
                .shopId(shop.getId().toString())
                .items(Arrays.asList(
                        OrderItemRequest.builder()
                                .menuItemId(menuItem1.getId().toString())
                                .quantity(1)
                                .build()
                ))
                .build();

        // When & Then
        mockMvc.perform(post("/api/orders")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void testHealthCheck() throws Exception {
        // When & Then
        mockMvc.perform(get("/api/actuator/health"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("UP"));
    }
}

