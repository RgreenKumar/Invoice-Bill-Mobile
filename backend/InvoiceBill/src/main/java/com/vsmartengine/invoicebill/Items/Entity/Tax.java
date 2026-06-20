	package com.vsmartengine.invoicebill.Items.Entity;
	
	
	
	
	import jakarta.persistence.*;
	import lombok.*;
	import java.math.BigDecimal;
	 
	@Entity
	@Table(name = "taxes")
	@Data
	@NoArgsConstructor
	@AllArgsConstructor
	@Builder
	public class Tax {
	 
	    @Id
	    @GeneratedValue(strategy = GenerationType.IDENTITY)
	    private Long id;
	 
	    @Column(name = "name", nullable = false, length = 100)
	    private String name;
	 
	    // e.g. 5.00, 12.00, 18.00
	    @Column(name = "rate", nullable = false, precision = 5, scale = 2)
	    private BigDecimal rate;
	 
	    // e.g. "percentage"
	    @Column(name = "type", nullable = false, length = 50)
	    private String type;
	    
	    @Column(name = "company", nullable = false, length = 100)
	    private String company;
	}