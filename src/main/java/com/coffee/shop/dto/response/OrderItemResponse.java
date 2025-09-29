package com.coffee.shop.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class OrderItemResponse {

    private String id;
    private String menuItemId;
    private String menuItemName;
    private String menuItemDescription;
    private String category;
    private Integer quantity;
    private BigDecimal unitPrice;
    private BigDecimal totalPrice;
    private String specialInstructions;
    private String imageUrl;
    private Integer preparationTimeMinutes;
}

