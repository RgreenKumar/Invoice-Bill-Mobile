package com.vsmartengine.invoicebill.ImageCompressing;
import java.awt.Graphics2D;
import java.awt.Image;
import java.awt.image.BufferedImage;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;

import javax.imageio.ImageIO;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.web.multipart.MultipartFile;

import com.vsmartengine.invoicebill.Notification.Service.NotificationService;

public class ImageResizer {
	 private static final Logger logger = LoggerFactory.getLogger(NotificationService.class);
	 public static byte[] resizeImage(byte[] imageBytes, int width, int height) {
		 try {
	        // Convert byte array to BufferedImage
	        ByteArrayInputStream bais = new ByteArrayInputStream(imageBytes);
	        BufferedImage originalImage = ImageIO.read(bais);
              if(originalImage== null) {
            	  return null;
              }
	        // Create a resized image with specified dimensions
	        Image resizedImage = originalImage.getScaledInstance(width, height, Image.SCALE_SMOOTH);

	        // Create a new BufferedImage to hold the resized image
	        BufferedImage bufferedResizedImage = new BufferedImage(width, height, BufferedImage.TYPE_INT_RGB);
	        Graphics2D g2d = bufferedResizedImage.createGraphics();
	        g2d.drawImage(resizedImage, 0, 0, null);
	        g2d.dispose();

	        // Convert BufferedImage to byte array
	        ByteArrayOutputStream baos = new ByteArrayOutputStream();
	        ImageIO.write(bufferedResizedImage, "jpg", baos);
	        baos.flush();
	        byte[] resizedImageBytes = baos.toByteArray();
	        baos.close();

	        return resizedImageBytes;
		 }catch(IOException e) {
			 logger.error("", e);;
			 return null;
		 }

	    }
	 public static byte[] resizeImage(MultipartFile file, int width, int height) {
	        // Convert MultipartFile to BufferedImage
		 try {
	        BufferedImage originalImage = ImageIO.read(file.getInputStream());
	        if(originalImage== null) {
          	  return null;
            }
	        // Create a resized image with specified dimensions
	        Image resizedImage = originalImage.getScaledInstance(width, height, Image.SCALE_SMOOTH);

	        // Create a new BufferedImage to hold the resized image
	        BufferedImage bufferedResizedImage = new BufferedImage(width, height, BufferedImage.TYPE_INT_RGB);
	        Graphics2D g2d = bufferedResizedImage.createGraphics();
	        g2d.drawImage(resizedImage, 0, 0, null);
	        g2d.dispose();

	        // Convert BufferedImage to byte array
	        ByteArrayOutputStream baos = new ByteArrayOutputStream();
	        ImageIO.write(bufferedResizedImage, "jpg", baos);
	        baos.flush();
	        byte[] resizedImageBytes = baos.toByteArray();
	        baos.close();

	        return resizedImageBytes;
		 }catch(IOException e) {
			 logger.error("", e);;
			 return null;
		 }
	    }

}
