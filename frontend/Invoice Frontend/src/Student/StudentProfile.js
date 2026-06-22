// import React, { useContext, useEffect, useState } from 'react'
// import { useLocation, useNavigate, useParams } from 'react-router-dom';
// import baseUrl from '../api/utils';
// import axios from 'axios';
// import { GlobalStateContext } from "../Context/GlobalStateProvider";

// import Profile from "./Profile";
// const StudentProfile = () => {
//   const { studentemail } = useParams();
//   const navigate=useNavigate();
//   const token=sessionStorage.getItem("token");
// const role=sessionStorage.getItem("role");
// const [notfound,setnotfound]=useState(false);
// const { displayname } = useContext(GlobalStateContext);
// const location = useLocation();
// const [initialUserData, setInitialUserData] = useState(location.state?.user || null);
//   const [img, setimg] = useState();
//   const [userData, setUserData] = useState({

//      username:"",
//      email:"",
//      phone:"",
//      skills:"",
//      dob:"",
//      countryCode:"",
//       roleName:"",
//       profile:null,
//     });

//     useEffect(() => {
//       const fetchData = async () => {
//         if (role === "ADMIN" || role === "TRAINER") {
//           try {
//             let fetchedInitialUserData = initialUserData;
            
//             // Fetch initialUserData if it's not available from location.state
//             if (!fetchedInitialUserData) {
//               const detailsRes = await axios.get(`${baseUrl}/details/${studentemail}`, {
//                 headers: { Authorization: token },
//               });
//               fetchedInitialUserData = detailsRes.data;
//               setInitialUserData(fetchedInitialUserData);
//             }
            
//             // Fetch additional user data
//             if (fetchedInitialUserData) {
//               setUserData(prevData =>  ({
//                 ...prevData,
//                 ...fetchedInitialUserData,
//               }));
//               const email = fetchedInitialUserData.email;
//               const response = await axios.get(`${baseUrl}/student/admin/getstudent/${email}`, {
//                 headers: { Authorization: token },
//               });
    
//               if (response.status === 200) {
//                 const serverData = response.data;
    
//                 // Merge initialUserData and serverData into userData
//                 setUserData(prevData => {
//                   const updatedData = { ...prevData,  ...serverData };
//                   if (updatedData.profile) {
//                     setimg(`data:image/jpeg;base64,${updatedData.profile}`);
//                   }
//                   return updatedData;
//                 });
//               }
//             }
//           } catch (error) {
//             if (error.response) {
//               if (error.response.status === 404) {
//                 setnotfound(true);
//               } else if (error.response.status === 401) {
//                 navigate("/unauthorized")
//               }else{
//                 throw error
//               }
//             }
//           }
//         } else {
//           navigate("/unauthorized")
//         }
//       };
    
//       fetchData();
//     }, []);

//   return (
//     <div>
//     <div className="page-header"></div>
//     <div className="card">
//       <div className="card-body">
//       <div className="row">
//       <div className="col-12">
//     <div className='navigateheaders'>
//       <div onClick={()=>{navigate(-1)}}><i className="fa-solid fa-arrow-left"></i></div>
//       <div></div>
//       <div onClick={()=>{navigate("/view/Students")}}><i className="fa-solid fa-xmark"></i></div>
//       </div>
//        <Profile notfound={notfound} displayname={displayname} userData={userData} img={img}/>
//   </div>
//   </div>
//   </div>
//   </div>
// </div>

  
//   )
// }

// export default StudentProfile
