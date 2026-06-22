import React, { useEffect, useState } from 'react';
import axios from 'axios';
import { Navigate } from 'react-router-dom';
import baseUrl from './api/utils';

const RedirectComponent = ({ vpsonly, admincount, children, sasonly, checkvisible }) => {
    const [activeProfile, setActiveProfile] = useState(sessionStorage.getItem("Activeprofile"));
    const [loading, setLoading] = useState(true);
    const [adminCount, setAdminCount] = useState(0); // State to hold the admin count
    const [showInLandingPage, setShowInLandingPage] = useState(null); // Set initial state to null

    // Fetch show in landing page setting
    // useEffect(() => {
    //     const fetchShowInLandingPage = async () => {
    //         try {
    //             const response = await axios.get(`${baseUrl}/settings/viewCourseInLanding`);
    //             setShowInLandingPage(response.data); 
    //         } catch (error) {
    //             console.error(error);
    //             throw error
    //         } finally {
    //             setLoading(false);
    //         }
    //     };

    //     fetchShowInLandingPage(); // Always fetch when component loads
    // }, []); 

    // Fetch the active environment
    useEffect(() => {
        const fetchActive = async () => {
            try {
                const active = await axios.get(`${baseUrl}/Active/Environment`);
               
                if (active?.data?.environment) {
                    sessionStorage.setItem("Activeprofile", active.data.environment);
                    setActiveProfile(active.data.environment);
                  } 
                  if (active?.data?.currency) {
                    sessionStorage.setItem("Currency", active.data.currency);
                  } 
            } catch (error) {
                console.error(error);
                throw error
            }finally {
            setLoading(false); // ✅ ADD THIS
        }

        };

        if (!activeProfile) {
            fetchActive();
        }else {
        setLoading(false); // ✅ ADD THIS — already in session, unlock immediately
    }

    }, [activeProfile]);

    // Fetch admin count if needed
    useEffect(() => {
        const countAdmin = async () => {
            try {
                const count = await axios.get(`${baseUrl}/count/admin`);
                setAdminCount(count.data); // Set the admin count in state
            } catch (error) {
                console.log(error);
                throw error
            }
        };

        if (admincount) {
            countAdmin(); // Fetch admin count if required
        }
    }, [admincount]);

    // Handle loading state
    if (loading) {
        return (
            <div className="outerspinner active">
                <div className="spinner"></div>
            </div>
        );
    }

    // Redirect logic after loading
    if (sasonly && activeProfile !== "SAS") {
        return <Navigate to="/notfound" />;
    }

    if (admincount && adminCount > 0) {
        return <Navigate to="/notfound" />;
    }

    if (vpsonly && activeProfile !== "VPS") {
        return <Navigate to="/login" />;
    }

    // Check for visibility and showInLandingPage
    if (checkvisible && (showInLandingPage === false || activeProfile!=="VPS")) {
        return <Navigate to="/login" />;
    }
    
        return <>{children}</>;
    

};

export default RedirectComponent;
