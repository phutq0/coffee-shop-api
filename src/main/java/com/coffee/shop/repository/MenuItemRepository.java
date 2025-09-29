package com.coffee.shop.repository;

import com.coffee.shop.entity.MenuItem;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface MenuItemRepository extends JpaRepository<MenuItem, UUID> {
    
    List<MenuItem> findByShopId(UUID shopId);
    
    List<MenuItem> findByShopIdAndIsAvailableTrue(UUID shopId);
    
    List<MenuItem> findByShopIdAndCategoryAndIsAvailableTrue(UUID shopId, String category);
    
    @Query("SELECT mi FROM MenuItem mi WHERE mi.shop.id = :shopId AND mi.isAvailable = true ORDER BY mi.sortOrder, mi.name")
    List<MenuItem> findAllByShopIdOrderBySortOrderAndName(@Param("shopId") UUID shopId);
    
    @Query("SELECT DISTINCT mi.category FROM MenuItem mi WHERE mi.shop.id = :shopId AND mi.isAvailable = true ORDER BY mi.category")
    List<String> findDistinctCategoriesByShopId(@Param("shopId") UUID shopId);
}
