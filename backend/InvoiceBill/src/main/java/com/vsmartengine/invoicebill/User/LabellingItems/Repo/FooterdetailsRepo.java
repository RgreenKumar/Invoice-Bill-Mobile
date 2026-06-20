package com.vsmartengine.invoicebill.User.LabellingItems.Repo;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import com.vsmartengine.invoicebill.User.LabellingItems.FooterDetails;

@Repository
public interface FooterdetailsRepo extends JpaRepository<FooterDetails, Long> {
    @Query("SELECT fd FROM FooterDetails fd WHERE fd.companyName=:companyName")
	Optional<FooterDetails>FindFooterDetailsByCompany(String companyName);
}
