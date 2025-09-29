package com.coffee.shop.controller;

import com.coffee.shop.dto.request.CreateOrderRequest;
import com.coffee.shop.dto.response.OrderResponse;
import com.coffee.shop.service.OrderProcessingService;
import com.coffee.shop.repository.OrderRepository;
import com.coffee.shop.entity.Order;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/orders")
@RequiredArgsConstructor
@Slf4j
@Tag(name = "Order Management", description = "APIs for managing coffee shop orders")
public class OrderController {

    private final OrderProcessingService orderProcessingService;
    private final OrderRepository orderRepository;

    @PostMapping
    @Operation(summary = "Create a new order", description = "Creates a new order for the authenticated customer")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "201", description = "Order created successfully"),
            @ApiResponse(responseCode = "400", description = "Invalid request data"),
            @ApiResponse(responseCode = "404", description = "Shop or menu items not found"),
            @ApiResponse(responseCode = "409", description = "Business logic error")
    })
    public ResponseEntity<OrderResponse> createOrder(
            @Valid @RequestBody CreateOrderRequest request,
            Authentication authentication) {
        
        log.info("Creating order for customer: {}", authentication.getName());
        
        UUID customerId = UUID.fromString(authentication.getName());
        OrderResponse orderResponse = orderProcessingService.processOrder(request, customerId);
        
        return ResponseEntity.status(HttpStatus.CREATED).body(orderResponse);
    }

    @GetMapping
    @Operation(summary = "Get customer orders", description = "Retrieves all orders for the authenticated customer")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Orders retrieved successfully")
    })
    public ResponseEntity<List<OrderResponse>> getCustomerOrders(Authentication authentication) {
        
        log.info("Retrieving orders for customer: {}", authentication.getName());
        
        UUID customerId = UUID.fromString(authentication.getName());
        List<Order> orders = orderRepository.findByCustomerIdOrderByCreatedAtDesc(customerId);
        
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

    @GetMapping("/{orderId}")
    @Operation(summary = "Get order details", description = "Retrieves details of a specific order")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Order retrieved successfully"),
            @ApiResponse(responseCode = "404", description = "Order not found")
    })
    public ResponseEntity<OrderResponse> getOrder(
            @Parameter(description = "Order ID") @PathVariable UUID orderId) {
        
        log.info("Retrieving order: {}", orderId);
        
        OrderResponse orderResponse = orderProcessingService.getOrder(orderId);
        return ResponseEntity.ok(orderResponse);
    }

    @PutMapping("/{orderId}/cancel")
    @Operation(summary = "Cancel an order", description = "Cancels an existing order")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Order cancelled successfully"),
            @ApiResponse(responseCode = "400", description = "Order cannot be cancelled"),
            @ApiResponse(responseCode = "404", description = "Order not found")
    })
    public ResponseEntity<OrderResponse> cancelOrder(
            @Parameter(description = "Order ID") @PathVariable UUID orderId,
            Authentication authentication) {
        
        log.info("Cancelling order: {} for customer: {}", orderId, authentication.getName());
        
        UUID customerId = UUID.fromString(authentication.getName());
        OrderResponse orderResponse = orderProcessingService.cancelOrder(orderId, customerId);
        
        return ResponseEntity.ok(orderResponse);
    }
}
