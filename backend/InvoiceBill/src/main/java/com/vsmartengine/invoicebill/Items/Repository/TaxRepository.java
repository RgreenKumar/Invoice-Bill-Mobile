	package com.vsmartengine.invoicebill.Items.Repository;
	
	import java.util.List;
	import org.springframework.data.jpa.repository.JpaRepository;
	import org.springframework.stereotype.Repository;
	import com.vsmartengine.invoicebill.Items.Entity.Tax;
	
	@Repository
	public interface TaxRepository extends JpaRepository<Tax, Long> {
	
	   
	    List<Tax> findByCompany(String company);
	
	    
	    boolean existsByNameAndCompany(String name, String company);
	
	   
	    Tax findByIdAndCompany(Long id, String company);
	
	    
	    boolean existsByIdAndCompany(Long id, String company);
	}