package com.vsmartengine.invoicebill.User.Approvals;

import org.springframework.data.jpa.repository.JpaRepository;

import com.vsmartengine.invoicebill.User.CashierPermission;

import java.util.List;

public interface CashierPermissionRepository
        extends JpaRepository<CashierPermission, Long> {

    List<CashierPermission> findByUser_UserId(Long userId);

    void deleteByUser_UserId(Long userId);
}