package com.vsmartengine.invoicebill.Settings.Repo;

import org.springframework.data.jpa.repository.JpaRepository;

import com.vsmartengine.invoicebill.Settings.ItemSettings;

import java.util.Optional;

public interface ItemSettingsRepository extends JpaRepository<ItemSettings, Long> {

    Optional<ItemSettings> findByCompanyName(String companyName);
}