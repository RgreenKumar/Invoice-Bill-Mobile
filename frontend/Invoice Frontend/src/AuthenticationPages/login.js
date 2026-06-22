import React, { useState, useEffect, useContext } from "react";
import { Link, useNavigate } from "react-router-dom";
import loginImage from "../images/login.png";
import Swal from "sweetalert2";
import withReactContent from "sweetalert2-react-content";
import baseUrl from "../api/utils";
import axios from "axios";
import logo from "../images/logo.png";
import { GlobalStateContext } from "../Context/GlobalStateProvider";
import "../assets/css/invoicestyle.css";
import { secureSet } from "../utils/secureStorage";

const Login = () => {
  const { siteSettings } = useContext(GlobalStateContext);
  const MySwal = withReactContent(Swal);
  const [formData, setFormData] = useState({ username: "", password: "" });
  const navigate = useNavigate();
  const [activeProfile, setActiveProfile] = useState(
    sessionStorage.getItem("Activeprofile")
  );
  const [adminExists, setAdminExists] = useState(true); // default true → hides link until we know for sure

  useEffect(() => {
    const getActiveProfile = async () => {
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
        console.log(error);
        throw error;
      }
    };
    getActiveProfile();
  }, []);

  // ── Check if admin already exists ──
  useEffect(() => {
    const checkAdminCount = async () => {
      try {
        const count = await axios.get(`${baseUrl}/count/admin`);
        setAdminExists(count.data > 0);
      } catch (error) {
        console.log("Error checking admin count", error);
      }
    };
    checkAdminCount();
  }, []);

  // ── Registration popup (only reachable when adminExists is false) ──
  const handleRegistration = () => {
    MySwal.fire({
      title: "Select your Role",
      html: `
        <div style="display:flex;flex-direction:column;align-items:center;">
          <button id="admin-btn" class="swal2-confirm swal2-styled" style="width:100%;">Register as Admin</button>
        </div>`,
      showCancelButton: true,
      showConfirmButton: false,
      cancelButtonText: "Cancel",
      didOpen: () => {
        const adminBtn = document.getElementById("admin-btn");
        if (adminBtn) {
          adminBtn.addEventListener("click", () => {
            navigate("/adminRegistration");
            MySwal.close();
          });
        }
      },
    });
  };

  const [errors, setErrors] = useState({ username: "", password: "" });

  const handleChange = (e) => {
    const { name, value } = e.target;
    let error = "";
    switch (name) {
      case "username":
        error = /^[^\s@]+@[^\s@]+\.com$/.test(value) ? "" : "Please enter a valid email address";
        break;
      case "password":
        error = value.length < 6 ? "Password must be at least 6 characters long" : "";
        break;
      default:
        break;
    }
    setFormData((prev) => ({ ...prev, [name]: value }));
    setErrors((prev) => ({ ...prev, [name]: error }));
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    try {
      if (formData.password === "") setErrors((prev) => ({ ...prev, password: "Please Enter The Password" }));
      if (formData.username === "") setErrors((prev) => ({ ...prev, username: "Please Enter The Email" }));
      if (Object.values(errors).some((error) => error) || !formData.username || !formData.password) return;

      const response = await axios.post(`${baseUrl}/login`, formData, {
        headers: { "Content-Type": "application/json" },
      });

      if (response.status === 200) {
        sessionStorage.clear();
        const data = response.data;
        sessionStorage.setItem("token", data.token);
        sessionStorage.setItem("role", data.role);
        sessionStorage.setItem("userid", data.userid);
        sessionStorage.setItem("email", data.email);

        // ── CASHIER PERMISSIONS ──
        if (data.role === "CASHIER") {
          try {
            const permResponse = await axios.get(
              `${baseUrl}/cashier/permissions/${data.userid}`,
              { headers: { Authorization: data.token } }
            );
            const permObj = {};
            permResponse.data.forEach((p) => {
              permObj[p.moduleName] = {
                canView: p.canView,
                canCreate: p.canCreate,
                canEdit: p.canEdit,
                canDelete: p.canDelete,
              };
            });
            secureSet("permissions", permObj);
          } catch (err) {
            console.log("Error fetching permissions", err);
            sessionStorage.setItem("permissions", JSON.stringify({}));
          }
        }
        // ── END CASHIER PERMISSIONS ──

        if (data.role === "SYSADMIN") {
          window.location.href = "/viewAll/Admins";
        } else {
          window.location.href = "/dashboard/viewitem";
        }
      }
    } catch (error) {
      if (error.response && error.response.status === 404) {
        setErrors((prev) => ({ ...prev, username: "User not found" }));
      } else if (error.response && error.response.status === 401) {
        const data = error.response.data || "error occurred";
        const message = data?.message;
        if (message === "Incorrect password") {
          setErrors((prev) => ({ ...prev, password: `Incorrect password. ${data?.attemptsLeft} attempts left before account lockout.` }));
        } else if (message === "In Active") {
          MySwal.fire({ title: "In Active User!", text: `reason : ${data?.Description}`, icon: "error" });
        } else if (message === "Not Approved") {
          MySwal.fire({ title: `${data?.message}`, text: `${data?.Description}`, icon: "error" });
        }
      } else {
        throw error;
      }
    }
  };

  return (
    <div className="inv-login-root">

      {/* ── LEFT DARK PANEL ── */}
      <div className="inv-left-panel">

        {/* Brand */}
        <div className="inv-brand">
          <img
            src={siteSettings?.siteicon
              ? `data:image/jpeg;base64,${siteSettings.siteicon}`
              : logo}
            alt="logo"
            className="inv-brand-logo"
          />
          <span className="inv-brand-name">InvoiceBill</span>
        </div>

        {/* SVG */}
        <div className="inv-svg-wrap">
          <svg viewBox="0 0 340 280" fill="none" xmlns="http://www.w3.org/2000/svg">
            <rect x="30" y="20" width="240" height="220" rx="16" fill="rgba(255,255,255,0.07)" stroke="rgba(255,255,255,0.12)" strokeWidth="1.5"/>
            <rect x="30" y="20" width="240" height="48" rx="16" fill="rgba(79,195,247,0.15)"/>
            <rect x="30" y="52" width="240" height="16" fill="rgba(79,195,247,0.15)"/>
            <rect x="54" y="35" width="80" height="8" rx="4" fill="rgba(255,255,255,0.6)"/>
            <rect x="54" y="50" width="50" height="5" rx="2.5" fill="rgba(255,255,255,0.25)"/>
            <circle cx="228" cy="42" r="16" fill="rgba(79,195,247,0.2)" stroke="rgba(79,195,247,0.4)" strokeWidth="1.5"/>
            <text x="222" y="47" fontSize="13" fill="#4fc3f7" fontWeight="bold">$</text>
            <line x1="54" y1="88" x2="246" y2="88" stroke="rgba(255,255,255,0.1)" strokeWidth="1"/>
            {[0,1,2,3].map((i) => (
              <g key={i}>
                <rect x="54" y={102 + i * 28} width={60 + (i % 2) * 20} height="6" rx="3" fill="rgba(255,255,255,0.2)"/>
                <rect x="180" y={102 + i * 28} width="40" height="6" rx="3" fill="rgba(79,195,247,0.35)"/>
              </g>
            ))}
            <line x1="54" y1="218" x2="270" y2="218" stroke="rgba(255,255,255,0.15)" strokeWidth="1"/>
            <rect x="54" y="228" width="60" height="5" rx="2.5" fill="rgba(255,255,255,0.3)"/>
            <rect x="180" y="226" width="70" height="8" rx="4" fill="rgba(79,195,247,0.6)"/>
            <rect x="195" y="160" width="100" height="44" rx="10" fill="#4fc3f7" opacity="0.95"/>
            <circle cx="209" cy="182" r="9" fill="rgba(15,32,39,0.2)"/>
            <path d="M205 182 L208 185 L214 178" stroke="#0f2027" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"/>
            <text x="222" y="179" fontSize="9" fill="#0f2027" fontWeight="700">PAID</text>
            <rect x="220" y="185" width="48" height="5" rx="2.5" fill="rgba(15,32,39,0.25)"/>
          </svg>
        </div>

        {/* Tagline */}
        <div className="inv-tagline">
          <h2>Smart Invoicing<br />Made Simple</h2>
          <p>Manage billing, track payments,<br />and grow your business with confidence.</p>
        </div>

        {/* Dots */}
        <div className="inv-dots">
          <div className="inv-dot active"></div>
          <div className="inv-dot"></div>
          <div className="inv-dot"></div>
        </div>

      </div>

      {/* ── RIGHT CARD ── */}
      <div className="inv-card-center">
        <div className="inv-card-login">

          {/* Logo */}
          <div className="inv-logo-wrap">
            <img
              src={siteSettings?.siteicon
                ? `data:image/jpeg;base64,${siteSettings.siteicon}`
                : logo}
              alt="logo"
            />
          </div>

          {/* Title */}
          <h3>Sign in</h3>

          {/* Email */}
          <div className="inv-field-wrap">
            <input
              type="text"
              name="username"
              value={formData.username}
              onChange={handleChange}
              className={`inv-input ${errors.username ? "is-invalid" : ""}`}
              placeholder="Email"
              autoComplete="username"
              autoFocus
            />
            {errors.username && (
              <div className="inv-invalid-msg">{errors.username}</div>
            )}
          </div>

          {/* Password */}
          <div className="inv-field-wrap">
            <input
              type="password"
              name="password"
              value={formData.password}
              onChange={handleChange}
              className={`inv-input ${errors.password ? "is-invalid" : ""}`}
              placeholder="Password"
              autoComplete="current-password"
            />
            {errors.password && (
              <div className="inv-invalid-msg">{errors.password}</div>
            )}
          </div>

          {/* Forgot / New user */}
          <div className="inv-links-row">
            <Link to="/forgot-password">Forgot Password?</Link>
            {!adminExists && (
              <Link to="#" onClick={handleRegistration}>New user?</Link>
            )}
          </div>

          {/* Login Button */}
          <button className="inv-btn-login" onClick={handleSubmit}>
            Login
          </button>

          {/* Cancel Button */}
          <Link className="inv-btn-cancel" to="/">
            Cancel
          </Link>

          <hr className="inv-divider" />

        </div>
      </div>

    </div>
  );
};

export default Login;