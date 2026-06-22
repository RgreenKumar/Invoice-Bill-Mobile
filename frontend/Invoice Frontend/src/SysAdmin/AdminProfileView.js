// import profile from "../images/profile.png";
// import React, { useContext, useEffect, useState } from "react";
// import { useLocation, useNavigate, useParams } from "react-router-dom";
// import baseUrl from "../api/utils";
// import axios from "axios";

// const AdminProfileView = () => {
//   const navigate = useNavigate();
//   const token = sessionStorage.getItem("token");
//   const role = sessionStorage.getItem("role");
//   const [notfound, setNotFound] = useState(false);
//   const [img, setImg] = useState(null);
//   const { adminemail } = useParams();
//   const location = useLocation();
//   const [licenceDetails, setLicenceDetails] = useState({});
//   const [initialUserData, setInitialUserData] = useState(
//     location.state?.user || null
//   );
//   const [LicenceNotfound, setLicenceNotfound] = useState(true);
//   const [userData, setUserData] = useState({
//     username: "",
//     email: "",
//     phone: "",
//     gstinNumber: "",
//     dob: "",
//     countryCode: "",
//     profile: null,
//     roleName: "",
//     lastactive: "",
//   });

//   useEffect(() => {
//     const fetchData = async () => {
//       if (role === "SYSADMIN") {
//         try {
//           let fetchedInitialUserData = initialUserData;

//           // Fetch initialUserData if it's not available from location.state
//           if (!fetchedInitialUserData) {
//             const detailsRes = await axios.get(
//               `${baseUrl}/details/${adminemail}`,
//               {
//                 headers: { Authorization: token },
//               }
//             );
//             fetchedInitialUserData = detailsRes.data;
//             setInitialUserData(fetchedInitialUserData);
//           }

//           // Fetch additional user data
//           if (fetchedInitialUserData) {
//             setUserData((prevData) => ({
//               ...prevData,
//               ...fetchedInitialUserData,
//             }));
//             const email = fetchedInitialUserData.email;
//             const response = await axios.get(
//               `${baseUrl}/student/getadmin/${email}`,
//               {
//                 headers: { Authorization: token },
//               }
//             );

//             if (response.status === 200) {
//               const serverData = response.data;

//               if (serverData.profile) {
//                 setImg(`data:image/jpeg;base64,${serverData.profile}`);
//               }
//               setUserData((prevData) => ({
//                 ...prevData,
//                 ...serverData,
//               }));
//             }
//           }
//         } catch (error) {
//           if (error.response) {
//             if (error.response.status === 404) {
//               setNotFound(true);
//             } else if (error.response.status === 401) {
//               navigate("/unauthorized")
//             }else{
//               throw error
//             }
//           }
//         }
//       } else if (role === "TRAINER") {
//         navigate("/unauthorized")
//       }
//     };

//     fetchData();
//   }, [initialUserData, adminemail, role, token]);
//   useEffect(() => {
//     const fetchlicencedetailsforadmin = async () => {
//       try {
//         const response = await axios.get(
//           `${baseUrl}/licence/getinfo/${adminemail}`,
//           {
//             headers: {
//               Authorization: token,
//             },
//           }
//         );
//         const { data } = response; // Destructure data from response
//         setLicenceNotfound(false);
//         // Filter out unwanted properties
//         const filteredData = {
//           ProductName: data.product_name,
//           CompanyName: data.company_name,
//           trainer: data.trainer, // Assuming Contact refers to trainer
//           student: data.students,
//           course: data.course,
//           Email: data.email, // Assuming email property exists
//           version: data.version, // Assuming version property exists
//           Type: data.type,
//           StartDate: data.start_date
//             ? new Date(data.start_date).toLocaleDateString()
//             : "NA",
//           EndDate: data.end_date
//             ? new Date(data.end_date).toLocaleDateString()
//             : "NA",
//           StorageSize: `${data.storagesize || 0} GB`, // Handle null storage size
//         };

//         setLicenceDetails(filteredData);
//       } catch (error) {
//         if (error.response) {
//           if (error.response.status === 404) {
//             setLicenceNotfound(true);
//           } else {
//             console.log(error);
//             throw error
//           }
//         }
//       }
//     };
//     fetchlicencedetailsforadmin();
//   }, []);
//   return (
//     <div>
//     <div className="page-header"></div>
//     <div className="card">
//       <div className="card-body">
  
//         <div className="navigateheaders">
//           <div
//             onClick={() => {
//               navigate(-1);
//             }}
//           >
//             <i className="fa-solid fa-arrow-left"></i>
//           </div>
//           <div></div>
//           <div
//             onClick={() => {
//               navigate("/view/Trainer");
//             }}
//           >
//             <i className="fa-solid fa-xmark"></i>
//           </div>
//         </div>
//         {notfound ? (
//           <h1 style={{ textAlign: "center", marginTop: "250px" }}>
//             No Admin found with the email
//           </h1>
//         ) : (
//           <div className="innerFrame">
//             <h4>Admin Profile</h4>
//             <div className="mainform">
//               <div className="profile-picture">
//                 <div className="image-group">
//                   <img
//                     id="preview"
//                     src={img || profile}
//                     alt="profile"
//                     onError={(e) => (e.target.src = profile)} // Handle image load error
//                   />
//                 </div>
//               </div>
//               <div
//                 style={{
//                   backgroundColor: "#F2E1F5",
//                   padding: "10px",
//                   paddingLeft: "20px",
//                   borderRadius: "20px",
//                 }}
//               >
//               {userData.lastactive &&
//               <div style={{ display: 'flex', alignItems: 'center' }} >
//                   <div
                 
//                 >
//                  {(new Date() - new Date(userData.lastactive)) /
//                     (1000 * 60 * 60 * 24) <=
//                   7
//                     ? <i className="fa-solid fa-circle text-success"></i>
//                     : <i className="fa-solid fa-circle text-danger"></i>}
//                 </div>
//                 <div className="small ml-2">
//   {"Last Active: " +
//     (new Date(userData.lastactive).toDateString() === new Date().toDateString()
//       ? "Today"
//       : new Date(userData.lastactive).toDateString() === new Date(Date.now() - 86400000).toDateString()
//       ? "Yesterday"
//       : new Date(userData.lastactive).toLocaleDateString()) +
//     " at " +
//     new Date(userData.lastactive).toLocaleTimeString()}
// </div>
// </div>}

//                 <div className="form-group row">
//                   <label htmlFor="Name" className="col-sm-3 col-form-label"><b>Name :</b></label>
//                   <div className="col-sm-9">
//                   <label className="col-form-label">{userData.username}</label>
//                </div> 
//                </div>
//                 <div className="form-group row">
//                   <label htmlFor="email" className="col-sm-3 col-form-label"><b>Email :</b></label>
//                   <div className="col-sm-9">
//                   <label className="col-form-label">{userData.email}</label>
//                </div> </div>
//                 <div className="form-group row">
//                   <label htmlFor="dob" className="col-sm-3 col-form-label"><b>Date of Birth :</b></label>
//                   <div className="col-sm-9">
//           <label className="col-form-label">{userData.dob}</label>
//               </div>  </div>
//                 <div className="form-group row">
//                   <label htmlFor="gstinNumber" className="col-sm-3 col-form-label"><b>Gstin Number:</b></label>
//                   <div className="col-sm-9">
//           <label className="col-form-label">{userData.gstinNumber}</label>
//               </div>  </div>

//                 <div className="form-group row">
//                   <label htmlFor="Phone" className="col-sm-3 col-form-label"><b>Phone :</b></label>
//                   <div className="col-sm-9">
//           <label className="col-form-label">
//                     {userData.countryCode}
//                     {userData.phone}
//                   </label>
//                   </div>
//                 </div>
//                 <div className="form-group row">
//                   <label htmlFor="role" className="col-sm-3 col-form-label"><b>RoleName :</b></label>
//                   <div className="col-sm-9">
//           <label className="col-form-label">Admin</label>
//                 </div></div>
//               </div>
//             </div>
//             {LicenceNotfound ? (
//               <h1 style={{ textAlign: "center", marginTop: "20px" }}>
//                 No Licence found with the email
//               </h1>
//             ) : (
//               <div className="mt-5">
//                 <h2
//                   style={{ textDecoration: "underline", textAlign: "center" }}
//                 >
//                   Licence Info
//                 </h2>

//                 <div
//                   className="twosplit"
//                   style={{ marginBottom: "10px", gap: "20px" }}
//                 >
//                   <div className="form-group row">
//                     <label className="col-sm-3 col-form-label"><b>Product name :</b> </label>
//                     <div className="col-sm-9">
//           <label className="col-form-label">{licenceDetails.ProductName || "NA"}</label>
//                   </div></div>

//                   <div className="form-group row">
//                     <label className="col-sm-3 col-form-label"><b>Trainers :</b> </label>
//                     <div className="col-sm-9">
//                     <label className="col-form-label">{licenceDetails.trainer || "NA"}</label>
//                  </div>
//                   </div>

//                   <div className="form-group row">
//                     <label className="col-sm-3 col-form-label"><b>Students :</b> </label>
//                     <div className="col-sm-9">
//                     <label className="col-form-label">{licenceDetails.student || "NA"}</label>
//                  </div> </div>

//                   <div className="form-group row">
//                     <label className="col-sm-3 col-form-label"><b>Course :</b> </label>
//                     <div className="col-sm-9">
//                     <label className="col-form-label">{licenceDetails.course || "NA"}</label>
//                   </div></div>

//                   <div className="form-group row">
//                     <label className="col-sm-3 col-form-label"><b>Type :</b> </label>
//                     <div className="col-sm-9">
//           <label className="col-form-label">{licenceDetails.Type || "NA"}</label>
//                  </div> </div>

//                   <div className="form-group row">
//                     <label className="col-sm-3 col-form-label"><b>Start Date  :</b></label>
//                     <div className="col-sm-9">
//           <label className="col-form-label">{licenceDetails.StartDate}</label>
//                 </div>  </div>

//                   <div className="form-group row">
//                     <label className="col-sm-3 col-form-label"><b>End Date :</b> </label>
//                     <div className="col-sm-9">
//                     <label className="col-form-label">{licenceDetails.EndDate}</label>
//                   </div></div>

//                   <div className="form-group row">
//                     <label className="col-sm-3 col-form-label"><b>Storage Size :</b> </label>
//                     <div className="col-sm-9">
//           <label className="col-form-label">{licenceDetails.StorageSize}</label>
//                   </div>
//                   </div>
//                 </div>
//               </div>
//             )}
//           </div>
//         )}
//       </div>
//     </div>
//     </div>
//   );
// };

// export default AdminProfileView;
