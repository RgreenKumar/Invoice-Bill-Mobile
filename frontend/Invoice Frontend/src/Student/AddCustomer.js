import React, { useEffect, useRef, useState,useContext } from "react";
import "@fortawesome/fontawesome-free/css/all.min.css";
import Swal from "sweetalert2";
import withReactContent from "sweetalert2-react-content";
import baseUrl from "../api/utils";
import axios from "axios";
import PhoneInput, { parsePhoneNumber } from "react-phone-number-input";
import "react-phone-number-input/style.css";
import { isValidPhoneNumber } from "react-phone-number-input";
import { useNavigate } from "react-router-dom";
import "../assets/css/invoicestyle.css";
import { GlobalStateContext } from "../Context/GlobalStateProvider";
import { getPermission } from "../utils/permissionUtils";
import MODULES from "../utils/modules";


const AddCustomer = ({ partyType = "CUSTOMER" }) => {
  const navigate = useNavigate();
  const token = sessionStorage.getItem("token");
  const MySwal = withReactContent(Swal);
  const canCreate = getPermission(MODULES.CUSTOMER, "canCreate");
  const { generalSettings } = useContext(GlobalStateContext);

  // ── OTP states ──────────────────────────────────────
  const [otpSent, setOtpSent] = useState(false);
  const [otpVerified, setOtpVerified] = useState(false);
  const [isSendingOtp, setIsSendingOtp] = useState(false);
  const [otp, setOtp] = useState("");

  const [activeTab, setActiveTab] = useState("basic");
  const [shippingEnabled, setShippingEnabled] = useState(false);
  const [phoneNumber, setPhoneNumber] = useState("");
  const [defaultCountry, setDefaultCountry] = useState("");

  const emailRef = useRef(null);

  const [formData, setFormData] = useState({
    name: "",
    gstin: "",
    phone: "",
    email: "",
    gstType: "unregistered_consumer",
    state: "",
    billingAddress: "",
    shippingAddress: "",
    openingBalance: "",
    asOfDate: "",
    creditLimitType: "no_limit",
    creditAmount: "",
    aadhaarNo: "",
    drugLicenseNo: "",
    panNo: "",
    partyType: partyType,
  });

  const [errors, setErrors] = useState({
    name: "",
    phone: "",
    email: "",
    otp: "",
  });

  // ── Fetch country code on load ──────────────────────
  useEffect(() => {
    const fetchUserCountryCode = async () => {
      try {
        const response = await fetch("https://ipapi.co/json/");
        const data = await response.json();
        setDefaultCountry(data.country_code.toUpperCase());
      } catch (error) {
        console.error("Error fetching country code: ", error);
      }
    };
    fetchUserCountryCode();
  }, []);

  // ── Phone change ────────────────────────────────────
  const handlePhoneChange = (value) => {
    if (typeof value !== "string") return;
    setPhoneNumber(value);
    const parsed = parsePhoneNumber(value);
    if (parsed) {
      setFormData((prev) => ({ ...prev, phone: parsed.nationalNumber }));
    }
    if (value && isValidPhoneNumber(value)) {
      setErrors((prev) => ({ ...prev, phone: "" }));
    } else {
      setErrors((prev) => ({ ...prev, phone: "Enter a valid Phone number" }));
    }
  };

  // ── Handle input change ─────────────────────────────
  const handleChange = (e) => {
    const { name, value } = e.target;
    let error = "";
    if (name === "name") {
      error = value.length < 1 ? "Please enter a valid name" : "";
    }
    if (name === "email" && value) {
      error = /^[^\s@]+@[^\s@]+\.com$/.test(value)
        ? ""
        : "Please enter a valid email address";
    }
    setErrors((prev) => ({ ...prev, [name]: error }));
    setFormData((prev) => ({ ...prev, [name]: value }));
  };

  // ── OTP handlers ────────────────────────────────────

  const handleSendOTP = async () => {
    if (!formData.email || errors.email) {
      setErrors((prev) => ({ ...prev, email: !formData.email ? "Email is required" : errors.email }));
      return;
    }
    setIsSendingOtp(true);
    try {
      setOtp(""); setErrors((prev) => ({ ...prev, otp: "" }));
      setOtpVerified(false); setOtpSent(true);
      const response = await axios.post(`${baseUrl}/auth/send-otp`, null, { params: { email: formData.email } });
      if (response.status === 200) MySwal.fire({ icon: "success", title: "OTP Sent!", text: "Please check your email." });
    } catch (error) {
      if (error.response?.status === 400 && error.response.data === "EMAIL") {
        setErrors((prev) => ({ ...prev, email: "This email is already registered" }));
      } else {
        setErrors((prev) => ({ ...prev, email: "Failed to send OTP. Please try again." }));
      }
    } finally { setIsSendingOtp(false); }
  };

  const handleVerifyOTP = async () => {
    if (!otp) { setErrors((prev) => ({ ...prev, otp: "OTP is required" })); return; }
    try {
      const response = await axios.post(`${baseUrl}/auth/verify-otp`, null, { params: { email: formData.email, otp } });
      if (response.status === 200) {
        setOtpVerified(true);
        setErrors((prev) => ({ ...prev, otp: "" }));
        MySwal.fire({ toast: true, position: "top-end", icon: "success", title: "Email verified!", showConfirmButton: false, timer: 3000 });
      }
    } catch { setErrors((prev) => ({ ...prev, otp: "Invalid or expired OTP" })); }
  };

  // ── Submit ──────────────────────────────────────────
  const handleSubmit = async (e, saveAndNew = false) => {
    e.preventDefault();

      

    if (generalSettings.otpservice && !otpVerified) {
      MySwal.fire({ toast: true, position: "top-end", icon: "warning", title: "Please Verify Your Email First!", showConfirmButton: false, timer: 3000 });
      return;
    }
  

    // Validate name
    if (!formData.name) {
      setErrors((prev) => ({ ...prev, name: "Name is required" }));
      return;
    }

    const payload = {
      name: formData.name,
      gstin: formData.gstin,
      phone: formData.phone,
      email: formData.email,
      gstType: formData.gstType,
      state: formData.state,
      billingAddress: formData.billingAddress,
      shippingAddress: formData.shippingAddress,
      openingBalance: formData.openingBalance || null,
      asOfDate: formData.asOfDate || null,
      creditLimit: formData.creditLimitType === "custom",
      creditAmount: formData.creditLimitType === "custom"
        ? formData.creditAmount
        : null,
      aadhaarNo: formData.aadhaarNo,
      drugLicenseNo: formData.drugLicenseNo,
      panNo: formData.panNo,
      partyType: formData.partyType,
    };

    try {
      const response = await axios.post(
        `${baseUrl}/admin/addParty`,
        payload,
        { headers: { Authorization: token } }
      );

      if (response.status === 200) {
        MySwal.fire({
          title: "Added!",
          text: `New ${partyType === "CUSTOMER" ? "Customer" : "Supplier"} added successfully!`,
          icon: "success",
          confirmButtonText: "OK",
        }).then((result) => {
          if (result.isConfirmed) {
            if (saveAndNew) {
              // Reset form
              setFormData({
                name: "",
                gstin: "",
                phone: "",
                email: "",
                gstType: "unregistered_consumer",
                state: "",
                billingAddress: "",
                shippingAddress: "",
                openingBalance: "",
                asOfDate: "",
                creditLimitType: "no_limit",
                creditAmount: "",
                aadhaarNo: "",
                drugLicenseNo: "",
                panNo: "",
                partyType: partyType,
              });
              setPhoneNumber("");
              setOtp("");
              setOtpSent(false);
              setOtpVerified(false);
              setActiveTab("basic");
            } else {
              navigate(-1);
            }
          }
        });
      }
    } catch (error) {
      if (error.response?.status === 403) {
        MySwal.fire({
          title: "Unauthorized!",
          text: "Only ADMIN can add party!",
          icon: "error",
        });
      } else {
        MySwal.fire({
          title: "Error!",
          text: "Something went wrong. Please try again.",
          icon: "error",
        });
      }
    }
  };

  const states = [
    "Tamil Nadu", "Kerala", "Karnataka", "Andhra Pradesh",
    "Maharashtra", "Delhi", "Gujarat", "Rajasthan",
    "Uttar Pradesh", "West Bengal",
  ];

  return (
    <div>
      <div className="card" style={{ marginTop: "-115px" }}>
        <div className="card-body p-0">

          {/* ── Header ── */}
          <div className="d-flex justify-content-between align-items-center px-4 py-3 border-bottom">
            <h5 className="mb-0 font-weight-bold">
              Add {partyType === "CUSTOMER" ? "Customer" : "Supplier"}
            </h5>
            <div className="as-close-icon-wrap" onClick={() => navigate(-1)}>
              <i className="fa-solid fa-xmark as-close-icon"></i>
            </div>
          </div>

          {/* ── Top 3 Fields Row ── */}
          <div className="px-4 pt-4 pb-3">
            <div className="row align-items-start">

              {/* Name */}
              <div className="col-md-4">
                <div className="as-float-label-wrap">
                  <label className="as-float-label as-float-label-primary">
                    {partyType === "CUSTOMER" ? "Customer" : "Supplier"} Name{" "}
                    <span className="text-danger">*</span>
                  </label>
                  <input
                    type="text"
                    className={`form-control as-input-std ${errors.name ? "is-invalid" : ""}`}
                    name="name"
                    value={formData.name}
                    onChange={handleChange}
                    placeholder=""
                    autoFocus
                  />
                  {errors.name && (
                    <div className="invalid-feedback">{errors.name}</div>
                  )}
                </div>
              </div>

              {/* GSTIN */}
              <div className="col-md-4 px-3">
                <div className="as-float-label-wrap">
                  <label className="as-float-label as-float-label-muted">GSTIN</label>
                  <div className="input-group" style={{ height: "42px" }}>
                    <input
                      type="text"
                      className="form-control as-gstin-input"
                      name="gstin"
                      value={formData.gstin}
                      onChange={handleChange}
                      placeholder=""
                    />
                    <div className="input-group-append">
                      <span className="input-group-text bg-white as-gstin-append">
                        <i className="fa-solid fa-circle-info as-info-icon"></i>
                      </span>
                    </div>
                  </div>
                </div>
              </div>

              {/* Phone */}
              <div className="col-md-4 pl-3">
                <div className="as-float-label-wrap">
                  <label className="as-float-label as-float-label-muted">Phone Number</label>
                  <div className={`as-phone-wrap ${errors.phone ? "as-phone-wrap-error" : "as-phone-wrap-normal"}`}>
                    <PhoneInput
                      placeholder=""
                      value={phoneNumber}
                      onChange={handlePhoneChange}
                      defaultCountry={defaultCountry}
                      international
                      countryCallingCodeEditable={true}
                      className="as-phone-input"
                    />
                  </div>
                  {errors.phone && (
                    <div className="text-danger as-phone-error">{errors.phone}</div>
                  )}
                </div>
              </div>

            </div>
          </div>

          {/* ── Tabs ── */}
          <div className="px-4">
            <div className="d-flex border-bottom">
              {[
                { key: "basic", label: "GST & Address" },
                { key: "account", label: "Credit & Balance" },
                { key: "additional", label: "Additional Fields" },
              ].map((tab) => (
                <button
                  key={tab.key}
                  onClick={() => setActiveTab(tab.key)}
                  className={`as-tab-btn ${activeTab === tab.key
                    ? "as-tab-btn-active"
                    : "as-tab-btn-inactive"}`}
                >{tab.label}</button>
              ))}
            </div>
          </div>

          {/* ── Tab Content ── */}
          <div className="px-4 py-4">

            {/* GST & ADDRESS TAB */}
            {activeTab === "basic" && (
              <div className="row">

                {/* Left Column */}
                <div className="col-md-4 as-col-divider-right">

                  {/* GST Type */}
                  <div className="form-group">
                    <label className="as-label-sm">GST Type</label>
                    <select
                      name="gstType"
                      className="form-control form-control-sm"
                      value={formData.gstType}
                      onChange={handleChange}
                    >
                      <option value="unregistered_consumer">Unregistered/Consumer</option>
                      <option value="registered_regular">Registered Business - Regular</option>
                      <option value="registered_composition">Registered Business - Composition</option>
                    </select>
                  </div>

                  {/* State */}
                  <div className="form-group">
                    <label className="as-label-sm">State</label>
                    <select
                      name="state"
                      className="form-control form-control-sm"
                      value={formData.state}
                      onChange={handleChange}
                    >
                      <option value="">Select State</option>
                      {states.map((s) => (
                        <option key={s} value={s}>{s}</option>
                      ))}
                    </select>
                  </div>

                  {/* Email with OTP */}
                  <div className="form-group" ref={emailRef}>
                    <label className="as-label-sm">Email ID</label>
                    <div className="input-group input-group-sm">
                      <input
                        type="email"
                        className={`form-control ${errors.email ? "is-invalid" : ""}`}
                        name="email"
                        value={formData.email}
                        onChange={handleChange}
                        placeholder="Email Address"
                        disabled={otpVerified}
                      />
                      {generalSettings.otpservice &&(	

                      <div className="input-group-append">
                        {otpVerified ? (
                          <span className="input-group-text bg-white">
                            <i className="fa-solid fa-circle-check as-email-verified-icon"></i>
                          </span>
                        ) : (
                          <button
                            type="button"
                            className="btn btn-sm btn-outline-primary as-otp-btn"
                            onClick={handleSendOTP}
                            disabled={!formData.email || !!errors.email || isSendingOtp}
                          >
                            {isSendingOtp ? "Sending..." : otpSent ? "Resend" : "Send OTP"}
                          </button>
                        )}
                      </div>
                      )}
                    </div>
                    {errors.email && <div className="text-danger as-field-error">{errors.email}</div>}

                    {/* OTP Input */}
                    {otpSent && !otpVerified && (
                      <div className="as-otp-row mt-2">
                        <input
                          type="text"
                          className={`form-control form-control-sm ${errors.otp ? "is-invalid" : ""}`}
                          value={otp}
                          onChange={(e) => {
                            const val = e.target.value.replace(/\D/g, "").slice(0, 6);
                            setOtp(val);
                            if (errors.otp) setErrors((prev) => ({ ...prev, otp: "" }));
                          }}
                          placeholder="Enter 6-digit OTP"
                          maxLength="6"
                        />
                        <button
                          type="button"
                          className="btn btn-sm btn-primary as-verify-btn"
                          onClick={handleVerifyOTP}
                          disabled={otp.length !== 6}
                        >Verify</button>
                      </div>
                    )}
                    {errors.otp && <div className="text-danger as-field-error">{errors.otp}</div>}
                  </div>

                </div>

                {/* Middle Column - Billing Address */}
                <div className="col-md-4 px-4 as-col-divider-right">
                  <label className="as-address-label">Billing Address</label>
                  <textarea
                    name="billingAddress"
                    className="form-control as-address-textarea"
                    rows={7}
                    placeholder="Billing Address"
                    value={formData.billingAddress}
                    onChange={handleChange}
                  />
                </div>

                {/* Right Column - Shipping Address */}
                <div className="col-md-4 pl-4">
                  <div className="d-flex justify-content-between align-items-center mb-2">
                    <label className="as-address-label-inline">Shipping Address</label>
                    {!shippingEnabled ? (
                      <span
                        className="as-address-link"
                        onClick={() => setShippingEnabled(true)}
                      >
                        <i className="fa-solid fa-plus mr-1"></i> Enable Shipping Address
                      </span>
                    ) : (
                      <span
                        className="as-address-link"
                        onClick={() =>
                          setFormData((prev) => ({
                            ...prev,
                            shippingAddress: prev.billingAddress,
                          }))
                        }
                      >
                        <i className="fa-solid fa-copy mr-1"></i> Copy Billing Address
                      </span>
                    )}
                  </div>
                  {shippingEnabled && (
                    <textarea
                      name="shippingAddress"
                      className="form-control as-address-textarea"
                      rows={7}
                      placeholder="Shipping Address"
                      value={formData.shippingAddress}
                      onChange={handleChange}
                    />
                  )}
                </div>

              </div>
            )}

            {/* CREDIT & BALANCE TAB */}
            {activeTab === "account" && (
              <div className="row">

                {/* Opening Balance */}
                <div className="col-md-4 mb-3">
                  <div className="as-float-label-wrap">
                    <label className="as-account-float-label">Opening Balance</label>
                    <input
                      type="number"
                      name="openingBalance"
                      className="form-control as-account-input"
                      value={formData.openingBalance}
                      onChange={handleChange}
                      placeholder=""
                    />
                  </div>
                </div>

                {/* As Of Date */}
                <div className="col-md-4 mb-3">
                  <div className="as-float-label-wrap">
                    <label className="as-account-float-label">As Of Date</label>
                    <input
                      type="date"
                      name="asOfDate"
                      className="form-control as-account-input"
                      value={formData.asOfDate}
                      onChange={handleChange}
                    />
                  </div>
                </div>

                {/* Credit Limit */}
                <div className="col-md-12 mt-2">
                  <div className="as-credit-label-row">
                    <label className="as-credit-label">Credit Limit</label>
                    <i className="fa-solid fa-circle-info as-credit-info-icon"></i>
                  </div>
                  <div className="as-credit-toggle-row">
                    <span className={formData.creditLimitType !== "custom"
                      ? "as-credit-text-active"
                      : "as-credit-text-muted"}>
                      No Limit
                    </span>
                    <div
                      className="as-toggle-track"
                      onClick={() =>
                        setFormData((prev) => ({
                          ...prev,
                          creditLimitType:
                            prev.creditLimitType === "custom"
                              ? "no_limit"
                              : "custom",
                        }))
                      }
                    >
                      <span className={`as-toggle-thumb ${formData.creditLimitType === "custom"
                        ? "as-toggle-thumb-on"
                        : "as-toggle-thumb-off"}`}
                      />
                    </div>
                    <span className={formData.creditLimitType === "custom"
                      ? "as-credit-text-active"
                      : "as-credit-text-muted"}>
                      Custom Limit
                    </span>
                  </div>
                  {formData.creditLimitType === "custom" && (
                    <div className="mt-3 as-credit-limit-wrap">
                      <div className="as-float-label-wrap">
                        <label className="as-account-float-label">Credit Limit Amount</label>
                        <input
                          type="number"
                          name="creditAmount"
                          className="form-control as-account-input"
                          value={formData.creditAmount}
                          onChange={handleChange}
                        />
                      </div>
                    </div>
                  )}
                </div>

              </div>
            )}

            {/* ADDITIONAL FIELDS TAB */}
            {activeTab === "additional" && (
              <div className="row">
                <div className="col-md-4">
                  <div className="form-group">
                    <label className="as-additional-label">Aadhaar No</label>
                    <input
                      type="text"
                      name="aadhaarNo"
                      className="form-control form-control-sm"
                      value={formData.aadhaarNo}
                      onChange={handleChange}
                      placeholder="Enter Aadhaar Number"
                      maxLength="12"
                    />
                  </div>
                </div>
                <div className="col-md-4">
                  <div className="form-group">
                    <label className="as-additional-label">Drug License No</label>
                    <input
                      type="text"
                      name="drugLicenseNo"
                      className="form-control form-control-sm"
                      value={formData.drugLicenseNo}
                      onChange={handleChange}
                      placeholder="Enter Drug License Number"
                    />
                  </div>
                </div>
                <div className="col-md-4">
                  <div className="form-group">
                    <label className="as-additional-label">PAN No</label>
                    <input
                      type="text"
                      name="panNo"
                      className="form-control form-control-sm as-pan-input"
                      value={formData.panNo}
                      onChange={handleChange}
                      placeholder="Enter PAN Number"
                      maxLength="10"
                    />
                  </div>
                </div>
              </div>
            )}

          </div>

          {/* ── Footer Buttons ── */}
          <div className="d-flex justify-content-end px-4 py-3 border-top as-footer-btns">
            <button
              type="button"
              className="btn btn-light btn-sm as-btn-cancel"
              onClick={() => navigate(-1)}
            >
              Cancel
            </button>
            {/* <button
              type="button"
              className="btn btn-outline-primary btn-sm as-btn-save-new"
              onClick={(e) => handleSubmit(e, true)}
            >
              Save & New
            </button> */}
            {canCreate && (
              <button type="button" className="btn btn-primary btn-sm as-btn-save"
                onClick={(e) => handleSubmit(e, false)}>
                Save
              </button>
            )}
          </div>

        </div>
      </div>
    </div>
  );
};

export default AddCustomer;
