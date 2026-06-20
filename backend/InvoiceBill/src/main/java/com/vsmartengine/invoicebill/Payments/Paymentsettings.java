package com.vsmartengine.invoicebill.Payments;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
@Entity
@Table(name="payment_settings")
public class Paymentsettings {

	@Id
	@GeneratedValue(strategy=GenerationType.IDENTITY)
	private long id;
	@Column (name ="razorpay_key")
	private String razorpay_key;
	
	@Column (name ="razorpay_secret_key")
	private String razorpay_secret_key;
	
	@Column (name ="companyName" ,unique =true)
	private String companyName;
	
	  public String getcompanyName() {
		return companyName;
	}
	public void setcompanyName(String companyName) {
		this.companyName = companyName;
	}
	public Paymentsettings() {
	        // Default constructor is empty
	    }
	public long getId() {
		return id;
	}

	public void setId(long id) {
		this.id = id;
	}

	
	public String getRazorpay_key() {
		return razorpay_key;
	}

	public void setRazorpay_key(String razorpay_key) {
		this.razorpay_key = razorpay_key;
	}

	public String getRazorpay_secret_key() {
		return razorpay_secret_key;
	}

	public void setRazorpay_secret_key(String razorpay_secret_key) {
		this.razorpay_secret_key = razorpay_secret_key;
	}
	public Paymentsettings(long id, String razorpay_key, String razorpay_secret_key) {
		super();
		this.id = id;
		this.razorpay_key = razorpay_key;
		this.razorpay_secret_key = razorpay_secret_key;
	}
	
	

}
