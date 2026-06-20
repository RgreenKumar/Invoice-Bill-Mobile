package com.vsmartengine.invoicebill.Items.Entity;

import lombok.*;
import java.math.BigDecimal;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ItemPricingDTO {

    private Long id;

    // item reference — only id needed in DTO
    private Long itemId;

    // e.g. 50.00, 120.00
    private BigDecimal salePrice;

    // "with_tax" or "without_tax"
    private String salePriceTaxType;

    // e.g. 5.00, 0.00
    private BigDecimal discountOnSale;

    // "percentage" or "fixed"
    private String discountType;

    // e.g. 45.00, 110.00
    private BigDecimal wholesalePrice;

    // "with_tax" or "without_tax"
    private String wholesalePriceTaxType;

    // e.g. 40.00, 95.00
    private BigDecimal purchasePrice;

    // "with_tax" or "without_tax"
    private String purchasePriceTaxType;

    // tax reference — only id needed in DTO
    private Long taxId;
    
    private BigDecimal mrp;
    private Boolean calculateTaxOnMrp;
    private BigDecimal additionalCessPerUnit;
    
}