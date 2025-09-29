package com.coffee.shop.entity;

import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.*;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "queue_entries", indexes = {
    @Index(name = "idx_queue_shop", columnList = "shop_id"),
    @Index(name = "idx_queue_customer", columnList = "customer_id"),
    @Index(name = "idx_queue_position", columnList = "shop_id, position"),
    @Index(name = "idx_queue_status", columnList = "status")
})
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class QueueEntry {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @NotNull(message = "Shop is required")
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "shop_id", nullable = false)
    @JsonIgnore
    private Shop shop;

    @NotNull(message = "Customer is required")
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "customer_id", nullable = false)
    @JsonIgnore
    private User customer;

    @NotNull(message = "Order is required")
    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "order_id", nullable = false)
    @JsonIgnore
    private Order order;

    @NotNull(message = "Position is required")
    @Column(nullable = false)
    private Integer position;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private QueueStatus status;

    @Builder.Default
    @Column(nullable = false)
    private LocalDateTime joinedAt = LocalDateTime.now();

    private LocalDateTime servedAt;
    private LocalDateTime leftAt;

    @Column(columnDefinition = "TEXT")
    private String notes;

    public enum QueueStatus {
        WAITING,
        BEING_SERVED,
        SERVED,
        LEFT
    }
}
