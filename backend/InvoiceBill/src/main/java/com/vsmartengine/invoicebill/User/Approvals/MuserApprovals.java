package com.vsmartengine.invoicebill.User.Approvals;

import java.time.LocalDate;
import java.time.LocalDateTime;

import com.vsmartengine.invoicebill.User.MuserRoles;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.Lob;
import jakarta.persistence.ManyToOne;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
@Entity
@Getter@Setter@NoArgsConstructor
public class MuserApprovals {
	 @Id
	    @GeneratedValue(strategy = GenerationType.IDENTITY)
	    private Long userId;
	    private String username;
	    private String psw;
	    @Column(unique = true)
	    private String email;
	    private LocalDate dob;
	    private String phone;
	    private String skills;
	    @Column
	    private String companyName;
	    @Lob
	    @Column(name="profile" ,length=1000000)
	    private byte[] profile;
	    @ManyToOne
	    @JoinColumn(name = "roleId")
	    private MuserRoles role;
	    @Column( columnDefinition = "varchar(10)")
	    private String countryCode;
	    private Boolean isActive=true;
	    private LocalDateTime lastactive;
	    private String inactiveDescription;

}
