package com.vsmartengine.invoicebill.Items.Entity;


import jakarta.persistence.*;
import lombok.*;
 
@Entity
@Table(name = "categories")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Category {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
     
    @Column(name = "name", nullable = false, length = 100)
    private String name;
    
    @Column(name = "company", nullable = false, length = 100)
    private String company;
}
 