package com.coffee.shop.controller;

import com.coffee.shop.dto.request.LoginRequest;
import com.coffee.shop.dto.request.RegisterRequest;
import com.coffee.shop.dto.response.AuthResponse;
import com.coffee.shop.entity.User;
import com.coffee.shop.repository.UserRepository;
import com.coffee.shop.service.JwtService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
@Slf4j
@Tag(name = "Authentication", description = "APIs for user authentication and registration")
public class AuthController {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;

    @PostMapping("/register")
    @Operation(summary = "Register a new user", description = "Creates a new user account")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "201", description = "User registered successfully"),
            @ApiResponse(responseCode = "400", description = "Invalid request data"),
            @ApiResponse(responseCode = "409", description = "User already exists")
    })
    public ResponseEntity<AuthResponse> register(@Valid @RequestBody RegisterRequest request) {
        log.info("Registering new user with mobile: {}", request.getMobileNumber());
        
        // Check if user already exists
        if (userRepository.existsByMobileNumber(request.getMobileNumber())) {
            throw new IllegalStateException("User with mobile number already exists");
        }
        
        if (userRepository.existsByEmail(request.getEmail())) {
            throw new IllegalStateException("User with email already exists");
        }

        // Create new user
        User user = User.builder()
                .mobileNumber(request.getMobileNumber())
                .password(passwordEncoder.encode(request.getPassword()))
                .name(request.getName())
                .email(request.getEmail())
                .role(User.UserRole.CUSTOMER)
                .loyaltyScore(0)
                .build();

        User savedUser = userRepository.save(user);
        
        // Generate JWT token
        String token = jwtService.generateToken(createUserDetails(savedUser));
        
        AuthResponse response = AuthResponse.builder()
                .token(token)
                .userId(savedUser.getId().toString())
                .mobileNumber(savedUser.getMobileNumber())
                .name(savedUser.getName())
                .email(savedUser.getEmail())
                .role(savedUser.getRole().name())
                .build();

        log.info("User registered successfully: {}", savedUser.getId());
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @PostMapping("/login")
    @Operation(summary = "User login", description = "Authenticates user and returns JWT token")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Login successful"),
            @ApiResponse(responseCode = "401", description = "Invalid credentials")
    })
    public ResponseEntity<AuthResponse> login(@Valid @RequestBody LoginRequest request) {
        log.info("User login attempt for mobile: {}", request.getMobileNumber());
        
        User user = userRepository.findByMobileNumber(request.getMobileNumber())
                .orElseThrow(() -> new IllegalArgumentException("Invalid credentials"));

        if (!passwordEncoder.matches(request.getPassword(), user.getPassword())) {
            throw new IllegalArgumentException("Invalid credentials");
        }

        // Generate JWT token
        String token = jwtService.generateToken(createUserDetails(user));
        
        AuthResponse response = AuthResponse.builder()
                .token(token)
                .userId(user.getId().toString())
                .mobileNumber(user.getMobileNumber())
                .name(user.getName())
                .email(user.getEmail())
                .role(user.getRole().name())
                .build();

        log.info("User logged in successfully: {}", user.getId());
        return ResponseEntity.ok(response);
    }

    private org.springframework.security.core.userdetails.UserDetails createUserDetails(User user) {
        return org.springframework.security.core.userdetails.User.builder()
                .username(user.getId().toString())
                .password(user.getPassword())
                .authorities("ROLE_" + user.getRole().name())
                .build();
    }
}

