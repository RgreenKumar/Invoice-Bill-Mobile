package com.vsmartengine.invoicebill.Settings.Repo;

import org.springframework.data.jpa.repository.JpaRepository;

import com.vsmartengine.invoicebill.Settings.GeneralSettings;

import java.util.Optional;

public interface GeneralSettingsRepository extends JpaRepository<GeneralSettings, Long> {
    
    Optional<GeneralSettings> findByCompanyName(String companyName);
}