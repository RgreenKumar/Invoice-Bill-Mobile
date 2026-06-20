package com.vsmartengine.invoicebill.Items.Entity;

import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDate;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ItemDTO {

    private Long id;

    // e.g. "Rice", "Coconut Oil"
    private String itemName;

    // e.g. "1006", "1507"
    private String itemHsn;

    // e.g. "ITM001", "ITM002"
    private String itemCode;

    // category reference — only id needed in DTO
    private Long categoryId;

    // category name — for display in response
    private String categoryName;

    // unit reference — only id needed in DTO
    private Long unitId;

    // unit name — for display in response
    private String unitName;

    // unit symbol — for display e.g. "kg", "L"
    private String unitSymbol;

    // image as Base64 string for frontend display
    // e.g. "data:image/jpeg;base64,/9j/4AAQSkZJRg..."
    private String itemImage;

    private LocalDate createdAt;

    // nested pricing info
    private ItemPricingDTO pricing;

    // nested stock info
    private ItemStockDTO stock;
    
    private String company;
    
    private BigDecimal salePrice;
    private BigDecimal purchasePrice;
    
    private BigDecimal remainingStock;
}