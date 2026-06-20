package com.vsmartengine.invoicebill.User;

import java.util.List;

import com.fasterxml.jackson.annotation.JsonIgnore;

import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.OneToMany;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Getter@Setter@NoArgsConstructor
public class MuserRoles {
	 @Id
	    @GeneratedValue(strategy = GenerationType.IDENTITY)
	    private Long roleId;
	    private String roleName;
	    private Boolean isActive;
	    @OneToMany(mappedBy = "role", fetch = FetchType.LAZY)
	    @JsonIgnore
	    private List<Muser> users;
}
