package com.vsmartengine.invoicebill.Items.Entity;

import lombok.*;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UnitDTO {

    private Long id;

    // e.g. "Kilogram", "Liter"
    private String name;

    // e.g. "kg", "L", "pcs"
    private String symbol;
    
    private Integer conversionValue;
    private String conversionUnit;
   

    
    private Long itemCount;

    // e.g. "1 Kilogram = 1000 Gram"
    private String conversionDisplay;
    
    
  
}