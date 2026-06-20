package com.vsmartengine.invoicebill.User;

import java.time.LocalDate;

import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter@Setter@NoArgsConstructor
public class MuserRequiredDto {
	    private Long userId;
	    private String username;
	    private String email;
	    private String phone;
	    private Boolean isActive;
	    private LocalDate dob;
	    private String skills;
	    private String institutionName;
	    private byte[] profile;
	    private String countryCode;

	    public MuserRequiredDto(Long userId, String username, String email, String phone, Boolean isActive, LocalDate dob, String skills,String institutionName,byte[] profile, String countryCode) {
	        this.userId = userId;
	        this.username = username;
	        this.email = email;
	        this.phone = phone;
	        this.isActive = isActive;
	        this.dob = dob;
	        this.skills = skills;
	        this.institutionName=institutionName;
	        this.profile = profile;
	        this.countryCode = countryCode;
	    }

		public MuserRequiredDto(Long userId, String username, String email) {
			super();
			this.userId = userId;
			this.username = username;
			this.email = email;
		}
}
