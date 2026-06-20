package com.vsmartengine.invoicebill.MyCompany.Service;

import com.vsmartengine.invoicebill.MyCompany.Entity.MyCompanyDto;
import com.vsmartengine.invoicebill.MyCompany.Entity.MyCompany;
import com.vsmartengine.invoicebill.MyCompany.Repository.MyCompanyRepository;
import com.vsmartengine.invoicebill.User.SecurityConfiguration.JwtUtil;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import java.util.Base64;

@Service
@RequiredArgsConstructor
public class MyCompanyService {

    private final MyCompanyRepository repo;
    private final JwtUtil jwtUtil;

    // ── GET ──────────────────────────────────────────────────
    public MyCompany getMyCompany(String token) {
        String company = jwtUtil.getCompanyFromToken(token);
        Long userId = jwtUtil.getUserIdFromToken(token);

        return repo.findByUserIdAndCompanyAndIsDeletedFalse(userId, company)
                   .orElse(null);
    }

    // ── SAVE / UPDATE ─────────────────────────────────────────
    public MyCompany saveMyCompany(String token, MyCompanyDto dto) {
        String company = jwtUtil.getCompanyFromToken(token);
        Long userId = jwtUtil.getUserIdFromToken(token);

        // ── Role check — only ADMIN allowed ──────────────────
        String role = jwtUtil.getRoleFromToken(token);
        if (!"ADMIN".equals(role)) {
            return null;
        }

        // ── If record exists update, else create new ──────────
        MyCompany myCompany = repo.findByUserIdAndCompanyAndIsDeletedFalse(userId, company)
                                  .orElse(new MyCompany());

        myCompany.setCompany(company);
        myCompany.setUserId(userId);
        myCompany.setBusinessName(dto.getBusinessName());
        myCompany.setPhoneNumber(dto.getPhoneNumber());
        myCompany.setCountryCode(dto.getCountryCode());
        myCompany.setEmailId(dto.getEmailId());
        myCompany.setGstin(dto.getGstin());
        myCompany.setBusinessType(dto.getBusinessType());
        myCompany.setBusinessCategory(dto.getBusinessCategory());
        myCompany.setState(dto.getState());
        myCompany.setPincode(dto.getPincode());
        myCompany.setBusinessAddress(dto.getBusinessAddress());

        // ── Convert Base64 → byte[] only if new image sent ────
        if (dto.getLogo() != null && !dto.getLogo().isEmpty()) {
            myCompany.setLogo(Base64.getDecoder().decode(dto.getLogo()));
        }
        if (dto.getSignature() != null && !dto.getSignature().isEmpty()) {
            myCompany.setSignature(Base64.getDecoder().decode(dto.getSignature()));
        }

        return repo.save(myCompany);
    }
}