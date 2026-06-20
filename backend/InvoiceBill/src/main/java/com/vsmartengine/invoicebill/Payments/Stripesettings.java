package com.vsmartengine.invoicebill.Payments;

import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name="stripe_settings")
@NoArgsConstructor
@Getter
@Setter
public class Stripesettings {
	@Id
	@GeneratedValue(strategy=GenerationType.IDENTITY)
	private long id;
	
	private String stripe_publish_key;

	private String stripe_secret_key;
	
	private String company_name;
	
}
