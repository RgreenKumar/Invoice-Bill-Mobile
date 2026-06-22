// import React, { useContext, useEffect, useRef, useState } from 'react'
// import Swal from "sweetalert2";
// import withReactContent from "sweetalert2-react-content";
// import profile from "../images/profile.png"
// import { useLocation, useNavigate, useParams } from 'react-router-dom';
// import baseUrl from '../api/utils';
// import axios from 'axios';
// import errorimg from '../images/errorimg.png'
// import PhoneInput, { parsePhoneNumber } from 'react-phone-number-input';
// import 'react-phone-number-input/style.css';
// import { isValidPhoneNumber } from 'react-phone-number-input';
// import { GlobalStateContext } from '../Context/GlobalStateProvider';
// const EditTrainer = () => {
//     const{email}=useParams()
//     const { displayname } = useContext(GlobalStateContext);
//     const navigate = useNavigate();
//     const token=sessionStorage.getItem("token")
//     const MySwal = withReactContent(Swal);
//     const [notFound, setNotFound] = useState(false);
//     const [formData, setFormData] = useState({
//       username: "",
//       base64Image:null,
//       email: "",
//       dob: "",
//       skills:"",
//       phone:"",
//       profile: null,
//       countryCode:"+91",
//       isActive: true,
//     });
//     const [errors, setErrors] = useState({
//       username: '',
//       email: '',
//       dob: '',
//       skills:'',
//      profile:'',
//       phone: '',
//       fileInput:''
      
//     });
//     const [defaultCountry, setDefaultCountry] = useState('IN');
//     const [phoneNumber, setPhoneNumber] = useState('');
//     const location = useLocation();
//     const nameRef = useRef(null);
//     const emailRef = useRef(null);
//     const dobRef = useRef(null);
//     const skillsRef = useRef(null);
//     const phoneRef = useRef(null);
     
   

//     // Access the passed user data from location.state
//     const initialUserData = location.state?.user || {};

//     useEffect(() => {
//       const fetchData = async () => {
//         try {
//           const response = await axios.get(`${baseUrl}/student/admin/getTrainer/${email}`, {
//             headers: {
//               Authorization: token,
//             },
//           });
//           const userData = response.data;
//         if(response.status===200){
//           setFormData(prevData => {
//           const updatedData = { ...prevData, ...initialUserData, ...userData };
//           return updatedData;
//         });
//         const fullPhoneNumber = `${userData.countryCode}${initialUserData.phone}`; 
//           setPhoneNumber(fullPhoneNumber)
         
//           if(userData.profile !== null){
//           setFormData((prevFormData) => ({
//             ...prevFormData, 
//             base64Image: `data:image/jpeg;base64,${userData.profile}` 
//         }));
//       }
//     }
//         } catch (error) {
//           if(error.response && error.response.status===404){
//             setNotFound(true)
//           }else if(error.response && error.response.status===401)
//           {
//             navigate("/unauthorized")
//           }else{
//             // MySwal.fire({
//             //   title: "Error!",
//             //   text: error.response,
//             //   icon: "error",
//             //   confirmButtonText: "OK",
//             // });
//             throw error
//           }
//            }
//       };
  
//       fetchData();
//     }, []);
  
//     const handlePhoneChange = (value) => {
//       if (typeof value !== 'string') {
//         return
//       }
     
//       setPhoneNumber(value);
//       const phoneNumber = parsePhoneNumber(value);
//       if (phoneNumber) {
//         // Extract phone number without country code
//         const phoneNumberWithoutCountryCode = phoneNumber.nationalNumber;
    
//         setFormData((prevState) => ({
//         ...prevState,
//         phone:phoneNumberWithoutCountryCode ,
//       }));
//     }
//       // Validate phone number
//       if (value && isValidPhoneNumber(value)) {
        
//         setErrors((prevErrors) => ({
//           ...prevErrors,
//           phone: '',
//         }));
//       } else {
//         setErrors((prevErrors) => ({
//           ...prevErrors,
//           phone: 'Enter a valid Phone number',
//         }));
//       }
//     };
//     const fetchCountryDialingCode = async (newCountryCode) => {
//       try {
//         if (!newCountryCode) {
//          return;
//         }
       
//         // Fetch country data based on the new country code (e.g., "IN", "US")
//         const response = await fetch(`https://restcountries.com/v3.1/alpha/${newCountryCode}`);
//         const data = await response.json();
    
       
//         // Extract the dialing code from the 'idd' object in the response
//         const dialingCode = data[0]?.idd?.root + (data[0]?.idd?.suffixes?.[0] || "") || "+91";
    
//         // Set the country dialing code in the formData
//         setFormData((prevState) => ({
//           ...prevState,
//           countryCode: dialingCode,
//         }));
  
//        // const countryCode = data.country_code.toUpperCase(); // Get the country code (e.g., "IN" for India, "US" for USA)
//         setDefaultCountry(newCountryCode);
//       } catch (error) {
//         console.error("Error fetching country dialing code: ", error);
//       }
//     };
//     const handleChange = (e) => {
//       const { name, value } = e.target;
//       let error = '';
  
//       switch (name) {
       
//           // case 'skills':
//           //   error = value.length < 1 ? 'Please enter a skill' : '';
//           // break;
//         case 'email':
//           // This is a basic email validation, you can add more advanced validation if needed
//          error = /^[^\s@]+@[^\s@]+\.com$/.test(value) ? '' : 'Please enter a valid email address';
//           break;
//         case 'dob':
//           const dobDate = new Date(value);
//           const today = new Date();
//           const maxDate = new Date(today.getFullYear() - 8, today.getMonth(), today.getDate()); // Min age 8 years
//           const minDate = new Date(today.getFullYear() - 100, today.getMonth(), today.getDate()); // Max age 100 years
//           error = dobDate <= maxDate && dobDate >= minDate ? '' : 'Please enter a valid date of birth';
//           break;
       
//           case 'phone':
//         error = value.length < 10 ? 'Phone number must be at least 10 digits' :
//        value.length > 15 ? 'Phone number cannot be longer than 15 digits' :
//        /^\d+$/.test(value) ? '' : 'Please enter a valid phone number (digits only)';

//         break;
         
//           default:
//             break;
//       }
  
//       setErrors(prevErrors => ({
//         ...prevErrors,
//         [name]: error
//       }));
  
//       setFormData(prevState => ({
//           ...prevState,
//           [name]: value
//       }));
//     };
  
//     const convertImageToBase64 = (file) => {
//       return new Promise((resolve, reject) => {
//         const reader = new FileReader();
//         reader.readAsDataURL(file);
//         reader.onload = () => resolve(reader.result);
//         reader.onerror = (error) => reject(error);
//       });
//     };
//     const handleFileChange = (e) => {
//       const file = e.target.files[0];
//      if (file && file.size > 50 * 1024) {
//   setErrors((prevErrors) => ({
//     ...prevErrors,
//     profile: 'Image size must be 50 KB or smaller',
//   }));
//   return;
// }
// setErrors((prevErrors) => ({
//   ...prevErrors,
//   profile: '',
// }));
//       // Convert the file to base64
//       convertImageToBase64(file)
//         .then((base64Data) => {
//           // Set the base64 encoded image and the file in the state
//           setFormData((prevFormData) => ({
//             ...prevFormData,
//             profile: file,
//             base64Image: base64Data,
//           }));
//           setErrors(prevErrors => ({
//             ...prevErrors,
//             profile: ''
//           }));
//         })
//         .catch((error) => {
//           console.error("Error converting image to base64:", error);
//         });
//     };
//     const scrollToError = () => {
//       if (errors.username) {
//         nameRef.current.scrollIntoView({ behavior: 'smooth', block: 'nearest', inline: 'start' });
//       } else if (errors.email) {
//         emailRef.current.scrollIntoView({ behavior: 'smooth', block: 'nearest', inline: 'start' });
//       } else if (errors.dob) {
//         dobRef.current.scrollIntoView({ behavior: 'smooth', block: 'nearest', inline: 'start' });
//       } else if (errors.skills) {
//         skillsRef.current.scrollIntoView({ behavior: 'smooth', block: 'nearest', inline: 'start' });
//       } else if (errors.phone) {
//         phoneRef.current.scrollIntoView({ behavior: 'smooth', block: 'nearest', inline: 'start' });
//       }
//     };
//     useEffect(() => {
//       scrollToError();
//     }, [errors]);
//     const handleSubmit = async (e) => {
//         e.preventDefault();
//         let hasErrors = false;
//         const requiredFields = [ 'email',  'phone', 'countryCode'];
      
//         requiredFields.forEach(field => {
//           if (!formData[field] || formData[field].length === 0 || errors[field]) {
//             hasErrors = true;
//             setErrors(prevErrors => ({
//               ...prevErrors,
//               [field]: !formData[field] ? 'This field is required' : errors[field]
//             }));
//           }
//         });
        
//         if (hasErrors) {
//           scrollToError(); // Scroll to the first error field
//           return;
//         }
//         const formDataToSend = new FormData();
//         formDataToSend.append("username", formData.username);
//         formDataToSend.append("psw", formData.psw);
//         formDataToSend.append("email", formData.email);
//         if(formData.dob===null){
//           setFormData((prev)=>({
//             ...prev,
//             dob:""
//           }))
//         }else{
//         formDataToSend.append("dob", formData.dob);
//         }
//         formDataToSend.append("phone", formData.phone);
//         formDataToSend.append("isActive", formData.isActive);
//         formDataToSend.append("profile", formData.profile);
//         formDataToSend.append("skills",formData.skills);
//         formDataToSend.append("countryCode",formData.countryCode);
      
//         try {
//           const response = await axios.patch(`${baseUrl}/Edit/Trainer/${email}`,formDataToSend, {
//             headers: {
//               Authorization: token,
//             }
//           });
//           const data = response.data;
//           if (response.status===200) {
//             MySwal.fire({
//               title: "Updated !",
//               text: `${displayname && displayname.trainer_name
//                 ? displayname.trainer_name
//                 : "Trainer"} Information Updated successfully!`,
//               icon: "success",
//               confirmButtonText: "OK",
              
//             }).then((result) => {
//                 if (result.isConfirmed) {
//                   navigate( "/view/Trainer");
//                 }
//               });
//           }          
//         } catch (error) {
//           if(error.response){
//             if(error.response.status===400){
//               setErrors(prevErrors => ({
//                 ...prevErrors,
//                 email: "This email is already registered."
//               }));
//             }else if(error.response.status===401){
//               MySwal.fire({
//                 title: "Un Authorized!",
//                 text: `you are unable to Update a ${displayname && displayname.trainer_name
//                     ? displayname.trainer_name
//                     : "Trainer"}`,
//                 icon: "error",
//                 confirmButtonText: "OK",
//               });
//             }
//           }else{
      
//           // MySwal.fire({
//           //   title: "Error!",
//           //   text: `An error occurred while adding ${displayname && displayname.trainer_name
//           //           ? displayname.trainer_name
//           //           : "Trainer"}. Please try again later.`,
//           //   icon: "error",
//           //   confirmButtonText: "OK",
//           // });
//           throw error
//         }
//       }
//     };
   
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
//       <div onClick={()=>{navigate("/view/Trainer")}}><i className="fa-solid fa-xmark"></i></div>
//       </div>
//     {notFound ? (
//       <div className='centerflex'>
//           <div className='enroll'>
//             <h2>No {displayname && displayname.trainer_name
//                     ? displayname.trainer_name
//                     : "Trainer"} found in this email</h2>
//             <button className='btn btn-primary' onClick={()=>{navigate(-1);}}>Go Back</button>
//           </div>
//           </div>
//         ) : (
//   <div className='innerFrame'>
//     <h4>Edit  {displayname && displayname.trainer_name
//                     ? displayname.trainer_name
//                     : "Trainer"}</h4>
//     <div className='mainform'>
//         <div className='profile-picture'>
//           <div className='image-group'>
//           {formData.base64Image ? (
//                     <img
//                       src={formData.base64Image}
//                       onError={(e) => {
//                         e.target.src = errorimg; // Use the imported error image
//                       }}
//                       alt="Selected Image"
//                       className="profile-picture"
//                     />
//                   ) : (
//                     <img
//                       src={profile}
//                       alt="Default Profile Picture"
//                       className="prof"
//                     />
//                   )}
//           </div>
//           <div style={{textAlign:'center'}}>
//           <label htmlFor='fileInput' className='file-upload-btn'>
//             Upload
//           </label>
    
//           <div className='text-danger'> {errors.profile}</div>
//           <input
//                 type='file'
//                 name="fileInput"
//                 style={{display:"none"}}
//                 id='fileInput'
//                 className={`file-upload ${errors.fileInput && 'is-invalid'}`}
//                 accept='image/*'
//                 onChange={handleFileChange}
//               />
//   </div>
//         </div>

//         <div >
//           <div className='form-group row' ref={nameRef}>
//             <label htmlFor='Name' className="col-sm-3 col-form-label"> Name </label>
//             <div className="col-sm-9"> <input
//              type="text"
//               id='Name'
//               value={formData.username|| ""}
//               onChange={handleChange}
//               name="username"
              
//               className={`form-control   mt-1 ${errors.username && 'is-invalid'}`}
//               placeholder="Full Name"
//               autoFocus
//             />
//             <div className="invalid-feedback">
//               {errors.username}
//             </div></div> 
//           </div>
//           <div className='form-group row' ref={emailRef}>
          
//             <label htmlFor='email' className="col-sm-3 col-form-label"> Email<span className="text-danger">*</span></label>
//             <div className="col-sm-9">             <input
//                     type="email"
//                     autoComplete="off"
//                     className={`form-control   ${errors.email && 'is-invalid'}`}
//                     name="email"
//                     value={formData.email|| ""}
//                     onChange={handleChange}
//                     placeholder="Email Address"
//                     required
//                   />
//                   <div className="invalid-feedback">
//                     {errors.email}
//                   </div></div>

//           </div>
//           <div className="form-group row "  ref={phoneRef} >
//                 <label htmlFor="Phone" 
//                 className="col-sm-3 col-form-label">
//                   {" "}
//                   Phone
//                   <span className="text-danger">
//                     *
//                   </span>
//                 </label>
//                 <div className="col-sm-9">
//                 <div className="phone-input-container inputlikeeffect">
                 
//       <PhoneInput
//         placeholder="Enter phone number"
//         id="phone"
//         value={phoneNumber||''}
//         onChange={handlePhoneChange}
//         className={`form-control  ${
//           errors.phone && "is-invalid"
//         }`}
//         defaultCountry={defaultCountry}
//         international
//         countryCallingCodeEditable={true}
//         onCountryChange={fetchCountryDialingCode} 
//       />
    
//                     <div className="invalid-feedback">{errors.phone}</div>
//                   </div>
//                 </div>
//               </div>
//               <div className='form-group row' ref={dobRef}>
//             <label htmlFor='dob' className="col-sm-3 col-form-label">Date of Birth</label>
//             <div className="col-sm-9">
//             <input
//               type="date"
//                                   name="dob"
//                                   className={`form-control   ${errors.dob && 'is-invalid'}`}
//                                   placeholder="Starting year"
//                                   value={formData.dob|| ""}
//                                   onChange={handleChange}
                                 
//             />
//             <div className="invalid-feedback">
//               {errors.dob}
//             </div></div>
//           </div>

//           <div className='form-group row' ref={skillsRef}>
//             <label htmlFor='skills' className="col-sm-3 col-form-label"> Skills </label>
//             <div className="col-sm-9"> <input
//              type="text"
//               id='skills'
//               value={formData.skills|| ""}
//               onChange={handleChange}
//               name="skills"
              
//               className={`form-control    ${errors.skills && 'is-invalid'}`}
//               placeholder="skills"
           
//             />
//             <div className="invalid-feedback">
//               {errors.skills}
//             </div></div> 
//           </div>

         

        
       
         
//         </div>
//       </div>
//       <div className='btngrp'>
//       <button className= "btn btn-primary" id='submitbtn' onClick={handleSubmit}>Save</button>

//       </div>
//   </div>     )}
//   </div>
//   </div>
//   </div>
//   </div>
// </div>
//   )
// }

// export default EditTrainer
