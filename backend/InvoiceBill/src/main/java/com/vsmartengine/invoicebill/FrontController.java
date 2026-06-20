package com.vsmartengine.invoicebill;

import java.text.SimpleDateFormat;
import java.time.LocalDate;
import java.util.Collections;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.domain.Page;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.servlet.mvc.method.annotation.ResponseBodyEmitter;
import org.springframework.web.servlet.mvc.method.annotation.StreamingResponseBody;

//import com.vsmartengine.invoicebill.AiIntegration.GwenAiService;
//import com.vsmartengine.invoicebill.Course.CourseDetail;
//import com.vsmartengine.invoicebill.Course.CourseDetailDto;
//import com.vsmartengine.invoicebill.Course.Controller.CheckAccess;
//import com.vsmartengine.invoicebill.Course.Controller.CourseController;
//import com.vsmartengine.invoicebill.Course.Controller.CourseControllerSecond;
import com.vsmartengine.invoicebill.Customer.Entity.CustomerDetails;
import com.vsmartengine.invoicebill.Customer.Entity.CustomerDetailsDto;
import com.vsmartengine.invoicebill.Customer.Service.CustomerService;
//import com.vsmartengine.invoicebill.Course.Controller.videolessonController;
//import com.vsmartengine.invoicebill.Course.VideoLessonDTO.SaveModuleTestRequest;
//import com.vsmartengine.invoicebill.Course.certificate.certificateController;
import com.vsmartengine.invoicebill.Email.EmailController;
import com.vsmartengine.invoicebill.Email.Mailkeys;
import com.vsmartengine.invoicebill.Items.Entity.CategoryDTO;
import com.vsmartengine.invoicebill.Items.Entity.UnitDTO;
import com.vsmartengine.invoicebill.Items.Service.AddItemService;
import com.vsmartengine.invoicebill.Items.Service.ItemService;
import com.vsmartengine.invoicebill.Items.Entity.ItemDTO;
import com.vsmartengine.invoicebill.Migration.BackupService;
import com.vsmartengine.invoicebill.Migration.Backupcomponent;
import com.vsmartengine.invoicebill.Migration.OAuthCredentialService;
import com.vsmartengine.invoicebill.Migration.Restoreservice;
import com.vsmartengine.invoicebill.Migration.model.BackupScheduleConfig;
import com.vsmartengine.invoicebill.Migration.model.OAuthCredential;
import com.vsmartengine.invoicebill.MyCompany.Entity.MyCompanyDto;
import com.vsmartengine.invoicebill.MyCompany.Service.MyCompanyService;
import com.vsmartengine.invoicebill.Notification.Controller.NotificationController;
import com.vsmartengine.invoicebill.Payments.Paymentsettings;
import com.vsmartengine.invoicebill.Payments.Paypalsettings;
import com.vsmartengine.invoicebill.Payments.Stripesettings;
import com.vsmartengine.invoicebill.Payments.controller.EnablePaymentsController;
import com.vsmartengine.invoicebill.Payments.controller.PaymentIntegration;
import com.vsmartengine.invoicebill.Payments.controller.PaymentIntegration2;
import com.vsmartengine.invoicebill.Payments.controller.PaymentListController;
import com.vsmartengine.invoicebill.Payments.controller.PaymentSettingsController;
import com.vsmartengine.invoicebill.SaleInvoice.Entity.SaleInvoiceRequestDto;
import com.vsmartengine.invoicebill.SaleInvoice.Service.SaleInvoiceService;
import com.vsmartengine.invoicebill.Settings.Feedback;
import com.vsmartengine.invoicebill.Settings.GeneralSettings;
import com.vsmartengine.invoicebill.Settings.GeneralSettingsDto;
import com.vsmartengine.invoicebill.Settings.GstSettings;
import com.vsmartengine.invoicebill.Settings.GstSettingsDto;
import com.vsmartengine.invoicebill.Settings.ItemSettings;
import com.vsmartengine.invoicebill.Settings.ItemSettingsDto;
import com.vsmartengine.invoicebill.Settings.Service.GeneralSettingsService;
//import com.vsmartengine.invoicebill.Settings.Controller.SettingsController;
import com.vsmartengine.invoicebill.Settings.Service.GstSettingsService;
import com.vsmartengine.invoicebill.Settings.Service.ItemSettingsService;
import com.vsmartengine.invoicebill.User.AddCashierRequestDto;
import com.vsmartengine.invoicebill.User.CashierPermissionDto;
import com.vsmartengine.invoicebill.User.Service.CashierPermissionService;
import com.vsmartengine.invoicebill.User.Muser;
import com.vsmartengine.invoicebill.User.MuserDto;
import com.vsmartengine.invoicebill.User.Controller.AddUsers;
//import com.vsmartengine.invoicebill.User.Controller.AssignCourse;
import com.vsmartengine.invoicebill.User.Controller.AuthenticationController;
import com.vsmartengine.invoicebill.User.Controller.Edituser;
import com.vsmartengine.invoicebill.User.Controller.Listview;
import com.vsmartengine.invoicebill.User.Controller.MserRegistrationController;
import com.vsmartengine.invoicebill.User.LabellingItems.FooterDetails;
import com.vsmartengine.invoicebill.User.LabellingItems.controller.FooterDetailsController;
import com.vsmartengine.invoicebill.User.LabellingItems.controller.LadellingitemController;
import com.vsmartengine.invoicebill.User.SecurityConfiguration.CheckAccessAnnotation;
import com.vsmartengine.invoicebill.User.SecurityConfiguration.JwtUtil;
import com.vsmartengine.invoicebill.User.Usersettings.RoleDisplayController;
import com.vsmartengine.invoicebill.User.Usersettings.Role_display_name;
import com.vsmartengine.invoicebill.User.Repository.MuserRepositories;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.transaction.Transactional;
import jakarta.validation.Valid;

@RestController
@CrossOrigin
public class FrontController {
	@Value("${spring.profiles.active}")
	private String activeProfile;
	@Value("${spring.environment}")
	private String environment;
	@Value("${currency}")
	private String currency;
	@Value("${openrouter.api.key}")
	private String airouterkey;
//	@Autowired
//	private CourseController courseController;

//	@Autowired
//	private CourseControllerSecond coursesec;

//	@Autowired
//	private videolessonController videoless;

//	@Autowired
//	private CheckAccess check;

	@Autowired
	private PaymentIntegration payment;

	@Autowired
	private PaymentIntegration2 payment2;

	@Autowired(required = false)
	private PaymentListController paylist;

	
	@Autowired
	private PaymentSettingsController settings;

	@Autowired
	private EnablePaymentsController enablectrl;
	@Autowired
	private AddUsers adduser;

//	@Autowired
//	private AssignCourse assign;

	@Autowired
	private AuthenticationController authcontrol;

	@Autowired
	private Edituser edit;

	@Autowired
	private Listview listview;

	@Autowired
	private MserRegistrationController muserreg;

//	@Autowired
//	private certificateController certi;

	@Autowired
	private NotificationController noticontroller;

	@Autowired
	private EmailController emailcontroller;

	@Autowired
	private RoleDisplayController displayctrl;

//	@Autowired
//	private SettingsController settingcontroller;

	@Autowired
	private LogManagement logmanagement;

	@Autowired
	private LadellingitemController labelingctrl;

	private static final Logger logger = LoggerFactory.getLogger(FrontController.class);

	@Autowired
	private FooterDetailsController footerctrl;

	@Autowired
	private Backupcomponent backupcomp;
	@Value("${openrouter.api.key}")
	private String openRouterApiKey;

	@Value("${ai.plugin.jar.path:plugins/qwen-integration.jar}")
	private String pluginPath;
	@Autowired
	private JwtUtil jwtutil;

//	@Autowired
//	private GwenAiService gwenservice;

	@Autowired
	private OAuthCredentialService drivecredentialsservice;

	@Autowired
	private Restoreservice restoreservice;
	@Autowired
	private BackupService backupService;
	@Autowired
	private JwtUtil jwtUtil;
	
	@Autowired
	private GeneralSettingsService generalsettingsservice; 
	
	@Autowired
	private  GstSettingsService gstSettingsService;
	
	@Autowired
	private ItemSettingsService itemSettingsService;
	
	
	// Add this with other services at top
	@Autowired
	private  CustomerService customerService;
	
	@Autowired
	private ItemService itemservice;
	
	@Autowired
	private AddItemService addItemService;
	
	@Autowired
	private CashierPermissionService cashierPermissionService;
	
	@Autowired
	private MuserRepositories muserrepositories;
	
	@Autowired
	private SaleInvoiceService saleInvoiceService;
	
	@Autowired
	private MyCompanyService myCompanyService;

//-------------------ACTIVE PROFILE------------------
	@GetMapping("/Active/Environment")
	public Map<String, String> getActiveEnvironment() {
		Map<String, String> response = new HashMap<>();
		response.put("environment", environment);
		response.put("currency", currency);
		return response;
	}

//----------------------------COURSECONTROLLER----------------------------

//	@GetMapping("/course/countcourse")
//	@CheckAccessAnnotation
//	public ResponseEntity<?> countCoursefront(@RequestHeader("Authorization") String token) {
//		return courseController.countCourse(token);
//	}
//
//	@GetMapping("/sysadmin/dashboard")
//	@CheckAccessAnnotation
//	public ResponseEntity<?> sysAdminDashboard(@RequestHeader("Authorization") String token) {
//		return courseController.sysAdminDashboard(token);
//	}
//
//	@GetMapping("/sysadmin/dashboard/{institutationName}")
//	@CheckAccessAnnotation
//	public ResponseEntity<?> sysAdminDashboardByInstitytaion(@PathVariable String institutationName,
//			@RequestHeader("Authorization") String token) {
//		return courseController.sysAdminDashboardByInstitytaion(token, institutationName);
//	}
//
//	@PostMapping("/course/add")
//	@CheckAccessAnnotation
//	public ResponseEntity<?> addCourse(@RequestParam("courseImage") MultipartFile file,
//			@RequestParam("courseName") String courseName, @RequestParam("courseDescription") String description,
//			@RequestParam("courseCategory") String category, @RequestParam("Duration") Long Duration,
//			@RequestParam("Noofseats") Long Noofseats, //@RequestParam("batches") String batches,
//			@RequestParam("courseAmount") Long amount, @RequestHeader("Authorization") String token) {
//		return courseController.addCourse(file, courseName, description, category, Duration, Noofseats, amount,
//				token);
//	}

//	@Transactional
//	@PatchMapping("/course/edit/{courseId}")
//	@CheckAccessAnnotation
//	public ResponseEntity<?> updateCourse(@PathVariable Long courseId,
//			@RequestParam(value = "courseImage", required = false) MultipartFile file,
//			@RequestParam(value = "courseName", required = false) String courseName,
//			@RequestParam(value = "courseDescription", required = false) String description,
//			@RequestParam(value = "courseCategory", required = false) String category,
//			@RequestParam(value = "Noofseats", required = false) Long Noofseats,
//			@RequestParam(value = "Duration", required = false) Long Duration,
//			@RequestParam(value = "courseAmount", required = false) Long amount,
//			@RequestHeader("Authorization") String token) {
//		return courseController.updateCourse(token, courseId, file, courseName, description, category, Noofseats,
//				Duration, amount);
//	}
//
//	@GetMapping("/course/get/{courseId}")
//	@CheckAccessAnnotation
//	public ResponseEntity<CourseDetail> getCourse(@PathVariable Long courseId,
//			@RequestHeader("Authorization") String token) {
//		return courseController.getCourse(courseId, token);
//	}
//
//	@GetMapping("/course/viewAllVps")
//	public ResponseEntity<List<CourseDetailDto>> viewCourseForVps() {
//		return courseController.viewCourseVps();
//	}
//
//	@GetMapping("/course/viewAll")
//	public ResponseEntity<List<CourseDetailDto>> viewCourse(@RequestHeader("Authorization") String token) {
//		if (environment == "VPS") {
//			return courseController.viewCourseVps();
//		} else {
//			return courseController.viewCourse(token);
//		}
//	}
//
//	@GetMapping("/course/getList")
//	@CheckAccessAnnotation
//	public ResponseEntity<?> getAllCourseInfo(@RequestHeader("Authorization") String token) {
//		return courseController.getAllCourseInfo(token);
//	}
//
//	@DeleteMapping("/course/{courseId}")
//	@CheckAccessAnnotation
//	public ResponseEntity<String> deleteCourse(@PathVariable Long courseId,
//			@RequestHeader("Authorization") String token) {
//		return courseController.deleteCourse(courseId, token);
//	}

//	@GetMapping("/course/getLessondetail/{courseId}")
//	@CheckAccessAnnotation
//	public ResponseEntity<?> getLessons(@PathVariable Long courseId, @RequestHeader("Authorization") String token) {
//		return courseController.getLessons(courseId, token);
//	}
//
//	@GetMapping("/course/getLessonlist/{courseId}")
//	@CheckAccessAnnotation
//	public ResponseEntity<?> getLessonList(@PathVariable Long courseId, @RequestHeader("Authorization") String token) {
//		return courseController.getLessonList(courseId, token);
//	}
	////===========================================================================================================
	//ADD customer ===================================================================
	
	// ── ADD PARTY (ADMIN only) ────────────────────────
	@PostMapping("/admin/addParty")
	public ResponseEntity<?> addParty(
	    HttpServletRequest request,
	    @RequestBody CustomerDetailsDto dto,
	    @RequestHeader("Authorization") String token
	) {	
	    CustomerDetails saved = customerService.addParty(dto, token);
	    if (saved == null) {
	        return ResponseEntity.status(403)
	            .body("Access Denied! Only ADMIN can add!");
	    }
	    return ResponseEntity.ok(saved);
	}

	// ── GET SUPPLIERS (ADMIN + CASHIER) ───────────────
	@GetMapping("/getSuppliers")
	public ResponseEntity<?> getSuppliers(
	    HttpServletRequest request,
	    @RequestHeader("Authorization") String token
	) {
	    return ResponseEntity.ok(
	        customerService.getSuppliers(token)
	    );
	}

	// ── GET CUSTOMERS (ADMIN + CASHIER) ───────────────
	@GetMapping("/getCustomers")
	public ResponseEntity<?> getCustomers(
	    HttpServletRequest request,
	    @RequestHeader("Authorization") String token
	) {
	    return ResponseEntity.ok(
	        customerService.getCustomers(token)
	    );
	}

	// ── GET SINGLE PARTY (ADMIN + CASHIER) ────────────
	@GetMapping("/getParty/{id}")
	public ResponseEntity<?> getPartyById(
	    HttpServletRequest request,
	    @PathVariable Long id,
	    @RequestHeader("Authorization") String token
	) {
	    CustomerDetails party = customerService
	        .getPartyById(id, token);
	    if (party == null) {
	        return ResponseEntity.status(404)
	            .body("Party Not Found!");
	    }
	    return ResponseEntity.ok(party);
	}
	
	
	
	@GetMapping("/getPartyTransactions")
	public ResponseEntity<?> getPartyTransactions(
	        @RequestParam String partyName,
	        @RequestHeader("Authorization") String token) {
	    return ResponseEntity.ok(customerService.getPartyTransactions(partyName, token));
	}
	//=============================================================
	
	//============================Add item===============================================
	
	// ADD ITEM (ADMIN + CASHIER)
	@PostMapping("/addItem")
	public ResponseEntity<?> addItem(
	    HttpServletRequest request,
	    @RequestBody ItemDTO dto,
	    @RequestHeader("Authorization") String token
	) {
	    String result = addItemService.addItem(dto, token);
	    switch (result) {
	        case "ACCESS_DENIED":
	            return ResponseEntity.status(403)
	                .body("Access Denied!");
	        case "DUPLICATE_NAME":
	            return ResponseEntity.status(409)
	                .body("Item name already exists!");
	        case "DUPLICATE_CODE":
	            return ResponseEntity.status(409)
	                .body("Item code already exists!");
	        default:
	            return ResponseEntity.ok("Item Saved Successfully!");
	    }
	}

	// SEARCH ITEMS BY NAME (ADMIN + CASHIER)
	@GetMapping("/searchItems")
	public ResponseEntity<?> searchItems(
	    HttpServletRequest request,
	    @RequestParam String name,
	    @RequestHeader("Authorization") String token
	) {
	    return ResponseEntity.ok(addItemService.searchItems(name, token));
	}

	// GENERATE ITEM CODE (ADMIN + CASHIER)
	@GetMapping("/generateItemCode")
	public ResponseEntity<?> generateItemCode(
	    HttpServletRequest request,
	    @RequestHeader("Authorization") String token
	) {
	    return ResponseEntity.ok(addItemService.generateItemCode(token));
	}
	
	
	// ── GET ALL ITEMS ──────────────────────────────
	@GetMapping("/item/viewAll")
	public ResponseEntity<?> viewAllItems(
	    HttpServletRequest request,
	    @RequestHeader("Authorization") String token
	) {
	    return ResponseEntity.ok(
	        itemservice.getItemsByCompany(token)
	    );
	}
	
	//lowstock notification 
	@GetMapping("/getLowStockItems")
	public ResponseEntity<?> getLowStockItems(
	        @RequestHeader("Authorization") String token) {
	    return ResponseEntity.ok(itemservice.getLowStockItems(token));
	}
 //============================update item=====================================
	// UPDATE ITEM (ADMIN + CASHIER)
	@PutMapping("/updateItem/{id}")
	public ResponseEntity<?> updateItem(
	    HttpServletRequest request,
	    @PathVariable Long id,
	    @RequestBody ItemDTO dto,
	    @RequestHeader("Authorization") String token
	) {
	    String result = addItemService.updateItem(id, dto, token);
	    switch (result) {
	        case "ACCESS_DENIED":
	            return ResponseEntity.status(403).body("Access Denied!");
	        case "NOT_FOUND":
	            return ResponseEntity.status(404).body("Item Not Found!");
	        case "DUPLICATE_NAME":
	            return ResponseEntity.status(409).body("Item name already exists!");
	        case "DUPLICATE_CODE":
	            return ResponseEntity.status(409).body("Item code already exists!");
	        default:
	            return ResponseEntity.ok("Item Updated Successfully!");
	    }
	}
	
	@GetMapping("/getItem/{id}")
	public ResponseEntity<?> getItemById(
	    HttpServletRequest request,
	    @PathVariable Long id,
	    @RequestHeader("Authorization") String token
	) {
	    return ResponseEntity.ok(
	        addItemService.getItemById(id, token)
	    );
	}
	
	// ── CATEGORY ──────────────────────────────────────────============================

	// GET ITEMS BY CATEGORY (ADMIN + CASHIER)
	@GetMapping("/getItemsByCategory/{categoryId}")
	public ResponseEntity<?> getItemsByCategory(
	    HttpServletRequest request,
	    @PathVariable Long categoryId,
	    @RequestHeader("Authorization") String token
	) {
	    return ResponseEntity.ok(itemservice.getItemsByCategory(categoryId, token));
	}
	
	// GET ALL CATEGORIES (ADMIN + CASHIER)
	@GetMapping("/getCategories")
	public ResponseEntity<?> getAllCategories(
	    HttpServletRequest request,
	    @RequestHeader("Authorization") String token
	) {
	    return ResponseEntity.ok(
	        itemservice.getAllCategoriesWithCount(token)
	    );
	}

	// ADD CATEGORY (ADMIN only)
	@PostMapping("/admin/addCategory")
	public ResponseEntity<?> addCategory(
	    HttpServletRequest request,
	    @RequestBody CategoryDTO dto,
	    @RequestHeader("Authorization") String token
	) {
	    var saved = itemservice.addCategory(dto, token);
	    if (saved == null) {
	        return ResponseEntity.status(403)
	            .body("Access Denied or Duplicate Category!");
	    }
	    return ResponseEntity.ok(saved);
	}

	// DELETE CATEGORY (ADMIN only)
	@DeleteMapping("/admin/deleteCategory/{id}")
	public ResponseEntity<?> deleteCategory(
	    HttpServletRequest request,
	    @PathVariable Long id,
	    @RequestHeader("Authorization") String token
	) {
	    String result = itemservice.deleteCategory(id, token);

	    switch (result) {
	        case "ACCESS_DENIED":
	            return ResponseEntity.status(403)
	                .body("Access Denied! Only ADMIN can delete!");
	        case "NOT_FOUND":
	            return ResponseEntity.status(404)
	                .body("Category Not Found!");
	        case "IN_USE":
	            return ResponseEntity.status(409)
	                .body("Cannot delete! Category is used by items!");
	        default:
	            return ResponseEntity.ok("Category Deleted Successfully!");
	    }
	}
	
	// UPDATE CATEGORY (ADMIN only)
	@PutMapping("/admin/updateCategory/{id}")
	public ResponseEntity<?> updateCategory(
	    HttpServletRequest request,
	    @PathVariable Long id,
	    @RequestBody CategoryDTO dto,
	    @RequestHeader("Authorization") String token
	) {
	    String result = itemservice.updateCategory(id, dto, token);
	    switch (result) {
	        case "ACCESS_DENIED":
	            return ResponseEntity.status(403)
	                .body("Access Denied! Only ADMIN can edit!");
	        case "NOT_FOUND":
	            return ResponseEntity.status(404)
	                .body("Category Not Found or is a Default Category!");
	        case "DUPLICATE":
	            return ResponseEntity.status(409)
	                .body("Category name already exists!");
	        default:
	            return ResponseEntity.ok("Category Updated Successfully!");
	    }
	}

	// ── UNIT ──────────────────────────────────────────────========================

	@GetMapping("/getItemsByUnit/{unitId}")
	public ResponseEntity<?> getItemsByUnit(
	    HttpServletRequest request,
	    @PathVariable Long unitId,
	    @RequestHeader("Authorization") String token
	) {
	    return ResponseEntity.ok(itemservice.getItemsByUnit(unitId, token));
	}
	
	
	// GET ALL UNITS (ADMIN + CASHIER)
	@GetMapping("/getUnits")
	public ResponseEntity<?> getAllUnits(
	    HttpServletRequest request,
	    @RequestHeader("Authorization") String token
	) {
	    return ResponseEntity.ok(
	        itemservice.getAllUnitsWithCount(token)
	    );
	}

	// ADD UNIT (ADMIN only)
	@PostMapping("/admin/addUnit")
	public ResponseEntity<?> addUnit(
	    HttpServletRequest request,
	    @RequestBody UnitDTO dto,
	    @RequestHeader("Authorization") String token
	) {
	    var saved=itemservice.addUnit(dto, token);
	    if (saved == null) {
	        return ResponseEntity.status(403)
	            .body("Access Denied or Duplicate Unit!");
	    }
	    return ResponseEntity.ok(saved);
	}

	// DELETE UNIT (ADMIN only)
	@DeleteMapping("/admin/deleteUnit/{id}")
	public ResponseEntity<?> deleteUnit(
	    HttpServletRequest request,
	    @PathVariable Long id,
	    @RequestHeader("Authorization") String token
	) {
	    String result = itemservice.deleteUnit(id, token);
	    switch (result) {
        case "ACCESS_DENIED":
            return ResponseEntity.status(403)
                .body("Access Denied! Only ADMIN can delete!");
        case "NOT_FOUND":
            return ResponseEntity.status(404)
                .body("Unit Not Found!");
        case "IN_USE":
            return ResponseEntity.status(409)
                .body("Cannot delete! Unit is used by items!");
        default:
            return ResponseEntity.ok("Unit Deleted Successfully!");
    }
	}
	
	
	// UPDATE UNIT (ADMIN only)
	@PutMapping("/admin/updateUnit/{id}")
	public ResponseEntity<?> updateUnit(
	    HttpServletRequest request,
	    @PathVariable Long id,
	    @RequestBody UnitDTO dto,
	    @RequestHeader("Authorization") String token
	) {
	    String result = itemservice.updateUnit(id, dto, token);
	    switch (result) {
	        case "ACCESS_DENIED":
	            return ResponseEntity.status(403)
	                .body("Access Denied! Only ADMIN can edit!");
	        case "NOT_FOUND":
	            return ResponseEntity.status(404)
	                .body("Unit Not Found or is a Default Unit!");
	        case "DUPLICATE":
	            return ResponseEntity.status(409)
	                .body("Unit name already exists!");
	        default:
	            return ResponseEntity.ok("Unit Updated Successfully!");
	    }
	}
	
	
	
	////taxes=======================================================
	// GET ALL TAXES (ADMIN + CASHIER)
	@GetMapping("/getTaxes")
	public ResponseEntity<?> getAllTax(
	    HttpServletRequest request,
	    @RequestHeader("Authorization") String token
	) {
	    return ResponseEntity.ok(itemservice.getAllTax(token));
	}
	
	
	///dashboard
//	
//	@GetMapping("/dashboard/counts")
//	public ResponseEntity<?> getDashboardCounts(
//	        @RequestHeader("Authorization") String token) {
//	    return ResponseEntity.ok(itemservice.getDashboardCounts(token));
//	}
	
	
//----------------------------COURSE CONTROLLER SECOND-----------------------------------
//	@GetMapping("/dashboard/storage")
//	@CheckAccessAnnotation
//	public ResponseEntity<?> getstorageDetails(@RequestHeader("Authorization") String token) {
//		return coursesec.getstoragedetails(token);
//	}
//
//	@GetMapping("/dashboard/trainerSats")
//	@CheckAccessAnnotation
//	public ResponseEntity<?> getAllTrainerhandlingUsersAndCourses(@RequestHeader("Authorization") String token) {
//		return coursesec.getAllTrainerhandlingUsersAndCourses(token);
//	}
//
//	@GetMapping("/dashboard/StudentSats")
//	@CheckAccessAnnotation
//	public ResponseEntity<?> getAllStudentCourseDetails(@RequestHeader("Authorization") String token) {
//		return coursesec.getAllStudentCourseDetails(token);
//	}

//	@GetMapping("/get/lessonIdBycourseID/{courseId}")
//	@CheckAccessAnnotation
//	public ResponseEntity<?> getLessonIdBycourseID(@PathVariable Long courseId,
//			@RequestHeader("Authorization") String token) {
//		return coursesec.getLessonIdBycourseID(courseId, token);
//	}

//----------------------------videolessonController-------------------------------
//	@GetMapping("/getDocs/{lessonId}")
//	@CheckAccessAnnotation
//	public ResponseEntity<?> getDocsName(@PathVariable Long lessonId, @RequestHeader("Authorization") String token) {
//		return videoless.getDocsName(lessonId, token);
//	}
//
//	@GetMapping("/getmini/{lessonId}/{docId}")
//	@CheckAccessAnnotation
//	public ResponseEntity<?> getMiniatureDetails(@PathVariable Long lessonId, @PathVariable Long docId,
//			@RequestHeader("Authorization") String token) {
//		return videoless.getMiniatureDetails(lessonId, docId, token);
//	}
//
//	@PostMapping("/lessons/save/{courseId}")
//	@CheckAccessAnnotation
//	public ResponseEntity<?> savenote(@RequestParam(value = "thumbnail", required = false) MultipartFile file,
//			@RequestParam("Lessontitle") String Lessontitle,
//			@RequestParam("LessonDescription") String LessonDescription,
//			@RequestParam(value = "videoFile", required = false) MultipartFile videoFile,
//			@RequestParam(value = "fileUrl", required = false) String fileUrl,
//			@RequestParam(value = "documentContent", required = false) List<MultipartFile> documentFiles,
//			@PathVariable Long courseId, @RequestHeader("Authorization") String token) {
//		return videoless.savenote(file, Lessontitle, LessonDescription, videoFile, fileUrl, documentFiles, courseId,
//				token);
//	}
//
//	@PatchMapping("/lessons/edit/{lessonId}")
//	@CheckAccessAnnotation
//	public ResponseEntity<?> EditLessons(@PathVariable Long lessonId,
//			@RequestParam(value = "thumbnail", required = false) MultipartFile file,
//			@RequestParam(required = false) String Lessontitle,
//			@RequestParam(required = false) String LessonDescription,
//			@RequestParam(value = "videoFile", required = false) MultipartFile videoFile,
//			@RequestParam(value = "newDocumentFiles", required = false) List<MultipartFile> newDocumentFiles,
//			@RequestParam(value = "removedDetails", required = false) List<Long> removedDetails,
//			@RequestParam(value = "fileUrl", required = false) String fileUrl,
//			@RequestHeader("Authorization") String token) {
//		return videoless.EditLessons(lessonId, file, Lessontitle, LessonDescription, videoFile, fileUrl,
//				newDocumentFiles, removedDetails, token);
//	}
//
//	@GetMapping("/slide")
//	@CheckAccessAnnotation
//	public ResponseEntity<?> getDocFile(@RequestParam String filePath, @RequestParam int pageNumber,
//			@RequestHeader("Authorization") String token) {
//		return videoless.getDocFile(filePath, pageNumber, token);
//	}
//
//	@GetMapping("/lessons/getvideoByid/{lessId}/{courseId}/{token}")
//	public ResponseEntity<?> getVideoFile(@PathVariable Long lessId, @PathVariable Long courseId,
//			@PathVariable String token, HttpServletRequest request) {
//		System.out.println("getting video");
//		return videoless.getVideoFile(lessId, courseId, token, request);
//	}
//
//	@GetMapping("/lessons/getLessonsByid/{lessonId}")
//	@CheckAccessAnnotation
//	public ResponseEntity<?> getlessonfromId(@PathVariable("lessonId") Long lessonId,
//			@RequestHeader("Authorization") String token) {
//		return videoless.getlessonfromId(lessonId, token);
//	}
//
//	@DeleteMapping("/lessons/delete")
//	@CheckAccessAnnotation
//	public ResponseEntity<?> deleteLessonsByLessonId(@RequestParam("lessonId") Long lessonId,
//			@RequestParam("Lessontitle") String Lessontitle, @RequestHeader("Authorization") String token) {
//		return videoless.deleteLessonsByLessonId(lessonId, Lessontitle, token);
//	}
//
	// -------------------------CheckAccess -------------------------------------
//	@PostMapping("/CheckAccess/match")
//	@CheckAccessAnnotation
//	public ResponseEntity<?> checkAccess(@RequestBody Map<String, Long> requestData,
//			@RequestHeader("Authorization") String token) {
//		return check.checkAccess(requestData, token);
//	}
//
	@PostMapping("/buyCourse/payment")
	@CheckAccessAnnotation
	public ResponseEntity<String> updatePaymentId(HttpServletRequest request,
			@RequestBody Map<String, String> requestData, @RequestHeader("Authorization") String token) {
		if (paylist != null && activeProfile.equals("demo")) {
			return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Payment functionality disabled");
		} else {
			return payment.updatePaymentId(request, requestData, token);
		}
	}

	@PostMapping("/buyCourse/updatePaypalPaymentId")
	@CheckAccessAnnotation
	public ResponseEntity<String> updatePayPalPayment(HttpServletRequest request,
			@RequestBody Map<String, String> requestData, @RequestHeader("Authorization") String token) {
		if (paylist != null && activeProfile.equals("demo")) {
			return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Payment functionality disabled");
		} else {
			return payment2.updatePayPalPayment(request, requestData, token);
		}
	}

	@PostMapping("/buyCourse/updateStripepaymentid")
	@CheckAccessAnnotation
	public ResponseEntity<String> updateStripepaymentid(HttpServletRequest request,
			@RequestBody Map<String, String> requestData, @RequestHeader("Authorization") String token) {
		if (paylist != null && activeProfile.equals("demo")) {
			return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Payment functionality disabled");
		} else {
			return payment.updateStripepaymentid(request, requestData, token);
		}
	}

//-------------------------paymentListcontrller-------------
	@GetMapping("/myPaymentHistory")
	@CheckAccessAnnotation
	public ResponseEntity<?> ViewMypaymentHistry(@RequestHeader("Authorization") String token) {
		if (paylist != null && activeProfile.equals("demo")) {
			return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Payment functionality disabled");
		} else {
			if (paylist != null) {
				return paylist.ViewMypaymentHistry(token);
			}
			return null;
		}
	}

	@GetMapping("/viewAllTransactionHistory")
	@CheckAccessAnnotation
	public ResponseEntity<?> viewTransactionHistory(@RequestHeader("Authorization") String token) {
		if (paylist != null && activeProfile.equals("demo")) {
			return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Payment functionality disabled");
		} else {
			if (paylist != null) {
				return paylist.viewTransactionHistory(token);
			}
			return null;
		}
	}


	// ------------------------SettingsController------------------------
	@GetMapping("/get/stripe/publishkey")
	@CheckAccessAnnotation
	public ResponseEntity<?> getpublishkey(@RequestHeader("Authorization") String token) {
		if (paylist != null && activeProfile.equals("demo")) {
			return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Payment functionality disabled");
		} else {
			return settings.getpublishkey(token);
		}
	}

	@PostMapping("/api/Paymentsettings")
	@CheckAccessAnnotation
	public ResponseEntity<?> SavePaymentDetails(@RequestBody Paymentsettings data,
			@RequestHeader("Authorization") String token) {
		if (paylist != null && activeProfile.equals("demo")) {
			return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Payment functionality disabled");
		} else {
			return settings.SavePaymentDetails(data, token);
		}
	}

	@GetMapping("/api/getPaymentDetails")
	@CheckAccessAnnotation
	public ResponseEntity<?> GetPaymentDetails(@RequestHeader("Authorization") String token) {
		if (paylist != null && activeProfile.equals("demo")) {
			return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Payment functionality disabled");
		} else {
			return settings.GetPaymentDetails(token);
		}
	}

	@PatchMapping("/api/update/{payid}")
	@CheckAccessAnnotation
	public ResponseEntity<?> editpayment(@PathVariable Long payid,
			@RequestParam(value = "razorpay_key", required = false) String razorpay_key,
			@RequestParam(value = "razorpay_secret_key", required = false) String razorpay_secret_key,
			@RequestHeader("Authorization") String token) {
		if (paylist != null && activeProfile.equals("demo")) {
			return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Payment functionality disabled");
		} else {
			return settings.editpayment(payid, razorpay_key, razorpay_secret_key, token);
		}
	}

	@PostMapping("/api/save/stripekeys")
	@CheckAccessAnnotation
	public ResponseEntity<?> SaveStripedetails(@RequestBody Stripesettings stripedata,
			@RequestHeader("Authorization") String token) {
		if (paylist != null && activeProfile.equals("demo")) {
			return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Payment functionality disabled");
		} else {
			return settings.SaveStripedetails(token, stripedata);
		}
	}

	@GetMapping("/api/get/stripekeys")
	@CheckAccessAnnotation
	public ResponseEntity<?> GetstripeKeys(@RequestHeader("Authorization") String token) {
		if (paylist != null && activeProfile.equals("demo")) {
			return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Payment functionality disabled");
		} else {
			return settings.GetstripeKeys(token);
		}
	}

	@PostMapping("/api/save/PaypalKeys")
	@CheckAccessAnnotation
	public ResponseEntity<?> SavepaypalKeys(@RequestBody Paypalsettings paypaldata,
			@RequestHeader("Authorization") String token) {
		if (paylist != null && activeProfile.equals("demo")) {
			return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Payment functionality disabled");
		} else {
			return settings.SavePaypaldetails(token, paypaldata);
		}
	}

	@GetMapping("/api/get/PaypalKeys")
	@CheckAccessAnnotation
	public ResponseEntity<?> GetpaypalKeys(@RequestHeader("Authorization") String token) {
		if (paylist != null && activeProfile.equals("demo")) {
			return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Payment functionality disabled");
		} else {
			return settings.GetpaypalKeys(token);
		}
	}

	@PostMapping("/api/feedback")
	public Feedback feedback(@RequestBody Feedback data) {
		return settings.feedback(data);
	}

	// ======================EnablePaymentCController==========================
	@GetMapping("/get/paytypedetails")
	@CheckAccessAnnotation
	public ResponseEntity<?> getpaytypedetails(@RequestHeader("Authorization") String token) {
		if (paylist != null && activeProfile.equals("demo")) {
			return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Payment functionality disabled");
		} else {
			return enablectrl.getpaytypedetails(token);
		}
	}

	@GetMapping("/get/paytypedetailsforUser")
	@CheckAccessAnnotation
	public ResponseEntity<?> getpaytypedetailsforuser(@RequestHeader("Authorization") String token) {
		if (paylist != null && activeProfile.equals("demo")) {
			return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Payment functionality disabled");
		} else {
			return enablectrl.getpaytypedetailsforuser(token);
		}
	}

	@PostMapping("save/PayTypeDetails")
	@CheckAccessAnnotation
	public Boolean updatePaymenttypes(@RequestParam Boolean isEnabled, @RequestParam String paymentTypeName,
			@RequestHeader("Authorization") String token) {
		if (paylist != null && activeProfile.equals("demo")) {
			return false;
		} else {
			return enablectrl.updatePaymenttypes(isEnabled, paymentTypeName, token);
		}
	}
	//====================Add cashier================================================
	// ===================== ADD CASHIER =====================
	@PostMapping("/admin/addCashier")
	@CheckAccessAnnotation
	public ResponseEntity<?> addCashier(
	        HttpServletRequest request,
	        @RequestBody AddCashierRequestDto cashierRequest,
	        @RequestHeader("Authorization") String token) {
	    return adduser.addCashier(request, cashierRequest, token);
	}

	// ===================== DEACTIVATE CASHIER =====================
	@DeleteMapping("/admin/deactivate/cashier")
	@CheckAccessAnnotation
	public ResponseEntity<?> deactivateCashier(
	        @RequestParam("email") String email,
	        @RequestParam("reason") String reason,
	        @RequestHeader("Authorization") String token) {
	    return adduser.deactivateCashier(reason, email, token);
	}

	// ===================== ACTIVATE CASHIER =====================
	@DeleteMapping("/admin/activate/cashier")
	@CheckAccessAnnotation
	public ResponseEntity<?> activateCashier(
	        @RequestParam("email") String email,
	        @RequestHeader("Authorization") String token) {
	    return adduser.activateCashier(email, token);
	}
	
	@GetMapping("/admin/getCashiers")
	@CheckAccessAnnotation
	public ResponseEntity<?> getCashiers(
	        @RequestHeader("Authorization") String token) {
	    return adduser.getCashiers(token);
	}

	/////=====================cashier permission==============================
	// GET permissions for cashier after login
	@GetMapping("/cashier/permissions/{userId}")
	@CheckAccessAnnotation
	public ResponseEntity<?> getCashierPermissions(
	        @PathVariable Long userId,
	        @RequestHeader("Authorization") String token) {
	    try {
	        String role = jwtUtil.getRoleFromToken(token);
	        // Only CASHIER or ADMIN can fetch permissions
	        if ("CASHIER".equals(role) || "ADMIN".equals(role)) {
	            List<CashierPermissionDto> permissions = 
	                cashierPermissionService.getPermissions(userId);
	            return ResponseEntity.ok().body(permissions);
	        } else {
	            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
	        }
	    } catch (Exception e) {
	        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
	    }
	}

	// UPDATE permissions for cashier — Admin only
	@PutMapping("/admin/cashier/permissions/{userId}")
	@CheckAccessAnnotation
	public ResponseEntity<?> updateCashierPermissions(
	        @PathVariable Long userId,
	        @RequestBody List<CashierPermissionDto> permissions,
	        @RequestHeader("Authorization") String token) {
	    try {
	        String role = jwtUtil.getRoleFromToken(token);
	        if ("ADMIN".equals(role)) {
	            Optional<Muser> userOptional = muserrepositories.findById(userId);
	            if (userOptional.isPresent()) {
	                cashierPermissionService.updatePermissions(
	                    userOptional.get(), permissions
	                );
	                return ResponseEntity.ok()
	                    .body("{\"message\": \"Permissions updated Successfully\"}");
	            } else {
	                return ResponseEntity.notFound().build();
	            }
	        } else {
	            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
	        }
	    } catch (Exception e) {
	        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
	    }
	}
	
	
	@GetMapping("/admin/getCashierByEmail")
	@CheckAccessAnnotation
	public ResponseEntity<?> getCashierByEmail(
	        @RequestParam String email,
	        @RequestHeader("Authorization") String token) {
	    try {
	        String role = jwtUtil.getRoleFromToken(token);
	        if (!"ADMIN".equals(role)) {
	            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
	        }
	        Optional<Muser> user = muserrepositories.findByEmail(email);
	        if (user.isPresent()) {
	            Muser u = user.get();
	            MuserDto dto = new MuserDto(
	                u.getUserId(), u.getUsername(),
	                u.getEmail(), u.getPhone(),
	                u.getIsActive(), u.getDob(),
	                u.getSkills(), u.getCompanyName()
	            );
	            return ResponseEntity.ok(dto);
	        }
	        return ResponseEntity.notFound().build();
	    } catch (Exception e) {
	        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
	    }
	}
	
//=============================billing controller======================
	// ── SAVE BILL ──────────────────────────────────────
	@PostMapping("/saveBill")
	public ResponseEntity<?> saveBill(
	    HttpServletRequest request,
	    @RequestHeader("Authorization") String token,
	    @RequestBody SaleInvoiceRequestDto dto
	) {
	    return ResponseEntity.ok(
	        saleInvoiceService.saveBill(dto, token)
	    );
	}

	// ── GET BILLS BY TYPE ──────────────────────────────
	@GetMapping("/getBills")
	public ResponseEntity<?> getBills(
	    HttpServletRequest request,
	    @RequestHeader("Authorization") String token,
	    @RequestParam String billType
	) {
	    return ResponseEntity.ok(
	        saleInvoiceService.getBills(billType, token)
	    );
	}

	// ── GET SINGLE BILL ────────────────────────────────
	@GetMapping("/getBill/{id}")
	public ResponseEntity<?> getBillById(
	    HttpServletRequest request,
	    @RequestHeader("Authorization") String token,
	    @PathVariable Long id
	) {
	    return ResponseEntity.ok(
	        saleInvoiceService.getBillById(id, token)
	    );
	}

	// ── DELETE BILL ────────────────────────────────────
	@DeleteMapping("/deleteBill/{id}")
	public ResponseEntity<?> deleteBill(
	    HttpServletRequest request,
	    @RequestHeader("Authorization") String token,
	    @PathVariable Long id
	) {
	    return ResponseEntity.ok(
	        saleInvoiceService.deleteBill(id, token)
	    );
	}
	
	@GetMapping("/getBillsFiltered")
	public ResponseEntity<?> getBillsFiltered(
	        @RequestHeader("Authorization") String token,
	        @RequestParam(required = false) String fromDate,
	        @RequestParam(required = false) String toDate,
	        @RequestParam(required = false) String createdBy,
	        @RequestParam(required = false, defaultValue = "SALE,POS") String billTypes) { // ← add this

	    LocalDate from = fromDate != null ? LocalDate.parse(fromDate) : null;
	    LocalDate to   = toDate   != null ? LocalDate.parse(toDate)   : null;
	    
	    List<String> types = List.of(billTypes.split(","));

	    return ResponseEntity.ok(
	        saleInvoiceService.getBillsFiltered(token, from, to, createdBy, types)
	    );
	}
	//=============invoice number=======================
	@GetMapping("/getNextInvoiceNumber")
	public ResponseEntity<?> getNextInvoiceNumber(
	    HttpServletRequest request,
	    @RequestHeader("Authorization") String token
	) {
	    return ResponseEntity.ok(
	        saleInvoiceService.getNextInvoiceNumber(token)
	    );
	}

	// ── SEARCH CUSTOMER ────────────────────────────────
	@GetMapping("/searchCustomer")
	public ResponseEntity<?> searchCustomer(
	    HttpServletRequest request,
	    @RequestHeader("Authorization") String token,
	    @RequestParam String keyword
	) {
	    return ResponseEntity.ok(
	        saleInvoiceService.searchCustomer(keyword, token)
	    );
	}

	// ── SEARCH ITEM ────────────────────────────────────
	@GetMapping("/searchItem")
	public ResponseEntity<?> searchItem(
	    HttpServletRequest request,
	    @RequestHeader("Authorization") String token,
	    @RequestParam String keyword
	) {
	    return ResponseEntity.ok(
	        saleInvoiceService.searchItem(keyword, token)
	    );
	}
	
	// ── GET ITEM TRANSACTIONS ──────────────────────
	@GetMapping("/getItemTransactions")
	public ResponseEntity<?> getItemTransactions(
	    HttpServletRequest request,
	    @RequestHeader("Authorization") String token,
	    @RequestParam String itemName
	) {
	    return ResponseEntity.ok(
	        saleInvoiceService.getItemTransactions(itemName, token)
	    );
	}
	
	//====================My company==============================
	
	// ── GET MY COMPANY ────────────────────────────────────────
	@GetMapping("/admin/getMyCompany")
	public ResponseEntity<?> getMyCompany(
	    HttpServletRequest request,
	    @RequestHeader("Authorization") String token
	) {
	    var result = myCompanyService.getMyCompany(token);
	    if (result == null) {
	        return ResponseEntity.status(404)
	            .body("No company details found!");
	    }
	    return ResponseEntity.ok(result);
	}

	// ── SAVE MY COMPANY ───────────────────────────────────────
	@PostMapping("/admin/saveMyCompany")
	public ResponseEntity<?> saveMyCompany(
	    HttpServletRequest request,
	    @RequestBody MyCompanyDto dto,
	    @RequestHeader("Authorization") String token
	) {
	    var saved = myCompanyService.saveMyCompany(token, dto);
	    if (saved == null) {
	        return ResponseEntity.status(403)
	            .body("Access Denied! Only ADMIN can update!");
	    }
	    return ResponseEntity.ok(saved);
	}
	
//--------------------AddUser---------------------------
	@PostMapping("/admin/addTrainer")
	@CheckAccessAnnotation
	public ResponseEntity<?> addTrainer(HttpServletRequest request, @RequestParam(required = false) String username,
			@RequestParam String psw, @RequestParam String email, @RequestParam(required = false) LocalDate dob,
			@RequestParam String phone, @RequestParam(required = false) String skills,
			@RequestParam(required = false) MultipartFile profile, @RequestParam Boolean isActive,
			@RequestParam(defaultValue = "+91") String countryCode, @RequestHeader("Authorization") String token,
			@RequestParam String otp) {
		return adduser.addTrainer(request, username, psw, email, dob, phone, skills, profile, isActive, countryCode,
				token, otp);
	}

//	@PostMapping("/admin/addStudent")
//	@CheckAccessAnnotation
//	public ResponseEntity<?> addStudent(HttpServletRequest request, @RequestParam(required = false) String username,
//			@RequestParam String psw, @RequestParam String email, @RequestParam(required = false) LocalDate dob,
//			@RequestParam String phone, @RequestParam(required = false) String skills,
//			@RequestParam(required = false) MultipartFile profile, @RequestParam Boolean isActive,
//			@RequestParam(defaultValue = "+91") String countryCode, @RequestHeader("Authorization") String token,
//			@RequestParam String otp) {
//		return adduser.addStudent(request, username, psw, email, dob, phone, skills, profile, isActive, countryCode,
//				token, otp);
//	}
//
//	@DeleteMapping("/admin/deactivate/trainer")
//	@CheckAccessAnnotation
//	public ResponseEntity<?> DeactivateTrainer(@RequestParam("email") String email,
//			@RequestParam("reason") String reason, @RequestHeader("Authorization") String token) {
//		return adduser.DeactivateTrainer(reason, email, token);
//	}
//
//	@DeleteMapping("/admin/Activate/trainer")
//	@CheckAccessAnnotation
//	public ResponseEntity<?> activateTrainer(@RequestParam("email") String email,
//			@RequestHeader("Authorization") String token) {
//		return adduser.activateTrainer(email, token);
//	}
//
//	@DeleteMapping("/admin/deactivate/Student")
//	@CheckAccessAnnotation
//	public ResponseEntity<?> DeactivateStudent(@RequestParam("email") String email,
//			@RequestParam("reason") String reason, @RequestHeader("Authorization") String token) {
//		return adduser.DeactivateStudent(reason, email, token);
//	}
//
//	@DeleteMapping("/admin/Activate/Student")
//	@CheckAccessAnnotation
//	public ResponseEntity<?> activateStudent(@RequestParam("email") String email,
//			@RequestHeader("Authorization") String token) {
//		return adduser.activateStudent(email, token);
//	}

	// --------------------------Authentication Controller------------------

	@PostMapping("/refreshtoken")
	@CheckAccessAnnotation
	public ResponseEntity<?> Refresh(@RequestHeader("Authorization") String token) {
		return authcontrol.refreshtoken(token);
	}

	@PostMapping("/logoutuser")
	@CheckAccessAnnotation
	public ResponseEntity<String> logout(@RequestHeader("Authorization") String token) {
		return authcontrol.logout(token);
	}

	@Transactional
	@PostMapping("/login")
	public ResponseEntity<?> login(@RequestBody Map<String, String> loginRequest) {
		return authcontrol.login(loginRequest);
	}

	@Transactional
	@PostMapping("/forgetpassword")
	public ResponseEntity<?> forgetPassword(@RequestParam("email") String email) {
		return authcontrol.forgetPassword(email);
	}

	@Transactional
	@PostMapping("/resetpassword")
	public ResponseEntity<?> resetPassword(@RequestParam("email") String email,
			@RequestParam("password") String newPassword) {
		return authcontrol.resetPassword(email, newPassword);
	}

//---------------------------EDIT USER------------------------------------
//	@PatchMapping("/Edit/Student/{email}")
//	@CheckAccessAnnotation
//	public ResponseEntity<?> updateStudent(@PathVariable("email") String originalEmail,
//			@RequestParam(name = "username", required = false) String username, @RequestParam("email") String newEmail,
//			@RequestParam(name = "dob", required = false) LocalDate dob, @RequestParam("phone") String phone,
//			@RequestParam(name = "skills", required = false) String skills,
//			@RequestParam(value = "profile", required = false) MultipartFile profile,
//			@RequestParam("isActive") Boolean isActive,
//			@RequestParam(name = "countryCode", defaultValue = "+91") String countryCode,
//			@RequestHeader("Authorization") String token) {
//		return edit.updateStudent(originalEmail, username, newEmail, dob, phone, skills, profile, isActive, countryCode,
//				token);
//	}

//	@PatchMapping("/Edit/Trainer/{email}")
//	@CheckAccessAnnotation
//	public ResponseEntity<?> updateTrainer(@PathVariable("email") String originalEmail,
//			@RequestParam(name = "username", required = false) String username, @RequestParam("email") String newEmail,
//			@RequestParam(name = "dob", required = false) LocalDate dob, @RequestParam("phone") String phone,
//			@RequestParam(name = "skills", required = false) String skills,
//			@RequestParam(value = "profile", required = false) MultipartFile profile,
//			@RequestParam("isActive") Boolean isActive,
//			@RequestParam(name = "countryCode", defaultValue = "+91") String countryCode,
//			@RequestHeader("Authorization") String token) {
//		return edit.updateTrainer(originalEmail, username, newEmail, dob, phone, skills, profile, isActive, countryCode,
//				token);
//	}

	@PatchMapping("/Edit/self")
	@CheckAccessAnnotation
	public ResponseEntity<?> EditProfile(@RequestParam(required = false) String username,
			@RequestParam("email") String newEmail, @RequestParam(name = "dob", required = false) LocalDate dob,
			@RequestParam String phone, @RequestParam(required = false) String skills,
			@RequestParam(required = false) MultipartFile profile, @RequestParam Boolean isActive,
			@RequestHeader("Authorization") String token, @RequestParam(defaultValue = "+91") String countryCode) {
		return edit.EditProfile(username, newEmail, dob, phone, skills, profile, isActive, countryCode, token);
	}

	@GetMapping("/Edit/profiledetails")
	@CheckAccessAnnotation
	public ResponseEntity<?> NameandProfile(@RequestHeader("Authorization") String token) {
		return edit.NameandProfile(token);
	}

	// ----------------------------ListView------------------------

	@GetMapping("/view/users")
	@CheckAccessAnnotation
	public ResponseEntity<?> getUsersByRoleName(@RequestHeader("Authorization") String token,
			@RequestParam(defaultValue = "0") int pageNumber, @RequestParam(defaultValue = "10") int pageSize) {
		return listview.getUsersByRoleName(token, pageNumber, pageSize);
	}

//	@GetMapping("/view/users/{userId}")
//	@CheckAccessAnnotation
//	public ResponseEntity<?> getUserById(@PathVariable Long userId, @RequestHeader("Authorization") String token) {
//		return listview.getUserById(userId, token);
//	}

//	@GetMapping("/view/Trainer")
//	@CheckAccessAnnotation
//	public ResponseEntity<?> getTrainerByRoleName(@RequestHeader("Authorization") String token,
//			@RequestParam(defaultValue = "0") int pageNumber, @RequestParam(defaultValue = "10") int pageSize) {
//		return listview.getTrainerByRoleName(token, pageNumber, pageSize);
//	}

//	@GetMapping("/view/Mystudent")
//	@CheckAccessAnnotation
//	public ResponseEntity<Page<MuserDto>> GetStudentsOfTrainer(@RequestHeader("Authorization") String token,
//			@RequestParam(defaultValue = "0") int pageNumber, @RequestParam(defaultValue = "10") int pageSize) {
//		return listview.GetStudentsOfTrainer(token, pageNumber, pageSize);
//	}

//	@GetMapping("/view/Approvals")
//	@CheckAccessAnnotation
//	public ResponseEntity<Page<MuserDto>> getallApprovals(@RequestHeader("Authorization") String token,
//			@RequestParam(defaultValue = "0") int pageNumber, @RequestParam(defaultValue = "10") int pageSize) {
//		return listview.getallApprovals(token, pageNumber, pageSize);
//	}
//
//	@PostMapping("/Reject/User/{id}")
//	@CheckAccessAnnotation
//	public ResponseEntity<?> RejectUser(@PathVariable Long id, @RequestHeader("Authorization") String token) {
//		return listview.RejectUser(id, token);
//	}
//
//	@PostMapping("/approve/User/{id}")
//	@CheckAccessAnnotation
//	public ResponseEntity<?> approveUser(HttpServletRequest request, @PathVariable Long id,
//			@RequestHeader("Authorization") String token) {
//		return listview.ApproveUser(request, id, token);
//	}

//	@GetMapping("/search/usersbyTrainer")
//	@CheckAccessAnnotation
//	public ResponseEntity<List<String>> getusersSearchbytrainer(@RequestHeader("Authorization") String token,
//			@RequestParam("query") String query) {
//		return listview.SearchEmailTrainer(token, query);
//	}

	@GetMapping("/admin/search")
	@CheckAccessAnnotation
	public ResponseEntity<Page<MuserDto>> searchAdmin(
			@RequestParam(value = "username", required = false) String username,
			@RequestParam(value = "email", required = false) String email,
			@RequestParam(value = "phone", required = false) String phone,
			@RequestParam(value = "dob", required = false) @DateTimeFormat(pattern = "yyyy-MM-dd") LocalDate dob,
			@RequestParam("institutionName") String institutionName,
			@RequestParam(value = "skills", required = false) String skills,
			@RequestParam(value = "page", defaultValue = "0") int page,
			@RequestParam(value = "size", defaultValue = "10") int size, @RequestHeader("Authorization") String token) {
		return listview.searchAdmin(username, email, phone, dob, institutionName, skills, page, size, token);
	}

//	@GetMapping("/trainer/search")
//	@CheckAccessAnnotation
//	public ResponseEntity<Page<MuserDto>> searchTrainer(
//			@RequestParam(value = "username", required = false) String username,
//			@RequestParam(value = "email", required = false) String email,
//			@RequestParam(value = "phone", required = false) String phone,
//			@RequestParam(value = "dob", required = false) @DateTimeFormat(pattern = "yyyy-MM-dd") LocalDate dob,
//			@RequestParam("institutionName") String institutionName,
//			@RequestParam(value = "skills", required = false) String skills,
//			@RequestParam(value = "page", defaultValue = "0") int page,
//			@RequestParam(value = "size", defaultValue = "10") int size, @RequestHeader("Authorization") String token) {
//		return listview.searchTrainer(username, email, phone, dob, institutionName, skills, page, size, token);
//	}
//
//	@GetMapping("/users/search")
//	@CheckAccessAnnotation
//	public ResponseEntity<Page<MuserDto>> searchUsers(
//			@RequestParam(value = "username", required = false) String username,
//			@RequestParam(value = "email", required = false) String email,
//			@RequestParam(value = "phone", required = false) String phone,
//			@RequestParam(value = "dob", required = false) @DateTimeFormat(pattern = "yyyy-MM-dd") LocalDate dob,
//			@RequestParam("institutionName") String institutionName,
//			@RequestParam(value = "skills", required = false) String skills,
//			@RequestParam(value = "page", defaultValue = "0") int page,
//			@RequestParam(value = "size", defaultValue = "10") int size, @RequestHeader("Authorization") String token) {
//		return listview.searchUser(username, email, phone, dob, institutionName, skills, page, size, token);
//	}
//
//	@GetMapping("/Institution/search/Approvals")
//	@CheckAccessAnnotation
//	public ResponseEntity<Page<MuserDto>> searchApproval(
//			@RequestParam(value = "username", required = false) String username,
//			@RequestParam(value = "email", required = false) String email,
//			@RequestParam(value = "phone", required = false) String phone,
//			@RequestParam(value = "dob", required = false) @DateTimeFormat(pattern = "yyyy-MM-dd") LocalDate dob,
//			@RequestParam(value = "skills", required = false) String skills,
//			@RequestParam(value = "role", required = false) String roleName,
//			@RequestParam(value = "page", defaultValue = "0") int page,
//			@RequestParam(value = "size", defaultValue = "10") int size, @RequestHeader("Authorization") String token) {
//		return listview.searchApprovalByAdmin(username, email, phone, dob, skills, roleName, page, size, token);
//	}
//
//	@GetMapping("/Institution/search/Trainer")
//	@CheckAccessAnnotation
//	public ResponseEntity<Page<MuserDto>> searchTrainerByadmin(
//			@RequestParam(value = "username", required = false) String username,
//			@RequestParam(value = "email", required = false) String email,
//			@RequestParam(value = "phone", required = false) String phone,
//			@RequestParam(value = "dob", required = false) @DateTimeFormat(pattern = "yyyy-MM-dd") LocalDate dob,
//			@RequestParam(value = "skills", required = false) String skills,
//			@RequestParam(value = "page", defaultValue = "0") int page,
//			@RequestParam(value = "size", defaultValue = "10") int size, @RequestHeader("Authorization") String token) {
//		return listview.searchTrainerByAdmin(username, email, phone, dob, skills, page, size, token);
//	}
//
//	@GetMapping("/Institution/search/User")
//	@CheckAccessAnnotation
//	public ResponseEntity<Page<MuserDto>> searchUserByadmin(
//			@RequestParam(value = "username", required = false) String username,
//			@RequestParam(value = "email", required = false) String email,
//			@RequestParam(value = "phone", required = false) String phone,
//			@RequestParam(value = "dob", required = false) @DateTimeFormat(pattern = "yyyy-MM-dd") LocalDate dob,
//			@RequestParam(value = "skills", required = false) String skills,
//			@RequestParam(value = "page", defaultValue = "0") int page,
//			@RequestParam(value = "size", defaultValue = "10") int size, @RequestHeader("Authorization") String token) {
//		return listview.searchUserByAdminorTrainer(username, email, phone, dob, skills, page, size, token);
//	}
//
//	@GetMapping("/Institution/search/Mystudent")
//	@CheckAccessAnnotation
//	public ResponseEntity<Page<MuserDto>> searchMystudent(
//			@RequestParam(value = "username", required = false) String username,
//			@RequestParam(value = "email", required = false) String email,
//			@RequestParam(value = "phone", required = false) String phone,
//			@RequestParam(value = "dob", required = false) @DateTimeFormat(pattern = "yyyy-MM-dd") LocalDate dob,
//			@RequestParam(value = "skills", required = false) String skills,
//			@RequestParam(value = "page", defaultValue = "0") int page,
//			@RequestParam(value = "size", defaultValue = "10") int size, @RequestHeader("Authorization") String token) {
//		return listview.searchStudentsOfTrainer(username, email, phone, dob, skills, page, size, token);
//	}

//------------------------MuserRegistrationController------------------------------
//	@PostMapping("/Student/register")
//	public ResponseEntity<?> RegisterStudent(HttpServletRequest request,
//			@RequestParam(required = false) String username, @RequestParam String psw, @RequestParam String email,
//			@RequestParam(required = false) LocalDate dob, @RequestParam String role, @RequestParam String phone,
//			@RequestParam(required = false) String skills, @RequestParam(required = false) MultipartFile profile,
//			@RequestParam Boolean isActive, @RequestParam(defaultValue = "+91") String countryCode,
//			@RequestParam String otp) {
//		return muserreg.RegisterStudent(request, username, psw, email, dob, role, phone, skills, profile, isActive,
//				countryCode, otp);
//	}

	@GetMapping("/count/admin")
	public Long CountAdmin() {
		return muserreg.countadmin();
	}

//	@PostMapping("/Trainer/register")
//	public ResponseEntity<?> RegisterTrainer(HttpServletRequest request,
//			@RequestParam(required = false) String username, @RequestParam String psw, @RequestParam String email,
//			@RequestParam(required = false) LocalDate dob, @RequestParam String role, @RequestParam String phone,
//			@RequestParam(required = false) String skills, @RequestParam(required = false) MultipartFile profile,
//			@RequestParam Boolean isActive, @RequestParam(defaultValue = "+91") String countryCode,
//			@RequestParam String otp) {
//		return muserreg.RegisterTrainer(request, username, psw, email, dob, role, phone, skills, profile, isActive,
//				countryCode, otp);
//	}

	@PostMapping("/admin/register")
	public ResponseEntity<?> registerAdmin(HttpServletRequest request, @RequestParam(required = false) String username,
			@RequestParam String psw, @RequestParam String email, @RequestParam String institutionName,
			@RequestParam(required = false) LocalDate dob, @RequestParam String role, @RequestParam String phone,
			@RequestParam(required = false) String skills, @RequestParam(required = false) MultipartFile profile,
			@RequestParam Boolean isActive, @RequestParam(defaultValue = "+91") String countryCode,
			@RequestParam String otp) {
		return muserreg.registerAdmin(request, username, psw, email, institutionName, dob, role, phone, skills, profile,
				isActive, countryCode, otp);
	}

//	@GetMapping("/student/users/{email}")
//	@CheckAccessAnnotation
//	public ResponseEntity<?> getUserByEmail(@PathVariable String email, @RequestHeader("Authorization") String token) {
//		return muserreg.getUserByEmail(email, token);
//	}
//
//	@GetMapping("/student/admin/getTrainer/{email}")
//	@CheckAccessAnnotation
//	public ResponseEntity<?> getTrainerDetailsByEmail(@PathVariable String email,
//			@RequestHeader("Authorization") String token) {
//		return muserreg.getTrainerDetailsByEmail(email, token);
//	}

//	@GetMapping("/student/admin/getstudent/{email}")
//	@CheckAccessAnnotation
//	public ResponseEntity<?> getStudentDetailsByEmail(@PathVariable String email,
//			@RequestHeader("Authorization") String token) {
//		return muserreg.getStudentDetailsByEmail(email, token);
//	}

	@GetMapping("/details/{email}")
	@CheckAccessAnnotation
	public ResponseEntity<?> getDetailsbyemail(@PathVariable String email,
			@RequestHeader("Authorization") String token) {
		return muserreg.getDetailsbyemail(email, token);
	}

	// --------------------------certificate Contoller----------------------
//
//	@PostMapping("/certificate/add")
//	@CheckAccessAnnotation
//	public ResponseEntity<?> addcertificate(@RequestParam("institutionName") String institutionName,
//			@RequestParam("ownerName") String ownerName, @RequestParam("qualification") String qualification,
//			@RequestParam("address") String address, @RequestParam("authorizedSign") MultipartFile authorizedSign,
//			@RequestHeader("Authorization") String token) {
//		return certi.addcertificate(institutionName, ownerName, qualification, address, authorizedSign, token);
//	}
//
//	@PatchMapping("/certificate/Edit")
//	@CheckAccessAnnotation
//	public ResponseEntity<String> editcertificate(@RequestParam("institutionName") String institutionName,
//			@RequestParam("ownerName") String ownerName, @RequestParam("qualification") String qualification,
//			@RequestParam("address") String address,
//			@RequestParam(value = "authorizedSign", required = false) MultipartFile authorizedSign,
//			@RequestParam("certificateId") Long certificateId, @RequestHeader("Authorization") String token) {
//		return certi.editcertificate(institutionName, ownerName, qualification, address, authorizedSign, certificateId,
//				token);
//	}
//
//	@GetMapping("/certificate/viewAll")
//	@CheckAccessAnnotation
//	public ResponseEntity<?> viewCoursecertificate(@RequestHeader("Authorization") String token) {
//		return certi.viewCoursecertificate(token);
//	}
//
//	@GetMapping("/certificate/getAllCertificate")
//	@CheckAccessAnnotation
//	public ResponseEntity<?> sendAllCertificate(@RequestHeader("Authorization") String token) {
//		return certi.sendAllCertificate(token);
//	}
//
//	@GetMapping("/certificate/getByActivityId/{activityId}")
//	@CheckAccessAnnotation
//	public ResponseEntity<?> getByActivityId(@PathVariable Long activityId,
//			@RequestHeader("Authorization") String token) {
//		return certi.getByActivityId(activityId, token);
//	}

	// -----------------------------------Notification Controller-------------------------------------------------
	@GetMapping("/notifications")
	@CheckAccessAnnotation
	public ResponseEntity<?> GetAllNotification(@RequestHeader("Authorization") String token) {
		return noticontroller.GetAllNotification(token);
	}

	@PostMapping("/MarkAllASRead")
	@CheckAccessAnnotation
	public ResponseEntity<?> MarkALLAsRead(@RequestHeader("Authorization") String token,
			@RequestBody List<Long> notiIds) {
		return noticontroller.MarkALLasRead(token, notiIds);
	}

	@GetMapping("/unreadCount")
	@CheckAccessAnnotation
	public ResponseEntity<?> UreadCount(@RequestHeader("Authorization") String token) {
		return noticontroller.UreadCount(token);
	}

	@GetMapping("/clearAll")
	@CheckAccessAnnotation
	public ResponseEntity<?> ClearAll(@RequestHeader("Authorization") String token) {
		return noticontroller.ClearAll(token);
	}

	@PostMapping("/getImages")
	@CheckAccessAnnotation
	public ResponseEntity<?> GetNotiImage(@RequestHeader("Authorization") String token,
			@RequestBody List<Long> notifyIds) {
		return noticontroller.GetNotiImage(token, notifyIds);
	}

	// -------------------EMAIL CONTROLLER--------------------------

	@GetMapping("/get/mailkeys")
	@CheckAccessAnnotation
	public ResponseEntity<?> getMailkeys(@RequestHeader("Authorization") String token) {
		return emailcontroller.getMailkeys(token);
	}

	@PatchMapping("/Edit/mailkeys")
	@CheckAccessAnnotation
	public ResponseEntity<?> UpdateMailkeys(@RequestHeader("Authorization") String token,
			@RequestBody Mailkeys mailkeys) {
		return emailcontroller.UpdateMailkeys(token, mailkeys);
	}

	@PostMapping("/save/mailkeys")
	@CheckAccessAnnotation
	public ResponseEntity<?> saveMail(@RequestHeader("Authorization") String token, @RequestBody Mailkeys mailkeys) {
		return emailcontroller.saveMail(token, mailkeys);
	}

//-------------------------------------------ROLE DISPLAY CONTROLLER----------------------------------------------------
	@GetMapping("/get/displayName")
	@CheckAccessAnnotation
	public ResponseEntity<?> getdisplayNames(@RequestHeader("Authorization") String token) {
		return displayctrl.getdisplayNames(token);
	}

	@PatchMapping("/edit/displayname")
	@CheckAccessAnnotation
	public ResponseEntity<?> UpdateDisplayName(@RequestHeader("Authorization") String token,
			@RequestBody Role_display_name displayName) {
		return displayctrl.UpdateDisplayName(token, displayName);
	}

	@PostMapping("/post/displayname")
	@CheckAccessAnnotation
	public ResponseEntity<?> postDisplayname(@RequestHeader("Authorization") String token,
			@RequestBody Role_display_name roledisplaynames) {
		return displayctrl.postDisplayname(token, roledisplaynames);
	}

//-------------------------------------SettingsController---------------------------------------------
//	@GetMapping("/settings/viewCourseInLanding")
//	public Boolean isViewCourseinLandingPageEnabled() {
//		try {
//			if (environment.equals("VPS")) {
//				return settingcontroller.isViewCourseinLandingPageEnabled();
//			} else {
//				return null;
//			}
//		} catch (Exception e) {
//			e.printStackTrace();
//			logger.error("", e);
//			return null;
//		}
//	}

//	@GetMapping("/settings/AttendanceThresholdMinutes")
//	public Long getAttendanceThresholdMinutes() {
//		try {
//			if (environment.equals("VPS")) {
//				return settingcontroller.getAttendanceThresholdMinutes();
//			} else {
//				return null;
//			}
//		} catch (Exception e) {
//			e.printStackTrace();
//			logger.error("", e);
//			return null;
//		}
//	}

//	@GetMapping("/settings/ShowSocialLogin")
//	public Boolean isSocialLoginEnabled() {
//		try {
//			if (environment.equals("VPS")) {
//				return settingcontroller.isSocialLoginEnabled();
//			} else {
//				return null;
//			}
//		} catch (Exception e) {
//			e.printStackTrace();
//			logger.error("", e);
//			return null;
//		}
//	}

//	@PostMapping("/settings/viewCourseInLanding")
//	@CheckAccessAnnotation
//	public Boolean updateViewCourseInLandingPage(@RequestBody Boolean isEnabled,
//			@RequestHeader("Authorization") String token) {
//		try {
//			if (environment.equals("VPS")) {
//				return settingcontroller.updateViewCourseInLandingPage(isEnabled, token);
//			} else {
//				return null;
//			}
//		} catch (Exception e) {
//			e.printStackTrace();
//			logger.error("", e);
//			return null;
//		}
//	}

//	@PostMapping("/settings/updateAttendanceThreshold")
//	@CheckAccessAnnotation
//	public Long setAttendanceThresholdMinutes(@RequestBody Long minuites,
//			@RequestHeader("Authorization") String token) {
//		try {
//			if (environment.equals("VPS")) {
//				return settingcontroller.setAttendanceThresholdMinutes(minuites, token);
//			} else {
//				return null;
//			}
//		} catch (Exception e) {
//			e.printStackTrace();
//			logger.error("", e);
//			return null;
//		}
//	}

//	@PostMapping("/settings/ShowSocialLogin")
//	@CheckAccessAnnotation
//	public Boolean updateSocialLoginEnabled(@RequestBody Boolean isEnabled,
//			@RequestHeader("Authorization") String token) {
//		try {
//			if (environment.equals("VPS")) {
//				return settingcontroller.updateSocialLogin(isEnabled, token);
//			} else {
//				return null;
//			}
//		} catch (Exception e) {
//			e.printStackTrace();
//			logger.error("", e);
//			return null;
//		}
//	}
	
	
	
	// ─────────────────── GeneralSettings ───────────────────

	@GetMapping("/settings/general/get")
	public ResponseEntity<GeneralSettings> getGeneralSettings(
	        @RequestHeader("Authorization") String token) {
	    try {
	        if (environment.equals("VPS")) {
	            return ResponseEntity.ok(generalsettingsservice.getSettings(token));
	        } else {
	            return null;
	        }
	    } catch (Exception e) {
	        e.printStackTrace();
	        logger.error("", e);
	        return null;
	    }
	}

	@PostMapping("/settings/general/save")
	public ResponseEntity<GeneralSettings> saveGeneralSettings(
	        @RequestHeader("Authorization") String token,
	        @RequestBody GeneralSettingsDto dto) {
	    try {
	        if (environment.equals("VPS")) {
	            return ResponseEntity.ok(generalsettingsservice.saveSettings(token, dto));
	        } else {
	            return null;
	        }
	    } catch (Exception e) {
	        e.printStackTrace();
	        logger.error("", e);
	        return null;
	    }
	}
	
	//--------------------------GST Settings----------------------------------------
	@GetMapping("/settings/gst/get")
	public ResponseEntity<GstSettings> getGstSettings(
	        @RequestHeader("Authorization") String token) {
	    try {
	        if (environment.equals("VPS")) {
	            return ResponseEntity.ok(gstSettingsService.getSettings(token));
	        } else {
	            return null;
	        }
	    } catch (Exception e) {
	        e.printStackTrace();
	        logger.error("", e);
	        return null;
	    }
	}

	@PostMapping("/settings/gst/save")
	public ResponseEntity<GstSettings> saveGstSettings(
	        @RequestHeader("Authorization") String token,
	        @RequestBody GstSettingsDto dto) {
	    try {
	        if (environment.equals("VPS")) {
	            return ResponseEntity.ok(gstSettingsService.saveSettings(token, dto));
	        } else {
	            return null;
	        }
	    } catch (Exception e) {
	        e.printStackTrace();
	        logger.error("", e);
	        return null;
	    }
	}
	
	//--------------------------Item Settings----------------------------------------

	@GetMapping("/settings/item/get")
	public ResponseEntity<ItemSettings> getItemSettings(
	        @RequestHeader("Authorization") String token) {
	    try {
	        if (environment.equals("VPS")) {
	            return ResponseEntity.ok(itemSettingsService.getSettings(token));
	        } else {
	            return null;
	        }
	    } catch (Exception e) {
	        e.printStackTrace();
	        logger.error("", e);
	        return null;
	    }
	}

	@PostMapping("/settings/item/save")
	public ResponseEntity<ItemSettings> saveItemSettings(
	        @RequestHeader("Authorization") String token,
	        @RequestBody ItemSettingsDto dto) {
	    try {
	        if (environment.equals("VPS")) {
	            return ResponseEntity.ok(itemSettingsService.saveSettings(token, dto));
	        } else {
	            return null;
	        }
	    } catch (Exception e) {
	        e.printStackTrace();
	        logger.error("", e);
	        return null;
	    }
	}
	
	// ===========================================Labelling===========================================
	@GetMapping("/getTheme")
	public Map<String, String> getTheme() {
		return labelingctrl.getPrimaryColor();
	}

	@PostMapping("/save/labellings")
	@CheckAccessAnnotation
	public ResponseEntity<?> SaveLabellingitems(@RequestHeader("Authorization") String token,
			@RequestParam(required = false) String siteUrl, @RequestParam(required = false) String title,
			@RequestParam(required = false) MultipartFile sitelogo,
			@RequestParam(required = false) MultipartFile siteicon,
			@RequestParam(required = false) MultipartFile titleicon) {
		try {
			if (environment.equals("VPS")) {
				return labelingctrl.SaveLabellingitems(token, siteUrl, title, sitelogo, siteicon, titleicon);
			} else {
				return null;
			}
		} catch (Exception e) {
			e.printStackTrace();
			return null;
		}
	}

	@GetMapping("/log/time/{id}")
	public ResponseEntity<?> errorSendindToMail(@PathVariable int id) {
		return logmanagement.logdetails(id);
	}

	@GetMapping("/triggerError")
	public ResponseEntity<String> triggerError() {
		try {
			causeException();
			return ResponseEntity.ok("No error occurred on try");
		} catch (Exception e) {
			logger.error("", e);
			e.printStackTrace();
			return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body("" + e);
		}
	}

	@RequestMapping("favicon.ico")
	public void favicon() {
	}

	private void causeException() throws Exception {
		throw new Exception("This is a simulated exception for testing purposes.");
	}

	@GetMapping("/Get/labellings")
	@CheckAccessAnnotation
	public ResponseEntity<?> getLabelingitems(@RequestHeader("Authorization") String token) {
		try {
			if (environment.equals("VPS")) {
				return labelingctrl.getLabelingitems(token);
			} else {
				return null;
			}
		} catch (Exception e) {
			e.printStackTrace();
			return null;
		}
	}

	@GetMapping("/all/get/labellings")
	public ResponseEntity<?> getLabelingitemsforall() {
		try {
			if (environment.equals("VPS")) {
				return labelingctrl.getLabelingitemsforall();
			} else {
				return null;
			}
		} catch (Exception e) {
			e.printStackTrace();
			return null;
		}
	}

//==============================Footer=======================================

	@PostMapping("/save/FooterDetails")
	@CheckAccessAnnotation
	public ResponseEntity<?> SaveFooterDetails(@RequestHeader("Authorization") String token,
			@RequestBody FooterDetails footerdetails) {
		try {
			if (environment.equals("VPS")) {
				return footerctrl.SaveFooterDetails(token, footerdetails);
			} else {
				return null;
			}
		} catch (Exception e) {
			e.printStackTrace();
			return null;
		}
	}

	@GetMapping("/Get/FooterDetails")
	@CheckAccessAnnotation
	public ResponseEntity<?> Getfooterdetails(@RequestHeader("Authorization") String token) {
		try {
			if (environment.equals("VPS")) {
				return footerctrl.Getfooterdetails(token);
			} else {
				return null;
			}
		} catch (Exception e) {
			e.printStackTrace();
			return null;
		}
	}

	@GetMapping("/all/get/FooterDetails")
	public ResponseEntity<?> getFooteritemsForAll() {
		try {
			if (environment.equals("VPS")) {
				return footerctrl.getFooteritemsForAll();
			} else {
				return null;
			}
		} catch (Exception e) {
			e.printStackTrace();
			return null;
		}
	}

	// ================AssignCourse=======================
//	@GetMapping("/AssignCourse/student/courselist")
//	@CheckAccessAnnotation
//	public ResponseEntity<List<CourseDetailDto>> getCoursesForUser(@RequestHeader("Authorization") String token) {
//		return assign.getCoursesForUser(token);
//	}
//
//	@GetMapping("/AssignCourse/Trainer/courselist")
//	@CheckAccessAnnotation
//	public ResponseEntity<List<CourseDetailDto>> getCoursesForTrainer(@RequestHeader("Authorization") String token) {
//		return assign.getCoursesForTrainer(token);
//	}

	// --------------------------OTP Verification----------------------
	@PostMapping("/auth/send-otp")
	public ResponseEntity<?> sendOTP(@RequestParam String email) {
		return muserreg.sendOTP(email);
	}

	@PostMapping("/auth/verify-otp")
	public ResponseEntity<?> verifyOTP(@RequestParam String email, @RequestParam String otp) {
		return muserreg.verifyOTP(email, otp);
	}

//	@GetMapping(value = "/user/chat", produces = MediaType.TEXT_PLAIN_VALUE)
//	public ResponseBodyEmitter chatwithQwen(@RequestHeader("Authorization") String token, @RequestParam String prompt) {
//		ResponseBodyEmitter emitter = new ResponseBodyEmitter(5 * 60 * 1000L);
//		try {
//			String email = jwtutil.getEmailFromToken(token);
//			gwenservice.callaiPlugin(email, emitter, prompt);
//		} catch (Exception e) {
//			e.printStackTrace();
//			try {
//				emitter.send("An error occurred while calling the AI plugin.");
//			} catch (Exception ex) {
//				ex.printStackTrace();
//			}
//			emitter.completeWithError(e);
//		}
//		return emitter;
//	}

//	@PostMapping("/openRouter/savekeys")
//	@CheckAccessAnnotation
//	public ResponseEntity<?> SaveOrUpdateOpenRouterKeys(@RequestParam String keys,
//			@RequestHeader("Authorization") String token) {
//		return gwenservice.saveOpenRouterKeys(token, keys);
//	}

//	@GetMapping("/openRouter/getkeys")
//	@CheckAccessAnnotation
//	public ResponseEntity<?> SaveOrUpdateOpenRouterKeys(@RequestHeader("Authorization") String token) {
//		return gwenservice.getOpenRouterKeys(token);
//	}

//	@GetMapping("/ai/available")
//	public ResponseEntity<?> isAiAvailable() {
//		boolean available = gwenservice.isAiPluginAvailable();
//		return ResponseEntity.ok(Map.of("available", available));
//	}

	// --------------------------------------BackupComponent-------------------------
	@GetMapping("/backup/download")
	@CheckAccessAnnotation
	public ResponseEntity<StreamingResponseBody> downloadWholeBackup(@RequestHeader("Authorization") String token) {
		String role = jwtUtil.getRoleFromToken(token);
		if (!("ADMIN".equals(role) || "SYSADMIN".equals(role))) {
			return new ResponseEntity<>(HttpStatus.UNAUTHORIZED);
		}
		if (!"VPS".equals(environment)) {
			return new ResponseEntity<>(HttpStatus.SERVICE_UNAVAILABLE);
		}
		String zipFileName = "full_backup_" + new SimpleDateFormat("yyyy-MM-dd_HH-mm-ss").format(new Date()) + ".zip";
		StreamingResponseBody responseBody = outputStream -> {
			try {
				backupService.writeDatabaseBackupToStream(outputStream);
			} catch (Exception e) {
				logger.error("An error occurred during streaming the backup.", e);
				throw e;
			}
		};
		return ResponseEntity.ok()
				.header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"" + zipFileName + "\"")
				.contentType(MediaType.APPLICATION_OCTET_STREAM).body(responseBody);
	}

	@GetMapping("/backup/SaveToDrive")
	@CheckAccessAnnotation
	public ResponseEntity<?> SaveBackupInDrive(@RequestHeader("Authorization") String token) {
		try {
			if (environment.equals("VPS")) {
				return backupcomp.BackupAndSaveToDrive(token);
			} else {
				return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
						.body("Oops...! This Feature is not Available for This Environment");
			}
		} catch (Exception e) {
			e.printStackTrace();
			return null;
		}
	}

	@PostMapping("/backup/shedule/SaveorUpdate")
	@CheckAccessAnnotation
	public ResponseEntity<?> saveOrUpdatebackupSchedule(@RequestBody BackupScheduleConfig config,
			@RequestHeader("Authorization") String token) {
		try {
			if (environment.equals("VPS")) {
				return backupcomp.saveOrUpdatebackupSchedule(config, token);
			} else {
				return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
						.body("Oops...! This Feature is not Available for This Environment");
			}
		} catch (Exception e) {
			e.printStackTrace();
			return null;
		}
	}

	@GetMapping("/backup/shedule/get")
	@CheckAccessAnnotation
	public ResponseEntity<?> getBackupShedule(@RequestHeader("Authorization") String token) {
		try {
			if (environment.equals("VPS")) {
				return backupcomp.getBackupShedule(token);
			} else {
				return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
						.body("Oops...! This Feature is not Available for This Environment");
			}
		} catch (Exception e) {
			e.printStackTrace();
			return null;
		}
	}

//------------------------------OAuthCredentials Service---------------
	@PostMapping("/save/DriveCredentials")
	@CheckAccessAnnotation
	public ResponseEntity<?> storeCredential(HttpServletRequest request, @Valid @RequestBody OAuthCredential credential,
			@RequestHeader("Authorization") String token) {
		try {
			if (environment.equals("VPS")) {
				return drivecredentialsservice.saveOrUpdateCredential(request, credential, token);
			} else {
				return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
						.body("Oops...! This Feature is not Available for This Environment");
			}
		} catch (Exception e) {
			e.printStackTrace();
			return null;
		}
	}

	@GetMapping("/get/DriveCredentials")
	@CheckAccessAnnotation
	public ResponseEntity<?> storeCredential(@RequestHeader("Authorization") String token) {
		try {
			if (environment.equals("VPS")) {
				return drivecredentialsservice.getDecryptedCredentialByInstitution(token);
			} else {
				return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
						.body("Oops...! This Feature is not Available for This Environment");
			}
		} catch (Exception e) {
			e.printStackTrace();
			return null;
		}
	}

	@GetMapping("/driveoauth/callback")
	public ResponseEntity<String> oauthCallback(HttpServletRequest request, @RequestParam("code") String code,
			@RequestParam("state") String institutionName) {
		return drivecredentialsservice.oauthCallback(code, institutionName, request);
	}

	// ----------------------Restore Service-------------------------------------------
	@PostMapping("/zip/restore-database")
	@CheckAccessAnnotation
	public ResponseEntity<?> restoreDatabase(@RequestParam("backupZipFile") MultipartFile backupZipFile,
			@RequestHeader("Authorization") String token) {
		try {
			if (environment.equals("VPS")) {
				return restoreservice.restoreDatabase(backupZipFile, token);
			} else {
				return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
						.body("Oops...! This Feature is not Available for This Environment");
			}
		} catch (Exception e) {
			e.printStackTrace();
			return null;
		}
	}

	@GetMapping("/listbackups")
	@CheckAccessAnnotation
	public ResponseEntity<List<String>> listBackupFiles(@RequestHeader("Authorization") String token) {
		try {
			if (environment.equals("VPS")) {
				return restoreservice.listBackupFiles(token);
			} else {
				return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(Collections.emptyList());
			}
		} catch (Exception e) {
			e.printStackTrace();
			return null;
		}
	}

	@PostMapping("/backups/restore/server")
	@CheckAccessAnnotation
	public ResponseEntity<?> restorebyfilename(@RequestParam("fileName") String filename,
			@RequestHeader("Authorization") String token) {
		try {
			if (environment.equals("VPS")) {
				return restoreservice.restoreDatabase(filename, token);
			} else {
				return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(Collections.emptyList());
			}
		} catch (Exception e) {
			e.printStackTrace();
			return null;
		}
	}
}