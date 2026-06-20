package com.vsmartengine.invoicebill.Items.Entity;

import lombok.*;
import java.math.BigDecimal;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class TaxDTO {

    private Long id;

    // e.g. "GST 5%", "GST 12%"
    private String name;

    // e.g. 5.00, 12.00, 18.00
    private BigDecimal rate;

    // e.g. "percentage"
    private String type;
    
    private String company;
}