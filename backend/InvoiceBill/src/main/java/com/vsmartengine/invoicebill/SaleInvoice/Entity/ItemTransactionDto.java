package com.vsmartengine.invoicebill.SaleInvoice.Entity;

import lombok.AllArgsConstructor;
import lombok.Data;
import java.math.BigDecimal;
import java.time.LocalDate;

@Data
@AllArgsConstructor
public class ItemTransactionDto {
    private Long invoiceId;
    private String billType;
    private Integer invoiceNumber;
    private String partyName;
    private LocalDate invoiceDate;
    private BigDecimal qty;
    private String unit;
    private BigDecimal totalAmount;
    private BigDecimal balanceAmount;  // for Paid/Unpaid status
}