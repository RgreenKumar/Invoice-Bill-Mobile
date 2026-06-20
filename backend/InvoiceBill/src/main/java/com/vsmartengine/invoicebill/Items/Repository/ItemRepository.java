package com.vsmartengine.invoicebill.Items.Repository;

import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import com.vsmartengine.invoicebill.Items.Entity.Item;

@Repository
public interface ItemRepository extends JpaRepository<Item, Long> {

   
    List<Item> findByCompanyAndIsDeleted(
        String company, Boolean isDeleted);

    Optional<Item> findByIdAndCompany(
        Long id, String company);

    boolean existsByItemNameAndCompany(
        String itemName, String company);

    boolean existsByItemCodeAndCompany(
        String itemCode, String company);

    boolean existsByIdAndCompany(
        Long id, String company);

    Long countByCategoryIdAndCompanyAndIsDeleted(
        Long categoryId, String company, Boolean isDeleted);

    Long countByUnitIdAndCompanyAndIsDeleted(
        Long unitId, String company, Boolean isDeleted);

    List<Item> findByCategoryIdAndCompanyAndIsDeleted(
        Long categoryId, String company, Boolean isDeleted);

    // get items by unit
    // used for unit page right side
    List<Item> findByUnitIdAndCompanyAndIsDeleted(
        Long unitId, String company, Boolean isDeleted);

    // search item by name
    // used for invoice item search
    @Query("SELECT i FROM Item i " +
           "WHERE LOWER(i.itemName) " +
           "LIKE LOWER(CONCAT('%', :itemName, '%')) " +
           "AND i.company = :company " +
           "AND i.isDeleted = false")
    List<Item> searchByItemNameAndCompany(
        @Param("itemName") String itemName,
        @Param("company") String company);
    
    
 // for generate item code — find last item by company
    Optional<Item> findTopByCompanyOrderByIdDesc(String company);
    
 // search item by name or code
 // used for billing page item search dropdown
 @Query("SELECT i FROM Item i " +
        "WHERE i.company = :company " +
        "AND i.isDeleted = false " +
        "AND (LOWER(i.itemName) LIKE LOWER(CONCAT('%', :keyword, '%')) " +
        "OR LOWER(i.itemCode) LIKE LOWER(CONCAT('%', :keyword, '%')))")
 List<Item> searchByNameOrCode(
     @Param("keyword") String keyword,
     @Param("company") String company);
    
}