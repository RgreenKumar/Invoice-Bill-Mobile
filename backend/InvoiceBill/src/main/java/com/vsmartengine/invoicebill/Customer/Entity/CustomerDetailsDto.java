package com.vsmartengine.invoicebill.Customer.Entity;

import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import java.math.BigDecimal;
import java.time.LocalDate;

@Getter
@Setter
@NoArgsConstructor
public class CustomerDetailsDto {

    private String name;

    private String gstin;

    private String phone;

    private String email;

    private String gstType;

    private String state;

    private String billingAddress;

    private String shippingAddress;

    private BigDecimal openingBalance;

    private LocalDate asOfDate;

    private Boolean creditLimit;

    private BigDecimal creditAmount;

    private String aadhaarNo;

    private String drugLicenseNo;

    private String panNo;

    private String partyType;  // SUPPLIER or CUSTOMER

}