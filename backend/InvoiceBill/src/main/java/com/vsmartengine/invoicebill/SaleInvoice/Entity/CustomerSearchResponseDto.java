package com.vsmartengine.invoicebill.SaleInvoice.Entity;

import lombok.*;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class CustomerSearchResponseDto {

    private Long id;
    private String name;
    private String phone;
    private String gstin;
    private String state;
    private String billingAddress;
}