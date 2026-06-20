package com.vsmartengine.invoicebill.Items.Service;

import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

import org.springframework.stereotype.Service;

import com.vsmartengine.invoicebill.Items.Entity.Category;
import com.vsmartengine.invoicebill.Items.Entity.Item;
import com.vsmartengine.invoicebill.Items.Entity.ItemDTO;
import com.vsmartengine.invoicebill.Items.Entity.ItemPricing;
import com.vsmartengine.invoicebill.Items.Entity.ItemPricingDTO;
import com.vsmartengine.invoicebill.Items.Entity.ItemStock;
import com.vsmartengine.invoicebill.Items.Entity.ItemStockDTO;
import com.vsmartengine.invoicebill.Items.Entity.Tax;
import com.vsmartengine.invoicebill.Items.Entity.Unit;
import com.vsmartengine.invoicebill.Items.Repository.ItemPricingRepository;
import com.vsmartengine.invoicebill.Items.Repository.ItemRepository;
import com.vsmartengine.invoicebill.Items.Repository.ItemStockRepository;
import com.vsmartengine.invoicebill.User.SecurityConfiguration.JwtUtil;
import com.vsmartengine.invoicebill.Notification.Service.NotificationService;
import java.util.ArrayList;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class AddItemService {

    private final ItemRepository itemRepository;
    private final ItemPricingRepository itemPricingRepository;
    private final ItemStockRepository itemStockRepository;
    private final JwtUtil jwtUtil;
    private final NotificationService notiservice;

    // ── 1. Add Item — ADMIN + CASHIER ─────────────────────
    public String addItem(ItemDTO dto, String token) {
        String role = jwtUtil.getRoleFromToken(token);
        String email   = jwtUtil.getEmailFromToken(token);      // ← add
        String username= jwtUtil.getUsernameFromToken(token);
        if (!"ADMIN".equals(role) && !"CASHIER".equals(role)) {
            return "ACCESS_DENIED";
        }

        String company = jwtUtil.getCompanyFromToken(token);

        // Check duplicate item name
        boolean nameExists = itemRepository
            .existsByItemNameAndCompany(dto.getItemName(), company);
        if (nameExists) {
            return "DUPLICATE_NAME";
        }

        // Check duplicate item code
        if (dto.getItemCode() != null && !dto.getItemCode().isEmpty()) {
            boolean codeExists = itemRepository
                .existsByItemCodeAndCompany(dto.getItemCode(), company);
            if (codeExists) {
                return "DUPLICATE_CODE";
            }
        }

        // ── Save Item ──────────────────────────────────────
        Item item = new Item();
        item.setItemName(dto.getItemName());
        item.setItemHsn(dto.getItemHsn());
        item.setItemCode(dto.getItemCode());
        item.setCompany(company);

        // Set category
        if (dto.getCategoryId() != null) {
            Category category = new Category();
            category.setId(dto.getCategoryId());
            item.setCategory(category);
        }

        // Set unit
        if (dto.getUnitId() != null) {
            Unit unit = new Unit();
            unit.setId(dto.getUnitId());
            item.setUnit(unit);
        }

        // Set image — Base64 to bytes
        if (dto.getItemImage() != null && !dto.getItemImage().isEmpty()) {
            byte[] imageBytes = java.util.Base64.getDecoder()
                .decode(dto.getItemImage());
            item.setItemImage(imageBytes);
        }

        Item savedItem = itemRepository.save(item);

        // ── Save ItemPricing ───────────────────────────────
        if (dto.getPricing() != null) {
            ItemPricingDTO p = dto.getPricing();
            ItemPricing pricing = new ItemPricing();
            pricing.setItem(savedItem);
            pricing.setSalePrice(p.getSalePrice());
            pricing.setSalePriceTaxType(p.getSalePriceTaxType());
            pricing.setDiscountOnSale(p.getDiscountOnSale());
            pricing.setDiscountType(p.getDiscountType());
            pricing.setWholesalePrice(p.getWholesalePrice());
            pricing.setWholesalePriceTaxType(p.getWholesalePriceTaxType());
            pricing.setPurchasePrice(p.getPurchasePrice());
            pricing.setPurchasePriceTaxType(p.getPurchasePriceTaxType());
            pricing.setMrp(p.getMrp());
            pricing.setCalculateTaxOnMrp(p.getCalculateTaxOnMrp());
            pricing.setAdditionalCessPerUnit(p.getAdditionalCessPerUnit());

            // Set tax
            if (p.getTaxId() != null) {
                Tax tax = new Tax();
                tax.setId(p.getTaxId());
                pricing.setTax(tax);
            }

            itemPricingRepository.save(pricing);
        }

        // ── Save ItemStock ─────────────────────────────────
        if (dto.getStock() != null) {
            ItemStockDTO s = dto.getStock();
            ItemStock stock = new ItemStock();
            stock.setItem(savedItem);
            stock.setOpeningStock(s.getOpeningStock());
            stock.setStockAtPrice(s.getStockAtPrice());
            stock.setStockAsOfDate(s.getStockAsOfDate());
            stock.setMinStockQty(s.getMinStockQty());
            stock.setLocation(s.getLocation());

            itemStockRepository.save(stock);
        }

     // ── Notification ───────────────────────────────────
        
        String heading         = "New Item Added !";
        String notidescription = "A new item " + savedItem.getItemName()
                               + " (Code: " + savedItem.getItemCode() + ") was added by " + username;
        String link = "";

        Long NotifyId = notiservice.createNotification(
            "ItemAdd",
            username,
            notidescription,
            email,
            heading,
            link,
            Optional.empty()
        );

        if (NotifyId != null) {
            List<String> notiuserlist = new ArrayList<>();
            notiuserlist.add("ADMIN");
            notiuserlist.add("CASHIER");
            notiservice.CommoncreateNotificationUser(NotifyId, notiuserlist, company);
        }
        
       return "SAVED";
    }

    // ── 2. Search Items by name — ADMIN + CASHIER ─────────
    // Used for auto fill HSN and item code when typing item name
    public List<ItemDTO> searchItems(String itemName, String token) {
        String company = jwtUtil.getCompanyFromToken(token);

        List<Item> items = itemRepository
            .searchByItemNameAndCompany(itemName, company);

        return items.stream().map(item -> {
            ItemDTO dto = new ItemDTO();
            dto.setId(item.getId());
            dto.setItemName(item.getItemName());
            dto.setItemHsn(item.getItemHsn());
            dto.setItemCode(item.getItemCode());
            return dto;
        }).collect(Collectors.toList());
    }

    // ── 3. Generate Item Code — ADMIN + CASHIER ───────────
    // Called when admin clicks "Generate" button
    // Finds last item in company and increments code
    public String generateItemCode(String token) {
        String company = jwtUtil.getCompanyFromToken(token);

        Optional<Item> lastItem = itemRepository
            .findTopByCompanyOrderByIdDesc(company);

        if (lastItem.isEmpty()) {
            return "ITM001"; // first item
        }

        String lastCode = lastItem.get().getItemCode();

        // If last item has no code, count all items and generate
        if (lastCode == null || lastCode.isEmpty()) {
            long count = itemRepository
                .findByCompanyAndIsDeleted(company, false).size();
            return String.format("ITM%03d", count + 1);
        }

        // Extract number from last code e.g. ITM005 → 5
        try {
            String numberPart = lastCode.replaceAll("[^0-9]", "");
            int lastNumber = Integer.parseInt(numberPart);
            return String.format("ITM%03d", lastNumber + 1);
        } catch (Exception e) {
            // If code format is different, just count and generate
            long count = itemRepository
                .findByCompanyAndIsDeleted(company, false).size();
            return String.format("ITM%03d", count + 1);
        }
    }
    
 // Update Item — ADMIN + CASHIER
    public String updateItem(Long id, ItemDTO dto, String token) {
        String role = jwtUtil.getRoleFromToken(token);
        if (!"ADMIN".equals(role) && !"CASHIER".equals(role)) {
            return "ACCESS_DENIED";
        }

        String company = jwtUtil.getCompanyFromToken(token);

        // Check item exists and belongs to company
        Optional<Item> optionalItem = itemRepository.findByIdAndCompany(id, company);
        if (optionalItem.isEmpty()) {
            return "NOT_FOUND";
        }

        Item item = optionalItem.get();

        // Check duplicate item name (exclude current item)
        if (!item.getItemName().equals(dto.getItemName())) {
            boolean nameExists = itemRepository
                .existsByItemNameAndCompany(dto.getItemName(), company);
            if (nameExists) {
                return "DUPLICATE_NAME";
            }
        }

        // Check duplicate item code (exclude current item)
        if (dto.getItemCode() != null && !dto.getItemCode().isEmpty()) {
            if (!dto.getItemCode().equals(item.getItemCode())) {
                boolean codeExists = itemRepository
                    .existsByItemCodeAndCompany(dto.getItemCode(), company);
                if (codeExists) {
                    return "DUPLICATE_CODE";
                }
            }
        }

        // ── Update Item ────────────────────────────────────────
        item.setItemName(dto.getItemName());
        item.setItemHsn(dto.getItemHsn());
        item.setItemCode(dto.getItemCode());

        if (dto.getCategoryId() != null) {
            Category category = new Category();
            category.setId(dto.getCategoryId());
            item.setCategory(category);
        }

        if (dto.getUnitId() != null) {
            Unit unit = new Unit();
            unit.setId(dto.getUnitId());
            item.setUnit(unit);
        }

        if (dto.getItemImage() != null && !dto.getItemImage().isEmpty()) {
            byte[] imageBytes = java.util.Base64.getDecoder()
                .decode(dto.getItemImage());
            item.setItemImage(imageBytes);
        }

        itemRepository.save(item);

        // ── Update ItemPricing ─────────────────────────────────
        if (dto.getPricing() != null) {
            ItemPricingDTO p = dto.getPricing();
            ItemPricing pricing = itemPricingRepository
                .findByItemId(id)
                .orElse(new ItemPricing());

            pricing.setItem(item);
            pricing.setSalePrice(p.getSalePrice());
            pricing.setSalePriceTaxType(p.getSalePriceTaxType());
            pricing.setDiscountOnSale(p.getDiscountOnSale());
            pricing.setDiscountType(p.getDiscountType());
            pricing.setWholesalePrice(p.getWholesalePrice());
            pricing.setWholesalePriceTaxType(p.getWholesalePriceTaxType());
            pricing.setPurchasePrice(p.getPurchasePrice());
            pricing.setPurchasePriceTaxType(p.getPurchasePriceTaxType());
            pricing.setMrp(p.getMrp());
            pricing.setCalculateTaxOnMrp(p.getCalculateTaxOnMrp());
            pricing.setAdditionalCessPerUnit(p.getAdditionalCessPerUnit());

            if (p.getTaxId() != null) {
                Tax tax = new Tax();
                tax.setId(p.getTaxId());
                pricing.setTax(tax);
            }

            itemPricingRepository.save(pricing);
        }

        // ── Update ItemStock ───────────────────────────────────
        if (dto.getStock() != null) {
            ItemStockDTO s = dto.getStock();
            ItemStock stock = itemStockRepository
                .findByItemId(id)
                .orElse(new ItemStock());

            stock.setItem(item);
            stock.setOpeningStock(s.getOpeningStock());
            stock.setStockAtPrice(s.getStockAtPrice());
            stock.setStockAsOfDate(s.getStockAsOfDate());
            stock.setMinStockQty(s.getMinStockQty());
            stock.setLocation(s.getLocation());

            itemStockRepository.save(stock);
        }

     // ── Notification ───────────────────────────────────
        String username = jwtUtil.getUsernameFromToken(token);
        String email    = jwtUtil.getEmailFromToken(token);

        String heading         = "Item Updated !";
        String notidescription = "Item " + item.getItemName()
                               + " (Code: " + item.getItemCode() + ") was updated by " + username;
        String link = "";

        Long NotifyId = notiservice.createNotification(
            "ItemUpdate",
            username,
            notidescription,
            email,
            heading,
            link,
            Optional.empty()
        );

        if (NotifyId != null) {
            List<String> notiuserlist = new ArrayList<>();
            notiuserlist.add("ADMIN");
            notiuserlist.add("CASHIER");
            notiservice.CommoncreateNotificationUser(NotifyId, notiuserlist, company);
        }
        
        return "UPDATED";
    }
    
    
    
    public ItemDTO getItemById(Long id, String token) {
        String company = jwtUtil.getCompanyFromToken(token);
        
        Optional<Item> optional = itemRepository.findByIdAndCompany(id, company);
        if (optional.isEmpty()) return null;
        
        Item item = optional.get();
        ItemDTO dto = new ItemDTO();
        dto.setId(item.getId());
        dto.setItemName(item.getItemName());
        dto.setItemHsn(item.getItemHsn());
        dto.setItemCode(item.getItemCode());
        dto.setCategoryId(item.getCategory() != null ? item.getCategory().getId() : null);
        dto.setUnitId(item.getUnit() != null ? item.getUnit().getId() : null);

        // pricing
        itemPricingRepository.findByItemId(id).ifPresent(p -> {
            ItemPricingDTO pricing = new ItemPricingDTO();
            pricing.setSalePrice(p.getSalePrice());
            pricing.setSalePriceTaxType(p.getSalePriceTaxType());
            pricing.setDiscountOnSale(p.getDiscountOnSale());
            pricing.setDiscountType(p.getDiscountType());
            pricing.setWholesalePrice(p.getWholesalePrice());
            pricing.setWholesalePriceTaxType(p.getWholesalePriceTaxType());
            pricing.setPurchasePrice(p.getPurchasePrice());
            pricing.setPurchasePriceTaxType(p.getPurchasePriceTaxType());
            pricing.setMrp(p.getMrp());
            pricing.setCalculateTaxOnMrp(p.getCalculateTaxOnMrp());
            pricing.setAdditionalCessPerUnit(p.getAdditionalCessPerUnit());
            pricing.setTaxId(p.getTax() != null ? p.getTax().getId() : null);
            dto.setPricing(pricing);
        });

        // stock
        itemStockRepository.findByItemId(id).ifPresent(s -> {
            ItemStockDTO stock = new ItemStockDTO();
            stock.setOpeningStock(s.getOpeningStock());
            stock.setStockAtPrice(s.getStockAtPrice());
            stock.setStockAsOfDate(s.getStockAsOfDate());
            stock.setMinStockQty(s.getMinStockQty());
            stock.setLocation(s.getLocation());
            dto.setStock(stock);
        });

        return dto;
    }
}