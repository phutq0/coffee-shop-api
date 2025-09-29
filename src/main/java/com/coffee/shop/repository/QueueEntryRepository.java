package com.coffee.shop.repository;

import com.coffee.shop.entity.QueueEntry;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface QueueEntryRepository extends JpaRepository<QueueEntry, UUID> {
    
    List<QueueEntry> findByShopIdOrderByPositionAsc(UUID shopId);
    
    List<QueueEntry> findByShopIdAndStatusOrderByPositionAsc(UUID shopId, QueueEntry.QueueStatus status);
    
    List<QueueEntry> findByCustomerId(UUID customerId);
    
    Optional<QueueEntry> findByOrderId(UUID orderId);
    
    @Query("SELECT qe FROM QueueEntry qe WHERE qe.shop.id = :shopId AND qe.status = 'WAITING' ORDER BY qe.position ASC")
    List<QueueEntry> findWaitingCustomersByShopIdOrderByPosition(@Param("shopId") UUID shopId);
    
    @Query("SELECT qe FROM QueueEntry qe WHERE qe.shop.id = :shopId AND qe.status = 'BEING_SERVED'")
    List<QueueEntry> findBeingServedCustomersByShopId(@Param("shopId") UUID shopId);
    
    @Query("SELECT MAX(qe.position) FROM QueueEntry qe WHERE qe.shop.id = :shopId AND qe.status = 'WAITING'")
    Integer findMaxPositionByShopId(@Param("shopId") UUID shopId);
    
    @Query("SELECT COUNT(qe) FROM QueueEntry qe WHERE qe.shop.id = :shopId AND qe.status = 'WAITING'")
    Long countWaitingCustomersByShopId(@Param("shopId") UUID shopId);
    
    @Query("SELECT qe FROM QueueEntry qe WHERE qe.shop.id = :shopId AND qe.position > :position ORDER BY qe.position ASC")
    List<QueueEntry> findCustomersAfterPosition(@Param("shopId") UUID shopId, @Param("position") Integer position);
}

