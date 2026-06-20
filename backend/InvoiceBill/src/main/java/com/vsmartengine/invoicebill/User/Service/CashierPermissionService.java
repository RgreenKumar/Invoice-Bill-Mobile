package com.vsmartengine.invoicebill.User.Service;

import java.util.List;
import java.util.stream.Collectors;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.vsmartengine.invoicebill.User.CashierPermission;
import com.vsmartengine.invoicebill.User.CashierPermissionDto;
import com.vsmartengine.invoicebill.User.Muser;
import com.vsmartengine.invoicebill.User.Approvals.CashierPermissionRepository;

@Service
public class CashierPermissionService {

    @Autowired
    private CashierPermissionRepository cashierPermissionRepository;

    // Get permissions for a cashier by userId
    public List<CashierPermissionDto> getPermissions(Long userId) {
        return cashierPermissionRepository.findByUser_UserId(userId)
                .stream()
                .map(p -> new CashierPermissionDto(
                        p.getModuleName(),
                        p.getCanView(),
                        p.getCanCreate(),
                        p.getCanEdit(),
                        p.getCanDelete()
                ))
                .collect(Collectors.toList());
    }

    // Update permissions for a cashier
    @Transactional
    public void updatePermissions(Muser user, List<CashierPermissionDto> permissions) {
        // Delete old permissions
        cashierPermissionRepository.deleteByUser_UserId(user.getUserId());
        // Save new permissions
        List<CashierPermission> permList = permissions.stream().map(dto -> {
            CashierPermission p = new CashierPermission();
            p.setUser(user);
            p.setModuleName(dto.getModuleName());
            p.setCanView(dto.getCanView());
            p.setCanCreate(dto.getCanCreate());
            p.setCanEdit(dto.getCanEdit());
            p.setCanDelete(dto.getCanDelete());
            return p;
        }).collect(Collectors.toList());
        cashierPermissionRepository.saveAll(permList);
    }
}