import React, { useEffect, useState, useRef } from "react";
import { useNavigate } from "react-router-dom";
import axios from "axios";
import baseUrl from "../api/utils";
import "../assets/css/invoicestyle.css";
import DatePicker from "react-datepicker";
import "react-datepicker/dist/react-datepicker.css";
import Swal from "sweetalert2";
import withReactContent from "sweetalert2-react-content";
import { getPermission } from "../utils/permissionUtils";
import MODULES from "../utils/modules";

const EstimateQuotation = () => {
  const token = sessionStorage.getItem("token");
  const MySwal = withReactContent(Swal);

  const navigate = useNavigate();
  const canCreate = getPermission(MODULES.ESTIMATE_QUOTATION, "canCreate");
  const canEdit   = getPermission(MODULES.ESTIMATE_QUOTATION, "canEdit");
  const canDelete = getPermission(MODULES.ESTIMATE_QUOTATION, "canDelete");

  const [invoices, setInvoices] = useState([]);
  const [loading, setLoading] = useState(false);
  const [searchQuery, setSearchQuery] = useState("");

  const [filterUser, setFilterUser] = useState("All Users");
  const [dropdownOpen, setDropdownOpen] = useState(false);
  const dropdownRef = useRef(null);
  const [filterMonth, setFilterMonth] = useState("This Month");
  const today = new Date();
  const [dateFrom, setDateFrom] = useState(new Date(today.getFullYear(), today.getMonth(), 1));
  const [dateTo, setDateTo]     = useState(new Date(today.getFullYear(), today.getMonth() + 1, 0));
  const [showCalendar, setShowCalendar] = useState(false);
  const [monthDropdownOpen, setMonthDropdownOpen] = useState(false);
  const monthRef = useRef(null);
  const calendarRef = useRef(null);

  const monthOptions = ["All Estimates", "This Month", "Last Month", "This Year"];

  const [totalSales, setTotalSales] = useState(0);
  const [received, setReceived] = useState(0);
  const [balance, setBalance] = useState(0);
  const [showViewModal, setShowViewModal] = useState(false);
  const [viewInvoice, setViewInvoice] = useState(null);
  const [viewLoading, setViewLoading] = useState(false);
  const [myCompany, setMyCompany] = useState(null);
  const [downloadingId, setDownloadingId] = useState(null);

  // ── FETCH ESTIMATES ─────────────────────────────────
  const fetchInvoices = async () => {
  try {
    setLoading(true);
    const params = new URLSearchParams();

    if (filterMonth === "All Estimates") {
      params.append("fromDate", "2000-01-01");
      params.append("toDate", "2099-12-31");
    } else {
      params.append("fromDate", dateFrom.toISOString().split("T")[0]);
      params.append("toDate", dateTo.toISOString().split("T")[0]);
    }

    if (filterUser !== "All Users") {
      params.append("createdBy", filterUser);
    }

    params.append("billTypes", "ESTIMATE"); // ← key change

    const res = await axios.get(`${baseUrl}/getBillsFiltered?${params.toString()}`, {
      headers: { Authorization: token },
    });

    const data = res.status === 200 ? res.data : [];
    data.sort((a, b) => new Date(b.invoiceDate) - new Date(a.invoiceDate));

    setInvoices(data);
    const total = data.reduce((sum, inv) => sum + (inv.grandTotal || 0), 0);
    const recv  = data.reduce((sum, inv) => sum + (inv.amountReceived || 0), 0);
    const bal   = data.reduce((sum, inv) => sum + (inv.balanceAmount || 0), 0);
    setTotalSales(total);
    setReceived(recv);
    setBalance(bal);
  } catch (error) {
    console.error("Error fetching estimates:", error);
  } finally {
    setLoading(false);
  }
};
 useEffect(() => { fetchInvoices(); }, [filterMonth, dateFrom, dateTo, filterUser]);

  useEffect(() => {
  const fetchCompany = async () => {
    try {
      const res = await axios.get(`${baseUrl}/admin/getMyCompany`, {
        headers: { Authorization: token },
      });
      setMyCompany(res.data);
    } catch (error) {
      console.error("Error fetching company details:", error);
    }
  };
  fetchCompany();
}, []);



  // ── SEARCH FILTER ───────────────────────────────────
  const filteredInvoices = invoices.filter((inv) => {
    const q = searchQuery.toLowerCase();
    return (
      inv.billType?.toLowerCase().includes(q) ||
      inv.invoiceNumber?.toString().includes(q) ||
      inv.partyName?.toLowerCase().includes(q)
    );
  });

  // ── USER FILTER OPTIONS ─────────────────────────────
  const userOptions = [
    { label: "All Users", initials: "AU", bg: "#e8f0fe", color: "#1a73e8" },
    { label: "Admin",     initials: "AD", bg: "#fce8e6", color: "#d93025" },
    { label: "Cashier",   initials: "CA", bg: "#e6f4ea", color: "#137333" },
  ];
  const selected = userOptions.find((u) => u.label === filterUser);

  useEffect(() => {
    const handler = (e) => {
      if (dropdownRef.current && !dropdownRef.current.contains(e.target))
        setDropdownOpen(false);
    };
    document.addEventListener("mousedown", handler);
    return () => document.removeEventListener("mousedown", handler);
  }, []);

  const applyDateRange = (option) => {
    const today = new Date();
    const year  = today.getFullYear();
    const month = today.getMonth();
    if (option === "This Month") {
      setDateFrom(new Date(year, month, 1));
      setDateTo(new Date(year, month + 1, 0));
      setShowCalendar(false);
    } else if (option === "Last Month") {
      setDateFrom(new Date(year, month - 1, 1));
      setDateTo(new Date(year, month, 0));
      setShowCalendar(false);
    } else if (option === "This Year") {
      setDateFrom(new Date(year, 0, 1));
      setDateTo(new Date(year, 11, 31));
      setShowCalendar(false);
    } else if (option === "All Estimates") {
      setShowCalendar(true);
    }
  };

  const handleMonthSelect = (option) => {
    setFilterMonth(option);
    applyDateRange(option);
    setMonthDropdownOpen(false);
  };

  const formatDate = (date) =>
    date.toLocaleDateString("en-GB").replace(/\//g, "/");

  useEffect(() => {
    const handler = (e) => {
      if (monthRef.current && !monthRef.current.contains(e.target))
        setMonthDropdownOpen(false);
      if (calendarRef.current && !calendarRef.current.contains(e.target))
        setShowCalendar(false);
    };
    document.addEventListener("mousedown", handler);
    return () => document.removeEventListener("mousedown", handler);
  }, []);

  const handleDelete = async (id) => {
  const result = await MySwal.fire({
    title: "Delete Invoice?",
    text: "This action cannot be undone.",
    icon: "warning",
    showCancelButton: true,
    confirmButtonColor: "#e74c3c",
    cancelButtonColor: "#aaa",
    confirmButtonText: "Yes, Delete",
  });

  if (result.isConfirmed) {
    try {
      await axios.delete(`${baseUrl}/deleteBill/${id}`, {
        headers: { Authorization: token },
      });
      MySwal.fire("Deleted!", "Invoice deleted successfully.", "success");
      fetchInvoices();
    } catch (error) {
      MySwal.fire("Error", "Failed to delete invoice.", "error");
    }
  }
};


const handleView = async (id) => {
  setShowViewModal(true);
  setViewLoading(true);
  try {
    const res = await axios.get(`${baseUrl}/getBill/${id}`, {
      headers: { Authorization: token },
    });
    setViewInvoice(res.data);
  } catch (error) {
    MySwal.fire("Error", "Failed to load estimate.", "error");
    setShowViewModal(false);
  } finally {
    setViewLoading(false);
  }
};

const handleDownload = async (id, invoiceNumber) => {
  setDownloadingId(id);
  try {
    const res = await axios.get(`${baseUrl}/downloadBill/${id}`, {
      headers: { Authorization: token },
      responseType: "blob",
    });
    const blob = new Blob([res.data], { type: "application/pdf" });
    const url = window.URL.createObjectURL(blob);
    const link = document.createElement("a");
    link.href = url;
    link.download = `Estimate_${invoiceNumber}.pdf`;
    document.body.appendChild(link);
    link.click();
    link.remove();
    window.URL.revokeObjectURL(url);
  } catch (error) {
    MySwal.fire("Error", "Failed to download estimate.", "error");
  } finally {
    setDownloadingId(null);
  }
};

  // ── RENDER ──────────────────────────────────────────
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
                  <button className="btn btn-sm btn-light" style={{ borderRadius: "6px", padding: "5px 9px" }}>
                    <i className="fa-solid fa-print" style={{ fontSize: "13px", color: "#555" }}></i>
                  </button>
                </div>
              </div>

              {/* ── TITLE ROW ── */}
              <div className="d-flex align-items-center justify-content-between px-3 py-2 border-bottom">
                <h5 className="mb-0 font-weight-bold" style={{ fontSize: "16px" }}>Estimate Quotation</h5>
                  {canCreate && (
                <div className="d-flex align-items-center" style={{ gap: "8px" }}>
                  <button
                    className="btn btn-danger btn-sm"
                    onClick={() => navigate("/addestimate")}
                    style={{ fontWeight: "600", borderRadius: "6px", padding: "5px 16px" }}
                  >
                    <i className="fa-solid fa-plus mr-1"></i> Add Estimate
                  </button>
                  {/* <button className="btn btn-sm btn-light" style={{ borderRadius: "6px", padding: "5px 9px" }}>
                    <i className="fa-solid fa-gear" style={{ color: "#555" }}></i>
                  </button> */}
                </div>
                  )}
              </div>

              {/* ── FILTER BAR ── */}
              <div
                className="d-flex align-items-center px-3 py-2 border-bottom"
                style={{ background: "#fafafa", gap: "10px", flexWrap: "wrap" }}
              >
                <span style={{ fontSize: "13px", color: "#555", fontWeight: "500" }}>Filter by :</span>

                {/* Month Dropdown */}
                <div ref={monthRef} style={{ position: "relative" }}>
                  <div
                    className="d-flex align-items-center"
                    onClick={() => setMonthDropdownOpen((p) => !p)}
                    style={{ border: "1px solid #ddd", borderRadius: "20px", padding: "3px 12px", background: "#fff", cursor: "pointer", gap: "6px", fontSize: "13px" }}
                  >
                    <span>{filterMonth}</span>
                    <i className="fa-solid fa-chevron-down" style={{ fontSize: "10px", color: "#888", transition: "transform 0.2s", transform: monthDropdownOpen ? "rotate(180deg)" : "rotate(0deg)" }}></i>
                  </div>
                  {monthDropdownOpen && (
                    <div style={{ position: "absolute", top: "calc(100% + 6px)", left: 0, minWidth: 180, background: "#fff", border: "0.5px solid #e0e0e0", borderRadius: 12, boxShadow: "0 4px 16px rgba(0,0,0,0.1)", zIndex: 200, padding: "6px 0" }}>
                      {monthOptions.map((opt) => (
                        <div
                          key={opt}
                          onClick={() => handleMonthSelect(opt)}
                          style={{ padding: "8px 16px", fontSize: 13, cursor: "pointer", display: "flex", justifyContent: "space-between", alignItems: "center", background: filterMonth === opt ? "#f5f5f5" : "transparent" }}
                        >
                          <span>{opt}</span>
                          {filterMonth === opt && <span style={{ color: "#1a73e8", fontSize: 13 }}>✓</span>}
                        </div>
                      ))}
                    </div>
                  )}
                </div>

                {/* Date Range */}
                <div ref={calendarRef} style={{ position: "relative" }}>
                  <div
                    className="d-flex align-items-center"
                    onClick={() => { if (filterMonth === "All Estimates") setShowCalendar((p) => !p); }}
                    style={{ border: "1px solid #ddd", borderRadius: "20px", padding: "3px 12px", background: "#fff", cursor: filterMonth === "All Estimates" ? "pointer" : "default", gap: "6px", fontSize: "13px" }}
                  >
                    <i className="fa-regular fa-calendar" style={{ color: "#888", fontSize: "12px" }}></i>
                    <span>{formatDate(dateFrom)}</span>
                    <span style={{ color: "#aaa" }}>To</span>
                    <span>{formatDate(dateTo)}</span>
                  </div>
                  {showCalendar && filterMonth === "All Estimates" && (
                    <div style={{ position: "absolute", top: "calc(100% + 6px)", left: 0, zIndex: 300, background: "#fff", border: "0.5px solid #e0e0e0", borderRadius: 12, boxShadow: "0 4px 16px rgba(0,0,0,0.12)", padding: 12, display: "flex", flexDirection: "column", gap: 10 }}>
                      <div style={{ fontSize: 12, color: "#888", marginBottom: 4 }}>Select date range</div>
                      <div className="d-flex align-items-center gap-2">
                        <span style={{ fontSize: 12, color: "#555", minWidth: 30 }}>From</span>
                        <DatePicker selected={dateFrom} onChange={(date) => setDateFrom(date)} selectsStart startDate={dateFrom} endDate={dateTo} dateFormat="dd/MM/yyyy" className="form-control form-control-sm" />
                      </div>
                      <div className="d-flex align-items-center gap-2">
                        <span style={{ fontSize: 12, color: "#555", minWidth: 30 }}>To</span>
                        <DatePicker selected={dateTo} onChange={(date) => setDateTo(date)} selectsEnd startDate={dateFrom} endDate={dateTo} minDate={dateFrom} dateFormat="dd/MM/yyyy" className="form-control form-control-sm" />
                      </div>
                    </div>
                  )}
                </div>
     
                {/* User Filter Dropdown */}
                <div ref={dropdownRef} style={{ position: "relative" }}>
                  <div
                    onClick={() => setDropdownOpen((prev) => !prev)}
                    style={{ display: "flex", alignItems: "center", gap: "6px", border: "1px solid #ddd", borderRadius: "20px", padding: "3px 12px", background: "#fff", cursor: "pointer", fontSize: "13px", userSelect: "none" }}
                  >
                    <div style={{ width: 22, height: 22, borderRadius: "50%", background: selected.bg, color: selected.color, display: "flex", alignItems: "center", justifyContent: "center", fontSize: 9, fontWeight: 500, flexShrink: 0 }}>
                      {selected.initials}
                    </div>
                    <span>{filterUser}</span>
                    <i className="fa-solid fa-chevron-down" style={{ fontSize: 10, color: "#888", transition: "transform 0.2s", transform: dropdownOpen ? "rotate(180deg)" : "rotate(0deg)" }} />
                  </div>
                  {dropdownOpen && (
                    <div style={{ position: "absolute", top: "calc(100% + 6px)", left: 0, minWidth: 180, background: "#fff", border: "0.5px solid #e0e0e0", borderRadius: 12, boxShadow: "0 4px 16px rgba(0,0,0,0.1)", zIndex: 100, padding: "6px 0" }}>
                      {userOptions.map((opt, i) => (
                        <div key={opt.label}>
                          {i === 1 && <hr style={{ margin: "4px 14px", border: "none", borderTop: "0.5px solid #eee" }} />}
                          <div
                            onClick={() => { setFilterUser(opt.label); setDropdownOpen(false); }}
                            style={{ display: "flex", alignItems: "center", gap: 10, padding: "8px 14px", cursor: "pointer", fontSize: 13, background: filterUser === opt.label ? "#f5f5f5" : "transparent" }}
                          >
                            <div style={{ width: 22, height: 22, borderRadius: "50%", background: opt.bg, color: opt.color, display: "flex", alignItems: "center", justifyContent: "center", fontSize: 9, fontWeight: 500 }}>
                              {opt.initials}
                            </div>
                            <span>{opt.label}</span>
                            {filterUser === opt.label && <span style={{ marginLeft: "auto", color: "#1a73e8", fontSize: 13 }}>✓</span>}
                          </div>
                        </div>
                      ))}
                    </div>
                  )}
                </div>
              </div>

              {/* ── SUMMARY CARD ── */}
              <div className="px-3 pt-3">
                <div style={{ border: "1px solid #e0e0e0", borderRadius: "10px", padding: "14px 18px", background: "#fff", maxWidth: "300px", boxShadow: "0 1px 4px rgba(0,0,0,0.05)" }}>
                  <div className="d-flex justify-content-between align-items-start mb-1">
                    <span style={{ fontSize: "13px", color: "#888" }}>Total Estimate Amount</span>
                  </div>
                  <div style={{ fontSize: "24px", fontWeight: "700", color: "#222", marginBottom: "2px" }}>
                    ₹ {totalSales.toLocaleString()}
                  </div>
                  <div style={{ borderTop: "1px solid #f0f0f0", paddingTop: "8px" }}>
                    <div className="d-flex" style={{ gap: "10px", fontSize: "12px" }}>
                      <span style={{ color: "#555" }}>Received: <strong style={{ color: "#222" }}>₹ {received.toLocaleString()}</strong></span>
                      <span style={{ color: "#ccc" }}>|</span>
                      <span style={{ color: "#555" }}>Balance: <strong style={{ color: "#222" }}>₹ {balance.toLocaleString()}</strong></span>
                    </div>
                  </div>
                </div>
              </div>

              {/* ── TABLE or EMPTY STATE ── */}
              {loading ? (

                <div className="text-center py-5">
                  <div className="spinner-border text-danger"></div>
                </div>

              ) : filteredInvoices.length === 0 ? (

                <div className="d-flex flex-column align-items-center justify-content-center" style={{ paddingTop: "30px", paddingBottom: "50px" }}>
                  <div style={{ width: "100px", height: "100px", background: "#e8f4fd", borderRadius: "50%", display: "flex", alignItems: "center", justifyContent: "center", marginBottom: "16px", boxShadow: "0 4px 16px rgba(47,128,237,0.10)" }}>
                    <i className="fa-solid fa-file-lines" style={{ fontSize: "40px", color: "#2f80ed" }}></i>
                  </div>
                  <p style={{ fontSize: "15px", fontWeight: "600", color: "#333", marginBottom: "4px" }}>No Transactions to show</p>
                  <p style={{ fontSize: "13px", color: "#aaa", marginBottom: "18px" }}>You haven't added any estimates yet.</p>
                  <button
                    className="btn btn-danger"
                    onClick={() => navigate("/addestimate")}
                    style={{ borderRadius: "8px", fontWeight: "600", padding: "8px 24px", fontSize: "14px" }}
                  >
                    <i className="fa-solid fa-plus mr-2"></i> Add Estimate
                  </button>
                </div>

              ) : (

                <div className="px-3 pt-2" style={{ overflowY: "auto", maxHeight: "420px" }}>
                  <table className="table table-hover table-bordered table-sm invoice-table" style={{ fontSize: "13px" }}>
                    <thead style={{ background: "#222", color: "#fff", position: "sticky", top: 0, zIndex: 1 }}>
                      <tr>
                        <th style={{ fontSize: "12px", fontWeight: "600", padding: "10px 12px" }}>Type</th>
                        <th style={{ fontSize: "12px", fontWeight: "600", padding: "10px 12px" }}>Estimate No.</th>
                        <th style={{ fontSize: "12px", fontWeight: "600", padding: "10px 12px" }}>Date</th>
                        <th style={{ fontSize: "12px", fontWeight: "600", padding: "10px 12px" }}>Party Name</th>
                        <th style={{ fontSize: "12px", fontWeight: "600", padding: "10px 12px" }}>Amount (₹)</th>
                        <th style={{ fontSize: "12px", fontWeight: "600", padding: "10px 12px" }}>Action</th>
                      </tr>
                    </thead>
                    <tbody>
                      {filteredInvoices.map((inv, idx) => (
                        <tr key={idx}>
                          <td>{inv.billType}</td>
                          <td>{inv.invoiceNumber}</td>
                          <td>{inv.invoiceDate}</td>
                          <td>{inv.partyName}</td>
                          <td>₹ {inv.grandTotal?.toLocaleString()}</td>
                          <td>
                        <div className="d-flex" style={{ gap: "6px" }}>
                          <button className="btn btn-sm btn-light" title="View"  onClick={() => navigate(`/addestimate/${inv.id}`)}>
                            <i className="fa-solid fa-eye" style={{ color: "#2f80ed" }}></i>
                          </button>
                          <button
                            className="btn btn-sm btn-light"
                            title="Download"
                            onClick={() => handleDownload(inv.id, inv.invoiceNumber)}
                            disabled={downloadingId === inv.id}
                          >
                            {downloadingId === inv.id ? (
                              <span className="spinner-border spinner-border-sm" style={{ width: 12, height: 12 }}></span>
                            ) : (
                              <i className="fa-solid fa-download" style={{ color: "#555" }}></i>
                            )}
                          </button>
                          {canEdit && (
                            <button
                              className="btn btn-sm btn-light"
                              title="Edit"
                              onClick={() => navigate(`/editestimate/${inv.id}`)}
                            >
                              <i className="fa-solid fa-pen-to-square" style={{ color: "#f39c12" }}></i>
                            </button>
                          )}
                          {canDelete && (
                            <button className="btn btn-sm btn-light" title="Delete" onClick={() => handleDelete(inv.id)}>
                              <i className="fa-solid fa-trash" style={{ color: "#e74c3c" }}></i>
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


      {/* ════════════════════════════════════════════════ */}
        {/* VIEW MODAL */}
        {/* ════════════════════════════════════════════════ */}
        {showViewModal && (
          <div
            style={{
              position: "fixed", top: 0, left: 0, right: 0, bottom: 0,
              background: "rgba(0,0,0,0.5)", zIndex: 1000,
              display: "flex", alignItems: "center", justifyContent: "center",
            }}
            onClick={() => setShowViewModal(false)}
          >
            <div
              style={{
                background: "#fff", borderRadius: "10px", width: "700px",
                maxWidth: "95%", maxHeight: "90vh", overflowY: "auto",
                padding: "24px", position: "relative",
              }}
              onClick={(e) => e.stopPropagation()}
            >
              <button
                onClick={() => setShowViewModal(false)}
                style={{
                  position: "absolute", top: 14, right: 14, background: "none",
                  border: "none", fontSize: 18, color: "#888", cursor: "pointer",
                }}
              >
                <i className="fa-solid fa-xmark"></i>
              </button>

              {viewLoading || !viewInvoice ? (
                <div className="text-center py-5">
                  <div className="spinner-border text-danger"></div>
                </div>
              ) : (
                <div>
                  {/* COMPANY + ESTIMATE HEADER */}
                  <div className="d-flex justify-content-between align-items-start mb-3 pb-3" style={{ borderBottom: "1px solid #eee" }}>
                    <div className="d-flex align-items-center" style={{ gap: 12 }}>
                      {myCompany?.logo && (
                        <img src={`data:image/jpeg;base64,${myCompany.logo}`} alt="logo" style={{ width: 50, height: 50, objectFit: "contain" }} />
                      )}
                      <div>
                        <h5 className="mb-0" style={{ fontWeight: 700 }}>{myCompany?.businessName || "—"}</h5>
                        <p className="mb-0" style={{ fontSize: 12, color: "#777" }}>{myCompany?.businessAddress}</p>
                        {myCompany?.gstin && <p className="mb-0" style={{ fontSize: 12, color: "#777" }}>GSTIN: {myCompany.gstin}</p>}
                      </div>
                    </div>
                    <div className="text-right">
                      <h5 style={{ fontWeight: 700, color: "#d93025" }}>ESTIMATE</h5>
                      <p className="mb-0" style={{ fontSize: 13 }}>#{viewInvoice.invoicePrefix || ""}{viewInvoice.invoiceNumber}</p>
                      <p className="mb-0" style={{ fontSize: 12, color: "#777" }}>{viewInvoice.invoiceDate}</p>
                    </div>
                  </div>

                  {/* PARTY DETAILS */}
                  <div className="mb-3">
                    <p style={{ fontSize: 12, color: "#888", marginBottom: 2 }}>ESTIMATE FOR</p>
                    <p style={{ fontWeight: 600, marginBottom: 2 }}>{viewInvoice.partyName}</p>
                    {viewInvoice.phoneNo && <p style={{ fontSize: 13, color: "#555" }}>{viewInvoice.phoneNo}</p>}
                  </div>

                  {/* ITEMS TABLE */}
                  <table className="table table-sm table-bordered" style={{ fontSize: 13 }}>
                    <thead style={{ background: "#f5f5f5" }}>
                      <tr>
                        <th>Item</th><th>HSN</th><th>Qty</th><th>Price</th><th>Disc</th><th>Tax</th><th>Total</th>
                      </tr>
                    </thead>
                    <tbody>
                      {viewInvoice.items?.map((item, idx) => (
                        <tr key={idx}>
                          <td>{item.itemName}</td>
                          <td>{item.hsnCode}</td>
                          <td>{item.qty} {item.unit}</td>
                          <td>₹{item.priceWithoutTax}</td>
                          <td>{item.discountPct}%</td>
                          <td>{item.taxPct}%</td>
                          <td>₹{item.totalAmount}</td>
                        </tr>
                      ))}
                    </tbody>
                  </table>

                  {/* TOTALS */}
                  <div className="d-flex justify-content-end">
                    <table style={{ fontSize: 13, minWidth: 220 }}>
                      <tbody>
                        <tr><td className="text-muted pr-3">Sub Total</td><td className="text-right">₹{viewInvoice.subTotal}</td></tr>
                        <tr><td className="text-muted pr-3">Discount</td><td className="text-right">₹{viewInvoice.totalDiscount}</td></tr>
                        <tr><td className="text-muted pr-3">CGST</td><td className="text-right">₹{viewInvoice.totalCgst}</td></tr>
                        <tr><td className="text-muted pr-3">SGST</td><td className="text-right">₹{viewInvoice.totalSgst}</td></tr>
                        <tr style={{ borderTop: "1px solid #ddd" }}>
                          <td style={{ fontWeight: 700 }} className="pr-3">Grand Total</td>
                          <td className="text-right" style={{ fontWeight: 700 }}>₹{viewInvoice.grandTotal}</td>
                        </tr>
                      </tbody>
                    </table>
                  </div>

                  {/* AUDIT INFO */}
                  <div className="mt-3 pt-2" style={{ borderTop: "1px solid #f0f0f0", fontSize: 11, color: "#aaa" }}>
                    Created by {viewInvoice.createdBy}
                    {viewInvoice.updatedBy && ` · Last edited by ${viewInvoice.updatedBy}`}
                  </div>

                  {/* MODAL ACTION BUTTONS */}
                  <div className="d-flex justify-content-end mt-3" style={{ gap: 8 }}>
                    <button
                      className="btn btn-sm btn-light"
                      onClick={() => handleDownload(viewInvoice.id, viewInvoice.invoiceNumber)}
                      disabled={downloadingId === viewInvoice.id}
                    >
                      <i className="fa-solid fa-download mr-1"></i> Download PDF
                    </button>
                  </div>
                </div>
              )}
            </div>
          </div>
        )}
    </div>


  );
};

export default EstimateQuotation;
