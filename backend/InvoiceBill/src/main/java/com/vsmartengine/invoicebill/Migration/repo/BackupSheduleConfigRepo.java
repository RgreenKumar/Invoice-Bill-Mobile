package com.vsmartengine.invoicebill.Migration.repo;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import com.vsmartengine.invoicebill.Migration.model.BackupScheduleConfig;

@Repository
public interface BackupSheduleConfigRepo extends JpaRepository<BackupScheduleConfig, Long> {
	@Query("SELECT b FROM BackupScheduleConfig b WHERE b.companyName=:company ")
	Optional<BackupScheduleConfig> findByCompanyName(@Param("company") String company);

}
