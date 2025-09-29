package com.coffee.shop.dto.request;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CreateOrderRequest {

    @NotNull(message = "Shop ID is required")
    private String shopId;

    @NotEmpty(message = "Order items are required")
    @Valid
    private List<OrderItemRequest> items;

    private String specialInstructions;
}
