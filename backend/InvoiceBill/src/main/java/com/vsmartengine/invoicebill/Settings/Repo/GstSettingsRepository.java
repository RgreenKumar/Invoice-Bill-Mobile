package com.vsmartengine.invoicebill.Settings.Repo;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.vsmartengine.invoicebill.Settings.GstSettings;

import java.util.Optional;

@Repository
public interface GstSettingsRepository extends JpaRepository<GstSettings, Long> {

    Optional<GstSettings> findByCompanyName(String companyName);
}