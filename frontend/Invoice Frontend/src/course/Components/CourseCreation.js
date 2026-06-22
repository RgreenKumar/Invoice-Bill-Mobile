import React, { useRef, useState, useContext, useEffect } from "react";
import Swal from "sweetalert2";
import withReactContent from "sweetalert2-react-content";
import baseUrl from "../../api/utils";
import { useNavigate, useParams } from "react-router-dom";
import axios from "axios";
import "../../assets/css/invoicestyle.css";
import { GlobalStateContext } from "../../Context/GlobalStateProvider";
import { getPermission } from "../../utils/permissionUtils";
import MODULES from "../../utils/modules";


const MySwal = withReactContent(Swal);

const AddItem = () => {
  const token = sessionStorage.getItem("token");
  const navigate = useNavigate();
  const { id } = useParams(); // ← get id from URL if editing
  const isEditMode = !!id;   // ← true if /edititem/:id

  const [activeTab, setActiveTab] = useState("pricing");
  const [showWholesale, setShowWholesale] = useState(false);
  const [previewImage, setPreviewImage] = useState(null);
  const { gstSettings, itemSettings } = useContext(GlobalStateContext);

  const [categories, setCategories] = useState([]);
  const [units, setUnits] = useState([]);
  const [taxes, setTaxes] = useState([]);
  const [suggestions, setSuggestions] = useState([]);
  const [showSuggestions, setShowSuggestions] = useState(false);
  const searchTimeout = useRef(null);
  const [saving, setSaving] = useState(false);
  const [generatingCode, setGeneratingCode] = useState(false);
  const [loadingItem, setLoadingItem] = useState(false);
  const canView = getPermission(MODULES.STOCK_ADJUSTMENT, "canView");
  const canEdit   = getPermission(MODULES.STOCK_ADJUSTMENT, "canEdit");
  const canDelete = getPermission(MODULES.STOCK_ADJUSTMENT, "canDelete");

  const [formData, setFormData] = useState({
    itemName: "",
    itemHSN: "",
    unitId: "",
    categoryId: "",
    itemCode: "",
    mrp: "",
    calculateTaxOnMRP: false,
    salePrice: "",
    taxType: "without_tax",
    additionalCessPerUnit: "",
    discount: "",
    discountType: "Percentage",
    wholesalePrice: "",
    wholesaleTaxType: "without_tax",
    purchasePrice: "",
    purchaseTaxType: "without_tax",
    taxId: "",
    openingStock: "",
    atPrice: "",
    asOfDate: "",
    minStockQty: "",
    location: "",
    itemImage: null,
  });

  const [errors, setErrors] = useState({});

  useEffect(() => {
    if (!itemSettings.stockMaintenance) {
      setActiveTab("pricing");
    }
  }, [itemSettings.stockMaintenance]);

  // ── Fetch dropdowns on mount ─────────────────────────────
  useEffect(() => {
    fetchCategories();
    fetchUnits();
    fetchTaxes();
  }, []);

  // ── If edit mode → fetch item data and pre-fill ──────────
  useEffect(() => {
    if (isEditMode) {
      fetchItemById(id);
    }
  }, [id]);

  // ═══════════════════════════════════════════════
  // FETCH ITEM BY ID — pre-fill form for edit
  // ═══════════════════════════════════════════════
  const fetchItemById = async (itemId) => {
    try {
      setLoadingItem(true);
      const res = await axios.get(`${baseUrl}/getItem/${itemId}`, {
        headers: { Authorization: token },
      });
      const item = res.data;

      // pre-fill form with fetched data
      setFormData({
        itemName:             item.itemName || "",
        itemHSN:              item.itemHsn || "",
        unitId:               item.unitId ? String(item.unitId) : "",
        categoryId:           item.categoryId ? String(item.categoryId) : "",
        itemCode:             item.itemCode || "",
        mrp:                  item.pricing?.mrp ? String(item.pricing.mrp) : "",
        calculateTaxOnMRP:    item.pricing?.calculateTaxOnMrp || false,
        salePrice:            item.pricing?.salePrice ? String(item.pricing.salePrice) : "",
        taxType:              item.pricing?.salePriceTaxType || "without_tax",
        additionalCessPerUnit: item.pricing?.additionalCessPerUnit ? String(item.pricing.additionalCessPerUnit) : "",
        discount:             item.pricing?.discountOnSale ? String(item.pricing.discountOnSale) : "",
        discountType:         item.pricing?.discountType
                                ? item.pricing.discountType.charAt(0).toUpperCase() + item.pricing.discountType.slice(1)
                                : "Percentage",
        wholesalePrice:       item.pricing?.wholesalePrice ? String(item.pricing.wholesalePrice) : "",
        wholesaleTaxType:     item.pricing?.wholesalePriceTaxType || "without_tax",
        purchasePrice:        item.pricing?.purchasePrice ? String(item.pricing.purchasePrice) : "",
        purchaseTaxType:      item.pricing?.purchasePriceTaxType || "without_tax",
        taxId:                item.pricing?.taxId ? String(item.pricing.taxId) : "",
        openingStock:         item.stock?.openingStock ? String(item.stock.openingStock) : "",
        atPrice:              item.stock?.stockAtPrice ? String(item.stock.stockAtPrice) : "",
        asOfDate:             item.stock?.stockAsOfDate || "",
        minStockQty:          item.stock?.minStockQty ? String(item.stock.minStockQty) : "",
        location:             item.stock?.location || "",
        itemImage:            null, // don't pre-fill image
      });

      // show wholesale section if any wholesale/purchase price exists
      if (item.pricing?.wholesalePrice || item.pricing?.purchasePrice) {
        setShowWholesale(true);
      }

      // show image preview if exists
      if (item.itemImage) {
        setPreviewImage(`data:image/jpeg;base64,${item.itemImage}`);
      }

    } catch (err) {
      console.error("Failed to fetch item", err);
      MySwal.fire("Error", "Failed to load item data!", "error");
    } finally {
      setLoadingItem(false);
    }
  };

  const fetchCategories = async () => {
    try {
      const res = await axios.get(`${baseUrl}/getCategories`, {
        headers: { Authorization: token },
      });
      setCategories(res.data);
    } catch (err) {
      console.error("Failed to load categories", err);
    }
  };

  const fetchUnits = async () => {
    try {
      const res = await axios.get(`${baseUrl}/getUnits`, {
        headers: { Authorization: token },
      });
      setUnits(res.data);
      
      if (!isEditMode && itemSettings.defaultUnit) {
      const matched = res.data.find(
        (u) => u.name.toLowerCase() === itemSettings.defaultUnit.toLowerCase()
      );
      if (matched) {
        setFormData((prev) => ({ ...prev, unitId: String(matched.id) }));
      }
    }

  } catch (err) {
      console.error("Failed to load units", err);
    }
  };

  const fetchTaxes = async () => {
    try {
      const res = await axios.get(`${baseUrl}/getTaxes`, {
        headers: { Authorization: token },
      });
      setTaxes(res.data);
    } catch (err) {
      console.error("Failed to load taxes", err);
    }
  };

  const handleChange = (e) => {
    const { name, value, type, checked } = e.target;
    setFormData((prev) => ({
      ...prev,
      [name]: type === "checkbox" ? checked : value,
    }));

    if (errors[name]) {
      setErrors((prev) => ({ ...prev, [name]: "" }));
    }

    if (name === "itemName") {
      if (value.length >= 2) {
        clearTimeout(searchTimeout.current);
        searchTimeout.current = setTimeout(() => {
          searchItemSuggestions(value);
        }, 400);
      } else {
        setSuggestions([]);
        setShowSuggestions(false);
      }
    }

    if (name === "itemHSN") {
      if (value && value.length !== 4 && value.length !== 6 && value.length !== 8) {
        setErrors((prev) => ({ ...prev, itemHSN: "HSN must be 4, 6, or 8 digits" }));
      } else {
        setErrors((prev) => ({ ...prev, itemHSN: "" }));
      }
    }
  };

  const searchItemSuggestions = async (name) => {
    try {
      const res = await axios.get(`${baseUrl}/searchItems?name=${name}`, {
        headers: { Authorization: token },
      });
      setSuggestions(res.data);
      setShowSuggestions(res.data.length > 0);
    } catch (err) {
      console.error("Search failed", err);
    }
  };

  const handleSuggestionClick = (item) => {
    if (item.itemName.toLowerCase() === formData.itemName.toLowerCase()) {
      setFormData((prev) => ({
        ...prev,
        itemHSN: item.itemHsn || "",
        itemCode: item.itemCode || "",
      }));
    } else {
      setFormData((prev) => ({
        ...prev,
        itemName: item.itemName,
        itemHSN: item.itemHsn || "",
      }));
    }
    setSuggestions([]);
    setShowSuggestions(false);
  };

  const handleGenerateCode = async () => {
    setGeneratingCode(true);
    try {
      const res = await axios.get(`${baseUrl}/generateItemCode`, {
        headers: { Authorization: token },
      });
      setFormData((prev) => ({ ...prev, itemCode: res.data }));
    } catch (err) {
      MySwal.fire("Error", "Failed to generate item code!", "error");
    } finally {
      setGeneratingCode(false);
    }
  };

  const handleFileChange = (e) => {
    const file = e.target.files[0];
    if (!file) return;
    if (!["image/jpeg", "image/png"].includes(file.type)) {
      MySwal.fire("Error", "Please select JPG or PNG", "error");
      return;
    }
    if (file.size > 50 * 1024) {
      MySwal.fire("Error", "Image must be 50 KB or smaller", "error");
      return;
    }
    const reader = new FileReader();
    reader.onload = () => {
      setPreviewImage(reader.result);
      const base64 = reader.result.split(",")[1];
      setFormData((prev) => ({ ...prev, itemImage: base64 }));
    };
    reader.readAsDataURL(file);
  };

  const validate = () => {
    const newErrors = {};
    if (!formData.itemName.trim())
      newErrors.itemName = "Item Name is required";
    if (!formData.salePrice)
      newErrors.salePrice = "Sale Price is required";
    if (formData.itemHSN &&
      formData.itemHSN.length !== 4 &&
      formData.itemHSN.length !== 6 &&
      formData.itemHSN.length !== 8)
      newErrors.itemHSN = "HSN must be 4, 6, or 8 digits";
    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const buildDTO = () => {
    return {
      itemName: formData.itemName.trim(),
      itemHsn: formData.itemHSN || null,
      itemCode: formData.itemCode || null,
      categoryId: formData.categoryId ? parseInt(formData.categoryId) : null,
      unitId: formData.unitId ? parseInt(formData.unitId) : null,
      itemImage: formData.itemImage || null,
      pricing: {
        salePrice: formData.salePrice ? parseFloat(formData.salePrice) : null,
        salePriceTaxType: formData.taxType,
        discountOnSale: formData.discount ? parseFloat(formData.discount) : null,
        discountType: formData.discountType.toLowerCase(),
        wholesalePrice: formData.wholesalePrice ? parseFloat(formData.wholesalePrice) : null,
        wholesalePriceTaxType: formData.wholesaleTaxType,
        purchasePrice: formData.purchasePrice ? parseFloat(formData.purchasePrice) : null,
        purchasePriceTaxType: formData.purchaseTaxType,
        taxId: formData.taxId ? parseInt(formData.taxId) : null,
        mrp: formData.mrp ? parseFloat(formData.mrp) : null,
        calculateTaxOnMrp: formData.calculateTaxOnMRP,
        additionalCessPerUnit: formData.additionalCessPerUnit
          ? parseFloat(formData.additionalCessPerUnit) : null,
      },
      stock: itemSettings.stockMaintenance ? {
        openingStock: formData.openingStock ? parseInt(formData.openingStock) : null,
        stockAtPrice: formData.atPrice ? parseFloat(formData.atPrice) : null,
        stockAsOfDate: formData.asOfDate || null,
        minStockQty: formData.minStockQty ? parseInt(formData.minStockQty) : null,
        location: formData.location || null,
      } : null,
    };
  };

  // ═══════════════════════════════════════════════
  // SUBMIT — Add or Update based on mode
  // ═══════════════════════════════════════════════
  const handleSubmit = async () => {
    if (!validate()) return;
    setSaving(true);
    try {
      if (isEditMode) {
        // ── UPDATE ──
        await axios.put(`${baseUrl}/updateItem/${id}`, buildDTO(), {
          headers: { Authorization: token },
        });
        MySwal.fire("Success", "Item updated successfully!", "success")
          .then(() => navigate(-1));
      } else {
        // ── ADD NEW ──
        await axios.post(`${baseUrl}/addItem`, buildDTO(), {
          headers: { Authorization: token },
        });
        MySwal.fire("Success", "Item saved successfully!", "success")
          .then(() => navigate(-1));
      }
    } catch (error) {
      if (error.response?.status === 403)
        MySwal.fire("Error", "Access Denied!", "error");
      else if (error.response?.status === 409)
        MySwal.fire("Error", error.response.data || "Duplicate item!", "error");
      else
        MySwal.fire("Error", "Something went wrong!", "error");
    } finally {
      setSaving(false);
    }
  };

  const resetForm = () => {
    setFormData({
      itemName: "", itemHSN: "", unitId: "", categoryId: "", itemCode: "",
      mrp: "", calculateTaxOnMRP: false, salePrice: "", taxType: "without_tax",
      additionalCessPerUnit: "", discount: "", discountType: "Percentage",
      wholesalePrice: "", wholesaleTaxType: "without_tax", purchasePrice: "",
      purchaseTaxType: "without_tax", taxId: "", openingStock: "", atPrice: "",
      asOfDate: "", minStockQty: "", location: "", itemImage: null,
    });
    setPreviewImage(null);
    setErrors({});
    setShowWholesale(false);
  };

  if (loadingItem) {
    return (
      <div className="add-item-wrapper" style={{ display: "flex", alignItems: "center", justifyContent: "center", height: "60vh" }}>
        <div className="spinner-border text-danger"></div>
      </div>
    );
  }

  return (
    <div className="add-item-wrapper">
      <div className="card add-item-card">
        <div className="card-body p-0">

          {/* ── Header ── */}
          <div className="add-item-header">
            <h5 className="add-item-header-title">
              {isEditMode ? "Edit Item" : "Add Item"}
            </h5>
            <div className="add-item-header-right">
              <button className="add-item-icon-btn" onClick={() => navigate(-1)} title="Close">
                <i className="fa-solid fa-xmark" />
              </button>
            </div>
          </div>

          {/* ── Top Section ── */}
          <div className="add-item-top-section">
            <div className="add-item-row">
              <div style={{ display: "flex", gap: 8 }}>

                {/* Item Name */}
                <div style={{ width: 420, flexShrink: 0, position: "relative" }}>
                  <input
                    type="text"
                    name="itemName"
                    placeholder="Item Name *"
                    value={formData.itemName}
                    onChange={handleChange}
                    onBlur={() => setTimeout(() => setShowSuggestions(false), 200)}
                    className={`add-item-input ${errors.itemName ? "add-item-input-error" : "add-item-input-highlight"}`}
                    autoFocus
                  />
                  {errors.itemName && <span className="add-item-error">{errors.itemName}</span>}

                  {showSuggestions && suggestions.length > 0 && (
                    <div style={{
                      position: "absolute", top: "100%", left: 0, right: 0,
                      background: "#fff", border: "1px solid #e2e8f0",
                      borderRadius: 6, boxShadow: "0 4px 12px rgba(0,0,0,0.1)",
                      zIndex: 999, maxHeight: 200, overflowY: "auto"
                    }}>
                      {suggestions.map((item) => (
                        <div
                          key={item.id}
                          onClick={() => handleSuggestionClick(item)}
                          style={{ padding: "8px 12px", cursor: "pointer", fontSize: 13, borderBottom: "1px solid #f1f5f9" }}
                          onMouseEnter={(e) => e.currentTarget.style.background = "#f8fafc"}
                          onMouseLeave={(e) => e.currentTarget.style.background = "#fff"}
                        >
                          <span style={{ fontWeight: 600 }}>{item.itemName}</span>
                          {item.itemHsn && (
                            <span style={{ color: "#94a3b8", marginLeft: 8, fontSize: 11 }}>HSN: {item.itemHsn}</span>
                          )}
                        </div>
                      ))}
                    </div>
                  )}
                </div>

                {/* HSN */}
                {gstSettings.enableHSN && (
                  <div style={{ width: 420, flexShrink: 0, position: "relative" }}>
                    <input
                      type="text"
                      name="itemHSN"
                      placeholder="Item HSN (4, 6, or 8 digits)"
                      value={formData.itemHSN}
                      onChange={handleChange}
                      className={`add-item-input ${errors.itemHSN ? "add-item-input-error" : ""}`}
                      maxLength={8}
                    />
                    {errors.itemHSN && <span className="add-item-error">{errors.itemHSN}</span>}
                    <i className="fa-solid fa-magnifying-glass add-item-search-icon" />
                  </div>
                )}
              </div>

              {/* Unit */}
              {itemSettings.itemsUnit && (
                <select name="unitId" value={formData.unitId} onChange={handleChange} className="add-item-select" style={{ width: 150 }}>
                  <option value="">Select Unit</option>
                  {units.map((u) => (
                    <option key={u.id} value={u.id}>{u.name} ({u.symbol})</option>
                  ))}
                </select>
              )}

              {/* Image */}
              {/* <label className="add-item-add-image-btn">
                {previewImage
                  ? <img src={previewImage} alt="preview" className="add-item-image-preview" />
                  : <i className="fa-solid fa-camera" style={{ fontSize: 18, color: "#888" }} />
                }
                <span>Add Item Image</span>
                <input type="file" onChange={handleFileChange} style={{ display: "none" }} />
              </label> */}
            </div>

            {/* Row 2 */}
            <div className="add-item-row">
              {itemSettings.itemCategory && (
                <div style={{ width: 200 }}>
                  <select name="categoryId" value={formData.categoryId} onChange={handleChange} className="add-item-select">
                    <option value="">Category</option>
                    {categories.map((c) => (
                      <option key={c.id} value={c.id}>{c.name}</option>
                    ))}
                  </select>
                </div>
              )}

              <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
                <input
                  type="text"
                  name="itemCode"
                  placeholder="Item Code"
                  value={formData.itemCode}
                  onChange={handleChange}
                  className="add-item-input"
                  style={{ width: 160 }}
                />
                <button className="add-item-assign-code-btn" onClick={handleGenerateCode} disabled={generatingCode}>
                  {generatingCode ? "..." : "Assign Code"}
                </button>
              </div>
            </div>
          </div>

          {/* ── Tabs ── */}
          <div className="add-item-tab-bar">
            {["pricing", "stock"].map((tab) => {
              if (tab === "stock" && !itemSettings.stockMaintenance) return null;
              if (tab === "stock" && !canView) return null;
              return (
                <button
                  key={tab}
                  className={activeTab === tab ? "add-item-tab-btn-active" : "add-item-tab-btn"}
                  onClick={() => setActiveTab(tab)}
                >
                  {tab.charAt(0).toUpperCase() + tab.slice(1)}
                </button>
              );
            })}
          </div>
        
          {/* ── Tab Body ── */}
          <div className="add-item-tab-body">

            {/* PRICING TAB */}
            {activeTab === "pricing" && (
              <div>
                  {itemSettings.mrp&&(
                <>    
                <p className="add-item-section-title">MRP</p>
                <div className="add-item-pricing-row">
                  <div className="add-item-input-group">
                    <input type="number" name="mrp" placeholder="MRP Price" value={formData.mrp} onChange={handleChange} className="add-item-ig-input" />
                  </div>
                  <label style={{ display: "flex", alignItems: "center", gap: 8, cursor: "pointer", whiteSpace: "nowrap" }}>
                    <input type="checkbox" name="calculateTaxOnMRP" checked={formData.calculateTaxOnMRP} onChange={handleChange} />
                    Calculate Tax based on MRP
                  </label>
                </div>
                </>
                  )}
                  


                <p className="add-item-section-title">Sale Price</p>
                {errors.salePrice && <span className="add-item-error">{errors.salePrice}</span>}
                <div className="add-item-pricing-row">
                  <div className="add-item-input-group">
                    <input
                      type="number" name="salePrice" placeholder="Sale Price"
                      value={formData.salePrice} onChange={handleChange}
                      className={`add-item-ig-input ${errors.salePrice ? "add-item-input-error" : ""}`}
                    />
                    {itemSettings.itemWiseTax && (
                      <select name="taxType" value={formData.taxType} onChange={handleChange} className="add-item-ig-select">
                        <option value="without_tax">Without Tax</option>
                        <option value="with_tax">With Tax</option>
                      </select>
                    )}
                  </div>
                  {itemSettings.itemWiseDiscount && (
                    <div className="add-item-input-group">
                      <input type="number" name="discount" placeholder="Disc. On Sale Price" value={formData.discount} onChange={handleChange} className="add-item-ig-input" />
                      <select name="discountType" value={formData.discountType} onChange={handleChange} className="add-item-ig-select">
                        <option>Percentage</option>
                        <option>Amount</option>
                      </select>
                    </div>
                  )}
                </div>

                {!showWholesale && (
                  <div onClick={() => setShowWholesale(true)} className="add-item-add-wholesale-link">
                    + Add Wholesale Price
                  </div>
                )}

                {showWholesale && (
                  <>
                    <p className="add-item-section-title">Wholesale Price</p>
                    <div className="add-item-pricing-row">
                      <div className="add-item-input-group">
                        <input type="number" name="wholesalePrice" placeholder="Wholesale Price" value={formData.wholesalePrice} onChange={handleChange} className="add-item-ig-input" />
                        {itemSettings.itemWiseTax && (
                          <select name="wholesaleTaxType" value={formData.wholesaleTaxType} onChange={handleChange} className="add-item-ig-select">
                            <option value="without_tax">Without Tax</option>
                            <option value="with_tax">With Tax</option>
                          </select>
                        )}
                      </div>
                    </div>

                    <p className="add-item-section-title">Purchase Price</p>
                    <div className="add-item-pricing-row">
                      <div className="add-item-input-group">
                        <input type="number" name="purchasePrice" placeholder="Purchase Price" value={formData.purchasePrice} onChange={handleChange} className="add-item-ig-input" />
                        {itemSettings.itemWiseTax && (
                          <select name="purchaseTaxType" value={formData.purchaseTaxType} onChange={handleChange} className="add-item-ig-select">
                            <option value="without_tax">Without Tax</option>
                            <option value="with_tax">With Tax</option>
                          </select>
                        )}
                      </div>
                    </div>

                        {gstSettings.enableGST && (
                    <p className="add-item-section-title">Taxes</p>
                  )}

                  <div
                    style={{
                      display: "flex",
                      alignItems: "center",
                      gap: 12,
                      flexWrap: "wrap",
                    }}
                  >
                    {gstSettings.enableGST && (
                      <select
                        name="taxId"
                        value={formData.taxId}
                        onChange={handleChange}
                        className="add-item-select"
                        style={{ width: 180 }}
                      >
                        <option value="">Select Tax</option>
                        {taxes.map((t) => (
                          <option key={t.id} value={t.id}>
                            {t.name} ({t.rate}%)
                          </option>
                        ))}
                      </select>
                    )}

                    {gstSettings.additionalCess && (
                      <input
                        type="number"
                        name="additionalCessPerUnit"
                        placeholder="Additional Cess Per Unit"
                        value={formData.additionalCessPerUnit}
                        onChange={handleChange}
                        className="add-item-input"
                        style={{ width: 200 }}
                      />
                    )}
                  </div>
                  </> 
                )}
              </div>
            )}

            {/* STOCK TAB */}
              {itemSettings.stockMaintenance && activeTab === "stock" && canView && (
                <div className="add-item-stock-grid">
                {[
                  { label: "Opening Stock", name: "openingStock", type: "number", placeholder: "0" },
                  { label: "At Price (₹)", name: "atPrice", type: "number", placeholder: "0.00" },
                  { label: "As of Date", name: "asOfDate", type: "date", placeholder: "" },
                  { label: "Min Stock Qty", name: "minStockQty", type: "number", placeholder: "0" },
                  { label: "Location", name: "location", type: "text", placeholder: "Warehouse / Location" },
                ].map((f) => (
              <div key={f.name}>
                <label className="add-item-stock-label">{f.label}</label>
                <input
                  type={f.type}
                  name={f.name}
                  placeholder={f.placeholder}
                  value={formData[f.name]}
                  onChange={handleChange}
                  className="add-item-input"
                  {...(["openingStock", "minStockQty"].includes(f.name) ? {
                    max: Math.pow(10, itemSettings.quantityDecimalPlaces) - 1,
                    onInput: (e) => {
                      if (e.target.value.length > itemSettings.quantityDecimalPlaces) {
                        e.target.value = e.target.value.slice(0, itemSettings.quantityDecimalPlaces);
                      }
                    }
                  } : {})}
                />
              </div>
            ))}           
           </div>
            )}

          </div>

          {/* ── Footer ── */}
          <div className="add-item-footer">
            <button className="add-item-btn-secondary" onClick={() => navigate(-1)}>Cancel</button>
            <button className="btn btn-primary has-ripple" onClick={handleSubmit} disabled={saving}>
              {saving ? (isEditMode ? "Updating..." : "Saving...") : (isEditMode ? "Update" : "Save")}
            </button>
          </div>

        </div>
      </div>
    </div>
  );
};

export default AddItem;
