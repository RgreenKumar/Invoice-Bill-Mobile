// import React, { useEffect, useState } from 'react';
// import axios from 'axios';
// import baseUrl from '../api/utils';

// const DisplayCourses = () => {
//   // const [showInLandingPage, setShowInLandingPage] = useState(false); // State to hold the checkbox state
// const token=sessionStorage.getItem("token")
//   // Fetch the current setting from the backend on component mount
//   // useEffect(() => {
//   //   const fetchShowInLandingPage = async () => {
//   //     try {
//   //       const response = await axios.get(`${baseUrl}/settings/viewCourseInLanding`);
//   //       setShowInLandingPage(response.data); // Assuming the response contains the boolean value directly
//   //     } catch (error) {
//   //       console.error('Error fetching the show in landing page status:', error);
//   //       throw error
//   //     }
//   //   };

//   //   fetchShowInLandingPage();
//   // }, []);

//   // Handle the checkbox change event
//   const handleCheckboxChange = async (event) => {
//     try { 
//       const isChecked = event.target.checked;
//       await axios.post(`${baseUrl}/settings/viewCourseInLanding`, isChecked,{
//         headers: {
//           'Content-Type': 'application/json',
//           Authorization: token,
//         },
//       });
//       setShowInLandingPage(isChecked); // Update the local state
//     } catch (error) {
      
//       console.error('Error updating the show in landing page status:', error);
//       throw error
  
//     }
//   };

//   return (
//     <div className='mt-4'>
//       <label>
//         <input
//           type="checkbox"
//           checked={showInLandingPage} // Bind the checkbox value to state
//           onChange={handleCheckboxChange} // Handle checkbox changes
//           className='mr-2'
//         />
//          Show Courses in Landing Page
//       </label>
//     </div>
//   );
// };

// export default DisplayCourses;
