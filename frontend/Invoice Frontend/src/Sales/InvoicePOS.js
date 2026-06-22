import React, { useState, useRef, useEffect, useContext, useCallback } from "react";
import { useNavigate } from "react-router-dom";
import axios from "axios";
import "../assets/css/invoicestyle.css";
import { GlobalStateContext } from "../Context/GlobalStateProvider";
import baseUrl from "../api/utils";

const UNITS = ["NONE", "PCS", "KG", "LTR", "BOX", "MTR", "DZN", "SET", "STRP", "BTL"];

const getGstPct = (taxStr) => {
  if (!taxStr || taxStr === "Select") return 0;
  return parseFloat(taxStr.replace("GST ", "").replace("%", "")) || 0;
};

const calcTotal = (item) => {
  const qty      = parseFloat(item.qty) || 0;
  const price    = parseFloat(item.price) || 0;
  const discPct  = parseFloat(item.discount) || 0;
  const taxPct   = getGstPct(item.tax);
  const grossAmt = qty * price;
  const discAmt  = (grossAmt * discPct) / 100;
  const taxable  = grossAmt - discAmt;
  const taxAmt   = (taxable * taxPct) / 100;
  const cessAmt  = parseFloat(item.addCess) || 0;
  return taxable + taxAmt + cessAmt;
};

const defaultItem = () => ({
  id: Date.now() + Math.random(),
  code: "",
  modelNo: "", mfgDate: "", expDate: "", mrp: "", size: "", addCess: "",
  name: "", hsncode: "", qty: 1, unit: "NONE",
  price: 0, discount: 0, tax: "Select", total: 0,
});

const defaultBill = (id, invoiceNumber) => ({
  id,
  label: `POS #${id}`,
  items: [defaultItem()],
  customerName: "",
  customerPhone: "",
  customerState: "",
  paymentMode: "Cash",
  amountReceived: 0,
  billDate: new Date().toISOString().split("T")[0],
  selectedItemIndex: null,
  billDiscount: 0,
  additionalCharges: 0,
  remarks: "",
  loyaltyPoints: "",
  invoiceNumber: invoiceNumber,
  invoicePrefix: "INV",
  received: false,
});

const InvoicePOS = () => {
  const navigate = useNavigate();
  const invoiceRef = useRef();
  const tabCounter = useRef(2);
  const invoiceCounter = useRef(1);
  const { gstSettings, itemSettings } = useContext(GlobalStateContext);
  const token = sessionStorage.getItem("token");

  const [bills, setBills] = useState([]);
  const [activeTabId, setActiveTabId] = useState(1);
  const [modal, setModal] = useState({ type: null, value: "", rowIndex: null });
  const [myCompany, setMyCompany] = useState(null);
  const [saving, setSaving] = useState(false);

  // ── item search ──
  const [itemSearchResults, setItemSearchResults] = useState([]);
  const [activeItemSearchIndex, setActiveItemSearchIndex] = useState(null);

  // ── customer search ──
  const [customerSearchResults, setCustomerSearchResults] = useState([]);
  const [showCustomerDropdown, setShowCustomerDropdown] = useState(false);

  // ═══════════════════════════════════════════════
  // FETCH NEXT INVOICE NUMBER ON LOAD
  // ═══════════════════════════════════════════════
  useEffect(() => {
    const fetchNextInvoiceNumber = async () => {
      try {
        const res = await axios.get(`${baseUrl}/getNextInvoiceNumber`, {
          headers: { Authorization: token },
        });
        const nextNo = res.data;
        invoiceCounter.current = nextNo;
        setBills([defaultBill(1, nextNo)]);
      } catch (err) {
        console.error("Failed to fetch invoice number", err);
        setBills([defaultBill(1, 1)]);
      }
    };
    fetchNextInvoiceNumber();
  }, []);

  // ── fetch company ──
  useEffect(() => {
    const fetchCompany = async () => {
      try {
        const res = await axios.get(`${baseUrl}/admin/getMyCompany`, {
          headers: { Authorization: token },
        });
        if (res.status === 200 && res.data) setMyCompany(res.data);
      } catch (err) {
        console.error("Failed to fetch company", err);
      }
    };
    fetchCompany();
  }, []);

  // ═══════════════════════════════════════════════
  // BILL HELPERS
  // ═══════════════════════════════════════════════
  const getActiveBill = () => bills.find((b) => b.id === activeTabId) || bills[0];

  const updateActiveBill = (updater) => {
    setBills((prev) =>
      prev.map((b) => (b.id === activeTabId ? { ...b, ...updater(b) } : b))
    );
  };

  const handleItemChange = (index, field, value) => {
    updateActiveBill((b) => {
      const updated = b.items.map((item, i) => {
        if (i !== index) return item;
        const newItem = { ...item, [field]: value };
        newItem.total = calcTotal(newItem);
        return newItem;
      });
      return { items: updated };
    });
  };

  const handleItemMultiChange = (index, fields) => {
    updateActiveBill((b) => {
      const updated = b.items.map((item, i) => {
        if (i !== index) return item;
        const newItem = { ...item, ...fields };
        newItem.total = calcTotal(newItem);
        return newItem;
      });
      return { items: updated };
    });
  };

  const addRow = () => updateActiveBill((b) => ({ items: [...b.items, defaultItem()] }));

  const removeRow = (index) => {
    updateActiveBill((b) => {
      if (b.items.length === 1) return {};
      return { items: b.items.filter((_, i) => i !== index), selectedItemIndex: null };
    });
  };

  const addNewBillTab = () => {
    const newId = tabCounter.current++;
    invoiceCounter.current = invoiceCounter.current + 1;
    setBills((prev) => [...prev, defaultBill(newId, invoiceCounter.current)]);
    setActiveTabId(newId);
  };

  const closeTab = (id) => {
    setBills((prev) => {
      const remaining = prev.filter((b) => b.id !== id);
      if (remaining.length === 0) return prev;
      if (activeTabId === id) setActiveTabId(remaining[remaining.length - 1].id);
      return remaining;
    });
  };

  // ═══════════════════════════════════════════════
  // CUSTOMER SEARCH
  // ═══════════════════════════════════════════════
  const searchCustomer = useCallback(async (keyword) => {
    if (!keyword || keyword.length < 2) {
      setCustomerSearchResults([]);
      setShowCustomerDropdown(false);
      return;
    }
    try {
      const res = await axios.get(`${baseUrl}/searchCustomer`, {
        headers: { Authorization: token },
        params: { keyword },
      });
      setCustomerSearchResults(res.data);
      setShowCustomerDropdown(true);
    } catch (err) {
      console.error("Customer search failed", err);
    }
  }, [token]);

  const customerSearchTimer = useRef(null);
  const handleCustomerInput = (value) => {
    updateActiveBill(() => ({ customerName: value }));
    clearTimeout(customerSearchTimer.current);
    customerSearchTimer.current = setTimeout(() => searchCustomer(value), 300);
  };

  const selectCustomer = (customer) => {
    updateActiveBill(() => ({
      customerName: customer.name,
      customerPhone: customer.phone || "",
      customerState: customer.state || "",
    }));
    setCustomerSearchResults([]);
    setShowCustomerDropdown(false);
  };

  // ═══════════════════════════════════════════════
  // ITEM SEARCH
  // ═══════════════════════════════════════════════
  const searchItem = useCallback(async (keyword, rowIndex) => {
    if (!keyword || keyword.length < 2) {
      setItemSearchResults([]);
      setActiveItemSearchIndex(null);
      return;
    }
    try {
      const res = await axios.get(`${baseUrl}/searchItem`, {
        headers: { Authorization: token },
        params: { keyword },
      });
      setItemSearchResults(res.data);
      setActiveItemSearchIndex(rowIndex);
    } catch (err) {
      console.error("Item search failed", err);
    }
  }, [token]);

  const itemSearchTimer = useRef(null);
  const handleItemNameInput = (index, value) => {
    handleItemChange(index, "name", value);
    clearTimeout(itemSearchTimer.current);
    itemSearchTimer.current = setTimeout(() => searchItem(value, index), 300);
  };

  const selectItem = (rowIndex, selectedItem) => {
    let priceToUse = 0;
    let taxString  = "Select";
    const taxPct   = selectedItem.taxRate || 0;

    if (selectedItem.mrp) {
      priceToUse = selectedItem.mrp;
      taxString  = "Select";
    } else {
      priceToUse = selectedItem.salePrice || 0;
      taxString  = taxPct > 0 ? `GST ${taxPct}%` : "Select";
      if (selectedItem.salePriceTaxType === "with_tax" && taxPct > 0) {
        priceToUse = priceToUse / (1 + taxPct / 100);
        priceToUse = Math.round(priceToUse * 100) / 100;
      }
    }

    handleItemMultiChange(rowIndex, {
      name:     selectedItem.itemName,
      code:     selectedItem.itemCode || "",
      hsncode:  selectedItem.itemHsn || "",
      unit:     selectedItem.unit || "NONE",
      price:    priceToUse,
      tax:      taxString,
      qty:      1,
      mrp:      selectedItem.mrp ? String(selectedItem.mrp) : "",
      addCess:  selectedItem.additionalCessPerUnit ? String(selectedItem.additionalCessPerUnit) : "",
      discount: selectedItem.discountOnSale ? String(selectedItem.discountOnSale) : "0",
    });

    setItemSearchResults([]);
    setActiveItemSearchIndex(null);
  };

  // ═══════════════════════════════════════════════
  // SAVE BILL
  // ═══════════════════════════════════════════════
  const handleSave = async (andPrint = false) => {
    const bill = getActiveBill();
    const filledItems = bill.items.filter((i) => i.name && i.name.trim() !== "");
    if (filledItems.length === 0) {
      alert("Please add at least one item.");
      return;
    }

    setSaving(true);
    try {
      const rows = filledItems.map((item, index) => {
        const taxPct = getGstPct(item.tax);
        return {
          lineNumber:      index + 1,
          itemName:        item.name,
          itemCode:        item.code || "",
          modelNo:         item.modelNo || null,
          mfgDate:         item.mfgDate || null,
          expDate:         item.expDate || null,
          mrp:             item.mrp ? parseFloat(item.mrp) : null,
          size:            item.size || null,
          addCess:         item.addCess ? parseFloat(item.addCess) : null,
          hsnCode:         item.hsncode || null,
          qty:             parseFloat(item.qty) || 0,
          unit:            item.unit,
          priceWithoutTax: parseFloat(item.price) || 0,
          discountPct:     parseFloat(item.discount) || 0,
          taxLabel:        item.tax !== "Select" ? item.tax : null,
          taxPct:          taxPct,
        };
      });

      const totalAmt   = filledItems.reduce((s, i) => s + (calcTotal(i) || 0), 0);
      const receivedAmt = parseFloat(bill.amountReceived) || 0;

      const payload = {
        billType:        "POS",
        invoiceNumber:   parseInt(bill.invoiceNumber),
        invoicePrefix:   bill.invoicePrefix,
        invoiceDate:     bill.billDate,
        partyName:       bill.customerName || "Walk-in Customer",
        phoneNo:         bill.customerPhone,
        stateOfSupply:   bill.customerState,
        isCash:          bill.paymentMode === "Cash",
        paymentMode:     bill.paymentMode,
        roundOffEnabled: false,
        received:        true,
        amountReceived:  receivedAmt > 0 ? receivedAmt : totalAmt,
        description:     bill.remarks,
        termsConditions: "",
        items:           rows,
        payments: [{
          paymentType: bill.paymentMode,
          amount: receivedAmt > 0 ? receivedAmt : totalAmt,
        }],
      };

      await axios.post(`${baseUrl}/saveBill`, payload, {
        headers: { Authorization: token },
      });

      if (andPrint) handlePrint();

      // reset tab with new invoice number
      invoiceCounter.current = invoiceCounter.current + 1;
      setBills((prev) =>
        prev.map((b) =>
          b.id === activeTabId
            ? { ...defaultBill(b.id, invoiceCounter.current), label: b.label }
            : b
        )
      );
      alert("Bill saved successfully!");
    } catch (err) {
      console.error("Save failed", err);
      alert("Failed to save bill. Please try again.");
    } finally {
      setSaving(false);
    }
  };

  // ═══════════════════════════════════════════════
  // MODAL
  // ═══════════════════════════════════════════════
  const openModal = (type) => {
    const bill = getActiveBill();
    const idx  = bill.selectedItemIndex !== null ? bill.selectedItemIndex : 0;
    const item = bill.items[idx];
    let val = "";
    if (type === "changeQty")         val = item?.qty ?? 1;
    if (type === "itemDiscount")      val = item?.discount ?? 0;
    if (type === "changeUnit")        val = item?.unit ?? "NONE";
    if (type === "additionalCharges") val = bill.additionalCharges || 0;
    if (type === "billDiscount")      val = bill.billDiscount || 0;
    if (type === "loyaltyPoints")     val = bill.loyaltyPoints || "";
    if (type === "remarks")           val = bill.remarks || "";
    setModal({ type, value: val, rowIndex: idx });
  };

  const applyModal = () => {
    const { type, value, rowIndex } = modal;
    if (type === "changeQty")         handleItemChange(rowIndex, "qty", parseFloat(value) || 1);
    else if (type === "itemDiscount") handleItemChange(rowIndex, "discount", parseFloat(value) || 0);
    else if (type === "changeUnit")   handleItemChange(rowIndex, "unit", value);
    else if (type === "removeItem")   removeRow(rowIndex);
    else if (type === "billDiscount") updateActiveBill(() => ({ billDiscount: parseFloat(value) || 0 }));
    else if (type === "additionalCharges") updateActiveBill(() => ({ additionalCharges: parseFloat(value) || 0 }));
    else if (type === "remarks")      updateActiveBill(() => ({ remarks: value }));
    else if (type === "loyaltyPoints") updateActiveBill(() => ({ loyaltyPoints: value }));
    setModal({ type: null, value: "", rowIndex: null });
  };

  // ── keyboard shortcuts ──
  useEffect(() => {
    const handleKeyDown = (e) => {
      const tag = document.activeElement.tagName;
      if (tag === "INPUT" || tag === "TEXTAREA" || tag === "SELECT") return;
      switch (e.key) {
        case "F2": e.preventDefault(); openModal("changeQty"); break;
        case "F3": e.preventDefault(); openModal("itemDiscount"); break;
        case "F4": e.preventDefault(); openModal("removeItem"); break;
        case "F6": e.preventDefault(); openModal("changeUnit"); break;
        default: break;
      }
    };
    window.addEventListener("keydown", handleKeyDown);
    return () => window.removeEventListener("keydown", handleKeyDown);
  }, [bills, activeTabId]);

  const handlePrint = () => {
    const bill = getActiveBill();
    const printContent = invoiceRef.current.innerHTML;
    const win = window.open("", "_blank");
    win.document.write(`<html><head><title>Invoice</title>
      <style>
        body { font-family: Arial, sans-serif; font-size: 12px; margin: 20px; }
        table { width: 100%; border-collapse: collapse; }
        th, td { border: 1px solid #ccc; padding: 4px 8px; }
        th { background: #f0f0f0; }
      </style></head><body>${printContent}</body></html>`);
    win.document.close();
    win.print();
  };

  const bill = getActiveBill();
  if (!bill) return <div>Loading...</div>;

  const filledItems  = bill.items.filter((i) => i.name);
  const subTotal     = bill.items.reduce((s, i) => s + (calcTotal(i) || 0), 0);
  const grandTotal   = subTotal + (bill.additionalCharges || 0) - (bill.billDiscount || 0);
  const totalItems   = filledItems.length;
  const totalQty     = bill.items.reduce((s, i) => s + (parseFloat(i.qty) || 0), 0);
  const changeDue    = Math.max(0, (parseFloat(bill.amountReceived) || 0) - grandTotal);

  const actionButtons = [
    { label: "Change Quantity [F2]", icon: "fa-pen",           type: "changeQty" },
    { label: "Item Discount [F3]",   icon: "fa-tag",           type: "itemDiscount" },
    { label: "Remove Item [F4]",     icon: "fa-trash",         type: "removeItem" },
    { label: "Change Unit [F6]",     icon: "fa-arrows-rotate", type: "changeUnit" },
  ];

  const dropdownStyle = {
    position: "absolute", top: "100%", left: 0, right: 0,
    background: "#fff", border: "1px solid #ddd",
    borderRadius: "4px", zIndex: 1000, maxHeight: "200px",
    overflowY: "auto", boxShadow: "0 4px 12px rgba(0,0,0,0.1)",
  };
  const dropdownItemStyle = {
    padding: "8px 12px", fontSize: "13px", cursor: "pointer",
    borderBottom: "1px solid #f5f5f5",
  };

  return (
    <div onClick={() => {
      setItemSearchResults([]);
      setActiveItemSearchIndex(null);
      setShowCustomerDropdown(false);
    }}>
      <div className="invoice-card-wrapper" style={{ marginTop: "-158px" }}>
        <div>
          <div className="card invoice-card">
            <div className="card-body p-0" style={{ display: "flex", flexDirection: "column", height: "calc(100vh - 160px)", minHeight: "600px" }}>

              {/* ══ TABS ══ */}
              <div style={{ display: "flex", alignItems: "center", borderBottom: "1px solid #e0e0e0", background: "#f8f9fa", padding: "0 12px", minHeight: "42px", gap: "4px", flexShrink: 0 }}>
                {bills.map((tab) => (
                  <div key={tab.id} onClick={() => setActiveTabId(tab.id)}
                    style={{
                      display: "flex", alignItems: "center", gap: "8px", padding: "8px 16px",
                      background: activeTabId === tab.id ? "#fff" : "transparent",
                      borderTop: activeTabId === tab.id ? "2px solid #2f80ed" : "2px solid transparent",
                      borderLeft: activeTabId === tab.id ? "1px solid #e0e0e0" : "none",
                      borderRight: activeTabId === tab.id ? "1px solid #e0e0e0" : "none",
                      borderBottom: activeTabId === tab.id ? "1px solid #fff" : "none",
                      cursor: "pointer", fontSize: "13px",
                      fontWeight: activeTabId === tab.id ? "600" : "400",
                      color: activeTabId === tab.id ? "#2f80ed" : "#555",
                      marginBottom: activeTabId === tab.id ? "-1px" : "0",
                      borderRadius: "4px 4px 0 0",
                    }}>
                    {tab.label}
                    <i className="fa-solid fa-xmark" style={{ fontSize: "10px", color: "#aaa", marginLeft: "2px" }}
                      onClick={(e) => { e.stopPropagation(); closeTab(tab.id); }} />
                  </div>
                ))}
                <button onClick={addNewBillTab}
                  style={{ background: "#e8f4fd", border: "1px solid #b3d4f5", borderRadius: "6px", padding: "4px 14px", fontSize: "12px", fontWeight: "600", color: "#2f80ed", cursor: "pointer", display: "flex", alignItems: "center", gap: "5px", marginLeft: "4px" }}>
                  <i className="fa-solid fa-plus" style={{ fontSize: "10px" }} /> New Bill
                </button>
                <div style={{ flex: 1 }} />
                <button className="btn btn-sm btn-light" style={{ borderRadius: "6px", marginRight: "4px" }}>
                  <i className="fa-solid fa-gear" style={{ color: "#555", fontSize: "13px" }} />
                </button>
              </div>

              {/* ══ BODY ══ */}
              <div style={{ display: "flex", flex: 1, overflow: "hidden" }}>

                {/* ── LEFT PANEL ── */}
                <div style={{ flex: 1, display: "flex", flexDirection: "column", overflow: "hidden", borderRight: "1px solid #e0e0e0", minWidth: 0 }}>

                  {/* Item Search */}
                  <div style={{ padding: "10px 12px", borderBottom: "1px solid #e8e8e8", flexShrink: 0 }}>
                    <div style={{ position: "relative" }}>
                      <i className="fa-solid fa-magnifying-glass" style={{ position: "absolute", left: "12px", top: "50%", transform: "translateY(-50%)", color: "#aaa", fontSize: "14px" }} />
                      <input
                        type="text"
                        placeholder="Scan or search by item code, model no or item name"
                        onChange={(e) => {
                          const bill = getActiveBill();
                          const idx  = bill.selectedItemIndex ?? (bill.items.length - 1);
                          handleItemNameInput(idx, e.target.value);
                        }}
                        onClick={(e) => e.stopPropagation()}
                        style={{ width: "100%", padding: "9px 40px 9px 36px", border: "2px solid #2f80ed", borderRadius: "6px", fontSize: "13px", outline: "none", background: "#fff", boxSizing: "border-box" }}
                      />
                      {/* item dropdown from top search bar */}
                      {activeItemSearchIndex !== null && itemSearchResults.length > 0 && (
                        <div style={{ ...dropdownStyle, minWidth: "320px" }} onClick={(e) => e.stopPropagation()}>
                          {itemSearchResults.map((si) => (
                            <div key={si.itemId} style={dropdownItemStyle}
                              onMouseEnter={(e) => e.currentTarget.style.background = "#f0f7ff"}
                              onMouseLeave={(e) => e.currentTarget.style.background = "#fff"}
                              onClick={() => selectItem(activeItemSearchIndex, si)}>
                              <div style={{ fontWeight: "600", fontSize: "13px" }}>{si.itemName}</div>
                              <div style={{ fontSize: "11px", color: "#888" }}>
                                {si.itemCode && `Code: ${si.itemCode}`}
                                {si.taxRate > 0 && ` | GST: ${si.taxRate}%`}
                                {si.salePrice && ` | Price: ₹${si.salePrice}`}
                              </div>
                            </div>
                          ))}
                        </div>
                      )}
                    </div>
                  </div>

                  {/* Table */}
                  <div style={{ flex: 1, overflowY: "auto", overflowX: "auto", minHeight: 0 }}>
                    <table className="table table-hover table-bordered table-sm invoice-table"
                      style={{ width: "1800px", borderCollapse: "collapse", fontSize: "12px", tableLayout: "fixed" }}>
                      <thead style={{ position: "sticky", top: 0, zIndex: 1 }}>
                        <tr style={{ background: "#f0f2f5", borderBottom: "2px solid #e0e0e0" }}>
                          <th style={{ ...thStyle, width: "40px" }}>#</th>
                          <th style={{ ...thStyle, width: "80px" }}>ITEM CODE</th>
                          <th style={{ ...thStyle, width: "160px", textAlign: "center" }}>ITEM NAME</th>
                          {itemSettings.modelNo && <th style={{ ...thStyle, width: "100px" }}>MODEL NO</th>}
                          {itemSettings.mfgDate && <th style={{ ...thStyle, width: "120px" }}>MFG DATE</th>}
                          {itemSettings.expDate && <th style={{ ...thStyle, width: "120px" }}>EXP DATE</th>}
                          {itemSettings.mrp     && <th style={{ ...thStyle, width: "70px" }}>MRP</th>}
                          {itemSettings.size    && <th style={{ ...thStyle, width: "70px" }}>SIZE</th>}
                          {gstSettings.additionalCess && <th style={{ ...thStyle, width: "80px" }}>ADD CESS</th>}
                          {gstSettings.enableHSN      && <th style={{ ...thStyle, width: "80px" }}>HSN/SAC</th>}
                          <th style={{ ...thStyle, width: "60px" }}>QTY</th>
                          <th style={{ ...thStyle, width: "70px" }}>UNIT</th>
                          <th style={{ ...thStyle, width: "100px" }}>PRICE/UNIT(₹)<br /><span style={{ fontWeight: "400", color: "#888", fontSize: "10px" }}>Without Tax</span></th>
                          <th style={{ ...thStyle, width: "80px" }}>DISCOUNT<br /><span style={{ fontWeight: "400", color: "#888", fontSize: "10px" }}>(%)</span></th>
                          {gstSettings.enableGST && <th style={{ ...thStyle, width: "80px" }}>TAX (GST)<br /><span style={{ fontWeight: "400", color: "#888", fontSize: "10px" }}>(₹)</span></th>}
                          <th style={{ ...thStyle, width: "90px" }}>TOTAL(₹)</th>
                          <th style={{ ...thStyle, width: "36px" }}></th>
                        </tr>
                      </thead>
                      <tbody>
                        {bill.items.map((item, index) => (
                          <tr key={item.id}
                            onClick={() => updateActiveBill(() => ({ selectedItemIndex: index }))}
                            style={{
                              borderBottom: "1px solid #f0f0f0",
                              background: bill.selectedItemIndex === index ? "#eaf3ff" : index % 2 === 0 ? "#fff" : "#fafafa",
                              cursor: "pointer",
                            }}>
                            <td style={tdStyle}>{index + 1}</td>
                            <td style={tdStyle}>
                              <input type="text" value={item.code}
                                onChange={(e) => handleItemChange(index, "code", e.target.value)}
                                style={inlineInput} placeholder="Code" onClick={(e) => e.stopPropagation()} />
                            </td>
                            {/* ITEM NAME with inline search dropdown */}
                            <td style={{ ...tdStyle, textAlign: "left", position: "relative" }} onClick={(e) => e.stopPropagation()}>
                              <input type="text" value={item.name}
                                onChange={(e) => handleItemNameInput(index, e.target.value)}
                                style={{ ...inlineInput, width: "100%", minWidth: "140px" }}
                                placeholder="Item name" />
                              {activeItemSearchIndex === index && itemSearchResults.length > 0 && (
                                <div style={{ ...dropdownStyle, minWidth: "280px" }}>
                                  {itemSearchResults.map((si) => (
                                    <div key={si.itemId} style={dropdownItemStyle}
                                      onMouseEnter={(e) => e.currentTarget.style.background = "#f0f7ff"}
                                      onMouseLeave={(e) => e.currentTarget.style.background = "#fff"}
                                      onClick={() => selectItem(index, si)}>
                                      <div style={{ fontWeight: "600", fontSize: "13px" }}>{si.itemName}</div>
                                      <div style={{ fontSize: "11px", color: "#888" }}>
                                        {si.itemCode && `Code: ${si.itemCode}`}
                                        {si.taxRate > 0 && ` | GST: ${si.taxRate}%`}
                                        {si.salePrice && ` | Price: ₹${si.salePrice}`}
                                      </div>
                                    </div>
                                  ))}
                                </div>
                              )}
                            </td>
                            {itemSettings.modelNo && (
                              <td style={tdStyle}>
                                <input type="text" value={item.modelNo} onChange={(e) => handleItemChange(index, "modelNo", e.target.value)} style={{ ...inlineInput, width: "80px" }} placeholder="Model" onClick={(e) => e.stopPropagation()} />
                              </td>
                            )}
                            {itemSettings.mfgDate && (
                              <td style={tdStyle}>
                                <input type="date" value={item.mfgDate} onChange={(e) => handleItemChange(index, "mfgDate", e.target.value)} style={{ ...inlineInput, width: "110px", fontSize: "11px" }} onClick={(e) => e.stopPropagation()} />
                              </td>
                            )}
                            {itemSettings.expDate && (
                              <td style={tdStyle}>
                                <input type="date" value={item.expDate} onChange={(e) => handleItemChange(index, "expDate", e.target.value)} style={{ ...inlineInput, width: "110px", fontSize: "11px" }} onClick={(e) => e.stopPropagation()} />
                              </td>
                            )}
                            {itemSettings.mrp && (
                              <td style={tdStyle}>
                                <input type="number" value={item.mrp} onChange={(e) => handleItemChange(index, "mrp", e.target.value)} style={{ ...inlineInput, width: "60px" }} placeholder="0" onClick={(e) => e.stopPropagation()} />
                              </td>
                            )}
                            {itemSettings.size && (
                              <td style={tdStyle}>
                                <input type="text" value={item.size} onChange={(e) => handleItemChange(index, "size", e.target.value)} style={{ ...inlineInput, width: "55px" }} placeholder="Size" onClick={(e) => e.stopPropagation()} />
                              </td>
                            )}
                            {gstSettings.additionalCess && (
                              <td style={tdStyle}>
                                <input type="text" value={item.addCess} onChange={(e) => handleItemChange(index, "addCess", e.target.value)} style={{ ...inlineInput, width: "60px" }} placeholder="0" onClick={(e) => e.stopPropagation()} />
                              </td>
                            )}
                            {gstSettings.enableHSN && (
                              <td style={tdStyle}>
                                <input type="text" value={item.hsncode} onChange={(e) => handleItemChange(index, "hsncode", e.target.value)} style={{ ...inlineInput, width: "60px" }} placeholder="HSN" onClick={(e) => e.stopPropagation()} />
                              </td>
                            )}
                            <td style={tdStyle}>
                              <input type="number" value={item.qty} onChange={(e) => handleItemChange(index, "qty", e.target.value)} style={{ ...inlineInput, width: "52px" }} onClick={(e) => e.stopPropagation()}   max={Math.pow(10, itemSettings.quantityDecimalPlaces) - 1}
                              onInput={(e) => {
                                if (e.target.value.length > itemSettings.quantityDecimalPlaces) {
                                  e.target.value = e.target.value.slice(
                                    0,
                                    itemSettings.quantityDecimalPlaces
                                  );
                                }
                              }} />
                            </td>
                            <td style={tdStyle}>
                              <select value={item.unit} onChange={(e) => handleItemChange(index, "unit", e.target.value)} style={{ ...inlineInput, width: "64px", padding: "2px" }} onClick={(e) => e.stopPropagation()}>
                                {UNITS.map((u) => <option key={u}>{u}</option>)}
                              </select>
                            </td>
                            <td style={tdStyle}>
                              <input type="number" value={item.price} onChange={(e) => handleItemChange(index, "price", e.target.value)} style={{ ...inlineInput, width: "70px" }} onClick={(e) => e.stopPropagation()} />
                            </td>
                            <td style={tdStyle}>
                              <input type="number" value={item.discount} onChange={(e) => handleItemChange(index, "discount", e.target.value)} style={{ ...inlineInput, width: "55px" }} onClick={(e) => e.stopPropagation()} />
                            </td>
                            {gstSettings.enableGST && (
                              <td style={tdStyle}>
                                <select value={item.tax} onChange={(e) => handleItemChange(index, "tax", e.target.value)}
                                  style={{ ...inlineInput, width: "70px", padding: "2px", fontSize: "11px" }} onClick={(e) => e.stopPropagation()}>
                                  {["Select", "GST 0%", "GST 5%", "GST 12%", "GST 18%", "GST 28%"].map((t) => <option key={t}>{t}</option>)}
                                </select>
                              </td>
                            )}
                            <td style={{ ...tdStyle, fontWeight: "600", color: "#222" }}>
                              {calcTotal(item) > 0 ? calcTotal(item).toFixed(2) : "0.00"}
                            </td>
                            <td style={tdStyle}>
                              <i className="fa-solid fa-trash-can" style={{ color: "#e74c3c", cursor: "pointer", fontSize: "12px" }}
                                onClick={(e) => { e.stopPropagation(); removeRow(index); }} />
                            </td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>

                  {/* Add Row */}
                  <div style={{ padding: "6px 12px", borderTop: "1px solid #f0f0f0", flexShrink: 0, background: "#fff" }}>
                    <button onClick={addRow} style={{ background: "none", border: "none", color: "#2f80ed", fontWeight: "600", fontSize: "13px", cursor: "pointer", padding: "2px 0" }}>
                      <i className="fa-solid fa-plus mr-1" /> Add Row
                    </button>
                    {(bill.billDiscount > 0 || bill.additionalCharges > 0) && (
                      <span style={{ fontSize: "12px", color: "#888", marginLeft: "16px" }}>
                        {bill.additionalCharges > 0 && <span>+Charges: ₹{bill.additionalCharges} &nbsp;</span>}
                        {bill.billDiscount > 0 && <span>-Bill Disc: {bill.billDiscount}% &nbsp;</span>}
                        <strong style={{ color: "#222" }}>Grand Total: ₹{grandTotal.toFixed(2)}</strong>
                      </span>
                    )}
                    {bill.remarks && <span style={{ fontSize: "12px", color: "#888", marginLeft: "16px" }}>💬 {bill.remarks}</span>}
                  </div>

                  {/* Action Buttons */}
                  <div style={{ borderTop: "1px solid #e0e0e0", background: "#f8f9fa", padding: "8px 12px", flexShrink: 0 }}>
                    <div style={{ display: "flex", flexWrap: "wrap", gap: "6px" }}>
                      {actionButtons.map((btn) => (
                        <button key={btn.type} onClick={() => openModal(btn.type)}
                          style={{ flex: "1 1 calc(25% - 6px)", padding: "7px 4px", background: "#e8f0fe", border: "1px solid #c5d5f5", borderRadius: "6px", fontSize: "12px", fontWeight: "500", color: "#2f80ed", cursor: "pointer", textAlign: "center", minWidth: "130px" }}>
                          <i className={`fa-solid ${btn.icon} mr-1`} /> {btn.label}
                        </button>
                      ))}
                    </div>
                  </div>
                </div>

                {/* ── RIGHT PANEL ── */}
                <div style={{ width: "340px", flexShrink: 0, display: "flex", flexDirection: "column", background: "#fff" }}>

                  {/* Bill Date */}
                  <div style={{ padding: "12px 14px", borderBottom: "1px solid #f0f0f0" }}>
                    <div style={{ position: "relative" }}>
                      <input type="date" value={bill.billDate}
                        onChange={(e) => updateActiveBill(() => ({ billDate: e.target.value }))}
                        style={{ width: "100%", padding: "8px 36px 8px 12px", border: "1px solid #ddd", borderRadius: "6px", fontSize: "13px", outline: "none", boxSizing: "border-box" }} />
                      <i className="fa-regular fa-calendar" style={{ position: "absolute", right: "10px", top: "50%", transform: "translateY(-50%)", color: "#2f80ed", fontSize: "15px", pointerEvents: "none" }} />
                    </div>
                  </div>

                  {/* Customer Search */}
                  <div style={{ padding: "10px 14px", borderBottom: "1px solid #f0f0f0", position: "relative" }} onClick={(e) => e.stopPropagation()}>
                    <div style={{ position: "relative" }}>
                      <input type="text" value={bill.customerName}
                        onChange={(e) => handleCustomerInput(e.target.value)}
                        placeholder="Search customer by name, phone [F11]"
                        style={{ width: "100%", padding: "8px 36px 8px 12px", border: "1px solid #ddd", borderRadius: "6px", fontSize: "12px", outline: "none", boxSizing: "border-box" }} />
                      <i className="fa-solid fa-magnifying-glass" style={{ position: "absolute", right: "10px", top: "50%", transform: "translateY(-50%)", color: "#aaa", fontSize: "12px" }} />
                    </div>
                    {showCustomerDropdown && customerSearchResults.length > 0 && (
                      <div style={{ position: "absolute", top: "calc(100% - 10px)", left: "14px", right: "14px", background: "#fff", border: "1px solid #ddd", borderRadius: "4px", zIndex: 1000, maxHeight: "180px", overflowY: "auto", boxShadow: "0 4px 12px rgba(0,0,0,0.1)" }}>
                        {customerSearchResults.map((c) => (
                          <div key={c.id} style={{ padding: "8px 12px", fontSize: "13px", cursor: "pointer", borderBottom: "1px solid #f5f5f5" }}
                            onMouseEnter={(e) => e.currentTarget.style.background = "#f0f7ff"}
                            onMouseLeave={(e) => e.currentTarget.style.background = "#fff"}
                            onClick={() => selectCustomer(c)}>
                            <div style={{ fontWeight: "600" }}>{c.name}</div>
                            {c.phone && <div style={{ fontSize: "11px", color: "#888" }}>{c.phone}</div>}
                          </div>
                        ))}
                      </div>
                    )}
                  </div>

                  {/* Total Summary */}
                  <div style={{ padding: "14px", borderBottom: "1px solid #f0f0f0", background: "#f8fbff" }}>
                    <div style={{ display: "flex", alignItems: "center", gap: "10px" }}>
                      <div style={{ width: "38px", height: "38px", background: "#e8f0fe", borderRadius: "8px", display: "flex", alignItems: "center", justifyContent: "center" }}>
                        <i className="fa-solid fa-receipt" style={{ color: "#2f80ed", fontSize: "16px" }} />
                      </div>
                      <div style={{ flex: 1 }}>
                        <div style={{ fontSize: "20px", fontWeight: "700", color: "#1a1a1a" }}>Total ₹ {grandTotal.toFixed(2)}</div>
                        <div style={{ fontSize: "12px", color: "#888", marginTop: "2px" }}>Items: {totalItems}, &nbsp; Qty: {totalQty}</div>
                      </div>
                    </div>
                  </div>

                  {/* Payment Mode */}
                  <div style={{ padding: "12px 14px", borderBottom: "1px solid #f0f0f0" }}>
                    <div style={{ fontSize: "12px", color: "#555", fontWeight: "600", marginBottom: "8px" }}>Payment Mode</div>
                    <div style={{ position: "relative" }}>
                      <select value={bill.paymentMode}
                        onChange={(e) => updateActiveBill(() => ({ paymentMode: e.target.value }))}
                        style={{ width: "100%", padding: "8px 30px 8px 12px", border: "1px solid #ddd", borderRadius: "6px", fontSize: "13px", outline: "none", appearance: "none", background: "#fff" }}>
                        {["Cash", "Card", "UPI", "Net Banking", "Cheque"].map((m) => <option key={m}>{m}</option>)}
                      </select>
                      <i className="fa-solid fa-chevron-down" style={{ position: "absolute", right: "10px", top: "50%", transform: "translateY(-50%)", color: "#aaa", fontSize: "11px", pointerEvents: "none" }} />
                    </div>
                  </div>

                  {/* Amount Received */}
                  <div style={{ padding: "12px 14px", borderBottom: "1px solid #f0f0f0" }}>
                    <div style={{ fontSize: "12px", color: "#555", fontWeight: "600", marginBottom: "8px" }}>Amount Received</div>
                    <div style={{ position: "relative" }}>
                      <span style={{ position: "absolute", left: "12px", top: "50%", transform: "translateY(-50%)", color: "#555", fontSize: "13px" }}>₹</span>
                      <input type="number" value={bill.amountReceived}
                        onChange={(e) => updateActiveBill(() => ({ amountReceived: e.target.value }))}
                        style={{ width: "100%", padding: "8px 12px 8px 28px", border: "1px solid #ddd", borderRadius: "6px", fontSize: "13px", outline: "none", boxSizing: "border-box" }} />
                    </div>
                  </div>

                  <div style={{ flex: 1 }} />

                  {/* Change to Return */}
                  <div style={{ padding: "12px 14px", borderTop: "1px solid #f0f0f0", borderBottom: "1px solid #f0f0f0", display: "flex", justifyContent: "space-between", alignItems: "center" }}>
                    <span style={{ fontSize: "14px", fontWeight: "600", color: "#333" }}>Change to Return:</span>
                    <span style={{ fontSize: "18px", fontWeight: "700", color: changeDue > 0 ? "#27ae60" : "#333" }}>₹ {changeDue.toFixed(2)}</span>
                  </div>

                  {/* Save & Print */}
                  <div style={{ padding: "12px 14px" }}>
                    <button onClick={() => handleSave(true)} disabled={saving}
                      style={{ width: "100%", padding: "13px", background: saving ? "#aaa" : "linear-gradient(135deg, #27ae60, #2ecc71)", border: "none", borderRadius: "8px", fontSize: "15px", fontWeight: "700", color: "#fff", cursor: saving ? "not-allowed" : "pointer", boxShadow: "0 3px 10px rgba(39,174,96,0.3)", marginBottom: "8px" }}>
                      <i className="fa-solid fa-print mr-2" /> {saving ? "Saving..." : "Save & Print Bill [Ctrl+P]"}
                    </button>
                    <button onClick={() => handleSave(false)} disabled={saving}
                      style={{ width: "100%", padding: "10px", background: "#fff", border: "1px solid #ddd", borderRadius: "8px", fontSize: "13px", fontWeight: "600", color: "#555", cursor: saving ? "not-allowed" : "pointer" }}>
                      <i className="fa-solid fa-floppy-disk mr-2" /> Save Only
                    </button>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Hidden print area */}
      <div ref={invoiceRef} style={{ display: "none" }}>
        <div style={{ textAlign: "center", fontWeight: "700", fontSize: "14px", marginBottom: "8px" }}>Tax Invoice (POS)</div>
        <div><strong>{myCompany?.businessName || "—"}</strong> | {myCompany?.businessAddress || ""} | {myCompany?.phoneNumber || ""}</div>
        {myCompany?.gstin && <div>GSTIN: {myCompany.gstin}</div>}
        <div>Invoice No: {bill.invoicePrefix !== "NONE" ? `${bill.invoicePrefix}-` : ""}{bill.invoiceNumber} | Date: {bill.billDate}</div>
        <div>Customer: {bill.customerName || "Walk-in Customer"} {bill.customerPhone ? `| Ph: ${bill.customerPhone}` : ""}</div>
        <table style={{ width: "100%", borderCollapse: "collapse", marginTop: "8px" }}>
          <thead>
            <tr style={{ background: "#f0f0f0" }}>
              {["#", "Item", "HSN", "Qty", "Unit", "Price", "Disc%", "GST", "Total"].map((h) => (
                <th key={h} style={{ border: "1px solid #ccc", padding: "4px" }}>{h}</th>
              ))}
            </tr>
          </thead>
          <tbody>
            {bill.items.filter((i) => i.name).map((item, idx) => (
              <tr key={idx}>
                <td style={{ border: "1px solid #ccc", padding: "4px" }}>{idx + 1}</td>
                <td style={{ border: "1px solid #ccc", padding: "4px" }}>{item.name}</td>
                <td style={{ border: "1px solid #ccc", padding: "4px" }}>{item.hsncode || "—"}</td>
                <td style={{ border: "1px solid #ccc", padding: "4px" }}>{item.qty}</td>
                <td style={{ border: "1px solid #ccc", padding: "4px" }}>{item.unit}</td>
                <td style={{ border: "1px solid #ccc", padding: "4px" }}>₹{parseFloat(item.price || 0).toFixed(2)}</td>
                <td style={{ border: "1px solid #ccc", padding: "4px" }}>{item.discount}%</td>
                <td style={{ border: "1px solid #ccc", padding: "4px" }}>{item.tax !== "Select" ? item.tax : "—"}</td>
                <td style={{ border: "1px solid #ccc", padding: "4px" }}>₹{calcTotal(item).toFixed(2)}</td>
              </tr>
            ))}
            <tr style={{ fontWeight: "700" }}>
              <td colSpan={8} style={{ border: "1px solid #ccc", padding: "4px" }}>Grand Total</td>
              <td style={{ border: "1px solid #ccc", padding: "4px" }}>₹{grandTotal.toFixed(2)}</td>
            </tr>
          </tbody>
        </table>
        <div style={{ marginTop: "8px" }}>Received: ₹{bill.amountReceived} | Change: ₹{changeDue.toFixed(2)}</div>
        {bill.remarks && <div>Remarks: {bill.remarks}</div>}
      </div>

      {/* ══ ACTION MODAL ══ */}
      {modal.type && (
        <div style={{ position: "fixed", top: 0, left: 0, right: 0, bottom: 0, background: "rgba(0,0,0,0.45)", zIndex: 9999, display: "flex", alignItems: "center", justifyContent: "center" }}>
          <div style={{ background: "#fff", borderRadius: "12px", padding: "28px 24px", width: "360px", boxShadow: "0 8px 32px rgba(0,0,0,0.18)" }}>
            <h6 style={{ fontWeight: "700", marginBottom: "16px", color: "#222", fontSize: "15px" }}>
              {modal.type === "changeQty"    && `Change Quantity — Row ${(modal.rowIndex ?? 0) + 1}`}
              {modal.type === "itemDiscount" && `Item Discount (%) — Row ${(modal.rowIndex ?? 0) + 1}`}
              {modal.type === "removeItem"   && `Remove Item — Row ${(modal.rowIndex ?? 0) + 1}`}
              {modal.type === "changeUnit"   && `Change Unit — Row ${(modal.rowIndex ?? 0) + 1}`}
              {modal.type === "billDiscount" && "Bill Discount (%)"}
              {modal.type === "additionalCharges" && "Additional Charges (₹)"}
              {modal.type === "remarks"      && "Remarks"}
              {modal.type === "loyaltyPoints" && "Loyalty Points"}
            </h6>

            {modal.type === "removeItem" ? (
              <p style={{ color: "#555", fontSize: "14px", marginBottom: "20px" }}>
                Are you sure you want to remove row #{(modal.rowIndex ?? 0) + 1}?
              </p>
            ) : modal.type === "changeUnit" ? (
              <select value={modal.value}
                onChange={(e) => setModal({ ...modal, value: e.target.value })}
                style={{ width: "100%", padding: "9px 12px", border: "1px solid #ddd", borderRadius: "6px", fontSize: "14px", marginBottom: "16px", outline: "none" }}>
                {UNITS.map((u) => <option key={u}>{u}</option>)}
              </select>
            ) : modal.type === "remarks" || modal.type === "loyaltyPoints" ? (
              <textarea value={modal.value}
                onChange={(e) => setModal({ ...modal, value: e.target.value })}
                rows={3} autoFocus
                style={{ width: "100%", padding: "9px 12px", border: "1px solid #ddd", borderRadius: "6px", fontSize: "14px", marginBottom: "16px", outline: "none", resize: "vertical", boxSizing: "border-box" }}
                placeholder={modal.type === "remarks" ? "Enter remarks..." : "Enter loyalty points..."} />
            ) : (
              <input type="number" value={modal.value}
                onChange={(e) => setModal({ ...modal, value: e.target.value })}
                autoFocus
                style={{ width: "100%", padding: "9px 12px", border: "1px solid #ddd", borderRadius: "6px", fontSize: "14px", marginBottom: "16px", outline: "none", boxSizing: "border-box" }} />
            )}

            <div style={{ display: "flex", gap: "10px", justifyContent: "flex-end" }}>
              <button onClick={() => setModal({ type: null, value: "", rowIndex: null })}
                style={{ padding: "8px 22px", background: "#f0f0f0", border: "none", borderRadius: "6px", fontSize: "13px", fontWeight: "600", cursor: "pointer", color: "#555" }}>
                Cancel
              </button>
              <button onClick={applyModal}
                style={{ padding: "8px 22px", background: modal.type === "removeItem" ? "#e74c3c" : "#2f80ed", border: "none", borderRadius: "6px", fontSize: "13px", fontWeight: "600", cursor: "pointer", color: "#fff" }}>
                {modal.type === "removeItem" ? "Remove" : "Apply"}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

const thStyle = {
  padding: "8px 6px", textAlign: "center", fontSize: "11px", fontWeight: "600",
  color: "#555", whiteSpace: "nowrap", borderBottom: "2px solid #e0e0e0", borderRight: "1px solid #e8e8e8",
};
const tdStyle = {
  padding: "5px 4px", textAlign: "center", verticalAlign: "middle", borderRight: "1px solid #f0f0f0",
};
const inlineInput = {
  border: "1px solid transparent", borderRadius: "4px", padding: "3px 5px",
  fontSize: "12px", width: "60px", textAlign: "center", outline: "none",
  background: "transparent", transition: "border 0.15s",
};

export default InvoicePOS;