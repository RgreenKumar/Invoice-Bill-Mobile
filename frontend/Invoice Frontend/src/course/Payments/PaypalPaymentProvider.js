import React from 'react'
import Swal from "sweetalert2";
import withReactContent from "sweetalert2-react-content";
import baseUrl from '../../api/utils';
import axios from 'axios';

const PaypalPaymentProvider = (orderData,setopenselectgateway) => {
    const MySwal = withReactContent(Swal);
    const token = sessionStorage.getItem("token");
    const handlePaymentPaypal = async () => {
        try{
         
          const data = JSON.stringify({
            batchId: orderData?.batchId,
            userId: orderData?.userId,
            paytypeL:orderData?.paytypeL
            });
         const url = "/full/buyBatch/create";
          const response = await axios.post(`${baseUrl}${url}?gateway=PAYPAL`, data, {
              headers: {
                Authorization: token,
                "Content-Type": "application/json",
              },
            });
            if (response.data && response.data.approvalUrl) {
                const approvalUrl = response?.data?.approvalUrl;
                const orderid=response?.data?.orderid;
                sessionStorage.setItem("PaypalOrderId",orderid);
                window.location.href = approvalUrl;
              } else {
                setopenselectgateway(false)
                console.error("Error: PayPal approval URL not found in response.");
              }
        }catch(error){
          setopenselectgateway(false)
          if(error.response && error.response.status===400){
         
            MySwal.fire({
              icon: "error",
              title: "Error creating order:",
              text: error.response.data ? error.response.data : "error occured",
            });
          }else{
            throw error
          }
        }
      };
  
  return {handlePaymentPaypal}
}

export default PaypalPaymentProvider