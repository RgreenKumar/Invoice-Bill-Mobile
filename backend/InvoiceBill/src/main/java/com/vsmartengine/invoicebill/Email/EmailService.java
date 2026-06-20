package com.vsmartengine.invoicebill.Email;

import java.util.List;
import java.util.Optional;
import java.util.Properties;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.JavaMailSenderImpl;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;

import jakarta.mail.MessagingException;
import jakarta.mail.internet.MimeMessage;

@Service
public class EmailService {

	  
	  @Autowired
	  private MailkeysRepo mailkeyrepo;
	  @Value("${spring.mail.host}")
	    private String defaultHost;

	    @Value("${spring.mail.port}")
	    private int defaultPort;

	    @Value("${spring.mail.username}")
	    private String defaultUsername;

	    @Value("${spring.mail.password}")
	    private String defaultPassword;
	  
	  	  @Async // This makes the method run asynchronously
	    public void sendHtmlEmailAsync(String institutionName, List<String> to, List<String> cc, List<String> bcc, String subject, String body) throws MessagingException {
	     
	        JavaMailSender mailSender = getJavaMailSender(institutionName);
	        MimeMessage mimeMessage = mailSender.createMimeMessage();
	        MimeMessageHelper helper = new MimeMessageHelper(mimeMessage, true, "UTF-8");
	        String from = this.getfrom(institutionName);
	        helper.setFrom(from);
	        if (to != null && !to.isEmpty()) {
	            helper.setTo(to.toArray(new String[0]));
	        }
	        if (cc != null && !cc.isEmpty()) {
	            helper.setCc(cc.toArray(new String[0]));
	        }
	        if (bcc != null && !bcc.isEmpty()) {
	            helper.setBcc(bcc.toArray(new String[0]));
	        }
	        helper.setSubject(subject);
	        helper.setText(body, true);  

	        mailSender.send(mimeMessage);
	        System.out.println("Sent email to: " + to); 
	    }
	  public String getfrom(String institution) {
		  Optional<Mailkeys> opkeys = mailkeyrepo.FindMailkeyByCompany(institution);
		  if(opkeys.isPresent()) {
			  Mailkeys keys =opkeys.get();
			  return keys.getEmailid();
		  } else {
			    return defaultUsername;   
			    }
	  }
	  
	  public JavaMailSender getJavaMailSender(String institution) {
	        Optional<Mailkeys> opkeys = mailkeyrepo.FindMailkeyByCompany(institution);
	        JavaMailSenderImpl mailSender = new JavaMailSenderImpl();

	        if (opkeys.isPresent()) {
	            Mailkeys keys = opkeys.get();
	            mailSender.setHost(keys.getHostname());
	            mailSender.setPort(Integer.parseInt(keys.getPort()));
	            mailSender.setUsername(keys.getEmailid());
	            mailSender.setPassword(keys.getPassword());
	        } else {
	            // ✅ Fallback to default application.properties values
	            mailSender.setHost(defaultHost);
	            mailSender.setPort(defaultPort);
	            mailSender.setUsername(defaultUsername);
	            mailSender.setPassword(defaultPassword);
	        }

	        // ✅ Common mail properties (TLS, SMTP authentication)
	        Properties props = mailSender.getJavaMailProperties();
	        props.put("mail.transport.protocol", "smtp");
	        props.put("mail.smtp.auth", "true");
	        props.put("mail.smtp.starttls.enable", "true");
	        props.put("mail.smtp.ssl.trust", "*");        
	        props.put("mail.debug", "true"); // Optional, set to true for debugging

	        return mailSender;
	    }
}
