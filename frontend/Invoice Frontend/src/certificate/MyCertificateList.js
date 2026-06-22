// import React, { useEffect, useState } from 'react';
// import baseUrl from '../api/utils';
// import axios from 'axios';
// import { useNavigate } from 'react-router-dom';

// const MyCertificateList = () => {
//     const [myCertificates, setMyCertificates] = useState([]);
//     const navigate=useNavigate();
//     useEffect(() => {
//         const fetchCertificates = async () => {
//             try {
//                 const token = sessionStorage.getItem("token");
//                 const certificateData = await axios.get(`${baseUrl}/certificate/getAllCertificate`, {
//                     headers: {
//                         Authorization: token
//                     }
//                 });
//                 if (certificateData.status===200) {
//                     const certificateJson =  certificateData.data;
//                     setMyCertificates(certificateJson);
//                 }
//             } catch (error) {
//                 console.error("Error fetching certificates:", error);
//                 throw error
//             }
//         };
//         fetchCertificates();
//     }, []);

//     return (
//         <div>
//         <div className="page-header"></div>
//         <div className='row'>
//           <div className='col-sm-12'>
//             <div className='card' >
//               <div className='card-header'>
//             <div className='navigateheaders'>
//       <div onClick={()=>{navigate(-1)}}><i className="fa-solid fa-arrow-left"></i></div>
//       <div></div>
//       <div onClick={()=>{navigate(-1)}}><i className="fa-solid fa-xmark"></i></div>
//       </div>
//         <div className="mt-4">
//             <h2>My Certificates</h2>
//             </div>
//             <div className='card-body'>
//             <div className="table-container">
//             <table className="table table-hover table-bordered table-sm ">
//                 <thead className='thead-dark'>
//                     <tr>
//                         <th scope="col" >S.No</th>
//                         <th scope="col" >Course Name</th>
//                         <th scope="col" >Percentage</th>
//                         <th scope="col" >Test Date</th>
//                         <th scope="col" >Certificate</th>
//                     </tr>
//                 </thead>
//                 <tbody>
//                 {  myCertificates.map((certificate, index) => (
//                         <tr key={index}>
//                             <td>{index + 1}</td>
//                             <td>{certificate.course}</td>
//                             <td>{certificate.percentage}</td>
//                             <td>{certificate.testDate}</td>
//                             <td><a href="#" onClick={(e)=>{e.preventDefault(); navigate(`/template/${certificate.activityId}`)}}><i className="fa-solid fa-download text-primary"></i></a></td>
//                         </tr>
//                     ))}
//                 </tbody>
//             </table>
//             </div>
//             </div>
//             </div>
//             </div>
//         </div>
//         </div>
//         </div>
//     );
// };

// export default MyCertificateList;
