package com.coffee.shop.service;

import com.coffee.shop.dto.request.CreateOrderRequest;
import com.coffee.shop.dto.request.OrderItemRequest;
import com.coffee.shop.dto.response.OrderResponse;
import com.coffee.shop.dto.response.QueuePositionResponse;
import com.coffee.shop.entity.*;
import com.coffee.shop.repository.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.modelmapper.ModelMapper;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
@Transactional
public class OrderProcessingService {

    private final OrderRepository orderRepository;
    private final OrderItemRepository orderItemRepository;
    private final UserRepository userRepository;
    private final ShopRepository shopRepository;
    private final MenuItemRepository menuItemRepository;
    private final QueueManagementService queueManagementService;
    private final ModelMapper modelMapper;

    private static final BigDecimal TAX_RATE = new BigDecimal("0.08"); // 8% tax rate

    public OrderResponse processOrder(CreateOrderRequest request, UUID customerId) {
        log.info("Processing order for customer {} at shop {}", customerId, request.getShopId());

        // Validate customer
        User customer = userRepository.findById(customerId)
                .orElseThrow(() -> new IllegalArgumentException("Customer not found"));

        // Validate shop
        Shop shop = shopRepository.findById(UUID.fromString(request.getShopId()))
                .orElseThrow(() -> new IllegalArgumentException("Shop not found"));

        if (!shop.getIsActive()) {
            throw new IllegalStateException("Shop is not currently active");
        }

        // Validate and process menu items
        List<OrderItem> orderItems = validateAndCreateOrderItems(request.getItems(), shop.getId());
        
        // Calculate totals
        BigDecimal subtotal = calculateSubtotal(orderItems);
        BigDecimal taxAmount = calculateTax(subtotal);
        BigDecimal totalAmount = subtotal.add(taxAmount);

        // Calculate estimated preparation time
        int estimatedPreparationTime = calculateEstimatedPreparationTime(orderItems);

        // Create order
        Order order = Order.builder()
                .customer(customer)
                .shop(shop)
                .status(Order.OrderStatus.PENDING)
                .subtotal(subtotal)
                .taxAmount(taxAmount)
                .totalAmount(totalAmount)
                .specialInstructions(request.getSpecialInstructions())
                .createdAt(LocalDateTime.now())
                .estimatedReadyTime(LocalDateTime.now().plusMinutes(estimatedPreparationTime))
                .build();

        Order savedOrder = orderRepository.save(order);

        // Create order items
        for (OrderItem orderItem : orderItems) {
            orderItem.setOrder(savedOrder);
            orderItemRepository.save(orderItem);
        }

        // Add to queue
        QueueEntry queueEntry = queueManagementService.addToQueue(shop, customer, savedOrder);

        // Update order status to confirmed
        savedOrder.setStatus(Order.OrderStatus.CONFIRMED);
        savedOrder.setUpdatedAt(LocalDateTime.now());
        orderRepository.save(savedOrder);

        log.info("Order {} created successfully for customer {} at shop {}", 
                savedOrder.getId(), customerId, shop.getId());

        return buildOrderResponse(savedOrder, queueEntry);
    }

    public OrderResponse getOrder(UUID orderId) {
        log.info("Retrieving order {}", orderId);
        
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new IllegalArgumentException("Order not found"));

        QueueEntry queueEntry = queueManagementService.getQueueForShop(order.getShop().getId())
                .stream()
                .filter(entry -> entry.getOrder().getId().equals(orderId))
                .findFirst()
                .orElse(null);

        return buildOrderResponse(order, queueEntry);
    }

    public OrderResponse cancelOrder(UUID orderId, UUID customerId) {
        log.info("Cancelling order {} for customer {}", orderId, customerId);
        
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new IllegalArgumentException("Order not found"));

        if (!order.getCustomer().getId().equals(customerId)) {
            throw new IllegalStateException("Order does not belong to this customer");
        }

        if (order.getStatus() == Order.OrderStatus.COMPLETED) {
            throw new IllegalStateException("Cannot cancel completed order");
        }

        if (order.getStatus() == Order.OrderStatus.CANCELLED) {
            throw new IllegalStateException("Order is already cancelled");
        }

        // Remove from queue if exists
        QueueEntry queueEntry = queueManagementService.getQueueForShop(order.getShop().getId())
                .stream()
                .filter(entry -> entry.getOrder().getId().equals(orderId))
                .findFirst()
                .orElse(null);

        if (queueEntry != null) {
            queueManagementService.removeFromQueue(queueEntry.getId());
        }

        // Update order status
        order.setStatus(Order.OrderStatus.CANCELLED);
        order.setCancellationReason("Cancelled by customer");
        order.setUpdatedAt(LocalDateTime.now());
        orderRepository.save(order);

        log.info("Order {} cancelled successfully", orderId);

        return buildOrderResponse(order, null);
    }

    private List<OrderItem> validateAndCreateOrderItems(List<OrderItemRequest> itemRequests, UUID shopId) {
        return itemRequests.stream()
                .map(itemRequest -> {
                    MenuItem menuItem = menuItemRepository.findById(UUID.fromString(itemRequest.getMenuItemId()))
                            .orElseThrow(() -> new IllegalArgumentException("Menu item not found: " + itemRequest.getMenuItemId()));

                    if (!menuItem.getShop().getId().equals(shopId)) {
                        throw new IllegalArgumentException("Menu item does not belong to this shop");
                    }

                    if (!menuItem.getIsAvailable()) {
                        throw new IllegalStateException("Menu item is not available: " + menuItem.getName());
                    }

                    BigDecimal totalPrice = menuItem.getPrice().multiply(BigDecimal.valueOf(itemRequest.getQuantity()));

                    return OrderItem.builder()
                            .menuItem(menuItem)
                            .quantity(itemRequest.getQuantity())
                            .unitPrice(menuItem.getPrice())
                            .totalPrice(totalPrice)
                            .specialInstructions(itemRequest.getSpecialInstructions())
                            .build();
                })
                .collect(Collectors.toList());
    }

    private BigDecimal calculateSubtotal(List<OrderItem> orderItems) {
        return orderItems.stream()
                .map(OrderItem::getTotalPrice)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
    }

    private BigDecimal calculateTax(BigDecimal subtotal) {
        return subtotal.multiply(TAX_RATE).setScale(2, RoundingMode.HALF_UP);
    }

    private int calculateEstimatedPreparationTime(List<OrderItem> orderItems) {
        return orderItems.stream()
                .mapToInt(item -> item.getMenuItem().getPreparationTimeMinutes() * item.getQuantity())
                .sum();
    }

    private OrderResponse buildOrderResponse(Order order, QueueEntry queueEntry) {
        OrderResponse.OrderResponseBuilder responseBuilder = OrderResponse.builder()
                .id(order.getId().toString())
                .customerId(order.getCustomer().getId().toString())
                .customerName(order.getCustomer().getName())
                .shopId(order.getShop().getId().toString())
                .shopName(order.getShop().getName())
                .status(order.getStatus())
                .subtotal(order.getSubtotal())
                .taxAmount(order.getTaxAmount())
                .totalAmount(order.getTotalAmount())
                .specialInstructions(order.getSpecialInstructions())
                .createdAt(order.getCreatedAt())
                .updatedAt(order.getUpdatedAt())
                .estimatedReadyTime(order.getEstimatedReadyTime())
                .completedAt(order.getCompletedAt())
                .cancellationReason(order.getCancellationReason())
                .items(order.getItems() != null ? order.getItems().stream()
                        .map(this::buildOrderItemResponse)
                        .collect(Collectors.toList()) : List.of());

        if (queueEntry != null) {
            QueuePositionResponse queuePosition = QueuePositionResponse.builder()
                    .queueEntryId(queueEntry.getId().toString())
                    .position(queueEntry.getPosition())
                    .totalWaiting(queueManagementService.getTotalWaitingCustomers(order.getShop().getId()).intValue())
                    .estimatedWaitTimeMinutes(queueManagementService.estimateWaitTime(order.getShop().getId(), queueEntry.getPosition()))
                    .status(queueEntry.getStatus().toString())
                    .notes(queueEntry.getNotes())
                    .build();
            responseBuilder.queuePosition(queuePosition);
        }

        return responseBuilder.build();
    }

    private com.coffee.shop.dto.response.OrderItemResponse buildOrderItemResponse(OrderItem orderItem) {
        return com.coffee.shop.dto.response.OrderItemResponse.builder()
                .id(orderItem.getId().toString())
                .menuItemId(orderItem.getMenuItem().getId().toString())
                .menuItemName(orderItem.getMenuItem().getName())
                .menuItemDescription(orderItem.getMenuItem().getDescription())
                .category(orderItem.getMenuItem().getCategory())
                .quantity(orderItem.getQuantity())
                .unitPrice(orderItem.getUnitPrice())
                .totalPrice(orderItem.getTotalPrice())
                .specialInstructions(orderItem.getSpecialInstructions())
                .imageUrl(orderItem.getMenuItem().getImageUrl())
                .preparationTimeMinutes(orderItem.getMenuItem().getPreparationTimeMinutes())
                .build();
    }
}
