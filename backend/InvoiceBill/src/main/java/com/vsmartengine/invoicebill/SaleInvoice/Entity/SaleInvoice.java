package com.vsmartengine.invoicebill.SaleInvoice.Entity;

import jakarta.persistence.*;
import lombok.*;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

@Entity
@Table(name = "sale_invoice")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class SaleInvoice {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // ── Tenant & Audit ──
    private String companyName;
    private String billType;        // ESTIMATE / SALE / POS
    private String createdBy;       // username from JWT

    // ── Party Details ──
    private String partyName;
    private String phoneNo;

    // ── Invoice Details ──
    private Integer invoiceNumber;  // 1, 2, 3
    private String invoicePrefix;   // INV, SALE, SI
    private LocalDate invoiceDate;
    private String stateOfSupply;

    // ── Payment ──
    private Boolean isCash;
    private String paymentMode;
    private BigDecimal amountReceived;
    private Boolean received;
    private BigDecimal balanceAmount;  // grandTotal - amountReceived

    // ── Totals ──
    private BigDecimal subTotal;
    private BigDecimal totalDiscount;
    private BigDecimal totalCgst;
    private BigDecimal totalSgst;
    private BigDecimal totalAmount;
    private Boolean roundOffEnabled;
    private BigDecimal roundOffAmount;
    private BigDecimal grandTotal;

    // ── POS only ──
    private BigDecimal billDiscount;
    private BigDecimal additionalCharges;
    private String remarks;
    private String loyaltyPoints;

    // ── Estimate/Sale only ──
    @Column(columnDefinition = "TEXT")
    private String description;

    @Column(columnDefinition = "TEXT")
    private String termsConditions;

    private String imagePath;

    // ── Timestamps ──
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    // ── Relationship ──
    @OneToMany(mappedBy = "saleInvoice", 
               cascade = CascadeType.ALL, 
               orphanRemoval = true)
    private List<SaleInvoiceItem> items;

    @OneToMany(mappedBy = "saleInvoice", 
               cascade = CascadeType.ALL, 
               orphanRemoval = true)
    private List<SaleInvoicePayment> payments;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
        updatedAt = LocalDateTime.now();
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }
}