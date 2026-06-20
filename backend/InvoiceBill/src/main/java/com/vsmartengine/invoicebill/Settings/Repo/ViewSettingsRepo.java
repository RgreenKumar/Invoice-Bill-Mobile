package com.vsmartengine.invoicebill.Settings.Repo;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

import com.vsmartengine.invoicebill.Settings.ViewSettings;

public interface ViewSettingsRepo extends JpaRepository<ViewSettings, Long>{
	 Optional<ViewSettings> findBySettingName(String settingName);
}
