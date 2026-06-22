import React, { useState, useEffect, useContext } from "react";
import { useNavigate, useLocation } from "react-router-dom";
import Swal from "sweetalert2";
import withReactContent from "sweetalert2-react-content";
import axios from "axios";
import baseUrl from "../api/utils";
import "../assets/css/invoicestyle.css";

const TRANSACTION_TYPES = [
   "Sale Invoice",
  "Invoice POS", "Estimate Quotation", "Add Item", "View Item",
  "Customer", "Parties", "Stock Adjustment",
];

const PERMISSION_COLUMNS = ["VIEW", "CREATE", "EDIT", "DELETE"];

const DEFAULT_CASHIER_PERMISSIONS = {
 // "Dashboard":           { VIEW: true,  CREATE: false, EDIT: false, DELETE: false },
  // "Settings":            { VIEW: false, CREATE: false, EDIT: false, DELETE: false },
  // "My Company":          { VIEW: false, CREATE: false, EDIT: false, DELETE: false },
  "Sale Invoice":        { VIEW: true,  CREATE: true,  EDIT: false, DELETE: false },
  "Invoice POS":         { VIEW: true,  CREATE: true,  EDIT: false, DELETE: false },
  "Estimate Quotation":  { VIEW: true,  CREATE: true,  EDIT: false, DELETE: false },
  "Add Item":            { VIEW: true,  CREATE: true,  EDIT: false, DELETE: false },
  "View Item":           { VIEW: true,  CREATE: false, EDIT: false, DELETE: false },
  "Customer":            { VIEW: true,  CREATE: false, EDIT: false, DELETE: false },
  "Parties":             { VIEW: true,  CREATE: false, EDIT: false, DELETE: false },
  "Stock Adjustment":    { VIEW: false, CREATE: false, EDIT: false, DELETE: false },
};

const PermIcon = ({ state, onClick }) => {
  if (state === true)
    return (
      <button type="button" className="au-perm-btn au-perm-yes" onClick={onClick}>
        <i className="fa-solid fa-check"></i>
      </button>
    );
  return (
    <button type="button" className="au-perm-btn au-perm-no" onClick={onClick}>
      <i className="fa-solid fa-xmark"></i>
    </button>
  );
};

const AddUsers = () => {
  const MySwal = withReactContent(Swal);
  const navigate = useNavigate();
  const location = useLocation();
  const token = sessionStorage.getItem("token");

  // ── Detect edit mode from URL ──
  const editEmail = new URLSearchParams(location.search).get("edit");
  const isEditMode = !!editEmail;

  // Form fields
  const [fullName, setFullName] = useState("");
  const [email, setEmail]       = useState("");
  const [phone, setPhone]       = useState("");
  const [userId, setUserId]     = useState(null);
  const [loading, setLoading]   = useState(false);
  const [fetchLoading, setFetchLoading] = useState(false);

  // Build permissions from default
  const buildPerms = () => {
    return TRANSACTION_TYPES.reduce((acc, t) => {
      acc[t] = {
        ...(DEFAULT_CASHIER_PERMISSIONS[t] || {
          VIEW: false, CREATE: false, EDIT: false, DELETE: false,
        }),
      };
      return acc;
    }, {});
  };

  const [permissions, setPermissions] = useState(buildPerms());

  // ── If edit mode → fetch existing cashier + permissions ──
  useEffect(() => {
    if (isEditMode && editEmail) {
      fetchCashierData(editEmail);
    }
  }, [editEmail]);

  const fetchCashierData = async (email) => {
    try {
      setFetchLoading(true);

      // Step 1 — Get cashier details by email
      const userRes = await axios.get(
        `${baseUrl}/admin/getCashierByEmail`,
        {
          params: { email },
          headers: { Authorization: token }
        }
      );

      const cashier = userRes.data;
      setFullName(cashier.username || "");
      setEmail(cashier.email || "");
      setPhone(cashier.phone || "");
      setUserId(cashier.userId);

      // Step 2 — Get existing permissions by userId
      const permRes = await axios.get(
        `${baseUrl}/cashier/permissions/${cashier.userId}`,
        { headers: { Authorization: token } }
      );

      // Convert array → grid format
      // [{moduleName, canView, canCreate, canEdit, canDelete}]
      // → { "Sale Invoice": { VIEW: true, CREATE: true, ... } }
      const permObj = buildPerms(); // start with defaults
      permRes.data.forEach((p) => {
        permObj[p.moduleName] = {
          VIEW:   p.canView,
          CREATE: p.canCreate,
          EDIT:   p.canEdit,
          DELETE: p.canDelete,
        };
      });
      setPermissions(permObj);

    } catch (err) {
      console.error("Error fetching cashier:", err);
      MySwal.fire("Error", "Failed to load cashier data.", "error");
    } finally {
      setFetchLoading(false);
    }
  };

  // Toggle single cell
  const togglePermission = (txn, col) => {
    setPermissions((prev) => ({
      ...prev,
      [txn]: { ...prev[txn], [col]: !prev[txn][col] },
    }));
  };

  // Toggle entire column
  const toggleColumn = (col) => {
    const allTrue = TRANSACTION_TYPES.every((t) => permissions[t][col]);
    setPermissions((prev) => {
      const updated = { ...prev };
      TRANSACTION_TYPES.forEach((t) => {
        updated[t] = { ...updated[t], [col]: !allTrue };
      });
      return updated;
    });
  };

  // Toggle entire row
  const toggleRow = (txn) => {
    const allTrue = PERMISSION_COLUMNS.every((c) => permissions[txn][c]);
    setPermissions((prev) => ({
      ...prev,
      [txn]: PERMISSION_COLUMNS.reduce((acc, c) => {
        acc[c] = !allTrue;
        return acc;
      }, {}),
    }));
  };

  // ── Submit ────────────────────────────────────────────────
  const handleSubmit = async () => {

    // Build permissions payload
    const permissionsPayload = TRANSACTION_TYPES.map((txn) => ({
      moduleName: txn,
      canView:    permissions[txn].VIEW,
      canCreate:  permissions[txn].CREATE,
      canEdit:    permissions[txn].EDIT,
      canDelete:  permissions[txn].DELETE,
    }));

    try {
      setLoading(true);

      if (isEditMode) {
        // ── EDIT MODE → update permissions only ──
        await axios.put(
          `${baseUrl}/admin/cashier/permissions/${userId}`,
          permissionsPayload,
          { headers: { Authorization: token } }
        );
        MySwal.fire("Success", "Permissions updated. Cashier must re-login to see changes.", "success")
          .then(() => navigate(-1));

      } else {
        // ── ADD MODE → validations + add cashier ──
        if (!fullName.trim()) {
          MySwal.fire("Required", "Please enter full name.", "warning");
          return;
        }
        if (!email.trim()) {
          MySwal.fire("Required", "Please enter email.", "warning");
          return;
        }
        if (!phone.trim()) {
          MySwal.fire("Required", "Please enter phone number.", "warning");
          return;
        }
        if (phone.trim().length < 10) {
          MySwal.fire("Invalid", "Please enter valid 10 digit phone number.", "warning");
          return;
        }

        const payload = {
          username:    fullName.trim(),
          email:       email.trim(),
          phone:       phone.trim(),
          permissions: permissionsPayload,
        };

        const response = await axios.post(
          `${baseUrl}/admin/addCashier`,
          payload,
          { headers: { Authorization: token } }
        );

        if (response.status === 200 || response.status === 201) {
          MySwal.fire("Success", "Cashier added successfully.", "success")
            .then(() => navigate(-1));
        }
      }

    } catch (error) {
      if (error.response?.status === 401) {
        navigate("/unauthorized");
      } else if (error.response?.data === "EMAIL") {
        MySwal.fire("Duplicate", "This email is already registered.", "warning");
      } else {
        MySwal.fire(
          "Error",
          error.response?.data?.message || "Failed to save.",
          "error"
        );
      }
    } finally {
      setLoading(false);
    }
  };

  const handleCancel = () => navigate(-1);

  // ─── Render ───────────────────────────────────────────────
  return (
    <div>
      <div className="invoice-card-wrapper" style={{ marginTop: "-115px" }}>
        <div>
          <div className="card invoice-card">
            <div className="card-body p-0">
              <div className="invoice-panel-layout">

                {/* ── LEFT PANEL ── */}
                <div className="invoice-left-panel au-left-panel">
                  <div className="invoice-left-panel-header">
                    <div className="vt-left-header-inner">
                      <h6 className="invoice-left-panel-title">
                        {isEditMode ? "Update Permissions" : "Add User"}
                      </h6>
                    </div>
                  </div>

                  {fetchLoading ? (
                    <div className="text-center p-4">
                      <div className="spinner-border spinner-border-sm text-danger"></div>
                    </div>
                  ) : (
                    <div className="au-form-section">

                      {/* Full Name */}
                      <div className="au-field-group">
                        <label className="au-label">
                          Enter Full Name <span className="au-required">*</span>
                        </label>
                        <input
                          type="text"
                          className="form-control form-control-sm au-input"
                          placeholder="Enter full name"
                          value={fullName}
                          onChange={(e) => setFullName(e.target.value)}
                          disabled={isEditMode}
                        />
                      </div>

                      {/* Email */}
                      <div className="au-field-group">
                        <label className="au-label">
                          Enter Email <span className="au-required">*</span>
                        </label>
                        <input
                          type="email"
                          className="form-control form-control-sm au-input"
                          placeholder="Enter email"
                          value={email}
                          onChange={(e) => setEmail(e.target.value)}
                          disabled={isEditMode}
                        />
                        {!isEditMode && (
                          <small className="au-hint">
                            Cashier will receive login credentials on this email.
                          </small>
                        )}
                      </div>

                      {/* Phone */}
                      <div className="au-field-group">
                        <label className="au-label">
                          Enter Phone Number <span className="au-required">*</span>
                        </label>
                        <input
                          type="text"
                          className="form-control form-control-sm au-input"
                          placeholder="Enter phone number"
                          value={phone}
                          onChange={(e) => setPhone(e.target.value)}
                          disabled={isEditMode}
                        />
                      </div>

                      {/* Role */}
                      <div className="au-field-group">
                        <label className="au-label">
                          Choose User Role <span className="au-required">*</span>
                        </label>
                        <select
                          className="form-control form-control-sm au-input"
                          value="CASHIER"
                          disabled
                        >
                          <option value="CASHIER">Cashier</option>
                        </select>
                      </div>

                    </div>
                  )}

                  {/* Action Buttons */}
                  <div className="au-action-row">
                    <button
                      className="btn btn-sm au-cancel-btn"
                      onClick={handleCancel}
                      disabled={loading}
                    >
                      Cancel
                    </button>
                    <button
                      className="btn btn-primary btn-sm as-btn-save"
                      onClick={handleSubmit}
                      disabled={loading || fetchLoading}
                    >
                      {loading ? (
                        <span className="spinner-border spinner-border-sm mr-1"></span>
                      ) : isEditMode ? (
                        <><i className="fa-solid fa-floppy-disk mr-1"></i> Update</>
                      ) : (
                        <><i className="fa-solid fa-user-plus mr-1"></i> Add User</>
                      )}
                    </button>
                  </div>
                </div>

                {/* ── RIGHT PANEL ── */}
                <div className="invoice-right-panel au-right-panel">
                  <div className="invoice-right-panel-header">
                    <div className="vt-right-header-left">
                      <h6 className="invoice-right-panel-title">
                        Cashier Permissions
                      </h6>
                    </div>
                    <div className="vt-right-header-right">
                      <button
                        className="btn btn-sm au-reset-btn"
                        onClick={() => setPermissions(buildPerms())}
                        title="Reset to defaults"
                      >
                        <i className="fa-solid fa-rotate-right mr-1"></i> Reset
                      </button>
                    </div>
                  </div>

                  <div className="invoice-details-section au-perm-section">
                    <div style={{ overflowX: "auto", width: "100%" }}>
                      <table className="table table-hover table-bordered table-sm invoice-table au-perm-table">
                        <thead>
                          <tr>
                            <th className="au-txn-col">Transactions</th>
                            {PERMISSION_COLUMNS.map((col) => (
                              <th
                                key={col}
                                className="au-perm-col"
                                onClick={() => toggleColumn(col)}
                                style={{ cursor: "pointer" }}
                              >
                                {col}
                              </th>
                            ))}
                          </tr>
                        </thead>
                        <tbody>
                          {TRANSACTION_TYPES.map((txn) => (
                            <tr key={txn}>
                              <td
                                className="au-txn-name"
                                onClick={() => toggleRow(txn)}
                                style={{ cursor: "pointer" }}
                              >
                                {txn}
                              </td>
                              {PERMISSION_COLUMNS.map((col) => (
                                <td key={col} className="au-perm-cell">
                                  <PermIcon
                                    state={permissions[txn][col]}
                                    onClick={() => togglePermission(txn, col)}
                                  />
                                </td>
                              ))}
                            </tr>
                          ))}
                        </tbody>
                      </table>
                    </div>
                  </div>
                </div>

              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Scoped styles — same as before */}
      <style>{`
        .au-left-panel { width: 320px; min-width: 260px; max-width: 340px; display: flex; flex-direction: column; }
        .au-right-panel { flex: 1; display: flex; flex-direction: column; overflow: hidden; }
        .au-form-section { padding: 14px 16px; display: flex; flex-direction: column; gap: 14px; flex: 1; }
        .au-field-group { display: flex; flex-direction: column; gap: 4px; }
        .au-label { font-size: 11.5px; font-weight: 600; color: #444; margin: 0; }
        .au-required { color: #e53935; }
        .au-input { font-size: 12.5px; border: 1px solid #d0d7de; border-radius: 5px; color: #222; }
        .au-input:disabled { background: #f5f5f5; color: #999; }
        .au-hint { font-size: 10.5px; color: #888; margin-top: 2px; }
        .au-action-row { display: flex; align-items: center; justify-content: flex-end; gap: 8px; padding: 12px 16px; border-top: 1px solid #e8ecef; background: #fafbfc; }
        .au-cancel-btn { background: #fff; border: 1px solid #ccc; color: #555; font-size: 12px; padding: 5px 14px; border-radius: 5px; }
        .au-reset-btn { background: #fff; border: 1px solid #ccc; color: #555; font-size: 11.5px; padding: 4px 12px; border-radius: 5px; }
        .au-perm-section { flex: 1; padding: 0 12px 12px; overflow: auto; }
        .au-perm-table th { font-size: 11px; font-weight: 700; text-align: center; background: #f4f7f6; color: #1a7a6e; border-bottom: 2px solid #c8eae6; padding: 7px 6px; }
        .au-perm-table th.au-txn-col { text-align: left; color: #444; width: 180px; }
        .au-perm-table th.au-perm-col { min-width: 68px; }
        .au-txn-name { font-size: 12px; color: #333; font-weight: 500; padding: 6px 8px; white-space: nowrap; user-select: none; }
        .au-txn-name:hover { background: #e6f4f2; }
        .au-perm-cell { text-align: center; padding: 4px; vertical-align: middle; }
        .au-perm-btn { background: none; border: none; cursor: pointer; padding: 2px 6px; font-size: 13px; border-radius: 4px; line-height: 1; }
        .au-perm-yes { color: #1a9e6e; }
        .au-perm-no { color: #e53935; }
      `}</style>
    </div>
  );
};

export default AddUsers;