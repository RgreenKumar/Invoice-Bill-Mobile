package com.vsmartengine.invoicebill.Email;


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
public class Mailkeys {
	  @Id
	    @GeneratedValue(strategy = GenerationType.IDENTITY)
	    private Long id;
	  private String hostname;
	  private String emailid;
	  private String password;
	  private String port;
	  @Column(unique=true)
	  private String company;
	  

}
