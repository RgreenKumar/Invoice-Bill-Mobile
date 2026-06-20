package com.vsmartengine.invoicebill.SaleInvoice.Entity;

import lombok.*;
import java.math.BigDecimal;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class ItemSearchResponseDto {

    private Long itemId;
    private String itemName;
    private String itemCode;
    private String itemHsn;
    private String unit;

    // ── Pricing ──
    private BigDecimal salePrice;
    private String salePriceTaxType;  // with_tax / without_tax
    private BigDecimal mrp;
    private BigDecimal additionalCessPerUnit;
    private BigDecimal discountOnSale;
    private String discountType;
    
    private Boolean calculateTaxOnMrp; // ← add this

    // ── Tax ──
    private String taxName;           // "GST 18%"
    private BigDecimal taxRate;       // 18.0
}