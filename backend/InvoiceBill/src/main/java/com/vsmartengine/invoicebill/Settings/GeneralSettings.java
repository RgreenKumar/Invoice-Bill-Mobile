package com.vsmartengine.invoicebill.Settings;

import jakarta.persistence.*;
import lombok.Data;

@Entity
@Table(name = "general_settings")
@Data
public class GeneralSettings {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String companyName; // from JWT token — each company has own settings

    private Integer amountDecimalPlaces; // e.g. 2

    private Boolean gstinNumber;       // checkbox

    private Boolean estimateQuotation; // checkbox

    private Boolean salesInvoiceOrder; // checkbox
    
    private Boolean otpservice;
}