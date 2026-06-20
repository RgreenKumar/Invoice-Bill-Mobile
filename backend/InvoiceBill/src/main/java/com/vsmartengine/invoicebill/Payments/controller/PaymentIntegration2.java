package com.vsmartengine.invoicebill.Payments.controller;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.Collections;
import java.util.Date;
import java.util.HashMap;
import java.util.Map;
import java.util.Optional;

import com.paypal.core.PayPalHttpClient;
import com.paypal.core.PayPalEnvironment;
import com.paypal.http.HttpResponse;
import com.paypal.orders.AmountWithBreakdown;
import com.paypal.orders.ApplicationContext;
import com.paypal.orders.LinkDescription;
import com.paypal.orders.Order;
import com.paypal.orders.OrderRequest;
import com.paypal.orders.OrdersCreateRequest;
import com.paypal.orders.OrdersGetRequest;
import com.paypal.orders.PurchaseUnitRequest;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import com.vsmartengine.invoicebill.Notification.Service.NotificationService;
import com.vsmartengine.invoicebill.Payments.Orderuser;
import com.vsmartengine.invoicebill.Payments.Paypalsettings;
import com.vsmartengine.invoicebill.Payments.repos.OrderuserRepo;
import com.vsmartengine.invoicebill.Payments.repos.paypalrepo;
import com.vsmartengine.invoicebill.User.Muser;
import com.vsmartengine.invoicebill.User.Repository.MuserRepositories;
import com.vsmartengine.invoicebill.User.SecurityConfiguration.JwtUtil;

import jakarta.servlet.http.HttpServletRequest;

@Service
public class PaymentIntegration2 {

    @Value("${currency}")
    private String currency;

    @Autowired
    private paypalrepo paypalrepo;

    @Value("${paypal.mode}")
    private String paypalMode;

    @Autowired
    private OrderuserRepo ordertablerepo;

    @Autowired
    private MuserRepositories muserRepository;

    @Autowired
    private NotificationService notiservice;

    @Autowired
    private JwtUtil jwtUtil;

    private static final String API_URL = "https://v6.exchangerate-api.com/v6/7bd3206191151fb9958f2ae9/pair/INR/USD/1";

    private static final Logger logger = LoggerFactory.getLogger(PaymentIntegration.class);

    public double convertINRtoUSD(double amountInINR) {
        try {
            RestTemplate restTemplate = new RestTemplate();
            String response = restTemplate.getForObject(API_URL, String.class);

            int startIdx = response.indexOf("conversion_rate") + 17;
            int endIdx = response.indexOf(",", startIdx);
            String conversionRateStr = response.substring(startIdx, endIdx).trim();

            double conversionRate = Double.parseDouble(conversionRateStr);
            double amountInUSD = amountInINR * conversionRate;

            BigDecimal roundedAmount = new BigDecimal(amountInUSD).setScale(2, RoundingMode.HALF_UP);

            System.out.println("Conversion Rate (INR to USD): " + conversionRate);
            System.out.println(amountInINR + " INR is approximately " + roundedAmount + " USD.");

            return roundedAmount.doubleValue();
        } catch (Exception e) {
            logger.error(e.getMessage());
            System.err.println("Error fetching conversion rate: " + e.getMessage());
            return -1;
        }
    }

    private Orderuser saveOrderDetails(String userName, String email, Long amt, String orderId, String status,
            String company, Long userId, Long installmentNumber, String PaymentType, String batchName,
            Long batchId) {
        Orderuser orderTable = new Orderuser();
        orderTable.setOrderId(orderId);
        orderTable.setUserId(userId);
        orderTable.setPaymentType(PaymentType);
        orderTable.setCompanyName(company);
        orderTable.setUsername(userName);
        orderTable.setBatchName(batchName);
        orderTable.setBatchId(batchId);
        orderTable.setEmail(email);
        orderTable.setInstallmentnumber(installmentNumber);
        orderTable.setDate(new java.util.Date());
        orderTable.setStatus(status);
        return ordertablerepo.save(orderTable);
    }

    public ResponseEntity<?> handlePaypalCheckout(String userName, String email, Long userid, String BatchName,
            Long batchId, Long installMentNumber, String companyName, Long amt, HttpServletRequest httpRequest) {
        try {
            Optional<Paypalsettings> opdataList = paypalrepo.FindByCompanyName(companyName);
            if (opdataList.isPresent()) {
                Paypalsettings data = opdataList.get();
                String clientId = data.getPaypal_client_id();
                String clientSecret = data.getPaypal_secret_key();

                String mode = paypalMode;
                PayPalHttpClient paypalClient;
                if ("live".equalsIgnoreCase(mode)) {
                    PayPalEnvironment environment = new PayPalEnvironment.Live(clientId, clientSecret);
                    paypalClient = new PayPalHttpClient(environment);
                } else {
                    PayPalEnvironment environment = new PayPalEnvironment.Sandbox(clientId, clientSecret);
                    paypalClient = new PayPalHttpClient(environment);
                }

                String clientBaseUrl = httpRequest.getHeader("Origin");
                if (clientBaseUrl == null) {
                    String referer = httpRequest.getHeader("Referer");
                    if (referer != null) {
                        System.out.println("Client Base URL: " + referer);
                        clientBaseUrl = referer.split("/")[0] + "//" + referer.split("/")[2];
                    }
                }

                System.out.println("Client Base URL: " + clientBaseUrl);

                String successUrl = clientBaseUrl + "/updatePaypalPayment";
                String cancelUrl = clientBaseUrl + "/dashboard/course";
                double amtfinal = amt;

                OrderRequest orderRequest = new OrderRequest();
                orderRequest.checkoutPaymentIntent("CAPTURE");
                if (currency.equals("INR")) {
                    amtfinal = this.convertINRtoUSD(amt);
                    if (amtfinal == -1) {
                        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Cannot Convert Amount to USD");
                    }
                }

                PurchaseUnitRequest purchaseUnit = new PurchaseUnitRequest()
                        .amountWithBreakdown(
                                new AmountWithBreakdown().currencyCode("USD").value(String.valueOf(amtfinal)))
                        .description(BatchName);
                orderRequest.purchaseUnits(Collections.singletonList(purchaseUnit));

                ApplicationContext appContext = new ApplicationContext()
                        .brandName(companyName)
                        .landingPage("BILLING")
                        .cancelUrl(cancelUrl)
                        .returnUrl(successUrl)
                        .userAction("PAY_NOW");
                orderRequest.applicationContext(appContext);

                OrdersCreateRequest paypalOrderRequest = new OrdersCreateRequest().requestBody(orderRequest);
                HttpResponse<Order> response = paypalClient.execute(paypalOrderRequest);

                if (response.statusCode() == 201) {
                    Order order = response.result();
                    saveOrderDetails(userName, email, amt, order.id(), "CREATED",
                            companyName, userid, installMentNumber, "PAYPAL", BatchName, batchId);
                    Map<String, String> approvalLink = new HashMap<>();
                    for (LinkDescription link : order.links()) {
                        if ("approve".equals(link.rel())) {
                            approvalLink.put("approvalUrl", link.href());
                            approvalLink.put("orderid", order.id());
                            break;
                        }
                    }
                    return ResponseEntity.ok(approvalLink);
                } else {
                    return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                            .body("Error: PayPal Order creation failed");
                }
            } else {
                return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("PayPal Payment details not found");
            }
        } catch (Exception e) {
            if (e.getMessage().contains("DECIMAL_PRECISION")) {
                System.out.println(e.getMessage());
                logger.error("Error with decimal precision: The amount has too many decimal places.");
                return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Invalid amount format.");
            } else {
                logger.error("Error creating Stripe Checkout: ", e);
                return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                        .body("Paypal keys are invalid. Please check your Paypal keys.");
            }
        }
    }

    public ResponseEntity<String> updatePayPalPayment(HttpServletRequest servletrequest,
            Map<String, String> requestData, String token) {
        try {
            String orderId = requestData.get("orderId");
            String payerId = requestData.get("PayerID");
            String paypalToken = requestData.get("token");

            if (orderId == null || payerId == null || paypalToken == null) {
                return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                        .body("Order ID, PayerID, or Token is missing");
            }

            Optional<Orderuser> orderUserOptional = ordertablerepo.findByOrderId(orderId);
            if (orderUserOptional.isPresent()) {
                Orderuser orderUser = orderUserOptional.get();

                PayPalHttpClient client = createPayPalHttpClient(token);
                if (client == null) {
                    return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Error Getting Payment details");
                }

                OrdersGetRequest request = new OrdersGetRequest(paypalToken);
                HttpResponse<Order> response = client.execute(request);
                Order order = response.result();

                if (order != null) {
                    String transactionId = order.id();
                    String amountString = order.purchaseUnits().get(0).amountWithBreakdown().value();
                    double amountPaidInCents = Double.parseDouble(amountString) * 100;
                    String status = order.status();

                    orderUser.setPaymentId(transactionId);
                    if (status.equals("APPROVED")) {
                        orderUser.setStatus("paid");
                    }
                    orderUser.setAmountReceived((int) amountPaidInCents);
                    orderUser.setDate(new Date());

                    ordertablerepo.save(orderUser);
                    return ResponseEntity.ok("Payment updated successfully.");
                } else {
                    return ResponseEntity.status(HttpStatus.NO_CONTENT).body("PayPal payment details not found");
                }
            } else {
                return ResponseEntity.status(HttpStatus.NO_CONTENT).body("Order not found");
            }
        } catch (Exception e) {
            e.printStackTrace();
            logger.error("General Error: ", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body("Error updating payment ID: " + e.getMessage());
        }
    }

    private PayPalHttpClient createPayPalHttpClient(String token) {
        String email = jwtUtil.getEmailFromToken(token);
        if (email.equals(null)) {
            return null;
        }
        String companyName = muserRepository.findcompanyByEmail(email);
        if (companyName.equals(null)) {
            return null;
        }
        Optional<Paypalsettings> keys = paypalrepo.FindByCompanyName(companyName);
        if (!keys.isPresent()) {
            return null;
        }
        Paypalsettings key = keys.get();
        PayPalEnvironment environment = new PayPalEnvironment.Sandbox(key.getPaypal_client_id(),
                key.getPaypal_secret_key());
        return new PayPalHttpClient(environment);
    }
}