package com.vsmartengine.invoicebill.SaleInvoice.Entity;

import jakarta.persistence.*;
import lombok.*;
import java.math.BigDecimal;
import com.fasterxml.jackson.annotation.JsonIgnore;


@Entity
@Table(name = "sale_invoice_payment")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class SaleInvoicePayment {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // ── Parent Link ──
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "sale_invoice_id")
    @JsonIgnore
    private SaleInvoice saleInvoice;

    private String paymentType;     // Cash/Card/UPI/Cheque
    private BigDecimal amount;
}