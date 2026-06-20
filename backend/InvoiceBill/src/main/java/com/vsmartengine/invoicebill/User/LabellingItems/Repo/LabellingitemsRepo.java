package com.vsmartengine.invoicebill.User.LabellingItems.Repo;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import com.vsmartengine.invoicebill.User.LabellingItems.Labelingitems;

@Repository
public interface LabellingitemsRepo extends JpaRepository<Labelingitems, Long> {
	
	@Query("SELECT li FROM Labelingitems li WHERE li.companyName=:companyName")
	Optional<Labelingitems>FindbyCompany(String companyName);

}
