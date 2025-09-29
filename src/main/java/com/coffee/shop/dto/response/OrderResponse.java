package com.coffee.shop.dto.response;

import com.coffee.shop.entity.Order;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class OrderResponse {

    private String id;
    private String customerId;
    private String customerName;
    private String shopId;
    private String shopName;
    private Order.OrderStatus status;
    private BigDecimal subtotal;
    private BigDecimal taxAmount;
    private BigDecimal totalAmount;
    private String specialInstructions;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
    private LocalDateTime estimatedReadyTime;
    private LocalDateTime completedAt;
    private String cancellationReason;
    private List<OrderItemResponse> items;
    private QueuePositionResponse queuePosition;
}

