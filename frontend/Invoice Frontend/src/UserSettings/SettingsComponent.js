import React, { useState, useEffect ,useContext } from "react";
import { useNavigate } from "react-router-dom";
import ErrorBoundary from "../ErrorBoundary";
import Sitesettings from "./Sitesettings";
import axios from "axios";
import Swal from "sweetalert2";
import withReactContent from "sweetalert2-react-content";
import baseUrl from '../api/utils';
import { GlobalStateContext } from "../Context/GlobalStateProvider";
import { getPermission } from "../utils/permissionUtils";
import MODULES from "../utils/modules";
const MySwal = withReactContent(Swal);


const SettingsComponent = (aiAvailable) => {
  const navigate = useNavigate();
  const [dropdownOpen, setDropdownOpen] = useState(false);
  // Change initial state to false (view mode on load)
   const [isEdit, setIsEdit] = useState(false);
  const token = sessionStorage.getItem("token");
  const canCreate = getPermission(MODULES.SETTINGS, "canCreate");
  const canEdit   = getPermission(MODULES.SETTINGS, "canEdit");
  const canDelete = getPermission(MODULES.SETTINGS, "canDelete");
  const { setGeneralSettings } = useContext(GlobalStateContext);

  // ── State for 4 fields ────────────────────────────────────
  const [form, setForm] = useState({
    amountDecimalPlaces: 2,
    gstinNumber: true,
    estimateQuotation: true,
    salesInvoiceOrder: true,
    otpservice:true
   
  });

  // ── Load saved settings on page open ─────────────────────
  useEffect(() => {
    axios
      .get(`${baseUrl}/settings/general/get`, {
       headers: {
            Authorization:token ,
          }
      })
      .then((res) => {
        setForm({
          amountDecimalPlaces: res.data.amountDecimalPlaces ?? 2,
          gstinNumber: res.data.gstinNumber ?? true,
          estimateQuotation: res.data.estimateQuotation ?? true,
          salesInvoiceOrder: res.data.salesInvoiceOrder ?? true,
          otpservice: res.data.otpservice ?? true,
        });
      })
      .catch((err) => {
        console.error("Failed to load settings", err);
      });
  }, []);

  // ── Checkbox toggle ───────────────────────────────────────
  const handleCheck = (field) => {
    setForm((prev) => ({ ...prev, [field]: !prev[field] }));
  };

  // ── Amount change ─────────────────────────────────────────
  const handleAmount = (value) => {
    setForm((prev) => ({ ...prev, amountDecimalPlaces: parseInt(value) }));
  };

  // ── Save ─────────────────────────  ─────────────────────────
  const handleSave = () => {
    axios
      .post(`${baseUrl}/settings/general/save`, form, {
       headers: {
            Authorization:token,
          }
      })
      .then(() => {
        setGeneralSettings(form);
        MySwal.fire({
          icon: "success",
          title: "Saved!",
          text: "Settings saved successfully.",
          confirmButtonText: "OK",
        }).then((result) => {
        if (result.isConfirmed) {
          setIsEdit(false);
        }
      });
    })
      
      .catch(() => {
        MySwal.fire("Error", "Failed to save settings", "error");
      });
  };

  const settingsOptions = [
    { label: "Mail", path: "/settings/mailSettings" },
    { label: "Footer", path: "/settings/footer" },
    { label: "Roles", path: "/settings/displayname" },
  ];

  return (
    <div>
      {/* Page Header */}
      <div className="page-header">
        <div className="page-block">
          <div className="row align-items-center">
            <div className="col-md-12">
              <div className="page-header-title">
                <h5 className="m-b-10">Settings</h5>
              </div>
              <ul className="breadcrumb">
                <li className="breadcrumb-item">
                  <a href="#" onClick={() => navigate("/admin/dashboard")} title="dashboard">
                    <i className="feather icon-home"></i>
                  </a>
                </li>
                <li className="breadcrumb-item">
                  <a href="#">General</a>
                </li>
              </ul>
            </div>
          </div>
        </div>
      </div>

      {/* Main Card */}
      <div className="card" style={{ margin: "0 -25px 0 -20px" }}>
        <div className="card-body">
          <div className="row">
            <div className="col-12">

              {/* Top Navigation Bar */}
              <div style={{
                display: "flex", justifyContent: "space-between",
                alignItems: "center", marginBottom: "16px"
              }}>
                <div onClick={() => navigate(-1)}
                  style={{ cursor: "pointer", fontSize: "16px", color: "#333" }}>
                  <i className="fa-solid fa-arrow-left"></i>
                </div>

                <div style={{ display: "flex", alignItems: "center", gap: "12px" }}>
                   {canCreate && (
                  <div style={{ position: "relative" }}>
                    <button
                      onClick={() => setDropdownOpen(!dropdownOpen)}
                      style={{
                        backgroundColor: "#1a3c5e", color: "#fff", border: "none",
                        padding: "8px 18px", borderRadius: "6px", cursor: "pointer",
                        fontWeight: "600", fontSize: "14px", display: "flex",
                        alignItems: "center", gap: "8px", letterSpacing: "0.3px"
                      }}>
                      Site Settings <span style={{ fontSize: "11px" }}>▼</span>
                    </button>

                    {dropdownOpen && (
                      <>
                        <div onClick={() => setDropdownOpen(false)}
                          style={{
                            position: "fixed", top: 0, left: 0,
                            width: "100vw", height: "100vh", zIndex: 998
                          }} />
                        <div style={{
                          position: "absolute", right: 0, top: "110%",
                          backgroundColor: "#fff", border: "1px solid #e0e0e0",
                          borderRadius: "6px", boxShadow: "0 6px 20px rgba(0,0,0,0.12)",
                          zIndex: 999, minWidth: "180px", overflow: "hidden"
                        }}>
                          {settingsOptions.map((option, index) => (
                            <div key={option.label}
                              onClick={() => { setDropdownOpen(false); navigate(option.path); }}
                              style={{
                                padding: "11px 18px", cursor: "pointer",
                                fontSize: "14px", color: "#2c3e50",
                                borderBottom: index < settingsOptions.length - 1
                                  ? "1px solid #f0f0f0" : "none",
                              }}
                              onMouseEnter={e => e.currentTarget.style.backgroundColor = "#f0f4f8"}
                              onMouseLeave={e => e.currentTarget.style.backgroundColor = "#fff"}>
                              {option.label}
                            </div>
                          ))}
                        </div>
                      </>
                    )}
                  </div>
                   )}
                  <div onClick={() => navigate(-1)}
                    style={{ cursor: "pointer", fontSize: "18px", color: "#555" }}>
                    <i className="fa-solid fa-xmark"></i>
                  </div>
                </div>
              </div>

              {/* Settings Heading */}
              <h4 style={{ margin: "0 0 20px 0" }}>Settings</h4>

              {/* 4 Fields */}
              <div style={{ maxWidth: "1200px" }}>

                {/* Amount Decimal Places */}
                <div style={{ display: "flex", alignItems: "center", gap: "10px", marginBottom: "16px" }}>
                  <label style={{ fontSize: "14px", color: "#333", margin: 0, minWidth: "160px" }}>
                    Amount<br />
                    <span style={{ fontSize: "11px", color: "#888" }}>(upto Decimal Places)</span>
                    <br />
                    <i className="fa-solid fa-circle-info" style={{ color: "#aaa", fontSize: "13px" }}></i>
                  </label>
                  <input
                    type="number"
                    value={form.amountDecimalPlaces}  
                    min={0} max={4}
                    onChange={(e) => handleAmount(e.target.value)}
                     disabled={!isEdit}   // 👈 add this
                    style={{
                      width: "50px", border: "none",
                      borderBottom: "1px solid #ccc", fontSize: "14px",
                      textAlign: "center", outline: "none", background: "transparent"
                    }}
                  />
                  {/* Live preview — shows how decimals will look */}
                  <span style={{ fontSize: "13px", color: "#aaa" }}>
                    e.g. {(0).toFixed(form.amountDecimalPlaces)}
                  </span>
                </div>

                {/* GSTIN Number */}
                <div style={{ display: "flex", alignItems: "center", gap: "10px", marginBottom: "16px" }}>
                  <input type="checkbox"
                    checked={form.gstinNumber}
                    onChange={() => handleCheck("gstinNumber")}
                     disabled={!isEdit}   // 👈 add this
                    style={{ width: "16px", height: "16px", cursor: "pointer", accentColor: "#1a6fdb" }} />
                  <label style={{ fontSize: "14px", color: "#333", margin: 0 }}>GSTIN Number</label>
                  <i className="fa-solid fa-circle-info" style={{ color: "#aaa", fontSize: "13px" }}></i>
                </div>

                {/* Estimate/Quotation */}
                <div style={{ display: "flex", alignItems: "center", gap: "10px", marginBottom: "16px" }}>
                  <input type="checkbox"
                    checked={form.estimateQuotation}
                    onChange={() => handleCheck("estimateQuotation")}
                    disabled={!isEdit}   // 👈 add this
                    style={{ width: "16px", height: "16px", cursor: "pointer", accentColor: "#1a6fdb" }} />
                  <label style={{ fontSize: "14px", color: "#333", margin: 0 }}>Estimate/Quotation</label>
                  <i className="fa-solid fa-circle-info" style={{ color: "#aaa", fontSize: "13px" }}></i>
                </div>

                {/* SalesInvoice Order */}
                <div style={{ display: "flex", alignItems: "center", gap: "10px", marginBottom: "16px" }}>
                  <input type="checkbox"
                    checked={form.salesInvoiceOrder}
                    onChange={() => handleCheck("salesInvoiceOrder")}
                    disabled={!isEdit}   // 👈 add this
                    style={{ width: "16px", height: "16px", cursor: "pointer", accentColor: "#1a6fdb" }} />
                  <label style={{ fontSize: "14px", color: "#333", margin: 0 }}>SalesInvoice Order</label>
                  <i className="fa-solid fa-circle-info" style={{ color: "#aaa", fontSize: "13px" }}></i>
                </div>

                 {/* otp verification */}
                <div style={{ display: "flex", alignItems: "center", gap: "10px", marginBottom: "16px" }}>
                  <input type="checkbox"
                    checked={form.otpservice}
                    onChange={() => handleCheck("otpservice")}
                    disabled={!isEdit}   // 👈 add this
                    style={{ width: "16px", height: "16px", cursor: "pointer", accentColor: "#1a6fdb" }} />
                  <label style={{ fontSize: "14px", color: "#333", margin: 0 }}>OtpService</label>
                  <i className="fa-solid fa-circle-info" style={{ color: "#aaa", fontSize: "13px" }}></i>
                </div>

     
                {/* Save / Edit Button */}
                 {canCreate && (
                <div className="btngrp" style={{ display: "flex", justifyContent: "flex-end" }}>
                  {isEdit ? (
                    <button className="btn btn-primary" onClick={handleSave}>
                      Save
                    </button>
                  ) : (
                    <button className="btn btn-success" onClick={() => setIsEdit(true)}>
                      Edit
                    </button>
                  )}
                </div>
                 )}

              </div>

              {/* Site Settings Form */}
              <ErrorBoundary>
                <Sitesettings />
              </ErrorBoundary>

              {aiAvailable && (
                <ErrorBoundary>
                  {/* <OpenRouterKeys /> */}
                </ErrorBoundary>
              )}

            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default SettingsComponent;