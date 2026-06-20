package com.vsmartengine.invoicebill.Migration;

import java.util.Optional;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Component;

import com.vsmartengine.invoicebill.Migration.model.BackupScheduleConfig;
import com.vsmartengine.invoicebill.Migration.repo.BackupSheduleConfigRepo;
import com.vsmartengine.invoicebill.Migration.sheduler.BackupSchedulerService;
import com.vsmartengine.invoicebill.User.SecurityConfiguration.JwtUtil;

@Component
public class Backupcomponent {

	private static final Logger logger = LoggerFactory.getLogger(Backupcomponent.class);

	@Autowired
	private BackupService backupService;
	@Autowired
	private JwtUtil jwtUtil;

	@Autowired
	private BackupSheduleConfigRepo configRepo;

	@Value("${upload.backup}")
	private String backupPath;

	@Value("${spring.datasource.username}")
	private String dbUsername;

	@Value("${spring.datasource.url}")
	private String dbUrl;
	@Value("${spring.datasource.password}")
	private String dbPassword;
	@Value("${database.name}")
	private String dbName;
	@Autowired
	private BackupSchedulerService backupSchedulerService;

	public ResponseEntity<?> BackupAndSaveToDrive(String token) {
		try {
			String role = jwtUtil.getRoleFromToken(token);
			String companyName = jwtUtil.getCompanyFromToken(token);
			if ("ADMIN".equals(role) || "SYSADMIN".equals(role)) {
				System.out.println("in backup component");
				return backupService.backupDatabaseToDriveOnly(companyName);
			} else {
				return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("you are not Authorized to access This..");
			}
		} catch (Exception e) {
			logger.error(e.getMessage());
			return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(e.getMessage());
		}
	}

	// save or edit shedule------------------------

	public ResponseEntity<?> saveOrUpdatebackupSchedule(BackupScheduleConfig config, String token) {
		try {
			String companyName = jwtUtil.getCompanyFromToken(token);
			String role = jwtUtil.getRoleFromToken(token);
			if (!"ADMIN".equals(role)) {
				return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
						.body("❌ Only ADMINs can configure backup schedules.");
			}

			Optional<BackupScheduleConfig> existingConfigOpt = configRepo.findByCompanyName(companyName);
			BackupScheduleConfig scheduleToSave;
			String result = "Updated";

			if (existingConfigOpt.isPresent()) {
				scheduleToSave = existingConfigOpt.get();
				scheduleToSave.setScheduleType(config.getScheduleType());
				scheduleToSave.setDayOfWeek(config.getDayOfWeek());
				scheduleToSave.setDayOfMonth(config.getDayOfMonth());
				scheduleToSave.setMaxBackupsToKeep(config.getMaxBackupsToKeep());
				scheduleToSave.setBackupTime(config.getBackupTime());
			} else {
				config.setCompanyName(companyName);
				scheduleToSave = config;
				result = "Saved";
			}

			configRepo.save(scheduleToSave);
			backupSchedulerService.rescheduleBackupForCompany(companyName);
			return ResponseEntity.ok(result);

		} catch (Exception e) {
			e.printStackTrace();
			return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
					.body("❌ Error while saving/updating the schedule.");
		}
	}

	public ResponseEntity<?> getBackupShedule(String token) {
		try {

			String companyName = jwtUtil.getCompanyFromToken(token);
			String role = jwtUtil.getRoleFromToken(token);
			if (!"ADMIN".equals(role)) {
				return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
						.body("❌ Only ADMINs can configure backup schedules.");
			}
			Optional<BackupScheduleConfig> existingConfigOpt = configRepo.findByCompanyName(companyName);
			if (existingConfigOpt.isPresent()) {
				BackupScheduleConfig conf = existingConfigOpt.get();
				return ResponseEntity.ok(conf);
			} else {
				return ResponseEntity.status(HttpStatus.NO_CONTENT).build();
			}
		} catch (Exception e) {
			e.printStackTrace();
			return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
					.body("❌ Internal server error occurred while saving/updating the schedule.");
		}
	}

}
