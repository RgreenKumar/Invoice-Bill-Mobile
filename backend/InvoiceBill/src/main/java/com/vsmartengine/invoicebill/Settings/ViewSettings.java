package com.vsmartengine.invoicebill.Settings;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Getter
@Setter
@NoArgsConstructor
public class ViewSettings {

	 @Id
	    @GeneratedValue(strategy = GenerationType.IDENTITY)
	    private Long id;
        @Column(unique=true)
	    private String settingName;
	    private Boolean settingValue;
	    private String settingStrValue;
	    private Long settingLongValue;
		@Override
		public String toString() {
			return "ViewSettings [id=" + id + ", settingName=" + settingName + ", settingValue=" + settingValue + "]";
		}

}
