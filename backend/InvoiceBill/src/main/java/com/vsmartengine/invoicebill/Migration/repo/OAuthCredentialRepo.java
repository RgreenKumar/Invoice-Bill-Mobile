package com.vsmartengine.invoicebill.Migration.repo;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import com.vsmartengine.invoicebill.Migration.model.OAuthCredential;

@Repository
public interface OAuthCredentialRepo extends JpaRepository<OAuthCredential, Long> {

	@Query("SELECT c FROM OAuthCredential c WHERE c.companyName=:companyName")
	Optional<OAuthCredential> findByCompanyName(@Param("companyName") String companyName);

	@Query("SELECT c FROM OAuthCredential c WHERE c.companyName='Meganartech'")
	Optional<OAuthCredential> getDefaultKeys();
}
