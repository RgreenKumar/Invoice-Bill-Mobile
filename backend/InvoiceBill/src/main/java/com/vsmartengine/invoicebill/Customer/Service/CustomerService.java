package com.vsmartengine.invoicebill.Customer.Service;

import com.vsmartengine.invoicebill.Customer.Entity.CustomerDetails;
import com.vsmartengine.invoicebill.Customer.Entity.CustomerDetailsDto;
import com.vsmartengine.invoicebill.Customer.Repository.CustomerRepository;
import com.vsmartengine.invoicebill.SaleInvoice.Entity.SaleInvoice;
import com.vsmartengine.invoicebill.SaleInvoice.Entity.SaleInvoiceResponseDto;
import com.vsmartengine.invoicebill.SaleInvoice.Repository.SaleInvoiceRepository;
import com.vsmartengine.invoicebill.SaleInvoice.Service.SaleInvoiceService;
import com.vsmartengine.invoicebill.User.SecurityConfiguration.JwtUtil;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class CustomerService {

    private final CustomerRepository customerRepository;
    private final SaleInvoiceService saleInvoiceService;


    private final JwtUtil jwtUtil;

    // Add new Supplier or Customer — ADMIN only
    public CustomerDetails addParty(CustomerDetailsDto dto,
                                    String token) {
        String role = jwtUtil.getRoleFromToken(token);
        if (!"ADMIN".equals(role)) {
            return null; // CASHIER cannot add
        }

        String company = jwtUtil.getCompanyFromToken(token);

        CustomerDetails party = new CustomerDetails();
        party.setCompany(company);
        party.setName(dto.getName());
        party.setGstin(dto.getGstin());
        party.setPhone(dto.getPhone());
        party.setEmail(dto.getEmail());
        party.setGstType(dto.getGstType());
        party.setState(dto.getState());
        party.setBillingAddress(dto.getBillingAddress());
        party.setShippingAddress(dto.getShippingAddress());
        party.setOpeningBalance(dto.getOpeningBalance());
        party.setAsOfDate(dto.getAsOfDate());
        party.setCreditLimit(dto.getCreditLimit());
        party.setCreditAmount(dto.getCreditAmount());
        party.setAadhaarNo(dto.getAadhaarNo());
        party.setDrugLicenseNo(dto.getDrugLicenseNo());
        party.setPanNo(dto.getPanNo());
        party.setPartyType(dto.getPartyType());
       
        return customerRepository.save(party);
    }

    // Get all Suppliers — ADMIN and CASHIER
    public List<CustomerDetails> getSuppliers(String token) {
        String company = jwtUtil.getCompanyFromToken(token);
        return customerRepository
            .findByCompanyAndPartyTypeAndIsActive(
                company,
                "SUPPLIER",
                true
            );
    }

    // Get all Customers — ADMIN and CASHIER
    public List<CustomerDetails> getCustomers(String token) {
        String company = jwtUtil.getCompanyFromToken(token);
        return customerRepository
            .findByCompanyAndPartyTypeAndIsActive(
                company,
                "CUSTOMER",
                true
            );
    }

    // Get single party — ADMIN and CASHIER
    public CustomerDetails getPartyById(Long id, String token) {
        String company = jwtUtil.getCompanyFromToken(token);
        return customerRepository
            .findByIdAndCompany(id, company);
    }
    
    
    public List<SaleInvoiceResponseDto> getPartyTransactions(
            String partyName, String token) {
        String company = jwtUtil.getCompanyFromToken(token);
        return saleInvoiceService.getPartyTransactions(partyName, company);
    }

}