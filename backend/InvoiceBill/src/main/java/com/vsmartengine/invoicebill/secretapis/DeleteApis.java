package com.vsmartengine.invoicebill.secretapis;

import java.util.Optional;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import com.vsmartengine.invoicebill.User.Muser;
import com.vsmartengine.invoicebill.User.Repository.MuserRepositories;
import com.vsmartengine.invoicebill.User.SecurityConfiguration.JwtUtil;

@RestController
@RequestMapping("/secret")
@CrossOrigin
public class DeleteApis {

    @Autowired
    private MuserRepositories muserrepositories;

    @Autowired
    private JwtUtil jwtUtil;

    private static final Logger logger = LoggerFactory.getLogger(DeleteApis.class);

    // SYSADMIN deletes an ADMIN
    @DeleteMapping("/Delete/Admin/{email}")
    public ResponseEntity<?> deleteAdmin(@RequestHeader("Authorization") String token,
            @PathVariable String email) {
        try {
            String role = jwtUtil.getRoleFromToken(token);

            if ("SYSADMIN".equals(role)) {
                Optional<Muser> existingUser = muserrepositories.findByEmail(email);

                if (existingUser.isPresent()) {
                    Muser user = existingUser.get();

                    if ("ADMIN".equals(user.getRole().getRoleName())) {
                        muserrepositories.delete(user);
                        return ResponseEntity.ok().body("{\"message\": \"Admin Deleted Successfully\"}");
                    }
                    return ResponseEntity.badRequest().body("{\"message\": \"Given email is not an Admin\"}");
                } else {
                    return ResponseEntity.notFound().build();
                }
            } else {
                return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                        .body("{\"message\": \"Unauthorized\"}");
            }
        } catch (Exception e) {
            logger.error("Error deleting admin", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    // SYSADMIN or ADMIN deletes a CASHIER
    @DeleteMapping("/Delete/Cashier/{email}")
    public ResponseEntity<?> deleteCashier(@RequestHeader("Authorization") String token,
            @PathVariable String email) {
        try {
            String role = jwtUtil.getRoleFromToken(token);

            if ("SYSADMIN".equals(role) || "ADMIN".equals(role)) {
                Optional<Muser> existingUser = muserrepositories.findByEmail(email);

                if (existingUser.isPresent()) {
                    Muser user = existingUser.get();

                    if ("CASHIER".equals(user.getRole().getRoleName())) {
                        muserrepositories.delete(user);
                        return ResponseEntity.ok().body("{\"message\": \"Cashier Deleted Successfully\"}");
                    }
                    return ResponseEntity.badRequest().body("{\"message\": \"Given email is not a Cashier\"}");
                } else {
                    return ResponseEntity.notFound().build();
                }
            } else {
                return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                        .body("{\"message\": \"Unauthorized\"}");
            }
        } catch (Exception e) {
            logger.error("Error deleting cashier", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }
}