import React from 'react';
import { useNavigate } from 'react-router-dom';


const Unauthorized = () => {
  const navigate=useNavigate();
    return (
   
      <div className='vh-100' style={{backgroundColor:"transparent",padding:"50px"}}>
      <div className="card" >
        <div className="card-header">
      <div className='navigateheaders'>
      <div onClick={()=>{navigate(-2)}}><i className="fa-solid fa-arrow-left"></i></div>
      <div></div>
      <div onClick={()=>{navigate(-2)}}><i className="fa-solid fa-xmark"></i></div>
      </div>
      </div>
      <div  className='card-body' style={{height:"75vh"}} >
      <div className="text-center mt-5">
      <h1 className="display-1 text-danger">401</h1>
      <h2 className="display-6">Oops! It seems you are not authorized to access this page.</h2>
      <p className="lead">Please contact the administrator for assistance..</p>
      <p>Go back To <a onClick={(e)=>{e.preventDefault();navigate("/login")}} href="#">Login</a></p>
     </div>
     </div>
     </div>
     </div>
    );
};

export default Unauthorized;
