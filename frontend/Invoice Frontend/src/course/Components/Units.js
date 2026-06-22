import React, { useState, useRef, useEffect } from "react";
import Swal from "sweetalert2";
import withReactContent from "sweetalert2-react-content";
import baseUrl from "../../api/utils";
import axios from "axios";
import { useNavigate } from "react-router-dom";
import "../../assets/css/invoicestyle.css";

const MySwal = withReactContent(Swal);

const TABS = [
  { key: "all",      label: "All Items" },
  { key: "category", label: "Category" },
  { key: "unit",     label: "Unit" },
];

const Units = () => {
  const token    = sessionStorage.getItem("token");
  const role     = sessionStorage.getItem("role");
  const navigate = useNavigate();

  // ── State ────────────────────────────────────────────────
  const [units,         setUnits]         = useState([]);
  const [items,         setItems]         = useState([]);
  const [loading,       setLoading]       = useState(true);
  const [itemsLoading,  setItemsLoading]  = useState(false);
  const [selectedUnit,  setSelectedUnit]  = useState(null);
  const [searchQuery,   setSearchQuery]   = useState("");
  const [itemSearch,    setItemSearch]    = useState("");
  const [activeTab,     setActiveTab]     = useState("unit");
  const [openMenuId,    setOpenMenuId]    = useState(null);

  // Add Modal
  const [showAddModal,  setShowAddModal]  = useState(false);
  const [addLoading,    setAddLoading]    = useState(false);
  const [addForm,       setAddForm]       = useState({
    name: "", symbol: "", conversionValue: "", conversionUnit: ""
  });

  // Edit Modal
  const [showEditModal, setShowEditModal] = useState(false);
  const [editLoading,   setEditLoading]   = useState(false);
  const [editUnit,      setEditUnit]      = useState(null);
  const [editForm,      setEditForm]      = useState({
    name: "", symbol: "", conversionValue: "", conversionUnit: ""
  });

  const menuRef = useRef(null);

  // ── Close menu on outside click ──────────────────────────
  useEffect(() => {
    const handler = (e) => {
      if (menuRef.current && !menuRef.current.contains(e.target))
        setOpenMenuId(null);
    };
    document.addEventListener("mousedown", handler);
    return () => document.removeEventListener("mousedown", handler);
  }, []);

  // ── Fetch all units on mount ─────────────────────────────
  useEffect(() => {
    fetchUnits();
  }, []);

  // ── Fetch items when unit selected ──────────────────────
  useEffect(() => {
    if (selectedUnit) {
      fetchItemsByUnit(selectedUnit.id);
    } else {
      setItems([]);
    }
  }, [selectedUnit]);

  // ── API: Get all units ───────────────────────────────────
  const fetchUnits = async () => {
    setLoading(true);
    try {
      const res = await axios.get(`${baseUrl}/getUnits`, {
        headers: { Authorization: token },
      });
      setUnits(res.data);
      if (res.data.length > 0) setSelectedUnit(res.data[0]);
    } catch (err) {
      MySwal.fire("Error", "Failed to load units!", "error");
    } finally {
      setLoading(false);
    }
  };

  // ── API: Get items by unit ───────────────────────────────
  const fetchItemsByUnit = async (unitId) => {
    setItemsLoading(true);
    try {
      const res = await axios.get(
        `${baseUrl}/getItemsByUnit/${unitId}`,
        { headers: { Authorization: token } }
      );
      setItems(res.data);
    } catch (err) {
      setItems([]);
    } finally {
      setItemsLoading(false);
    }
  };

  // ── API: Add unit ────────────────────────────────────────
  const handleAddUnit = async () => {
    if (!addForm.name.trim() || !addForm.symbol.trim()) {
      MySwal.fire("Warning", "Unit name and symbol are required!", "warning");
      return;
    }
    setAddLoading(true);
    try {
      await axios.post(
        `${baseUrl}/admin/addUnit`,
        {
          name: addForm.name.trim(),
          symbol: addForm.symbol.trim(),
          conversionValue: addForm.conversionValue ? parseInt(addForm.conversionValue) : null,
          conversionUnit: addForm.conversionUnit.trim() || null,
        },
        { headers: { Authorization: token } }
      );
      MySwal.fire("Success", "Unit added successfully!", "success");
      setAddForm({ name: "", symbol: "", conversionValue: "", conversionUnit: "" });
      setShowAddModal(false);
      fetchUnits();
    } catch (err) {
      if (err.response?.status === 403)
        MySwal.fire("Error", err.response.data || "Access Denied or Duplicate Unit!", "error");
      else
        MySwal.fire("Error", "Failed to add unit!", "error");
    } finally {
      setAddLoading(false);
    }
  };

  // ── API: Update unit ─────────────────────────────────────
  const handleUpdateUnit = async () => {
    if (!editForm.name.trim() || !editForm.symbol.trim()) {
      MySwal.fire("Warning", "Unit name and symbol are required!", "warning");
      return;
    }
    setEditLoading(true);
    try {
      await axios.put(
        `${baseUrl}/admin/updateUnit/${editUnit.id}`,
        {
          name: editForm.name.trim(),
          symbol: editForm.symbol.trim(),
          conversionValue: editForm.conversionValue ? parseInt(editForm.conversionValue) : null,
          conversionUnit: editForm.conversionUnit.trim() || null,
        },
        { headers: { Authorization: token } }
      );
      MySwal.fire("Success", "Unit updated successfully!", "success");
      setShowEditModal(false);
      setEditUnit(null);
      fetchUnits();
    } catch (err) {
      if (err.response?.status === 403)
        MySwal.fire("Error", err.response.data || "Access Denied!", "error");
      else if (err.response?.status === 404)
        MySwal.fire("Error", "Unit not found or is a Default Unit!", "error");
      else if (err.response?.status === 409)
        MySwal.fire("Error", "Unit name already exists!", "error");
      else
        MySwal.fire("Error", "Failed to update unit!", "error");
    } finally {
      setEditLoading(false);
    }
  };

  // ── API: Delete unit ─────────────────────────────────────
  const handleDeleteUnit = async (item) => {
    // Block delete for DEFAULT units
    if (isDefault(item)) {
      MySwal.fire("Cannot Delete", "This is a default unit and cannot be deleted!", "warning");
      return;
    }

    const confirm = await MySwal.fire({
      icon: "warning",
      title: "Delete Unit?",
      text: `Are you sure you want to delete "${item.name}"?`,
      showCancelButton: true,
      confirmButtonText: "Delete",
      confirmButtonColor: "#e03535",
    });
    if (!confirm.isConfirmed) return;

    try {
      const res = await axios.delete(
        `${baseUrl}/admin/deleteUnit/${item.id}`,
        { headers: { Authorization: token } }
      );
      MySwal.fire("Deleted!", res.data || "Unit deleted successfully!", "success");
      if (selectedUnit?.id === item.id) setSelectedUnit(null);
      fetchUnits();
    } catch (err) {
      if (err.response?.status === 403)
        MySwal.fire("Error", err.response.data || "Unit is used by items, cannot delete!", "error");
      else if (err.response?.status === 404)
        MySwal.fire("Error", "Unit not found!", "error");
      else
        MySwal.fire("Error", "Failed to delete unit!", "error");
    }
  };

  // ── Tab navigation ───────────────────────────────────────
  const handleTabClick = (key) => {
    setActiveTab(key);
    if (key === "all")      navigate("/dashboard/viewitem");
    if (key === "category") navigate("/dashboard/category");
  };

  // ── Filtered lists ───────────────────────────────────────
  const filteredUnits = units.filter((u) =>
    u.name.toLowerCase().includes(searchQuery.toLowerCase())
  );

  const filteredItems = items.filter((i) =>
    (i.itemName || "").toLowerCase().includes(itemSearch.toLowerCase())
  );

  // ── Is DEFAULT unit ──────────────────────────────────────
  const isDefault = (item) => item.company === "DEFAULT";

  return (
    <>
      <div className="page-header"></div>

      <div className="invoice-card-wrapper" style={{ marginLeft: "-20px", marginRight: "-25px" }}>
        <div>
          <div className="invoice-card">
            <div className="card-body p-0">

              {/* ══ TAB BAR ══ */}
              <div
                className="vc-tab-bar"
                style={{ marginLeft: "-25px", marginRight: "-25px", paddingLeft: "25px", paddingRight: "25px" }}
              >
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

                {role === "ADMIN" && (
                  <div className="vc-tab-actions">
                    <button
                      className="btn btn-danger btn-sm"
                      onClick={() => setShowAddModal(true)}
                    >
                      <i className="feather icon-plus" style={{ marginRight: 5 }}></i>
                      Add Unit
                    </button>
                  </div>
                )}
              </div>

              {/* ══ ADD MODAL ══ */}
              {showAddModal && (
                <div className="modal-overlay">
                  <div className="modal-box" style={{ maxWidth: 600, width: "100%" }}>
                    <div className="modal-header" style={{ borderBottom: "1px solid #e2e8f0", paddingBottom: 12, marginBottom: 16 }}>
                      <h5 style={{ fontWeight: 700, fontSize: 15, margin: 0 }}>NEW UNIT</h5>
                      <span onClick={() => { setShowAddModal(false); setAddForm({ name: "", symbol: "", conversionValue: "", conversionUnit: "" }); }} style={{ cursor: "pointer", fontSize: 16 }}>✖</span>
                    </div>
                    <div className="modal-body" style={{ display: "flex", flexDirection: "column", gap: 16 }}>
                      <div style={{ display: "flex", gap: 16 }}>
                        {/* Unit Name */}
                        <div style={{ flex: 2, display: "flex", flexDirection: "column", gap: 4 }}>
                          <label style={{ fontSize: 11, fontWeight: 600, color: "#64748b", letterSpacing: "0.05em" }}>UNIT NAME *</label>
                          <input
                            type="text"
                            className="form-control"
                            placeholder="e.g. Kilogram"
                            value={addForm.name}
                            onChange={(e) => setAddForm({ ...addForm, name: e.target.value })}
                            style={{ borderTop: "none", borderLeft: "none", borderRight: "none", borderRadius: 0, paddingLeft: 0, fontSize: 14 }}
                          />
                        </div>
                        {/* Symbol */}
                        <div style={{ flex: 1, display: "flex", flexDirection: "column", gap: 4 }}>
                          <label style={{ fontSize: 11, fontWeight: 600, color: "#64748b", letterSpacing: "0.05em" }}>SYMBOL *</label>
                          <input
                            type="text"
                            className="form-control"
                            placeholder="e.g. kg"
                            value={addForm.symbol}
                            onChange={(e) => setAddForm({ ...addForm, symbol: e.target.value })}
                            style={{ borderTop: "none", borderLeft: "none", borderRight: "none", borderRadius: 0, paddingLeft: 0, fontSize: 14 }}
                          />
                        </div>
                      </div>
                      <div style={{ display: "flex", gap: 16 }}>
                        {/* Conversion Value */}
                        <div style={{ flex: 1, display: "flex", flexDirection: "column", gap: 4 }}>
                          <label style={{ fontSize: 11, fontWeight: 600, color: "#64748b", letterSpacing: "0.05em" }}>CONVERSION VALUE</label>
                          <input
                            type="number"
                            className="form-control"
                            placeholder="e.g. 1000"
                            value={addForm.conversionValue}
                            onChange={(e) => setAddForm({ ...addForm, conversionValue: e.target.value })}
                            style={{ borderTop: "none", borderLeft: "none", borderRight: "none", borderRadius: 0, paddingLeft: 0, fontSize: 14 }}
                          />
                        </div>
                        {/* Conversion Unit */}
                        <div style={{ flex: 1, display: "flex", flexDirection: "column", gap: 4 }}>
                          <label style={{ fontSize: 11, fontWeight: 600, color: "#64748b", letterSpacing: "0.05em" }}>CONVERSION UNIT</label>
                          <input
                            type="text"
                            className="form-control"
                            placeholder="e.g. Gram"
                            value={addForm.conversionUnit}
                            onChange={(e) => setAddForm({ ...addForm, conversionUnit: e.target.value })}
                            style={{ borderTop: "none", borderLeft: "none", borderRight: "none", borderRadius: 0, paddingLeft: 0, fontSize: 14 }}
                          />
                        </div>
                      </div>
                    </div>
                    <div className="modal-footer" style={{ justifyContent: "flex-end", gap: 8, borderTop: "1px solid #e2e8f0", paddingTop: 12, marginTop: 16 }}>
                      <button
                        className="btn btn-primary btn-sm"
                        onClick={handleAddUnit}
                        disabled={addLoading}
                      >
                        {addLoading ? "Saving..." : "Save"}
                      </button>
                    </div>
                  </div>
                </div>
              )}

              {/* ══ EDIT MODAL ══ */}
              {showEditModal && (
                <div className="modal-overlay">
                  <div className="modal-box" style={{ maxWidth: 600, width: "100%" }}>
                    <div className="modal-header" style={{ borderBottom: "1px solid #e2e8f0", paddingBottom: 12, marginBottom: 16 }}>
                      <h5 style={{ fontWeight: 700, fontSize: 15, margin: 0 }}>EDIT UNIT</h5>
                      <span onClick={() => { setShowEditModal(false); setEditUnit(null); }} style={{ cursor: "pointer", fontSize: 16 }}>✖</span>
                    </div>
                    <div className="modal-body" style={{ display: "flex", flexDirection: "column", gap: 16 }}>
                      <div style={{ display: "flex", gap: 16 }}>
                        <div style={{ flex: 2, display: "flex", flexDirection: "column", gap: 4 }}>
                          <label style={{ fontSize: 11, fontWeight: 600, color: "#64748b", letterSpacing: "0.05em" }}>UNIT NAME *</label>
                          <input
                            type="text"
                            className="form-control"
                            placeholder="e.g. Kilogram"
                            value={editForm.name}
                            onChange={(e) => setEditForm({ ...editForm, name: e.target.value })}
                            style={{ borderTop: "none", borderLeft: "none", borderRight: "none", borderRadius: 0, paddingLeft: 0, fontSize: 14 }}
                          />
                        </div>
                        <div style={{ flex: 1, display: "flex", flexDirection: "column", gap: 4 }}>
                          <label style={{ fontSize: 11, fontWeight: 600, color: "#64748b", letterSpacing: "0.05em" }}>SYMBOL *</label>
                          <input
                            type="text"
                            className="form-control"
                            placeholder="e.g. kg"
                            value={editForm.symbol}
                            onChange={(e) => setEditForm({ ...editForm, symbol: e.target.value })}
                            style={{ borderTop: "none", borderLeft: "none", borderRight: "none", borderRadius: 0, paddingLeft: 0, fontSize: 14 }}
                          />
                        </div>
                      </div>
                      <div style={{ display: "flex", gap: 16 }}>
                        <div style={{ flex: 1, display: "flex", flexDirection: "column", gap: 4 }}>
                          <label style={{ fontSize: 11, fontWeight: 600, color: "#64748b", letterSpacing: "0.05em" }}>CONVERSION VALUE</label>
                          <input
                            type="number"
                            className="form-control"
                            placeholder="e.g. 1000"
                            value={editForm.conversionValue}
                            onChange={(e) => setEditForm({ ...editForm, conversionValue: e.target.value })}
                            style={{ borderTop: "none", borderLeft: "none", borderRight: "none", borderRadius: 0, paddingLeft: 0, fontSize: 14 }}
                          />
                        </div>
                        <div style={{ flex: 1, display: "flex", flexDirection: "column", gap: 4 }}>
                          <label style={{ fontSize: 11, fontWeight: 600, color: "#64748b", letterSpacing: "0.05em" }}>CONVERSION UNIT</label>
                          <input
                            type="text"
                            className="form-control"
                            placeholder="e.g. Gram"
                            value={editForm.conversionUnit}
                            onChange={(e) => setEditForm({ ...editForm, conversionUnit: e.target.value })}
                            style={{ borderTop: "none", borderLeft: "none", borderRight: "none", borderRadius: 0, paddingLeft: 0, fontSize: 14 }}
                          />
                        </div>
                      </div>
                    </div>
                    <div className="modal-footer" style={{ justifyContent: "flex-end", gap: 8, borderTop: "1px solid #e2e8f0", paddingTop: 12, marginTop: 16 }}>
                      <button
                        className="btn btn-primary btn-sm"
                        onClick={handleUpdateUnit}
                        disabled={editLoading}
                      >
                        {editLoading ? "Updating..." : "Update"}
                      </button>
                    </div>
                  </div>
                </div>
              )}

              <div className="vc-wrapper">

                {/* ══ LEFT PANEL ══ */}
                <div className="vc-left-panel">
                  <div className="vc-left-header">
                    <div className="vc-search-box">
                      <i className="feather icon-search"></i>
                      <input
                        className="vc-search-input"
                        placeholder="Search..."
                        value={searchQuery}
                        onChange={(e) => setSearchQuery(e.target.value)}
                      />
                    </div>
                  </div>

                  <div className="vc-col-headers">
                    <span className="invoice-column-header-text" style={{ flex: 1 }}>
                      UNIT
                      <i className="fa-solid fa-filter ml-1" style={{ fontSize: "9px", color: "#e74c3c" }}></i>
                    </span>
                    <span className="invoice-column-header-text">ITEMS</span>
                  </div>

                  <div className="vc-course-list">
                    {loading && [...Array(4)].map((_, i) => (
                      <div key={i} className="vc-course-row" style={{ gap: 10 }}>
                        <div className="skeleton skeleton-title" style={{ flex: 1, height: 14 }}></div>
                        <div className="skeleton" style={{ width: 40, height: 20, borderRadius: 20 }}></div>
                      </div>
                    ))}

                    {!loading && filteredUnits.length === 0 && (
                      <div className="vc-list-message">No units found</div>
                    )}

                    {!loading && filteredUnits.map((item) => {
                      const active = selectedUnit?.id === item.id;
                      return (
                        <div
                          key={item.id}
                          className={`vc-course-row ${active ? "active" : ""}`}
                          onClick={() => setSelectedUnit(item)}
                        >
                          <span className="vc-course-row-name">{item.name || "—"}</span>
                          <div style={{ display: "flex", alignItems: "center", gap: 4 }}>
                            {/* Item count badge */}
                            <span className="vc-price-badge paid" style={{ minWidth: 24, textAlign: "center" }}>
                              {item.itemCount ?? 0}
                            </span>

                            {/* 3-dot menu — ADMIN only */}
                            {role === "ADMIN" && (
                              <div
                                className="vc-row-menu-wrap"
                                ref={openMenuId === item.id ? menuRef : null}
                              >
                                <button
                                  className="vc-row-menu-btn"
                                  onClick={(e) => {
                                    e.stopPropagation();
                                    setOpenMenuId(openMenuId === item.id ? null : item.id);
                                  }}
                                >
                                  <i className="feather icon-more-vertical"></i>
                                </button>
                                {openMenuId === item.id && (
                                  <div className="vc-row-dropdown">
                                    <button onClick={(e) => {
                                      e.stopPropagation();
                                      setOpenMenuId(null);
                                      setEditUnit(item);
                                      setEditForm({
                                        name: item.name,
                                        symbol: item.symbol,
                                        conversionValue: item.conversionValue ?? "",
                                        conversionUnit: item.conversionUnit ?? "",
                                      });
                                      setShowEditModal(true);
                                    }}>
                                      <i className="feather icon-edit-2"></i> Edit
                                    </button>
                                    <button className="danger" onClick={(e) => {
                                      e.stopPropagation();
                                      setOpenMenuId(null);
                                      handleDeleteUnit(item);
                                    }}>
                                      <i className="feather icon-trash-2"></i> Delete
                                    </button>
                                  </div>
                                )}
                              </div>
                            )}
                          </div>
                        </div>
                      );
                    })}
                  </div>
                </div>

                {/* ══ RIGHT PANEL ══ */}
                <div className="vc-right-panel" style={{ overflow: "hidden", minWidth: 0 }}>

                  {/* Selected unit name bar */}
                  {selectedUnit && (
                    <div className="vc-detail-bar">
                      <div className="vc-detail-bar-top">
                        <div className="vc-course-title-large">
                          <span>{selectedUnit.name}</span>
                          <i className="feather icon-arrow-right" style={{ fontSize: 13, color: "#94a3b8" }}></i>
                          <span className="vc-paytype-tag">{selectedUnit.symbol}</span>
                        </div>
                        {/* Conversion info */}
                        {selectedUnit.conversionValue && (
                          <span style={{ fontSize: 12, color: "#64748b" }}>
                            1 {selectedUnit.name} = {selectedUnit.conversionValue} {selectedUnit.conversionUnit}
                          </span>
                        )}
                      </div>
                    </div>
                  )}

                    {/* ══ CONVERSION TABLE ══ */}
                    <div className="vc-students-section">
                      <div className="vc-students-header">
                        <span className="vc-students-title" style={{ fontSize: 15 }}>Units</span>
                      </div>

                      <div className="vc-table-wrap">
                        <table className="table table-hover table-bordered table-sm invoice-table">
                          <thead>
                            <tr>
                              <th>#</th>
                              <th>Conversion</th>
                            </tr>
                          </thead>
                          <tbody>
                            {!selectedUnit && (
                              <tr>
                                <td colSpan={2} style={{ textAlign: "center", color: "#94a3b8", padding: 24 }}>
                                  Select a unit to view conversion
                                </td>
                              </tr>
                            )}
                            {selectedUnit && !selectedUnit.conversionValue && (
                              <tr>
                                <td colSpan={2} style={{ textAlign: "center", color: "#94a3b8", padding: 24 }}>
                                  No conversion available
                                </td>
                              </tr>
                            )}
                            {selectedUnit && selectedUnit.conversionValue && (
                              <tr>
                                <td>1</td>
                                <td>1 {selectedUnit.name} = {selectedUnit.conversionValue} {selectedUnit.conversionUnit}</td>
                              </tr>
                            )}
                          </tbody>
                        </table>
                      </div>
                    </div>





                  {/* ══ ITEMS TABLE ══
                  <div className="vc-students-section">
                    <div className="vc-students-header">
                      <span className="vc-students-title" style={{ fontSize: 15 }}>
                        {selectedUnit ? `Items using "${selectedUnit.name}"` : "Items"}
                      </span>
                      <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
                        <div className="vc-search-box" style={{ padding: "4px 9px", minWidth: 180 }}>
                          <i className="feather icon-search" style={{ color: "#a0aec0", fontSize: 12 }}></i>
                          <input
                            className="vc-search-input"
                            placeholder="Search items..."
                            value={itemSearch}
                            onChange={(e) => setItemSearch(e.target.value)}
                            style={{ fontSize: "0.78rem" }}
                          />
                        </div>
                        <span className="vc-students-count">{filteredItems.length} total</span>
                      </div>
                    </div>

                    <div className="vc-table-wrap">
                      <table className="table table-hover table-bordered table-sm invoice-table">
                        <thead>
                          <tr>
                            <th>#</th>
                            <th>Item Name</th>
                            <th>Item Code</th>
                            <th>Stock</th>
                          </tr>
                        </thead>
                        <tbody>
                          {itemsLoading && (
                            <tr>
                              <td colSpan={4} style={{ textAlign: "center", color: "#94a3b8", padding: 24 }}>
                                Loading...
                              </td>
                            </tr>
                          )}
                          {!itemsLoading && !selectedUnit && (
                            <tr>
                              <td colSpan={4} style={{ textAlign: "center", color: "#94a3b8", padding: 24 }}>
                                Select a unit to view items
                              </td>
                            </tr>
                          )}
                          {!itemsLoading && selectedUnit && filteredItems.length === 0 && (
                            <tr>
                              <td colSpan={4} style={{ textAlign: "center", color: "#94a3b8", padding: 24 }}>
                                No items found using this unit
                              </td>
                            </tr>
                          )}
                          {!itemsLoading && filteredItems.map((item, index) => (
                            <tr key={item.id}>
                              <td>{index + 1}</td>
                              <td>{item.itemName || "—"}</td>
                              <td>{item.itemCode || "—"}</td>
                              <td>{item.stock ?? "—"}</td>
                            </tr>
                          ))}
                        </tbody>
                      </table>
                    </div>
                  </div> */}

                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </>
  );
};

export default Units;
