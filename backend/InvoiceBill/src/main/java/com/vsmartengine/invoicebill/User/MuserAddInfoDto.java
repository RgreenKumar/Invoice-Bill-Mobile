package com.vsmartengine.invoicebill.User;


import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class MuserAddInfoDto {
	private Long adminCount;
    private String companyName;
    private String adminEmail;
    private boolean emailExists;
	@Override
	public String toString() {
		return "MuserAddInfoDto [adminCount=" + adminCount + ", companyName=" + companyName + ", adminEmail="
				+ adminEmail + ", emailExists=" + emailExists + "]";
	} 
}
