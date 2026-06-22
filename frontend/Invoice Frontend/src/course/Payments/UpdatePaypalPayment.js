import axios from 'axios';
import React, { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import MySwal from 'sweetalert2';
import baseUrl from '../../api/utils';
const UpdatePaypalPayment = () => {
const PaypalOrderId = sessionStorage.getItem("PaypalOrderId");
const token = sessionStorage.getItem("token");
const [loading, setLoading] = useState(true);
const [error, setError] = useState(null); // State for error
const navigate = useNavigate();

const copyToClipboard = (text) => {
  navigator.clipboard.writeText(text);
  MySwal.fire({
    title: "Copied!",
    text: "Session ID copied to clipboard.",
    icon: "success",
    confirmButtonText: "OK",
  });
};
const urlParams = new URLSearchParams(window.location.search);
const Paypaltoken = urlParams.get('token');
const payerId = urlParams.get('PayerID');
useEffect(() => {
    // Extract query parameters from the URL

  
    // Now you can use the token and payerId as needed
    if (Paypaltoken && payerId) {
     
      updatePayment(Paypaltoken, payerId);
    }
  }, []);
  

const updatePayment = async (Paypaltoken, payerId) => {
    try {
        if(!token){
            return
        }
      setLoading(true);
      const data = JSON.stringify({
        orderId: PaypalOrderId,
        PayerID: payerId,
        token: Paypaltoken
      });
  
      const response = await axios.post(
        `${baseUrl}/buyCourse/updatePaypalPaymentId`,
        data,
        {
          headers: {
            'Content-Type': 'application/json',
            'Authorization': token,  // Use the token to authorize
          },
        }
      );
  
      const responseData = response.data;
      sessionStorage.removeItem("PaypalOrderId");
  
      MySwal.fire({
        title: "Saved!",
        text: "Payment details updated successfully.",
        icon: "success",
        confirmButtonText: "OK",
      })
      .then(() => {
       window.location.href="/mycourses"
      });
    } catch (error) {
      setLoading(false);
      setError(error.response?.data || 'Failed to update payment details.');
      MySwal.fire({
        title: "Error!",
        text: error.response?.data || 'Failed to update payment details.',
        icon: "error",
        confirmButtonText: "OK",
      });
    }
  };
  

return (
  <div className='vh-100' style={{ backgroundColor: "transparent", padding: "50px" }}>
    <div className="card">
      <div className='card-body' style={{ height: "75vh" }}>
        <div className="text-center mt-5">
          {loading ? (
            <h4>Updating your payment, please do not close the window...</h4>
            
          ) : (
            <div>
              <h4>Error updating Payment details. Kindly contact the administrator.</h4>
              {PaypalOrderId && (
               <div>
                  <p>
                    <strong>order ID:</strong>{" "}

                    <span> {PaypalOrderId}</span>
                    <span
                      style={{  cursor: "pointer"}}
                      onClick={() => copyToClipboard(PaypalOrderId)}
                    >
                        <i className="fa-solid fa-copy"></i>
                     
                    </span>

                    <strong>PayerID:</strong>
                    <span>    {payerId}</span>
                    <span
                      style={{  cursor: "pointer", textDecoration: "underline" }}
                      onClick={() => copyToClipboard(payerId)}
                    >
                        <i className="fa-solid fa-copy"></i>
                  
                    </span>
                    <strong>Token:</strong>
                    <span>  {Paypaltoken}</span>
                    <span
                      style={{  cursor: "pointer", textDecoration: "underline" }}
                      onClick={() => copyToClipboard(Paypaltoken)}
                    >
                        <i className="fa-solid fa-copy"></i>
                    
                    </span>
                  </p>
                  <p>
                    Please copy the above <strong>Session ID</strong> and share it with the administrator for troubleshooting.
                  </p>
                </div>
              )}
            </div>
          )}
        </div>
      </div>
    </div>
  </div>
);
};

export default UpdatePaypalPayment;
