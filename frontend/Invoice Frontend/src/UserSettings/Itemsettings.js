import React, { useState, useContext,useEffect } from "react";
import { useNavigate } from "react-router-dom";
import axios from "axios";
import Swal from "sweetalert2";
import withReactContent from "sweetalert2-react-content";
import baseUrl from "../api/utils";
import { GlobalStateContext } from "../Context/GlobalStateProvider";
import { getPermission } from "../utils/permissionUtils";
import MODULES from "../utils/modules";

const MySwal = withReactContent(Swal);

const ItemSettings = () => {
  const navigate = useNavigate();
  const token = sessionStorage.getItem("token");
  const [isEdit, setIsEdit] = useState(false);
  const [units, setUnits] = useState([]);
  const canCreate = getPermission(MODULES.SETTINGS, "canCreate");
  const canEdit   = getPermission(MODULES.SETTINGS, "canEdit");
  const canDelete = getPermission(MODULES.SETTINGS, "canDelete");

              
              

  const { setItemSettings: setGlobalItemSettings } = useContext(GlobalStateContext);

const [itemSettings, setItemSettings] = useState({
  enableItem: true,
  stockMaintenance: true,
  showLowStockDialog: true,
  itemsUnit: true,
  defaultUnit: "",
  defaultUnitName: "",
  itemCategory: true,
  description: false,
  itemWiseTax: true,
  itemWiseDiscount: true,
  quantityDecimalPlaces: 2,
  wholesalePrice: true,
  mrp: false,
  calculateTaxBasedOnMrp: false,
  expDate: true,
  expDateFormat: "mm/yy",
  mfgDate: true,
  mfgDateFormat: "dd/mm/yy",
  modelNo: false,
  size: false,
});

  const handleChange = (key) => {
    setItemSettings((prev) => ({ ...prev, [key]: !prev[key] }));
  };

  const handleSelectChange = (key, value) => {
    setItemSettings((prev) => ({ ...prev, [key]: value }));
  };

  useEffect(() => {
  axios
    .get(`${baseUrl}/settings/item/get`, {
      headers: { Authorization: token },
    })
    .then((res) => {
      setItemSettings(res.data);
    })
    .catch((err) => {
      console.error("Failed to load item settings", err);
    });
}, []);



  useEffect(() => {
  axios
    .get(`${baseUrl}/getUnits`, {
      headers: { Authorization: token },
    })
    .then((res) => {
       console.log("UNITS RESPONSE:", res.data);
      setUnits(res.data || []);
    })
    .catch(() => {
      console.error("Failed to load units");
    });
}, []);

 const handleSave = () => {
  axios
    .post(`${baseUrl}/settings/item/save`, itemSettings, {
      headers: { Authorization: token },
    })
    .then(() => {
      setGlobalItemSettings(itemSettings); // ✅ push to global context only after successful save
      MySwal.fire({
        icon: "success",
        title: "Saved!",
        text: "Item Settings saved successfully.",
        confirmButtonText: "OK",
      }).then((result) => {
        if (result.isConfirmed) setIsEdit(false);
      });
    })
    .catch(() => {
      MySwal.fire("Error", "Failed to save Item settings", "error");
    });
};

  const CheckboxRow = ({ keyName, label, info = true }) => (
    <div style={{ display: "flex", alignItems: "center", gap: "10px", marginBottom: "13px" }}>
      <input
        type="checkbox"
        id={keyName}
        checked={itemSettings[keyName]}
        onChange={() => handleChange(keyName)}
        disabled={!isEdit}
        style={{
          width: "16px",
          height: "16px",
          accentColor: "#1a6fdb",
          cursor: "pointer",
          flexShrink: 0,
        }}
      />
      <label
        htmlFor={keyName}
        style={{ margin: 0, fontSize: "13.5px", color: "#333", cursor: "pointer", flex: 1 }}
      >
        {label}
      </label>
      {info && (
        <i
          className="fa-solid fa-circle-question"
          style={{ color: "#bbb", fontSize: "13px", cursor: "pointer" }}
        ></i>
      )}
    </div>
  );

  const SectionTitle = ({ title }) => (
    <div style={{ display: "flex", alignItems: "center", gap: "6px", marginBottom: "12px", marginTop: "6px" }}>
      <span style={{ fontWeight: "600", fontSize: "13.5px", color: "#222" }}>{title}</span>
    </div>
  );

  const FieldInput = ({ placeholder }) => (
    <input
      type="text"
      placeholder={placeholder}
      disabled={!isEdit}
      style={{
        border: "1px solid #ddd",
        borderRadius: "4px",
        padding: "5px 10px",
        fontSize: "13px",
        color: "#aaa",
        width: "130px",
        outline: "none",
        background: "#fafafa",
      }}
    />
  );

  const DateSelect = ({ value, onChange }) => (
    <select
      value={value}
      onChange={onChange}
      disabled={!isEdit}
      style={{
        border: "1px solid #ddd",
        borderRadius: "4px",
        padding: "5px 6px",
        fontSize: "12px",
        color: "#555",
        background: "#fafafa",
        cursor: "pointer",
        outline: "none",
        width: "90px",
      }}
    >
      <option value="mm/yy">mm/yy</option>
      <option value="dd/mm/yy">dd/mm/yy</option>
      <option value="mm/dd/yy">mm/dd/yy</option>
    </select>
  );

  return (
    <div>
      <div className="card" style={{ margin: "0 -25px 0 -20px", marginTop: "-115px" }}>
        <div className="card-body" style={{ padding: "20px 24px" }}>

          {/* Top Nav */}
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "18px" }}>
            <div onClick={() => navigate(-1)} style={{ cursor: "pointer", fontSize: "16px", color: "#333" }}>
              <i className="fa-solid fa-arrow-left"></i>
            </div>
            <div onClick={() => navigate(-1)} style={{ cursor: "pointer", fontSize: "18px", color: "#555" }}>
              <i className="fa-solid fa-xmark"></i>
            </div>
          </div>

          {/* Layout */}
          <div style={{ display: "flex", gap: "32px", alignItems: "flex-start", flexWrap: "wrap" }}>

            {/* Column 1 */}
            <div style={{ minWidth: "220px", flex: "1" }}>
              <div style={{ borderBottom: "2px solid #e0e0e0", paddingBottom: "6px", marginBottom: "16px" }}>
                <span style={{ fontWeight: "700", fontSize: "14px", color: "#111" }}>Item Settings</span>
              </div>

              <CheckboxRow keyName="enableItem" label="Enable Item" />
              
              <CheckboxRow keyName="stockMaintenance" label="Stock Maintenance" />
              <CheckboxRow keyName="showLowStockDialog" label="Show Low Stock Dialog" />
              <CheckboxRow keyName="itemsUnit" label="Items Unit" />
                            
                          {/* Default Unit */}
              <div style={{ display: "flex", alignItems: "center", gap: "10px", marginBottom: "13px" }}>
                <input
                  type="checkbox"
                  id="defaultUnit"
                  checked={!!itemSettings.defaultUnit}
                  disabled={!isEdit}
                 onChange={() => {
                      if (itemSettings.defaultUnit) {
                        setItemSettings((prev) => ({ ...prev, defaultUnit: null, defaultUnitName: null }));
                      } else {
                        if (!units.length) {
                          MySwal.fire("No Units Found", "Please add units first.", "info");
                          return;
                        }

                        const optionsHtml = units
                          .map((u) => `<option value="${u.id}">${u.name}</option>`)   // ✅ u.name not u.unitName
                          .join("");

                        MySwal.fire({
                          title: "Select Default Unit",
                          html: `
                            <select id="unit-select" class="swal2-input" style="width:100%">
                              <option value="">-- Select Unit --</option>
                              ${optionsHtml}
                            </select>
                          `,
                          confirmButtonText: "Set Default",
                          showCancelButton: true,
                          preConfirm: () => {
                            const select = document.getElementById("unit-select");
                            const val = select.value;
                            if (!val) {
                              Swal.showValidationMessage("Please select a unit!");
                              return false;
                            }
                            const label = select.options[select.selectedIndex].text;
                            return { id: val, name: label };
                          },
                        }).then((result) => {
                          if (result.isConfirmed && result.value) {
                            setItemSettings((prev) => ({
                              ...prev,
                              defaultUnit: result.value.id,
                              defaultUnitName: result.value.name,
                            }));
                          }
                        });
                      }
                    }}
                  style={{
                    width: "16px",
                    height: "16px",
                    accentColor: "#1a6fdb",
                    cursor: "pointer",
                    flexShrink: 0,
                  }}
                />
                <label
                  htmlFor="defaultUnit"
                  style={{ margin: 0, fontSize: "13.5px", color: "#333", cursor: "pointer", flex: 1 }}
                >
                  Default Unit
                  {itemSettings.defaultUnit && (
                    <span style={{ marginLeft: "8px", fontSize: "12px", color: "#1a6fdb", fontWeight: "600" }}>
                      ({itemSettings.defaultUnitName})
                    </span>
                  )}
                </label>
                <i className="fa-solid fa-circle-question" style={{ color: "#bbb", fontSize: "13px", cursor: "pointer" }}></i>
              </div>

              <CheckboxRow keyName="itemCategory" label="Item Category" />

              {/* Description with Change Text */}
              <div style={{ display: "flex", alignItems: "center", gap: "10px", marginBottom: "13px" }}>
                <input
                  type="checkbox"
                  id="description"
                  checked={itemSettings.description}
                  onChange={() => handleChange("description")}
                  disabled={!isEdit}
                  style={{ width: "16px", height: "16px", accentColor: "#1a6fdb", cursor: "pointer", flexShrink: 0 }}
                />
                <label htmlFor="description" style={{ margin: 0, fontSize: "13.5px", color: "#333", cursor: "pointer" }}>
                  Description
                </label>
                <span style={{ fontSize: "12px", color: "#aaa", cursor: "pointer" }}>Change Text</span>
                <i className="fa-solid fa-circle-question" style={{ color: "#bbb", fontSize: "13px" }}></i>
              </div>

              <CheckboxRow keyName="itemWiseTax" label="Item wise Tax" />
              <CheckboxRow keyName="itemWiseDiscount" label="Item wise Discount" />

              {/* Quantity Decimal Places */}
              <div style={{ display: "flex", alignItems: "center", gap: "8px", marginBottom: "13px" }}>
                <span style={{ fontSize: "13.5px", color: "#333" }}>Quantity</span>
                <span style={{ fontSize: "12px", color: "#777" }}>(upto Decimal Places)</span>
                <i className="fa-solid fa-circle-question" style={{ color: "#bbb", fontSize: "13px" }}></i>

                <div style={{ display: "flex", flexDirection: "column", border: "1px solid #ccc", borderRadius: "4px", overflow: "hidden" }}>
                  <button
                    type="button"
                    disabled={!isEdit}
                    onClick={() =>
                      setItemSettings((prev) => ({
                        ...prev,
                        quantityDecimalPlaces: Math.min((prev.quantityDecimalPlaces ?? 0) + 1, 9),
                      }))
                    }
                    style={{ background: "#f5f5f5", border: "none", cursor: "pointer", fontSize: "10px", padding: "1px 6px", lineHeight: 1.2 }}
                  >
                    ▲
                  </button>
                  <div style={{ textAlign: "center", fontSize: "13px", padding: "1px 8px", background: "#fff", borderTop: "1px solid #eee", borderBottom: "1px solid #eee" }}>
                    {itemSettings.quantityDecimalPlaces}
                  </div>
                  <button
                    type="button"
                    disabled={!isEdit}
                    onClick={() =>
                      setItemSettings((prev) => ({
                        ...prev,
                        quantityDecimalPlaces: Math.max((prev.quantityDecimalPlaces ?? 0) - 1, 0),
                      }))
                    }
                    style={{ background: "#f5f5f5", border: "none", cursor: "pointer", fontSize: "10px", padding: "1px 6px", lineHeight: 1.2 }}
                  >
                    ▼
                  </button>
                </div>

                <span style={{ fontSize: "12px", color: "#aaa" }}>
                  e.g. {Number(0).toFixed(itemSettings.quantityDecimalPlaces)}
                </span>
              </div>

              <CheckboxRow keyName="wholesalePrice" label="Wholesale Price" />
            </div>

            {/* Column 2 */}
            <div style={{ minWidth: "260px", flex: "1" }}>
              <div style={{ borderBottom: "2px solid #e0e0e0", paddingBottom: "6px", marginBottom: "16px" }}>
                <span style={{ fontWeight: "700", fontSize: "14px", color: "#111" }}>Additional Item Fields</span>
              </div>

              <SectionTitle title="MRP/Price" />

              {/* MRP */}
              <div style={{ display: "flex", alignItems: "center", gap: "10px", marginBottom: "13px" }}>
                <input
                  type="checkbox"
                  id="mrp"
                  checked={itemSettings.mrp}
                  onChange={() => handleChange("mrp")}
                  disabled={!isEdit}
                  style={{ width: "16px", height: "16px", accentColor: "#1a6fdb", cursor: "pointer", flexShrink: 0 }}
                />
                <label htmlFor="mrp" style={{ margin: 0, fontSize: "13.5px", color: "#333", cursor: "pointer", width: "160px" }}>
                  MRP
                </label>
                <i className="fa-solid fa-circle-question" style={{ color: "#bbb", fontSize: "13px" }}></i>
                <FieldInput placeholder="MRP" />
              </div>

              {/* Calculate Tax based on MRP */}
              <div style={{ display: "flex", alignItems: "center", gap: "10px", marginBottom: "18px" }}>
                <input
                  type="checkbox"
                  id="calculateTaxBasedOnMrp"
                  checked={itemSettings.calculateTaxBasedOnMrp}
                  onChange={() => handleChange("calculateTaxBasedOnMrp")}
                  disabled={!isEdit}
                  style={{ width: "16px", height: "16px", accentColor: "#1a6fdb", cursor: "pointer", flexShrink: 0 }}
                />
                <label htmlFor="calculateTaxBasedOnMrp" style={{ margin: 0, fontSize: "13.5px", color: "#333", cursor: "pointer", flex: 1 }}>
                  Calculate Tax based on MRP
                </label>
                <i className="fa-solid fa-circle-question" style={{ color: "#bbb", fontSize: "13px" }}></i>
              </div>

              {/* Exp Date */}
              <div style={{ display: "flex", alignItems: "center", gap: "10px", marginBottom: "13px" }}>
                <input
                  type="checkbox"
                  id="expDate"
                  checked={itemSettings.expDate}
                  onChange={() => handleChange("expDate")}
                  disabled={!isEdit}
                  style={{ width: "16px", height: "16px", accentColor: "#1a6fdb", cursor: "pointer", flexShrink: 0 }}
                />
                <label htmlFor="expDate" style={{ margin: 0, fontSize: "13.5px", color: "#333", cursor: "pointer", width: "160px" }}>
                  Exp Date
                </label>
                <DateSelect
                  value={itemSettings.expDateFormat}
                  onChange={(e) => handleSelectChange("expDateFormat", e.target.value)}
                />
                <FieldInput placeholder="Exp. Date" />
              </div>

              {/* Mfg Date */}
              <div style={{ display: "flex", alignItems: "center", gap: "10px", marginBottom: "13px" }}>
                <input
                  type="checkbox"
                  id="mfgDate"
                  checked={itemSettings.mfgDate}
                  onChange={() => handleChange("mfgDate")}
                  disabled={!isEdit}
                  style={{ width: "16px", height: "16px", accentColor: "#1a6fdb", cursor: "pointer", flexShrink: 0 }}
                />
                <label htmlFor="mfgDate" style={{ margin: 0, fontSize: "13.5px", color: "#333", cursor: "pointer", width: "160px" }}>
                  Mfg Date
                </label>
                <DateSelect
                  value={itemSettings.mfgDateFormat}
                  onChange={(e) => handleSelectChange("mfgDateFormat", e.target.value)}
                />
                <FieldInput placeholder="Mfg. Date" />
              </div>

              {/* Model No */}
              <div style={{ display: "flex", alignItems: "center", gap: "10px", marginBottom: "13px" }}>
                <input
                  type="checkbox"
                  id="modelNo"
                  checked={itemSettings.modelNo}
                  onChange={() => handleChange("modelNo")}
                  disabled={!isEdit}
                  style={{ width: "16px", height: "16px", accentColor: "#1a6fdb", cursor: "pointer", flexShrink: 0 }}
                />
                <label htmlFor="modelNo" style={{ margin: 0, fontSize: "13.5px", color: "#333", cursor: "pointer", width: "160px" }}>
                  Model No.
                </label>
                <FieldInput placeholder="Model No." />
              </div>

              {/* Size */}
              <div style={{ display: "flex", alignItems: "center", gap: "10px", marginBottom: "13px" }}>
                <input
                  type="checkbox"
                  id="size"
                  checked={itemSettings.size}
                  onChange={() => handleChange("size")}
                  disabled={!isEdit}
                  style={{ width: "16px", height: "16px", accentColor: "#1a6fdb", cursor: "pointer", flexShrink: 0 }}
                />
                <label htmlFor="size" style={{ margin: 0, fontSize: "13.5px", color: "#333", cursor: "pointer", width: "160px" }}>
                  Size
                </label>
                <FieldInput placeholder="Size" />
              </div>
            </div>
          </div>

          {/* Save / Edit Button */}
           {canCreate && (
          <div style={{ display: "flex", justifyContent: "flex-end", marginTop: "16px" }}>
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
      </div>
    </div>
  );
};

export default ItemSettings;