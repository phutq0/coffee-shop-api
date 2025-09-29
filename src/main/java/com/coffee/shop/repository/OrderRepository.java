package com.coffee.shop.repository;

import com.coffee.shop.entity.Order;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Repository
public interface OrderRepository extends JpaRepository<Order, UUID> {
    
    List<Order> findByCustomerId(UUID customerId);
    
    List<Order> findByShopId(UUID shopId);
    
    List<Order> findByCustomerIdAndStatus(UUID customerId, Order.OrderStatus status);
    
    List<Order> findByShopIdAndStatus(UUID shopId, Order.OrderStatus status);
    
    @Query("SELECT o FROM Order o WHERE o.customer.id = :customerId ORDER BY o.createdAt DESC")
    List<Order> findByCustomerIdOrderByCreatedAtDesc(@Param("customerId") UUID customerId);
    
    @Query("SELECT o FROM Order o WHERE o.shop.id = :shopId ORDER BY o.createdAt DESC")
    List<Order> findByShopIdOrderByCreatedAtDesc(@Param("shopId") UUID shopId);
    
    @Query("SELECT o FROM Order o WHERE o.shop.id = :shopId AND o.status IN :statuses ORDER BY o.createdAt ASC")
    List<Order> findByShopIdAndStatusInOrderByCreatedAtAsc(@Param("shopId") UUID shopId, 
                                                          @Param("statuses") List<Order.OrderStatus> statuses);
    
    @Query("SELECT o FROM Order o WHERE o.createdAt BETWEEN :startDate AND :endDate ORDER BY o.createdAt DESC")
    List<Order> findByCreatedAtBetween(@Param("startDate") LocalDateTime startDate, 
                                     @Param("endDate") LocalDateTime endDate);
}

