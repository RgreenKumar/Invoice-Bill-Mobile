// import React from 'react'
// import { useEffect } from 'react';
// import { useState } from 'react';
// import Swal from "sweetalert2";
// import withReactContent from "sweetalert2-react-content";
// import baseUrl from '../api/utils';
// import axios from 'axios';

// const Affiliates = () => {
//   const MySwal = withReactContent(Swal);

//   const [users, setUsers] = useState([]);
//   useEffect(() => {
//     const fetchData = async () => {
//       try {
//         const response = await axios.get(`${baseUrl}/api/v2/affliators`);
//         setUsers(response.data);
//       } catch (error) {
//         console.error('Error fetching affiliates:', error);
//         // MySwal.fire({
//         //   icon: 'error',
//         //   title: 'Error',
//         //   text: 'Failed to fetch affiliates. Please try again later.',
//         // });
//         throw error
//       }
//     };

//     fetchData();
//   }, []);
//   return (
//     <div>
//       <div className="page-header"></div>
//       <div className='row'>
//         <div className='col-sm-12'>
//           <div className='card'>
//             <div className='card-header'>
//     <div className="tableheader2">
//       <h4>Affiliates Details</h4>
     
       
   
//         </div>
//         </div>
//         <div className='card-body'>
//       <div className="table-container">
//         <table className="table table-hover table-bordered table-sm">
//           <thead className='thead-dark'>
//             <tr>
//               <th>#</th>
//             <th scope="col">Name</th>
//               <th scope="col">Email</th>
//               <th scope='col'>Address</th>
//               <th scope="col">Phone</th>
//               <th scope="col"> 10% code</th>
//               <th scope="col"> 20% code</th>
//               <th scope="col"> referral ID</th>
              
//             </tr>
//             {/* {fullsearch ?  <tr>
//           <td></td>
//             <td>
//               <input
//                 type="search"
//                 name="username"
//                 value={username}
//                 onChange={handleChange}
//                 placeholder="Search Username"
//               />
//             </td>
//             <td>
//               <input
//                 type="search"
//                 name="email"
//                 value={email}
//                 onChange={handleChange}
//                 placeholder="Search Email"
//               />
//             </td>
//             <td>
//               <input
//                 type="search"
//                 name="institutionName"
//                 value={institutionName}
//                 onChange={handleChange}
//                 placeholder="Search Institution"
//               />
//             </td>
            
//             <td>
//               <input
//                 type="search"
//                 name="phone"
//                 value={phone}
//                 onChange={handleChange}
//                 placeholder="Search Phone"
//               />
//             </td>
//             <td>
//               <input
//                 type="search"
//                 name="skills"
//                 value={skills}
//                 onChange={handleChange}
//                 placeholder="Search Skills"
//               />
//             </td>
//            <td><div style={{width:'110px'}}></div></td>
//           </tr> :<></>} */}
//           </thead>
//           <tbody>
//           {users.map((user, index) => (
//               <tr key={user.id}>
//                 {/* <th scope="row">{(currentPage * itemsperpage) + (index + 1)}</th> */}
//                 <th scope="row">{index + 1}</th>
//                 <td className='py-2'>{user.name}</td>
//                 <td className='py-2'>{user.emailid}</td>
//                 <td className='py-2'>{user.address}</td>
//                 <td className='py-2'>{user.mobilenumber}</td>
//                 <td className='py-2'>{user.coupon10}</td>
//                 <td className='py-2'>{user.coupon20}</td>
//                 <td className='py-2'>{user.referalid}</td>
               
//               </tr>
//             ))}
//           </tbody>
//         </table>
       
//       </div>
//   </div>
//   </div>
//   </div>
//     </div>
//   </div>
//   )
// }

// // export default Affiliates