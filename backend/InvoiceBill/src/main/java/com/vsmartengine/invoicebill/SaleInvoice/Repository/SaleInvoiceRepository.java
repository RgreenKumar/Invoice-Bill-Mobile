package com.vsmartengine.invoicebill.SaleInvoice.Repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import com.vsmartengine.invoicebill.SaleInvoice.Entity.SaleInvoice;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

@Repository
public interface SaleInvoiceRepository 
    extends JpaRepository<SaleInvoice, Long> {

    // get all bills by company
    List<SaleInvoice> findByCompanyName(String companyName);

    // get all bills by company + bill type
    // used for listing — ESTIMATE / SALE / POS separately
    List<SaleInvoice> findByCompanyNameAndBillType(
        String companyName, String billType);

    // get single bill by id + company
    SaleInvoice findByIdAndCompanyName(
        Long id, String companyName);
    
 // find last bill for company
    SaleInvoice findTopByCompanyNameOrderByIdDesc(String companyName);
    
    List<SaleInvoice> findByPartyNameAndCompanyName(String partyName, String companyName);
    
    
 // Total Transactions — all bill types
    Long countByCompanyName(String companyName);

    // Total Revenue — all bill types (SALE + POS + ESTIMATE)
    @Query("SELECT COALESCE(SUM(s.grandTotal), 0) FROM SaleInvoice s WHERE s.companyName = :company")
    BigDecimal sumGrandTotalByCompanyName(@Param("company") String company);

    // Total Received — all bill types
    @Query("SELECT COALESCE(SUM(s.amountReceived), 0) FROM SaleInvoice s WHERE s.companyName = :company")
    BigDecimal sumAmountReceivedByCompanyName(@Param("company") String company);
    
 // When createdBy is null — no user filter
    List<SaleInvoice> findByCompanyNameAndBillTypeInAndInvoiceDateBetween(
        String companyName,
        List<String> billTypes,
        LocalDate fromDate,
        LocalDate toDate);

    // When createdBy is selected — with user filter
    List<SaleInvoice> findByCompanyNameAndBillTypeInAndInvoiceDateBetweenAndCreatedBy(
        String companyName,
        List<String> billTypes,
        LocalDate fromDate,
        LocalDate toDate,
        String createdBy);
    
    List<SaleInvoice> findByCompanyNameAndBillTypeInAndInvoiceDateBetweenAndCreatedByIn(
    	    String companyName,
    	    List<String> billTypes,
    	    LocalDate fromDate,
    	    LocalDate toDate,
    	    List<String> createdByList);
    
}