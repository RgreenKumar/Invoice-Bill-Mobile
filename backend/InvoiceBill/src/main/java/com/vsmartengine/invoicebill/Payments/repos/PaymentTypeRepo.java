package com.vsmartengine.invoicebill.Payments.repos;

import java.util.List;
import java.util.Map;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import com.vsmartengine.invoicebill.Payments.Payment_Type;

@Repository
public interface PaymentTypeRepo extends JpaRepository<Payment_Type, Long>{

	@Query("SELECT pt.isActive FROM Payment_Type pt WHERE pt.companyName=:companyName AND pt.paymentTypeName=:typeName  ")
	Boolean findisActivebycompanyNameAndTypeName(String companyName,String typeName);
	
	@Query("SELECT pt FROM Payment_Type pt WHERE pt.companyName=:companyName AND pt.paymentTypeName=:typeName  ")
	Optional<Payment_Type> findPaymentTypecompanyNameAndTypeName(String companyName,String typeName);
	
	@Query("SELECT p.paymentTypeName AS name, p.isActive AS active " +
		       "FROM Payment_Type p WHERE p.companyName = :companyName")
		List<Map<String, Object>> findByCompanyNameAsMap(@Param("companyName") String companyName);

}
