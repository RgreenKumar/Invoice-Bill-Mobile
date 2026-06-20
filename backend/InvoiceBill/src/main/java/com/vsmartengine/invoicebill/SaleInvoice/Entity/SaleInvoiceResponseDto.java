package com.vsmartengine.invoicebill.SaleInvoice.Entity;

import lombok.*;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class SaleInvoiceResponseDto {

    private Long id;
    private String billType;
    private Integer invoiceNumber;
    private String  invoicePrefix;
    private LocalDate invoiceDate;
    private String partyName;
    private String phoneNo;
    private String paymentMode;
    private BigDecimal grandTotal;
    private BigDecimal amountReceived;
    private BigDecimal balanceAmount;
    private Boolean received;
    private String createdBy;
    private LocalDateTime createdAt;

    // ── Items ──
    private List<SaleInvoiceItemDto> items;

    // ── Payments ──
    private List<SaleInvoicePaymentDto> payments;
}