  import React, { useContext, useEffect, useState } from 'react'

  import logo from "../images/LearnHubLogo.png"
  import Notification from './Notification'
  import baseUrl from '../api/utils'
  import axios from 'axios'
  import { useLocation, useNavigate } from 'react-router-dom'
  import errorimg from "../images/errorimg.png"
  import undraw_profile from "../images/profile-white.png";
  import { GlobalStateContext } from "../Context/GlobalStateProvider";
  import Swal from "sweetalert2";
  import withReactContent from "sweetalert2-react-content";

  const Header = ({ searchQuery, handleSearchChange }) => {

    const navigate = useNavigate();
    const { siteSettings, lowStockItems, setLowStockItems } = useContext(GlobalStateContext);
    const islogedin = sessionStorage.getItem("token") !== null;
    const location = useLocation();
    const [data, setdata] = useState({ name: "", profileImage: null });
    const [count, setcount] = useState(0);
    const [profileOpen, setProfileOpen] = useState(false);
    const [notifOpen, setNotifOpen] = useState(false);
     const { itemSettings } = useContext(GlobalStateContext);

    const token = sessionStorage.getItem("token");
    const role = sessionStorage.getItem("role");

    useEffect(() => {
      const cachedData = sessionStorage.getItem("profileData");
      if (cachedData) {
        setdata(JSON.parse(cachedData));
      } else {
        const fetchItems = async () => {
          try {
            if (token) {
              const response = await axios.get(`${baseUrl}/Edit/profiledetails`, {
                headers: { Authorization: token },
              });
              if (response.status === 200) {
                const fetchedData = response.data;
                setdata(fetchedData);
                sessionStorage.setItem("profileData", JSON.stringify(fetchedData));
              }
            }
          } catch (error) {
            console.error("Error fetching data:", error);
          }
        };
        fetchItems();
      }
    }, []);

    const fetchUnreadCount = async () => {
      try {
        if (role !== "SYSADMIN" && token) {
          const response = await axios.get(`${baseUrl}/unreadCount`, {
            headers: { Authorization: token },
          });
          if (response.status === 200) {
            setcount(response.data);
          }
        }
      } catch (error) {
        console.error("Error fetching unread count:", error);
      }
    };

    const fetchLowStock = async () => {
      try {
        if (token && role !== "SYSADMIN") {
          const res = await axios.get(`${baseUrl}/getLowStockItems`, {
            headers: { Authorization: token }
          });
           console.log("Low stock items:", res.data);
          setLowStockItems(res.data);
        }
         else {
      console.log("Token:", token, "Role:", role); // ← ADD THIS
    }
      } catch (err) {
        console.error("Low stock fetch failed", err);
      }
    };


    useEffect(() => {
      fetchUnreadCount();
    }, []);

    useEffect(() => {
      fetchLowStock();
    }, []);



    const handlemarkallasRead = async (notificationIds) => {
      try {
        const markread = await axios.post(`${baseUrl}/MarkAllASRead`, notificationIds, {
          headers: { Authorization: token },
        });
        if (markread.status === 200) {
          fetchUnreadCount();
        }
      } catch (error) {
        console.error("Error fetching unread count:", error);
      }
    };

    const MySwal = withReactContent(Swal);
    const imageSource = data.profileImage
      ? `data:image/jpeg;base64,${data.profileImage}`
      : undraw_profile;

    const handleLogout = async () => {
      Swal.fire({
        title: "Logout",
        text: "Are you sure you want to logout?",
        icon: "warning",
        showCancelButton: true,
        confirmButtonText: "Logout",
        cancelButtonText: "Cancel",
      }).then(async (result) => {
        if (result.isConfirmed) {
          if (!token) return;
          try {
            const response = await axios.post(`${baseUrl}/logoutuser`, {}, {
              headers: { Authorization: token },
            });
            if (response.status === 200) {
              sessionStorage.clear();
              localStorage.clear();
              navigate("/login");
            }
          } catch (error) {
            MySwal.fire({
              title: "Error!",
              text: "An error occurred while logging out. Please try again later.",
              icon: "error",
              confirmButtonText: "OK",
            });
          }
        }
      });
    };
    
    useEffect(() => {
  const handleClickOutside = (e) => {
    if (!e.target.closest(".hdr-notif-wrapper")) {
      setNotifOpen(false);
    }
    if (!e.target.closest(".hdr-profile-wrapper")) {
      setProfileOpen(false);
    }
  };

  document.addEventListener("mousedown", handleClickOutside);
  return () => document.removeEventListener("mousedown", handleClickOutside);
}, []);

    const displayName = data.name
      ? (data.name.length > 15 ? data.name.substring(0, 15) + "…" : data.name)
      : "Admin";
    const firstLetter = displayName.charAt(0).toUpperCase();

    return (
      /* ✅ KEPT: original class "navbar pcoded-header navbar-expand-lg navbar-light header-blue" */
      <header className="navbar pcoded-header navbar-expand-lg navbar-light header-blue">

        {/* ✅ KEPT: original m-header block */}
        <div className="m-header">
          {islogedin && (
            <a className="mobile-menu" id="mobile-collapse" href="#!">
              <span></span>
            </a>
          )}

          <a  href="#" onClick={() => navigate("/admin/dashboard")} className="b-brand" >
            <img
              src={siteSettings.sitelogo
                ? `data:image/jpeg;base64,${siteSettings.sitelogo}`
                : logo}
              alt="logo"
              className="logo"
            />
          </a>
        </div>

        {/* ✅ KEPT: original right-side wrapper class */}
        <div className="d-flex align-items-center ml-auto">

          {/* ✅ KEPT: original search bar
          {["/", "/dashboard/course", "/AssignedCourses", "/mycourses", "/course/admin/edit"]
            .includes(location.pathname) && (
            <li className="nav-item list-unstyled">
              <a href="#!" className="pop-search">
                <i className="fa-solid fa-magnifying-glass text-light"></i>
              </a>
              <div className="search-bar">
                <input
                  type="text"
                  className="form-control border-0 shadow-none"
                  name="search"
                  id="search"
                  value={searchQuery}
                  onChange={handleSearchChange}
                  placeholder="Search Course...."
                />
                <button type="button" className="close" aria-label="Close">
                  <span aria-hidden="true">&times;</span>
                </button>
              </div>
            </li>
          )} */}

          {islogedin && (
            <ul className="navbar-nav p-1 flex-row align-items-center">

              {/* ── 🔔 Notification Bell (NEW style) ────────── */}
              {role !== "SYSADMIN" && (
                <li className="mr-2">
                  <div className="hdr-notif-wrapper">
                   {/* REPLACE WITH THIS */}
                          <button
                            className={`hdr-icon-btn ${notifOpen ? "active" : ""}`}
                            onMouseDown={(e) => e.stopPropagation()} 
                            onClick={() => { 
                              setNotifOpen(!notifOpen); 
                              setProfileOpen(false);
                              if (!notifOpen) fetchUnreadCount(); 
                              fetchLowStock();// ✅ refresh count when opening
                            }}
                          >
                      <i className="feather icon-bell"></i>
                       
                  {itemSettings.showLowStockDialog && lowStockItems.length > 0
                    ? <span className="hdr-badge-warning" title="Low Stock Alert!">⚠️</span>
                    : count > 0 && <span className="hdr-badge">{count > 99 ? "99+" : count}</span>
                  }           
                    
                    </button>

                    {notifOpen && (
                      <div className="hdr-dropdown hdr-dropdown--notif">
                        <Notification handlemarkallasRead={handlemarkallasRead} />
                      </div>
                    )}
                  </div>
                </li>
              )}

              {/* ── ☀️ Sun / Theme Icon (NEW — was missing) ── */}
              <li className="mr-2">
                <button
                  className="hdr-icon-btn"
                  title="Theme"
                  onClick={() => { /* add theme toggle logic here if needed */ }}
                >
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    width="19"
                    height="19"
                    viewBox="0 0 24 24"
                    fill="none"
                    strokeWidth="1.8"
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    className="hdr-sun-svg"
                  >
                    <circle cx="12" cy="12" r="4" />
                    <line x1="12" y1="2"    x2="12" y2="4" />
                    <line x1="12" y1="20"   x2="12" y2="22" />
                    <line x1="4.22"  y1="4.22"  x2="5.64"  y2="5.64" />
                    <line x1="18.36" y1="18.36" x2="19.78" y2="19.78" />
                    <line x1="2"  y1="12"   x2="4"  y2="12" />
                    <line x1="20" y1="12"   x2="22" y2="12" />
                    <line x1="4.22"  y1="19.78" x2="5.64"  y2="18.36" />
                    <line x1="18.36" y1="5.64"  x2="19.78" y2="4.22" />
                  </svg>
                </button>
              </li>

              {/* ── 👤 Profile Pill (NEW style) ──────────────── */}
              <li>
                <div className="hdr-profile-wrapper">
                  <div
                    className="hdr-profile-pill"
                    onMouseDown={(e) => e.stopPropagation()} 
                    onClick={() => { setProfileOpen(!profileOpen); setNotifOpen(false); }}
                  >
                    {data.profileImage ? (
                      <img
                        src={imageSource}
                        onError={e => { e.target.src = errorimg; }}
                        alt="profile"
                        className="hdr-avatar-img"
                      />
                    ) : (
                      <div className="hdr-avatar-letter">{firstLetter}</div>
                    )}
                    <span className="hdr-profile-name">{displayName}</span>
                    <i className="feather icon-chevron-down hdr-profile-caret"></i>
                  </div>

                  {profileOpen && (
                    <div className="hdr-dropdown">
                      {role !== "SYSADMIN" && (
                        <a href="/course/dashboard/profile" className="hdr-dropdown-item">
                          <i className="feather icon-user"></i> Profile
                        </a>
                      )}
                      <button
                        onClick={handleLogout}
                        className="hdr-dropdown-item danger"
                      >
                        <i className="feather icon-log-out"></i> Logout
                      </button>
                    </div>
                  )}
                </div>
              </li>

            </ul>
          )}

          {/* ✅ KEPT: original sign in/up buttons */}
          {!islogedin && (
            <div className="ml-auto p-2" style={{ width: "250px", display: "flex", alignItems: "end", justifyContent: "flex-end" }}>
              <button className="btn btn-sm btn-success mr-2" onClick={() => navigate("/login")}>
                Sign In
              </button>
              <button className="btn btn-sm btn-secondary" onClick={() => navigate("/StudentRegistration")}>
                Sign Up
              </button>
            </div>
          )}

        </div>
      </header>
    );
  };

  export default Header;
