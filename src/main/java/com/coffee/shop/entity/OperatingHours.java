package com.coffee.shop.entity;

import jakarta.persistence.*;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.DayOfWeek;
import java.time.LocalTime;
import java.util.UUID;

@Entity
@Table(name = "operating_hours", indexes = {
    @Index(name = "idx_operating_hours_shop", columnList = "shop_id"),
    @Index(name = "idx_operating_hours_day", columnList = "dayOfWeek")
})
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class OperatingHours {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @NotNull(message = "Shop is required")
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "shop_id", nullable = false)
    private Shop shop;

    @NotNull(message = "Day of week is required")
    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private DayOfWeek dayOfWeek;

    @NotNull(message = "Opening time is required")
    @Column(nullable = false)
    private LocalTime openingTime;

    @NotNull(message = "Closing time is required")
    @Column(nullable = false)
    private LocalTime closingTime;

    @Builder.Default
    @Column(nullable = false)
    private Boolean isClosed = false;

    @Column(columnDefinition = "TEXT")
    private String notes;
}
