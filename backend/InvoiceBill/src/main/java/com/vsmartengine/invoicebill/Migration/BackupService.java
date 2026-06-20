package com.vsmartengine.invoicebill.Migration;

import java.io.BufferedReader;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.net.URI;
import java.net.URISyntaxException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.text.SimpleDateFormat;
import java.util.Arrays;
import java.util.Comparator;
import java.util.Date;
import java.util.zip.ZipEntry;
import java.util.zip.ZipOutputStream;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;

@Service
public class BackupService {

	@Autowired
	private GoogleDriveOAuthService googleDriveOAuthService;

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

	private static final int MAX_BACKUPS = 7;
	private static final String FOLDER_NAME = "InvoiceBill_Backup";

	private static final Logger logger = LoggerFactory.getLogger(BackupService.class);

	// ✅ Ensure backup directory exists
	private void ensureBackupDirectoryExists() {
		File backupDir = new File(backupPath);
		if (!backupDir.exists() && backupDir.mkdirs()) {
			logger.info("Backup directory created: {}", backupPath);
		}
	}

	// ✅ Create DB backup as byte array (used for Drive backup)
	private byte[] createDatabaseBackup() throws Exception {
		URI uri = new URI(dbUrl.replaceFirst("jdbc:", ""));
		String dbHost = uri.getHost();
		int dbPort = uri.getPort() == -1 ? 5432 : uri.getPort();
		String dbName = uri.getPath().substring(1);

		ProcessBuilder pb = new ProcessBuilder("pg_dump",
				"-h", dbHost,
				"-p", String.valueOf(dbPort),
				"-U", dbUsername,
				"-F", "c",
				"--no-owner",
				"--no-acl",
				dbName);

		pb.environment().put("PGPASSWORD", dbPassword);
		pb.redirectErrorStream(true);

		Process process = pb.start();

		ByteArrayOutputStream baos = new ByteArrayOutputStream();
		try (InputStream is = process.getInputStream()) {
			byte[] buffer = new byte[4096];
			int len;
			while ((len = is.read(buffer)) != -1) {
				baos.write(buffer, 0, len);
			}
		}

		int exitCode = process.waitFor();
		if (exitCode != 0) {
			throw new RuntimeException("❌ pg_dump failed: " + baos.toString());
		}

		return baos.toByteArray();
	}

	// ✅ Stream DB backup (used for download — no assets)
	public void writeDatabaseBackupToStream(OutputStream outputStream) throws IOException {
		try (ZipOutputStream zos = new ZipOutputStream(outputStream)) {

			logger.info("Starting database backup and adding to zip...");
			zos.putNextEntry(new ZipEntry("backup_" + timestamp() + ".sql"));
			try (InputStream dbBackupStream = createDatabaseBackupStream()) {
				dbBackupStream.transferTo(zos);
			}
			zos.closeEntry();
			logger.info("Database dump added successfully.");

		} catch (Exception e) {
			logger.error("Error while streaming ZIP", e);
			throw new IOException("Error during backup streaming", e);
		}
	}

	// ✅ Stream pg_dump output directly (for download)
	private InputStream createDatabaseBackupStream() throws IOException {
		try {
			logger.info("Starting pg_dump process for database backup...");
			URI uri = new URI(dbUrl.replaceFirst("jdbc:", ""));
			String dbHost = uri.getHost();
			int dbPort = uri.getPort() == -1 ? 5432 : uri.getPort();

			ProcessBuilder pb = new ProcessBuilder("pg_dump",
					"-h", dbHost,
					"-p", String.valueOf(dbPort),
					"-U", dbUsername,
					"-F", "c",
					"--no-owner",
					"--no-acl",
					dbName);

			pb.environment().put("PGPASSWORD", dbPassword);
			Process process = pb.start();

			// Consume stderr to prevent process from hanging
			new Thread(() -> {
				try (BufferedReader reader = new BufferedReader(
						new InputStreamReader(process.getErrorStream()))) {
					String line;
					while ((line = reader.readLine()) != null) {
						logger.warn("pg_dump STDERR: {}", line);
					}
				} catch (IOException ignored) {
				}
			}).start();

			return process.getInputStream();
		} catch (URISyntaxException e) {
			logger.error("Invalid DB URL: {}", dbUrl, e);
			throw new IOException("Invalid DB URL", e);
		}
	}

	// ✅ Manual: Save backup to Google Drive only (no assets)
	public ResponseEntity<?> backupDatabaseToDriveOnly(String companyName) {
		try {
			byte[] sqlData = createDatabaseBackup();
			String timestamp = timestamp();
			String zipFileName = "full_backup_" + timestamp + ".zip";

			ByteArrayOutputStream zipBaos = new ByteArrayOutputStream();
			try (ZipOutputStream zos = new ZipOutputStream(zipBaos)) {
				zos.putNextEntry(new ZipEntry("backup_" + timestamp + ".sql"));
				zos.write(sqlData);
				zos.closeEntry();
			}

			String driveFileId;
			try (InputStream zipInputStream = new ByteArrayInputStream(zipBaos.toByteArray())) {
				driveFileId = googleDriveOAuthService.uploadFileToDrive(
						zipInputStream, zipFileName, FOLDER_NAME, companyName);
			}

			return ResponseEntity.ok("✅ Backup sent to Google Drive (File ID: " + driveFileId + ")");

		} catch (Exception e) {
			logger.error("❌ Error during Drive backup", e);
			return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
					.body("❌ Error: " + e.getMessage());
		}
	}

	// ✅ Scheduled: backup and upload to Drive (no assets)
	public void performBackupAndUpload(String companyName, int maxFilesToKeep) throws Exception {
		logger.info("Dumping Database...");
		byte[] sqlData = createDatabaseBackup();
		String timestamp = timestamp();
		String zipFileName = "full_backup_" + timestamp + ".zip";

		ByteArrayOutputStream zipBaos = new ByteArrayOutputStream();
		try (ZipOutputStream zos = new ZipOutputStream(zipBaos)) {
			zos.putNextEntry(new ZipEntry("backup_" + timestamp + ".sql"));
			zos.write(sqlData);
			zos.closeEntry();
		}

		try (InputStream zipInputStream = new ByteArrayInputStream(zipBaos.toByteArray())) {
			logger.info("Sending zip to Drive...");
			googleDriveOAuthService.uploadFileToDrivesheduled(
					zipInputStream, zipFileName, FOLDER_NAME, companyName);
		}

		logger.info("Deleting old Drive files...");
		googleDriveOAuthService.deleteOldFilesInDriveFolder(FOLDER_NAME, maxFilesToKeep, companyName);
	}

	// ✅ Save backup zip to local server folder (no assets)
	public void backupDatabaseToFolder() throws Exception {
		ensureBackupDirectoryExists();

		byte[] sqlData = createDatabaseBackup();
		String timestamp = timestamp();

		Path zipFilePath = Paths.get(backupPath, "backup_" + timestamp + ".zip");

		try (FileOutputStream fos = new FileOutputStream(zipFilePath.toFile());
				ZipOutputStream zos = new ZipOutputStream(fos)) {

			ZipEntry sqlEntry = new ZipEntry("backup_" + timestamp + ".sql");
			zos.putNextEntry(sqlEntry);
			zos.write(sqlData);
			zos.closeEntry();
		}

		// Keep only latest MAX_BACKUPS zip files
		cleanupOldBackups(backupPath, ".zip", MAX_BACKUPS);
	}

	// ✅ Delete old backup files beyond max limit
	private void cleanupOldBackups(String directoryPath, String extension, int maxFilesToKeep) {
		File dir = new File(directoryPath);
		File[] files = dir.listFiles((d, name) -> name.endsWith(extension));

		if (files != null && files.length > maxFilesToKeep) {
			Arrays.sort(files, Comparator.comparingLong(File::lastModified));
			for (int i = 0; i < files.length - maxFilesToKeep; i++) {
				if (!files[i].delete()) {
					logger.warn("⚠️ Failed to delete: {}", files[i].getName());
				}
			}
		}
	}

	private String timestamp() {
		return new SimpleDateFormat("yyyy-MM-dd_HH-mm-ss").format(new Date());
	}
}