package com.vsmartengine.invoicebill.User.Approvals;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

@Repository
public interface MuserApprovalRepo extends JpaRepository<MuserApprovals, Long> {
	@Query("SELECT u FROM MuserApprovals u WHERE u.email = ?1")
	  Optional<MuserApprovals> findByEmail(String email);
}
