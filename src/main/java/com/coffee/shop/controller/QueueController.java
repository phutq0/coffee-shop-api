package com.coffee.shop.controller;

import com.coffee.shop.dto.request.JoinQueueRequest;
import com.coffee.shop.dto.response.QueuePositionResponse;
import com.coffee.shop.entity.Order;
import com.coffee.shop.entity.QueueEntry;
import com.coffee.shop.repository.OrderRepository;
import com.coffee.shop.service.QueueManagementService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@RestController
@RequestMapping("/api/queue")
@RequiredArgsConstructor
@Slf4j
@Tag(name = "Queue Management", description = "APIs for managing customer queues")
public class QueueController {

    private final QueueManagementService queueManagementService;
    private final OrderRepository orderRepository;

    @PostMapping("/join")
    @Operation(summary = "Join queue", description = "Adds a customer to the queue for their order")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Successfully joined queue"),
            @ApiResponse(responseCode = "400", description = "Invalid request data"),
            @ApiResponse(responseCode = "404", description = "Order not found"),
            @ApiResponse(responseCode = "409", description = "Already in queue")
    })
    public ResponseEntity<QueuePositionResponse> joinQueue(
            @Valid @RequestBody JoinQueueRequest request,
            Authentication authentication) {
        
        log.info("Customer {} joining queue for order {}", authentication.getName(), request.getOrderId());
        
        UUID customerId = UUID.fromString(authentication.getName());
        UUID orderId = UUID.fromString(request.getOrderId());
        
        // Get the order
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new IllegalArgumentException("Order not found"));
        
        // Verify the order belongs to the customer
        if (!order.getCustomer().getId().equals(customerId)) {
            throw new IllegalStateException("Order does not belong to this customer");
        }
        
        // Add to queue
        QueueEntry queueEntry = queueManagementService.addToQueue(order.getShop(), order.getCustomer(), order);
        
        // Build response
        QueuePositionResponse response = QueuePositionResponse.builder()
                .queueEntryId(queueEntry.getId().toString())
                .position(queueEntry.getPosition())
                .totalWaiting(queueManagementService.getTotalWaitingCustomers(order.getShop().getId()).intValue())
                .estimatedWaitTimeMinutes(queueManagementService.estimateWaitTime(order.getShop().getId(), queueEntry.getPosition()))
                .status(queueEntry.getStatus().toString())
                .notes(queueEntry.getNotes())
                .build();
        
        return ResponseEntity.ok(response);
    }

    @GetMapping("/position/{queueEntryId}")
    @Operation(summary = "Get queue position", description = "Gets the current position of a customer in the queue")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Queue position retrieved successfully"),
            @ApiResponse(responseCode = "404", description = "Queue entry not found")
    })
    public ResponseEntity<QueuePositionResponse> getQueuePosition(
            @Parameter(description = "Queue Entry ID") @PathVariable UUID queueEntryId) {
        
        log.info("Getting queue position for entry {}", queueEntryId);
        
        QueueEntry queueEntry = queueManagementService.getQueueForShop(queueEntryId)
                .stream()
                .filter(entry -> entry.getId().equals(queueEntryId))
                .findFirst()
                .orElseThrow(() -> new IllegalArgumentException("Queue entry not found"));
        
        QueuePositionResponse response = QueuePositionResponse.builder()
                .queueEntryId(queueEntry.getId().toString())
                .position(queueEntry.getPosition())
                .totalWaiting(queueManagementService.getTotalWaitingCustomers(queueEntry.getShop().getId()).intValue())
                .estimatedWaitTimeMinutes(queueManagementService.estimateWaitTime(queueEntry.getShop().getId(), queueEntry.getPosition()))
                .status(queueEntry.getStatus().toString())
                .notes(queueEntry.getNotes())
                .build();
        
        return ResponseEntity.ok(response);
    }
}
