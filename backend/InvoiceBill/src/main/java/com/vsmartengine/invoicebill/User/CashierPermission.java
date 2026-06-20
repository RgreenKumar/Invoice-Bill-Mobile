package com.vsmartengine.invoicebill.User;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Getter
@Setter
@NoArgsConstructor
@Table(name = "cashier_permissions")
public class CashierPermission {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne
    @JoinColumn(name = "user_id", nullable = false)
    private Muser user;

    @Column(nullable = false)
    private String moduleName;

    private Boolean canView   = false;
    private Boolean canCreate = false;
    private Boolean canEdit   = false;
    private Boolean canDelete = false;
}