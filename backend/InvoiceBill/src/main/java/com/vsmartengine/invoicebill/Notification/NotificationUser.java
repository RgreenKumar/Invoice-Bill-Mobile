package com.vsmartengine.invoicebill.Notification;

import java.time.LocalDate;

import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Getter @Setter @NoArgsConstructor
@Table
public class NotificationUser {
	@Id
	@GeneratedValue(strategy  = GenerationType.IDENTITY)
    private Long id;
	private Long userid;
	private Long notificationId;
	private Boolean is_read;
	private Boolean Is_Active;
	private LocalDate datetonotify;
}
