package com.vsmartengine.invoicebill.Notification;


import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
@Entity
@Getter
@Setter
@NoArgsConstructor // Keep for initialization without arguments
@AllArgsConstructor  // Generate constructor with all fields
@Table
public class NotificationType {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long notifyTypeId;

    @Column(columnDefinition = "Varchar(100)", unique = true, name = "type")
    private String type;
    
    public NotificationType(String type) {
        this.type = type;
    }
   
//CourseAdd-CourseEdit-CourseDelete-


}
