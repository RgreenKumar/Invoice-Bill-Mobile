package com.vsmartengine.invoicebill.User.Controller;

import java.io.IOException;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import com.vsmartengine.invoicebill.Email.EmailService;
import com.vsmartengine.invoicebill.User.Muser;
import com.vsmartengine.invoicebill.User.MuserAddInfoDto;
import com.vsmartengine.invoicebill.User.MuserDto;
import com.vsmartengine.invoicebill.User.MuserProfileDTO;
import com.vsmartengine.invoicebill.User.MuserRequiredDto;
import com.vsmartengine.invoicebill.User.MuserRoles;
import com.vsmartengine.invoicebill.User.Approvals.MuserApprovalRepo;
import com.vsmartengine.invoicebill.User.Approvals.MuserApprovals;
import com.vsmartengine.invoicebill.User.Repository.MuserRepositories;
import com.vsmartengine.invoicebill.User.Repository.MuserRoleRepository;
import com.vsmartengine.invoicebill.User.SecurityConfiguration.JwtUtil;
import com.vsmartengine.invoicebill.User.SecurityConfiguration.OtpService;

import jakarta.mail.internet.MimeMessage;
import jakarta.servlet.http.HttpServletRequest;

@RestController
public class MserRegistrationController {
	@Autowired
	private MuserRepositories muserrepositories;
	@Autowired
	private BCryptPasswordEncoder passwordEncoder;

	@Autowired
	private JwtUtil jwtUtil;
	@Autowired
	private MuserRoleRepository muserrolerepository;

	@Autowired
	private MuserApprovalRepo MuserApproval;

	@Autowired
	private EmailService emailservice;

	@Value("${spring.environment}")
	private String environment;

	@Value("${spring.profiles.active}")
	private String activeProfile;

	@Value("${base.url}")
	private String baseUrl;

	@Autowired
	private OtpService otpService;

	private static final Logger logger = LoggerFactory.getLogger(MserRegistrationController.class);

	@Autowired
	private JavaMailSender mailSender;

	@Value("${spring.mail.username}")
	private String emailUsername;

	public Long countadmin() {
		return muserrepositories.countByRoleName("ADMIN");
	}

	public ResponseEntity<?> registerAdmin(HttpServletRequest request, String username, String psw, String email,
			String companyName, LocalDate dob, String role, String phone, String skills, MultipartFile profile,
			Boolean isActive, String countryCode, String otp) {
		try {
			if (!otpService.validateOtp(email, otp)) {
				return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Invalid or expired OTP");
			}
			// Remove OTP after successful verification
			otpService.clearOtp(email);

			Long count = muserrepositories.count();
			if (environment.equals("VPS") && count > 1) {
				return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("ADMIN");
			}

			Optional<Muser> existingUser = muserrepositories.findByEmail(email);
			Optional<Muser> existingCompany = muserrepositories.findByCompanyName(companyName);

			if (existingUser.isPresent()) {
				return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("EMAIL");
			}
			if (existingCompany.isPresent()) {
				return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("INSTITUTE");
			}

			Optional<MuserRoles> oproleUser = muserrolerepository.findByRoleName("ADMIN");
			if (oproleUser.isPresent()) {
				MuserRoles roleuser = oproleUser.get();

				if (username == null || username.trim().isEmpty()) {
					if (email != null && email.contains("@")) {
						username = email.substring(0, email.indexOf("@"));
					}
				}

				Muser user = new Muser();
				user.setUsername(username);
				user.setEmail(email);
				String plainTextPassword = psw;
				user.setPassword(psw, passwordEncoder);
				user.setIsActive(isActive);
				user.setPhone(phone);
				user.setDob(dob);
				user.setSkills(skills);
				user.setCompanyName(companyName);
				user.setCountryCode(countryCode);
				user.setRole(roleuser);

				if (profile != null && !profile.isEmpty()) {
					try {
						user.setProfile(profile.getBytes());
					} catch (IOException e) {
						e.printStackTrace();
						logger.error("", e);
						return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
								.body("{\"message\": \"Error compressing image\"}");
					}
				}

				// ✅ Save admin to database
				muserrepositories.save(user);

				List<String> bcc = null;
				List<String> cc = null;
				String companyname = companyName;

				String domain = request.getHeader("origin");
				if (domain == null || domain.isEmpty()) {
					domain = request.getScheme() + "://" + request.getServerName();
					if (request.getServerPort() != 80 && request.getServerPort() != 443) {
						domain += ":" + request.getServerPort();
					}
				}

				String signInLink = domain + "/login";

				String body = String.format("<html>" + "<body>" + "<h2>Welcome to LearnHub Admin Portal!</h2>"
						+ "<p>Dear %s,</p>" + "<p>We are excited to welcome you as an administrator at LearnHub.</p>"
						+ "<p>Here are your login credentials:</p>" + "<ul>"
						+ "<li><strong>Username (Email):</strong> %s</li>" + "<li><strong>Password:</strong> %s</li>"
						+ "</ul>" + "<p>With your admin access, you can:</p>" + "<ul>"
						+ "<li>Add and manage courses.</li>" + "<li>Add and manage Student and Trainers.</li>"
						+ "<li>Approve the Registered Trainer.</li>" + "<li>Allot Courses For Trainers.</li>"
						+ "<li>Oversee Revenue Details.</li>" + "<li>Oversee student enrollments.</li>"
						+ "<li>Update course content.</li>" + "<li>Support students in their learning journey.</li>"
						+ "<li>And Many More.....</li>" + "</ul>"
						+ "<p>If you need any assistance, our support team is always here to help.</p>"
						+ "<p>Click the link below to sign in:</p>" + "<p><a href='" + signInLink
						+ "' style='font-size:16px; color:blue;'>Sign In</a></p>"
						+ "<p>We appreciate your dedication and look forward to a great collaboration!</p>"
						+ "<p>Best Regards,<br>LearnHub Team</p>" + "</body>" + "</html>",
						user.getUsername(),
						user.getEmail(),
						plainTextPassword);

				if (companyname != null && !companyname.isEmpty()) {
					try {
						List<String> emailList = new ArrayList<>();
						emailList.add(email);
						System.out.println("sending.." + email);
						emailservice.sendHtmlEmailAsync(companyname, emailList, cc, bcc,
								"Welcome to LearnHub - Start Your Administrator Journey Today!", body);
					} catch (Exception e) {
						System.out.println("cant send email" + e.getMessage());
						logger.error("Error sending mail: " + e.getMessage());
					}
				}

				return ResponseEntity.ok().body("{\"message\": \"saved Successfully\"}");
			} else {
				return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
						.body("{\"message\": \"Error getting role\"}");
			}
		} catch (Exception e) {
			e.printStackTrace();
			logger.error("", e);
			return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
					.body("{\"message\": \"Internal Server Error\"}");
		}
	}

//	public ResponseEntity<?> RegisterStudent(HttpServletRequest request, String username, String psw, String email,
//			LocalDate dob, String role, String phone, String skills, MultipartFile profile, Boolean isActive,
//			String countryCode, String otp) {
//		try {
//			if (!otpService.validateOtp(email, otp)) {
//				return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Invalid or expired OTP");
//			}
//			// Remove OTP after successful verification
//			otpService.clearOtp(email);
//
//			if (!environment.equals("VPS")) {
//				return ResponseEntity.status(HttpStatus.BAD_REQUEST)
//						.body("Cannot Register as Student in Sas Environment");
//			}
//			Long admincount = muserrepositories.countByRoleName("ADMIN");
//			if (admincount == 0) {
//				return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("No company Found");
//			}
//			if (admincount > 1) {
//				return ResponseEntity.status(HttpStatus.BAD_REQUEST)
//						.body("Cannot Register as Student in Sas Environment");
//			}
//
//			Optional<Muser> existingUser = muserrepositories.findByEmail(email);
//			String existingCompany = muserrepositories.getCompany("ADMIN");
//
//			if (existingCompany == null || existingCompany.isEmpty()) {
//				return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("company not Found");
//			}
//			if (existingUser.isPresent()) {
//				return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("EMAIL");
//			}
//
//			Optional<MuserRoles> oproleUser = muserrolerepository.findByRoleName("USER");
//			if (oproleUser.isPresent()) {
//				MuserRoles roleuser = oproleUser.get();
//
//				if (username == null || username.trim().isEmpty()) {
//					if (email != null && email.contains("@")) {
//						username = email.substring(0, email.indexOf("@"));
//					}
//				}
//
//				Muser user = new Muser();
//				user.setUsername(username);
//				user.setEmail(email);
//				String plainTextPassword = psw;
//				user.setPassword(psw, passwordEncoder);
//				user.setPhone(phone);
//				user.setDob(dob);
//				user.setSkills(skills);
//				user.setCompanyName(existingCompany);
//				user.setCountryCode(countryCode);
//				user.setRole(roleuser);
//
//				if (profile != null && !profile.isEmpty()) {
//					try {
//						user.setProfile(profile.getBytes());
//					} catch (IOException e) {
//						e.printStackTrace();
//						logger.error("", e);
//						return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
//								.body("{\"message\": \"Error compressing image\"}");
//					}
//				}
//
//				muserrepositories.save(user);
//
//				List<String> bcc = null;
//				List<String> cc = null;
//				String companyname = existingCompany;
//
//				String domain = request.getHeader("origin");
//				if (domain == null || domain.isEmpty()) {
//					domain = request.getScheme() + "://" + request.getServerName();
//					if (request.getServerPort() != 80 && request.getServerPort() != 443) {
//						domain += ":" + request.getServerPort();
//					}
//				}
//
//				String signInLink = domain + "/login";
//				String body = String.format("<html>" + "<body>" + "<h2>Welcome to LearnHub!</h2>" + "<p>Dear %s,</p>"
//						+ "<p>We are excited to have you on board at LearnHub, your gateway to knowledge and growth.</p>"
//						+ "<p>Here are your login credentials to access your courses:</p>" + "<ul>"
//						+ "<li><strong>Username (Email):</strong> %s</li>" + "<li><strong>Password:</strong> %s</li>"
//						+ "</ul>"
//						+ "<p>Start exploring your enrolled courses, engage with trainers, and enhance your learning experience.</p>"
//						+ "<p>If you need any support, feel free to reach out to our help desk.</p>"
//						+ "<p>Click the link below to sign in:</p>" + "<p><a href='" + signInLink
//						+ "' style='font-size:16px; color:blue;'>Sign In</a></p>" + "<p>Happy Learning!</p>"
//						+ "<p>Best Regards,<br>LearnHub Team</p>" + "</body>" + "</html>",
//						username,
//						email,
//						plainTextPassword);
//
//				if (companyname != null && !companyname.isEmpty()) {
//					try {
//						List<String> emailList = new ArrayList<>();
//						emailList.add(email);
//						emailservice.sendHtmlEmailAsync(companyname, emailList, cc, bcc,
//								"Welcome to LearnHub - Start Your Learning Journey!", body);
//					} catch (Exception e) {
//						logger.error("Error sending mail: " + e.getMessage());
//					}
//				}
//
//				return ResponseEntity.ok().body("{\"message\": \"saved Successfully\"}");
//			} else {
//				return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
//						.body("{\"message\": \"Error getting role\"}");
//			}
//		} catch (Exception e) {
//			e.printStackTrace();
//			logger.error("", e);
//			return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
//					.body("{\"message\": \"Internal Server Error\"}");
//		}
//	}

//	public ResponseEntity<?> RegisterTrainer(HttpServletRequest request, String username, String psw, String email,
//			LocalDate dob, String role, String phone, String skills, MultipartFile profile, Boolean isActive,
//			String countryCode, String otp) {
//		try {
//			if (!otpService.validateOtp(email, otp)) {
//				return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Invalid or expired OTP");
//			}
//			// Remove OTP after successful verification
//			otpService.clearOtp(email);
//
//			if (!environment.equals("VPS")) {
//				return ResponseEntity.status(HttpStatus.BAD_REQUEST)
//						.body("Cannot Register as Trainer in Sas Environment");
//			}
//
//			MuserAddInfoDto adminInfo = muserrepositories.getAdminInfo(email);
//			System.out.println(adminInfo.toString());
//
//			if (adminInfo.getAdminCount() == 0) {
//				return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("No company Found");
//			}
//			if (adminInfo.getAdminCount() > 1) {
//				return ResponseEntity.status(HttpStatus.BAD_REQUEST)
//						.body("Cannot Register as Trainer in Sas Environment");
//			}
//			if (adminInfo.getCompanyName() == null || adminInfo.getCompanyName().isEmpty()) {
//				return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Institution not Found");
//			}
//			if (adminInfo.isEmailExists()) {
//				return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("EMAIL");
//			}
//
//			String adminEmail = adminInfo.getAdminEmail();
//			String existingCompany = adminInfo.getCompanyName();
//
//			Optional<MuserRoles> oproleUser = muserrolerepository.findByRoleName("TRAINER");
//			if (oproleUser.isPresent()) {
//				MuserRoles roleuser = oproleUser.get();
//
//				if (username == null || username.trim().isEmpty()) {
//					if (email != null && email.contains("@")) {
//						username = email.substring(0, email.indexOf("@"));
//					}
//				}
//
//				MuserApprovals user = new MuserApprovals();
//				user.setUsername(username);
//				user.setEmail(email);
//				user.setIsActive(isActive);
//				user.setPsw(psw);
//				user.setPhone(phone);
//				user.setDob(dob);
//				user.setSkills(skills);
//				user.setCompanyName(existingCompany);
//				user.setCountryCode(countryCode);
//				user.setRole(roleuser);
//
//				if (profile != null && !profile.isEmpty()) {
//					try {
//						user.setProfile(profile.getBytes());
//					} catch (IOException e) {
//						logger.error("Error processing profile image", e);
//					}
//				}
//
//				MuserApproval.save(user);
//				sendApprovalEmail(request, adminEmail, user);
//
//				return ResponseEntity.ok().body("{\"message\": \"Trainer registration pending approval.\"}");
//			} else {
//				return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("{\"message\": \"Error getting role\"}");
//			}
//		} catch (Exception e) {
//			logger.error("Error registering trainer", e);
//			return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
//					.body("{\"message\": \"Internal Server Error\"}");
//		}
//	}

//	private void sendApprovalEmail(HttpServletRequest request, String adminEmail, MuserApprovals trainer) {
//		try {
//			String domain = request.getHeader("origin");
//			if (domain == null || domain.isEmpty()) {
//				domain = request.getScheme() + "://" + request.getServerName();
//				if (request.getServerPort() != 80 && request.getServerPort() != 443) {
//					domain += ":" + request.getServerPort();
//				}
//			}
//
//			String approvalLink = domain + "/view/Approvals";
//
//			StringBuilder body = new StringBuilder();
//			body.append("<html><body>");
//			body.append("<h2>Trainer Approval Request</h2>");
//			body.append("<p>Dear Admin,</p>");
//			body.append("<p>A new trainer has registered and is awaiting your approval.</p>");
//			body.append("<p><strong>Trainer Details:</strong></p>");
//			body.append("<ul>");
//			body.append("<li><strong>Name:</strong> ").append(trainer.getUsername()).append("</li>");
//			body.append("<li><strong>Email:</strong> ").append(trainer.getEmail()).append("</li>");
//			body.append("<li><strong>Phone:</strong> ").append(trainer.getPhone()).append("</li>");
//			body.append("<li><strong>Skills:</strong> ")
//					.append(trainer.getSkills() != null ? trainer.getSkills() : "Not specified").append("</li>");
//			body.append("<li><strong>Date of Birth:</strong> ")
//					.append(trainer.getDob() != null ? trainer.getDob().toString() : "Not specified").append("</li>");
//			body.append("<li><strong>Company:</strong> ").append(trainer.getCompanyName()).append("</li>");
//			body.append("</ul>");
//			body.append("<p><a href='").append(approvalLink)
//					.append("' style='font-size:16px; color:blue;'>Review Approvals</a></p>");
//			body.append("<p>Best Regards,<br>LearnHub Team</p>");
//			body.append("</body></html>");
//
//			List<String> addminEmailList = new ArrayList<String>();
//			addminEmailList.add(adminEmail);
//			emailservice.sendHtmlEmailAsync(trainer.getCompanyName(), addminEmailList, null, null,
//					"Trainer Approval Required - LearnHub", body.toString());
//
//			logger.info("Trainer approval email sent to Admin: " + adminEmail);
//		} catch (Exception e) {
//			logger.error("Error sending trainer approval email: " + e.getMessage());
//		}
//	}

	public ResponseEntity<?> getUserByEmail(String email, String token) {
		try {
			String emailofreq = jwtUtil.getEmailFromToken(token);
			String company = "";
			Optional<Muser> opuser = muserrepositories.findByEmail(emailofreq);
			if (opuser.isPresent()) {
				Muser user = opuser.get();
				company = user.getCompanyName();
				boolean adminIsactive = muserrepositories.getactiveResultByCompanyName("ADMIN", company);
				if (!adminIsactive) {
					return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
				}
			} else {
				return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
			}

			Optional<MuserRequiredDto> userOptional = muserrepositories
					.findDetailandProfileByEmailAndCompany(email, company);
			if (userOptional.isPresent()) {
				MuserRequiredDto user = userOptional.get();
				return ResponseEntity.ok().contentType(MediaType.APPLICATION_JSON).body(user);
			} else {
				return ResponseEntity.notFound().build();
			}
		} catch (Exception e) {
			e.printStackTrace();
			logger.error("", e);
			return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).contentType(MediaType.APPLICATION_JSON)
					.body(null);
		}
	}

	public ResponseEntity<?> getTrainerDetailsByEmail(String email, String token) {
		try {
			String emailofreq = jwtUtil.getEmailFromToken(token);
			String role = jwtUtil.getRoleFromToken(token);
			String company = "";
			Optional<Muser> opuser = muserrepositories.findByEmail(emailofreq);
			if (opuser.isPresent()) {
				Muser user = opuser.get();
				company = user.getCompanyName();
				boolean adminIsactive = muserrepositories.getactiveResultByCompanyName("ADMIN", company);
				if (!adminIsactive) {
					return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
				}
			} else {
				return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
			}

			if ("ADMIN".equals(role)) {
				Optional<MuserProfileDTO> userOptional = muserrepositories
						.findProfileAndCountryCodeAndRoleByEmailAndCompanyName(email, company);
				if (userOptional.isPresent()) {
					MuserProfileDTO user = userOptional.get();
					return ResponseEntity.ok().contentType(MediaType.APPLICATION_JSON).body(user);
				} else {
					return ResponseEntity.status(HttpStatus.NOT_FOUND).body("{\"message\": \"Trainer not found\"}");
				}
			} else {
				return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
			}
		} catch (Exception e) {
			e.printStackTrace();
			logger.error("", e);
			return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
		}
	}

//	public ResponseEntity<?> getStudentDetailsByEmail(String email, String token) {
//		try {
//			String role = jwtUtil.getRoleFromToken(token);
//			String emailofreq = jwtUtil.getEmailFromToken(token);
//			String company = "";
//			Optional<Muser> opuser = muserrepositories.findByEmail(emailofreq);
//			if (opuser.isPresent()) {
//				Muser user = opuser.get();
//				company = user.getCompanyName();
//				boolean adminIsactive = muserrepositories.getactiveResultByCompanyName("ADMIN", company);
//				if (!adminIsactive) {
//					return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
//				}
//			} else {
//				return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
//			}
//
//			if ("ADMIN".equals(role) || "TRAINER".equals(role)) {
//				Optional<MuserProfileDTO> userOptional = muserrepositories
//						.findProfileAndCountryCodeAndRoleByEmailAndCompanyName(email, company);
//				if (userOptional.isPresent()) {
//					MuserProfileDTO user = userOptional.get();
//					return ResponseEntity.ok().contentType(MediaType.APPLICATION_JSON).body(user);
//				} else {
//					return ResponseEntity.status(HttpStatus.NOT_FOUND).body("{\"message\": \"Student not found\"}");
//				}
//			} else {
//				return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
//			}
//		} catch (Exception e) {
//			e.printStackTrace();
//			logger.error("", e);
//			return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
//		}
//	}

	public ResponseEntity<?> getDetailsbyemail(String email, String token) {
		try {
			String emailofreq = jwtUtil.getEmailFromToken(token);
			String company = "";
			Optional<Muser> opuser = muserrepositories.findByEmail(emailofreq);
			if (opuser.isPresent()) {
				Muser user = opuser.get();
				if ("SYSADMIN".equals(user.getRole().getRoleName())) {
					Optional<MuserDto> opadmin = muserrepositories.findDetailsByEmailforSysadmin(email);
					if (opadmin.isPresent()) {
						MuserDto admin = opadmin.get();
						return ResponseEntity.ok().contentType(MediaType.APPLICATION_JSON).body(admin);
					} else {
						return ResponseEntity.status(HttpStatus.NOT_FOUND).body("{\"message\": \"User not found\"}");
					}
				}
				company = user.getCompanyName();
				Optional<MuserDto> opdto = muserrepositories.findDetailsByEmailAndCompany(email, company);
				if (opdto.isPresent()) {
					MuserDto usertosend = opdto.get();
					return ResponseEntity.ok().contentType(MediaType.APPLICATION_JSON).body(usertosend);
				} else {
					return ResponseEntity.status(HttpStatus.NOT_FOUND).body("{\"message\": \"User not found\"}");
				}
			} else {
				return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
			}
		} catch (Exception e) {
			e.printStackTrace();
			logger.error("", e);
			return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
		}
	}

	public ResponseEntity<?> getAdminDetailsBYEmail(String email, String token) {
		try {
			String role = jwtUtil.getRoleFromToken(token);
			if ("SYSADMIN".equals(role)) {
				Optional<Muser> opuser = muserrepositories.findByEmail(email);
				if (opuser.isPresent()) {
					Muser user = opuser.get();
					Optional<MuserProfileDTO> userOptional = muserrepositories
							.findProfileAndCountryCodeAndRoleByEmail(email);
					if (userOptional.isPresent()) {
						MuserProfileDTO userdto = userOptional.get();
						userdto.setLastactive(
								muserrepositories.findLatestLastActiveByCompany(user.getCompanyName()));
						return ResponseEntity.ok().contentType(MediaType.APPLICATION_JSON).body(userdto);
					} else {
						return ResponseEntity.status(HttpStatus.NOT_FOUND).body("{\"message\": \"Admin not found\"}");
					}
				} else {
					return ResponseEntity.status(HttpStatus.NOT_FOUND).body("{\"message\": \"Admin not found\"}");
				}
			} else {
				return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
			}
		} catch (Exception e) {
			e.printStackTrace();
			logger.error("", e);
			return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
		}
	}

	public ResponseEntity<?> sendOTP(String email) {
		try {
			Optional<Muser> existingUser = muserrepositories.findByEmail(email);
			if (existingUser.isPresent()) {
				return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("EMAIL");
			}

			String otp = otpService.generateOtpAndStore(email);

			String emailContent = String.format("<html>" + "<body>" + "<p>Dear User,</p>"
					+ "<p>Welcome to LearnHub! We're excited to have you join our learning community.</p>"
					+ "<p>To complete your registration and verify your email address, please use the following One-Time Password (OTP):</p>"
					+ "<p style='font-size: 24px; font-weight: bold; text-align: center;'>%s</p>"
					+ "<p><strong>Important Notes:</strong><br>" + "• This OTP is valid for 5 minutes only<br>"
					+ "• Please do not share this OTP with anyone<br>"
					+ "• If you didn't request this OTP, please ignore this email</p>"
					+ "<p>Need help? Contact our support team at <a href='mailto:support@meganartech.com'>support@meganartech.com</a></p>"
					+ "<p>Best regards,<br>The LearnHub Team</p>"
					+ "<p><em>Note: This is an auto-generated email. Please do not reply to this email.</em></p>"
					+ "</body>" + "</html>", otp);

			MimeMessage mimeMessage = mailSender.createMimeMessage();
			MimeMessageHelper helper = new MimeMessageHelper(mimeMessage, true, "UTF-8");
			helper.setFrom(otpService.getEmailUsername());
			helper.setTo(email);
			helper.setSubject("LearnHub - Email Verification OTP");
			helper.setText(emailContent, true);
			mailSender.send(mimeMessage);

			return ResponseEntity.ok().body("OTP sent successfully");
		} catch (Exception e) {
			logger.error("Error sending OTP", e);
			return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body("Failed to send OTP");
		}
	}

	public ResponseEntity<?> verifyOTP(String email, String otp) {
		boolean isValid = otpService.validateOtp(email, otp);
		if (!isValid) {
			return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Invalid or expired OTP");
		}
		return ResponseEntity.ok().body("OTP verified successfully");
	}

}