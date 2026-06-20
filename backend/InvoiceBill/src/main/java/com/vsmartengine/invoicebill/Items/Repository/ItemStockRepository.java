package com.vsmartengine.invoicebill.Items.Repository;

import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import com.vsmartengine.invoicebill.Items.Entity.ItemStock;

@Repository
public interface ItemStockRepository extends JpaRepository<ItemStock, Long> {

    
    Optional<ItemStock> findByItemId(Long itemId);

    
    boolean existsByItemId(Long itemId);
}