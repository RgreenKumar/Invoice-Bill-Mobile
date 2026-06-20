package com.vsmartengine.invoicebill.Payments;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(
    uniqueConstraints = @UniqueConstraint(columnNames = {"payment_type_name", "institution_name"})
)
@Getter
@Setter
@NoArgsConstructor
public class Payment_Type {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long paymentTypeId;

    @Column(name="payment_type_name",columnDefinition = "Varchar(50)")
    private String paymentTypeName;

    @Column(name = "company_name")
    private String companyName;

    @Column(name = "is_active")
    private Boolean isActive;
    
    
    public Payment_Type(Boolean isActive, String paymentTypeName) {
        this.isActive = isActive;
        this.paymentTypeName = paymentTypeName;
    }
}
