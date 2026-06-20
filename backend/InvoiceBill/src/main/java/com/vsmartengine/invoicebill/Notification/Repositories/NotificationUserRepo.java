package com.vsmartengine.invoicebill.Notification.Repositories;

import java.time.LocalDate;
import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import com.vsmartengine.invoicebill.Notification.NotificationUser;

import jakarta.transaction.Transactional;

@Repository
public interface NotificationUserRepo extends JpaRepository<NotificationUser, Long> {
	 @Query("SELECT nu.notificationId FROM NotificationUser nu WHERE nu.userid = :userId AND nu.is_read = :isRead")
	  List<Long> findUnreadNotificationIdsByUserId(Long userId, Boolean isRead);
	 
	 @Query("SELECT nu.notificationId FROM NotificationUser nu WHERE nu.userid = :userId AND (nu.datetonotify = :today OR nu.datetonotify IS NULL)")
	 List<Long> findNotificationIdsByUserId(Long userId, LocalDate today);
	 
	 @Query("SELECT nu FROM NotificationUser nu WHERE nu.userid = :userId AND nu.notificationId = :notificationId")
	  NotificationUser findbyuserIdNotificationId(Long userId, Long notificationId);
	 
	
	 @Query("SELECT COUNT(nu) FROM NotificationUser nu  WHERE( nu.userid = :userId AND nu.is_read = :isRead) AND (nu.datetonotify = :today OR nu.datetonotify IS NULL)")
	 Long CountUnreadNotificationOftheUser(Long userId, Boolean isRead ,LocalDate today);

	 @Query("SELECT nu.id FROM NotificationUser nu WHERE nu.userid = :userId ")
	  List<Long> findprimaryIdsByUserId(Long userId);
	 
	  @Modifying
	  @Transactional
	    @Query("DELETE FROM NotificationUser nu WHERE nu.notificationId = :notificationId")
	    void deleteByNotificationId(@Param("notificationId") Long notificationId);
	 
}
