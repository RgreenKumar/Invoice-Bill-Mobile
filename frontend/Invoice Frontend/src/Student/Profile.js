// import React from "react";
// import undraw_profile from "../images/profile.png"
// import errorimg from "../images/errorimg.png"
// const Profile = ({notfound,displayname,userData,img}) => {
  
      
//   return (
//     <div> {notfound ? (
//         <h1 style={{textAlign:"center",marginTop:"250px"}}>No {displayname && displayname.student_name 
//           ? displayname.student_name 
//           : "Student" 
//         } found with the email</h1>) : (
//             <div className='innerFrame '>
//               <h4> {displayname && displayname.student_name 
//           ? displayname.student_name 
//           : "Student" 
//         } Profile</h4>
//               <div className='mainform'>
//                 <div className='profile-picture'>
//                   <div className='image-group' >
//                     <img id="preview"  src={img ? img : undraw_profile}
//                      onError={(e) => {
//                 e.target.src = errorimg; // Use the imported error image
//               }}
//                alt='profile' />
//                   </div>
//                 </div>

//       <div  style={{backgroundColor:"#F2E1F5",padding:"10px",paddingLeft:"20px",borderRadius:"20px" }} >
//         <div className='form-group row' >
//           <label htmlFor='Name'className="col-sm-3 col-form-label"><b> Name :</b></label>
//           <div className="col-sm-9">
//           <label className="col-form-label">
//            {userData.username}</label>
//            </div>
//         </div>
//         <div className='form-group row'>
//           <label htmlFor='email'className="col-sm-3 col-form-label"> <b>Email :</b></label>
//           <div className="col-sm-9">
//           <label className="col-form-label">
//          {userData.email}</label>
//          </div>
//         </div>

//         <div className='form-group row'>
//           <label htmlFor='dob'className="col-sm-3 col-form-label"><b>Date of Birth :</b></label>
//           <div className="col-sm-9">
//           <label className="col-form-label">{userData.dob}</label>
//           </div>
//         </div>
//         <div className='form-group row'>
//           <label htmlFor='skills'className="col-sm-3 col-form-label"><b>Skills :</b></label>
//           <div className="col-sm-9">
//           <label className="col-form-label">{userData.skills}</label>
//           </div>
//         </div>

//         <div className='form-group row'>
//                   <label htmlFor='Phone'className="col-sm-3 col-form-label"><b>Phone :</b></label>
//                   <div className="col-sm-9">
//                   <label className="col-form-label">{userData.countryCode}{userData.phone}</label>
//                 </div></div>
       
//         <div className='form-group row'>
//           <label htmlFor='role'className="col-sm-3 col-form-label"><b>RoleName :</b></label>
//           <div className="col-sm-9">
//          <label className="col-form-label">{displayname && displayname.student_name 
//           ? displayname.student_name 
//           : "Student" 
//         }</label> 
//         </div>


//         </div>
//       </div>
//     </div>
    
//   </div>)}</div>
//   )
// }

// export default Profile