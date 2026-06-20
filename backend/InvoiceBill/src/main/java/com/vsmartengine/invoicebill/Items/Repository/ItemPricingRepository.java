package com.vsmartengine.invoicebill.Items.Repository;

import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import com.vsmartengine.invoicebill.Items.Entity.ItemPricing;

@Repository
public interface ItemPricingRepository extends JpaRepository<ItemPricing, Long> {

    Optional<ItemPricing> findByItemId(Long itemId);

    boolean existsByItemId(Long itemId);
}