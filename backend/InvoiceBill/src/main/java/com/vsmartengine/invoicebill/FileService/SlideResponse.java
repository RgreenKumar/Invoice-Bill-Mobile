package com.vsmartengine.invoicebill.FileService;

import lombok.Setter;
@Setter
public class SlideResponse {
    private String image; // Base64 encoded image
    private int totalSlides;

    public SlideResponse(String image, int totalSlides) {
        this.image = image;
        this.totalSlides = totalSlides;
    }

    public SlideResponse(String base64Image) {
		// TODO Auto-generated constructor stub
	}

	public SlideResponse() {
		// TODO Auto-generated constructor stub
	}

	public String getImage() {
        return image;
    }

    public int getTotalSlides() {
        return totalSlides;
    }

}
