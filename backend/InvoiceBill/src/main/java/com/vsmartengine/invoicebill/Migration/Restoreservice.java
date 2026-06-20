package com.vsmartengine.invoicebill.Migration;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStreamReader;
import java.net.URI;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Arrays;
import java.util.Collections;
import java.util.Comparator;
import java.util.List;
import java.util.stream.Collectors;
import java.util.zip.ZipEntry;
import java.util.zip.ZipInputStream;

import org.apache.commons.io.FileUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import com.vsmartengine.invoicebill.User.SecurityConfiguration.JwtUtil;

@Service
public class Restoreservice {

	@Value("${spring.datasource.username}")
	private String dbUsername;

	@Value("${spring.datasource.url}")
	private String dbUrl;

	@Value("${spring.datasource.password}")
	private String dbPassword;

	@Value("${database.name}")
	private String dbName;

	@Value("${upload.backup:data/backup}")
	private String backupDir;

	@Autowired
	private JwtUtil jwtUtil;

	private static final Logger logger = LoggerFactory.getLogger(Restoreservice.class);

	// ✅ List all .zip backup files from server backup folder
	public ResponseEntity<List<String>> listBackupFiles(String token) {
		try {
			String role = jwtUtil.getRoleFromToken(token);
			if (!("SYSADMIN".equals(role) || "ADMIN".equals(role))) {
				return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(Collections.emptyList());
			}

			File folder = new File(backupDir);
			if (!folder.exists() || !folder.isDirectory()) {
				return ResponseEntity.status(HttpStatus.NOT_FOUND).body(Collections.emptyList());
			}

			String[] files = folder.list((dir, name) -> name.toLowerCase().endsWith(".zip"));
			List<String> backupFiles = files != null ? Arrays.asList(files) : Collections.emptyList();

			// Sort latest first
			backupFiles.sort(Comparator.reverseOrder());

			return ResponseEntity.ok(backupFiles);

		} catch (Exception e) {
			return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
					.body(Collections.singletonList("Error reading backup files: " + e.getMessage()));
		}
	}

	// ✅ Restore from existing backup file on server (by filename)
	public ResponseEntity<?> restoreDatabase(String fileName, String token) {

		String role = jwtUtil.getRoleFromToken(token);
		if (!("SYSADMIN".equals(role) || "ADMIN".equals(role))) {
			return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("❌ Unauthorized");
		}

		try {
			Path backupFilePath = Paths.get(backupDir, fileName);
			if (!Files.exists(backupFilePath) || !Files.isRegularFile(backupFilePath)) {
				return ResponseEntity.status(HttpStatus.BAD_REQUEST)
						.body("❌ Backup file not found: " + fileName);
			}

			File sqlFile = null;

			// Extract only the .sql file from the zip
			try (ZipInputStream zis = new ZipInputStream(new FileInputStream(backupFilePath.toFile()))) {
				ZipEntry entry;
				while ((entry = zis.getNextEntry()) != null) {
					if (!entry.isDirectory() && entry.getName().endsWith(".sql")) {
						sqlFile = new File("backup/sql_restore.sql");
						if (!sqlFile.getParentFile().exists()) {
							sqlFile.getParentFile().mkdirs();
						}
						try (FileOutputStream fos = new FileOutputStream(sqlFile)) {
							byte[] buffer = new byte[1024];
							int len;
							while ((len = zis.read(buffer)) > 0) {
								fos.write(buffer, 0, len);
							}
						}
					}
					zis.closeEntry();
				}
			}

			if (sqlFile == null || !sqlFile.exists()) {
				return ResponseEntity.status(HttpStatus.BAD_REQUEST)
						.body("❌ No .sql file found in backup: " + fileName);
			}

			return executeSqlFile(sqlFile);

		} catch (Exception e) {
			return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
					.body("❌ Error during restore: " + e.getMessage());
		}
	}

	// ✅ Restore from uploaded .zip file
	public ResponseEntity<?> restoreDatabase(MultipartFile backupZipFile, String token) {
		File tempDir = null;
		try {
			String role = jwtUtil.getRoleFromToken(token);
			if (!("SYSADMIN".equals(role) || "ADMIN".equals(role))) {
				return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("❌ Unauthorized");
			}

			logger.info("Restore started...");

			if (backupZipFile.isEmpty()) {
				return ResponseEntity.status(HttpStatus.BAD_REQUEST)
						.body("❌ Backup file is empty! Please upload the correct backup file.");
			}

			// Create temp directory to extract zip
			tempDir = Files.createTempDirectory("db-restore-").toFile();
			File zipFile = new File(tempDir, backupZipFile.getOriginalFilename());
			backupZipFile.transferTo(zipFile);

			File sqlFile = null;

			// Extract only the .sql file from zip
			try (ZipInputStream zis = new ZipInputStream(new FileInputStream(zipFile))) {
				ZipEntry entry;
				while ((entry = zis.getNextEntry()) != null) {
					if (!entry.isDirectory() && entry.getName().endsWith(".sql")) {
						File newFile = new File(tempDir, entry.getName());
						if (!newFile.getParentFile().exists()) {
							newFile.getParentFile().mkdirs();
						}
						try (FileOutputStream fos = new FileOutputStream(newFile)) {
							byte[] buffer = new byte[1024];
							int len;
							while ((len = zis.read(buffer)) > 0) {
								fos.write(buffer, 0, len);
							}
						}
						sqlFile = newFile;
					}
					zis.closeEntry();
				}
			}

			if (sqlFile == null || !sqlFile.exists()) {
				return ResponseEntity.status(HttpStatus.BAD_REQUEST)
						.body("❌ Restore failed: No .sql file found in the uploaded zip archive.");
			}

			return executeSqlFile(sqlFile);

		} catch (IOException e) {
			return ResponseEntity.status(HttpStatus.BAD_REQUEST)
					.body("❌ I/O Error during restore: " + e.getMessage());
		} catch (Exception e) {
			return ResponseEntity.status(HttpStatus.BAD_REQUEST)
					.body("❌ Unexpected error during restore: " + e.getMessage());
		} finally {
			// Clean up temp directory
			if (tempDir != null && tempDir.exists()) {
				try {
					FileUtils.deleteDirectory(tempDir);
				} catch (IOException e) {
					logger.warn("Error deleting temporary directory: " + e.getMessage());
				}
			}
		}
	}

	// ✅ Run pg_restore on the extracted .sql file
	private ResponseEntity<?> executeSqlFile(File backupFile) {
		try {
			logger.info("Starting restore from backup file: {}", backupFile.getName());

			URI uri = new URI(dbUrl.replaceFirst("jdbc:", ""));
			String dbHost = uri.getHost();
			String dbPort = String.valueOf(uri.getPort() == -1 ? 5432 : uri.getPort());
			String dbName = uri.getPath().substring(1);

			ProcessBuilder pb = new ProcessBuilder("pg_restore",
					"--clean",
					"--if-exists",
					"--no-owner",
					"-h", dbHost,
					"-p", dbPort,
					"-U", dbUsername,
					"-d", dbName,
					backupFile.getAbsolutePath());

			pb.environment().put("PGPASSWORD", dbPassword);
			pb.redirectErrorStream(true);

			Process process = pb.start();

			String output;
			try (BufferedReader reader = new BufferedReader(
					new InputStreamReader(process.getInputStream()))) {
				output = reader.lines().collect(Collectors.joining(System.lineSeparator()));
			}

			int exitCode = process.waitFor();
			logger.info("pg_restore exit code: {}", exitCode);

			if (!output.isEmpty()) {
				logger.info("pg_restore output:\n{}", output);
			}

			if (exitCode == 0) {
				return ResponseEntity.ok("✅ Restore completed successfully");
			} else {
				String failureMessage = "❌ Restore failed. Exit code: " + exitCode + ". Details: " + output;
				logger.error(failureMessage);
				return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(failureMessage);
			}

		} catch (Exception e) {
			logger.error("Restore error: {}", e.getMessage(), e);
			return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
					.body("❌ Restore error: " + e.getMessage());
		}
	}
}