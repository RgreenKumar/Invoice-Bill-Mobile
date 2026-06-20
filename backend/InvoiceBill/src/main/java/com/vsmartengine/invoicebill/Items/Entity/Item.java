package com.vsmartengine.invoicebill.Items.Entity;



import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDate;

@Entity
@Table(name = "items")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Item {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
                                                          
    // e.g. "Rice", "Coconut Oil"
    @Column(name = "item_name", nullable = false, length = 200)
    private String itemName;

    // HSN code e.g. 1006, 1507
    @Column(name = "item_hsn", length = 50)
    private String itemHsn;

    // e.g. "ITM001", "ITM002"
    @Column(name = "item_code", unique = true, length = 50)
    private String itemCode;

    // FK → categories.id
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "category_id", referencedColumnName = "id")
    private Category category;

    // FK → units.id
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "unit_id", referencedColumnName = "id")
    private Unit unit;

    // Store image as binary in DB (max ~50KB enforced at service layer)
    @Lob
    @Column(name = "item_image", length = 1000000)
    private byte[] itemImage;

    @Column(name = "created_at")
    private LocalDate createdAt;
    
    @Column(name = "company", nullable = false, length = 100)
    private String company;
    
    @Column(name = "is_deleted")
    private Boolean isDeleted;

    @PrePersist
    public void prePersist() {
        if (this.createdAt == null) {
            this.createdAt = LocalDate.now();
        }
        if (this.isDeleted == null) {
            this.isDeleted = false;
        }
    }

  
}