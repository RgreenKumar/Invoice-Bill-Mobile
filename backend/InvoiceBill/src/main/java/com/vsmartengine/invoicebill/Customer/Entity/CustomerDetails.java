package com.vsmartengine.invoicebill.Customer.Entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Getter
@Setter
@NoArgsConstructor
@Entity
@Table(name = "customer_details")
public class CustomerDetails {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String company;

    @Column(nullable = false)
    private String name;

    private String gstin;

    private String phone;

    private String email;

    private String gstType;

    private String state;

    @Column(columnDefinition = "TEXT")
    private String billingAddress;

    @Column(columnDefinition = "TEXT")
    private String shippingAddress;

    private BigDecimal openingBalance;

    private LocalDate asOfDate;

    private Boolean creditLimit;

    private BigDecimal creditAmount;

    private String aadhaarNo;

    private String drugLicenseNo;

    private String panNo;

    @Column(nullable = false)
    private String partyType;  // SUPPLIER or CUSTOMER

    private Boolean isActive;

    private LocalDateTime createdAt;

    @PrePersist
    protected void onCreate() {
        this.createdAt = LocalDateTime.now();
        this.isActive = true;
    }
}