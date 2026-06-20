package com.vsmartengine.invoicebill.Notification.Service;

import java.io.IOException;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import com.vsmartengine.invoicebill.ImageCompressing.ImageResizer;
import com.vsmartengine.invoicebill.Notification.NotificationDetails;
import com.vsmartengine.invoicebill.Notification.NotificationType;
import com.vsmartengine.invoicebill.Notification.NotificationUser;
import com.vsmartengine.invoicebill.Notification.Repositories.NotificationDetailsRepo;
import com.vsmartengine.invoicebill.Notification.Repositories.NotificationTypeRepo;
import com.vsmartengine.invoicebill.Notification.Repositories.NotificationUserRepo;
import com.vsmartengine.invoicebill.User.Muser;
import com.vsmartengine.invoicebill.User.Repository.MuserRepositories;

@Service
public class NotificationService {

	@Autowired
	private NotificationDetailsRepo notidetailRepo;
	@Autowired
	private NotificationUserRepo notiuserRepo;
	@Autowired
	private MuserRepositories muserrepositories;
	@Autowired
	private NotificationTypeRepo notitypeRepo;
	
	 private static final Logger logger = LoggerFactory.getLogger(NotificationService.class);

  //Create Notification with Multipart
	
    public Long  createNotification(String type,String username, String description, String createdBy,String heading,String link ,Optional<MultipartFile> file) {
    	NotificationType notificationType = notitypeRepo.findByType(type)
                .orElseGet(() -> {
                    NotificationType newType = new NotificationType(type);
                    return notitypeRepo.save(newType); // Save and return the new type
                });
        
        NotificationDetails notiDetails= new NotificationDetails();
        notiDetails.setHeading(heading);
        notiDetails.setLink(link);
        if (file.isPresent()) { // Check if file is present (for approach 2)
            try {
               // notiDetails.setNotimage(ImageUtils.compressImage(file.get().getBytes()));
            	
                byte[] img= file.get().getBytes();
                if(img!=null) {
                notiDetails.setNotimage(ImageResizer.resizeImage(img, 100, 100));
                }
            } catch (IOException e) {
            	System.out.println("null image first");
            	notiDetails.setNotimage(null);
                e.printStackTrace();    logger.error("", e);;
            }
        }
        
        notiDetails.setNotifyTypeId(notificationType.getNotifyTypeId());
        notiDetails.setUsername(username);
        notiDetails.setCreatedBy(createdBy);
        notiDetails.setCreatedDate(LocalDate.now());
        notiDetails.setIsActive(true);
        notiDetails.setDescription(description);
        NotificationDetails savedNotiDetails= notidetailRepo.save(notiDetails);
        return (savedNotiDetails.getNotifyId());
    }
    
    //Create Notification with byte image
    public Long  createNotification(String type,String username, String description, String createdBy,String heading,String link ,byte[] file) {
    	NotificationType notificationType = notitypeRepo.findByType(type)
                .orElseGet(() -> {
                    NotificationType newType = new NotificationType(type);
                    return notitypeRepo.save(newType); // Save and return the new type
                });
        
        NotificationDetails notiDetails= new NotificationDetails();
        notiDetails.setHeading(heading);
        notiDetails.setLink(link);
        if(file!=null) {
        try {
			notiDetails.setNotimage(ImageResizer.resizeImage(file, 100, 100));
		} catch (Exception e) {
			e.printStackTrace();    logger.error("", e);;
			notiDetails.setNotimage(null);

		}
        }
        
        notiDetails.setNotifyTypeId(notificationType.getNotifyTypeId());
        notiDetails.setUsername(username);
        notiDetails.setCreatedBy(createdBy);
        notiDetails.setCreatedDate(LocalDate.now());
        notiDetails.setIsActive(true);
        notiDetails.setDescription(description);
        NotificationDetails savedNotiDetails= notidetailRepo.save(notiDetails);
        return (savedNotiDetails.getNotifyId());
    }
 //create notification without pic   
    public Long  createNotification(String type,String username, String description, String createdBy,String heading,String link ) {
    	NotificationType notificationType = notitypeRepo.findByType(type)
                .orElseGet(() -> {
                    NotificationType newType = new NotificationType(type);
                    return notitypeRepo.save(newType); // Save and return the new type
                });
        
        NotificationDetails notiDetails= new NotificationDetails();
        notiDetails.setHeading(heading);
        notiDetails.setLink(link); 
        notiDetails.setNotifyTypeId(notificationType.getNotifyTypeId());
        notiDetails.setUsername(username);
        notiDetails.setCreatedBy(createdBy);
        notiDetails.setCreatedDate(LocalDate.now());
        notiDetails.setIsActive(true);
        notiDetails.setDescription(description);
        NotificationDetails savedNotiDetails= notidetailRepo.save(notiDetails);
        return (savedNotiDetails.getNotifyId());
    }
    
    
    public Boolean SpecificCreateNotification(Long notificationId, List<Long> userlist) {
    	for(Long singleuser :userlist) {
    		 NotificationUser notificationUser = new NotificationUser();
			 notificationUser.setUserid(singleuser);
			 notificationUser.setNotificationId(notificationId);
			 notificationUser.setIs_read(false);
			 notificationUser.setIs_Active(true);
			 notiuserRepo.save(notificationUser);
    	}
    	return(true);
    }
    
    public Boolean SpecificCreateNotificationusingEmail(Long notificationId, List<String> userlist) {
    	for(String singleuser :userlist) {
    		 Optional<Muser> opuser =muserrepositories.findByEmail(singleuser);
    		 if(opuser.isPresent()) {
    			 Muser user=opuser.get();
    		 NotificationUser notificationUser = new NotificationUser();
			 notificationUser.setUserid(user.getUserId());
			 notificationUser.setNotificationId(notificationId);
			 notificationUser.setIs_read(false);
			 notificationUser.setIs_Active(true);
			 notiuserRepo.save(notificationUser);
    		 }else {
    			 System.out.println("usernot found");
    		 }
    	}
    	return(true);
    }
    
    public Boolean SpecificCreateNotification(Long notificationId, List<Long> userlist,LocalDate datetonotify) {
    	for(Long singleuser :userlist) {
    		 NotificationUser notificationUser = new NotificationUser();
			 notificationUser.setUserid(singleuser);
			 notificationUser.setNotificationId(notificationId);
			 notificationUser.setIs_read(false);
			 notificationUser.setIs_Active(true);
			 notificationUser.setDatetonotify(datetonotify);
			 notiuserRepo.save(notificationUser);
    	}
    	return(true);
    }
    public Boolean LicenceExpitedNotification(Long notificationId ,LocalDate datetonotify,String institution) {
    	List<Muser> listofadmins =muserrepositories.findByRoleNameAndCompanyName("ADMIN", institution);
		for(Muser admin :listofadmins) {
			 NotificationUser notificationUser = new NotificationUser();
			 notificationUser.setUserid(admin.getUserId());
			 notificationUser.setNotificationId(notificationId);
			 notificationUser.setIs_read(false);
			 notificationUser.setIs_Active(true);
			 notificationUser.setDatetonotify(datetonotify);
			 notiuserRepo.save(notificationUser);
		}
    	return(true);
    }
    
    public Boolean CommoncreateNotificationUser(Long notificationId , List<String> userlist,String institution) {
    	for(String singleuser :userlist) {
    		if("ADMIN".equals(singleuser)) {
    			List<Muser> listofadmins =muserrepositories.findByRoleNameAndCompanyName(singleuser, institution);
    			for(Muser admin :listofadmins) {
    				 NotificationUser notificationUser = new NotificationUser();
    				 notificationUser.setUserid(admin.getUserId());
    				 notificationUser.setNotificationId(notificationId);
    				 notificationUser.setIs_read(false);
    				 notificationUser.setIs_Active(true);
    				 notiuserRepo.save(notificationUser);
    			}
    		}
//    		if("TRAINER".equals(singleuser)) {
//    			List<Muser> listofTrainer =muserrepositories.findByRoleNameAndCompanyName(singleuser, institution);
//    			for(Muser user :listofTrainer) {
//    				 NotificationUser notificationTrainer = new NotificationUser();
//    				 notificationTrainer.setUserid(user.getUserId());
//    				 notificationTrainer.setNotificationId(notificationId);
//    				 notificationTrainer.setIs_read(false);
//    				 notificationTrainer.setIs_Active(true);
//    				 notiuserRepo.save(notificationTrainer);
//    		}
//    		}
//    		if("USER".equals(singleuser)) {
//    			List<Muser> listofuser =muserrepositories.findByRoleNameAndCompanyName(singleuser, institution);
//    			for(Muser user :listofuser) {
//    				 NotificationUser notificationUser = new NotificationUser();
//    				 notificationUser.setUserid(user.getUserId());
//    				 notificationUser.setNotificationId(notificationId);
//    				 notificationUser.setIs_read(false);
//    				 notificationUser.setIs_Active(true);
//    				 notiuserRepo.save(notificationUser);
//    		}
//    	}
    		if("CASHIER".equals(singleuser)) {
    		    List<Muser> listofCashier = muserrepositories.findByRoleNameAndCompanyName(singleuser, institution);
    		    for(Muser user : listofCashier) {
    		        NotificationUser notificationCashier = new NotificationUser();
    		        notificationCashier.setUserid(user.getUserId());
    		        notificationCashier.setNotificationId(notificationId);
    		        notificationCashier.setIs_read(false);
    		        notificationCashier.setIs_Active(true);
    		        notiuserRepo.save(notificationCashier);
    		    }
    		}
    	}
    	return(true);
    }
    
    
    
    
}
