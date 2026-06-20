package com.vsmartengine.invoicebill.SaleInvoice.Entity;

import lombok.*;
import java.math.BigDecimal;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class SaleInvoicePaymentDto {

    private String paymentType;       // Cash/Card/UPI/Cheque
    private BigDecimal amount;
}