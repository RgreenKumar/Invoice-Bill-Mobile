package com.vsmartengine.invoicebill.SaleInvoice.Repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.vsmartengine.invoicebill.SaleInvoice.Entity.SaleInvoiceItem;

import java.util.List;

@Repository
public interface SaleInvoiceItemRepository 
    extends JpaRepository<SaleInvoiceItem, Long> {

    // get all items for a bill
    List<SaleInvoiceItem> findBySaleInvoiceId(Long saleInvoiceId);

    // delete all items for a bill
    // used when bill is edited
    void deleteBySaleInvoiceId(Long saleInvoiceId);
    
 // get all items by itemName and company
    List<SaleInvoiceItem> findByItemNameAndCompanyName(String itemName, String companyName);
}	