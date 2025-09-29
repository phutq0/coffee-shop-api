package com.coffee.shop.entity;

import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.*;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.util.UUID;

@Entity
@Table(name = "menu_items", indexes = {
    @Index(name = "idx_menu_item_shop", columnList = "shop_id"),
    @Index(name = "idx_menu_item_category", columnList = "category")
})
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class MenuItem {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @NotBlank(message = "Item name is required")
    @Column(nullable = false)
    private String name;

    @NotBlank(message = "Description is required")
    @Column(columnDefinition = "TEXT")
    private String description;

    @NotNull(message = "Price is required")
    @DecimalMin(value = "0.0", inclusive = false, message = "Price must be greater than 0")
    @Column(nullable = false, precision = 10, scale = 2)
    private BigDecimal price;

    @NotBlank(message = "Category is required")
    @Column(nullable = false)
    private String category;

    @NotNull(message = "Shop is required")
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "shop_id", nullable = false)
    @JsonIgnore
    private Shop shop;

    @Column(columnDefinition = "TEXT")
    private String imageUrl;

    @Builder.Default
    @Column(nullable = false)
    private Boolean isAvailable = true;

    @Builder.Default
    @Column(nullable = false)
    private Integer preparationTimeMinutes = 5;

    @Builder.Default
    @Column(nullable = false)
    private Integer calories = 0;

    @Column(columnDefinition = "TEXT")
    private String allergens;

    @Builder.Default
    @Column(nullable = false)
    private Integer sortOrder = 0;
}
