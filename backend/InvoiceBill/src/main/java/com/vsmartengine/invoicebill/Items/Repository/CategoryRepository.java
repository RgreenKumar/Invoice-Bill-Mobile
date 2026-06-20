package com.vsmartengine.invoicebill.Items.Repository;

import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import com.vsmartengine.invoicebill.Items.Entity.Category;

@Repository
public interface CategoryRepository extends JpaRepository<Category, Long> {

  
    List<Category> findByCompany(String company);

    
    boolean existsByNameAndCompany(String name, String company);

    Category findByIdAndCompany(Long id, String company);

    boolean existsByIdAndCompany(Long id, String company);
    
    List<Category> findByCompanyIn(List<String> companies);
}