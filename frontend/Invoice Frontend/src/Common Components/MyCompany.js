import React, { useState, useRef, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import axios from "axios";
import baseUrl from "../api/utils";
import Swal from "sweetalert2";
import withReactContent from "sweetalert2-react-content";
import PhoneInput, { parsePhoneNumber, isValidPhoneNumber } from "react-phone-number-input";
import "react-phone-number-input/style.css";

const MyCompany = () => {
  const navigate = useNavigate();
  const [isEditing, setIsEditing] = useState(false);
  const logoInputRef = useRef(null);
  const signatureInputRef = useRef(null);
  const token = sessionStorage.getItem("token");
  const [phoneNumber, setPhoneNumber] = useState("");     
  const [defaultCountry, setDefaultCountry] = useState("IN");
  const MySwal = withReactContent(Swal);


  const [companyData, setCompanyData] = useState({
    businessName: "",
    phoneNumber: "",
    gstin: "",
    emailId: "",
    businessType: "",
    businessCategory: "",
    state: "",
    pincode: "",
    businessAddress: "",
    logo: null,
    signature: null,
  });

  const [logoPreview, setLogoPreview] = useState(null);
  const [signaturePreview, setSignaturePreview] = useState(null);
  const [loading, setLoading] = useState(false);


  useEffect(() => {
  const fetchUserCountryCode = async () => {
    try {
      const res = await fetch("https://ipapi.co/json/");
      const data = await res.json();
      setDefaultCountry(data.country_code.toUpperCase());
    } catch (err) {
      console.error("Error fetching country code:", err);
    }
  };
  fetchUserCountryCode();
}, []);

  // ── CONVERT FILE TO BASE64 ────────────────────────────────
  const toBase64 = (file) =>
    new Promise((resolve, reject) => {
      const reader = new FileReader();
      reader.readAsDataURL(file);
      reader.onload = () => {
        // Remove "data:image/png;base64," prefix — send only raw base64
        const base64String = reader.result.split(",")[1];
        resolve(base64String);
      };
      reader.onerror = (error) => reject(error);
    });

  // ── GET MY COMPANY ────────────────────────────────────────
  const fetchMyCompany = async () => {
    try {
      const response = await axios.get(`${baseUrl}/admin/getMyCompany`, {
        headers: {
          Authorization: token,
        },
      });
      if (response.status === 200 && response.data) {
        const data = response.data;
        setCompanyData({
          businessName: data.businessName || "",
          phoneNumber: data.phoneNumber || "",
          gstin: data.gstin || "",
          emailId: data.emailId || "",
          countryCode: data.countryCode || "+91",
          businessType: data.businessType || "",
          businessCategory: data.businessCategory || "",
          state: data.state || "",
          pincode: data.pincode || "",
          businessAddress: data.businessAddress || "",
          logo: null,
          signature: null,
        });
        // ── Show existing logo and signature ─────────────────
        if (data.logo) {
          setLogoPreview(`data:image/jpeg;base64,${data.logo}`);
        }
        if (data.signature) {
          setSignaturePreview(`data:image/jpeg;base64,${data.signature}`);
        }
        if (data.countryCode && data.phoneNumber) {
        setPhoneNumber(`${data.countryCode}${data.phoneNumber}`);
      }
      }
    } catch (error) {
      console.error("Error fetching company details:", error);
    }
  };

  useEffect(() => {
    fetchMyCompany();
  }, []);


const handlePhoneChange = (value) => {
  if (typeof value !== "string") return;
  setPhoneNumber(value);
  const parsed = parsePhoneNumber(value);
  setCompanyData((prev) => ({
    ...prev,
    phoneNumber: parsed ? parsed.nationalNumber : "",
    countryCode: parsed ? `+${parsed.countryCallingCode}` : prev.countryCode,
  }));
};


  // ── HANDLE INPUT CHANGE ───────────────────────────────────
  const handleChange = (e) => {
    const { name, value } = e.target;
    setCompanyData((prev) => ({ ...prev, [name]: value }));
  };

  // REPLACE with:
const handleLogoChange = (e) => {
  const file = e.target.files[0];
  if (file) {
    setCompanyData((prev) => ({ ...prev, logo: file }));
    const reader = new FileReader();
    reader.readAsDataURL(file);
    reader.onload = () => setLogoPreview(reader.result); // data:image/... allowed
  }
};

 const handleSignatureChange = (e) => {
  const file = e.target.files[0];
  if (file) {
    setCompanyData((prev) => ({ ...prev, signature: file }));
    const reader = new FileReader();
    reader.readAsDataURL(file);
    reader.onload = () => setSignaturePreview(reader.result);
  }
};

  const handleEdit = (e) => {
    e.preventDefault();
    setIsEditing(true);
  };

  // ── SAVE MY COMPANY ───────────────────────────────────────
  const handleSave = async (e) => {
    e.preventDefault();
    setLoading(true);
    try {
      // ── Convert images to Base64 only if new file selected ─
      let logoBase64 = null;
      let signatureBase64 = null;

      if (companyData.logo instanceof File) {
        logoBase64 = await toBase64(companyData.logo);
      }
      if (companyData.signature instanceof File) {
        signatureBase64 = await toBase64(companyData.signature);
      }

      const payload = {
        businessName: companyData.businessName,
        phoneNumber: companyData.phoneNumber,
        gstin: companyData.gstin,
        emailId: companyData.emailId,
        countryCode: companyData.countryCode,
        businessType: companyData.businessType,
        businessCategory: companyData.businessCategory,
        state: companyData.state,
        pincode: companyData.pincode,
        businessAddress: companyData.businessAddress,
        logo: logoBase64,         // null if not changed
        signature: signatureBase64, // null if not changed
      };

      const response = await axios.post(
        `${baseUrl}/admin/saveMyCompany`,
        payload,
        {
          headers: {
            Authorization: token,
          },
        }
      );

      if (response.status === 200) {
      // REMOVE: alert("Company details saved successfully!");
      MySwal.fire({
        icon: "success",
        title: "Saved!",
        text: "Company details saved successfully.",
        confirmButtonText: "OK",
      }).then((result) => {
        if (result.isConfirmed) {
          setIsEditing(false);
          fetchMyCompany();
        }
      });
    }
    }catch (error) {
      console.error("Error saving company details:", error);
      // REMOVE: alert("Failed to save company details!");
      MySwal.fire("Error", "Failed to save company details!", "error");
    }finally {
          setLoading(false);
        }
      };

  const businessTypes = [
    "Sole Proprietorship", "Partnership",
    "Private Limited", "Public Limited", "LLP"
  ];
  const businessCategories = [
    "Retail", "Wholesale", "Manufacturing",
    "Services", "Education", "Healthcare", "Technology"
  ];
  const states = [
    "Tamil Nadu", "Kerala", "Karnataka", "Andhra Pradesh",
    "Maharashtra", "Delhi", "Gujarat", "Rajasthan",
    "Uttar Pradesh", "West Bengal"
  ];

  const formContent = () =>(
    <div>
      {/* Logo */}
      <div className="mb-4">
        
          <div
            style={{
              width: "100px",
              height: "100px",
              borderRadius: "50%",
              background: "#e8f0fe",
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              cursor: isEditing ? "pointer" : "default",
              position: "relative",
              overflow: "hidden",
              border: "2px solid #d0d9f0",  // ← add border
            }}
            onClick={() => isEditing && logoInputRef.current.click()}
          >
            {logoPreview ? (
              <img
                src={logoPreview}
                alt="logo"
                style={{
                  width: "100px",      // ← exact size
                  height: "100px",     // ← exact size
                  objectFit: "cover",
                  borderRadius: "50%",
                  display: "block",    // ← remove inline spacing
                  position: "absolute", // ← cover full circle
                  top: 0,
                  left: 0,
                }}
              />
            ) : (
              <span style={{ color: "#7a9cc6", fontSize: "14px", textAlign: "center" }}>
                Add<br />Logo
              </span>
            )}
          </div>

          <input
              type="file" ref={logoInputRef}
              style={{ display: "none" }} accept="image/*"
              onChange={handleLogoChange}
            />
        {isEditing && (
          <>
            <div
              onClick={() => logoInputRef.current.click()}
              style={{
                width: "28px", height: "28px", borderRadius: "50%",
                background: "#fff", border: "1px solid #ccc",
                display: "flex", alignItems: "center", justifyContent: "center",
                cursor: "pointer", marginTop: "-14px", marginLeft: "72px",
                position: "relative", zIndex: 1,
              }}
            >
              <i className="fa-solid fa-pen" style={{ fontSize: "11px", color: "#555" }}></i>
            </div>
            
          </>
        )}
      </div>

      {/* Three column layout */}
      <div className="row">
        {/* Business Details */}
        <div className="col-md-4">
          <h6 className="font-weight-bold mb-3">Business Details</h6>

          <div className="form-group">
            <label>Business Name <span className="text-danger">*</span></label>
            <input
              className="form-control" name="businessName"
              placeholder="Enter Business Name"
              value={companyData.businessName}
              onChange={handleChange} readOnly={!isEditing}
            />
          </div>

          <div className="form-group">
          <label>Phone Number</label>
          <div className={`form-control p-0 ${!isEditing ? "bg-light" : ""}`}
            style={{ display: "flex", alignItems: "center", overflow: "hidden" }}>
            <style>{`.PhoneInputInput { letter-spacing: 0 !important; }`}</style>
            <PhoneInput
              placeholder="Enter Phone Number"
              value={phoneNumber}
              onChange={handlePhoneChange}
              defaultCountry={defaultCountry}

              international
              countryCallingCodeEditable={true}
              disabled={!isEditing}
              style={{ width: "100%", padding: "0 10px" }}
            />
          </div>
        </div>

          <div className="form-group">
            <label>GSTIN</label>
            <input
              className="form-control" name="gstin"
              placeholder="Enter GSTIN"
              value={companyData.gstin}
              onChange={handleChange} readOnly={!isEditing}
            />
          </div>

          <div className="form-group">
            <label>Email ID</label>
            <input
              className="form-control" name="emailId"
              placeholder="Enter Email ID"
              value={companyData.emailId}
              onChange={handleChange} readOnly={!isEditing}
            />
          </div>
        </div>

        {/* More Details */}
        <div className="col-md-4">
          <h6 className="font-weight-bold mb-3">More Details</h6>

          <div className="form-group">
            <label>Business Type</label>
            <select
              className="form-control" name="businessType"
              value={companyData.businessType}
              onChange={handleChange} disabled={!isEditing}
            >
              <option value="">Select Business Type</option>
              {businessTypes.map((type) => (
                <option key={type} value={type}>{type}</option>
              ))}
            </select>
          </div>

          <div className="form-group">
            <label>Business Category</label>
            <select
              className="form-control" name="businessCategory"
              value={companyData.businessCategory}
              onChange={handleChange} disabled={!isEditing}
            >
              <option value="">Select Business Category</option>
              {businessCategories.map((cat) => (
                <option key={cat} value={cat}>{cat}</option>
              ))}
            </select>
          </div>

          <div className="form-group">
            <label>State</label>
            <select
              className="form-control" name="state"
              value={companyData.state}
              onChange={handleChange} disabled={!isEditing}
            >
              <option value="">Select State</option>
              {states.map((s) => (
                <option key={s} value={s}>{s}</option>
              ))}
            </select>
          </div>

          <div className="form-group">
            <label>Pincode</label>
            <input
              className="form-control" name="pincode"
              placeholder="Enter Pincode"
              value={companyData.pincode}
              onChange={handleChange} readOnly={!isEditing}
            />
          </div>
        </div>

        {/* Business Address + Signature */}
        <div className="col-md-4">
          <div className="form-group">
            <label className="font-weight-bold">Business Address</label>
            <textarea
              className="form-control" name="businessAddress"
              placeholder="Enter Business Address" rows={5}
              value={companyData.businessAddress}
              onChange={handleChange} readOnly={!isEditing}
            />
          </div>

          <div className="form-group">
            <label className="font-weight-bold">Add Signature</label>
            <div
              style={{
                border: "2px dashed #ccc", borderRadius: "8px",
                padding: "20px", textAlign: "center",
                cursor: isEditing ? "pointer" : "default",
                background: "#fafafa", minHeight: "100px",
                display: "flex", flexDirection: "column",
                alignItems: "center", justifyContent: "center",
              }}
              onClick={() => isEditing && signatureInputRef.current.click()}
            >
              {signaturePreview ? (
                <img
                  src={signaturePreview} alt="signature"
                  style={{ maxHeight: "80px", maxWidth: "100%" }}
                />
              ) : (
                <>
                  <i className="fa-solid fa-cloud-arrow-up" style={{ fontSize: "24px", color: "#aaa" }}></i>
                  <p className="mb-0 mt-1" style={{ color: "#aaa", fontSize: "13px" }}>Upload Signature</p>
                </>
              )}
            </div>
            {isEditing && (
              <input
                type="file" ref={signatureInputRef}
                style={{ display: "none" }} accept="image/*"
                onChange={handleSignatureChange}
              />
            )}
          </div>
        </div>
      </div>

      {/* Button */}
      <div className="btngrp text-right mt-3">
        {isEditing ? (
          <button
            className="btn btn-primary"
            onClick={handleSave}
            disabled={loading}
          >
            {loading ? "Saving..." : "Save"}
          </button>
        ) : (
          <button className="btn btn-success" onClick={handleEdit}>
            Edit
          </button>
        )}
      </div>
    </div>
  );

  return (
    <div>
      <div className="main-body">
        <div className="page-wrapper">
          <div className="card" style={{ margin: "0 -25px 0 -20px", marginTop: "-115px" }}>
            <div className="card-body">
              <div className="d-flex align-items-center mb-3">
                <button className="btn btn-light mr-2" onClick={() => navigate(-1)}>
                  <i className="fa-solid fa-arrow-left"></i>
                </button>
              </div>
              {formContent ()}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default MyCompany;