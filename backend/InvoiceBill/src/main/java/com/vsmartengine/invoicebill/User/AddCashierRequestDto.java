package com.vsmartengine.invoicebill.User;

import java.util.List;
import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class AddCashierRequestDto {
    private String username;
    private String email;
    private String phone;
    private List<CashierPermissionDto> permissions;
}