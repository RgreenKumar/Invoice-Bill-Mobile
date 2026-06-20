//package com.vsmartengine.invoicebill.File;
//
//
//import java.io.File;
//import java.text.SimpleDateFormat;
//import java.time.LocalDate;
//import java.time.ZoneId;
//import java.util.Date;
//
//import org.springframework.beans.factory.annotation.Autowired;
//import org.springframework.stereotype.Service;
//import org.springframework.web.bind.annotation.RequestParam;
//
//import com.vsmartengine.invoicebill.Course.Controller.CourseController;
//
//import io.jsonwebtoken.Jwts;
//import io.jsonwebtoken.SignatureAlgorithm;
//import jakarta.xml.bind.JAXBContext;
//import jakarta.xml.bind.Marshaller;
//
//@Service
//public class XmlFileService {
//
//	@Autowired
//    private DataRepository dataRepository;
//	
//	private final Root root;
//
//    public XmlFileService(Root root) {
//        this.root = root;
//    }
//
//	
////	public void createXmlFile(String filePath,String Trainer,String Student,String Validity,String Course,String Type,String CompanyName,String StorageSize,
////			String ProductName,String Version) {
////        try {
////        	
////        	LocalDate currentDate = LocalDate.now();
////        	 Date date = Date.from(currentDate.atStartOfDay(ZoneId.systemDefault()).toInstant());
////        	 Date date2 = Date.from(currentDate.plusDays(1).atStartOfDay(ZoneId.systemDefault()).toInstant());
////    		SimpleDateFormat formatter = new SimpleDateFormat("ddMMyyyy");
////			String formattedDate = formatter.format(date) + Course + Type + Validity;
////			String formattedDate2 = formatter.format(date2) + Course + Type + Validity;
////			String key = (Jwts.builder().setSubject(formattedDate)
////					.signWith(SignatureAlgorithm.HS256, "yourSecretKeyStringWithAtLeast256BitsLength").compact());
////			String key2 = (Jwts.builder().setSubject(formattedDate2)
////					.signWith(SignatureAlgorithm.HS256, "yourSecretKeyStringWithAtLeast256BitsLength").compact());
////		
////            Data data = new Data();
////            data.setCompanyName(CompanyName);
////            data.setStorageSize(StorageSize);
////            data.setProductName(ProductName);
////            data.setVersion(Version);
////            data.setKey(key);
////            data.setKey2(key2);
////            data.setType(Type);
////            data.setCourse(Course);
////            data.setTrainer(Trainer);
////            data.setStudent(Student);
////            data.setValidity(Validity);
////            root.setData(data);
////
////            // Create JAXB context
////            JAXBContext context = JAXBContext.newInstance(Root.class);
////
////            // Create Marshaller
////            Marshaller marshaller = context.createMarshaller();
////
////            // Format the XML output
////            marshaller.setProperty(Marshaller.JAXB_FORMATTED_OUTPUT, Boolean.TRUE);
////
////            // Marshal Java object to XML file
////            marshaller.marshal(root, new File(filePath));
////            System.out.println("XML file created successfully at: " + filePath);
////        } catch (Exception e) {
////            e.printStackTrace();
////        }
////    }
//   
//    
//    public void createXmlFile(String filePath , String companyName,String productName, String storageSize, String course,
//    		 String student, String trainer, String validity, String version,String type) {
//try {
//LocalDate currentDate = LocalDate.now();
//SimpleDateFormat formatter = new SimpleDateFormat("ddMMyyyy");
//
//String formattedDate = formatter.format(Date.from(currentDate.atStartOfDay(ZoneId.systemDefault()).toInstant())) 
//                  + course + type + validity;
//String formattedDate2 = formatter.format(Date.from(currentDate.plusDays(1)
//                  .atStartOfDay(ZoneId.systemDefault()).toInstant())) 
//                  + course + type + validity;
//
//String key = Jwts.builder()
//  .setSubject(formattedDate)
//  .signWith(SignatureAlgorithm.HS256, "yourSecretKeyStringWithAtLeast256BitsLength")
//  .compact();
//String key2 = Jwts.builder()
//  .setSubject(formattedDate2)
//  .signWith(SignatureAlgorithm.HS256, "yourSecretKeyStringWithAtLeast256BitsLength")
//  .compact();
//
//Data data = new Data(companyName,productName, storageSize , version, key, key2, type, course, trainer, student, validity);
//dataRepository.save(data);
//Root root = new Root(); // Assuming a default constructor exists
//root.setData(data);
//
//JAXBContext context = JAXBContext.newInstance(Root.class);
//Marshaller marshaller = context.createMarshaller();
//marshaller.setProperty(Marshaller.JAXB_FORMATTED_OUTPUT, Boolean.TRUE);
//
//marshaller.marshal(root, new File(filePath));
//System.out.println("XML file created successfully at: " + filePath);
//} catch (Exception e) {
//e.printStackTrace();
//}
//}
//
//
//}
