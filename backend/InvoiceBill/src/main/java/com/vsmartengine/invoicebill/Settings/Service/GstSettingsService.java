package com.vsmartengine.invoicebill.Settings.Service;

import com.vsmartengine.invoicebill.Settings.GstSettings;
import com.vsmartengine.invoicebill.Settings.GstSettingsDto;
import com.vsmartengine.invoicebill.Settings.Repo.GstSettingsRepository;
import com.vsmartengine.invoicebill.User.SecurityConfiguration.JwtUtil;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class GstSettingsService {

    private final GstSettingsRepository repo;
    private final JwtUtil jwtUtil;

    // ── GET ──────────────────────────────────────────────────
    public GstSettings getSettings(String token) {
        String company = jwtUtil.getCompanyFromToken(token);

        return repo.findByCompanyName(company).orElseGet(() -> {
            // If no settings saved yet → return defaults
            GstSettings defaults = new GstSettings();
            defaults.setCompanyName(company);
            defaults.setEnableGST(true);
            defaults.setEnableHSN(true);
            defaults.setAdditionalCess(false);
            defaults.setEnablePlaceOfSupply(true);
            return defaults;
        });
    }

    // ── SAVE ─────────────────────────────────────────────────
    public GstSettings saveSettings(String token, GstSettingsDto dto) {
        String company = jwtUtil.getCompanyFromToken(token);

        // ── Role check — only ADMIN allowed ──────────────────
        String role = jwtUtil.getRoleFromToken(token);
        if (!"ADMIN".equals(role)) {
            return null; // CASHIER cannot change settings
        }

        GstSettings settings = repo.findByCompanyName(company)
                                   .orElse(new GstSettings());
        settings.setCompanyName(company);
        settings.setEnableGST(dto.getEnableGST());
        settings.setEnableHSN(dto.getEnableHSN());
        settings.setAdditionalCess(dto.getAdditionalCess());
        settings.setEnablePlaceOfSupply(dto.getEnablePlaceOfSupply());

        return repo.save(settings);
    }
}