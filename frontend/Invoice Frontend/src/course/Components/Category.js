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

const Category = () => {
  const token    = sessionStorage.getItem("token");
  const role     = sessionStorage.getItem("role");
  const navigate = useNavigate();

  // ── State ────────────────────────────────────────────────
  const [categories,       setCategories]       = useState([]);
  const [items,            setItems]            = useState([]);
  const [loading,          setLoading]          = useState(true);
  const [itemsLoading,     setItemsLoading]     = useState(false);
  const [selectedCategory, setSelectedCategory] = useState(null);
  const [searchQuery,      setSearchQuery]      = useState("");
  const [itemSearch,       setItemSearch]       = useState("");
  const [activeTab,        setActiveTab]        = useState("category");
  const [openMenuId,       setOpenMenuId]       = useState(null);

  // Add Modal
  const [showAddModal,  setShowAddModal]  = useState(false);
  const [categoryName,  setCategoryName]  = useState("");
  const [addLoading,    setAddLoading]    = useState(false);

  // Edit Modal
  const [showEditModal, setShowEditModal] = useState(false);
  const [editItem,      setEditItem]      = useState(null);
  const [editName,      setEditName]      = useState("");
  const [editLoading,   setEditLoading]   = useState(false);

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

  // ── Fetch all categories on mount ────────────────────────
  useEffect(() => {
    fetchCategories();
  }, []);

  // ── Fetch items when category selected ──────────────────
  useEffect(() => {
    if (selectedCategory) {
      fetchItemsByCategory(selectedCategory.id);
    } else {
      setItems([]);
    }
  }, [selectedCategory]);

  // ── API: Get all categories ──────────────────────────────
  const fetchCategories = async () => {
    setLoading(true);
    try {
      const res = await axios.get(`${baseUrl}/getCategories`, {
        headers: { Authorization: token },
      });
      setCategories(res.data);
      // Auto-select first category
      if (res.data.length > 0) setSelectedCategory(res.data[0]);
    } catch (err) {
      MySwal.fire("Error", "Failed to load categories!", "error");
    } finally {
      setLoading(false);
    }
  };

  // ── API: Get items by category ───────────────────────────
  const fetchItemsByCategory = async (categoryId) => {
    setItemsLoading(true);
    try {
      const res = await axios.get(
        `${baseUrl}/getItemsByCategory/${categoryId}`,
        { headers: { Authorization: token } }
      );
      setItems(res.data);
    } catch (err) {
      setItems([]);
    } finally {
      setItemsLoading(false);
    }
  };

  // ── API: Add category ────────────────────────────────────
  const handleAddCategory = async () => {
    if (!categoryName.trim()) {
      MySwal.fire("Warning", "Category name is required!", "warning");
      return;
    }
    setAddLoading(true);
    try {
      await axios.post(
        `${baseUrl}/admin/addCategory`,
        { name: categoryName.trim() },
        { headers: { Authorization: token } }
      );
      MySwal.fire("Success", "Category added successfully!", "success");
      setCategoryName("");
      setShowAddModal(false);
      fetchCategories();
    } catch (err) {
      if (err.response?.status === 403)
        MySwal.fire("Error", err.response.data || "Access Denied or Duplicate Category!", "error");
      else
        MySwal.fire("Error", "Failed to add category!", "error");
    } finally {
      setAddLoading(false);
    }
  };

  // ── API: Update category ─────────────────────────────────
  const handleUpdateCategory = async () => {
    if (!editName.trim()) {
      MySwal.fire("Warning", "Category name is required!", "warning");
      return;
    }
    setEditLoading(true);
    try {
      await axios.put(
        `${baseUrl}/admin/updateCategory/${editItem.id}`,
        { name: editName.trim() },
        { headers: { Authorization: token } }
      );
      MySwal.fire("Success", "Category updated successfully!", "success");
      setShowEditModal(false);
      setEditItem(null);
      fetchCategories();
    } catch (err) {
      if (err.response?.status === 403)
        MySwal.fire("Error", err.response.data || "Access Denied!", "error");
      else if (err.response?.status === 404)
        MySwal.fire("Error", "Category not found or is a Default Category!", "error");
      else if (err.response?.status === 409)
        MySwal.fire("Error", "Category name already exists!", "error");
      else
        MySwal.fire("Error", "Failed to update category!", "error");
    } finally {
      setEditLoading(false);
    }
  };

  // ── API: Delete category ─────────────────────────────────
  const handleDeleteCategory = async (item) => {
    const confirm = await MySwal.fire({
      icon: "warning",
      title: "Delete Category?",
      text: `Are you sure you want to delete "${item.name}"?`,
      showCancelButton: true,
      confirmButtonText: "Delete",
      confirmButtonColor: "#e03535",
    });
    if (!confirm.isConfirmed) return;

    try {
      const res = await axios.delete(
        `${baseUrl}/admin/deleteCategory/${item.id}`,
        { headers: { Authorization: token } }
      );
      MySwal.fire("Deleted!", res.data || "Category deleted successfully!", "success");
      if (selectedCategory?.id === item.id) setSelectedCategory(null);
      fetchCategories();
    } catch (err) {
      if (err.response?.status === 403)
        MySwal.fire("Error", err.response.data || "Access Denied or Category is used by items!", "error");
      else if (err.response?.status === 404)
        MySwal.fire("Error", "Category not found!", "error");
      else
        MySwal.fire("Error", "Failed to delete category!", "error");
    }
  };

  // ── Tab navigation ───────────────────────────────────────
  const handleTabClick = (key) => {
    setActiveTab(key);
    if (key === "all")  navigate("/dashboard/viewitem");
    if (key === "unit") navigate("/dashboard/unit");
  };

  // ── Filtered lists ───────────────────────────────────────
  const filteredCategories = categories.filter((c) =>
    c.name.toLowerCase().includes(searchQuery.toLowerCase())
  );

  const filteredItems = items.filter((i) =>
    (i.itemName || "").toLowerCase().includes(itemSearch.toLowerCase())
  );

  // ── Is DEFAULT category (cannot edit/delete) ─────────────
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
                      Add Category
                    </button>
                  </div>
                )}
              </div>

              {/* ══ ADD MODAL ══ */}
              {showAddModal && (
                <div className="modal-overlay">
                  <div className="modal-box">
                    <div className="modal-header">
                      <h5>Add Category</h5>
                      <span onClick={() => { setShowAddModal(false); setCategoryName(""); }} style={{ cursor: "pointer" }}>✖</span>
                    </div>
                    <div className="modal-body">
                      <input
                        type="text"
                        placeholder="e.g., Grocery"
                        className="form-control"
                        value={categoryName}
                        onChange={(e) => setCategoryName(e.target.value)}
                        onKeyDown={(e) => e.key === "Enter" && handleAddCategory()}
                        autoFocus
                      />
                    </div>
                    <div className="modal-footer">
                      <button
                        className="btn btn-danger w-100"
                        onClick={handleAddCategory}
                        disabled={addLoading}
                      >
                        {addLoading ? "Creating..." : "Create"}
                      </button>
                    </div>
                  </div>
                </div>
              )}

              {/* ══ EDIT MODAL ══ */}
              {showEditModal && (
                <div className="modal-overlay">
                  <div className="modal-box">
                    <div className="modal-header">
                      <h5>Edit Category</h5>
                      <span onClick={() => { setShowEditModal(false); setEditItem(null); }} style={{ cursor: "pointer" }}>✖</span>
                    </div>
                    <div className="modal-body">
                      <input
                        type="text"
                        placeholder="Category name"
                        className="form-control"
                        value={editName}
                        onChange={(e) => setEditName(e.target.value)}
                        onKeyDown={(e) => e.key === "Enter" && handleUpdateCategory()}
                        autoFocus
                      />
                    </div>
                    <div className="modal-footer">
                      <button
                        className="btn btn-danger w-100"
                        onClick={handleUpdateCategory}
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
                      CATEGORY
                      {/* <i className="fa-solid fa-filter ml-1" style={{ fontSize: "9px", color: "#e74c3c" }}></i> */}
                    </span>
                    <span className="invoice-column-header-text">ITEMS</span>
                  </div>

                  <div className="vc-course-list">
                    {/* Loading skeleton */}
                    {loading && [...Array(4)].map((_, i) => (
                      <div key={i} className="vc-course-row" style={{ gap: 10 }}>
                        <div className="skeleton skeleton-title" style={{ flex: 1, height: 14 }}></div>
                        <div className="skeleton" style={{ width: 40, height: 20, borderRadius: 20 }}></div>
                      </div>
                    ))}

                    {!loading && filteredCategories.length === 0 && (
                      <div className="vc-list-message">No categories found</div>
                    )}

                    {!loading && filteredCategories.map((item) => {
                      const active = selectedCategory?.id === item.id;
                      return (
                        <div
                          key={item.id}
                          className={`vc-course-row ${active ? "active" : ""}`}
                          onClick={() => setSelectedCategory(item)}
                        >
                          <span className="vc-course-row-name">{item.name || "—"}</span>
                          <div style={{ display: "flex", alignItems: "center", gap: 4 }}>
                            {/* Item count badge */}
                            <span className="vc-price-badge paid" style={{ minWidth: 24, textAlign: "center" }}>
                              {item.itemCount ?? 0}
                            </span>

                            {/* 3-dot menu — only for ADMIN on non-default */}
                            {role === "ADMIN" && !isDefault(item) && (
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
                                      setEditItem(item);
                                      setEditName(item.name);
                                      setShowEditModal(true);
                                    }}>
                                      <i className="feather icon-edit-2"></i> Edit
                                    </button>
                                    <button className="danger" onClick={(e) => {
                                      e.stopPropagation();
                                      setOpenMenuId(null);
                                      handleDeleteCategory(item);
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

                  {/* Selected category name bar */}
                  {selectedCategory && (
                    <div className="vc-detail-bar">
                      <div className="vc-detail-bar-top">
                        <div className="vc-course-title-large">
                          <span>{selectedCategory.name}</span>
                          <i className="feather icon-arrow-right" style={{ fontSize: 13, color: "#94a3b8" }}></i>
                          <span className="vc-paytype-tag">Category</span>
                        </div>
                      </div>
                    </div>
                  )}

                  {/* ══ ITEMS TABLE ══ */}
                  <div className="vc-students-section">
                    <div className="vc-students-header">
                      <span className="vc-students-title" style={{ fontSize: 15 }}>
                        {selectedCategory ? `Items in "${selectedCategory.name}"` : "Items"}
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
                          {!itemsLoading && !selectedCategory && (
                            <tr>
                              <td colSpan={4} style={{ textAlign: "center", color: "#94a3b8", padding: 24 }}>
                                Select a category to view items
                              </td>
                            </tr>
                          )}
                          {!itemsLoading && selectedCategory && filteredItems.length === 0 && (
                            <tr>
                              <td colSpan={4} style={{ textAlign: "center", color: "#94a3b8", padding: 24 }}>
                                No items found in this category
                              </td>
                            </tr>
                          )}
                          {!itemsLoading && filteredItems.map((item, index) => (
                            <tr key={item.id}>
                              <td>{index + 1}</td>
                              <td>{item.itemName || "—"}</td>
                              <td>{item.itemCode || "—"}</td>
                             <td>{item.stock?.openingStock ?? 0}</td>                           
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
    </>
  );
};

export default Category;
