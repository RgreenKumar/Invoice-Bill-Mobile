package com.vsmartengine.invoicebill.User.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import com.vsmartengine.invoicebill.User.Muser;
import com.vsmartengine.invoicebill.User.MuserAddInfoDto;
import com.vsmartengine.invoicebill.User.MuserDto;
import com.vsmartengine.invoicebill.User.MuserProfileDTO;
import com.vsmartengine.invoicebill.User.MuserRequiredDto;

@Repository
public interface MuserRepositories extends JpaRepository<Muser, Long> {

    @Query("SELECT u FROM Muser u WHERE u.email = ?1")
    Optional<Muser> findByEmail(String email);

    @Query("SELECT u.userId FROM Muser u WHERE u.email = ?1")
    Long findidByEmail(String email);

    @Query("SELECT u.companyName FROM Muser u WHERE u.role.roleName = :rolename")
    String getCompany(String rolename);

    @Query("SELECT u.email FROM Muser u WHERE u.role.roleName = :rolename")
    String getAdminEmailByRoleName(String rolename);

    @Query("SELECT u.email FROM Muser u WHERE u.userId = ?1")
    String FindEmailByuserId(Long userId);

    @Query("SELECT u.companyName FROM Muser u WHERE u.email = ?1")
    String findcompanyByEmail(String email);

    @Query("SELECT new com.vsmartengine.invoicebill.User.MuserAddInfoDto("
            + "(SELECT COUNT(u) FROM Muser u WHERE u.role.roleName = 'ADMIN'), "
            + "(SELECT u.companyName FROM Muser u WHERE u.role.roleName = 'ADMIN'), "
            + "(SELECT u.email FROM Muser u WHERE u.role.roleName = 'ADMIN'), "
            + "(CASE WHEN (COUNT(e) > 0) THEN true ELSE false END) "
            + ") FROM Muser u "
            + "LEFT JOIN Muser e ON e.email = :email")
    MuserAddInfoDto getAdminInfo(@Param("email") String email);

    @Query("SELECT new com.vsmartengine.invoicebill.User.MuserDto(u.userId, u.username, u.email, u.phone, u.isActive, u.dob, u.skills, u.companyName) "
            + "FROM Muser u WHERE u.email = :email")
    Optional<MuserDto> findDetailsByEmailforSysadmin(@Param("email") String email);

    @Query("SELECT new com.vsmartengine.invoicebill.User.MuserDto(u.userId, u.username, u.email, u.phone, u.isActive, u.dob, u.skills, u.companyName) "
            + "FROM Muser u WHERE u.email = :email AND u.companyName = :companyName")
    Optional<MuserDto> findDetailsByEmailAndCompany(@Param("email") String email,
            @Param("companyName") String companyName);

    @Query("SELECT new com.vsmartengine.invoicebill.User.MuserRequiredDto(u.userId, u.username, u.email, u.phone, u.isActive, u.dob, u.skills, u.companyName, u.profile, u.countryCode) "
            + "FROM Muser u WHERE u.email = :email AND u.companyName = :companyName")
    Optional<MuserRequiredDto> findDetailandProfileByEmailAndCompany(@Param("email") String email,
            @Param("companyName") String companyName);

    @Query("SELECT new com.vsmartengine.invoicebill.User.MuserProfileDTO(u.profile, u.countryCode, u.role.roleName) "
            + "FROM Muser u JOIN u.role r "
            + "WHERE u.email = :email AND u.companyName = :companyName")
    Optional<MuserProfileDTO> findProfileAndCountryCodeAndRoleByEmailAndCompanyName(@Param("email") String email,
            @Param("companyName") String companyName);

    @Query("SELECT new com.vsmartengine.invoicebill.User.MuserProfileDTO(u.profile, u.countryCode, u.role.roleName, u.lastactive) "
            + "FROM Muser u JOIN u.role r WHERE u.email = :email")
    Optional<MuserProfileDTO> findProfileAndCountryCodeAndRoleByEmail(@Param("email") String email);

    @Query("SELECT MAX(m.lastactive) FROM Muser m WHERE m.companyName = :companyName")
    LocalDateTime findLatestLastActiveByCompany(@Param("companyName") String companyName);

    @Query("SELECT u FROM Muser u WHERE u.email = ?1 AND u.companyName = ?2")
    Optional<Muser> findByEmailandCompanyName(String email, String companyName);

    @Query("SELECT new com.vsmartengine.invoicebill.User.MuserRequiredDto(u.userId, u.username, u.email) "
            + "FROM Muser u WHERE u.userId = ?1 AND u.companyName = ?2")
    Optional<MuserRequiredDto> findByuserIdandCompanyName(Long userId, String companyName);

    @Query("SELECT u FROM Muser u WHERE u.companyName = ?1")
    Optional<Muser> findByCompanyName(String companyName);

    @Query("SELECT u FROM Muser u WHERE u.companyName = ?1")
    List<Muser> findByCompanyNameall(String companyName);

    @Query("SELECT u.email FROM Muser u WHERE u.role.roleName = 'ADMIN' AND u.companyName = :companyname")
    List<String> findAdminEmailfromCompanyName(@Param("companyname") String companyName);

    @Query("SELECT u FROM Muser u WHERE u.role.roleName = :rolename AND u.companyName = :companyname")
    List<Muser> findByRoleNameAndCompanyName(@Param("rolename") String roleName,
            @Param("companyname") String companyName);

    @Query("SELECT COUNT(u) FROM Muser u WHERE u.role.roleName = :rolename AND u.companyName = :companyname")
    Long countByRoleNameandCompanyName(@Param("rolename") String roleName,
            @Param("companyname") String companyName);

    @Query("SELECT COUNT(u) FROM Muser u WHERE u.role.roleName = :rolename")
    Long countByRoleName(@Param("rolename") String roleName);

    @Query("SELECT isActive FROM Muser u WHERE u.role.roleName = :rolename AND u.companyName = :companyname")
    Boolean getactiveResultByCompanyName(@Param("rolename") String roleName,
            @Param("companyname") String companyName);

    @Query("SELECT u FROM Muser u WHERE u.role.roleId = ?1")
    Optional<Muser> findByroleid(Long roleId);

    @Query("SELECT u FROM Muser u WHERE u.role.roleId = ?1")
    List<Muser> findByroleidSAS(Long roleId);
}