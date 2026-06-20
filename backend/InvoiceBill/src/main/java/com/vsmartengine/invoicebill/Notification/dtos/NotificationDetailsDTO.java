package com.vsmartengine.invoicebill.Notification.dtos;
import java.time.LocalDate;

import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter @Setter @NoArgsConstructor
public class NotificationDetailsDTO {
	  private Long notifyId;
	    private Long notifyTypeId;
	    private String heading;
	    private String description;
	    private LocalDate createdDate;
	    private String createdBy;
	    private String username;
	    private String link;

	    public NotificationDetailsDTO(Long notifyId, Long notifyTypeId, String heading, String description, LocalDate createdDate, String createdBy, String username, String link) {
	        this.notifyId = notifyId;
	        this.notifyTypeId = notifyTypeId;
	        this.heading = heading;
	        this.description = description;
	        this.createdDate = createdDate;
	        this.createdBy = createdBy;
	        this.username = username;
	        this.link = link;
	    }

}
