package com.vsmartengine.invoicebill.Email;

import java.util.List;

import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter@Setter@NoArgsConstructor
public class EmailRequest {

	  private List<String> to;
	    private List<String> cc;
	    private List<String> bcc;
	    private String subject;
	    private String body;
		@Override
		public String toString() {
			return "EmailRequest [to=" + to + ", cc=" + cc + ", bcc=" + bcc + ", subject=" + subject + ", body=" + body
					+ "]";
		}
}
