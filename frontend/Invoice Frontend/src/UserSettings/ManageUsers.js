import React, { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import axios from "axios";
import baseUrl from "../api/utils";
import "../assets/css/invoicestyle.css";

const ManageUsers = () => {
  const token = sessionStorage.getItem("token");
  const navigate = useNavigate();

  const [cashiers, setCashiers] = useState([]);
  const [loading, setLoading] = useState(false);
  const [searchQuery, setSearchQuery] = useState("");

  // Deactivate modal state
  const [showDeactivateModal, setShowDeactivateModal] = useState(false);
  const [deactivateEmail, setDeactivateEmail] = useState("");
  const [deactivateReason, setDeactivateReason] = useState("");
  const [actionLoading, setActionLoading] = useState(false);

  // ── FETCH CASHIERS ──────────────────────────────────────────
  const fetchCashiers = async () => {
    try {
      setLoading(true);
      const response = await axios.get(`${baseUrl}/admin/getCashiers`, {
        headers: { Authorization: token },
      });
      if (response.status === 200) {
        setCashiers(response.data || []);
      }
    } catch (error) {
      console.error("Error fetching cashiers:", error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchCashiers();
  }, []);

  // ── FILTERED LIST ───────────────────────────────────────────
  const filteredCashiers = cashiers.filter((c) => {
    const q = searchQuery.toLowerCase();
    return (
      c.username?.toLowerCase().includes(q) ||
      c.email?.toLowerCase().includes(q) ||
      c.phone?.toLowerCase().includes(q)
    );
  });

  // ── OPEN DEACTIVATE MODAL ───────────────────────────────────
  const openDeactivate = (email) => {
    setDeactivateEmail(email);
    setDeactivateReason("");
    setShowDeactivateModal(true);
  };

  // ── CONFIRM DEACTIVATE ──────────────────────────────────────
  const confirmDeactivate = async () => {
    if (!deactivateReason.trim()) {
      alert("Please enter a reason.");
      return;
    }
    try {
      setActionLoading(true);
      await axios.delete(`${baseUrl}/admin/deactivate/cashier`, {
        params: { email: deactivateEmail, reason: deactivateReason },
        headers: { Authorization: token },
      });
      setShowDeactivateModal(false);
      fetchCashiers(); // refresh table
    } catch (error) {
      console.error("Deactivate error:", error);
      alert("Failed to deactivate cashier.");
    } finally {
      setActionLoading(false);
    }
  };

  // ── ACTIVATE ────────────────────────────────────────────────
  const handleActivate = async (email) => {
    try {
      setActionLoading(true);
      await axios.delete(`${baseUrl}/admin/activate/cashier`, {
        params: { email },
        headers: { Authorization: token },
      });
      fetchCashiers(); // refresh table
    } catch (error) {
      console.error("Activate error:", error);
      alert("Failed to activate cashier.");
    } finally {
      setActionLoading(false);
    }
  };

  // ───────────────────────────────────────────────────────────
  return (
    <div>
      <div className="invoice-card-wrapper" style={{ marginTop: "-115px" }}>
        <div>
          <div className="card invoice-card">
            <div className="card-body p-0">

              {/* ── TOP BAR ── */}
              <div
                className="d-flex align-items-center justify-content-between px-3 py-2 border-bottom"
                style={{ gap: "12px", flexWrap: "wrap" }}
              >
                <div className="input-group input-group-sm" style={{ maxWidth: "300px" }}>
                  <div className="input-group-prepend">
                    <span className="input-group-text bg-white border-right-0">
                      <i className="fa-solid fa-magnifying-glass" style={{ color: "#aaa", fontSize: "13px" }}></i>
                    </span>
                  </div>
                  <input
                    type="text"
                    className="form-control border-left-0"
                    placeholder="Search Transactions"
                    value={searchQuery}
                    onChange={(e) => setSearchQuery(e.target.value)}
                    style={{ boxShadow: "none", fontSize: "13px" }}
                  />
                </div>

                <div className="d-flex align-items-center" style={{ gap: "8px" }}>
                  <button
                    className="btn btn-sm"
                    onClick={() => navigate("/addusers")}
                    style={{
                      background: "#fff0f0", color: "#e74c3c",
                      border: "1px solid #f5c6c6", fontWeight: "600",
                      fontSize: "13px", borderRadius: "6px", padding: "5px 14px",
                    }}
                  >
                    <i className="fa-solid fa-plus mr-1"></i> Add Sale
                  </button>
                  <button className="btn btn-sm btn-light" style={{ borderRadius: "6px", padding: "5px 9px" }}>
                    <i className="fa-solid fa-print" style={{ fontSize: "13px", color: "#555" }}></i>
                  </button>
                  <button className="btn btn-sm btn-light" style={{ borderRadius: "6px", padding: "5px 9px" }}>
                    <i className="fa-solid fa-ellipsis-vertical" style={{ fontSize: "13px", color: "#555" }}></i>
                  </button>
                </div>
              </div>

              {/* ── TITLE ROW ── */}
              <div className="d-flex align-items-center justify-content-between px-3 py-2 border-bottom">
                <h5 className="mb-0 font-weight-bold" style={{ fontSize: "16px" }}>Manage Users</h5>
                <div className="d-flex align-items-center" style={{ gap: "8px" }}>
                  <button
                    className="btn btn-danger btn-sm"
                    onClick={() => navigate("/addusers")}
                    style={{ fontWeight: "600", borderRadius: "6px", padding: "5px 16px" }}
                  >
                    <i className="fa-solid fa-plus mr-1"></i> Add Users
                  </button>
                  <button className="btn btn-sm btn-light" style={{ borderRadius: "6px", padding: "5px 9px" }}>
                    <i className="fa-solid fa-gear" style={{ color: "#555" }}></i>
                  </button>
                </div>
              </div>

              {/* ── TABLE or EMPTY or LOADING ── */}
              {loading ? (
                <div className="text-center py-5">
                  <div className="spinner-border text-danger"></div>
                </div>

              ) : filteredCashiers.length === 0 ? (

                <div
                  className="d-flex flex-column align-items-center justify-content-center"
                  style={{ paddingTop: "30px", paddingBottom: "50px" }}
                >
                  <div
                    style={{
                      width: "100px", height: "100px", background: "#e8f4fd",
                      borderRadius: "50%", display: "flex", alignItems: "center",
                      justifyContent: "center", marginBottom: "16px",
                      boxShadow: "0 4px 16px rgba(47,128,237,0.10)",
                    }}
                  >
                    <i className="fa-solid fa-file-invoice-dollar" style={{ fontSize: "40px", color: "#2f80ed" }}></i>
                  </div>
                  <p style={{ fontSize: "15px", fontWeight: "600", color: "#333", marginBottom: "4px" }}>
                    You haven't added any users till now
                  </p>
                  <p style={{ fontSize: "13px", color: "#aaa", marginBottom: "18px" }}>
                    Add users, assign roles and let your employees manage your business.
                  </p>
                  <button
                    className="btn btn-danger"
                    onClick={() => navigate("/addusers")}
                    style={{ borderRadius: "8px", fontWeight: "600", padding: "8px 24px", fontSize: "14px" }}
                  >
                    <i className="fa-solid fa-plus mr-2"></i> Add Users
                  </button>
                </div>

              ) : (

                <div className="px-3 pt-2">
                  <table
                    className="table table-hover table-bordered table-sm invoice-table"
                    style={{ fontSize: "13px" }}
                  >
                    <thead style={{ background: "#f8f9fa" }}>
                      <tr>
                        <th>#</th>
                        <th>Username</th>
                        <th>Email</th>
                        <th>Phone</th>
                        <th>Status</th>
                        <th style={{ textAlign: "center" }}>Action</th>
                      </tr>
                    </thead>
                    <tbody>
                      {filteredCashiers.map((cashier, idx) => (
                        <tr key={cashier.userId || idx}>
                          <td>{idx + 1}</td>
                          <td>{cashier.username}</td>
                          <td>{cashier.email}</td>
                          <td>{cashier.phone}</td>
                          <td>
                            {cashier.isActive ? (
                              <span
                                style={{
                                  background: "#e6f9f0", color: "#27ae60",
                                  padding: "3px 10px", borderRadius: "20px",
                                  fontWeight: "600", fontSize: "12px",
                                }}
                              >
                                ● Active
                              </span>
                            ) : (
                              <span
                                style={{
                                  background: "#fff0f0", color: "#e74c3c",
                                  padding: "3px 10px", borderRadius: "20px",
                                  fontWeight: "600", fontSize: "12px",
                                }}
                              >
                                ● Inactive
                              </span>
                            )}
                          </td>
                          <td style={{ textAlign: "center" }}>
                            <div className="d-flex justify-content-center" style={{ gap: "6px" }}>

                              {/* UPDATE button */}
                              <button
                                className="btn btn-sm"
                                title="Update"
                                style={{
                                  background: "#eaf3ff", color: "#2f80ed",
                                  border: "1px solid #c5dcff", borderRadius: "6px",
                                  padding: "4px 10px",
                                }}
                                onClick={() => navigate(`/addusers?edit=${cashier.email}`)}
                              >
                                <i className="fa-solid fa-pen"></i>
                              </button>

                              {/* DEACTIVATE / ACTIVATE toggle */}
                              {cashier.isActive ? (
                                <button
                                  className="btn btn-sm"
                                  title="Deactivate"
                                  style={{
                                    background: "#fff0f0", color: "#e74c3c",
                                    border: "1px solid #f5c6c6", borderRadius: "6px",
                                    padding: "4px 10px",
                                  }}
                                  onClick={() => openDeactivate(cashier.email)}
                                  disabled={actionLoading}
                                >
                                  <i className="fa-solid fa-ban"></i>
                                </button>
                              ) : (
                                <button
                                  className="btn btn-sm"
                                  title="Activate"
                                  style={{
                                    background: "#e6f9f0", color: "#27ae60",
                                    border: "1px solid #b2dfc9", borderRadius: "6px",
                                    padding: "4px 10px",
                                  }}
                                  onClick={() => handleActivate(cashier.email)}
                                  disabled={actionLoading}
                                >
                                  <i className="fa-solid fa-circle-check"></i>
                                </button>
                              )}

                            </div>
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              )}

            </div>
          </div>
        </div>
      </div>

      {/* ── DEACTIVATE REASON MODAL ── */}
      {showDeactivateModal && (
        <div
          style={{
            position: "fixed", top: 0, left: 0, width: "100vw", height: "100vh",
            background: "rgba(0,0,0,0.4)", zIndex: 9999,
            display: "flex", alignItems: "center", justifyContent: "center",
          }}
        >
          <div
            style={{
              background: "#fff", borderRadius: "12px", padding: "28px 32px",
              minWidth: "360px", boxShadow: "0 8px 32px rgba(0,0,0,0.18)",
            }}
          >
            <h6 style={{ fontWeight: "700", marginBottom: "6px" }}>Deactivate Cashier</h6>
            <p style={{ fontSize: "13px", color: "#888", marginBottom: "16px" }}>
              Enter a reason for deactivating <strong>{deactivateEmail}</strong>
            </p>
            <textarea
              className="form-control"
              rows={3}
              placeholder="Enter reason..."
              value={deactivateReason}
              onChange={(e) => setDeactivateReason(e.target.value)}
              style={{ fontSize: "13px", marginBottom: "16px", resize: "none" }}
            />
            <div className="d-flex justify-content-end" style={{ gap: "10px" }}>
              <button
                className="btn btn-sm btn-light"
                onClick={() => setShowDeactivateModal(false)}
                style={{ borderRadius: "6px", padding: "6px 18px" }}
              >
                Cancel
              </button>
              <button
                className="btn btn-sm btn-danger"
                onClick={confirmDeactivate}
                disabled={actionLoading}
                style={{ borderRadius: "6px", padding: "6px 18px", fontWeight: "600" }}
              >
                {actionLoading ? "Processing..." : "Deactivate"}
              </button>
            </div>
          </div>
        </div>
      )}

    </div>
  );
};

export default ManageUsers;