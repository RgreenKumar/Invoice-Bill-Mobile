import React, { useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import Swal from "sweetalert2";
import withReactContent from "sweetalert2-react-content";
import baseUrl from "../api/utils";
import axios from "axios";
import logo from "../images/logo.png";
import "../assets/css/invoicestyle.css";

const MySwal = withReactContent(Swal);

const ForgetPassword = () => {
  const navigate = useNavigate();
  const [isResetPassword, setIsResetPassword] = useState(false);
  const [email, setEmail] = useState("");
  const [formData, setFormData] = useState({ password: "", confirmPassword: "" });
  const [forgetPasswordFormData, setForgetPasswordFormData] = useState({ email: "" });
  const [passwordError, setPasswordError] = useState("");
  const [confirmPasswordError, setConfirmPasswordError] = useState("");
  const [emailError, setEmailError] = useState("");

  const handleChange = (e) => {
    const { name, value } = e.target;
    setFormData({ ...formData, [name]: value });
    if (name === "password") {
      const passwordRegex = /^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$/;
      setPasswordError(!passwordRegex.test(value)
        ? "Password must be at least 8 characters, include uppercase, lowercase, digit, and special character."
        : "");
    } else if (name === "confirmPassword") {
      setConfirmPasswordError(value !== formData.password ? "Passwords do not match" : "");
    }
  };

  const handleForgetPasswordChange = (e) => {
    const { name, value } = e.target;
    setForgetPasswordFormData({ ...forgetPasswordFormData, [name]: value });
    setEmailError(/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value) ? "" : "Please enter a valid email address");
  };

  const handleResetPasswordSubmit = async (e) => {
    e.preventDefault();
    try {
      if (formData.password !== formData.confirmPassword) { setConfirmPasswordError("Passwords do not match"); return; }
      if (formData.password.length < 6) { setPasswordError("Password must be at least 6 characters long"); return; }
      const formDataToSend = new FormData();
      formDataToSend.append("email", email);
      formDataToSend.append("password", formData.password);
      const response = await axios.post(`${baseUrl}/resetpassword`, formDataToSend);
      if (response.status === 200) {
        MySwal.fire({ title: "Success", text: "Your password has been reset successfully!", icon: "success", confirmButtonText: "OK" })
          .then((result) => { if (result.isConfirmed) navigate("/login"); });
      } else if (response.status === 404) {
        setEmailError("User not found");
      }
    } catch (error) {
      throw error;
    }
  };

  const handleForgetPasswordSubmit = async (e) => {
    e.preventDefault();
    try {
      const formDataToSend = new FormData();
      formDataToSend.append("email", forgetPasswordFormData.email);
      const response = await axios.post(`${baseUrl}/forgetpassword`, formDataToSend);
      if (response.status === 200) { setEmail(forgetPasswordFormData.email); setIsResetPassword(true); }
    } catch (error) {
      if (error.response && error.response.status === 404) { setEmailError("User not found"); }
      else { throw error; }
    }
  };

  const isResetButtonDisabled = !email || emailError || !formData.password || !formData.confirmPassword || passwordError || confirmPasswordError;
  const isForgetButtonDisabled = !forgetPasswordFormData.email || emailError;

  return (
    <div className="inv-login-root">

      {/* ══════════════════════════════
          LEFT — Dark Panel + SVG
      ══════════════════════════════ */}
      <div className="inv-left-panel">

        {/* Brand */}
        <div className="inv-brand">
          <img src={logo} alt="logo" className="inv-brand-logo" />
          <span className="inv-brand-name">InvoiceBill</span>
        </div>

        {/* SVG Invoice Illustration */}
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
          <div className="inv-dot"></div>
          <div className="inv-dot active"></div>
          <div className="inv-dot"></div>
        </div>

      </div>

      {/* ══════════════════════════════
          RIGHT — White Card
      ══════════════════════════════ */}
      <div className="inv-card-center">
        <div className="inv-card-login">

          {/* Logo */}
          <div className="inv-logo-wrap">
            <img src={logo} alt="logo" />
          </div>

          {/* ── STEP 1: Email Verification ── */}
          {!isResetPassword ? (
            <>
              <h3>User Verification</h3>

              <div className="inv-field-wrap">
                <input
                  type="text"
                  name="email"
                  value={forgetPasswordFormData.email}
                  onChange={handleForgetPasswordChange}
                  className={`inv-input ${emailError ? "is-invalid" : ""}`}
                  placeholder="Enter Email Address"
                  autoComplete="username"
                  autoFocus
                />
                {emailError && <div className="inv-invalid-msg">{emailError}</div>}
              </div>

              <button
                className="inv-btn-login"
                onClick={handleForgetPasswordSubmit}
                disabled={isForgetButtonDisabled}
                style={{ opacity: isForgetButtonDisabled ? 0.6 : 1, cursor: isForgetButtonDisabled ? "not-allowed" : "pointer" }}
              >
                Verify
              </button>

              <Link className="inv-btn-cancel" to="/login" style={{ marginTop: "12px" }}>
                Back to Login
              </Link>

              <hr className="inv-divider" />

              <div style={{ textAlign: "center" }}>
                <Link to="/login" style={{ fontSize: "13px", color: "#0d3b52", textDecoration: "none", fontWeight: 500 }}>
                  Go to Login page!
                </Link>
              </div>
            </>
          ) : (
            /* ── STEP 2: Reset Password ── */
            <>
              <h3>Change Password</h3>

              <div className="inv-field-wrap">
                <input
                  type="text"
                  name="email"
                  className="inv-input"
                  value={email}
                  readOnly
                  style={{ background: "#f0f4f8", color: "#888", cursor: "not-allowed" }}
                />
              </div>

              <div className="inv-field-wrap">
                <input
                  type="password"
                  name="password"
                  value={formData.password}
                  onChange={handleChange}
                  className={`inv-input ${passwordError ? "is-invalid" : ""}`}
                  placeholder="New Password"
                  autoComplete="new-password"
                />
                {passwordError && <div className="inv-invalid-msg">{passwordError}</div>}
              </div>

              <div className="inv-field-wrap">
                <input
                  type="password"
                  name="confirmPassword"
                  value={formData.confirmPassword}
                  onChange={handleChange}
                  className={`inv-input ${confirmPasswordError ? "is-invalid" : ""}`}
                  placeholder="Confirm Password"
                  autoComplete="new-password"
                />
                {confirmPasswordError && <div className="inv-invalid-msg">{confirmPasswordError}</div>}
              </div>

              <button
                className="inv-btn-login"
                onClick={handleResetPasswordSubmit}
                disabled={isResetButtonDisabled}
                style={{ opacity: isResetButtonDisabled ? 0.6 : 1, cursor: isResetButtonDisabled ? "not-allowed" : "pointer" }}
              >
                Reset Password
              </button>

              <button
                className="inv-btn-cancel"
                style={{ marginTop: "12px" }}
                onClick={() => navigate("/login")}
              >
                Cancel
              </button>

              <hr className="inv-divider" />
            </>
          )}

        </div>
      </div>

    </div>
  );
};

export default ForgetPassword;
