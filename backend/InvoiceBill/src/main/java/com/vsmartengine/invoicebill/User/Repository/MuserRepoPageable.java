package com.vsmartengine.invoicebill.User.Repository;

import java.time.LocalDate;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.PagingAndSortingRepository;
import org.springframework.data.repository.query.Param;

import com.vsmartengine.invoicebill.User.Muser;
import com.vsmartengine.invoicebill.User.MuserDto;

public interface MuserRepoPageable extends PagingAndSortingRepository<Muser, Long> {

    @Query("SELECT new com.vsmartengine.invoicebill.User.MuserDto(u.userId, u.username, u.email, u.phone, u.isActive, u.dob, u.skills, u.companyName) "
            + "FROM Muser u WHERE u.role.roleName = :rolename")
    Page<MuserDto> findByRoleName(@Param("rolename") String roleName, Pageable pageable);

    @Query("SELECT new com.vsmartengine.invoicebill.User.MuserDto(u.userId, u.username, u.email, u.phone, u.isActive, u.dob, u.skills, u.companyName) "
            + "FROM Muser u WHERE u.role.roleName = :rolename AND u.companyName = :companyname")
    Page<MuserDto> findByRoleNameAndCompanyName(@Param("rolename") String roleName,
            @Param("companyname") String companyName, Pageable pageable);

    // ================SYSADMIN===================
    @Query("SELECT new com.vsmartengine.invoicebill.User.MuserDto("
            + "m.userId, m.username, m.email, m.phone, m.isActive, m.dob, m.skills, m.companyName) "
            + "FROM Muser m WHERE "
            + "(:username IS NULL OR LOWER(m.username) LIKE LOWER(CONCAT(:username, '%'))) AND "
            + "(:email IS NULL OR LOWER(m.email) LIKE LOWER(CONCAT(:email, '%'))) AND "
            + "(:phone IS NULL OR LOWER(m.phone) LIKE LOWER(CONCAT(:phone, '%'))) AND "
            + "(:dob IS NULL OR m.dob = :dob) AND "
            + "(:companyName IS NULL OR LOWER(m.companyName) LIKE LOWER(CONCAT(:companyName, '%'))) AND "
            + "(m.role.roleName = :roleName) AND "
            + "(:skills IS NULL OR LOWER(m.skills) LIKE LOWER(CONCAT(:skills, '%')))")
    Page<MuserDto> CustomesearchUsers(@Param("username") String username,
            @Param("email") String email,
            @Param("phone") String phone,
            @Param("dob") LocalDate dob,
            @Param("companyName") String companyName,
            @Param("roleName") String roleName,
            @Param("skills") String skills,
            Pageable pageable);

    // ================ADMIN===================
    @Query("SELECT new com.vsmartengine.invoicebill.User.MuserDto("
            + "m.userId, m.username, m.email, m.phone, m.isActive, m.dob, m.skills, m.companyName) "
            + "FROM Muser m WHERE "
            + "(:username IS NULL OR LOWER(m.username) LIKE LOWER(CONCAT(:username, '%'))) AND "
            + "(:email IS NULL OR LOWER(m.email) LIKE LOWER(CONCAT(:email, '%'))) AND "
            + "(:phone IS NULL OR LOWER(m.phone) LIKE LOWER(CONCAT(:phone, '%'))) AND "
            + "(:dob IS NULL OR m.dob = :dob) AND "
            + "(m.companyName = :companyName) AND "
            + "(m.role.roleName = :roleName) AND "
            + "(:skills IS NULL OR LOWER(m.skills) LIKE LOWER(CONCAT(:skills, '%')))")
    Page<MuserDto> CustomesearchForAdmin(@Param("username") String username,
            @Param("email") String email,
            @Param("phone") String phone,
            @Param("dob") LocalDate dob,
            @Param("companyName") String companyName,
            @Param("roleName") String roleName,
            @Param("skills") String skills,
            Pageable pageable);
}