package com.vsmartengine.invoicebill;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.builder.SpringApplicationBuilder;
import org.springframework.boot.web.servlet.support.SpringBootServletInitializer;



@SpringBootApplication
public class InvoiceBillApplication extends SpringBootServletInitializer{

	public static void main(String[] args) {
		SpringApplication.run(InvoiceBillApplication.class, args);
		
	}
	  @Override
	    protected SpringApplicationBuilder configure(SpringApplicationBuilder application) {
	        return application.sources(InvoiceBillApplication.class);
	    }

}
