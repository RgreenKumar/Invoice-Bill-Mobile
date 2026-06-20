package com.vsmartengine.invoicebill.Settings;

import lombok.Data;

@Data
public class GeneralSettingsDto {

    private Integer amountDecimalPlaces;

    private Boolean gstinNumber;

    private Boolean estimateQuotation;

    private Boolean salesInvoiceOrder;
    
    private Boolean otpservice;
}