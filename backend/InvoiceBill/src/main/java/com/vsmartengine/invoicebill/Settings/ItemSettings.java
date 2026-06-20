package com.vsmartengine.invoicebill.Settings;

import jakarta.persistence.*;
import lombok.Data;

@Entity
@Table(name = "item_settings")
@Data
public class ItemSettings {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String companyName; // from JWT token

    // Left Side - Item Settings
    private Boolean enableItem;

    private Boolean stockMaintenance;

    private Boolean showLowStockDialog;

    private Boolean itemsUnit;

    private String defaultUnit;

    private Boolean itemCategory;

    private Boolean description;

    private Boolean itemWiseTax;

    private Boolean itemWiseDiscount;

    private Integer quantityDecimalPlaces;

    private Boolean wholesalePrice;

    // Right Side - Additional Item Fields

    // MRP / Price
    private Boolean mrp;

    private Boolean calculateTaxBasedOnMrp;

    // Expiry Date
    private Boolean expDate;

    private String expDateFormat;

    // Manufacturing Date
    private Boolean mfgDate;

    private String mfgDateFormat;

    // Model Number
    private Boolean modelNo;

    // Size
    private Boolean size;
}