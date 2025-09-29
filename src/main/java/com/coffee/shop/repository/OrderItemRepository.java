package com.coffee.shop.repository;

import com.coffee.shop.entity.OrderItem;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface OrderItemRepository extends JpaRepository<OrderItem, UUID> {
    
    List<OrderItem> findByOrderId(UUID orderId);
    
    List<OrderItem> findByMenuItemId(UUID menuItemId);
}

