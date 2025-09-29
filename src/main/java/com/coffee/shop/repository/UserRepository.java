package com.coffee.shop.repository;

import com.coffee.shop.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface UserRepository extends JpaRepository<User, UUID> {
    
    Optional<User> findByMobileNumber(String mobileNumber);
    
    Optional<User> findByEmail(String email);
    
    boolean existsByMobileNumber(String mobileNumber);
    
    boolean existsByEmail(String email);
}

