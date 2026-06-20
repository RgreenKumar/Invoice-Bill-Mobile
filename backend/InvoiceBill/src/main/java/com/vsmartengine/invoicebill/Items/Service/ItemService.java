package com.vsmartengine.invoicebill.Items.Service;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

import org.springframework.stereotype.Service;

import com.vsmartengine.invoicebill.Customer.Repository.CustomerRepository;
import com.vsmartengine.invoicebill.Items.Entity.Category;
import com.vsmartengine.invoicebill.Items.Entity.CategoryDTO;
import com.vsmartengine.invoicebill.Items.Entity.Unit;
import com.vsmartengine.invoicebill.Items.Entity.UnitDTO;
import com.vsmartengine.invoicebill.Items.Repository.CategoryRepository;
import com.vsmartengine.invoicebill.Items.Repository.ItemPricingRepository;
import com.vsmartengine.invoicebill.Items.Repository.ItemRepository;
import com.vsmartengine.invoicebill.Items.Repository.TaxRepository;
import com.vsmartengine.invoicebill.Items.Repository.UnitRepository;
import com.vsmartengine.invoicebill.User.SecurityConfiguration.JwtUtil;
import com.vsmartengine.invoicebill.Items.Entity.Tax;
import com.vsmartengine.invoicebill.Items.Entity.Item;
import com.vsmartengine.invoicebill.Items.Entity.ItemDTO;
import com.vsmartengine.invoicebill.Items.Entity.ItemStockDTO;
import com.vsmartengine.invoicebill.Items.Repository.ItemStockRepository;
import com.vsmartengine.invoicebill.Notification.Repositories.NotificationDetailsRepo;
import 	com.vsmartengine.invoicebill.Notification.Service.NotificationService;
import com.vsmartengine.invoicebill.SaleInvoice.Entity.SaleInvoiceItem;
import com.vsmartengine.invoicebill.SaleInvoice.Repository.SaleInvoiceItemRepository;
import com.vsmartengine.invoicebill.SaleInvoice.Repository.SaleInvoiceRepository;

import lombok.RequiredArgsConstructor;    
 
 

@Service
@RequiredArgsConstructor
public class ItemService{
	
    private final UnitRepository unitRepository;
	private final CategoryRepository categoryRepository;
	private final ItemRepository itemRepository;
	private final TaxRepository taxRepository;
	private final ItemStockRepository  itemStockRepository;
    private final JwtUtil jwtUtil;
    private final NotificationService notiservice;
    private final SaleInvoiceItemRepository saleInvoiceItemRepository;
    private final ItemPricingRepository itemPricingRepository;
    private final NotificationDetailsRepo notidetailRepo;
    private final CustomerRepository customerRepository;
    private final SaleInvoiceRepository saleInvoiceRepository;
    
 // Get items by category — ADMIN and CASHIER
    public List<ItemDTO> getItemsByCategory(Long categoryId, String token) {
        String company = jwtUtil.getCompanyFromToken(token);
        List<Item> items = itemRepository
            .findByCategoryIdAndCompanyAndIsDeleted(categoryId, company, false);

        return items.stream().map(item -> {
            ItemDTO dto = new ItemDTO();
            dto.setId(item.getId());
            dto.setItemName(item.getItemName());
            dto.setItemCode(item.getItemCode());

            // fetch opening stock
            itemStockRepository.findByItemId(item.getId())
                .ifPresent(stock -> {
                    ItemStockDTO stockDTO = new ItemStockDTO();
                    stockDTO.setOpeningStock(stock.getOpeningStock());
                    dto.setStock(stockDTO);
                });

            return dto;
        }).collect(java.util.stream.Collectors.toList());
    }
    
    // Get all categories — ADMIN and CASHIER
    // Returns DEFAULT (system) + company's own categories
    public List<CategoryDTO> getAllCategoriesWithCount(String token) {
        String company = jwtUtil.getCompanyFromToken(token);
        List<Category> categories = categoryRepository
            .findByCompanyIn(List.of("DEFAULT", company));

        return categories.stream().map(cat -> {
            CategoryDTO dto = new CategoryDTO();
            dto.setId(cat.getId());
            dto.setName(cat.getName());
            Long count = itemRepository
                .countByCategoryIdAndCompanyAndIsDeleted(
                    cat.getId(), company, false);
            dto.setItemCount(count);
            return dto;
        }).collect(java.util.stream.Collectors.toList());
    }

    // Add new category — ADMIN only
   // Add new category — ADMIN only
    public Category addCategory(CategoryDTO dto, String token) {
        String role = jwtUtil.getRoleFromToken(token);
        if (!"ADMIN".equals(role)) {
            return null; // CASHIER cannot add
        }

        String company = jwtUtil.getCompanyFromToken(token);

        // Check duplicate within DEFAULT + company
        boolean exists = categoryRepository
            .existsByNameAndCompany(dto.getName(), company);
        boolean existsInDefault = categoryRepository
            .existsByNameAndCompany(dto.getName(), "DEFAULT");

        if (exists || existsInDefault) {
            return null; // duplicate category name
        }

        Category category = new Category();
        category.setName(dto.getName());
        category.setCompany(company);

        Category savedCategory = categoryRepository.save(category);

        String username = jwtUtil.getUsernameFromToken(token);
        String email    = jwtUtil.getEmailFromToken(token);
        String heading         = "New Category Added !";
        String notidescription = "A new category " + savedCategory.getName() + " was added by " + username;

        Long NotifyId = notiservice.createNotification(
            "CategoryAdd", username, notidescription, email, heading, "", java.util.Optional.empty()
        );
        if (NotifyId != null) {
            java.util.List<String> notiuserlist = new java.util.ArrayList<>();
            notiuserlist.add("ADMIN");
            notiservice.CommoncreateNotificationUser(NotifyId, notiuserlist, company);
        }

        return savedCategory;
    }
    
    public List<ItemDTO> getItemsByCompany(String token) {
        String company = jwtUtil.getCompanyFromToken(token);
        List<Item> items = itemRepository
            .findByCompanyAndIsDeleted(company, false);

        return items.stream().map(item -> {
            ItemDTO dto = new ItemDTO();
            dto.setId(item.getId());
            dto.setItemName(item.getItemName());
            dto.setItemCode(item.getItemCode());
         
            // ── opening stock ──
            final Integer[] openingStock = { 0 };
            itemStockRepository.findByItemId(item.getId())
                .ifPresent(stock -> {
                    ItemStockDTO stockDTO = new ItemStockDTO();
                    stockDTO.setOpeningStock(stock.getOpeningStock());
                    dto.setStock(stockDTO);
                    if (stock.getOpeningStock() != null) {
                        openingStock[0] = stock.getOpeningStock();
                    }
                });

            // ── total sold qty from all bills ──
            List<SaleInvoiceItem> soldRows = saleInvoiceItemRepository
                .findByItemNameAndCompanyName(item.getItemName(), company);

            BigDecimal totalSold = soldRows.stream()
                .map(row -> row.getQty() != null ? row.getQty() : BigDecimal.ZERO)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

            // ── remaining = opening - sold ──
            BigDecimal remaining = BigDecimal.valueOf(openingStock[0])
                                   .subtract(totalSold);
            dto.setRemainingStock(remaining);
            ///pricing 	
            itemPricingRepository.findByItemId(item.getId())
            .ifPresent(pricing -> {
                dto.setSalePrice(pricing.getSalePrice());
                dto.setPurchasePrice(pricing.getPurchasePrice());
            });
            return dto;
        }).collect(Collectors.toList());
    }    
    
    // Delete category — ADMIN only, only their own company (not DEFAULT)
    public String deleteCategory(Long id, String token) {
        String role = jwtUtil.getRoleFromToken(token);
        if (!"ADMIN".equals(role)) {
            return "ACCESS_DENIED";
        }

        String company = jwtUtil.getCompanyFromToken(token);

        // Only allow delete if category belongs to their company (not DEFAULT)
        boolean exists = categoryRepository
            .existsByIdAndCompany(id, company);
        if (!exists) {
            return "NOT_FOUND";
        }

        // Check if any active item is using this category
        Long itemCount = itemRepository
            .countByCategoryIdAndCompanyAndIsDeleted(id, company, false);
        if (itemCount > 0) {
            return "IN_USE"; // category is in use
        }

        categoryRepository.deleteById(id);
        return "DELETED";
    }
    
    // Update category — ADMIN only, only their own company (not DEFAULT)
 		 public String updateCategory(Long id, CategoryDTO dto, String token) {
 		     String role = jwtUtil.getRoleFromToken(token);
 		     if (!"ADMIN".equals(role)) {
 		         return "ACCESS_DENIED";
 		     }

 		     String company = jwtUtil.getCompanyFromToken(token);

 		     // Only allow edit if category belongs to their company (not DEFAULT)
 		     Category category = categoryRepository
 		         .findByIdAndCompany(id, company);
 		     if (category == null) {
 		         return "NOT_FOUND";
 		     }

 		     // Check duplicate name
 		     boolean exists = categoryRepository
 		         .existsByNameAndCompany(dto.getName(), company);
 		     if (exists) {
 		         return "DUPLICATE";
 		     }

 		     category.setName(dto.getName());
 		     categoryRepository.save(category);
 		     
 		    String username = jwtUtil.getUsernameFromToken(token);
 		   String email    = jwtUtil.getEmailFromToken(token);
 		   String heading         = "Category Updated !";
 		   String notidescription = "Category " + category.getName() + " was updated by " + username;

 		   Long NotifyId = notiservice.createNotification(
 		       "CategoryUpdate", username, notidescription, email, heading, "", java.util.Optional.empty()
 		   );
 		   if (NotifyId != null) {
 		       java.util.List<String> notiuserlist = new java.util.ArrayList<>();
 		       notiuserlist.add("ADMIN");
 		       notiservice.CommoncreateNotificationUser(NotifyId, notiuserlist, company);
 		   }

 		   return "UPDATED";
 		 }		 
 		 
    //========================================unit added====================================
    
 		// FIXED ✅
 		public List<ItemDTO> getItemsByUnit(Long unitId, String token) {
 		    String company = jwtUtil.getCompanyFromToken(token);
 		    List<Item> items = itemRepository.findByUnitIdAndCompanyAndIsDeleted(
 		        unitId, company, false
 		    );

 		    return items.stream().map(item -> {
 		        ItemDTO dto = new ItemDTO();
 		        dto.setId(item.getId());
 		        dto.setItemName(item.getItemName());
 		        dto.setItemCode(item.getItemCode());

 		        itemStockRepository.findByItemId(item.getId())
 		            .ifPresent(stock -> {
 		                ItemStockDTO stockDTO = new ItemStockDTO();
 		                stockDTO.setOpeningStock(stock.getOpeningStock());
 		                dto.setStock(stockDTO);
 		            });

 		        return dto;
 		    }).collect(java.util.stream.Collectors.toList());
 		}	 
 		 
     // Get all units — ADMIN and CASHIER
    // Returns DEFAULT (system) + company's own units
    
 		public List<UnitDTO> getAllUnitsWithCount(String token) {
 		    String company = jwtUtil.getCompanyFromToken(token);
 		    List<Unit> units = unitRepository
 		        .findByCompanyIn(List.of("DEFAULT", company));

 		    return units.stream().map(u -> {
 		        UnitDTO dto = new UnitDTO();
 		        dto.setId(u.getId());
 		        dto.setName(u.getName());
 		        dto.setSymbol(u.getSymbol());
 		        dto.setConversionValue(u.getConversionValue());
 		        dto.setConversionUnit(u.getConversionUnit());
 		        Long count = itemRepository
 		            .countByUnitIdAndCompanyAndIsDeleted(u.getId(), company, false);
 		        dto.setItemCount(count);
 		        return dto;
 		    }).collect(java.util.stream.Collectors.toList());
 		}

    // Add new unit — ADMIN only
    public Unit addUnit(UnitDTO dto, String token) {
        String role = jwtUtil.getRoleFromToken(token);
        if (!"ADMIN".equals(role)) {
            return null; // CASHIER cannot add
        }

        String company = jwtUtil.getCompanyFromToken(token);

        // Check duplicate within company + DEFAULT
        boolean exists = unitRepository
            .existsByNameAndCompany(dto.getName(), company);
        boolean existsInDefault = unitRepository
            .existsByNameAndCompany(dto.getName(), "DEFAULT");

        if (exists || existsInDefault) {
            return null; // duplicate unit name
        }

        Unit unit = new Unit();
        unit.setName(dto.getName());
        unit.setSymbol(dto.getSymbol());
        unit.setConversionValue(dto.getConversionValue());
        unit.setConversionUnit(dto.getConversionUnit());
        unit.setCompany(company);

        Unit savedUnit = unitRepository.save(unit);

        String username = jwtUtil.getUsernameFromToken(token);
        String email    = jwtUtil.getEmailFromToken(token);
        String heading         = "New Unit Added !";
        String notidescription = "A new unit " + savedUnit.getName() + " (" + savedUnit.getSymbol() + ") was added by " + username;

        Long NotifyId = notiservice.createNotification(
            "UnitAdd", username, notidescription, email, heading, "", java.util.Optional.empty()
        );
        if (NotifyId != null) {
            java.util.List<String> notiuserlist = new java.util.ArrayList<>();
            notiuserlist.add("ADMIN");
            notiservice.CommoncreateNotificationUser(NotifyId, notiuserlist, company);
        }

        return savedUnit;
    }

    // Delete unit — ADMIN only, only their own company (not DEFAULT)
    public String deleteUnit(Long id, String token) {
        String role = jwtUtil.getRoleFromToken(token);
        if (!"ADMIN".equals(role)) {
            return "ACCESS_DENIED";
        }

        String company = jwtUtil.getCompanyFromToken(token);

        // Only allow delete if unit belongs to their company (not DEFAULT)
        boolean exists = unitRepository
            .existsByIdAndCompany(id, company);
        if (!exists) {
            return "NOT_FOUND";
        }

        // Check if any active item is using this unit
        Long itemCount = itemRepository
            .countByUnitIdAndCompanyAndIsDeleted(id, company, false);
        if (itemCount > 0) {
            return "IN_USE"; // unit is in use
        }

        unitRepository.deleteById(id);
        return "DELETED";
    }
    
    public String updateUnit(Long id,UnitDTO dto,String token)
    {
    	String role=jwtUtil.getRoleFromToken(token);
    	if(!"ADMIN".equals(role))
    	{
    		return"ACCESS_DENIED";
    	}
    	
    	String company=jwtUtil.getCompanyFromToken(token);
    	
    	
    	Unit unit = unitRepository.findByIdAndCompany(id, company);
    	
    	if(unit==null)
    	{
    		return "NOT_FOUND";
    		
         }
    	
    	boolean exists = unitRepository.existsByNameAndCompany(dto.getName(), company);
    	
    	if(exists)
    	{
    		return "DUPLICATE";
    		
    	}
    	unit.setName(dto.getName());
    	unit.setSymbol(dto.getSymbol());
        unit.setConversionValue(dto.getConversionValue());
        unit.setConversionUnit(dto.getConversionUnit());
        unitRepository.save(unit);
        String username = jwtUtil.getUsernameFromToken(token);
        String email    = jwtUtil.getEmailFromToken(token);
        String heading         = "Unit Updated !";
        String notidescription = "Unit " + unit.getName() + " (" + unit.getSymbol() + ") was updated by " + username;

        Long NotifyId = notiservice.createNotification(
            "UnitUpdate", username, notidescription, email, heading, "", java.util.Optional.empty()
        );
        if (NotifyId != null) {
            java.util.List<String> notiuserlist = new java.util.ArrayList<>();
            notiuserlist.add("ADMIN");
            notiservice.CommoncreateNotificationUser(NotifyId, notiuserlist, company);
        }

        return "UPDATED";

    	
    }
    
    public List<ItemDTO> getLowStockItems(String token) {
        String company = jwtUtil.getCompanyFromToken(token);
        List<Item> items = itemRepository.findByCompanyAndIsDeleted(company, false);

        return items.stream().map(item -> {
            final Integer[] openingStock = { 0 };
            final Integer[] minStockQty = { 0 };

            itemStockRepository.findByItemId(item.getId())
                .ifPresent(stock -> {
                    if (stock.getOpeningStock() != null)
                        openingStock[0] = stock.getOpeningStock();
                    if (stock.getMinStockQty() != null)
                        minStockQty[0] = stock.getMinStockQty();
                });

            List<SaleInvoiceItem> soldRows = saleInvoiceItemRepository
                .findByItemNameAndCompanyName(item.getItemName(), company);

            BigDecimal totalSold = soldRows.stream()
                .map(r -> r.getQty() != null ? r.getQty() : BigDecimal.ZERO)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

            BigDecimal remaining = BigDecimal.valueOf(openingStock[0]).subtract(totalSold);

            if (remaining.compareTo(BigDecimal.valueOf(minStockQty[0])) > 0)
                return null;

            ItemDTO dto = new ItemDTO();
            dto.setId(item.getId());
            dto.setItemName(item.getItemName());
            dto.setItemCode(item.getItemCode());
            dto.setRemainingStock(remaining);

            

            itemPricingRepository.findByItemId(item.getId())
                .ifPresent(pricing -> {
                    dto.setSalePrice(pricing.getSalePrice());
                    dto.setPurchasePrice(pricing.getPurchasePrice());
                });

            return dto;

        }).filter(dto -> dto != null).collect(Collectors.toList());
    }
    
    
//    public Map<String, Object> getDashboardCounts(String token) {
//        String company = jwtUtil.getCompanyFromToken(token);
//        Map<String, Object> result = new java.util.HashMap<>();
//
//        // Total Items
//        result.put("totalItems", itemRepository
//            .findByCompanyAndIsDeleted(company, false).size());
//
//        // Total Customers
//        result.put("totalParties", customerRepository.countByCompany(company));
//
//        // Total Transactions
//        result.put("totalTransactions", saleInvoiceRepository
//            .countByCompanyName(company));
//
//        // Total Revenue
//        result.put("totalRevenue", saleInvoiceRepository
//            .sumGrandTotalByCompanyName(company));
//
//        // Total Received
//        result.put("totalReceived", saleInvoiceRepository
//            .sumAmountReceivedByCompanyName(company));
//
//        return result;
//    }
    
    
		 // Get all taxes — ADMIN and CASHIER
		 // Returns DEFAULT (system) taxes only
		 public List<Tax> getAllTax(String token) {
		     return taxRepository.findByCompany("DEFAULT");
		 }
//===================================================================================================		    
//===============================edit category=================================================================		 

		
		 
	
}