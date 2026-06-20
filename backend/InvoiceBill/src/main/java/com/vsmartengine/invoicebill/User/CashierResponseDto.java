package com.vsmartengine.invoicebill.User;

import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class CashierResponseDto {
    private Long userId;
    private String username;
    private String email;
    private String phone;
    private Boolean isActive;
}