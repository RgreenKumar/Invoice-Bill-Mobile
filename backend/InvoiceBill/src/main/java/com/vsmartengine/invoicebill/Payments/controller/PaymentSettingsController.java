package com.vsmartengine.invoicebill.Payments.controller;

import java.util.Optional;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.RestController;

import com.vsmartengine.invoicebill.Payments.Paymentsettings;
import com.vsmartengine.invoicebill.Payments.Paypalsettings;
import com.vsmartengine.invoicebill.Payments.Stripesettings;
import com.vsmartengine.invoicebill.Payments.repos.PaymentsettingRepository;
import com.vsmartengine.invoicebill.Payments.repos.Striperepo;
import com.vsmartengine.invoicebill.Payments.repos.paypalrepo;
import com.vsmartengine.invoicebill.Settings.Feedback;
import com.vsmartengine.invoicebill.Settings.FeedbackRepository;
import com.vsmartengine.invoicebill.User.Muser;
import com.vsmartengine.invoicebill.User.Repository.MuserRepositories;
import com.vsmartengine.invoicebill.User.SecurityConfiguration.JwtUtil;


@RestController
@CrossOrigin
public class PaymentSettingsController {
	
	 @Autowired
	 private JwtUtil jwtUtil;
	@Autowired
	private PaymentsettingRepository paymentsetting;
	
	@Autowired
	private FeedbackRepository feedback;
	
	@Autowired
	private MuserRepositories muserRepository;
	@Autowired
	private Striperepo striperepo;
	
	@Autowired
	private  paypalrepo paypalrepo;
	
	 private static final Logger logger = LoggerFactory.getLogger(PaymentSettingsController.class);

	public ResponseEntity<?> SavePaymentDetails( Paymentsettings data, String token) {
		
		String role = jwtUtil.getRoleFromToken(token);
		String email=jwtUtil.getEmailFromToken(token);
  	     Optional<Muser>opreq=muserRepository.findByEmail(email);
  	     String company="";
  	     if(opreq.isPresent()) {
  	    	 Muser requser=opreq.get();
  	    	company=requser.getCompanyName();
  	    	 boolean adminIsactive=muserRepository.getactiveResultByCompanyName("ADMIN", company);
	   	    	if(!adminIsactive) {
	   	    	 return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
	   	    	}
  	     }else {
  	    	 return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build(); 
  	     }
        if ("ADMIN".equals(role)) {
        	Optional<Paymentsettings> oppaysetting=paymentsetting.findBycompanyName(company);
        if(oppaysetting.isPresent()) {

         	 return new ResponseEntity<>("payment Data already exists", HttpStatus.BAD_REQUEST);
        }else {
        	data.setcompanyName(company);
        	paymentsetting.save(data);
        	return ResponseEntity.ok("saved sucessfully");
        	
        }
        }else {

            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }
	}
	

	public ResponseEntity<?> GetPaymentDetails ( String token){
		try { String role = jwtUtil.getRoleFromToken(token);
	          String email=jwtUtil.getEmailFromToken(token);
	   	     Optional<Muser>opreq=muserRepository.findByEmail(email);
	   	     String company="";
	   	     if(opreq.isPresent()) {
	   	    	 Muser requser=opreq.get();
	   	    	company=requser.getCompanyName();
	   	     boolean adminIsactive=muserRepository.getactiveResultByCompanyName("ADMIN", company);
	   	    	if(!adminIsactive) {
	   	    	 return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
	   	    	}
	   	     }else {
	   	    	 return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build(); 
	   	     }
	          // Perform authentication based on role
	          if ("ADMIN".equals(role)) {
			Optional<Paymentsettings> opdatalist=paymentsetting.findBycompanyName(company);
			
		        // If there's only one certificate, return it directly
		        if (opdatalist.isPresent()) {
		            Paymentsettings pay = opdatalist.get();
		            return ResponseEntity.ok()
		                .body(pay);  
		        }else {
		        	return ResponseEntity.status(HttpStatus.NO_CONTENT)
				            .body("No payment data found");
		        }
		        
		        
			}else {
		              return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
		        }
		    } catch (Exception e) {
		    	e.printStackTrace();    logger.error("", e);;
		        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
		            .body("An error occurred while retrieving payment data");
		    }
	}
	
	public ResponseEntity<?> editpayment( Long payid, String razorpay_key, String razorpay_secret_key, String token){
	try{
		 String role = jwtUtil.getRoleFromToken(token);
		 String email=jwtUtil.getEmailFromToken(token);
   	     Optional<Muser>opreq=muserRepository.findByEmail(email);
   	     String company="";
   	     if(opreq.isPresent()) {
   	    	 Muser requser=opreq.get();
   	    	company=requser.getCompanyName();
   	     boolean adminIsactive=muserRepository.getactiveResultByCompanyName("ADMIN", company);
	    	if(!adminIsactive) {
	    	 return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
	    	}
   	     }else {
   	    	 return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build(); 
   	     }
         // Perform authentication based on role
         if ("ADMIN".equals(role)) {
		 Optional<Paymentsettings> oldsettings=paymentsetting.findBycompanyName(company);
		 if (oldsettings.isPresent()) {
			 Paymentsettings  updatedsettings =oldsettings.get();
			 if(razorpay_key!=null) {
				 updatedsettings.setRazorpay_key(razorpay_key);
			 }
			 if(razorpay_secret_key!= null) {
				 updatedsettings.setRazorpay_secret_key(razorpay_secret_key);
			 }
			 paymentsetting.saveAndFlush(updatedsettings);
	            return ResponseEntity.ok("settings updated successfully");
		 }else {
	            return ResponseEntity.notFound().build();
	        }
         }else {
	             return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
	        } 
	}catch(Exception e){
		return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
	} 
		 
	 }
	//=====================Stripe Keys================================
	 public ResponseEntity<?>SaveStripedetails(String token, Stripesettings stripedetails){
		  try {
	   	     String role = jwtUtil.getRoleFromToken(token);
	   	     if(!"ADMIN".equals(role)) {
	   	    	 return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
	   	     }
	   	     String email=jwtUtil.getEmailFromToken(token);
	   	     Optional<Muser>opreq=muserRepository.findByEmail(email);
	   	     String company="";
	   	     if(opreq.isPresent()) {
	   	    	 Muser requser=opreq.get();
	   	    	company=requser.getCompanyName();
	   	    	Optional<Stripesettings> stripe = striperepo.findBycompanyName(company);
	   	    	if(stripe.isPresent()) {
	   	    		Stripesettings existingstripe=stripe.get();
	   	    		existingstripe.setStripe_publish_key(stripedetails.getStripe_publish_key());
	   	    		existingstripe.setStripe_secret_key(stripedetails.getStripe_secret_key());
	   	    		striperepo.save(existingstripe);
	   	    	   return ResponseEntity.ok("Updated");
	   	  } else {
	   	      Stripesettings stripenew = new Stripesettings();
	   	     stripenew.setCompany_name(company);
	   	     stripenew.setStripe_publish_key(stripedetails.getStripe_publish_key());
	   	     stripenew.setStripe_secret_key(stripedetails.getStripe_secret_key());
	   	     striperepo.save(stripenew);
	   	    	return ResponseEntity.ok("saved");
	   	    	}
	 }else {
		 return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
	 }
		  }catch (Exception e) {
		    e.printStackTrace();
		    return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
		}
}
	 
	 public ResponseEntity<?> GetstripeKeys ( String token){
			try {  String role = jwtUtil.getRoleFromToken(token);
		          String email=jwtUtil.getEmailFromToken(token);
		   	     Optional<Muser>opreq=muserRepository.findByEmail(email);
		   	     String company="";
		   	     if(opreq.isPresent()) {
		   	    	 Muser requser=opreq.get();
		   	    	company=requser.getCompanyName();
		   	     boolean adminIsactive=muserRepository.getactiveResultByCompanyName("ADMIN", company);
		   	    	if(!adminIsactive) {
		   	    	 return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
		   	    	}
		   	     }else {
		   	    	 return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build(); 
		   	     }
		          // Perform authentication based on role
		          if ("ADMIN".equals(role)) {
				Optional<Stripesettings> stripedata=striperepo.findBycompanyName(company);
				
			        // If there's only one certificate, return it directly
			        if (stripedata.isPresent()) {
			            Stripesettings stripe = stripedata.get();
			            return ResponseEntity.ok()
			                .body(stripe);  
			        }else {
			        	return ResponseEntity.status(HttpStatus.NO_CONTENT)
					            .body("No payment data found");
			        }
			        
			        
				}else {
			              return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
			        }
			    } catch (Exception e) {
			    	e.printStackTrace();    logger.error("", e);;
			        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
			            .body("An error occurred while retrieving payment data");
			    }
		}
		
	
     public ResponseEntity<?>getpublishkey(String token){
    	 try {  String role = jwtUtil.getRoleFromToken(token);
	          if("ADMIN".equals(role)||"TRAINER".equals(role)) {
	        	  return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Student only enrole in course");
	          }
	          String email=jwtUtil.getEmailFromToken(token);
	   	     Optional<Muser>opreq=muserRepository.findByEmail(email);
	   	     String company="";
	   	     if(opreq.isPresent()) {
	   	    	 Muser requser=opreq.get();
	   	    	company=requser.getCompanyName();
	   	    	String publishkey=striperepo.findpublishkeybycompany(company);
	   	    	if(publishkey==null) {
	   	    		return ResponseEntity.status(HttpStatus.NO_CONTENT).build();
	   	    	}else {
	   	    		return ResponseEntity.ok(publishkey);
	   	    	}
	   	     }else {
	   	      return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("usernot found");
	   	     }
	   	  } catch (Exception e) {
		    	e.printStackTrace();    logger.error("", e);;
		        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
		            .body("An error occurred while retrieving payment data");
		    }
    	 
     }
   //=====================Stripe Keys================================
     //=======================PayPal=======================
     public ResponseEntity<?>SavePaypaldetails(String token, Paypalsettings paypalsettings){
		  try {
	   	     String role = jwtUtil.getRoleFromToken(token);
	   	     if(!"ADMIN".equals(role)) {
	   	    	 return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("Trainer or Stdent cannot access this page");
	   	     }
	   	     String email=jwtUtil.getEmailFromToken(token);
	   	    String company=muserRepository.findcompanyByEmail(email);
	   	    if(company==null) {
	   	    	return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("User Not found");
	   	    }
	   	    	Optional<Paypalsettings> paypal = paypalrepo.FindByCompanyName(company);
	   	    	if(paypal.isPresent()) {
	   	    		Paypalsettings existingpaypal=paypal.get();
	   	    		existingpaypal.setPaypal_client_id(paypalsettings.getPaypal_client_id());
	   	    		existingpaypal.setPaypal_secret_key(paypalsettings.getPaypal_secret_key());
	   	    		paypalrepo.save(existingpaypal);
	   	    	   return ResponseEntity.ok("Updated");
	   	  } else {
	   	      Paypalsettings paypalnew = new Paypalsettings();
	   	    paypalnew.setCompanyName(company);
	   	    paypalnew.setPaypal_client_id(paypalsettings.getPaypal_client_id());
	   	    paypalnew.setPaypal_secret_key(paypalsettings.getPaypal_secret_key());
	   	     paypalrepo.save(paypalnew);
	   	    	return ResponseEntity.ok("saved");
	   	    	}
	 
		  }catch (Exception e) {
		    e.printStackTrace();
		    return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
		}
}
     
     public ResponseEntity<?> GetpaypalKeys ( String token){
			try {
				  String role = jwtUtil.getRoleFromToken(token);
		          String email=jwtUtil.getEmailFromToken(token);
		          String company=muserRepository.findcompanyByEmail(email);
		          if(company==null) {
		              return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("User Not Found");
		          }
		   	     boolean adminIsactive=muserRepository.getactiveResultByCompanyName("ADMIN", company);
		   	    	if(!adminIsactive) {
		   	    	 return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("Company is  not active");
		   	    	}
		   	     
		          if ("ADMIN".equals(role)) {
				Optional<Paypalsettings> oppaypal=paypalrepo.FindByCompanyName(company);
				
			        // If there's only one certificate, return it directly
			        if (oppaypal.isPresent()) {
			            Paypalsettings  paypal = oppaypal.get();
			            return ResponseEntity.ok()
			                .body(paypal);  
			        }else {
			        	return ResponseEntity.status(HttpStatus.NO_CONTENT)
					            .body("No payment data found");
			        }
		          }else {
		        	  return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("Admin is only allowed to access this page");
		          }
			        
			
			    } catch (Exception e) {
			    	e.printStackTrace();    logger.error("", e);;
			        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
			            .body("An error occurred while retrieving payment data");
			    }
		}
     
     
     
     //==================paypal=======================
	 public Feedback feedback( Feedback data) {
		System.out.println(data);
		return feedback.save(data);
	}

}
