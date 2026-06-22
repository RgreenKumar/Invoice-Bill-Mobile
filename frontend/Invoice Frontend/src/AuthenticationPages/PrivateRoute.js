import React from 'react'
import { Navigate } from 'react-router-dom';

const PrivateRoute = ({sysadmin, authenticationRequired, authorizationRequired,
  onlyadmin, onlyuser, onlytrainer, children, sysandadmin}) => {

  const isAuthenticated = sessionStorage.getItem('token') !== null;
  const userRole = sessionStorage.getItem('role'); 

  if (authenticationRequired && !isAuthenticated) {
    return <Navigate to="/login" />;
  }

  if (authorizationRequired) {
    if(userRole === "USER") {
      return <Navigate to="/unauthorized" />;
    } else if(userRole === null) {
      return <Navigate to="/login" />;
    }
  }
    
  if(onlyadmin && (userRole === "TRAINER" || userRole === "USER")){
    return <Navigate to="/unauthorized" />;
  }

  if(sysadmin && (userRole === "TRAINER" || userRole === "USER" || userRole === "ADMIN")){
    return <Navigate to="/unauthorized" />;
  } 

  if(onlytrainer && (userRole === "ADMIN" || userRole === "USER")){
    return <Navigate to="/unauthorized" />;
  }

  if(onlyuser && (userRole === "ADMIN" || userRole === "TRAINER")){
    return <Navigate to="/unauthorized" />;
  } 

  if(sysandadmin && (userRole !== "ADMIN" && userRole !== "SYSADMIN")) {
    return <Navigate to="/unauthorized" />;
  }

  return <>{children}</>;
}

export default PrivateRoute