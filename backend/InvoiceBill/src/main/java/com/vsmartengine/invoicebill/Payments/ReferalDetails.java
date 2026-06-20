
package com.vsmartengine.invoicebill.Payments;



import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
@Entity@Table
@Getter@Setter
@NoArgsConstructor
public class ReferalDetails {
	@Id
	@GeneratedValue(strategy=GenerationType.IDENTITY)
	private Long id;
	@Column(columnDefinition = "Varchar(100)")
	private String Referalcode;
	private String name;
	private String email;
	private String contactNumber;
	private Long Discountpercent;
	private Long BenifitAmount;

}
