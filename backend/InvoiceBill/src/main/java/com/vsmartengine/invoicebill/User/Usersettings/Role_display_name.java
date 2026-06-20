package com.vsmartengine.invoicebill.User.Usersettings;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
@Getter
@Setter@NoArgsConstructor
@Entity
@Table
public class Role_display_name {
	 @Id
	    @GeneratedValue(strategy = GenerationType.IDENTITY)
	    private Long Id;
	   private String Admin_name;
	   private String Trainer_name;
	   private String Student_name;
	   @Column(unique = true)
	   private String company;
	  private Boolean isActive;
	   
}
