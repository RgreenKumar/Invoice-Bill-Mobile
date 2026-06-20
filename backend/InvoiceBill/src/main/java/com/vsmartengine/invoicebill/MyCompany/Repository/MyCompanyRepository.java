package com.vsmartengine.invoicebill.MyCompany.Repository;

import com.vsmartengine.invoicebill.MyCompany.Entity.MyCompany;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface MyCompanyRepository extends JpaRepository<MyCompany, Long> {

    // Find my company by userId and company (tenant)
    Optional<MyCompany> findByUserIdAndCompanyAndIsDeletedFalse(Long userId, String company);

    // Check if record exists
    boolean existsByUserIdAndCompany(Long userId, String company);
}