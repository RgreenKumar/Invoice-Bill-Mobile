package com.vsmartengine.invoicebill.User.Controller;

import java.io.IOException;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import com.vsmartengine.invoicebill.Email.EmailService;
import com.vsmartengine.invoicebill.Notification.Service.NotificationService;
import com.vsmartengine.invoicebill.User.AddCashierRequestDto;
import com.vsmartengine.invoicebill.User.CashierPermission;
import com.vsmartengine.invoicebill.User.CashierPermissionDto;
import com.vsmartengine.invoicebill.User.CashierResponseDto;
import com.vsmartengine.invoicebill.User.Muser;
import com.vsmartengine.invoicebill.User.MuserRoles;
import com.vsmartengine.invoicebill.User.Repository.MuserRepositories;
import com.vsmartengine.invoicebill.User.Repository.MuserRoleRepository;
import com.vsmartengine.invoicebill.User.SecurityConfiguration.CacheService;
import com.vsmartengine.invoicebill.User.SecurityConfiguration.JwtUtil;
import com.vsmartengine.invoicebill.User.SecurityConfiguration.OtpService;
import com.vsmartengine.invoicebill.User.Approvals.CashierPermissionRepository;
import io.jsonwebtoken.io.DecodingException;
import jakarta.servlet.http.HttpServletRequest;

@RestController
public class AddUsers {
	@Autowired
	private MuserRepositories muserrepositories;
	@Autowired
	private JwtUtil jwtUtil;
	@Autowired
	private MuserRoleRepository muserrolerepository;
	@Autowired
	private BCryptPasswordEncoder passwordEncoder;
	@Autowired
	private NotificationService notiservice;
	@Autowired
	private EmailService emailService;
	@Autowired
	private CacheService cacheService;
	@Autowired
	private OtpService otpService;
	@Autowired
	private CashierPermissionRepository cashierPermissionRepository;
	
	private static final Logger logger = LoggerFactory.getLogger(AddUsers.class);

	public ResponseEntity<?> addTrainer(HttpServletRequest request, String username, String psw, String email,
			LocalDate dob, String phone, String skills, MultipartFile profile, Boolean isActive, String countryCode,
			String token, String otp) {
		try {
			if (!otpService.validateOtp(email, otp)) {
				return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Invalid or expired OTP");
			}
			// Remove OTP after successful verification
			otpService.clearOtp(email);
			String role = jwtUtil.getRoleFromToken(token);
			String adminemail = jwtUtil.getEmailFromToken(token);

			// Perform authentication based on role
			if ("ADMIN".equals(role)) {
				Optional<Muser> existingUser = muserrepositories.findByEmail(email);

				if (existingUser.isPresent()) {
					return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("EMAIL");
				} else {
					MuserRoles roletrainer = muserrolerepository.findByroleName("TRAINER");
					Muser trainer = new Muser();
					Optional<Muser> addingadmin = muserrepositories.findByEmail(adminemail);
					if (addingadmin.isPresent()) {

						Muser adding = addingadmin.get();

						trainer.setCompanyName(adding.getCompanyName());
						if (username == null || username.trim().isEmpty()) {
							// Extract the part before '@' from the email
							if (email != null && email.contains("@")) {
								username = email.substring(0, email.indexOf("@"));
							}
						}
						trainer.setUsername(username);
						trainer.setEmail(email);
						trainer.setIsActive(isActive);
						trainer.setPassword(psw, passwordEncoder);
						trainer.setPhone(phone);
						trainer.setDob(dob);
						trainer.setSkills(skills);
						trainer.setRole(roletrainer);
						trainer.setCountryCode(countryCode);
						if (profile != null && !profile.isEmpty()) {
							try {
								trainer.setProfile(profile.getBytes());
							} catch (IOException e) {
								e.printStackTrace();
								logger.error("", e);
							}
						}

						muserrepositories.save(trainer);
						List<String> bcc = null;
						List<String> cc = null;
						String institutionname = adding.getCompanyName();
						String domain = request.getHeader("origin"); // Extracts the domain dynamically

						// Fallback if "Origin" header is not present (e.g., direct backend requests)
						if (domain == null || domain.isEmpty()) {
							domain = request.getScheme() + "://" + request.getServerName();
							if (request.getServerPort() != 80 && request.getServerPort() != 443) {
								domain += ":" + request.getServerPort();
							}
						}

						// Construct the Sign-in Link
						String signInLink = domain + "/login";
						String body = String.format("<html>" + "<body>" + "<h2>Welcome to LearnHub Trainer Portal!</h2>"
								+ "<p>Dear %s,</p>"
								+ "<p>We are thrilled to have you as a trainer at LearnHub. Your expertise will help shape the learning journey of many students.</p>"
								+ "<p>Here are your login credentials:</p>" + "<ul>"
								+ "<li><strong>Username (Email):</strong> %s</li>"
								+ "<li><strong>Password:</strong> %s</li>" + "</ul>" + "<p>As a trainer, you can:</p>"
								+ "<ul>" + "<li>Create and manage courses.</li>"
								+ "<li>Interact with students and address their queries.</li>"
								+ "<li>Track student progress and provide valuable feedback.</li>"
								+ "<li>And Many More....</li>" + "</ul>"
								+ "<p>If you need any assistance, our support team is here to help.</p>"

								+ "<p>Click the link below to sign in:</p>" + "<p><a href='" + signInLink
								+ "' style='font-size:16px; color:blue;'>Sign In</a></p>"
								+ "<p>We look forward to your contribution in making learning more impactful!</p>"
								+ "<p>Best Regards,<br>LearnHub Team</p>" + "</body>" + "</html>",
								trainer.getUsername(), // Trainer Name
								trainer.getEmail(), // Trainer Username (email)
								psw // Trainer Password
						);

						if (institutionname != null && !institutionname.isEmpty()) {
							try {
								List<String> emailList = new ArrayList<>();
								emailList.add(trainer.getEmail());
								emailService.sendHtmlEmailAsync(institutionname, emailList, cc, bcc,
										"Welcome to LearnHub - Trainer Access Granted!", body);
							} catch (Exception e) {
								logger.error("Error sending mail: " + e.getMessage());
							}
						}

						return ResponseEntity.ok().body("{\"message\": \"saved Successfully\"}");
					} else {

						return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
					}
				}
			} else {
				return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
			}
		} catch (DecodingException ex) {
			// Log the decoding exception
			ex.printStackTrace(); // You can replace this with logging framework like Log4j
			logger.error("", ex);
			// Return an error response indicating invalid token
			return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
		} catch (Exception e) {
			// Log any other exceptions for debugging purposes
			logger.error("", e);
			e.printStackTrace(); // You can replace this with logging framework like Log4j
			// Return an internal server error response
			return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
		}
	}

//===========================================ADMIN OR TRAINER -ADDING STUDENT======================================================	  

//	public ResponseEntity<?> addStudent(HttpServletRequest request, String username, String psw, String email,
//			LocalDate dob, String phone, String skills, MultipartFile profile, Boolean isActive, String countryCode,
//			String token, String otp) {
//		try {
//			if (!otpService.validateOtp(email, otp)) {
//				return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Invalid or expired OTP");
//			}
//			// Remove OTP after successful verification
//			otpService.clearOtp(email);
//			String role = jwtUtil.getRoleFromToken(token);
//			String emailofadd = jwtUtil.getEmailFromToken(token);
//			String usernameofadding = "";
//			String emailofadding = "";
//			String company= "";
//			Optional<Muser> optiUser = muserrepositories.findByEmail(emailofadd);
//			if (optiUser.isPresent()) {
//				Muser addinguser = optiUser.get();
//				usernameofadding = addinguser.getUsername();
//				emailofadding = addinguser.getEmail();
//				company= addinguser.getCompanyName();
//			} else {
//				return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
//			}
//
//			// Perform authentication based on role
//			if ("ADMIN".equals(role) || "TRAINER".equals(role)) {
//
//				Optional<Muser> existingUser = muserrepositories.findByEmail(email);
//				if (existingUser.isPresent()) {
//					return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("EMAIL");
//				} else {
//					MuserRoles roletrainer = muserrolerepository.findByroleName("USER");
//					if (username == null || username.trim().isEmpty()) {
//						// Extract the part before '@' from the email
//						if (email != null && email.contains("@")) {
//							username = email.substring(0, email.indexOf("@"));
//						}
//					}
//					Muser user = new Muser();
//					user.setUsername(username);
//					user.setEmail(email);
//					user.setIsActive(isActive);
//					user.setPassword(psw, passwordEncoder);
//					user.setPhone(phone);
//					user.setDob(dob);
//					user.setRole(roletrainer);
//					user.setCompanyName(company);
//					user.setSkills(skills);
//					user.setCountryCode(countryCode);
//					if (profile != null && !profile.isEmpty()) {
//						try {
//							user.setProfile(profile.getBytes());
//						} catch (IOException e) {
//							e.printStackTrace();
//							logger.error("", e);
//						}
//					}
//					Muser saveduser = muserrepositories.save(user);
//					String heading = "New Student Added !";
//					String link = "/view/Student/profile/" + saveduser.getEmail();
//					String notidescription = "A new Student " + saveduser.getUsername() + " was added";
//
//					Long NotifyId = notiservice.createNotification("UserAdd", usernameofadding, notidescription,
//							emailofadding, heading, link, Optional.ofNullable(profile));
//					if (NotifyId != null) {
//						List<String> notiuserlist = new ArrayList<>();
//						notiuserlist.add("ADMIN");
//						notiservice.CommoncreateNotificationUser(NotifyId, notiuserlist, company);
//					}
//					List<String> bcc = null;
//					List<String> cc = null;
//					String institutionname = company;
//					String domain = request.getHeader("origin"); // Extracts the domain dynamically
//
//					// Fallback if "Origin" header is not present (e.g., direct backend requests)
//					if (domain == null || domain.isEmpty()) {
//						domain = request.getScheme() + "://" + request.getServerName();
//						if (request.getServerPort() != 80 && request.getServerPort() != 443) {
//							domain += ":" + request.getServerPort();
//						}
//					}
//
//					// Construct the Sign-in Link
//					String signInLink = domain + "/login";
//					String body = String.format("<html>" + "<body>" + "<h2>Welcome to LearnHub!</h2>"
//							+ "<p>Dear %s,</p>"
//							+ "<p>We are excited to have you on board at LearnHub, your gateway to knowledge and growth.</p>"
//							+ "<p>Here are your login credentials to access your courses:</p>" + "<ul>"
//							+ "<li><strong>Username (Email):</strong> %s</li>"
//							+ "<li><strong>Password:</strong> %s</li>" + "</ul>"
//							+ "<p>Start exploring your enrolled courses, engage with trainers, and enhance your learning experience.</p>"
//							+ "<p>If you need any support, feel free to reach out to our help desk.</p>"
//
//							+ "<p>Click the link below to sign in:</p>" + "<p><a href='" + signInLink
//							+ "' style='font-size:16px; color:blue;'>Sign In</a></p>" + "<p>Happy Learning!</p>"
//							+ "<p>Best Regards,<br>LearnHub Team</p>" + "</body>" + "</html>", username, email, // Student
//																												// Username
//																												// (email)
//							psw);
//
//					if (institutionname != null && !institutionname.isEmpty()) {
//						try {
//							List<String> emailList = new ArrayList<>();
//							emailList.add(email);
//							emailService.sendHtmlEmailAsync(institutionname, emailList, cc, bcc,
//									"Welcome to LearnHub - Start Your Learning Journey!", body);
//						} catch (Exception e) {
//							logger.error("Error sending mail: " + e.getMessage());
//						}
//					}
//
//					return ResponseEntity.ok().body("{\"message\": \"saved Successfully\"}");
//				}
//			} else {
//
//				System.out.println("not a trainer or admin");
//				return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
//			}
//		} catch (DecodingException ex) {
//			// Log the decoding exception
//			ex.printStackTrace(); // You can replace this with logging framework like Log4j
//			logger.error("", ex);
//			// Return an error response indicating invalid token
//
//			System.out.println("catch ");
//			return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
//		} catch (Exception e) {
//			// Log any other exceptions for debugging purposes
//			e.printStackTrace(); // You can replace this with logging framework like Log4j
//			logger.error("", e);
//			// Return an internal server error response
//			return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
//		}
//	}
//
//	public ResponseEntity<?> DeactivateTrainer(String reason, String email, String token) {
//		try {
//			String role = jwtUtil.getRoleFromToken(token);
//
//			// Perform authentication based on role
//			if ("ADMIN".equals(role) || "SYSADMIN".equals(role)) {
//				Optional<Muser> existingUser = muserrepositories.findByEmail(email);
//				if (existingUser.isPresent()) {
//					Muser user = existingUser.get();
//					if ("TRAINER".equals(user.getRole().getRoleName())) {
//						user.setIsActive(false);
//						user.setInactiveDescription(reason);
//						muserrepositories.save(user);
//						cacheService.setUserActiveStatus(user.getEmail(), false);
//						return ResponseEntity.ok().body("{\"message\": \"DeActivated Successfully\"}");
//					}
//					return ResponseEntity.notFound().build();
//				} else {
//					// Return not found if the user with the given email does not exist
//					return ResponseEntity.notFound().build();
//				}
//			} else {
//				// Return unauthorized status if the role is neither ADMIN nor TRAINER
//				return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
//			}
//		} catch (Exception e) {
//			// Log any other exceptions for debugging purposes
//			e.printStackTrace(); // You can replace this with logging framework like Log4j
//			logger.error("", e);
//			// Return an internal server error response
//			return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
//		}
//	}
//
//	public ResponseEntity<?> activateTrainer(String email, String token) {
//		try {
//			String role = jwtUtil.getRoleFromToken(token);
//
//			// Perform authentication based on role
//			if ("ADMIN".equals(role) || "SYSADMIN".equals(role)) {
//				Optional<Muser> existingUser = muserrepositories.findByEmail(email);
//				if (existingUser.isPresent()) {
//					Muser user = existingUser.get();
//					if ("TRAINER".equals(user.getRole().getRoleName())) {
//						user.setIsActive(true);
//						user.setLoginAttempts(0);
//						user.setInactiveDescription("");
//						muserrepositories.save(user);
//						cacheService.setUserActiveStatus(user.getEmail(), true);
//						return ResponseEntity.ok().body("{\"message\": \"Activated Successfully\"}");
//					}
//					return ResponseEntity.notFound().build();
//				} else {
//					// Return not found if the user with the given email does not exist
//					return ResponseEntity.notFound().build();
//				}
//			} else {
//
//				// Return unauthorized status if the role is neither ADMIN nor TRAINER
//				return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
//			}
//		} catch (Exception e) {
//			// Log any other exceptions for debugging purposes
//			e.printStackTrace(); // You can replace this with logging framework like Log4j
//			logger.error("", e);
//			// Return an internal server error response
//			return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
//		}
//	}
//
//	public ResponseEntity<?> DeactivateStudent(String reason, String email, String token) {
//		try {
//
//			String role = jwtUtil.getRoleFromToken(token);
//
//			// Perform authentication based on role
//			if ("ADMIN".equals(role) || "TRAINER".equals(role) || "SYSADMIN".equals(role)) {
//				Optional<Muser> existingUser = muserrepositories.findByEmail(email);
//				if (existingUser.isPresent()) {
//					Muser user = existingUser.get();
//					if ("USER".equals(user.getRole().getRoleName())) {
//						user.setIsActive(false);
//						user.setInactiveDescription(reason);
//						muserrepositories.save(user);
//						cacheService.setUserActiveStatus(user.getEmail(), false);
//						return ResponseEntity.ok().body("{\"message\": \"Deactivated Successfully\"}");
//					}
//
//					// Return not found if the user with the given email does not exist
//					return ResponseEntity.notFound().build();
//
//				} else {
//					// Return not found if the user with the given email does not exist
//					return ResponseEntity.notFound().build();
//				}
//			} else {
//				// Return unauthorized status if the role is neither ADMIN nor TRAINER
//				return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
//			}
//		} catch (Exception e) {
//			// Log any other exceptions for debugging purposes
//			e.printStackTrace(); // You can replace this with logging framework like Log4j
//			logger.error("", e);
//			// Return an internal server error response
//			return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
//		}
//	}
//
//	public ResponseEntity<?> activateStudent(String email, String token) {
//		try {
//			String role = jwtUtil.getRoleFromToken(token);
//
//			// Perform authentication based on role
//			if ("ADMIN".equals(role) || "TRAINER".equals(role) || "SYSADMIN".equals(role)) {
//				Optional<Muser> existingUser = muserrepositories.findByEmail(email);
//				if (existingUser.isPresent()) {
//					Muser user = existingUser.get();
//					if ("USER".equals(user.getRole().getRoleName())) {
//						user.setIsActive(true);
//						user.setLoginAttempts(0);
//						user.setInactiveDescription("");
//						muserrepositories.save(user);
//						cacheService.setUserActiveStatus(user.getEmail(), true);
//						return ResponseEntity.ok().body("{\"message\": \"Activated Successfully\"}");
//					}
//
//					// Return not found if the user with the given email does not exist
//					return ResponseEntity.notFound().build();
//
//				} else {
//					// Return not found if the user with the given email does not exist
//					return ResponseEntity.notFound().build();
//				}
//			} else {
//				// Return unauthorized status if the role is neither ADMIN nor TRAINER
//				return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
//			}
//		} catch (Exception e) {
//			// Log any other exceptions for debugging purposes
//			e.printStackTrace(); // You can replace this with logging framework like Log4j
//			logger.error("", e);
//			// Return an internal server error response
//			return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
//		}
//	}
	/////////=======================add cashier============================================
	
	public ResponseEntity<?> addCashier(
	        HttpServletRequest request,
	        AddCashierRequestDto cashierRequest,
	        String token) {
	    try {

	        // ===== OTP BLOCK — uncomment when needed =====
	        // if (!otpService.validateOtp(cashierRequest.getEmail(), otp)) {
	        //     return ResponseEntity.status(HttpStatus.BAD_REQUEST)
	        //             .body("Invalid or expired OTP");
	        // }
	        // otpService.clearOtp(cashierRequest.getEmail());
	        // =============================================

	        // Get role and admin email from token
	        String role       = jwtUtil.getRoleFromToken(token);
	        String adminEmail = jwtUtil.getEmailFromToken(token);

	        // Extract from DTO into local variables
	        String username                          = cashierRequest.getUsername();
	        String email                             = cashierRequest.getEmail();
	        String phone                             = cashierRequest.getPhone();
	        List<CashierPermissionDto> permissions   = cashierRequest.getPermissions();

	        // Only ADMIN can add cashier
	        if ("ADMIN".equals(role)) {

	            // Check email already exists
	            Optional<Muser> existingUser = muserrepositories.findByEmail(email);
	            if (existingUser.isPresent()) {
	                return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("EMAIL");
	            } else {

	                // Get CASHIER role from DB
	                MuserRoles cashierRole = muserrolerepository.findByroleName("CASHIER");

	                Muser cashier = new Muser();

	                // Get admin details from DB
	                Optional<Muser> addingAdmin = muserrepositories.findByEmail(adminEmail);
	                if (addingAdmin.isPresent()) {

	                    Muser admin = addingAdmin.get();

	                    // Fix username — effectively final for lambda
	                    String finalUsername;
	                    if (username == null || username.trim().isEmpty()) {
	                        finalUsername = email.substring(0, email.indexOf("@"));
	                    } else {
	                        finalUsername = username;
	                    }

	                    // Auto generate password → invoice@ + first 4 digits of phone
	                    String rawPassword = "invoice@" + phone.substring(0, 4);

	                    // Build cashier object
	                    cashier.setUsername(finalUsername);
	                    cashier.setEmail(email);
	                    cashier.setPhone(phone);
	                    cashier.setPassword(rawPassword, passwordEncoder); // BCrypt encoded
	                    cashier.setCompanyName(admin.getCompanyName());    // from admin
	                    cashier.setCountryCode("+91");                      // default
	                    cashier.setRole(cashierRole);
	                    cashier.setIsActive(true);
	                    cashier.setLoginAttempts(0);
	                    // dob     → null (not needed for cashier)
	                    // skills  → null (not needed for cashier)
	                    // profile → null (not needed for cashier)

	                    // Save cashier to muser table
	                    Muser savedCashier = muserrepositories.save(cashier);

	                    // Save permissions to cashier_permissions table
	                    if (permissions != null && !permissions.isEmpty()) {
	                        List<CashierPermission> permList = permissions.stream().map(dto -> {
	                            CashierPermission p = new CashierPermission();
	                            p.setUser(savedCashier);
	                            p.setModuleName(dto.getModuleName());
	                            p.setCanView(dto.getCanView());
	                            p.setCanCreate(dto.getCanCreate());
	                            p.setCanEdit(dto.getCanEdit());
	                            p.setCanDelete(dto.getCanDelete());
	                            return p;
	                        }).collect(Collectors.toList());
	                        cashierPermissionRepository.saveAll(permList);
	                    }

	                    // Build email body
	                    String companyName = admin.getCompanyName();
	                    String domain      = request.getHeader("origin");

	                    // Fallback if Origin header not present
	                    if (domain == null || domain.isEmpty()) {
	                        domain = request.getScheme() + "://" + request.getServerName();
	                        if (request.getServerPort() != 80 && request.getServerPort() != 443) {
	                            domain += ":" + request.getServerPort();
	                        }
	                    }

	                    String signInLink = domain + "/login";
	                    String body = String.format(
	                        "<html>" +
	                        "<body>" +
	                        "<h2>Welcome to InvoiceBill!</h2>" +
	                        "<p>Dear %s,</p>" +
	                        "<p>You have been added as a Cashier by your Admin at %s.</p>" +
	                        "<p>Here are your login credentials:</p>" +
	                        "<ul>" +
	                        "<li><strong>Username (Email):</strong> %s</li>" +
	                        "<li><strong>Password:</strong> %s</li>" +
	                        "</ul>" +
	                        "<p>As a Cashier, you can access the modules assigned by your Admin.</p>" +
	                        "<p>If you need any assistance, please contact your Admin.</p>" +
	                        "<p>Click the link below to sign in:</p>" +
	                        "<p><a href='%s' style='font-size:16px; color:blue;'>Sign In</a></p>" +
	                        "<p>Best Regards,<br>InvoiceBill Team</p>" +
	                        "</body>" +
	                        "</html>",
	                        finalUsername,  // Dear {name}
	                        companyName,    // added by admin at {company}
	                        email,          // username (email)
	                        rawPassword,    // password plain for email
	                        signInLink      // sign in link
	                    );

	                    // Send email with credentials
	                    if (companyName != null && !companyName.isEmpty()) {
	                        try {
	                            List<String> emailList = new ArrayList<>();
	                            emailList.add(email);
	                            emailService.sendHtmlEmailAsync(
	                                companyName, emailList, null, null,
	                                "Welcome to InvoiceBill - Cashier Access Granted!", body
	                            );
	                        } catch (Exception e) {
	                            logger.error("Error sending mail: " + e.getMessage());
	                        }
	                    }

	                    return ResponseEntity.ok().body("{\"message\": \"Cashier saved Successfully\"}");

	                } else {
	                    return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
	                }
	            }
	        } else {
	            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
	        }

	    } catch (DecodingException ex) {
	        ex.printStackTrace();
	        logger.error("", ex);
	        return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
	    } catch (Exception e) {
	        logger.error("", e);
	        e.printStackTrace();
	        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
	    }
	}
	
	// ===================== DEACTIVATE CASHIER =====================
	public ResponseEntity<?> deactivateCashier(String reason, String email, String token) {
	    try {
	        String role = jwtUtil.getRoleFromToken(token);

	        if ("ADMIN".equals(role) || "SYSADMIN".equals(role)) {
	            Optional<Muser> existingUser = muserrepositories.findByEmail(email);
	            if (existingUser.isPresent()) {
	                Muser user = existingUser.get();
	                if ("CASHIER".equals(user.getRole().getRoleName())) {
	                    user.setIsActive(false);
	                    user.setInactiveDescription(reason);
	                    muserrepositories.save(user);
	                    cacheService.setUserActiveStatus(user.getEmail(), false);
	                    return ResponseEntity.ok().body("{\"message\": \"Cashier Deactivated Successfully\"}");
	                }
	                return ResponseEntity.notFound().build();
	            } else {
	                return ResponseEntity.notFound().build();
	            }
	        } else {
	            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
	        }
	    } catch (Exception e) {
	        logger.error("", e);
	        e.printStackTrace();
	        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
	    }
	}

	// ===================== ACTIVATE CASHIER =====================
	public ResponseEntity<?> activateCashier(String email, String token) {
	    try {
	        String role = jwtUtil.getRoleFromToken(token);

	        if ("ADMIN".equals(role) || "SYSADMIN".equals(role)) {
	            Optional<Muser> existingUser = muserrepositories.findByEmail(email);
	            if (existingUser.isPresent()) {
	                Muser user = existingUser.get();
	                if ("CASHIER".equals(user.getRole().getRoleName())) {
	                    user.setIsActive(true);
	                    user.setLoginAttempts(0);
	                    user.setInactiveDescription("");
	                    muserrepositories.save(user);
	                    cacheService.setUserActiveStatus(user.getEmail(), true);
	                    return ResponseEntity.ok().body("{\"message\": \"Cashier Activated Successfully\"}");
	                }
	                return ResponseEntity.notFound().build();
	            } else {
	                return ResponseEntity.notFound().build();
	            }
	        } else {
	            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
	        }
	    } catch (Exception e) {
	        logger.error("", e);
	        e.printStackTrace();
	        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
	    }
	}
	
	//getcashier
	// ===================== GET ALL CASHIERS =====================
	public ResponseEntity<?> getCashiers(String token) {
	    try {
	        String role       = jwtUtil.getRoleFromToken(token);
	        String adminEmail = jwtUtil.getEmailFromToken(token);

	        if ("ADMIN".equals(role)) {
	            Optional<Muser> adminOpt = muserrepositories.findByEmail(adminEmail);
	            if (adminOpt.isEmpty()) {
	                return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
	                        .body("{\"message\": \"Admin not found\"}");
	            }

	            String companyName = adminOpt.get().getCompanyName();

	            List<Muser> cashiers = muserrepositories
	                    .findByRoleNameAndCompanyName("CASHIER", companyName);

	            List<CashierResponseDto> result = cashiers.stream()
	                    .map(u -> new CashierResponseDto(
	                            u.getUserId(),
	                            u.getUsername(),
	                            u.getEmail(),
	                            u.getPhone(),
	                            u.getIsActive()))
	                    .collect(Collectors.toList());

	            return ResponseEntity.ok(result);

	        } else {
	            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
	        }

	    } catch (Exception e) {
	        logger.error("", e);
	        e.printStackTrace();
	        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
	    }
	}
	
	
	
	

}
