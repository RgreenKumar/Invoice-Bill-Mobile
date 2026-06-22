import React, { useState, useEffect, useRef } from "react";
import { useNavigate } from "react-router-dom";
import axios from "axios";
import baseUrl from "../api/utils";
import "../assets/css/invoicestyle.css";
import { getPermission } from "../utils/permissionUtils";
import MODULES from "../utils/modules";
import Swal from "sweetalert2";
import withReactContent from "sweetalert2-react-content";

const ViewSuppliers = () => {
  const token    = sessionStorage.getItem("token");
  const MySwal = withReactContent(Swal);
  const navigate = useNavigate();
  const canCreate = getPermission(MODULES.PARTIES, "canCreate");
  const canEdit   = getPermission(MODULES.PARTIES, "canEdit");
  const canDelete   = getPermission(MODULES.PARTIES, "canDelete");
  const getViewPath = (txn) =>
  txn.billType === "ESTIMATE" ? `/addestimate/${txn.id}` : `/addsale/${txn.id}`;
  const getEditPath = (txn) =>
  txn.billType === "ESTIMATE" ? `/editestimate/${txn.id}` : `/editsale/${txn.id}`;


  const [suppliers,        setSuppliers]        = useState([]);
  const [selectedSupplier, setSelectedSupplier] = useState(null);
  const [transactions,     setTransactions]     = useState([]);
  const [loading,          setLoading]          = useState(false);
  const [txnLoading,       setTxnLoading]       = useState(false);
  const [searchQuery,      setSearchQuery]      = useState("");
  const [txnSearch,        setTxnSearch]        = useState("");
  const [showSearchBox,    setShowSearchBox]    = useState(false);
  const [openMenuId,       setOpenMenuId]       = useState(null);
  const [filterOption,     setFilterOption]     = useState("All");
  const [balanceMap,       setBalanceMap]       = useState({});
  const tableMenuRef = useRef(null);

  useEffect(() => {
    const handler = (e) => {
      if (tableMenuRef.current && !tableMenuRef.current.contains(e.target))
        setOpenMenuId(null);
    };
    document.addEventListener("mousedown", handler);
    return () => document.removeEventListener("mousedown", handler);
  }, []);

  useEffect(() => { fetchSuppliers(); }, []);

  useEffect(() => {
    if (suppliers.length > 0 && !selectedSupplier) {
      handleSupplierClick(suppliers[0]);
    }
  }, [suppliers]);

  const fetchAllBalances = async (supplierList) => {
    const map = {};
    await Promise.all(
      supplierList.map(async (s) => {
        try {
          const res = await axios.get(`${baseUrl}/getPartyTransactions`, {
            headers: { Authorization: token },
            params: { partyName: s.name },
          });
          const data = Array.isArray(res.data) ? res.data : res.data?.content ?? [];
          const total = data.reduce((sum, t) => sum + (Number(t.balanceAmount) || 0), 0);
          map[s.id] = total;
        } catch {
          map[s.id] = 0;
        }
      })
    );
    setBalanceMap(map);
  };

  const fetchSuppliers = async () => {
    try {
      setLoading(true);
      const res = await axios.get(`${baseUrl}/getSuppliers`, {
        headers: { Authorization: token },
      });
      const list = Array.isArray(res.data) ? res.data : [];
      setSuppliers(list);
      fetchAllBalances(list);
    } catch (err) {
      console.error("Failed to fetch suppliers", err);
    } finally {
      setLoading(false);
    }
  };

  const fetchTransactions = async (partyName) => {
    if (!partyName) return;
    try {
      setTxnLoading(true);
      const res = await axios.get(`${baseUrl}/getPartyTransactions`, {
        headers: { Authorization: token },
        params: { partyName },
      });
      const data = Array.isArray(res.data) ? res.data : res.data?.content ?? [];
      setTransactions(data);
    } catch (err) {
      console.error("Failed to fetch transactions", err);
      setTransactions([]);
    } finally {
      setTxnLoading(false);
    }
  };

  const handleDeleteTxn = async (id) => {
  const result = await MySwal.fire({
    title: "Delete Transaction?",
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
      MySwal.fire("Deleted!", "Transaction deleted successfully.", "success");
      fetchTransactions(selectedSupplier.name);
      fetchAllBalances(suppliers);
    } catch (err) {
      MySwal.fire("Error", "Failed to delete transaction.", "error");
    }
  }
};


  const handleSupplierClick = (supplier) => {
    setSelectedSupplier(supplier);
    setTransactions([]);
    fetchTransactions(supplier.name);
  };

  const filteredSuppliers = suppliers.filter((s) =>
    (s.name || "").toLowerCase().includes(searchQuery.toLowerCase())
  );

  const filteredTxns = transactions.filter((t) => {
    if (filterOption === "Paid")   return !t.balanceAmount || Number(t.balanceAmount) <= 0;
    if (filterOption === "Unpaid") return t.balanceAmount  && Number(t.balanceAmount) > 0;
    const q = txnSearch.toLowerCase();
    return !q || t.billType?.toLowerCase().includes(q) || t.invoiceNumber?.toString().includes(q);
  }).filter((t) => {
    if (!txnSearch) return true;
    const q = txnSearch.toLowerCase();
    return t.billType?.toLowerCase().includes(q) || t.invoiceNumber?.toString().includes(q);
  });

  const totalBalance    = transactions.reduce((sum, t) => sum + (Number(t.balanceAmount) || 0), 0);
  const totalGrandTotal = transactions.reduce((sum, t) => sum + (Number(t.grandTotal)    || 0), 0);

  return (
    <div>
      <div className="invoice-card-wrapper vt-card-wrapper">
        <div>
          <div className="card invoice-card">
            <div className="card-body p-0">
              <div className="invoice-panel-layout">

                {/* ══ LEFT PANEL ══ */}
                <div className="invoice-left-panel">
                  <div className="invoice-left-panel-header">
                    <div className="vt-left-header-inner">
                      <h6 className="invoice-left-panel-title">Suppliers</h6>
                      <span className="invoice-count-badge">{filteredSuppliers.length}</span>
                    </div>
                  </div>

                  <div className="invoice-search-box">
                    <div className="input-group input-group-sm">
                      <div className="input-group-prepend">
                        <span className="input-group-text bg-white border-right-0">
                          <i className="fa-solid fa-magnifying-glass" style={{ color: "#aaa" }}></i>
                        </span>
                      </div>
                      <input type="text" className="form-control border-left-0"
                        placeholder="Search supplier name..."
                        value={searchQuery}
                        onChange={(e) => setSearchQuery(e.target.value)}
                        style={{ boxShadow: "none" }} />
                    </div>
                  </div>

                  <div className="invoice-column-headers">
                    <span className="invoice-column-header-text" style={{ flex: 1 }}>
                      SUPPLIERS NAME
                      <i className="fa-solid fa-filter ml-1 vt-filter-icon"></i>
                    </span>
                    <span className="invoice-column-header-text">BALANCE</span>
                  </div>

                  <div className="invoice-list-scroll">
                    {loading ? (
                      <div className="text-center p-4">
                        <div className="spinner-border spinner-border-sm text-danger"></div>
                      </div>
                    ) : filteredSuppliers.length === 0 ? (
                      <div className="text-center p-4" style={{ color: "#aaa", fontSize: 13 }}>
                        No suppliers found
                      </div>
                    ) : (
                      filteredSuppliers.map((supplier) => {
                        const isSelected = selectedSupplier?.id === supplier.id;
                        const displayBalance = isSelected
                          ? totalBalance
                          : (balanceMap[supplier.id] ?? 0);
                        return (
                          <div key={supplier.id}
                            className={`invoice-list-item ${isSelected ? "selected" : ""}`}
                            onClick={() => handleSupplierClick(supplier)}>
                            <span className={`invoice-list-item-name ${isSelected ? "selected" : ""}`}>
                              {supplier.name}
                            </span>
                            <span style={{ fontSize: 13, fontWeight: 600, color: displayBalance > 0 ? "#e74c3c" : "#27ae60" }}>
                              {Number(displayBalance).toLocaleString("en-IN", { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
                            </span>
                          </div>
                        );
                      })
                    )}
                  </div>
                </div>

                {/* ══ RIGHT PANEL ══ */}
                <div className="invoice-right-panel">
                  <div className="invoice-right-panel-header">
                    <div className="vt-right-header-left">
                      <h6 className="invoice-right-panel-title">
                        {selectedSupplier ? selectedSupplier.name : "Suppliers"}
                      </h6>
                     {selectedSupplier && canEdit && (
                        <i className="fa-solid fa-pen vt-edit-pen-icon"
                          style={{ cursor: "pointer", marginLeft: 8 }}
                          onClick={() => navigate(`/editSupplier/${selectedSupplier.id}`)}>
                        </i>
                      )}
                    </div>
                    <div className="vt-right-header-right" style={{ display: "flex", alignItems: "center", gap: 8 }}>
                      <select className="form-control form-control-sm invoice-filter-select"
                        value={filterOption}
                        onChange={(e) => setFilterOption(e.target.value)}
                        style={{ width: "auto", fontSize: 12 }}>
                        <option value="All">All</option>
                        <option value="Paid">Paid</option>
                        <option value="Unpaid">Unpaid</option>
                      </select>
                      {canCreate && (
                      <button className="btn btn-danger btn-sm" onClick={() => navigate("/addSupplier")}>
                        <i className="fa-solid fa-plus mr-1"></i> Add Supplier
                      </button>
                    )}
                    </div>
                  </div>

                  {selectedSupplier ? (
                    <>
                      {/* ── Summary Cards ── */}
                      <div style={{ display: "flex", gap: 12, padding: "12px 16px 0 16px" }}>
                        <div style={{ flex: 1, background: "#f0f7ff", borderRadius: 8, padding: "10px 14px", borderLeft: "3px solid #1a73e8" }}>
                          <div style={{ fontSize: 11, color: "#888", marginBottom: 2 }}>TOTAL PURCHASES</div>
                          <div style={{ fontSize: 15, fontWeight: 700, color: "#222" }}>
                            <i className="fa-solid fa-indian-rupee-sign" style={{ fontSize: "0.75rem", marginRight: 2 }}></i>
                            {Number(totalGrandTotal).toLocaleString("en-IN", { minimumFractionDigits: 2 })}
                          </div>
                        </div>
                        <div style={{ flex: 1, background: totalBalance > 0 ? "#fff0f0" : "#f0fdf4", borderRadius: 8, padding: "10px 14px", borderLeft: `3px solid ${totalBalance > 0 ? "#e74c3c" : "#27ae60"}` }}>
                          <div style={{ fontSize: 11, color: "#888", marginBottom: 2 }}>OUTSTANDING BALANCE</div>
                          <div style={{ fontSize: 15, fontWeight: 700, color: totalBalance > 0 ? "#e74c3c" : "#27ae60" }}>
                            <i className="fa-solid fa-indian-rupee-sign" style={{ fontSize: "0.75rem", marginRight: 2 }}></i>
                            {Number(totalBalance).toLocaleString("en-IN", { minimumFractionDigits: 2 })}
                          </div>
                        </div>
                        <div style={{ flex: 1, background: "#f5f5f5", borderRadius: 8, padding: "10px 14px", borderLeft: "3px solid #aaa" }}>
                          <div style={{ fontSize: 11, color: "#888", marginBottom: 2 }}>TRANSACTIONS</div>
                          <div style={{ fontSize: 15, fontWeight: 700, color: "#333" }}>{transactions.length}</div>
                        </div>
                      </div>

                      {/* ── Transactions Table ── */}
                      <div className="invoice-details-section">
                        <div className="invoice-details-header">
                          <h6 className="invoice-details-title">Transactions Details</h6>
                          <div className="vt-details-icons-row">
                            <i className="fa-solid fa-magnifying-glass invoice-icon" style={{ cursor: "pointer" }}
                              onClick={() => setShowSearchBox(!showSearchBox)}></i>
                            {showSearchBox && (
                              <input type="text" placeholder="Search..."
                                className="form-control form-control-sm vt-search-toggle-input"
                                value={txnSearch}
                                onChange={(e) => setTxnSearch(e.target.value)} />
                            )}
                            <i className="fa-solid fa-print invoice-icon" style={{ cursor: "pointer" }}></i>
                            <i className="fa-solid fa-rotate-right invoice-icon" style={{ cursor: "pointer" }}
                              onClick={() => fetchTransactions(selectedSupplier.name)}></i>
                          </div>
                        </div>

                        <div style={{ overflowX: "auto", width: "100%" }}>
                          <table className="table table-hover table-bordered table-sm invoice-table">
                            <thead style={{ background: "#222", color: "#fff", position: "sticky", top: 0, zIndex: 1 }}>
                              <tr>
                                <th>Type</th>
                                <th>Invoice Number</th>
                                <th>Date</th>
                                <th>Total Amount</th>
                                <th>Balance / Unused</th>
                                <th>Status</th>
                                <th style={{ width: 18 }}></th>
                              </tr>
                            </thead>
                            <tbody>
                              {txnLoading && (
                                <tr><td colSpan={7} style={{ textAlign: "center", padding: 24 }}>
                                  <div className="spinner-border spinner-border-sm text-danger"></div>
                                </td></tr>
                              )}
                              {!txnLoading && filteredTxns.length === 0 && (
                                <tr><td colSpan={7} style={{ textAlign: "center", color: "#aaa", padding: 24 }}>
                                  No transactions found
                                </td></tr>
                              )}
                              {!txnLoading && filteredTxns.map((txn, idx) => {
                                const isPaid = !txn.balanceAmount || Number(txn.balanceAmount) <= 0;
                                return (
                                  <tr key={idx}>
                                    <td>
                                      <span style={{
                                        padding: "2px 8px", borderRadius: 10, fontSize: "11px", fontWeight: 600,
                                        background: txn.billType === "SALE" ? "#e8f4fd" : txn.billType === "POS" ? "#fef3e2" : txn.billType === "ESTIMATE" ? "#f0fdf4" : "#f5f5f5",
                                        color:     txn.billType === "SALE" ? "#1a73e8" : txn.billType === "POS" ? "#e65100" : txn.billType === "ESTIMATE" ? "#137333" : "#555",
                                      }}>{txn.billType || "—"}</span>
                                    </td>
                                    <td>{txn.invoiceNumber || "—"}</td>
                                    <td>{txn.invoiceDate ? new Date(txn.invoiceDate).toLocaleDateString("en-GB") : "—"}</td>
                                    <td style={{ fontWeight: 600 }}>
                                      {txn.grandTotal != null ? <>
                                        <i className="fa-solid fa-indian-rupee-sign" style={{ fontSize: "0.7rem", marginRight: 2 }}></i>
                                        {Number(txn.grandTotal).toLocaleString("en-IN", { minimumFractionDigits: 2 })}
                                      </> : "—"}
                                    </td>
                                    <td style={{ color: isPaid ? "#27ae60" : "#e74c3c", fontWeight: 500 }}>
                                      <i className="fa-solid fa-indian-rupee-sign" style={{ fontSize: "0.7rem", marginRight: 2 }}></i>
                                      {Number(txn.balanceAmount || 0).toLocaleString("en-IN", { minimumFractionDigits: 2 })}
                                    </td>
                                    <td>
                                      <span style={{
                                        padding: "2px 10px", borderRadius: 12, fontSize: "11px", fontWeight: 600,
                                        background: isPaid ? "#e6f4ea" : "#fdecea",
                                        color:      isPaid ? "#137333" : "#d93025",
                                      }}>{txn.billType === "ESTIMATE" ? "—" : (isPaid ? "Paid" : "Unpaid")}</span>
                                    </td>
                                    <td style={{ position: "relative" }} ref={openMenuId === idx ? tableMenuRef : null}>
                                      <button className="vc-row-menu-btn"
                                        onClick={(e) => { e.stopPropagation(); setOpenMenuId(openMenuId === idx ? null : idx); }}>
                                        <i className="feather icon-more-vertical"></i>
                                      </button>
                                     {openMenuId === idx && (
                                          <div className="vc-row-dropdown vt-row-dropdown" style={{ right: 0, left: "auto", zIndex: 200 }}>
                                            <button onClick={() => navigate(getViewPath(txn))}>
                                              <i className="feather icon-eye"></i> View
                                            </button>
                                            <button><i className="feather icon-printer"></i> Print</button>
                                            {canEdit && (
                                              <button onClick={() => navigate(getEditPath(txn))}>
                                                <i className="feather icon-edit"></i> Edit
                                              </button>
                                            )}
                                            {canDelete && (
                                              <button onClick={() => handleDeleteTxn(txn.id)}>
                                                <i className="feather icon-trash-2"></i> Delete
                                              </button>
                                            )}
                                          </div>
                                        )}
                                    </td>
                                  </tr>
                                );
                              })}
                            </tbody>
                            {!txnLoading && filteredTxns.length > 0 && (
                              <tfoot>
                                <tr style={{ background: "#f5f5f5", fontWeight: 700 }}>
                                  <td colSpan={3} style={{ padding: "8px 12px", fontSize: 12 }}>
                                    Total ({filteredTxns.length} transactions)
                                  </td>
                                  <td style={{ padding: "8px 12px", fontSize: 13 }}>
                                    <i className="fa-solid fa-indian-rupee-sign" style={{ fontSize: "0.7rem", marginRight: 2 }}></i>
                                    {filteredTxns.reduce((s, t) => s + (Number(t.grandTotal) || 0), 0).toLocaleString("en-IN", { minimumFractionDigits: 2 })}
                                  </td>
                                  <td style={{ padding: "8px 12px", fontSize: 13, color: totalBalance > 0 ? "#e74c3c" : "#27ae60" }}>
                                    <i className="fa-solid fa-indian-rupee-sign" style={{ fontSize: "0.7rem", marginRight: 2 }}></i>
                                    {filteredTxns.reduce((s, t) => s + (Number(t.balanceAmount) || 0), 0).toLocaleString("en-IN", { minimumFractionDigits: 2 })}
                                  </td>
                                  <td colSpan={2}></td>
                                </tr>
                              </tfoot>
                            )}
                          </table>
                        </div>
                      </div>
                    </>
                  ) : (
                    <div className="invoice-empty-state">
                      <i className="fa-solid fa-handshake"></i>
                      <p>Select a supplier to view details</p>
                    </div>
                  )}
                </div>

              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default ViewSuppliers;