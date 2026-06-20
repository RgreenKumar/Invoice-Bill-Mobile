package com.vsmartengine.invoicebill.Payments.repos;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import com.vsmartengine.invoicebill.Payments.Paypalsettings;

@Repository
public interface paypalrepo extends JpaRepository<Paypalsettings, Long> {

	@Query("SELECT p FROM Paypalsettings p WHERE p.companyName=:companyName")
	Optional<Paypalsettings>FindByCompanyName(String companyName);
}
