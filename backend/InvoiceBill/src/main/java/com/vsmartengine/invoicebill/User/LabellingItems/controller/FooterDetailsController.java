package com.vsmartengine.invoicebill.User.LabellingItems.controller;

import java.util.Optional;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.RestController;

import com.vsmartengine.invoicebill.User.Muser;
import com.vsmartengine.invoicebill.User.LabellingItems.FooterDetails;
import com.vsmartengine.invoicebill.User.LabellingItems.Repo.FooterdetailsRepo;
import com.vsmartengine.invoicebill.User.Repository.MuserRepositories;
import com.vsmartengine.invoicebill.User.SecurityConfiguration.JwtUtil;

@RestController
@CrossOrigin
public class FooterDetailsController {
	@Autowired
	private FooterdetailsRepo footerrepo;
	@Autowired
	private MuserRepositories muserrepositories;
	 @Autowired
	 private JwtUtil jwtUtil;

	 public ResponseEntity<?>SaveFooterDetails(String token, FooterDetails footerdetails){
		  try {
	   	     String role = jwtUtil.getRoleFromToken(token);
	   	     if(!"ADMIN".equals(role)) {
	   	    	 return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
	   	     }
	   	     String email=jwtUtil.getEmailFromToken(token);
	   	     Optional<Muser>opreq=muserrepositories.findByEmail(email);
	   	     String company="";
	   	     if(opreq.isPresent()) {
	   	    	 Muser requser=opreq.get();
	   	    	company=requser.getCompanyName();
	   	    	Optional<FooterDetails> footer = footerrepo.FindFooterDetailsByCompany(company);
	   	    	if(footer.isPresent()) {
	   	    		FooterDetails existingFooter=footer.get();
	   	    		existingFooter.setContact(footerdetails.getContact());
	   	    		existingFooter.setCopyright(footerdetails.getCopyright());
	   	    		existingFooter.setCompanymail(footerdetails.getCompanymail());
	   	    		existingFooter.setSupportmail(footerdetails.getSupportmail());
	   	    		footerrepo.save(existingFooter);
	   	    	   return ResponseEntity.ok("Updated");
	   	  } else {
	   	      FooterDetails footernew = new FooterDetails();
	   	      footernew.setContact(footerdetails.getContact());
	   	      footernew.setCopyright(footerdetails.getCopyright());
	   	      footernew.setCompanymail(footerdetails.getCompanymail());
	   	      footernew.setSupportmail(footerdetails.getSupportmail());
	   	      footernew.setCompanyName(company);
	   	      footerrepo.save(footernew);
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
	 public ResponseEntity<?>Getfooterdetails(String token){
		  try {
	   	     String role = jwtUtil.getRoleFromToken(token);
	   	     if(!"ADMIN".equals(role)) {
	   	    	 return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
	   	     }
	   	     String email=jwtUtil.getEmailFromToken(token);
	   	     Optional<Muser>opreq=muserrepositories.findByEmail(email);
	   	     String company="";
	   	     if(opreq.isPresent()) {
	   	    	 Muser requser=opreq.get();
	   	    	company=requser.getCompanyName();
	   	    	Optional<FooterDetails>footerdetsils=footerrepo.FindFooterDetailsByCompany(company);
	   	       if(footerdetsils.isPresent()) {
	   	    	   return ResponseEntity.ok(footerdetsils);
	   	       }else {
	   	    	   return ResponseEntity.status(HttpStatus.NO_CONTENT).build();
	   	       }
		            
	  }else {
		 return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
	 }
		  }catch (Exception e) {
		    e.printStackTrace();
		    return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
		}
}
	 public ResponseEntity<?>getFooteritemsForAll(){
		 try {
			 String companyname=muserrepositories.getCompany("ADMIN");
			 if(companyname == null ||companyname.isEmpty()) {
				 return ResponseEntity.status(HttpStatus.NO_CONTENT).build();
			 }else {
				 Optional<FooterDetails>footerdetails= footerrepo.FindFooterDetailsByCompany(companyname);
		   	       if(footerdetails.isPresent()) {
		   	    	   return ResponseEntity.ok(footerdetails);
		   	       }else {
		   	    	   return ResponseEntity.status(HttpStatus.NO_CONTENT).build();
		   	       }
			 }
		 }catch(Exception e) {
			 e.printStackTrace();
			 return ResponseEntity.internalServerError().build();
		 }
	 
	 }

}
