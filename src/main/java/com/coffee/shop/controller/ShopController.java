package com.coffee.shop.controller;

import com.coffee.shop.entity.Shop;
import com.coffee.shop.entity.User;
import com.coffee.shop.entity.Order;
import com.coffee.shop.repository.ShopRepository;
import com.coffee.shop.repository.UserRepository;
import com.coffee.shop.repository.OrderRepository;
import com.coffee.shop.service.OrderProcessingService;
import com.coffee.shop.dto.response.OrderResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/shops")
@RequiredArgsConstructor
@Slf4j
@Tag(name = "Shop Management", description = "APIs for managing coffee shops")
public class ShopController {

    private final ShopRepository shopRepository;
    private final UserRepository userRepository;
    private final OrderRepository orderRepository;
    private final OrderProcessingService orderProcessingService;

    @GetMapping("/nearby")
    @Operation(summary = "Find nearby shops", description = "Finds shops within a specified radius")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Shops retrieved successfully"),
            @ApiResponse(responseCode = "400", description = "Invalid parameters")
    })
    public ResponseEntity<List<Shop>> findNearbyShops(
            @Parameter(description = "Latitude") @RequestParam Double latitude,
            @Parameter(description = "Longitude") @RequestParam Double longitude,
            @Parameter(description = "Radius in meters") @RequestParam(defaultValue = "1000") Double radius) {
        
        log.info("Finding nearby shops for lat: {}, lng: {}, radius: {}", latitude, longitude, radius);
        
        List<Shop> shops = shopRepository.findNearbyShopsUsingDWithin(latitude, longitude, radius);
        
        return ResponseEntity.ok(shops);
    }

    @GetMapping("/{shopId}")
    @Operation(summary = "Get shop details", description = "Retrieves details of a specific shop")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Shop retrieved successfully"),
            @ApiResponse(responseCode = "404", description = "Shop not found")
    })
    public ResponseEntity<Shop> getShop(
            @Parameter(description = "Shop ID") @PathVariable UUID shopId) {
        
        log.info("Retrieving shop: {}", shopId);
        
        Shop shop = shopRepository.findById(shopId)
                .orElseThrow(() -> new IllegalArgumentException("Shop not found"));
        
        return ResponseEntity.ok(shop);
    }

    @GetMapping
    @Operation(summary = "Get all shops", description = "Retrieves all active shops")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Shops retrieved successfully")
    })
    public ResponseEntity<List<Shop>> getAllShops() {
        log.info("Retrieving all shops");
        
        List<Shop> shops = shopRepository.findAll();
        return ResponseEntity.ok(shops);
    }

    @PostMapping
    @Operation(summary = "Create shop", description = "Creates a new coffee shop")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "201", description = "Shop created successfully"),
            @ApiResponse(responseCode = "400", description = "Invalid request data")
    })
    public ResponseEntity<Shop> createShop(@RequestBody Map<String, Object> shopData, Authentication authentication) {
        log.info("Creating new shop: {}", shopData.get("name"));
        
        // Get current user
        String username = authentication.getName();
        User owner = userRepository.findById(UUID.fromString(username))
                .orElseThrow(() -> new IllegalArgumentException("User not found"));
        
        // Create shop
        Map<String, Object> contactDetailsMap = (Map<String, Object>) shopData.get("contactDetails");
        Map<String, Object> queueConfigMap = (Map<String, Object>) shopData.get("queueConfiguration");
        
        Shop.ContactDetails contactDetails = Shop.ContactDetails.builder()
                .phone((String) contactDetailsMap.get("phone"))
                .email((String) contactDetailsMap.get("email"))
                .website((String) contactDetailsMap.get("website"))
                .build();
        
        Shop.QueueConfiguration queueConfiguration = Shop.QueueConfiguration.builder()
                .maxQueueSize(((Number) queueConfigMap.get("maxQueueSize")).intValue())
                .averageServiceTimeMinutes(((Number) queueConfigMap.get("averageServiceTime")).intValue())
                .allowOnlineOrders((Boolean) queueConfigMap.getOrDefault("allowOnlineOrders", true))
                .allowWalkInOrders((Boolean) queueConfigMap.getOrDefault("allowWalkInOrders", true))
                .build();
        
        Shop shop = Shop.builder()
                .name((String) shopData.get("name"))
                .description((String) shopData.get("description"))
                .owner(owner)
                .latitude(((Number) shopData.get("latitude")).doubleValue())
                .longitude(((Number) shopData.get("longitude")).doubleValue())
                .address((String) shopData.get("address"))
                .contactDetails(contactDetails)
                .queueConfiguration(queueConfiguration)
                .isActive(true)
                .build();
        
        Shop savedShop = shopRepository.save(shop);
        
        return ResponseEntity.ok(savedShop);
    }

    @GetMapping("/{shopId}/orders")
    @Operation(summary = "Get shop orders", description = "Retrieves all orders for a specific shop")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Shop orders retrieved successfully"),
            @ApiResponse(responseCode = "404", description = "Shop not found")
    })
    public ResponseEntity<List<OrderResponse>> getShopOrders(
            @Parameter(description = "Shop ID") @PathVariable UUID shopId,
            Authentication authentication) {

        log.info("Retrieving orders for shop: {} by user: {}", shopId, authentication.getName());

        // Verify shop exists
        Shop shop = shopRepository.findById(shopId)
                .orElseThrow(() -> new IllegalArgumentException("Shop not found"));

        // Get orders for the shop
        List<Order> orders = orderRepository.findByShopIdOrderByCreatedAtDesc(shopId);
        
        List<OrderResponse> orderResponses = orders.stream()
                .map(order -> {
                    try {
                        return orderProcessingService.getOrder(order.getId());
                    } catch (Exception e) {
                        log.error("Error building order response for order {}: {}", order.getId(), e.getMessage());
                        return null;
                    }
                })
                .filter(response -> response != null)
                .collect(Collectors.toList());

        return ResponseEntity.ok(orderResponses);
    }
}
