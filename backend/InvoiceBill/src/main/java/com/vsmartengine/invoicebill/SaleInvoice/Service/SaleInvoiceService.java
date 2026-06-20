package com.vsmartengine.invoicebill.SaleInvoice.Service;

import com.vsmartengine.invoicebill.Customer.Entity.CustomerDetails;
import com.vsmartengine.invoicebill.Customer.Repository.CustomerRepository;
import com.vsmartengine.invoicebill.Items.Entity.Item;
import com.vsmartengine.invoicebill.Items.Entity.ItemPricing;
import com.vsmartengine.invoicebill.Items.Repository.ItemPricingRepository;
import com.vsmartengine.invoicebill.Items.Repository.ItemRepository;
import com.vsmartengine.invoicebill.SaleInvoice.Entity.CustomerSearchResponseDto;
import com.vsmartengine.invoicebill.SaleInvoice.Entity.ItemSearchResponseDto;
import com.vsmartengine.invoicebill.SaleInvoice.Entity.ItemTransactionDto;
import com.vsmartengine.invoicebill.SaleInvoice.Entity.SaleInvoice;
import com.vsmartengine.invoicebill.SaleInvoice.Entity.SaleInvoiceItem;
import com.vsmartengine.invoicebill.SaleInvoice.Entity.SaleInvoiceItemDto;
import com.vsmartengine.invoicebill.SaleInvoice.Entity.SaleInvoicePayment;
import com.vsmartengine.invoicebill.SaleInvoice.Entity.SaleInvoicePaymentDto;
import com.vsmartengine.invoicebill.SaleInvoice.Entity.SaleInvoiceRequestDto;
import com.vsmartengine.invoicebill.SaleInvoice.Entity.SaleInvoiceResponseDto;
import com.vsmartengine.invoicebill.SaleInvoice.Repository.SaleInvoiceItemRepository;
import com.vsmartengine.invoicebill.SaleInvoice.Repository.SaleInvoicePaymentRepository;
import com.vsmartengine.invoicebill.SaleInvoice.Repository.SaleInvoiceRepository;
import lombok.Data;
import lombok.AllArgsConstructor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.util.List;
import java.util.stream.Collectors;

import com.vsmartengine.invoicebill.User.Repository.MuserRepositories;
import com.vsmartengine.invoicebill.User.SecurityConfiguration.*;
@Service
public class SaleInvoiceService {

    @Autowired
    private SaleInvoiceRepository saleInvoiceRepository;

    @Autowired
    private SaleInvoiceItemRepository saleInvoiceItemRepository;

    @Autowired
    private SaleInvoicePaymentRepository saleInvoicePaymentRepository;

    @Autowired
    private CustomerRepository customerRepository;

    @Autowired
    private ItemRepository itemRepository;

    @Autowired
    private ItemPricingRepository itemPricingRepository;

    @Autowired
    private JwtUtil jwtUtil;
    
    @Autowired
    private MuserRepositories muserRepository;

    // ═══════════════════════════════════════════════
    // PRIVATE HELPER — Row Calculation
    // ═══════════════════════════════════════════════
    // Same formula as React calcRow()
    // Called inside saveBill() for each item row
    // ═══════════════════════════════════════════════

    private RowCalculation calculateRow(SaleInvoiceItemDto item) {

        BigDecimal qty     = item.getQty() != null 
                             ? item.getQty() : BigDecimal.ZERO;
        BigDecimal price   = item.getPriceWithoutTax() != null 
                             ? item.getPriceWithoutTax() : BigDecimal.ZERO;
        BigDecimal discPct = item.getDiscountPct() != null 
                             ? item.getDiscountPct() : BigDecimal.ZERO;
        BigDecimal taxPct  = item.getTaxPct() != null 
                             ? item.getTaxPct() : BigDecimal.ZERO;

        // qty × price
        BigDecimal grossAmt = qty.multiply(price);

        // grossAmt × discPct / 100
        BigDecimal discAmt = grossAmt
                .multiply(discPct)
                .divide(BigDecimal.valueOf(100), 2, RoundingMode.HALF_UP);

        // grossAmt - discAmt
        BigDecimal taxable = grossAmt.subtract(discAmt);

        // taxable × (taxPct/2) / 100
        BigDecimal cgst = taxable
                .multiply(taxPct.divide(BigDecimal.valueOf(2), 2, RoundingMode.HALF_UP))
                .divide(BigDecimal.valueOf(100), 2, RoundingMode.HALF_UP);

        BigDecimal sgst = cgst;


	     // change to ✅
	     BigDecimal cessAmt = item.getAddCess() != null 
	                          ? item.getAddCess() 
	                          : BigDecimal.ZERO;
	     BigDecimal total   = taxable.add(cgst).add(sgst).add(cessAmt);

        return new RowCalculation(grossAmt, discAmt, taxable, cgst, sgst, total);
    }

    // ═══════════════════════════════════════════════
    // METHOD 1 — saveBill()
    // ═══════════════════════════════════════════════
    // Called when user clicks Save in billing page
    // Handles Estimate, Sale, POS — all 3 bill types
    // Steps:
    //   1. Extract company + username from JWT
    //   2. Create SaleInvoice entity
    //   3. Loop items → calculateRow() each item
    //   4. Sum all rows → bill totals
    //   5. Handle round off
    //   6. Save invoice + items + payments to DB
    // ═══════════════════════════════════════════════

    @Transactional
    public SaleInvoiceResponseDto saveBill(
            SaleInvoiceRequestDto request,
            String token) {

        // Step 1 — extract from JWT
        String company   = jwtUtil.getCompanyFromToken(token);
        String createdBy = jwtUtil.getUsernameFromToken(token);

        // Step 2 — create invoice header
        SaleInvoice invoice = new SaleInvoice();
        invoice.setCompanyName(company);
        invoice.setCreatedBy(createdBy);
        invoice.setBillType(request.getBillType());
        invoice.setInvoiceNumber(request.getInvoiceNumber());
        invoice.setInvoicePrefix(request.getInvoicePrefix());
        invoice.setInvoiceDate(request.getInvoiceDate());
        invoice.setPartyName(request.getPartyName());
        invoice.setPhoneNo(request.getPhoneNo());
        invoice.setStateOfSupply(request.getStateOfSupply());
        invoice.setIsCash(request.getIsCash());
        invoice.setPaymentMode(request.getPaymentMode());
        invoice.setRoundOffEnabled(request.getRoundOffEnabled());
        invoice.setReceived(request.getReceived());
        invoice.setAmountReceived(request.getAmountReceived());
        invoice.setDescription(request.getDescription());
        invoice.setTermsConditions(request.getTermsConditions());
        invoice.setImagePath(request.getImagePath());

        // POS only fields
        invoice.setBillDiscount(request.getBillDiscount());
        invoice.setAdditionalCharges(request.getAdditionalCharges());
        invoice.setRemarks(request.getRemarks());
        invoice.setLoyaltyPoints(request.getLoyaltyPoints());

        // Step 3 — loop items and calculate each row
        List<SaleInvoiceItem> itemEntities = request.getItems()
                .stream()
                .filter(i -> i.getItemName() != null 
                             && !i.getItemName().isEmpty())
                .map(itemDto -> {

                    // calculate this row
                    RowCalculation calc = calculateRow(itemDto);

                    // create item entity
                    SaleInvoiceItem itemEntity = new SaleInvoiceItem();
                    itemEntity.setCompanyName(company);
                    itemEntity.setLineNumber(itemDto.getLineNumber());
                    itemEntity.setItemName(itemDto.getItemName());
                    itemEntity.setItemCode(itemDto.getItemCode());
                    itemEntity.setModelNo(itemDto.getModelNo());
                    itemEntity.setMfgDate(itemDto.getMfgDate());
                    itemEntity.setExpDate(itemDto.getExpDate());
                    itemEntity.setMrp(itemDto.getMrp());
                    itemEntity.setSize(itemDto.getSize());
                    itemEntity.setAddCess(itemDto.getAddCess());
                    itemEntity.setHsnCode(itemDto.getHsnCode());
                    itemEntity.setQty(itemDto.getQty());
                    itemEntity.setUnit(itemDto.getUnit());
                    itemEntity.setPriceWithoutTax(itemDto.getPriceWithoutTax());
                    itemEntity.setDiscountPct(itemDto.getDiscountPct());
                    itemEntity.setTaxLabel(itemDto.getTaxLabel());
                    itemEntity.setTaxPct(itemDto.getTaxPct());

                    // set backend calculated values
                    itemEntity.setDiscountAmount(calc.getDiscAmt());
                    itemEntity.setTaxableAmount(calc.getTaxable());
                    itemEntity.setCgstAmount(calc.getCgst());
                    itemEntity.setSgstAmount(calc.getSgst());
                    itemEntity.setTotalAmount(calc.getTotal());

                    return itemEntity;
                })
                .collect(Collectors.toList());

        // Step 4 — sum all rows for bill totals
        BigDecimal subTotal     = itemEntities.stream()
                .map(SaleInvoiceItem::getTaxableAmount)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        BigDecimal totalDiscount = itemEntities.stream()
                .map(SaleInvoiceItem::getDiscountAmount)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        BigDecimal totalCgst    = itemEntities.stream()
                .map(SaleInvoiceItem::getCgstAmount)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        BigDecimal totalSgst    = itemEntities.stream()
                .map(SaleInvoiceItem::getSgstAmount)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        BigDecimal totalAmount  = itemEntities.stream()
                .map(SaleInvoiceItem::getTotalAmount)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        // Step 5 — round off
        BigDecimal roundOffAmount = BigDecimal.ZERO;
        if (Boolean.TRUE.equals(request.getRoundOffEnabled())) {
            BigDecimal rounded = new BigDecimal(totalAmount.setScale(0, RoundingMode.HALF_UP).toPlainString());
            roundOffAmount = rounded.subtract(totalAmount).setScale(2, RoundingMode.HALF_UP);
        }
        BigDecimal grandTotal = totalAmount.add(roundOffAmount);

        // set totals into invoice
        invoice.setSubTotal(subTotal);
        invoice.setTotalDiscount(totalDiscount);
        invoice.setTotalCgst(totalCgst);
        invoice.setTotalSgst(totalSgst);
        invoice.setTotalAmount(totalAmount);
        invoice.setRoundOffAmount(roundOffAmount);
        invoice.setGrandTotal(grandTotal);

        // ── calculate and set balance ──        ← PASTE HERE
        BigDecimal receivedAmt = request.getAmountReceived() != null
                                 ? request.getAmountReceived()
                                 : BigDecimal.ZERO;
        BigDecimal balanceAmount = grandTotal.subtract(receivedAmt)
                                   .setScale(2, RoundingMode.HALF_UP);
        invoice.setBalanceAmount(balanceAmount);

        // Step 6 — save invoice first to get ID
        SaleInvoice savedInvoice = saleInvoiceRepository.save(invoice);

        // link items to invoice and save
        itemEntities.forEach(i -> i.setSaleInvoice(savedInvoice));
        saleInvoiceItemRepository.saveAll(itemEntities);

        // save payments if present
        if (request.getPayments() != null && !request.getPayments().isEmpty()) {
            List<SaleInvoicePayment> payments = request.getPayments()
                    .stream()
                    .map(p -> {
                        SaleInvoicePayment payment = new SaleInvoicePayment();
                        payment.setSaleInvoice(savedInvoice);
                        payment.setPaymentType(p.getPaymentType());
                        payment.setAmount(p.getAmount());
                        return payment;
                    })
                    .collect(Collectors.toList());
            saleInvoicePaymentRepository.saveAll(payments);
        }

        // return response
        return mapToResponseDto(savedInvoice, itemEntities, request.getPayments());
    }

    // ═══════════════════════════════════════════════
    // METHOD 2 — getBills()
    // ═══════════════════════════════════════════════
    // Get all bills for a company filtered by billType
    // Used for listing page
    // ═══════════════════════════════════════════════

    public List<SaleInvoiceResponseDto> getBills(
            String billType,
            String token) {

        String company = jwtUtil.getCompanyFromToken(token);

        List<SaleInvoice> invoices = saleInvoiceRepository
                .findByCompanyNameAndBillType(company, billType);

        return invoices.stream()
                .map(inv -> mapToResponseDto(inv, 
                     inv.getItems(), 
                     null))
                .collect(Collectors.toList());
    }

    // ═══════════════════════════════════════════════
    // METHOD 3 — getBillById()
    // ═══════════════════════════════════════════════
    // Get single bill with all items and payments
    // Used when user opens a bill to view or edit
    // ═══════════════════════════════════════════════

    public SaleInvoiceResponseDto getBillById(
            Long id,
            String token) {

        String company = jwtUtil.getCompanyFromToken(token);

        SaleInvoice invoice = saleInvoiceRepository
                .findByIdAndCompanyName(id, company);

        if (invoice == null) {
            throw new RuntimeException("Bill not found");
        }

        List<SaleInvoiceItem> items = saleInvoiceItemRepository
                .findBySaleInvoiceId(id);

        List<SaleInvoicePayment> payments = saleInvoicePaymentRepository
                .findBySaleInvoiceId(id);

        List<SaleInvoicePaymentDto> paymentDtos = payments.stream()
                .map(p -> new SaleInvoicePaymentDto(
                        p.getPaymentType(),
                        p.getAmount()))
                .collect(Collectors.toList());

        return mapToResponseDto(invoice, items, paymentDtos);
    }

    // ═══════════════════════════════════════════════
    // METHOD 4 — deleteBill()
    // ═══════════════════════════════════════════════
    // Delete bill + all its items + payments
    // cascade delete handled by @OneToMany
    // ═══════════════════════════════════════════════

    @Transactional
    public String deleteBill(Long id, String token) {

        String company = jwtUtil.getCompanyFromToken(token);

        SaleInvoice invoice = saleInvoiceRepository
                .findByIdAndCompanyName(id, company);

        if (invoice == null) {
            throw new RuntimeException("Bill not found");
        }

        saleInvoiceRepository.delete(invoice);
        return "Bill deleted successfully";
    }

    // ═══════════════════════════════════════════════
    // METHOD 5 — searchCustomer()
    // ═══════════════════════════════════════════════
    // Search customer by name or phone
    // Called when user types in party search field
    // Returns dropdown list
    // ═══════════════════════════════════════════════

    public List<CustomerSearchResponseDto> searchCustomer(
            String keyword,
            String token) {

        String company = jwtUtil.getCompanyFromToken(token);

        List<CustomerDetails> customers = customerRepository
                .searchByNameOrPhone(keyword, company);

        return customers.stream()
                .map(c -> new CustomerSearchResponseDto(
                        c.getId(),
                        c.getName(),
                        c.getPhone(),
                        c.getGstin(),
                        c.getState(),
                        c.getBillingAddress()))
                .collect(Collectors.toList());
    }

    // ═══════════════════════════════════════════════
    // METHOD 6 — searchItem()
    // ═══════════════════════════════════════════════
    // Search item by name or code
    // Called when user types in item search field
    // Returns item + pricing + tax for auto fill
    // ═══════════════════════════════════════════════

    public List<ItemSearchResponseDto> searchItem(
            String keyword,
            String token) {

        String company = jwtUtil.getCompanyFromToken(token);

        List<Item> items = itemRepository
                .searchByNameOrCode(keyword, company);

        return items.stream()
                .map(item -> {
                    ItemSearchResponseDto dto = new ItemSearchResponseDto();
                    dto.setItemId(item.getId());
                    dto.setItemName(item.getItemName());
                    dto.setItemCode(item.getItemCode());
                    dto.setItemHsn(item.getItemHsn());
                    dto.setUnit(item.getUnit() != null 
                                ? item.getUnit().getName() : "");

                    // get pricing for this item
                    itemPricingRepository.findByItemId(item.getId())
                            .ifPresent(pricing -> {
                                dto.setSalePrice(pricing.getSalePrice());
                                dto.setSalePriceTaxType(pricing.getSalePriceTaxType());
                                dto.setMrp(pricing.getMrp());
                                dto.setCalculateTaxOnMrp(pricing.getCalculateTaxOnMrp()); // ← add
                                dto.setAdditionalCessPerUnit(pricing.getAdditionalCessPerUnit());
                                dto.setDiscountOnSale(pricing.getDiscountOnSale());
                                dto.setDiscountType(pricing.getDiscountType());

                                // get tax details
                                if (pricing.getTax() != null) {
                                    dto.setTaxName(pricing.getTax().getName());
                                    dto.setTaxRate(pricing.getTax().getRate());
                                }
                            });

                    return dto;
                })
                .collect(Collectors.toList());
    }

    // ═══════════════════════════════════════════════
    // PRIVATE HELPER — mapToResponseDto()
    // ═══════════════════════════════════════════════
    // Converts SaleInvoice entity → ResponseDto
    // Used by saveBill, getBills, getBillById
    // ═══════════════════════════════════════════════

    private SaleInvoiceResponseDto mapToResponseDto(
            SaleInvoice invoice,
            List<SaleInvoiceItem> items,
            List<SaleInvoicePaymentDto> payments) {

        SaleInvoiceResponseDto dto = new SaleInvoiceResponseDto();
        dto.setId(invoice.getId());
        dto.setBillType(invoice.getBillType());
        dto.setInvoiceNumber(invoice.getInvoiceNumber());
        dto.setInvoiceDate(invoice.getInvoiceDate());
        dto.setPartyName(invoice.getPartyName());
        dto.setPhoneNo(invoice.getPhoneNo());
        dto.setPaymentMode(invoice.getPaymentMode());
        dto.setGrandTotal(invoice.getGrandTotal());
        dto.setAmountReceived(invoice.getAmountReceived());
        dto.setReceived(invoice.getReceived());
        dto.setBalanceAmount(invoice.getBalanceAmount());
        dto.setCreatedBy(invoice.getCreatedBy());
        dto.setCreatedAt(invoice.getCreatedAt());
        

        // map items
        List<SaleInvoiceItemDto> itemDtos = items.stream()
                .map(i -> {
                    SaleInvoiceItemDto itemDto = new SaleInvoiceItemDto();
                    itemDto.setLineNumber(i.getLineNumber());
                    itemDto.setItemName(i.getItemName());
                    itemDto.setItemCode(i.getItemCode());
                    itemDto.setModelNo(i.getModelNo());
                    itemDto.setMfgDate(i.getMfgDate());
                    itemDto.setExpDate(i.getExpDate());
                    itemDto.setMrp(i.getMrp());
                    itemDto.setSize(i.getSize());
                    itemDto.setAddCess(i.getAddCess());
                    itemDto.setHsnCode(i.getHsnCode());
                    itemDto.setQty(i.getQty());
                    itemDto.setUnit(i.getUnit());
                    itemDto.setPriceWithoutTax(i.getPriceWithoutTax());
                    itemDto.setDiscountPct(i.getDiscountPct());
                    itemDto.setDiscountAmount(i.getDiscountAmount());
                    itemDto.setTaxableAmount(i.getTaxableAmount());
                    itemDto.setTaxLabel(i.getTaxLabel());
                    itemDto.setTaxPct(i.getTaxPct());
                    itemDto.setCgstAmount(i.getCgstAmount());
                    itemDto.setSgstAmount(i.getSgstAmount());
                    itemDto.setTotalAmount(i.getTotalAmount());
                    return itemDto;
                })
                .collect(Collectors.toList());

        dto.setItems(itemDtos);
        dto.setPayments(payments);
        return dto;
    }

    
    public Integer getNextInvoiceNumber(String token) {
        String company = jwtUtil.getCompanyFromToken(token);
        SaleInvoice last = saleInvoiceRepository
            .findTopByCompanyNameOrderByIdDesc(company);
        return last != null ? last.getInvoiceNumber() + 1 : 1;
    }
    
    
    
 // ═══════════════════════════════════════════════
 // METHOD — getItemTransactions()
 // ═══════════════════════════════════════════════
 // Get all bills that contain a specific item
 // Called when user clicks an item in ViewItem page
 // Returns: billType, invoiceNo, partyName,
//           date, qty, amount, status
 // ═══════════════════════════════════════════════

 public List<ItemTransactionDto> getItemTransactions(
         String itemName,
         String token) {

     String company = jwtUtil.getCompanyFromToken(token);

     // get all sale_invoice_item rows matching itemName + company
     List<SaleInvoiceItem> itemRows = saleInvoiceItemRepository
             .findByItemNameAndCompanyName(itemName, company);

     // map each item row → parent invoice + this item's qty/amount
     return itemRows.stream()
             .map(row -> {
                 SaleInvoice inv = row.getSaleInvoice();
                 return new ItemTransactionDto(
                         inv.getId(),
                         inv.getBillType(),
                         inv.getInvoiceNumber(),
                         inv.getPartyName(),
                         inv.getInvoiceDate(),
                         row.getQty(),
                         row.getUnit(),
                         row.getTotalAmount(),
                         inv.getBalanceAmount()
                 );
             })
             .collect(Collectors.toList());
 }
    
 
 
 public List<SaleInvoiceResponseDto> getBillsFiltered(
	        String token,
	        LocalDate fromDate,
	        LocalDate toDate,
	        String createdBy,List<String> billTypes) {

	    String company = jwtUtil.getCompanyFromToken(token);
//	    List<String> billTypes = List.of("SALE", "POS");

	    List<SaleInvoice> invoices;

	    if (createdBy == null || createdBy.equals("All Users")) {
	        // no user filter
	        invoices = saleInvoiceRepository
	            .findByCompanyNameAndBillTypeInAndInvoiceDateBetween(
	                company, billTypes, fromDate, toDate);

	    } else if (createdBy.equals("Admin")) {
	        // get all ADMIN usernames for this company
	        List<String> adminUsernames = muserRepository
	            .findByRoleNameAndCompanyName("ADMIN", company)
	            .stream()
	            .map(u -> u.getUsername())
	            .collect(Collectors.toList());

	        invoices = saleInvoiceRepository
	            .findByCompanyNameAndBillTypeInAndInvoiceDateBetweenAndCreatedByIn(
	                company, billTypes, fromDate, toDate, adminUsernames);

	    } else {
	        // get all CASHIER usernames for this company
	        List<String> cashierUsernames = muserRepository
	            .findByRoleNameAndCompanyName("CASHIER", company)
	            .stream()
	            .map(u -> u.getUsername())
	            .collect(Collectors.toList());

	        invoices = saleInvoiceRepository
	            .findByCompanyNameAndBillTypeInAndInvoiceDateBetweenAndCreatedByIn(
	                company, billTypes, fromDate, toDate, cashierUsernames);
	    }

	    return invoices.stream()
	        .map(inv -> mapToResponseDto(inv, inv.getItems(), null))
	        .collect(Collectors.toList());
	} 
 
 public List<SaleInvoiceResponseDto> getPartyTransactions(
	        String partyName, String company) {
	    List<SaleInvoice> invoices = saleInvoiceRepository
	        .findByPartyNameAndCompanyName(partyName, company);
	    return invoices.stream()
	        .map(inv -> mapToResponseDto(inv, inv.getItems(), null))
	        .collect(Collectors.toList());
	}
    // ═══════════════════════════════════════════════
    // PRIVATE HELPER — RowCalculation inner class
    // ═══════════════════════════════════════════════

    @Data
    @AllArgsConstructor
    private static class RowCalculation {
        private BigDecimal grossAmt;
        private BigDecimal discAmt;
        private BigDecimal taxable;
        private BigDecimal cgst;
        private BigDecimal sgst;
        private BigDecimal total;
    }
}