package com.vsmartengine.invoicebill.User.LabellingItems;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Getter@Setter@NoArgsConstructor
public class FooterDetails {

	 @Id
	    @GeneratedValue(strategy = GenerationType.IDENTITY)
	    private Long id;
	 private String   copyright;
	  private String  contact;
	  private String  supportmail;
	  private String  companymail;
	  @Column(unique=true)
	  private String companyName;
}
