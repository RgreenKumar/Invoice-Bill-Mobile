	package com.vsmartengine.invoicebill.Items.Entity;


import jakarta.persistence.*;
import lombok.*;
import java.math.BigDecimal;
 
@Entity
@Table(name = "item_pricing")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ItemPricing {
 
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
 
    // FK → items.id
    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "item_id", referencedColumnName = "id", nullable = false)
    private Item item;
 
    // e.g. 50.00, 120.00
    @Column(name = "sale_price", nullable = false, precision = 10, scale = 4)
    private BigDecimal salePrice;
 
    // "with_tax" or "without_tax"
    @Column(name = "sale_price_tax_type", nullable = false, length = 20)
    private String salePriceTaxType;
 
    // e.g. 5.00, 0.00, 2.00
    @Column(name = "discount_on_sale", precision = 10, scale = 4)
    private BigDecimal discountOnSale;
 
    // "percentage" or "fixed"
    @Column(name = "discount_type", length = 20)
    private String discountType;
 
    // e.g. 45.00, 110.00
    @Column(name = "wholesale_price", precision = 10, scale = 4)
    private BigDecimal wholesalePrice;
 
    // "with_tax" or "without_tax"  <- NEW
    @Column(name = "wholesale_price_tax_type", length = 20)
    private String wholesalePriceTaxType;
 
    // e.g. 40.00, 95.00
    @Column(name = "purchase_price", precision = 10, scale = 4)
    private BigDecimal purchasePrice;
 
    // "with_tax" or "without_tax"  <- NEW
    @Column(name = "purchase_price_tax_type", length = 20)
    private String purchasePriceTaxType;
 
    // FK → taxes.id
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "tax_id", referencedColumnName = "id")
    private Tax tax;
    
    
    @Column(name = "mrp", precision = 10, scale = 4)
    private BigDecimal mrp;

    @Column(name = "calculate_tax_on_mrp")
    private Boolean calculateTaxOnMrp;

    @Column(name = "additional_cess_per_unit", precision = 10, scale = 4)
    private BigDecimal additionalCessPerUnit;
}