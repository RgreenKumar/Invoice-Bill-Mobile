package com.vsmartengine.invoicebill.MyCompany.Entity;

import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
public class MyCompanyDto {

    private Long id;
    private Long userId;
    private String businessName;
    private String phoneNumber;
    private String countryCode;
    private String emailId;
    private String gstin;
    private String businessType;
    private String businessCategory;
    private String state;
    private String pincode;
    private String businessAddress;
    private String logo;        
    private String signature;   
}