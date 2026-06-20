package com.vsmartengine.invoicebill.Payments.repos;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import com.vsmartengine.invoicebill.Payments.Paymentsettings;

@Repository
public interface PaymentsettingRepository extends JpaRepository<Paymentsettings, Long> {

	@Query("SELECT u FROM Paymentsettings u WHERE u.companyName = ?1")
	Optional<Paymentsettings>findBycompanyName(String companyName);
}


