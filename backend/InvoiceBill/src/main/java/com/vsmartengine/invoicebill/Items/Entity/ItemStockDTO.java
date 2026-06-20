package com.vsmartengine.invoicebill.Items.Entity;

import lombok.*;
import java.math.BigDecimal;
import java.time.LocalDate;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ItemStockDTO {

    private Long id;

    // item reference — only id needed in DTO
    private Long itemId;

    // e.g. 100, 50, 200
    private Integer openingStock;

    // e.g. 40.00, 95.00
    private BigDecimal stockAtPrice;

    // e.g. 2026-04-24
    private LocalDate stockAsOfDate;

    // e.g. 10, 5, 20
    private Integer minStockQty;

    // e.g. "Warehouse A", "Warehouse B"
    private String location;

    private LocalDate createdAt;
}