import axios from 'axios'
import React, { useEffect } from 'react'
import baseUrl from '../api/utils'
import Swal from "sweetalert2";
import withReactContent from "sweetalert2-react-content";
import { useNavigate } from 'react-router-dom';

const RefreshToken = () => {
    
    const MySwal = withReactContent(Swal);

    const token=sessionStorage.getItem("token");
    const navigate=useNavigate();
    
        const refreshtoken = async () => {
            try {
                const newtoken = await axios.post(`${baseUrl}/refreshtoken`, {}, {
                    headers: {
                        Authorization: token,
                    }
                });
                if(newtoken.status===200){
                    if(token !== ""){
                sessionStorage.setItem('token', newtoken.data);
                navigate(-1);
                    }
                }
            } catch (error) {
                // if(error.response){
// 
            //      MySwal.fire({
            //     title: "Error Occured!",
            //     text: error.response,
            //     icon: "error",
            //   })
            // }
            throw error
            }
        }
        
    

    
  return (
    <div className='vh-100' style={{backgroundColor:"transparent",padding:"50px"}}>
    <div className="card" >
      <div className="card-header"><div className="text-center mt-5">
      <h1 className="display-1 text-danger">Session Expired</h1>
      <h2 className="display-4">Oops! It seems your session was Expired Try Login again or Refresh your Session .</h2>
      <p className="lead">Refresh Session by Clicking Refresh button..</p>
         <button className='btn btn-primary' onClick={(e)=>{refreshtoken()}}>Refresh</button>
     </div>
     </div>
     </div>
     </div>
  )
}

export default RefreshToken
