package com.coffee.shop.service;

import com.coffee.shop.entity.Order;
import com.coffee.shop.entity.QueueEntry;
import com.coffee.shop.entity.Shop;
import com.coffee.shop.entity.User;
import com.coffee.shop.repository.QueueEntryRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Slf4j
@Transactional
public class QueueManagementService {

    private final QueueEntryRepository queueEntryRepository;

    public QueueEntry addToQueue(Shop shop, User customer, Order order) {
        log.info("Adding customer {} to queue for shop {}", customer.getId(), shop.getId());
        
        // Check if customer is already in queue for this shop
        List<QueueEntry> existingEntries = queueEntryRepository.findByCustomerId(customer.getId());
        boolean alreadyInQueue = existingEntries.stream()
                .anyMatch(entry -> entry.getShop().getId().equals(shop.getId()) && 
                         (entry.getStatus() == QueueEntry.QueueStatus.WAITING || 
                          entry.getStatus() == QueueEntry.QueueStatus.BEING_SERVED));
        
        if (alreadyInQueue) {
            throw new IllegalStateException("Customer is already in queue for this shop");
        }

        // Get next position in queue
        Integer maxPosition = queueEntryRepository.findMaxPositionByShopId(shop.getId());
        int nextPosition = (maxPosition != null) ? maxPosition + 1 : 1;

        // Create queue entry
        QueueEntry queueEntry = QueueEntry.builder()
                .shop(shop)
                .customer(customer)
                .order(order)
                .position(nextPosition)
                .status(QueueEntry.QueueStatus.WAITING)
                .joinedAt(LocalDateTime.now())
                .build();

        QueueEntry savedEntry = queueEntryRepository.save(queueEntry);
        log.info("Customer {} added to queue at position {} for shop {}", 
                customer.getId(), nextPosition, shop.getId());
        
        return savedEntry;
    }

    public void removeFromQueue(UUID queueEntryId) {
        log.info("Removing queue entry {}", queueEntryId);
        
        QueueEntry queueEntry = queueEntryRepository.findById(queueEntryId)
                .orElseThrow(() -> new IllegalArgumentException("Queue entry not found"));
        
        if (queueEntry.getStatus() == QueueEntry.QueueStatus.SERVED) {
            throw new IllegalStateException("Cannot remove served customer from queue");
        }

        queueEntry.setStatus(QueueEntry.QueueStatus.LEFT);
        queueEntry.setLeftAt(LocalDateTime.now());
        queueEntryRepository.save(queueEntry);

        // Reorder remaining customers
        reorderQueue(queueEntry.getShop().getId(), queueEntry.getPosition());
        
        log.info("Queue entry {} removed and queue reordered", queueEntryId);
    }

    public QueueEntry serveCustomer(UUID queueEntryId) {
        log.info("Serving customer for queue entry {}", queueEntryId);
        
        QueueEntry queueEntry = queueEntryRepository.findById(queueEntryId)
                .orElseThrow(() -> new IllegalArgumentException("Queue entry not found"));
        
        if (queueEntry.getStatus() != QueueEntry.QueueStatus.WAITING) {
            throw new IllegalStateException("Customer is not waiting to be served");
        }

        queueEntry.setStatus(QueueEntry.QueueStatus.BEING_SERVED);
        queueEntry.setServedAt(LocalDateTime.now());
        QueueEntry savedEntry = queueEntryRepository.save(queueEntry);
        
        log.info("Customer {} is now being served", queueEntry.getCustomer().getId());
        return savedEntry;
    }

    public void completeService(UUID queueEntryId) {
        log.info("Completing service for queue entry {}", queueEntryId);
        
        QueueEntry queueEntry = queueEntryRepository.findById(queueEntryId)
                .orElseThrow(() -> new IllegalArgumentException("Queue entry not found"));
        
        if (queueEntry.getStatus() != QueueEntry.QueueStatus.BEING_SERVED) {
            throw new IllegalStateException("Customer is not being served");
        }

        queueEntry.setStatus(QueueEntry.QueueStatus.SERVED);
        queueEntryRepository.save(queueEntry);
        
        // Reorder queue after service completion
        reorderQueue(queueEntry.getShop().getId(), queueEntry.getPosition());
        
        log.info("Service completed for customer {}", queueEntry.getCustomer().getId());
    }

    public List<QueueEntry> getQueueForShop(UUID shopId) {
        return queueEntryRepository.findByShopIdOrderByPositionAsc(shopId);
    }

    public List<QueueEntry> getWaitingCustomers(UUID shopId) {
        return queueEntryRepository.findWaitingCustomersByShopIdOrderByPosition(shopId);
    }

    public Integer getQueuePosition(UUID queueEntryId) {
        QueueEntry queueEntry = queueEntryRepository.findById(queueEntryId)
                .orElseThrow(() -> new IllegalArgumentException("Queue entry not found"));
        
        return queueEntry.getPosition();
    }

    public Long getTotalWaitingCustomers(UUID shopId) {
        return queueEntryRepository.countWaitingCustomersByShopId(shopId);
    }

    public Integer estimateWaitTime(UUID shopId, Integer position) {
        // Get shop's average service time from configuration
        // This is a simplified calculation - in reality, you'd consider historical data
        List<QueueEntry> waitingCustomers = queueEntryRepository.findWaitingCustomersByShopIdOrderByPosition(shopId);
        int customersAhead = Math.max(0, position - 1);
        
        // Assume 5 minutes average service time per customer
        int averageServiceTimeMinutes = 5;
        return customersAhead * averageServiceTimeMinutes;
    }

    private void reorderQueue(UUID shopId, Integer removedPosition) {
        log.info("Reordering queue for shop {} after removing position {}", shopId, removedPosition);
        
        List<QueueEntry> customersAfterPosition = queueEntryRepository.findCustomersAfterPosition(shopId, removedPosition);
        
        for (QueueEntry entry : customersAfterPosition) {
            entry.setPosition(entry.getPosition() - 1);
            queueEntryRepository.save(entry);
        }
        
        log.info("Queue reordered for shop {}", shopId);
    }
}
