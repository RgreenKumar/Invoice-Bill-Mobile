package com.vsmartengine.invoicebill;

import java.io.InputStream;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.Arrays;
import java.util.List;

import javax.annotation.PostConstruct;
import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.NodeList;

import com.vsmartengine.invoicebill.User.Muser;
import com.vsmartengine.invoicebill.User.MuserRoles;
import com.vsmartengine.invoicebill.User.Repository.MuserRepositories;
import com.vsmartengine.invoicebill.User.Repository.MuserRoleRepository;
import com.vsmartengine.invoicebill.Items.Entity.Category;
import com.vsmartengine.invoicebill.Items.Entity.Unit;
import com.vsmartengine.invoicebill.Items.Entity.Tax;
import com.vsmartengine.invoicebill.Items.Repository.CategoryRepository;
import com.vsmartengine.invoicebill.Items.Repository.UnitRepository;
import com.vsmartengine.invoicebill.Items.Repository.TaxRepository;

@Service
public class DataLoaderService {

    private static final Logger logger = LoggerFactory.getLogger(DataLoaderService.class);

    // existing repositories
    @Autowired
    private MuserRoleRepository muserRoleRepository;
    @Autowired
    private MuserRepositories muserrepositories;

    // new repositories
    @Autowired
    private CategoryRepository categoryRepository;
    @Autowired
    private UnitRepository unitRepository;
    @Autowired
    private TaxRepository taxRepository;

    // default company name
    private static final String DEFAULT_COMPANY = "DEFAULT";

    @PostConstruct
    @Transactional
    public void init() {
        try {
            loadRoles();
            loadUsers();
            loadDefaultCategories();
            loadDefaultUnits();
            loadDefaultTaxes();
        } catch (Exception e) {
            e.printStackTrace();
            logger.error("", e);
        }
    }

    private void loadRoles() {
        try {
            InputStream is = getClass().getResourceAsStream("/roles.xml");

            DocumentBuilderFactory factory = DocumentBuilderFactory.newInstance();
            DocumentBuilder builder = factory.newDocumentBuilder();
            Document doc = builder.parse(is);

            NodeList roleNodes = doc.getElementsByTagName("role");
            for (int i = 0; i < roleNodes.getLength(); i++) {
                Element roleElement = (Element) roleNodes.item(i);
                String roleName = roleElement.getElementsByTagName("roleName").item(0).getTextContent();
                boolean isActive = Boolean
                        .parseBoolean(roleElement.getElementsByTagName("isActive").item(0).getTextContent());

                MuserRoles role = new MuserRoles();
                role.setRoleName(roleName);
                role.setIsActive(isActive);

                if (muserRoleRepository.findByRoleName(roleName).isEmpty()) {
                    muserRoleRepository.save(role);
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
            logger.error("", e);
        }
    }

    private void loadUsers() {
        try {
            InputStream is = getClass().getResourceAsStream("/users.xml");

            DocumentBuilderFactory factory = DocumentBuilderFactory.newInstance();
            DocumentBuilder builder = factory.newDocumentBuilder();
            Document doc = builder.parse(is);

            NodeList userNodes = doc.getElementsByTagName("user");

            for (int i = 0; i < userNodes.getLength(); i++) {
                Element userElement = (Element) userNodes.item(i);
                String username = userElement.getElementsByTagName("username").item(0).getTextContent();
                String password = userElement.getElementsByTagName("psw").item(0).getTextContent();
                String email = userElement.getElementsByTagName("email").item(0).getTextContent();
                LocalDate dob = LocalDate.parse(userElement.getElementsByTagName("dob").item(0).getTextContent());
                String phone = userElement.getElementsByTagName("phone").item(0).getTextContent();
                String skills = userElement.getElementsByTagName("skills").item(0).getTextContent();
                String countryCode = userElement.getElementsByTagName("countryCode").item(0).getTextContent();
                String roleName = userElement.getElementsByTagName("role").item(0).getTextContent();
                String companyName = userElement.getElementsByTagName("companyName").item(0).getTextContent();

                if (muserrepositories.findByEmail(email).isEmpty()) {
                    MuserRoles role = muserRoleRepository.findByRoleName(roleName)
                            .orElseThrow(() -> new RuntimeException("Role not found: " + roleName));

                    Muser newUser = new Muser();
                    newUser.setUsername(username);
                    newUser.setPsw(password);
                    newUser.setEmail(email);
                    newUser.setDob(dob);
                    newUser.setPhone(phone);
                    newUser.setSkills(skills);
                    newUser.setCountryCode(countryCode);
                    newUser.setCompanyName(companyName);
                    newUser.setRole(role);
                    newUser.setIsActive(true);
                    muserrepositories.save(newUser);
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
            logger.error("", e);
        }
    }

    // ── DEFAULT CATEGORIES ──
    private void loadDefaultCategories() {
        try {
            // check if already loaded
            if (!categoryRepository.findByCompany(DEFAULT_COMPANY).isEmpty()) {
                return;
            }

            List<String> defaultCategories = Arrays.asList(
                "Groceries",
                "Food Grains",
                "Oils",
                "Beverages",
                "Dairy Products",
                "Snacks",
                "Personal Care"
            );

            for (String name : defaultCategories) {
                Category category = new Category();
                category.setName(name);
                category.setCompany(DEFAULT_COMPANY);
                categoryRepository.save(category);
                logger.info("Category saved: {}", name);
            }
        } catch (Exception e) {
            e.printStackTrace();
            logger.error("", e);
        }
    }

    // ── DEFAULT UNITS ──
    private void loadDefaultUnits() {
        try {
            // check if already loaded
            if (!unitRepository.findByCompany(DEFAULT_COMPANY).isEmpty()) {
                return;
            }

            List<Object[]> defaultUnits = Arrays.asList(
            		// Weight
            	    new Object[]{"Kilogram",  "kg",   1000, "Gram"},
            	    new Object[]{"Gram",      "g",    1000, "Milligram"},
            	    new Object[]{"Quintal",   "qtl",  100,  "Kilogram"},
            	    new Object[]{"Ton",       "ton",  1000, "Kilogram"},

            	    // Volume
            	    new Object[]{"Litre",     "L",    1000, "ML"},
            	    new Object[]{"Millilitre","ml",   1,    "ML"},

            	    // Length
            	    new Object[]{"Meter",     "m",    100,  "CM"},
            	    new Object[]{"Centimeter","cm",   10,   "MM"},
            	    new Object[]{"Foot",      "ft",   12,   "Inch"},

            	    // Count
            	    new Object[]{"Piece",     "pcs",  1,    "Piece"},
            	    new Object[]{"Dozen",     "dz",   12,   "Piece"},
            	    new Object[]{"Box",       "box",  1,    "Box"},
            	    new Object[]{"Pack",      "pack", 1,    "Pack"},
            	    new Object[]{"Bag",       "bag",  1,    "Bag"},
            	    new Object[]{"Bundle",    "bndl", 1,    "Bundle"},
            	    new Object[]{"Bottle",    "btl",  1,    "Bottle"},
            	    new Object[]{"Tin",       "tin",  1,    "Tin"},
            	    new Object[]{"Carton",    "ctn",  1,    "Carton"},
            	    new Object[]{"Roll",      "roll", 1,    "Roll"}

            );

            for (Object[] u : defaultUnits) {
                Unit unit = new Unit();
                unit.setName((String)  u[0]);
                unit.setSymbol((String) u[1]);
                unit.setConversionValue((Integer) u[2]);
                unit.setConversionUnit((String) u[3]);
                unit.setCompany(DEFAULT_COMPANY);
                unitRepository.save(unit);
                logger.info("Unit saved: {}", u[0]);
            }
        } catch (Exception e) {
            e.printStackTrace();
            logger.error("", e);
        }
    }

    // ── DEFAULT TAXES ──
    private void loadDefaultTaxes() {
        try {
            // check if already loaded
            if (!taxRepository.findByCompany(DEFAULT_COMPANY).isEmpty()) {
                return;
            }

            List<Object[]> defaultTaxes = Arrays.asList(
            	    new Object[]{"GST 0%",  new BigDecimal("0.00"),  "percentage"},
            	    new Object[]{"GST 5%",  new BigDecimal("5.00"),  "percentage"},
            	    new Object[]{"GST 12%", new BigDecimal("12.00"), "percentage"},
            	    new Object[]{"GST 18%", new BigDecimal("18.00"), "percentage"},
            	    new Object[]{"GST 28%", new BigDecimal("28.00"), "percentage"}
            	);

            for (Object[] t : defaultTaxes) {
                Tax tax = new Tax();
                tax.setName((String) t[0]);
                tax.setRate((BigDecimal) t[1]);
                tax.setType((String) t[2]);
                tax.setCompany(DEFAULT_COMPANY);
                taxRepository.save(tax);
                logger.info("Tax saved: {}", t[0]);
            }
        } catch (Exception e) {
            e.printStackTrace();
            logger.error("", e);
        }
    }

//	private void loadSocialLoginKeys() {
//		try {
//			if (SocialKeysRepo.checkIfSysAdminExists()) {
//				return;
//			}
//			InputStream is = getClass().getResourceAsStream("/social_login_keys.xml");
//			DocumentBuilderFactory factory = DocumentBuilderFactory.newInstance();
//			DocumentBuilder builder = factory.newDocumentBuilder();
//			Document doc = builder.parse(is);
//
//			NodeList rootNodes = doc.getElementsByTagName("Socialkeys");
//			for (int i = 0; i < rootNodes.getLength(); i++) {
//				Element SocialLogin = (Element) rootNodes.item(i);
//				String provider = SocialLogin.getElementsByTagName("provider").item(0).getTextContent();
//				String institutionName = SocialLogin.getElementsByTagName("institutionName").item(0).getTextContent();
//				String clientid = SocialLogin.getElementsByTagName("clientid").item(0).getTextContent();
//				String clientSecret = SocialLogin.getElementsByTagName("clientSecret").item(0).getTextContent();
//				String RedirectUrl = SocialLogin.getElementsByTagName("RedirectUrl").item(0).getTextContent();
//
//				SocialLoginKeys keys = new SocialLoginKeys();
//				keys.setProvider(provider);
//				keys.setInstitutionName(institutionName);
//				keys.setClientid(clientid);
//				keys.setClientSecret(clientSecret);
//				keys.setRedirectUrl(RedirectUrl);
//				SocialKeysRepo.save(keys);
//			}
//		} catch (Exception e) {
//			e.printStackTrace();
//			logger.error("", e);
//			;
//		}
//	}

}
