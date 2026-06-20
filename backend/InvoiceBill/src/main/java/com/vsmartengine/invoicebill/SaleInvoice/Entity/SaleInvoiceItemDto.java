package com.vsmartengine.invoicebill.SaleInvoice.Entity;

import lombok.*;
import java.math.BigDecimal;
import java.time.LocalDate;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class SaleInvoiceItemDto {

    private Integer lineNumber;       // row order 1,2,3

    // ── Item Details ──
    private String itemName;
    private String itemCode;          // POS only

    // ── Optional columns ──
    private String modelNo;
    private LocalDate mfgDate;
    private LocalDate expDate;
    private BigDecimal mrp;           // display only
    private String size;
    private BigDecimal addCess;
    private String hsnCode;

    // ── Core ──
    private BigDecimal qty;
    private String unit;
    private BigDecimal priceWithoutTax;
    private BigDecimal discountPct;
    private BigDecimal discountAmount;
    private BigDecimal taxableAmount;

    // ── Tax ──
    private String taxLabel;          // "GST 18%"
    private BigDecimal taxPct;        // 18.0

    // ── Calculated ──
    private BigDecimal cgstAmount;
    private BigDecimal sgstAmount;
    private BigDecimal totalAmount;
}