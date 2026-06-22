// import React, { useEffect, useState } from 'react'
// import baseUrl from '../api/utils';
// import axios from 'axios';

// const AttendanceThresholdMinutes = () => {
//     const token=sessionStorage.getItem("token");
//     const[AttendanceTheresold,setattendanceThreshold]=useState(0);
//     useEffect(() => {
//         const fetchAttendanceThreshold = async () => {
//           try {
//             const response = await axios.get(`${baseUrl}/settings/AttendanceThresholdMinutes`);
//             setattendanceThreshold(response.data); // Assuming the response contains the boolean value directly
//           } catch (error) {
//             console.error('Error fetching Attendance Threshold  status:', error);
//             throw error
//           }
//         };
    
//         fetchAttendanceThreshold();
//       }, []);
//       const handleThresholdChange = async (event) => {
//         const minutes = parseInt(event.target.value, 10);
//         try {
//           await axios.post(
//             `${baseUrl}/settings/updateAttendanceThreshold`,
//             minutes,
//             {
//               headers: {
//                 "Content-Type": "application/json",
//                 Authorization: token,
//               },
//             }
//           );
//           setattendanceThreshold(minutes);
//         } catch (error) {
//           console.error("Error updating attendance threshold:", error);
//         }
//       };
//   return (
//     <div className='mt-4 mb-3'>
//       <div style={{ display: "flex", alignItems: "center", gap: "10px", flexWrap: "wrap" }}>
//   <label>Mark absent for students joining after</label>
//   <select
//     className="btn btn-light"
//     style={{ width: "80px" }}
//     value={AttendanceTheresold}
//     onChange={handleThresholdChange}
//   >
//     {[10, 15, 20,25,30].map((min) => (
//       <option key={min} value={min}>
//         {min}
//       </option>
//     ))}
//   </select>
//   <span>minutes from the meeting start.</span>
// </div>

//         </div>
//   )
// }

// export default AttendanceThresholdMinutes