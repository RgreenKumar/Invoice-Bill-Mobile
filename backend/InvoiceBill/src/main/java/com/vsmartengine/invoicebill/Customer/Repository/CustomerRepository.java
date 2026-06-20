package com.vsmartengine.invoicebill.Customer.Repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import com.vsmartengine.invoicebill.Customer.Entity.CustomerDetails;

import java.util.List;

@Repository
public interface CustomerRepository 
    extends JpaRepository<CustomerDetails, Long> {

    // Get all SUPPLIERS for a company
    List<CustomerDetails> findByCompanyAndPartyTypeAndIsActive(
        String company, 
        String partyType, 
        Boolean isActive
    );

    // Get single party by id and company
    CustomerDetails findByIdAndCompany(
        Long id, 
        String company
    );
    
 // search customer by name or phone
   @Query("SELECT c FROM CustomerDetails c " +
    	       "WHERE c.company = :company " +
    	       "AND c.isActive = true " +
    	       "AND (LOWER(c.name) LIKE LOWER(CONCAT('%', :keyword, '%')) " +
    	       "OR c.phone LIKE CONCAT('%', :keyword, '%'))")
    	List<CustomerDetails> searchByNameOrPhone(
    	    @Param("keyword") String keyword,
    	    @Param("company") String company);
    
    Long countByCompanyAndPartyType(String company, String partyType);
    
    Long countByCompany(String company);
}