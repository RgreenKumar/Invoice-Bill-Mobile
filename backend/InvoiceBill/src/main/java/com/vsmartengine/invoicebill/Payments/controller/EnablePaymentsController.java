package com.vsmartengine.invoicebill.Payments.controller;

import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.stream.Collectors;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.RestController;

import com.vsmartengine.invoicebill.Payments.Payment_Type;
import com.vsmartengine.invoicebill.Payments.Paymentsettings;
import com.vsmartengine.invoicebill.Payments.Paypalsettings;
import com.vsmartengine.invoicebill.Payments.Stripesettings;
import com.vsmartengine.invoicebill.Payments.repos.PaymentTypeRepo;
import com.vsmartengine.invoicebill.Payments.repos.PaymentsettingRepository;
import com.vsmartengine.invoicebill.Payments.repos.Striperepo;
import com.vsmartengine.invoicebill.Payments.repos.paypalrepo;
//import com.vsmartengine.invoicebill.Settings.Controller.SettingsController;
import com.vsmartengine.invoicebill.User.Repository.MuserRepositories;
import com.vsmartengine.invoicebill.User.SecurityConfiguration.JwtUtil;

@RestController
public class EnablePaymentsController {
	 private static final Logger logger = LoggerFactory.getLogger(EnablePaymentsController.class);
	 @Autowired
	 private JwtUtil jwtUtil;
	 @Autowired
	 private PaymentTypeRepo paytyperepo;
	 @Autowired
	 private PaymentsettingRepository razorPayRepo;
	 @Autowired
	 private Striperepo striperepo;
	 @Autowired
	 private paypalrepo paypalrepo;
	 
	 @Autowired
	 private MuserRepositories muserrepo;
	 public Boolean updatePaymenttypes(Boolean isEnabled,String paymentTypeName,String token) {
		 try {
	         String role = jwtUtil.getRoleFromToken(token);
	         String email=jwtUtil.getEmailFromToken(token);
	         if("ADMIN".equals(role)) {
	        	 String companyName=muserrepo.findcompanyByEmail(email);
	        	
	        	
	        Optional<Payment_Type> oppaytype = paytyperepo.findPaymentTypecompanyNameAndTypeName(companyName,paymentTypeName);
             
	        Payment_Type paytype;
	        if (oppaytype.isPresent()) {
	            // Update existing setting
	        	paytype = oppaytype.get();
	           
		      
	        } else {
	            // Create new setting
	        	paytype = new Payment_Type();
	        	paytype.setPaymentTypeName(paymentTypeName);
	        	paytype.setCompanyName(companyName);  
	        }
	        // Set the new value
	        paytype.setIsActive(isEnabled);
	      paytyperepo.save(paytype);
	     
	        return true;
	         }else {
	        	 return false;
	         }
		 }catch(Exception e) {
			 e.printStackTrace();    logger.error("", e);;
			 return false;
		 }
	    }
	 
	 public ResponseEntity<?> getpaytypedetails(String token) {
		    try {
		        String email = jwtUtil.getEmailFromToken(token);
		        String role=jwtUtil.getRoleFromToken(token);
		        String companyName = muserrepo.findcompanyByEmail(email);
                 if(!"ADMIN".equals(role)) {
                	 return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("Users or Trainers are tnot allowed to access this");
                 }
		        // Fetch and transform the data
		        List<Map<String, Object>> paytypes = paytyperepo.findByCompanyNameAsMap(companyName);
		        Map<String, Boolean> responseMap = paytypes.stream()
		            .collect(Collectors.toMap(
		                entry -> (String) entry.get("name"),
		                entry -> (Boolean) entry.get("active")
		            ));

		        return ResponseEntity.ok(responseMap);

		    } catch (Exception e) {
		        logger.error("Exception at getpaydetails", e);
		        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
		    }
		}

	 public ResponseEntity<?> getpaytypedetailsforuser(String token) {
		    try {
		        String email = jwtUtil.getEmailFromToken(token);
		        String companyName = muserrepo.findcompanyByEmail(email);
		        String role=jwtUtil.getRoleFromToken(token);
		        if(!"USER".equals(role)) {
               	 return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("Users or Trainers are tnot allowed to access this");
                }
		        // Fetch and transform the data
		        List<Map<String, Object>> paytypes = paytyperepo.findByCompanyNameAsMap(companyName);

		        Map<String, Boolean> responseMap = paytypes.stream()
		            .collect(Collectors.toMap(
		                entry -> (String) entry.get("name"),
		                entry -> (Boolean) entry.get("active")
		            ));

		        responseMap.forEach((key, value) -> {
		            boolean isActive = false; // Default to false if keys are not found or if isActive was not true

		            if ("RAZORPAY".equalsIgnoreCase(key)) {
		                // Check if Razorpay record exists by unwrapping the Optional
		                Paymentsettings payset = razorPayRepo.findBycompanyName(companyName).orElse(null);
		                boolean hasKeys = (payset != null);
		                // Set isActive only if both conditions are true
		                isActive = value && hasKeys;
		            } else if ("STRIPE".equalsIgnoreCase(key)) {
		                // Check if Stripe record exists by unwrapping the Optional
		                Stripesettings payset = striperepo.findBycompanyName(companyName).orElse(null);
		                boolean hasKeys = (payset != null);
		                // Set isActive only if both conditions are true
		                isActive = value && hasKeys;
		            } else if ("PAYPAL".equalsIgnoreCase(key)) {
		                // Check if PayPal record exists by unwrapping the Optional
		                Paypalsettings payset = paypalrepo.FindByCompanyName(companyName).orElse(null);
		                boolean hasKeys = (payset != null);
		                // Set isActive only if both conditions are true
		                System.out.println("hasKeys: " + hasKeys);
		                isActive = value && hasKeys;
		            }

		            // Update the value in the map
		            responseMap.put(key, isActive);
		        });

		         

		        // Print the updated responseMap
		        responseMap.forEach((key, value) -> 
		            System.out.println("Payment Type: " + key + ", Active: " + value)
		        );



		        return ResponseEntity.ok(responseMap);

		    } catch (Exception e) {
		        logger.error("Exception at getpaydetails", e);
		        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
		    }
		}

	 

}
