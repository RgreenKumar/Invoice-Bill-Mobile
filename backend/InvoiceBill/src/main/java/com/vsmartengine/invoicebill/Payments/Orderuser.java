package com.vsmartengine.invoicebill.Payments;


import java.util.Date;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table
@Getter@Setter@NoArgsConstructor
public class Orderuser {
	   @Id
	    @GeneratedValue(strategy = GenerationType.IDENTITY)
	    private Long id;
	    private String companyName;
	    private String PaymentType;
	    private String orderId;
	    private Long userId;
	    private String courseName;
	    private String email;
	    private String username;
	    private Long courseId;
	    private String paymentId;
	    private Long batchId;
	    private String batchName;
	    private Long installmentnumber;
	    @Column(columnDefinition = "Varchar(50)")
	    private String status;
	    private int amountReceived;
	    private Date date;
 
}
