package com.vsmartengine.invoicebill.Items.Entity;


import jakarta.persistence.*;
import lombok.*;
 
@Entity
@Table(name = "units")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Unit {
 
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
 
    @Column(name = "name", nullable = false, length = 100)
    private String name;
 
    @Column(name = "symbol", nullable = false, length = 20)
    private String symbol;
    
    // e.g. 1000, 100, 1
    @Column(name = "conversion_value")
    private Integer conversionValue;

    // e.g. "Gram", "ML", "CM", "Piece"
    @Column(name = "conversion_unit", length = 50)
    private String conversionUnit;
    
    @Column(name = "company", nullable = false, length = 100)
    private String company;
}