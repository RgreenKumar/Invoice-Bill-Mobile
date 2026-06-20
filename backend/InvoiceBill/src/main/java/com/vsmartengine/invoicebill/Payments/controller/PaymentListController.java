package com.vsmartengine.invoicebill.Payments.controller;

import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.RestController;

//import com.vsmartengine.invoicebill.Course.CourseDetail;
import com.vsmartengine.invoicebill.Payments.Orderuser;
import com.vsmartengine.invoicebill.Payments.repos.OrderuserRepo;
import com.vsmartengine.invoicebill.User.Muser;
import com.vsmartengine.invoicebill.User.Repository.MuserRepositories;
import com.vsmartengine.invoicebill.User.SecurityConfiguration.JwtUtil;
@RestController
public class PaymentListController {
	
	    @Autowired
	    private JwtUtil jwtUtil;
		@Autowired
		private MuserRepositories muserRepository;
		@Autowired
		private OrderuserRepo ordertablerepo;
		 
		 private static final Logger logger = LoggerFactory.getLogger(PaymentListController.class);

	
	public ResponseEntity<?>ViewMypaymentHistry(String token){
		  try {
		    	 String email=jwtUtil.getEmailFromToken(token);
		    	Optional< Muser> opuser = muserRepository.findByEmail(email);
		    			if(opuser.isPresent()) {
		    				Muser user=opuser.get();
		    				 boolean adminIsactive=muserRepository.getactiveResultByCompanyName("ADMIN", user.getCompanyName());
		 		   	    	if(!adminIsactive) {
		 		   	    	 return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
		 		   	    	}
		    				Long userId=user.getUserId();
		              	   List<Orderuser>orderuser =ordertablerepo.findAllByUserId(userId);
		              	   if(orderuser.size()>0) {
		              		  
		              		   return ResponseEntity.ok(orderuser);
		              		   
		              	   }else {
		              		   return ResponseEntity.status(HttpStatus.NO_CONTENT).body("Empty");
		              	   }
		    			}else {
		    				 return ResponseEntity.status(HttpStatus.NO_CONTENT)
		 		                    .body("Unauthorized access");
		    			}

		  }catch (Exception e) {
			  e.printStackTrace();    logger.error("", e);
		        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
		                .body("An error occurred : " + e.getMessage() );
		    }
	}

public ResponseEntity<?> viewTransactionHistory(String token) {
    try {
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
  	    	 return ResponseEntity.status(HttpStatus.NO_CONTENT).build(); 
  	     }
        if ("USER".equals(role)) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body("Students cannot access this page");
        }

        if ("ADMIN".equals(role) ) {
                List<Orderuser> orderUsers = ordertablerepo.findAllBycompanyName(company);

                if (!orderUsers.isEmpty()) {
                    return ResponseEntity.ok(orderUsers);
                } else {
                    return ResponseEntity.status(HttpStatus.NO_CONTENT).build(); 
                }
            } else {
                // Handle case where user with email is not found (log, return appropriate message)
                return ResponseEntity.notFound().build();
            }
        
    } catch (Exception e) {
    	e.printStackTrace();    logger.error("", e);;
        // Log the exception and return a more informative error response
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body("An error occurred: " + e.getMessage() );
    }
}

//public ResponseEntity<?>ViewMypaymentHistrytrainer(String token){
//	  try {
//	    	 String email=jwtUtil.getEmailFromToken(token);
//	    	Optional< Muser> opuser = muserRepository.findByEmail(email);
//	    			if(opuser.isPresent()) {
//	    				Muser user=opuser.get();
//	    				String companyName=user.getCompanyName();
//	    				 boolean adminIsactive=muserRepository.getactiveResultByCompanyName("ADMIN", companyName);
//	 		   	    	if(!adminIsactive) {
//	 		   	    	 return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
//	 		   	    	}
////	    				List<CourseDetail> courses =user.getAllotedCourses();
////	    				   
////		              	 List<Object> courseOrderMap = new ArrayList<>();
////	    			        for (CourseDetail course : courses) {
////	    			            Long courseId = course.getCourseId();
////	    			            List<Orderuser> orderUsersForCourse = ordertablerepo.findAllBycourseIdandcompanyName(courseId, companyName);
////
////	    			            if (!orderUsersForCourse.isEmpty()) {
////	    			                courseOrderMap.addAll(orderUsersForCourse);
////	    			            }
////	    			        }
//	              	
//	              	   if(courseOrderMap.size()>0) {
//	              		  
//	              		   return ResponseEntity.ok(courseOrderMap);
//	              	   }else {
//	              		   return ResponseEntity.notFound().build();
//	              	   }
//
//	    			}else {
//	    				 return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
//	 		                    .body("Unauthorized access");
//	    			}
//
//	  }catch (Exception e) {
//		  e.printStackTrace();    logger.error("", e);;
//	        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
//	                .body("An error occurred : " + e.getMessage() );
//	    }
//}



}
