package com.vsmartengine.invoicebill.User.LabellingItems;


import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Lob;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Getter@Setter@NoArgsConstructor
public class Labelingitems {
	 @Id
	    @GeneratedValue(strategy = GenerationType.IDENTITY)
	    private Long id;
	 private String siteUrl;
	 @Lob
	    @Column(length=1000000)
	    private byte[] sitelogo;
	 
	 @Lob
	    @Column(length=1000000)
	    private byte[] siteicon;
	 
	 @Lob
	    @Column(length=1000000)
	    private byte[] titleicon;
	 private String title;
	 @Column(unique = true)
	 private String companyName;
}
