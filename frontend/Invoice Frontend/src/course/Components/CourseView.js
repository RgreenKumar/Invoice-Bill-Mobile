import React, { useState, useRef, useEffect, useCallback } from "react";
import axios from "axios";
import { useNavigate } from "react-router-dom";
import baseUrl from "../../api/utils";
import "../../assets/css/invoicestyle.css";
import { getPermission } from "../../utils/permissionUtils";
import MODULES from "../../utils/modules";

const TABS = [
  { key: "all",      label: "All Items" },
  { key: "category", label: "Category" },
  { key: "unit",     label: "Unit" },
];

// ═══════════════════════════════════════════════════════════════════════════════
// MAIN COMPONENT
// ═══════════════════════════════════════════════════════════════════════════════
const ViewItem = () => {

  const [filteredCourses, setFilteredCourses] = useState([]);
  const [loading, setLoading] = useState(false);
  

  // Add these 3 lines at top
  const canCreate = getPermission(MODULES.VIEW_ITEM, "canCreate");
  const canEdit   = getPermission(MODULES.VIEW_ITEM, "canEdit");
  const canDelete = getPermission(MODULES.VIEW_ITEM, "canDelete");

  // rest of your code...

  useEffect(() => {
    const fetchItems = async () => {
      try {
        setLoading(true);
        const token = sessionStorage.getItem("token");
        const response = await axios.get(`${baseUrl}/item/viewAll`, {
          headers: { Authorization: token },
        });
        console.log("Items response:", response.data);
        setFilteredCourses(response.data);
      } catch (error) {
        console.error("Failed to fetch items:", error);
      } finally {
        setLoading(false);
      }
    };
    fetchItems();
  }, []);


  const token    = sessionStorage.getItem("token");
  const role     = sessionStorage.getItem("role");
  const navigate = useNavigate();

  // ── State ──
  const [selectedItem,     setSelectedItem]     = useState(null);
  const [searchQuery,      setSearchQuery]      = useState("");
  const [txnSearch,        setTxnSearch]        = useState("");
  const [activeTab,        setActiveTab]        = useState("all");
  const [openMenuId,       setOpenMenuId]       = useState(null);
  const [openTableMenuId,  setOpenTableMenuId]  = useState(null);

  // ── Transaction state ──
  const [transactions,     setTransactions]     = useState([]);
  const [txnLoading,       setTxnLoading]       = useState(false);

  const leftMenuRef  = useRef(null);
  const tableMenuRef = useRef(null);

  // ── Auto-select first item on load ──
  useEffect(() => {
    if (filteredCourses?.length > 0 && !selectedItem) {
      const first = filteredCourses[filteredCourses.length - 1];
      setSelectedItem(first);
      fetchTransactions(first.itemName);
    }
  }, [filteredCourses]);

  // ── Close dropdowns on outside click ──
  useEffect(() => {
    const handler = (e) => {
      if (leftMenuRef.current  && !leftMenuRef.current.contains(e.target))  setOpenMenuId(null);
      if (tableMenuRef.current && !tableMenuRef.current.contains(e.target)) setOpenTableMenuId(null);
    };
    document.addEventListener("mousedown", handler);
    return () => document.removeEventListener("mousedown", handler);
  }, []);

  // ═══════════════════════════════════════════════
  // FETCH ITEM TRANSACTIONS
  // ═══════════════════════════════════════════════
  const fetchTransactions = useCallback(async (itemName) => {
    if (!itemName) return;
    try {
      setTxnLoading(true);
      const res = await axios.get(`${baseUrl}/getItemTransactions`, {
        headers: { Authorization: token },
        params: { itemName },
      });
      setTransactions(res.data);
    } catch (err) {
      console.error("Failed to fetch transactions", err);
      setTransactions([]);
    } finally {
      setTxnLoading(false);
    }
  }, [token]);

  // ── When item clicked → fetch its transactions ──
  const handleItemClick = (item) => {
    setSelectedItem(item);
    setTransactions([]);
    fetchTransactions(item.itemName);
  };

  // ── Tab navigation ──
  const handleTabClick = (key) => {
    setActiveTab(key);
    if (key === "category") navigate("/dashboard/category");
    if (key === "unit")     navigate("/dashboard/unit");
  };

  // ── Left panel search filter ──
  const localFiltered = (filteredCourses || [])
    .slice().reverse()
    .filter((item) =>
      (item.itemName || "").toLowerCase().includes(searchQuery.toLowerCase())
    );

  // ── Transaction table search filter ──
  const txnFiltered = transactions.filter((t) => {
    const q = txnSearch.toLowerCase();
    return (
      t.billType?.toLowerCase().includes(q) ||
      t.invoiceNumber?.toString().includes(q) ||
      t.partyName?.toLowerCase().includes(q)
    );
  });

  // ── Get sale price from item pricing ──
  const getSalePrice = (item) => {
    return item.salePrice ?? item.pricing?.salePrice ?? null;
  };

  const getPurchasePrice = (item) => {
    return item.purchasePrice ?? item.pricing?.purchasePrice ?? null;
  };

  return (
    <>
      <div className="page-header"></div>

      <div className="invoice-card-wrapper" style={{ marginLeft: "-20px", marginRight: "-25px" }}>
        <div>
          <div className="invoice-card">
            <div className="card-body p-0">

              {/* ══ TAB BAR ══ */}
              <div className="vc-tab-bar" style={{ marginLeft: "-25px", marginRight: "-25px", paddingLeft: "25px", paddingRight: "25px" }}>
                <div className="vc-tabs-left">
                  {TABS.map((tab) => (
                    <button
                      key={tab.key}
                      className={`vc-tab-btn ${activeTab === tab.key ? "active" : ""}`}
                      onClick={() => handleTabClick(tab.key)}
                    >
                      {tab.label}
                    </button>
                  ))}
                </div>
                {canCreate && (
                    <div className="vc-tab-actions">
                      <button
                        className="btn btn-danger btn-sm"
                        onClick={() => navigate("/additem")}
                      >
                        <i className="feather icon-plus" style={{ marginRight: 5 }}></i>
                        Add Item
                        <i className="feather icon-chevron-down" style={{ marginLeft: 5, fontSize: "0.72rem" }}></i>
                      </button>
                      {/* <button className="vc-tab-icon-btn" title="More">
                        <i className="feather icon-more-vertical"></i>
                      </button> */}
                    </div>
                  )}
              </div>

              <div className="vc-wrapper">

                {/* ══ LEFT PANEL — Item List ══ */}
                <div className="vc-left-panel">
                  <div className="vc-left-header">
                    <div className="vc-search-box">
                      <i className="feather icon-search"></i>
                      <input
                        className="vc-search-input"
                        placeholder="Search items..."
                        value={searchQuery}
                        onChange={(e) => setSearchQuery(e.target.value)}
                      />
                    </div>
                  </div>

                  <div className="vc-col-headers">
                    <span className="invoice-column-header-text" style={{ flex: 1 }}>
                      ITEM NAME
                      <i className="fa-solid fa-filter ml-1" style={{ fontSize: "9px", color: "#e74c3c" }}></i>
                    </span>
                    <span className="invoice-column-header-text">QTY</span>
                  </div>

                  <div className="vc-course-list">
                    {/* Loading skeletons */}
                    {loading && [...Array(5)].map((_, i) => (
                      <div key={i} className="vc-course-row" style={{ gap: 10 }}>
                        <div className="skeleton skeleton-title" style={{ flex: 1, height: 14 }}></div>
                        <div className="skeleton" style={{ width: 40, height: 20, borderRadius: 20 }}></div>
                      </div>
                    ))}

                    {!loading && localFiltered.length === 0 && (
                      <div className="vc-list-message">No items found</div>
                    )}

                    {!loading && localFiltered.map((item) => {
                     const isActive = selectedItem?.id === item.id;
                      return (
                        <div
                          key={item.itemId || item.id}
                          className={`vc-course-row ${isActive ? "active" : ""}`}
                          onClick={() => handleItemClick(item)}
                        >
                          <span className="vc-course-row-name">{item.itemName || "—"}</span>
                          <div style={{ display: "flex", alignItems: "center", gap: 4 }}>
                            {/* Qty badge */}
                            <span className="vc-price-badge paid" style={{ minWidth: 28, textAlign: "center", fontSize: "11px" }}>
                              {item.remainingStock ?? "—"}
                            </span>
                            {/* 3-dot menu */}
                            <div
                              className="vc-row-menu-wrap"
                              ref={openMenuId === (item.itemId || item.id) ? leftMenuRef : null}
                            >
                              {(canEdit || canDelete) && (
                            <button
                              className="vc-row-menu-btn"
                              onClick={(e) => {
                                e.stopPropagation();
                                const id = item.itemId || item.id;
                                setOpenMenuId(openMenuId === id ? null : id);
                              }}
                            >
                              <i className="feather icon-more-vertical"></i>
                            </button>
                          )}                          
                            {openMenuId === (item.itemId || item.id) && (
                              <div className="vc-row-dropdown">
                                {canEdit && (
                                  <button onClick={(e) => {
                                    e.stopPropagation();
                                    setOpenMenuId(null);
                                    navigate(`/edititem/${item.itemId || item.id}`);
                                  }}>
                                    <i className="feather icon-edit-2"></i> Edit
                                  </button>
                                )}
                                {canDelete && (
                                  <button className="danger" onClick={(e) => {
                                    e.stopPropagation();
                                    setOpenMenuId(null);
                                  }}>
                                    <i className="feather icon-trash-2"></i> Delete
                                  </button>
                                )}
                              </div>
                            )}
                            </div>
                          </div>
                        </div>
                      );
                    })}
                  </div>
                </div>

                {/* ══ RIGHT PANEL ══ */}
                <div className="vc-right-panel" style={{ overflow: "hidden", minWidth: 0 }}>
                  {loading ? (
                    <div style={{ padding: 28 }}>
                      <div className="skeleton skeleton-title" style={{ width: "40%", height: 24, marginBottom: 16 }}></div>
                      <div className="skeleton skeleton-input" style={{ width: "100%", height: 80, marginBottom: 16 }}></div>
                      <div className="skeleton skeleton-input" style={{ width: "100%", height: 200 }}></div>
                    </div>
                  ) : selectedItem ? (
                    <>
                      {/* ── Detail Bar ── */}
                      <div className="vc-detail-bar">
                        <div className="vc-detail-bar-top">
                          <div className="vc-course-title-large">
                            <span style={{ fontSize: "16px", fontWeight: "700" }}>
                              {selectedItem.itemName || "—"}
                            </span>
                            <i className="feather icon-arrow-right" style={{ fontSize: 13, color: "#94a3b8" }}></i>
                          </div>
                        </div>

                        {/* ── Meta Row: Sale Price | Purchase Price | Total Items ── */}
                        <div className="vc-detail-meta">
                          <div className="vc-meta-item">
                            <span className="vc-meta-label">Sale Price</span>
                            <span className="vc-meta-value paid">
                              {getSalePrice(selectedItem)
                                ? <>
                                    <i className="fa-solid fa-indian-rupee-sign" style={{ marginRight: 4, fontSize: "0.8rem" }}></i>
                                    {getSalePrice(selectedItem)}
                                    <span style={{ fontSize: "0.7rem", color: "#94a3b8", fontWeight: 400, marginLeft: 3 }}>(incl)</span>
                                  </>
                                : <span style={{ color: "#94a3b8" }}>—</span>
                              }
                            </span>
                          </div>

                          <div className="vc-meta-item">
                            <span className="vc-meta-label">Purchase Price</span>
                            <span className="vc-meta-value">
                              {getPurchasePrice(selectedItem)
                                ? <>
                                    <i className="fa-solid fa-indian-rupee-sign" style={{ marginRight: 4, fontSize: "0.8rem" }}></i>
                                    {getPurchasePrice(selectedItem)}
                                  </>
                                : <span className="vc-badge yellow">-</span>
                              }
                            </span>
                          </div>

                          {selectedItem.category && (
                            <div className="vc-meta-item">
                              <span className="vc-meta-label">Category</span>
                              <span className="vc-meta-value">{selectedItem.category}</span>
                            </div>
                          )}

                          {selectedItem.unit && (
                            <div className="vc-meta-item">
                              <span className="vc-meta-label">Unit</span>
                              <span className="vc-meta-value">{selectedItem.unit?.name || selectedItem.unit}</span>
                            </div>
                          )}

                          <div className="vc-meta-item vc-meta-right">
                            <span className="vc-meta-label">Total Items</span>
                            <span className="vc-meta-value" style={{ color: "#2563eb" }}>
                              {(filteredCourses || []).length}
                            </span>
                          </div>
                        </div>
                      </div>

                      {/* ══ TRANSACTION DETAILS TABLE ══ */}
                      <div className="vc-students-section">
                        <div className="vc-students-header">
                          <h6>TRANSACTIONS</h6>
                          <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
                            <div className="vc-search-box" style={{ padding: "4px 9px", minWidth: 180 }}>
                              <i className="feather icon-search" style={{ color: "#a0aec0", fontSize: 12 }}></i>
                              <input
                                className="vc-search-input"
                                placeholder="Search..."
                                value={txnSearch}
                                onChange={(e) => setTxnSearch(e.target.value)}
                                style={{ fontSize: "0.78rem" }}
                              />
                            </div>
                            <span className="vc-students-count">{txnFiltered.length} total</span>
                          </div>
                        </div>

                        <div className="vc-table-wrap">
                          <table className="table table-hover table-bordered table-sm invoice-table">
                            <thead style={{ background: "#222", color: "#fff", position: "sticky", top: 0, zIndex: 1 }}>
                              <tr>
                                <th style={{ width: 18, paddingRight: 0 }}></th>
                                <th>Type</th>
                                <th>Invoice No</th>
                                <th>Customer / Supplier Name</th>
                                <th>Date</th>
                                <th>Quantity</th>
                                <th>Amount</th>
                                <th>Status</th>
                              </tr>
                            </thead>
                            <tbody>
                              {txnLoading && (
                                <tr>
                                  <td colSpan={8} style={{ textAlign: "center", padding: 24 }}>
                                    <div className="spinner-border spinner-border-sm text-danger"></div>
                                  </td>
                                </tr>
                              )}

                              {!txnLoading && txnFiltered.length === 0 && (
                                <tr>
                                  <td colSpan={8} style={{ textAlign: "center", color: "#94a3b8", padding: 24 }}>
                                    No transactions found for this item
                                  </td>
                                </tr>
                              )}

                              {!txnLoading && txnFiltered.map((txn, idx) => {
                                const isPaid = !txn.balanceAmount || txn.balanceAmount <= 0;
                                return (
                                  <tr key={idx} style={{ cursor: "pointer" }}>
                                    {/* status dot */}
                                    <td style={{ paddingRight: 0 }}>
                                      <span style={{
                                        display: "inline-block", width: 8, height: 8, borderRadius: "50%",
                                        background: isPaid ? "#25a265" : "#f0a500",
                                      }}></span>
                                    </td>
                                    {/* TYPE */}
                                    <td>
                                      <span style={{
                                        padding: "2px 8px", borderRadius: 10, fontSize: "11px", fontWeight: 600,
                                        background: txn.billType === "SALE" ? "#e8f4fd"
                                                  : txn.billType === "POS"  ? "#fef3e2"
                                                  : "#f0fdf4",
                                        color:     txn.billType === "SALE" ? "#1a73e8"
                                                  : txn.billType === "POS"  ? "#e65100"
                                                  : "#137333",
                                      }}>
                                        {txn.billType || "—"}
                                      </span>
                                    </td>
                                    {/* INVOICE NO */}
                                    <td>{txn.invoiceNumber || "—"}</td>
                                    {/* CUSTOMER NAME */}
                                    <td>{txn.partyName || <span style={{ color: "#cbd5e0" }}>—</span>}</td>
                                    {/* DATE */}
                                    <td>
                                      {txn.invoiceDate
                                        ? new Date(txn.invoiceDate).toLocaleDateString("en-GB")
                                        : "—"}
                                    </td>
                                    {/* QUANTITY */}
                                    <td>
                                      {txn.qty
                                        ? `${txn.qty} ${txn.unit && txn.unit !== "NONE" ? txn.unit : ""}`
                                        : "—"}
                                    </td>
                                    {/* AMOUNT */}
                                    <td style={{ fontWeight: 600, color: "#222" }}>
                                      {txn.totalAmount
                                        ? <>
                                            <i className="fa-solid fa-indian-rupee-sign" style={{ fontSize: "0.7rem", marginRight: 2 }}></i>
                                            {Number(txn.totalAmount).toLocaleString("en-IN", { minimumFractionDigits: 2 })}
                                          </>
                                        : "—"}
                                    </td>
                                    {/* STATUS */}
                                    <td>
                                      <span style={{
                                        padding: "2px 10px", borderRadius: 12, fontSize: "11px", fontWeight: 600,
                                        background: isPaid ? "#e6f4ea" : "#fdecea",
                                        color:      isPaid ? "#137333" : "#d93025",
                                      }}>
                                        {isPaid ? "Paid" : "Unpaid"}
                                      </span>
                                    </td>
                                  </tr>
                                );
                              })}
                            </tbody>
                          </table>
                        </div>
                      </div>
                    </>
                  ) : (
                    <div className="vc-empty-state">
                      <i className="feather icon-package"></i>
                      <span>Select an item to view transactions</span>
                    </div>
                  )}
                </div>

              </div>
            </div>
          </div>
        </div>
      </div>
    </>
  );
};

export default ViewItem;
