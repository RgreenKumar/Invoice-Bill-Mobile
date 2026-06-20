package com.vsmartengine.invoicebill.SaleInvoice.Repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.vsmartengine.invoicebill.SaleInvoice.Entity.SaleInvoicePayment;

import java.util.List;

@Repository
public interface SaleInvoicePaymentRepository 
    extends JpaRepository<SaleInvoicePayment, Long> {

    // get all payments for a bill
    List<SaleInvoicePayment> findBySaleInvoiceId(Long saleInvoiceId);

    // delete all payments for a bill
    // used when bill is edited
    void deleteBySaleInvoiceId(Long saleInvoiceId);
}