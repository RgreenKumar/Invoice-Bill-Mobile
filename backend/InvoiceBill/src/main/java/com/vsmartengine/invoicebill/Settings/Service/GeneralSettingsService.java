package com.vsmartengine.invoicebill.Settings.Service;

import com.vsmartengine.invoicebill.Settings.GeneralSettings;
import com.vsmartengine.invoicebill.Settings.GeneralSettingsDto;
import com.vsmartengine.invoicebill.Settings.Repo.GeneralSettingsRepository;
import com.vsmartengine.invoicebill.User.SecurityConfiguration.JwtUtil;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class GeneralSettingsService {

    private final GeneralSettingsRepository repo;
    private final JwtUtil jwtUtil;

    // ── GET ──────────────────────────────────────────────────
    public GeneralSettings getSettings(String token) {
        String company = jwtUtil.getCompanyFromToken(token);
        
        return repo.findByCompanyName(company).orElseGet(() -> {
            // If no settings saved yet → return defaults
            GeneralSettings defaults = new GeneralSettings();
            defaults.setCompanyName(company);
            defaults.setAmountDecimalPlaces(2);
            defaults.setGstinNumber(true);
            defaults.setEstimateQuotation(true);
            defaults.setSalesInvoiceOrder(true);
            defaults.setOtpservice(true);
            return defaults;
        });
    }

    // ── SAVE ─────────────────────────────────────────────────
    public GeneralSettings saveSettings(String token, GeneralSettingsDto dto) {
        String company = jwtUtil.getCompanyFromToken(token);
        
        // ── Role check — only ADMIN allowed ──────────────────
        String role = jwtUtil.getRoleFromToken(token);
        if (!"ADMIN".equals(role)) {
            return null; // CASHIER cannot change settings
        }

        GeneralSettings settings = repo.findByCompanyName(company)
                                       .orElse(new GeneralSettings());
        settings.setCompanyName(company);
        settings.setAmountDecimalPlaces(dto.getAmountDecimalPlaces());
        settings.setGstinNumber(dto.getGstinNumber());
        settings.setEstimateQuotation(dto.getEstimateQuotation());
        settings.setSalesInvoiceOrder(dto.getSalesInvoiceOrder());
        settings.setOtpservice(dto.getOtpservice());

        return repo.save(settings);
    }
}