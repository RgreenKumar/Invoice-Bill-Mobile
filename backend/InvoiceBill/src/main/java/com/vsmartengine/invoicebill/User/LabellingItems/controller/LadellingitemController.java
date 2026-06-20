package com.vsmartengine.invoicebill.User.LabellingItems.controller;

import java.util.HashMap;
import java.util.Map;
import java.util.Optional;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import com.vsmartengine.invoicebill.User.Muser;
import com.vsmartengine.invoicebill.User.LabellingItems.Labelingitems;
import com.vsmartengine.invoicebill.User.LabellingItems.Repo.LabellingitemsRepo;
import com.vsmartengine.invoicebill.User.Repository.MuserRepositories;
import com.vsmartengine.invoicebill.User.SecurityConfiguration.JwtUtil;

@Service
public class LadellingitemController {
	@Autowired
	private LabellingitemsRepo labellingrepo;
	@Autowired
	private MuserRepositories muserrepositories;
	@Autowired
	private JwtUtil jwtUtil;
	@Value("${theme.primarycolor}")
	private String primaryColor;

	@Value("${theme.lightprimarycolor}")
	private String lightprimarycolor;

	public Map<String, String> getPrimaryColor() {
		Map<String, String> colorMap = new HashMap<>();
		colorMap.put("primaryColor", primaryColor);
		colorMap.put("lightPrimaryColor", lightprimarycolor);
		return colorMap;
	}

	public ResponseEntity<?> SaveLabellingitems(String token, String siteUrl, String title, MultipartFile sitelogo,
			MultipartFile siteicon, MultipartFile titleicon) {
		try {
			String role = jwtUtil.getRoleFromToken(token);
			if (!"ADMIN".equals(role)) {
				return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
			}
			String email = jwtUtil.getEmailFromToken(token);
			Optional<Muser> opreq = muserrepositories.findByEmail(email);
			String company = "";
			if (opreq.isPresent()) {
				Muser requser = opreq.get();
				company = requser.getCompanyName();
				Optional<Labelingitems> label = labellingrepo.FindbyCompany(company);
				if (label.isPresent()) {
					Labelingitems existinglabels = label.get();

					existinglabels.setSiteUrl(siteUrl);
					existinglabels.setTitle(title);

					if (siteicon != null && !siteicon.isEmpty()) {
						existinglabels.setSiteicon(siteicon.getBytes());
					}

					if (sitelogo != null && !sitelogo.isEmpty()) {
						existinglabels.setSitelogo(sitelogo.getBytes());
					}

					if (titleicon != null && !titleicon.isEmpty()) {
						existinglabels.setTitleicon(titleicon.getBytes());
					}

					labellingrepo.save(existinglabels);
					return ResponseEntity.ok("Updated ");
				} else {
					Labelingitems labels = new Labelingitems();
					labels.setSiteUrl(siteUrl);
					labels.setTitle(title);
					// Check if each file is not null before calling getBytes()
					if (siteicon != null && !siteicon.isEmpty()) {
						labels.setSiteicon(siteicon.getBytes());
					}

					if (sitelogo != null && !sitelogo.isEmpty()) {
						labels.setSitelogo(sitelogo.getBytes());
					}

					if (titleicon != null && !titleicon.isEmpty()) {
						labels.setTitleicon(titleicon.getBytes());
					}

					labels.setCompanyName(company);
					labellingrepo.save(labels);

					return ResponseEntity.ok("saved ");
				}
			} else {
				return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
			}
		} catch (Exception e) {
			e.printStackTrace();
			return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
		}
	}

	public ResponseEntity<?> getLabelingitems(String token) {
		try {
			String role = jwtUtil.getRoleFromToken(token);
			if (!"ADMIN".equals(role)) {
				return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
			}
			String email = jwtUtil.getEmailFromToken(token);
			Optional<Muser> opreq = muserrepositories.findByEmail(email);
			String company = "";
			if (opreq.isPresent()) {
				Muser requser = opreq.get();
				company = requser.getCompanyName();
				Optional<Labelingitems> labels = labellingrepo.FindbyCompany(company);
				if (labels.isPresent()) {
					return ResponseEntity.ok(labels);
				} else {
					return ResponseEntity.status(HttpStatus.NO_CONTENT).build();
				}

			} else {
				return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
			}
		} catch (Exception e) {
			e.printStackTrace();
			return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
		}
	}

	public ResponseEntity<?> getLabelingitemsforall() {
		try {
			String companyname = muserrepositories.getCompany("ADMIN");
			if (companyname == null || companyname.isEmpty()) {
				return ResponseEntity.status(HttpStatus.NO_CONTENT).build();
			} else {
				Optional<Labelingitems> labels = labellingrepo.FindbyCompany(companyname);
				if (labels.isPresent()) {
					return ResponseEntity.ok(labels);
				} else {
					return ResponseEntity.status(HttpStatus.NO_CONTENT).build();
				}
			}
		} catch (Exception e) {
			e.printStackTrace();
			return ResponseEntity.internalServerError().build();
		}

	}
}
