package com.vsmartengine.invoicebill.Payments.repos;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import com.vsmartengine.invoicebill.Payments.Stripesettings;

public interface Striperepo extends JpaRepository<Stripesettings, Long> {
	@Query("SELECT u FROM Stripesettings u WHERE u.company_name = ?1")
	Optional<Stripesettings>findBycompanyName(String companyName);
	@Query("SELECT u.stripe_publish_key FROM Stripesettings u WHERE u.company_name = ?1")
	String findpublishkeybycompany(String companyName);

}
