package com.vsmartengine.invoicebill.Settings;

import jakarta.persistence.*;
import lombok.Data;

@Entity
@Table(name = "gst_settings")
@Data
public class GstSettings {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String companyName; // from JWT token

    private Boolean enableGST;

    private Boolean enableHSN;

    private Boolean additionalCess;

    private Boolean enablePlaceOfSupply;
}