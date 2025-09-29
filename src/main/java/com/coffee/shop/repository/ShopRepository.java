package com.coffee.shop.repository;

import com.coffee.shop.entity.Shop;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface ShopRepository extends JpaRepository<Shop, UUID> {
    
    List<Shop> findByOwnerId(UUID ownerId);
    
    List<Shop> findByIsActiveTrue();
    
    @Query("SELECT s FROM Shop s WHERE s.isActive = true AND " +
           "ST_Distance_Sphere(ST_MakePoint(s.longitude, s.latitude), ST_MakePoint(:longitude, :latitude)) <= :radiusMeters " +
           "ORDER BY ST_Distance_Sphere(ST_MakePoint(s.longitude, s.latitude), ST_MakePoint(:longitude, :latitude))")
    List<Shop> findNearbyShops(@Param("latitude") Double latitude, 
                              @Param("longitude") Double longitude, 
                              @Param("radiusMeters") Double radiusMeters);
    
    @Query(value = "SELECT s.* FROM shops s WHERE s.is_active = true AND " +
           "ST_DWithin(ST_MakePoint(s.longitude, s.latitude), ST_MakePoint(:longitude, :latitude), :radiusMeters) " +
           "ORDER BY ST_Distance(ST_MakePoint(s.longitude, s.latitude), ST_MakePoint(:longitude, :latitude))", 
           nativeQuery = true)
    List<Shop> findNearbyShopsUsingDWithin(@Param("latitude") Double latitude, 
                                          @Param("longitude") Double longitude, 
                                          @Param("radiusMeters") Double radiusMeters);
}
