package com.coffee.shop.service;

import com.coffee.shop.dto.request.CreateOrderRequest;
import com.coffee.shop.dto.request.OrderItemRequest;
import com.coffee.shop.entity.*;
import com.coffee.shop.repository.*;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.modelmapper.ModelMapper;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.Arrays;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class OrderProcessingServiceTest {

    @Mock
    private OrderRepository orderRepository;
    
    @Mock
    private OrderItemRepository orderItemRepository;
    
    @Mock
    private UserRepository userRepository;
    
    @Mock
    private ShopRepository shopRepository;
    
    @Mock
    private MenuItemRepository menuItemRepository;
    
    @Mock
    private QueueManagementService queueManagementService;
    
    @Mock
    private ModelMapper modelMapper;

    @InjectMocks
    private OrderProcessingService orderProcessingService;

    private User customer;
    private Shop shop;
    private MenuItem menuItem1;
    private MenuItem menuItem2;
    private CreateOrderRequest createOrderRequest;
    private QueueEntry queueEntry;

    @BeforeEach
    void setUp() {
        // Setup test data
        customer = User.builder()
                .id(UUID.randomUUID())
                .mobileNumber("+1234567890")
                .name("Test Customer")
                .email("test@example.com")
                .role(User.UserRole.CUSTOMER)
                .loyaltyScore(100)
                .build();

        shop = Shop.builder()
                .id(UUID.randomUUID())
                .name("Test Coffee Shop")
                .description("A test coffee shop")
                .owner(customer)
                .latitude(40.7128)
                .longitude(-74.0060)
                .address("123 Test St")
                .isActive(true)
                .build();

        menuItem1 = MenuItem.builder()
                .id(UUID.randomUUID())
                .name("Espresso")
                .description("Rich espresso")
                .price(new BigDecimal("2.50"))
                .category("Coffee")
                .shop(shop)
                .isAvailable(true)
                .preparationTimeMinutes(3)
                .build();

        menuItem2 = MenuItem.builder()
                .id(UUID.randomUUID())
                .name("Cappuccino")
                .description("Espresso with milk")
                .price(new BigDecimal("3.50"))
                .category("Coffee")
                .shop(shop)
                .isAvailable(true)
                .preparationTimeMinutes(5)
                .build();

        createOrderRequest = CreateOrderRequest.builder()
                .shopId(shop.getId().toString())
                .items(Arrays.asList(
                        OrderItemRequest.builder()
                                .menuItemId(menuItem1.getId().toString())
                                .quantity(2)
                                .specialInstructions("Extra hot")
                                .build(),
                        OrderItemRequest.builder()
                                .menuItemId(menuItem2.getId().toString())
                                .quantity(1)
                                .build()
                ))
                .specialInstructions("Please prepare quickly")
                .build();

        queueEntry = QueueEntry.builder()
                .id(UUID.randomUUID())
                .shop(shop)
                .customer(customer)
                .position(1)
                .status(QueueEntry.QueueStatus.WAITING)
                .joinedAt(LocalDateTime.now())
                .build();
    }

    @Test
    void processOrder_Success() {
        // Given
        when(userRepository.findById(customer.getId())).thenReturn(Optional.of(customer));
        when(shopRepository.findById(shop.getId())).thenReturn(Optional.of(shop));
        when(menuItemRepository.findById(menuItem1.getId())).thenReturn(Optional.of(menuItem1));
        when(menuItemRepository.findById(menuItem2.getId())).thenReturn(Optional.of(menuItem2));
        when(orderRepository.save(any(Order.class))).thenAnswer(invocation -> {
            Order order = invocation.getArgument(0);
            order.setId(UUID.randomUUID());
            return order;
        });
        when(queueManagementService.addToQueue(any(Shop.class), any(User.class), any(Order.class)))
                .thenReturn(queueEntry);

        // When
        var result = orderProcessingService.processOrder(createOrderRequest, customer.getId());

        // Then
        assertNotNull(result);
        assertEquals(shop.getId().toString(), result.getShopId());
        assertEquals(customer.getId().toString(), result.getCustomerId());
        assertEquals(2, result.getItems().size());
        
        // Verify interactions
        verify(userRepository).findById(customer.getId());
        verify(shopRepository).findById(shop.getId());
        verify(menuItemRepository).findById(menuItem1.getId());
        verify(menuItemRepository).findById(menuItem2.getId());
        verify(orderRepository, times(2)).save(any(Order.class)); // Once for order, once for update
        verify(queueManagementService).addToQueue(any(Shop.class), any(User.class), any(Order.class));
    }

    @Test
    void processOrder_CustomerNotFound() {
        // Given
        when(userRepository.findById(customer.getId())).thenReturn(Optional.empty());

        // When & Then
        assertThrows(IllegalArgumentException.class, () -> 
                orderProcessingService.processOrder(createOrderRequest, customer.getId()));
        
        verify(userRepository).findById(customer.getId());
        verify(shopRepository, never()).findById(any());
    }

    @Test
    void processOrder_ShopNotFound() {
        // Given
        when(userRepository.findById(customer.getId())).thenReturn(Optional.of(customer));
        when(shopRepository.findById(shop.getId())).thenReturn(Optional.empty());

        // When & Then
        assertThrows(IllegalArgumentException.class, () -> 
                orderProcessingService.processOrder(createOrderRequest, customer.getId()));
        
        verify(userRepository).findById(customer.getId());
        verify(shopRepository).findById(shop.getId());
    }

    @Test
    void processOrder_ShopInactive() {
        // Given
        shop.setIsActive(false);
        when(userRepository.findById(customer.getId())).thenReturn(Optional.of(customer));
        when(shopRepository.findById(shop.getId())).thenReturn(Optional.of(shop));

        // When & Then
        assertThrows(IllegalStateException.class, () -> 
                orderProcessingService.processOrder(createOrderRequest, customer.getId()));
        
        verify(userRepository).findById(customer.getId());
        verify(shopRepository).findById(shop.getId());
    }

    @Test
    void processOrder_MenuItemNotFound() {
        // Given
        when(userRepository.findById(customer.getId())).thenReturn(Optional.of(customer));
        when(shopRepository.findById(shop.getId())).thenReturn(Optional.of(shop));
        when(menuItemRepository.findById(menuItem1.getId())).thenReturn(Optional.empty());

        // When & Then
        assertThrows(IllegalArgumentException.class, () -> 
                orderProcessingService.processOrder(createOrderRequest, customer.getId()));
        
        verify(userRepository).findById(customer.getId());
        verify(shopRepository).findById(shop.getId());
        verify(menuItemRepository).findById(menuItem1.getId());
    }

    @Test
    void processOrder_MenuItemUnavailable() {
        // Given
        menuItem1.setIsAvailable(false);
        when(userRepository.findById(customer.getId())).thenReturn(Optional.of(customer));
        when(shopRepository.findById(shop.getId())).thenReturn(Optional.of(shop));
        when(menuItemRepository.findById(menuItem1.getId())).thenReturn(Optional.of(menuItem1));

        // When & Then
        assertThrows(IllegalStateException.class, () -> 
                orderProcessingService.processOrder(createOrderRequest, customer.getId()));
        
        verify(userRepository).findById(customer.getId());
        verify(shopRepository).findById(shop.getId());
        verify(menuItemRepository).findById(menuItem1.getId());
    }

    @Test
    void getOrder_Success() {
        // Given
        Order order = Order.builder()
                .id(UUID.randomUUID())
                .customer(customer)
                .shop(shop)
                .status(Order.OrderStatus.CONFIRMED)
                .subtotal(new BigDecimal("8.50"))
                .taxAmount(new BigDecimal("0.68"))
                .totalAmount(new BigDecimal("9.18"))
                .createdAt(LocalDateTime.now())
                .build();

        when(orderRepository.findById(order.getId())).thenReturn(Optional.of(order));
        when(queueManagementService.getQueueForShop(shop.getId())).thenReturn(Arrays.asList(queueEntry));

        // When
        var result = orderProcessingService.getOrder(order.getId());

        // Then
        assertNotNull(result);
        assertEquals(order.getId().toString(), result.getId());
        assertEquals(shop.getId().toString(), result.getShopId());
        assertEquals(customer.getId().toString(), result.getCustomerId());
        
        verify(orderRepository).findById(order.getId());
        verify(queueManagementService).getQueueForShop(shop.getId());
    }

    @Test
    void getOrder_NotFound() {
        // Given
        UUID orderId = UUID.randomUUID();
        when(orderRepository.findById(orderId)).thenReturn(Optional.empty());

        // When & Then
        assertThrows(IllegalArgumentException.class, () -> 
                orderProcessingService.getOrder(orderId));
        
        verify(orderRepository).findById(orderId);
    }

    @Test
    void cancelOrder_Success() {
        // Given
        Order order = Order.builder()
                .id(UUID.randomUUID())
                .customer(customer)
                .shop(shop)
                .status(Order.OrderStatus.CONFIRMED)
                .subtotal(new BigDecimal("8.50"))
                .taxAmount(new BigDecimal("0.68"))
                .totalAmount(new BigDecimal("9.18"))
                .createdAt(LocalDateTime.now())
                .build();

        when(orderRepository.findById(order.getId())).thenReturn(Optional.of(order));
        when(queueManagementService.getQueueForShop(shop.getId())).thenReturn(Arrays.asList(queueEntry));
        when(orderRepository.save(any(Order.class))).thenReturn(order);

        // When
        var result = orderProcessingService.cancelOrder(order.getId(), customer.getId());

        // Then
        assertNotNull(result);
        assertEquals(Order.OrderStatus.CANCELLED, result.getStatus());
        assertNotNull(result.getCancellationReason());
        
        verify(orderRepository).findById(order.getId());
        verify(queueManagementService).removeFromQueue(queueEntry.getId());
        verify(orderRepository).save(any(Order.class));
    }

    @Test
    void cancelOrder_OrderNotFound() {
        // Given
        UUID orderId = UUID.randomUUID();
        when(orderRepository.findById(orderId)).thenReturn(Optional.empty());

        // When & Then
        assertThrows(IllegalArgumentException.class, () -> 
                orderProcessingService.cancelOrder(orderId, customer.getId()));
        
        verify(orderRepository).findById(orderId);
    }

    @Test
    void cancelOrder_WrongCustomer() {
        // Given
        Order order = Order.builder()
                .id(UUID.randomUUID())
                .customer(customer)
                .shop(shop)
                .status(Order.OrderStatus.CONFIRMED)
                .build();

        UUID differentCustomerId = UUID.randomUUID();
        when(orderRepository.findById(order.getId())).thenReturn(Optional.of(order));

        // When & Then
        assertThrows(IllegalStateException.class, () -> 
                orderProcessingService.cancelOrder(order.getId(), differentCustomerId));
        
        verify(orderRepository).findById(order.getId());
    }

    @Test
    void cancelOrder_AlreadyCompleted() {
        // Given
        Order order = Order.builder()
                .id(UUID.randomUUID())
                .customer(customer)
                .shop(shop)
                .status(Order.OrderStatus.COMPLETED)
                .build();

        when(orderRepository.findById(order.getId())).thenReturn(Optional.of(order));

        // When & Then
        assertThrows(IllegalStateException.class, () -> 
                orderProcessingService.cancelOrder(order.getId(), customer.getId()));
        
        verify(orderRepository).findById(order.getId());
    }

    @Test
    void cancelOrder_AlreadyCancelled() {
        // Given
        Order order = Order.builder()
                .id(UUID.randomUUID())
                .customer(customer)
                .shop(shop)
                .status(Order.OrderStatus.CANCELLED)
                .build();

        when(orderRepository.findById(order.getId())).thenReturn(Optional.of(order));

        // When & Then
        assertThrows(IllegalStateException.class, () -> 
                orderProcessingService.cancelOrder(order.getId(), customer.getId()));
        
        verify(orderRepository).findById(order.getId());
    }
}

