package com.vsmartengine.invoicebill.Migration;

import java.sql.Connection;
import java.sql.Statement;

import javax.sql.DataSource;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class DatabaseCreationService {
	 @Autowired
	    private DataSource dataSource;

	    public void createDatabase(String dbName) {
	        String sql = "CREATE DATABASE " + dbName;

	        try (Connection connection = dataSource.getConnection();
	             Statement statement = connection.createStatement()) {
	            connection.setAutoCommit(true); // Ensure it's outside a transaction
	            statement.executeUpdate(sql);
	        } catch (Exception e) {
	            throw new RuntimeException("Failed to create database: " + dbName, e);
	        }
	    }
}
