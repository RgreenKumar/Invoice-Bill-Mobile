// import React, { useEffect, useState } from 'react'
// import baseUrl from '../api/utils';
// import axios from 'axios';

// const DisplaysocialLogin = () => {
//     const [showSocialLogin, setshowSocialLogin] = useState(false); // State to hold the checkbox state
//     const token=sessionStorage.getItem("token")
//       // Fetch the current setting from the backend on component mount
//       useEffect(() => {
//         const fetchshowSocialLogin = async () => {
//           try {
//             const response = await axios.get(`${baseUrl}/settings/ShowSocialLogin`);
//             setshowSocialLogin(response.data); // Assuming the response contains the boolean value directly
//           } catch (error) {
//             console.error('Error fetching the show in landing page status:', error);
//             throw error
//           }
//         };
    
//         fetchshowSocialLogin();
//       }, []);
    
//       // Handle the checkbox change event
//       const handleCheckboxChange = async (event) => {
//         try { 
//           const isChecked = event.target.checked;
//           await axios.post(`${baseUrl}/settings/ShowSocialLogin`, isChecked,{
//             headers: {
//               'Content-Type': 'application/json',
//               Authorization: token,
//             },
//           });
//           setshowSocialLogin(isChecked); // Update the local state
//         } catch (error) {
          
//           console.error('Error updating the show in landing page status:', error);
//           throw error
      
//         }
//       };
    
//   return (
//     <div className='mt-4'>
//     <label>
//       <input
//         type="checkbox"
//         checked={showSocialLogin} // Bind the checkbox value to state
//         onChange={handleCheckboxChange} // Handle checkbox changes
//         className='mr-2'
//       />
//        Enable/Disable Social Login
//     </label>
//   </div>
//   )
// }

// export default DisplaysocialLogin