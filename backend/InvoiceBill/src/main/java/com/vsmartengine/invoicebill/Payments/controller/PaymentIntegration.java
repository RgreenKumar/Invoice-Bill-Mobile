package com.vsmartengine.invoicebill.Payments.controller;

import java.util.Date;
import java.util.Map;
import java.util.Optional;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;

import com.razorpay.Order;
import com.razorpay.RazorpayClient;
import com.stripe.Stripe;
import com.stripe.model.PaymentIntent;
import com.stripe.model.checkout.Session;
import com.vsmartengine.invoicebill.Notification.Service.NotificationService;
import com.vsmartengine.invoicebill.Payments.Orderuser;
import com.vsmartengine.invoicebill.Payments.Paymentsettings;
import com.vsmartengine.invoicebill.Payments.Stripesettings;
import com.vsmartengine.invoicebill.Payments.repos.OrderuserRepo;
import com.vsmartengine.invoicebill.Payments.repos.PaymentsettingRepository;
import com.vsmartengine.invoicebill.Payments.repos.Striperepo;
import com.vsmartengine.invoicebill.User.Muser;
import com.vsmartengine.invoicebill.User.Repository.MuserRepositories;
import com.vsmartengine.invoicebill.User.SecurityConfiguration.JwtUtil;

import jakarta.servlet.http.HttpServletRequest;

@Service
public class PaymentIntegration {

    @Value("${currency}")
    private String currency;

    @Autowired
    private JwtUtil jwtUtil;

    @Autowired
    private PaymentsettingRepository paymentsetting;

    @Autowired
    private OrderuserRepo ordertablerepo;

    @Autowired
    private MuserRepositories muserRepository;

    @Autowired
    private NotificationService notiservice;

    @Autowired
    private Striperepo stripereop;

    private static final Logger logger = LoggerFactory.getLogger(PaymentIntegration.class);

    public Paymentsettings getpaydetails(String token) {
        try {
            String email = jwtUtil.getEmailFromToken(token);
            Optional<Muser> opreq = muserRepository.findByEmail(email);
            String company = "";
            if (opreq.isPresent()) {
                Muser requser = opreq.get();
                company = requser.getCompanyName();
            }
            Optional<Paymentsettings> opdataList = paymentsetting.findBycompanyName(company);
            if (opdataList.isPresent()) {
                return opdataList.get();
            } else {
                return null;
            }
        } catch (Exception e) {
            e.printStackTrace();
            logger.error("", e);
            return null;
        }
    }

    public ResponseEntity<String> updateStripepaymentid(HttpServletRequest request, Map<String, String> requestData,
            String token) {
        try {
            String sessionId = requestData.get("sessionId");
            if (sessionId == null) {
                return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Session id is missing");
            }
            Optional<Orderuser> orderUserOptional = ordertablerepo.findByOrderId(sessionId);
            if (orderUserOptional.isPresent()) {
                Orderuser orderUser = orderUserOptional.get();
                Optional<Stripesettings> opdataList = stripereop.findBycompanyName(orderUser.getCompanyName());
                if (opdataList.isPresent()) {
                    Stripesettings data = opdataList.get();
                    String stripeApiKey = data.getStripe_secret_key();
                    Stripe.apiKey = stripeApiKey;

                    Session session = Session.retrieve(sessionId);
                    String paymentIntentId = session.getPaymentIntent();
                    PaymentIntent paymentIntent = PaymentIntent.retrieve(paymentIntentId);

                    long amountPaidInCents = paymentIntent.getAmountReceived();
                    int amountPaidIn = (int) (amountPaidInCents / 100);
                    String status = paymentIntent.getStatus();

                    orderUser.setPaymentId(paymentIntentId);
                    if (status.equals("succeeded")) {
                        orderUser.setStatus("paid");
                    }
                    orderUser.setAmountReceived(amountPaidIn);

                    if (paymentIntent.getCreated() != null) {
                        Date paymentDate = new Date(paymentIntent.getCreated() * 1000L);
                        orderUser.setDate(paymentDate);
                    }

                    ordertablerepo.save(orderUser);
                    return ResponseEntity.ok("Payment updated successfully.");
                } else {
                    return ResponseEntity.status(HttpStatus.NOT_FOUND).body("Payment details not found");
                }
            } else {
                return ResponseEntity.status(HttpStatus.NOT_FOUND).body("Order not found");
            }
        } catch (Exception e) {
            e.printStackTrace();
            logger.error("", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body("Error updating payment ID: " + e.getMessage());
        }
    }

    public ResponseEntity<String> updatePaymentId(HttpServletRequest request, Map<String, String> requestData,
            String token) {
        try {
            String orderId = requestData.get("orderId");
            String paymentId = requestData.get("paymentId");
            if (orderId == null || paymentId == null) {
                return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Some Values are missing");
            }

            Optional<Orderuser> orderUserOptional = ordertablerepo.findByOrderId(orderId);
            if (orderUserOptional.isPresent()) {
                Orderuser orderUser = orderUserOptional.get();
                orderUser.setPaymentId(paymentId);
                if (getpaydetails(token) != null) {
                    String razorpayApiKey = getpaydetails(token).getRazorpay_key();
                    String razorpayApiSecret = getpaydetails(token).getRazorpay_secret_key();

                    RazorpayClient client = new RazorpayClient(razorpayApiKey, razorpayApiSecret);
                    Order detailedOrder = client.orders.fetch(orderId);
                    String amountPaidString = detailedOrder.get("amount_paid").toString();
                    int amountPaidIn = Integer.parseInt(amountPaidString) / 100;
                    String status = detailedOrder.get("status").toString();
                    orderUser.setStatus(status);
                    orderUser.setAmountReceived(amountPaidIn);
                    if (detailedOrder.has("created_at")) {
                        Date paymentDate = detailedOrder.get("created_at");
                        orderUser.setDate(paymentDate);
                    }

                    ordertablerepo.save(orderUser);
                    return ResponseEntity.ok("Payment updated successfully.");
                } else {
                    return ResponseEntity.status(HttpStatus.NOT_FOUND).body("Pay details not found");
                }
            } else {
                return ResponseEntity.status(HttpStatus.NOT_FOUND).body("Order not found");
            }
        } catch (Exception e) {
            e.printStackTrace();
            logger.error("", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body("Error updating payment ID: " + e.getMessage());
        }
    }
}