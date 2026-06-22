// import React from "react";
// import axios from "axios";
// import baseUrl from "../api/utils";
// import Swal from "sweetalert2";
// import withReactContent from "sweetalert2-react-content";
// import { LoginSocialGoogle } from "reactjs-social-login";
// import googleicon from "../images/google-25x25.png";
// import { useNavigate } from "react-router-dom";

// const GoogleLoginComponent = ({clientId}) => {
//   console.log("gooogle component is clicking...")
//    console.log("Client ID:", clientId);
//   const MySwal = withReactContent(Swal);

//   const navigate=useNavigate();
//   const handleLoginSuccess = async (response) => {
//     // Access the id_token directly from the response
//     const idToken = response; 

//     // Send the token to your backend Spring Boot server for verification
//     try {
//       const result = await axios.post(`${baseUrl}/api/auth/google`, {
//         authCode: response.code,
//         role: "USER",
//       });

//       const data = result.data;
//       const jwtToken = data.token;
//       const role = data.role;
//       const userId = data.userid;
//       const email = data.email;

//       sessionStorage.setItem("token", jwtToken);
//       sessionStorage.setItem("role", role);
//       sessionStorage.setItem("userid", userId);
//       sessionStorage.setItem("email", email);

//       // Redirect based on role
//       if (role === "SYSADMIN") {
//          navigate("/viewAll/Admins");
//       } else {
//          navigate("/dashboard/course");
//       }
//     } catch (error) {
//       if (error.response && error.response.status === 401) {
//         const data = error.response.data || "error occurred";
//         const message = data.message;
//         if (message === "In Active") {
//           MySwal.fire({
//             title: "In Active User!",
//             text: `Reason: ${data.Description}`,
//             icon: "error",
//           });
//         } else {
//           MySwal.fire({
//             title: "Error Occurred!",
//             text: "An error occurred !! Please try again later.",
//             icon: "error",
//           });
//         }
//       } else {
//         // MySwal.fire({
//         //   title: "Error Occurred!",
//         //   text: "An error occurred while logging in. Please try again later.",
//         //   icon: "error",
//         // });
//         throw error
//       }
//     }
//   };

//   return (
//     <>
//     {clientId !==null &&(
//    <LoginSocialGoogle
//   client_id={clientId}
//   scope="openid profile email"
//   access_type="offline"
//   onResolve={({ provider, data }) => {
//     console.log("Google response:", data);
//     handleLoginSuccess(data);
//   }}
//   onReject={(err) => {
//     console.log(err);
//   }}
// >
//   <img
//     src={googleicon}
//     alt="googlelogin"
//     style={{cursor:"pointer"}}
//   />
//   {/* <button>login with google</button> */}
// </LoginSocialGoogle>

//   )}</>
//   );
// };

// export default GoogleLoginComponent;
  