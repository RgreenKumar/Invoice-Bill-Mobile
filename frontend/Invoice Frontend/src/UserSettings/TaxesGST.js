import React, { useState, useEffect, useContext } from "react";
import { useNavigate } from "react-router-dom";
import axios from "axios";
import Swal from "sweetalert2";
import withReactContent from "sweetalert2-react-content";
import baseUrl from "../api/utils";
import { GlobalStateContext } from "../Context/GlobalStateProvider";
import { getPermission } from "../utils/permissionUtils";
 import MODULES from "../utils/modules";

const MySwal = withReactContent(Swal);

const TaxesGST = () => {
  const navigate = useNavigate();
  const token = sessionStorage.getItem("token");
  const [isEdit, setIsEdit] = useState(false);
   const canCreate = getPermission(MODULES.SETTINGS, "canCreate");
  const canEdit   = getPermission(MODULES.SETTINGS, "canEdit");
  const canDelete = getPermission(MODULES.SETTINGS, "canDelete");

  const { gstSettings, setGstSettings } = useContext(GlobalStateContext);



  // ── Load from API on page open ──
  
  // ✅ AFTER
const handleChange = (key) => {
  setGstSettings((prev) => ({ ...prev, [key]: !prev[key] }));
};

  // ── Save ──
  const handleSave = () => {
    axios.post(`${baseUrl}/settings/gst/save`, gstSettings, {
      headers: { Authorization: token }
    }).then(() => {
     
      MySwal.fire({
        icon: "success",
        title: "Saved!",
        text: "GST Settings saved successfully.",
        confirmButtonText: "OK",
      }).then((result) => {
        if (result.isConfirmed) setIsEdit(false);
      });
    }).catch(() => {
      MySwal.fire("Error", "Failed to save GST settings", "error");
    });
  };

  const checkboxItems = [
    { key: "enableGST", label: "Enable GST" },
    { key: "enableHSN", label: "Enable HSN/SAC Code" },
    { key: "additionalCess", label: "Additional Cess On Item" },
    { key: "enablePlaceOfSupply", label: "Enable Place of Supply" },
  ];

  return (
    <div>
      <div className="card" style={{ margin: "0 -25px 0 -20px", marginTop: "-115px" }}>
        <div className="card-body">
          <div className="row">
            <div className="col-12">

              {/* Top Navigation Bar */}
              <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "16px" }}>
                <div onClick={() => navigate(-1)} style={{ cursor: "pointer", fontSize: "16px", color: "#333" }}>
                  <i className="fa-solid fa-arrow-left"></i>
                </div>
                <div onClick={() => navigate(-1)} style={{ cursor: "pointer", fontSize: "18px", color: "#555" }}>
                  <i className="fa-solid fa-xmark"></i>
                </div>
              </div>

              {/* GST Settings Card */}
              <div style={{ backgroundColor: "#fff", border: "1px solid #e0e0e0", borderRadius: "8px", padding: "20px", maxWidth: "420px" }}>
                <h6 style={{ fontWeight: "700", marginBottom: "12px", fontSize: "15px" }}>
                  GST Settings
                </h6>
                <hr style={{ marginBottom: "16px" }} />

                {checkboxItems.map((item) => (
                  <div key={item.key} style={{ display: "flex", alignItems: "center", gap: "10px", marginBottom: "14px" }}>
                    <input
                      type="checkbox"
                      id={item.key}
                      checked={gstSettings[item.key]}
                      onChange={() => handleChange(item.key)}
                      disabled={!isEdit}
                      style={{ width: "17px", height: "17px", accentColor: "#1a6fdb", cursor: "pointer" }}
                    />
                    <label htmlFor={item.key} style={{ margin: 0, fontSize: "14px", color: "#333", cursor: "pointer" }}>
                      {item.label}
                    </label>
                    <i className="fa-solid fa-circle-info" style={{ color: "#aaa", fontSize: "13px" }}></i>
                  </div>
                ))}

                {/* Tax List Button
                <button
                  onClick={() => navigate("/settings/taxlist")}
                  style={{ marginTop: "6px", backgroundColor: "#f0f0f0", border: "1px solid #ccc", borderRadius: "6px", padding: "6px 14px", fontSize: "13px", color: "#1a6fdb", cursor: "pointer", fontWeight: "500" }}>
                  Tax List &gt;
                </button> */}

                {/* Save / Edit Button */}
                {canCreate && (
                <div style={{ display: "flex", justifyContent: "flex-end", marginTop: "16px" }}>
                  {isEdit ? (
                    <button className="btn btn-primary" onClick={handleSave}>Save</button>
                  ) : (
                    <button className="btn btn-success" onClick={() => setIsEdit(true)}>Edit</button>
                  )}
                </div>
                )}
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default TaxesGST;