package com.vsmartengine.invoicebill.User.SecurityConfiguration;


import jakarta.servlet.http.HttpServletRequest;
import org.aspectj.lang.ProceedingJoinPoint;
import org.aspectj.lang.annotation.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.cache.CacheManager;
import org.springframework.stereotype.Component;
import org.aspectj.lang.annotation.Aspect;
import org.springframework.web.context.request.RequestContextHolder;
import org.springframework.web.context.request.ServletRequestAttributes;

import com.vsmartengine.invoicebill.User.Repository.MuserRepositories;

@Aspect
@Component
public class AccessCheckAspect {

    @Autowired
    private JwtUtil jwtUtil;

    @Autowired
    private MuserRepositories muserRepository;

    @Autowired
    private CacheManager cacheManager;

    @Around("@annotation(com.vsmartengine.invoicebill.User.SecurityConfiguration.CheckAccessAnnotation)")
    public Object checkAccess(ProceedingJoinPoint joinPoint) throws Throwable {
        HttpServletRequest request = ((ServletRequestAttributes) RequestContextHolder.getRequestAttributes()).getRequest();

        String token = request.getHeader("Authorization");
        String role = jwtUtil.getRoleFromToken(token);
         if (token == null || !jwtUtil.validateToken(token)) {
            throw new UnauthorizedAccessException("Invalid Token");
        }
        if("SYSADMIN".equals(role)) {
            return joinPoint.proceed();
        }
      
        String company = jwtUtil.getCompanyFromToken(token);
        String email = jwtUtil.getEmailFromToken(token);
        
        if (company == null || email == null) {
            throw new UnauthorizedAccessException("Invalid Token");
        }

        // Check user active status
        String userCacheKey = "userActive::" + email;
        Boolean isUserActive = cacheManager.getCache("userActive") != null
                ? cacheManager.getCache("userActive").get(userCacheKey, Boolean.class)
                : null;

        if (isUserActive == null) {
            Boolean userActiveStatus = muserRepository.findByEmail(email)
                    .map(user -> user.getIsActive())
                    .orElse(false);
            if (cacheManager.getCache("userActive") != null) {
                cacheManager.getCache("userActive").put(userCacheKey, userActiveStatus);
            }
            if (!userActiveStatus) {
                throw new UnauthorizedAccessException("User Account Inactive");
            }
        } else if (!isUserActive) {
            throw new UnauthorizedAccessException("User Account Inactive");
        }

        // Check company blocked status
        String companyCacheKey = "companyBlocked::" + company;
        Boolean isBlocked = cacheManager.getCache("companyBlocked") != null
                ? cacheManager.getCache("companyBlocked").get(companyCacheKey, Boolean.class)
                : null;

        if (isBlocked == null) {
            boolean adminActive = muserRepository.getactiveResultByCompanyName("ADMIN", company);
            if (cacheManager.getCache("companyBlocked") != null) {
                cacheManager.getCache("companyBlocked").put(companyCacheKey, !adminActive);
            }
            if (!adminActive) {
                throw new UnauthorizedAccessException("Institution Blocked");
            }
        } else if (isBlocked) {
            throw new UnauthorizedAccessException("Institution Blocked");
        }

        return joinPoint.proceed();
    }
}

