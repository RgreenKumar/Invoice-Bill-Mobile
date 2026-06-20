package com.vsmartengine.invoicebill.SaleInvoice.Entity;

import lombok.*;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class SaleInvoiceRequestDto {

    // ── Bill Info ──
    private String billType;          // ESTIMATE / SALE / POS
    private Integer invoiceNumber;
    private String  invoicePrefix;
    private LocalDate invoiceDate;

    // ── Party ──
    private String partyName;
    private String phoneNo;

    // ── Settings ──
    private String stateOfSupply;
    private Boolean isCash;
    private String paymentMode;
    private Boolean roundOffEnabled;

    // ── Totals (calculated in React) ──
    private BigDecimal subTotal;
    private BigDecimal totalDiscount;
    private BigDecimal totalCgst;
    private BigDecimal totalSgst;
    private BigDecimal totalAmount;
    private BigDecimal roundOffAmount;
    private BigDecimal grandTotal;

    // ── Payment ──
    private Boolean received;
    private BigDecimal amountReceived;
    private BigDecimal balanceAmount;
    // ── POS only ──
    private BigDecimal billDiscount;
    private BigDecimal additionalCharges;
    private String remarks;
    private String loyaltyPoints;

    // ── Estimate/Sale only ──
    private String description;
    private String termsConditions;
    private String imagePath;

    // ── Items list ──
    private List<SaleInvoiceItemDto> items;

    // ── Payments list ──
    private List<SaleInvoicePaymentDto> payments;
}