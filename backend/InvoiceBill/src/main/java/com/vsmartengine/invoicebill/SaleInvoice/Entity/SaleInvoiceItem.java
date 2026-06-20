package com.vsmartengine.invoicebill.SaleInvoice.Entity;

import jakarta.persistence.*;
import lombok.*;
import java.math.BigDecimal;
import java.time.LocalDate;
import com.fasterxml.jackson.annotation.JsonIgnore;


@Entity
@Table(name = "sale_invoice_item")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class SaleInvoiceItem {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // ── Parent Link ──
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "sale_invoice_id")
    @JsonIgnore

    private SaleInvoice saleInvoice;

    private String companyName;
    private Integer lineNumber;     // row order 1,2,3

    // ── Item Details ──
    private String itemName;
    private String itemCode;        // POS only

    // ── Optional columns (nullable) ──
    private String modelNo;
    private LocalDate mfgDate;
    private LocalDate expDate;
    private BigDecimal mrp;         // display only, not in calculation
    private String size;
    private BigDecimal addCess;
    private String hsnCode;

    // ── Core columns ──
    private BigDecimal qty;
    private String unit;
    private BigDecimal  	priceWithoutTax;
    private BigDecimal discountPct;
    private BigDecimal discountAmount;
    private BigDecimal taxableAmount;

    // ── Tax ──
    private String taxLabel;        // "GST 18%"
    private BigDecimal taxPct;      // 18.0

    // ── Calculated ──
    private BigDecimal cgstAmount;
    private BigDecimal sgstAmount;
    private BigDecimal totalAmount;
}