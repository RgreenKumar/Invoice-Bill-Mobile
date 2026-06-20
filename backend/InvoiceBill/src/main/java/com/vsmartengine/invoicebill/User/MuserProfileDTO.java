package com.vsmartengine.invoicebill.User;


import java.time.LocalDateTime;

import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter@Setter@NoArgsConstructor
public class MuserProfileDTO {
	 private byte[] profile;
	    private String countryCode;
	    private String roleName;
        private LocalDateTime lastactive;
        
	    public MuserProfileDTO(byte[] profile, String countryCode, String roleName,LocalDateTime lastactive) {
	        this.profile = profile;
	        this.countryCode = countryCode;
	        this.roleName = roleName;
	        this.lastactive=lastactive;
	    }
	    public MuserProfileDTO(byte[] profile, String countryCode, String roleName) {
	    	 this.profile = profile;
		        this.countryCode = countryCode;
		        this.roleName = roleName;
	    }

}
