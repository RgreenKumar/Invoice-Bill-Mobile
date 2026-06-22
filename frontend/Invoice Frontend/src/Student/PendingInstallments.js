// import React, { useEffect, useState } from 'react'
// import Swal from "sweetalert2";
// import withReactContent from "sweetalert2-react-content";
// import baseUrl from '../api/utils';
// import axios from 'axios';
// import { useNavigate } from 'react-router-dom';
// import SelectPaymentGateway from '../course/Payments/SelectPaymentGateway';

// const PendingInstallments = () => {
//     const navigate=useNavigate();
//     const token=sessionStorage.getItem("token")
//     const userId=sessionStorage.getItem("userid")
//         const [submitting, setsubmitting] = useState(false);
//     const MySwal = withReactContent(Swal);
//     const[pendings,setpendings]=useState([]);
//     useEffect(() => {
//         // Simulating fetching data from the server
//         const fetchData = async () => {
//           try {
//             // Fetch data from server
//             const response = await axios.get(`${baseUrl}/get/Pendings`,{
//               headers:{
//                 Authorization:token
//               }
//             });
//             if (response?.status === 200) {
//               const data = response.data;
//               setpendings(data);

//             } else if (response?.status === 204) {
//                 setpendings([]);
//             }           
//           } catch (error) {
//             if(error?.response?.status===401){
//               navigate("/unauthorized")
//             }
           
//           }
//         };
    
//         fetchData();
//       }, []);

//       const[openselectgateway,setopenselectgateway]=useState(false)
//       const[orderData,setorderData]=useState({
//         userId:"",
//         batchId:"",
//         amount:"" ,
//         batchAmount:"",
//         batchName:"",
//         installment:"",
//         paytype:"",
//         url:""
//     })
//     const FetchOrderSummary = async (batchId) => {
//       try {
//           setsubmitting(true);
    
//           // Prepare request data
//           const data = JSON.stringify({
//             batchId: batchId,
//             userId: userId,
//             paytype: 1, // 0->FULL 1->PART
//           });
    
//           // Make API call
//           const response = await axios.post(`${baseUrl}/Batch/getOrderSummary`, data, {
//             headers: {
//               Authorization: token,
//               "Content-Type": "application/json",
//             },
//           });
    
//           setsubmitting(false);
//           setorderData(response.data);
//           console.log(response.data)
//           setopenselectgateway(true);
        
//       } catch (error) {
//         setsubmitting(false);
//         setopenselectgateway(false);
    
//         if (error.response && error.response.status === 400) {
//           MySwal.fire({
//             icon: "error",
//             title: "Error creating order:",
//             text: error.response.data ? error.response.data : "An error occurred",
//           });
//         } else {
//           throw error;
//         }
//       }
//     };
//   return (
//     <div>
//        {submitting && (
//               <div className="outerspinner active">
//                 <div className="spinner"></div>
//               </div>
//             )}
//             {openselectgateway && (
//               <SelectPaymentGateway orderData={orderData} setorderData={setorderData} setopenselectgateway={setopenselectgateway}/>
//             )}
//     <div className="page-header"></div>
//     <div className='row'>
//       <div className='col-sm-12'>
//         <div className='card'>
//           <div className='card-header'>
//     <div className='navigateheaders'>
//       <div onClick={()=>{navigate(-1)}}><i className="fa-solid fa-arrow-left"></i></div>
//       <div></div>
//       <div onClick={()=>{navigate(-1)}}><i className="fa-solid fa-xmark"></i></div>
//       </div>
//       <h4>Pending Installments</h4>
//        </div>
//        <div className='card-body'>
//       <div className="table-container">
//         <table className="table table-hover table-bordered table-sm">
//           <thead className='thead-dark'>
//             <tr>
//             <th scope="col">Batch Name</th>
//               <th scope="col">Installment Number</th>
//               <th scope="col">Amount </th>
//               <th scope='col'>Last Date</th>
//               <th scope="col"> Action </th>
//             </tr>
//           </thead>
//           <tbody>
//           {pendings.map((pending) => (
//              <tr key={pending.id}>
//                 <td className='py-2'>{pending.batchName}</td>
//                 <td  className='py-2'> {pending.installmentNo}</td>
//                 <td className='py-2'>{pending.amount}</td>
//                 <td className='py-2'>{pending.lastDate}</td>
//                 <td className='py-2'><button className='btn btn-success'onClick={()=>{FetchOrderSummary(pending.batchId)}}>Pay Now</button></td>
               
//               </tr>
//             ))}
//           </tbody>
//         </table>
//       </div>
//       </div>
//       </div>
//       </div>
//     </div>
//   </div>
//   )
// }

// export default PendingInstallments