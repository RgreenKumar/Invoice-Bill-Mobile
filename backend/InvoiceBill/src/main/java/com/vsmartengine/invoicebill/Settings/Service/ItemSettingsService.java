package com.vsmartengine.invoicebill.Settings.Service;

import com.vsmartengine.invoicebill.Settings.ItemSettings;
import com.vsmartengine.invoicebill.Settings.ItemSettingsDto;
import com.vsmartengine.invoicebill.Settings.Repo.ItemSettingsRepository;
import com.vsmartengine.invoicebill.User.SecurityConfiguration.JwtUtil;

import lombok.RequiredArgsConstructor;

import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class ItemSettingsService {

    private final ItemSettingsRepository repo;
    private final JwtUtil jwtUtil;

    // ── GET ──────────────────────────────────────────────────
    public ItemSettings getSettings(String token) {

        String company = jwtUtil.getCompanyFromToken(token);

        return repo.findByCompanyName(company).orElseGet(() -> {

            // Default Settings
            ItemSettings defaults = new ItemSettings();

            defaults.setCompanyName(company);

            // Left Side
            defaults.setEnableItem(true);
            defaults.setStockMaintenance(true);
            defaults.setShowLowStockDialog(true);
            defaults.setItemsUnit(true);
            defaults.setDefaultUnit(null);
            defaults.setItemCategory(true);
            defaults.setDescription(false);
            defaults.setItemWiseTax(true);
            defaults.setItemWiseDiscount(true);
            defaults.setQuantityDecimalPlaces(2);
            defaults.setWholesalePrice(true);

            // Right Side
            defaults.setMrp(false);
            defaults.setCalculateTaxBasedOnMrp(false);

            defaults.setExpDate(true);
            defaults.setExpDateFormat("dd/mm/yy");

            defaults.setMfgDate(true);
            defaults.setMfgDateFormat("dd/mm/yy");

            defaults.setModelNo(false);
            defaults.setSize(false);

            return defaults;
        });
    }

    // ── SAVE ─────────────────────────────────────────────────
    public ItemSettings saveSettings(String token, ItemSettingsDto dto) {

        String company = jwtUtil.getCompanyFromToken(token);

        // ── Role check — only ADMIN allowed ──────────────────
        String role = jwtUtil.getRoleFromToken(token);

        if (!"ADMIN".equals(role)) {
            return null;
        }

        ItemSettings settings = repo.findByCompanyName(company)
                                    .orElse(new ItemSettings());

        settings.setCompanyName(company);

        // Left Side
        settings.setEnableItem(dto.getEnableItem());
        settings.setStockMaintenance(dto.getStockMaintenance());
        settings.setShowLowStockDialog(dto.getShowLowStockDialog());
        settings.setItemsUnit(dto.getItemsUnit());
        settings.setDefaultUnit(dto.getDefaultUnit());
        settings.setItemCategory(dto.getItemCategory());
        settings.setDescription(dto.getDescription());
        settings.setItemWiseTax(dto.getItemWiseTax());
        settings.setItemWiseDiscount(dto.getItemWiseDiscount());
        settings.setQuantityDecimalPlaces(dto.getQuantityDecimalPlaces());
        settings.setWholesalePrice(dto.getWholesalePrice());

        // Right Side
        settings.setMrp(dto.getMrp());
        settings.setCalculateTaxBasedOnMrp(dto.getCalculateTaxBasedOnMrp());

        settings.setExpDate(dto.getExpDate());
        settings.setExpDateFormat(dto.getExpDateFormat());

        settings.setMfgDate(dto.getMfgDate());
        settings.setMfgDateFormat(dto.getMfgDateFormat());

        settings.setModelNo(dto.getModelNo());
        settings.setSize(dto.getSize());

        return repo.save(settings);
    }
}