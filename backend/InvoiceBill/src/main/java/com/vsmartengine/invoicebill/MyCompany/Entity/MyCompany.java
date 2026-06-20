package com.vsmartengine.invoicebill.MyCompany.Entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDate;

@Entity
@Table(name = "my_company")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class MyCompany {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // VPS tenant identifier - same pattern as Item entity
    @Column(name = "company", nullable = false, length = 100)
    private String company;

    // FK → user.id (one company per admin)
    @Column(name = "user_id", nullable = false, unique = true)
    private Long userId;

    // Business name admin types in the form
    @Column(name = "business_name", nullable = false, length = 255)
    private String businessName;

    // Overrides user.phone if admin changes it
    @Column(name = "phone_number", length = 20)
    private String phoneNumber;
    
    @Column(name = "country_code", length = 10)
    private String countryCode;

    // Overrides user.email if admin changes it
    @Column(name = "email_id", length = 255)
    private String emailId;

    // Overrides user.gstin if admin changes it
    @Column(name = "gstin", length = 15)
    private String gstin;

    // e.g. "Sole Proprietor", "Pvt Ltd", "Partnership"
    @Column(name = "business_type", length = 100)
    private String businessType;

    // e.g. "Retail", "Wholesale", "Manufacturing"
    @Column(name = "business_category", length = 100)
    private String businessCategory;

    // Indian state name
    @Column(name = "state", length = 100)
    private String state;

    @Column(name = "pincode", length = 10)
    private String pincode;

    @Column(name = "business_address", columnDefinition = "TEXT")
    private String businessAddress;

    // Company logo stored as binary (same pattern as item_image)
    @Lob
    @Column(name = "logo", length = 1000000)
    private byte[] logo;

    // Handwritten signature image stored as binary
    @Lob
    @Column(name = "signature", length = 1000000)
    private byte[] signature;

    @Column(name = "created_at")
    private LocalDate createdAt;

    @Column(name = "updated_at")
    private LocalDate updatedAt;

    @Column(name = "is_deleted")
    private Boolean isDeleted;

    @PrePersist
    public void prePersist() {
        if (this.createdAt == null) {
            this.createdAt = LocalDate.now();
        }
        if (this.updatedAt == null) {
            this.updatedAt = LocalDate.now();
        }
        if (this.isDeleted == null) {
            this.isDeleted = false;
        }
    }

    @PreUpdate
    public void preUpdate() {
        this.updatedAt = LocalDate.now();
    }
}