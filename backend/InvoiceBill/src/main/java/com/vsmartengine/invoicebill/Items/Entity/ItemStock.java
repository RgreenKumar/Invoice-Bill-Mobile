package com.vsmartengine.invoicebill.Items.Entity;




import jakarta.persistence.*;
import lombok.*;
import java.math.BigDecimal;
import java.time.LocalDate;
 
@Entity
@Table(name = "item_stock")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ItemStock {
 
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
 
    // FK → items.id
    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "item_id", referencedColumnName = "id", nullable = false)
    private Item item;
 
    // e.g. 100, 50, 200
    @Column(name = "opening_stock")
    private Integer openingStock;
 
    // price at which stock was added e.g. 40.00
    @Column(name = "stock_at_price", precision = 10, scale =4 )
    private BigDecimal stockAtPrice;
 
    // date stock was recorded e.g. 2026-04-24
    @Column(name = "stock_as_of_date")
    private LocalDate stockAsOfDate;
 
    // minimum stock alert threshold e.g. 10, 5, 20
    @Column(name = "min_stock_qty")
    private Integer minStockQty;
 
    // e.g. "Warehouse A", "Warehouse B"
    @Column(name = "location", length = 200)
    private String location;
 
    @Column(name = "created_at")
    private LocalDate createdAt;
 
    @PrePersist
    public void prePersist() {
        if (this.createdAt == null) {
            this.createdAt = LocalDate.now();
        }
    }
}
 