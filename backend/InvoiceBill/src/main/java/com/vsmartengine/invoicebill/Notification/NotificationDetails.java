package com.vsmartengine.invoicebill.Notification;

import java.time.LocalDate;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Lob;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table
@Getter @Setter @NoArgsConstructor
public class NotificationDetails {
	@Id
	@GeneratedValue(strategy  = GenerationType.IDENTITY)
	private Long notifyId;
	private Long notifyTypeId;
	private String heading;
	@Column(columnDefinition = "Varchar(10000)")
	private String Description;
	private LocalDate CreatedDate;
	@Column(columnDefinition = "Varchar(100)")
	private String CreatedBy; //email
	private String username;
	private String link;
    @Lob
    @Column(length=1000000)
    private byte[] notimage;
	private Boolean isActive;
	private Boolean for_student;
    private Boolean for_trainer;
    private Boolean for_Admin;
    private Boolean for_All;
    
	public NotificationDetails(Long notifyId, byte[] notimage) {
		super();
		this.notifyId = notifyId;
		this.notimage = notimage;
	}

	@Override
	public String toString() {
		return "NotificationDetails [notifyId=" + notifyId+"]";
	}
    
	

}
