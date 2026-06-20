//package com.vsmartengine.invoicebill.File;
//
//import java.io.File;
//import java.io.FileInputStream;
//import java.nio.file.Path;
//import java.nio.file.Paths;
//
//import org.springframework.core.io.InputStreamResource;
//import org.springframework.http.HttpHeaders;
//import org.springframework.http.HttpStatus;
//import org.springframework.http.MediaType;
//import org.springframework.http.ResponseEntity;
//import org.springframework.web.bind.annotation.CrossOrigin;
//import org.springframework.web.bind.annotation.GetMapping;
//import org.springframework.web.bind.annotation.RequestMapping;
//import org.springframework.web.bind.annotation.RequestParam;
//import org.springframework.web.bind.annotation.RestController;
//
//@RestController
//@RequestMapping("/api/v2")
//@CrossOrigin
//public class XmlController {
//
//    private final XmlFileService xmlFileService;
//
//    public XmlController(XmlFileService xmlFileService) {
//        this.xmlFileService = xmlFileService;
//    }
//
////    @GetMapping("/download")
////    public ResponseEntity<InputStreamResource> downloadXml() {
////        String fileName = "data.xml";
////        Path tempDir = Paths.get(System.getProperty("java.io.tmpdir"));
////        String filePath = tempDir.resolve(fileName).toString();
////        String successMessage = "File downloaded successfully";
////		String Trainer = "100";
////		String Student = "100";
////		String Validity = "30";
////		String Course = "100";
////		String Type = "FREE";
////		String CompanyName = "Meganar Technologies";
////		String StorageSize = "100";
////		String ProductName = "LearnHub";
////		String Version = "4.0";
////
////        // Generate the XML file
////        xmlFileService.createXmlFile(filePath,Trainer,Student,Validity,Course,Type,CompanyName,StorageSize,
////    			ProductName, Version);
////
////        try {
////            File file = new File(filePath);
////            InputStreamResource resource = new InputStreamResource(new FileInputStream(file));
////
////            HttpHeaders headers = new HttpHeaders();
////            headers.setContentDispositionFormData("attachment", file.getName());
////            headers.setContentType(MediaType.APPLICATION_XML);
////            headers.add("X-Message", "File downloaded successfully"); // Add the message as a custom header
////
////            // Set headers for the file download
////            return ResponseEntity.ok()
////            		.headers(headers)
////                    .contentLength(file.length())
////                    .body(resource);
////        } catch (Exception e) {
////            e.printStackTrace();
////            return ResponseEntity.internalServerError().build();
////        }
////    }
//    
//    @GetMapping("/download")
//    public ResponseEntity<InputStreamResource> downloadXml( 
//    		@RequestParam String companyName,
//            @RequestParam String productName,
//            @RequestParam String storageSize,
//            @RequestParam String noOfCourse,
//            @RequestParam String noOfStudent,
//            @RequestParam String noOfTrainers,
//            @RequestParam String validity,
//            @RequestParam String version,
//            @RequestParam String type
//            ) {
//        String fileName = "data.xml";
//        Path tempDir = Paths.get(System.getProperty("java.io.tmpdir"));
//        String filePath = tempDir.resolve(fileName).toString();
//
//        try {
//            // Parameters for XML file
////        	String  noOfTrainers = "100";
////        	String noOfStudent = "100";
////        	String validity = "30";
////        	String  noOfCourse = "100";
////            String type = "FREE";
////            String  companyName = "Meganar Technologies";
////            String  productName = "LearnHub";
////            String  storageSize = "100";
////            String  version = "4.0";
//
//            // Generate XML file
//            xmlFileService.createXmlFile(filePath, companyName, productName, storageSize, noOfCourse,
//            		noOfStudent, noOfTrainers, validity, version, type);
//
//            File file = new File(filePath);
//            if (!file.exists()) {
//                return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(null);
//            }
//
//            InputStreamResource resource = new InputStreamResource(new FileInputStream(file));
//
//            HttpHeaders headers = new HttpHeaders();
//            headers.setContentDispositionFormData("attachment", fileName);
//            headers.setContentType(MediaType.APPLICATION_XML);
//
//            // Serve the file as a response
//            return ResponseEntity.ok()
//                    .headers(headers)
//                    .contentLength(file.length())
//                    .body(resource);
//        } catch (Exception e) {
//            e.printStackTrace();
//            return ResponseEntity.internalServerError().build();
//        }
//    }
//
//}
