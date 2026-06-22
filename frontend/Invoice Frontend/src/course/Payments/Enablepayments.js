import React, { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import axios from 'axios';
import baseUrl from '../../api/utils';

const Enablepayments = () => {
  const navigate = useNavigate();
    const token = sessionStorage.getItem("token")
  const [paymentMethods, setPaymentMethods] = useState([]);
  const fetchpaymentTypedetails = async () => {
    try {
      const response = await axios.get(`${baseUrl}/get/paytypedetails`,{
        headers:{
          Authorization:token
        }
      });
     

      setPaymentMethods(response.data);
    } catch (error) {
      console.error('error', error);
      throw error
    }
  };
  useEffect(() => {
    fetchpaymentTypedetails();
  }, []);
  const handleChange = async (event) => {
    const { name, checked } = event.target;
  
    // Update state locally
    setPaymentMethods((prev) => ({
      ...prev,
      [name]: checked,
    }));
  
    if (token) {
      try {
        const response = await axios.post(
          `${baseUrl}/save/PayTypeDetails?isEnabled=${checked}&paymentTypeName=${name}`,
          null,
          {
            headers: {
              Authorization: token,
            },
          }
        );
  fetchpaymentTypedetails()
      } catch (error) {
        console.error('Error updating payment type:', error);
      }
    }
  };
  
  

  return (
    <div className="card"  >
      <div className="card-body" >
        <div className="row">
          <div className="col-12">
            <div className="navigateheaders">
              <div onClick={() => navigate(-1)}>
                <i className="fa-solid fa-arrow-left"></i>
              </div>
              <div></div>
              <div onClick={() => navigate(-1)}>
                <i className="fa-solid fa-xmark"></i>
              </div>
            </div>
            <h4>Payment Settings</h4>
            <div className="mt-4">
  <label>
    <input
      type="checkbox"
      className="mr-2"
      name="RAZORPAY"
      checked={paymentMethods.RAZORPAY || false} // Fallback to false
      onChange={handleChange}
    />
    Razorpay
  </label>
</div>
<div className="mt-4">
  <label>
    <input
      type="checkbox"
      className="mr-2"
      name="STRIPE"
      checked={paymentMethods.STRIPE || false} // Fallback to false
      onChange={handleChange}
    />
    Stripe
  </label>
</div>
<div className="mt-4">
  <label>
    <input
      type="checkbox"
      className="mr-2"
      name="PAYPAL"
      checked={paymentMethods.PAYPAL || false} // Fallback to false
      onChange={handleChange}
    />
    PayPal
  </label>
</div>
</div>
        </div>
      </div>
    </div>
  );
};

export default Enablepayments;
