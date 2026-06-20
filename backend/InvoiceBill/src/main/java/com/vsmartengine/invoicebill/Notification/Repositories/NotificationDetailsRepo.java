package com.vsmartengine.invoicebill.Notification.Repositories;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import com.vsmartengine.invoicebill.Notification.NotificationDetails;
import com.vsmartengine.invoicebill.Notification.dtos.NotificationDetailsDTO;

import jakarta.transaction.Transactional;

@Repository
public interface NotificationDetailsRepo extends JpaRepository<NotificationDetails, Long> {

	@Modifying
	 @Transactional
    @Query("DELETE FROM NotificationDetails nu WHERE nu.notifyId = :notificationId")
    void deleteByNotifyId(@Param("notificationId") Long notificationId);
	
	 @Query("SELECT new com.vsmartengine.invoicebill.Notification.dtos.NotificationDetailsDTO(n.notifyId, n.notifyTypeId, n.heading, n.Description, n.CreatedDate, n.CreatedBy, n.username, n.link) " +
	           "FROM NotificationDetails n WHERE n.notifyId = :id")
	    Optional<NotificationDetailsDTO> findCustomNotificationById(@Param("id") Long id);
	    
	    @Query("SELECT new NotificationDetails(n.notifyId, n.notimage) FROM NotificationDetails n WHERE n.notifyId IN :notifyIds")
	    List<NotificationDetails> findNotificationsWithImagesByNotifyIdIn(@Param("notifyIds") List<Long> notifyIds);
        
	 // Check if low stock notification already exists for today for this item
	    @Query("SELECT CASE WHEN COUNT(n) > 0 THEN true ELSE false END FROM NotificationDetails n WHERE n.Description LIKE %:description% AND n.CreatedDate = :createdDate")
	    boolean existsByDescriptionContainingAndCreatedDate(
	        @Param("description") String description, 
	        @Param("createdDate") LocalDate createdDate);
}
