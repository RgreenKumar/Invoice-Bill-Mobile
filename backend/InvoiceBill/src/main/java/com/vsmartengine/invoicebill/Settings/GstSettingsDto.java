package com.vsmartengine.invoicebill.Settings;

import lombok.Data;

@Data
public class GstSettingsDto {

    private Boolean enableGST;

    private Boolean enableHSN;

    private Boolean additionalCess;

    private Boolean enablePlaceOfSupply;
}