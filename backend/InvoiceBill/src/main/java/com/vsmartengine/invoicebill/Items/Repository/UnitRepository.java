	package com.vsmartengine.invoicebill.Items.Repository;
	
	import java.util.List;
	import org.springframework.data.jpa.repository.JpaRepository;
	import org.springframework.stereotype.Repository;
	import com.vsmartengine.invoicebill.Items.Entity.Unit;
	
	@Repository
	public interface UnitRepository extends JpaRepository<Unit, Long> {
	
	    
	    List<Unit> findByCompany(String company);
	
	    
	    boolean existsByNameAndCompany(String name, String company);
	
	    
	    Unit findByIdAndCompany(Long id, String company);
	
	    
	    boolean existsByIdAndCompany(Long id, String company);
	    
	
	    List<Unit> findByCompanyIn(List<String> companies);
	}