package com.coffee.shop.controller;

import com.coffee.shop.entity.MenuItem;
import com.coffee.shop.entity.Shop;
import com.coffee.shop.repository.MenuItemRepository;
import com.coffee.shop.repository.ShopRepository;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/menu")
@RequiredArgsConstructor
@Slf4j
@Tag(name = "Menu Management", description = "APIs for managing menu items")
public class MenuController {

    private final MenuItemRepository menuItemRepository;
    private final ShopRepository shopRepository;

    @GetMapping("/shop/{shopId}")
    @Operation(summary = "Get shop menu", description = "Retrieves all menu items for a specific shop")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Menu items retrieved successfully"),
            @ApiResponse(responseCode = "404", description = "Shop not found")
    })
    public ResponseEntity<List<MenuItem>> getShopMenu(
            @Parameter(description = "Shop ID") @PathVariable UUID shopId) {
        
        log.info("Retrieving menu for shop: {}", shopId);
        
        List<MenuItem> menuItems = menuItemRepository.findAllByShopIdOrderBySortOrderAndName(shopId);
        
        return ResponseEntity.ok(menuItems);
    }

    @GetMapping("/shop/{shopId}/category/{category}")
    @Operation(summary = "Get menu items by category", description = "Retrieves menu items for a specific shop and category")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Menu items retrieved successfully"),
            @ApiResponse(responseCode = "404", description = "Shop not found")
    })
    public ResponseEntity<List<MenuItem>> getMenuItemsByCategory(
            @Parameter(description = "Shop ID") @PathVariable UUID shopId,
            @Parameter(description = "Category") @PathVariable String category) {
        
        log.info("Retrieving menu items for shop: {} and category: {}", shopId, category);
        
        List<MenuItem> menuItems = menuItemRepository.findByShopIdAndCategoryAndIsAvailableTrue(shopId, category);
        
        return ResponseEntity.ok(menuItems);
    }

    @PostMapping("/shop/{shopId}")
    @Operation(summary = "Create menu item", description = "Creates a new menu item for a shop")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "201", description = "Menu item created successfully"),
            @ApiResponse(responseCode = "400", description = "Invalid request data"),
            @ApiResponse(responseCode = "404", description = "Shop not found")
    })
    public ResponseEntity<MenuItem> createMenuItem(
            @Parameter(description = "Shop ID") @PathVariable UUID shopId,
            @RequestBody Map<String, Object> menuItemData) {
        
        log.info("Creating menu item for shop: {}", shopId);
        
        // Verify shop exists
        Shop shop = shopRepository.findById(shopId)
                .orElseThrow(() -> new IllegalArgumentException("Shop not found"));
        
        // Create menu item
        MenuItem menuItem = MenuItem.builder()
                .name((String) menuItemData.get("name"))
                .description((String) menuItemData.get("description"))
                .price(BigDecimal.valueOf(((Number) menuItemData.get("price")).doubleValue()))
                .category((String) menuItemData.get("category"))
                .isAvailable((Boolean) menuItemData.getOrDefault("isAvailable", true))
                .preparationTimeMinutes(((Number) menuItemData.getOrDefault("preparationTimeMinutes", 0)).intValue())
                .shop(shop)
                .build();
        
        MenuItem savedMenuItem = menuItemRepository.save(menuItem);
        
        return ResponseEntity.ok(savedMenuItem);
    }
}
