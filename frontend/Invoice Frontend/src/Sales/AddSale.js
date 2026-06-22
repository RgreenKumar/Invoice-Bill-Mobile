import React, { useState, useRef, useContext, useEffect, useCallback } from "react";
import { useNavigate , useParams, useLocation} from "react-router-dom";
import axios from "axios";
import "../assets/css/invoicestyle.css";
import { GlobalStateContext } from "../Context/GlobalStateProvider";
import baseUrl from "../api/utils";

//const UNITS = ["NONE", "PCS", "KG", "LTR", "BOX", "MTR", "DZN", "SET", "STRP", "BTL"];
const TAX_OPTIONS = ["Select", "GST 0%", "GST 5%", "GST 12%", "GST 18%", "GST 28%"];
const INVOICE_PREFIX_OPTIONS = ["NONE", "INV", "SALE", "SI"];

const STATES = [
  "01-Jammu & Kashmir","02-Himachal Pradesh","03-Punjab","04-Chandigarh",
  "05-Uttarakhand","06-Haryana","07-Delhi","08-Rajasthan","09-Uttar Pradesh",
  "10-Bihar","11-Sikkim","12-Arunachal Pradesh","13-Nagaland","14-Manipur",
  "15-Mizoram","16-Tripura","17-Meghalaya","18-Assam","19-West Bengal",
  "20-Jharkhand","21-Odisha","22-Chhattisgarh","23-Madhya Pradesh",
  "24-Gujarat","26-Dadra & Nagar Haveli","27-Maharashtra","28-Andhra Pradesh",
  "29-Karnataka","30-Goa","31-Lakshadweep","32-Kerala","33-Tamil Nadu",
  "34-Puducherry","35-Andaman & Nicobar","36-Telangana","37-Andhra Pradesh (New)",
];

const ones = ["","One","Two","Three","Four","Five","Six","Seven","Eight","Nine",
  "Ten","Eleven","Twelve","Thirteen","Fourteen","Fifteen","Sixteen","Seventeen","Eighteen","Nineteen"];
const tens = ["","","Twenty","Thirty","Forty","Fifty","Sixty","Seventy","Eighty","Ninety"];

function numToWords(n) {
  n = Math.round(n);
  if (n === 0) return "Zero";
  if (n < 0) return "Minus " + numToWords(-n);
  let words = "";
  if (n >= 10000000) { words += numToWords(Math.floor(n / 10000000)) + " Crore "; n %= 10000000; }
  if (n >= 100000)   { words += numToWords(Math.floor(n / 100000))   + " Lakh ";  n %= 100000;  }
  if (n >= 1000)     { words += numToWords(Math.floor(n / 1000))     + " Thousand "; n %= 1000; }
  if (n >= 100)      { words += numToWords(Math.floor(n / 100))      + " Hundred ";  n %= 100;  }
  if (n >= 20)       { words += tens[Math.floor(n / 10)] + " "; n %= 10; }
  if (n > 0)         { words += ones[n] + " "; }
  return words.trim();
}

function amountInWords(amount) {
  const rupees = Math.floor(amount);
  const paise  = Math.round((amount - rupees) * 100);
  let result = numToWords(rupees) + " Rupees";
  if (paise > 0) result += " and " + numToWords(paise) + " Paise";
  return result + " only";
}

const getGstPct = (taxStr) => {
  if (!taxStr || taxStr === "Select") return 0;
  return parseFloat(taxStr.replace("GST ", "").replace("%", "")) || 0;
};

// ── calcRow — unchanged, works perfectly ──
const calcRow = (item) => {
  const qty     = parseFloat(item.qty) || 0;
  const price   = parseFloat(item.priceWithoutTax) || 0;
  const discPct = parseFloat(item.discountPct) || 0;
  const taxPct  = getGstPct(item.tax);
  const grossAmt = qty * price;
  const discAmt = item._discAmtManual
    ? (parseFloat(item.discountAmt) || 0)
    : (grossAmt * discPct) / 100;
  const taxable = grossAmt - discAmt;
  const cgst    = (taxable * (taxPct / 2)) / 100;
  const sgst    = (taxable * (taxPct / 2)) / 100;
const cess    = parseFloat(item.addcess) || 0;
const cessAmt = cess;
const amount  = taxable + cgst + sgst + cessAmt;
return { grossAmt, discAmt, taxable, cgst, sgst, amount,  cessAmt };
};

const fmt = (n) => n ? Number(n).toLocaleString("en-IN", {
  minimumFractionDigits: 2, maximumFractionDigits: 2
}) : "";

const defaultItem = () => ({
  id: Date.now() + Math.random(),
  item: "",
  modelNo: "",
  mfgDate: "",
  expDate: "",
  mrp: "",
  size: "",
  addcess: "",
  hsn: "",
  qty: "1",
  unit: "NONE",
  priceWithoutTax: "",
  discountPct: "",
  discountAmt: "",
  _discAmtManual: false,
  tax: "Select",
});

// ── defaultBill — prefix INV, number from backend ──
const defaultBill = (id, invoiceNumber) => ({
  id,
  label: `Sale #${id}`,
  items: [defaultItem(), defaultItem()],
  partyName: "",
  phoneNo: "",
  isCash: true,
  invoicePrefix: "INV",         // ← default INV
  invoiceNumber: invoiceNumber, // ← from backend
  invoiceDate: new Date().toISOString().split("T")[0],
  stateOfSupply: "",
  description: "",
  termsConditions: "Thanks for doing business with us!",
  imageFile: null,
  imageDataUrl: null,
  roundOff: true,
  paymentTypes: [{ type: "Cash", amount: "" }],
  received: false,
  receivedAmount: "",
});

// ── mapBillToFormState — converts a /getBill/:id API response (flat fields
// like itemName, hsnCode, taxPct) into the shape this form's state expects
// (item, hsn, tax, etc — same shape as defaultBill/defaultItem) ──
const mapBillToFormState = (data) => {
  const items = (data.items || []).map((it, idx) => ({
    id: Date.now() + idx + Math.random(),
    item: it.itemName || "",
    modelNo: it.modelNo || "",
    mfgDate: it.mfgDate || "",
    expDate: it.expDate || "",
    mrp: it.mrp != null ? String(it.mrp) : "",
    size: it.size || "",
    addcess: it.addCess != null ? String(it.addCess) : "",
    hsn: it.hsnCode || "",
    qty: it.qty != null ? String(it.qty) : "1",
    unit: it.unit || "NONE",
    priceWithoutTax: it.priceWithoutTax != null ? String(it.priceWithoutTax) : "",
    discountPct: it.discountPct != null ? String(it.discountPct) : "",
    discountAmt: "",
    _discAmtManual: false,
    tax: it.taxLabel || (it.taxPct ? `GST ${it.taxPct}%` : "Select"),
  }));

  return {
    id: 1,
    label: `Sale #${data.invoiceNumber ?? ""}`,
    items: items.length ? items : [defaultItem(), defaultItem()],
    partyName: data.partyName || "",
    phoneNo: data.phoneNo || "",
    isCash: data.isCash ?? true,
    invoicePrefix: data.invoicePrefix || "NONE",
    invoiceNumber: data.invoiceNumber ?? "",
    invoiceDate: data.invoiceDate || "",
    stateOfSupply: data.stateOfSupply || "",
    description: data.description || "",
    termsConditions: data.termsConditions || "",
    imageFile: null,
    imageDataUrl: null,
    roundOff: data.roundOffEnabled ?? true,
    paymentTypes: data.payments?.length
      ? data.payments.map((p) => ({ type: p.paymentType, amount: String(p.amount ?? "") }))
      : [{ type: "Cash", amount: "" }],
    received: data.received ?? false,
    receivedAmount: data.amountReceived != null ? String(data.amountReceived) : "",
  };
};

const COMPANY = {
  name: "Your Company Name",
  address: "Address Line 1, City",
  phone: "Phone no: 9999999999",
};

// ═══════════════════════════════════════════════════════════════════════════════
// BILL PREVIEW COMPONENT — unchanged
// ═══════════════════════════════════════════════════════════════════════════════
const BillPreview = ({ bill, myCompany, onClose }) => {
  const printRef = useRef();

  const rows = bill.items.map((item) => ({ ...item, ...calcRow(item) }));
  const subTotal    = rows.reduce((s, r) => s + r.taxable, 0);
  const totalCgst   = rows.reduce((s, r) => s + r.cgst, 0);
  const totalSgst   = rows.reduce((s, r) => s + r.sgst, 0);
  const totalAmt    = rows.reduce((s, r) => s + r.amount, 0);
  const totalDisc   = rows.reduce((s, r) => s + r.discAmt, 0);
  const roundOffAmt = bill.roundOff ? Math.round(totalAmt) - totalAmt : 0;
  const grandTotal  = totalAmt + roundOffAmt;

    const logoSrc = myCompany?.logo
    ? `data:image/jpeg;base64,${myCompany.logo}`
    : null;

  // signature from base64
  const signatureSrc = myCompany?.signature
    ? `data:image/jpeg;base64,${myCompany.signature}`
    : null;

  const taxSummary = {};
  rows.forEach((r) => {
    const pct = getGstPct(r.tax);
    if (pct === 0) return;
    const key = `${pct}%`;
    if (!taxSummary[key]) taxSummary[key] = { taxable: 0, cgst: 0, sgst: 0, rate: pct };
    taxSummary[key].taxable += r.taxable;
    taxSummary[key].cgst    += r.cgst;
    taxSummary[key].sgst    += r.sgst;
  });

  const handlePrint = () => {
    const printContents = printRef.current.innerHTML;
    const w = window.open("", "_blank");
    w.document.write(`
      <html><head><title>Sale Invoice</title>
      <style>
        @import url('https://fonts.googleapis.com/css2?family=Roboto:wght@400;500;600;700&display=swap');
        * { box-sizing: border-box; margin: 0; padding: 0; }
        body { font-family: 'Roboto', Arial, sans-serif; background: #fff; }
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid #ccc; padding: 5px 8px; font-size: 11px; }
        @media print { body { -webkit-print-color-adjust: exact; print-color-adjust: exact; } }
      </style></head>
      <body>${printContents}</body></html>
    `);
    w.document.close();
    w.focus();
    setTimeout(() => { w.print(); w.close(); }, 400);
  };

  const HDR = { background: "#7B2D00", color: "#fff", padding: "6px 10px", fontWeight: "700", fontSize: "12px" };
  const cellStyle = { border: "1px solid #ccc", padding: "5px 8px", fontSize: "11px", verticalAlign: "middle" };
  const thStyle = { ...cellStyle, background: "#7B2D00", color: "#fff", fontWeight: "600", textAlign: "center", whiteSpace: "nowrap" };

  return (
    <div style={{ position: "fixed", inset: 0, background: "rgba(0,0,0,0.55)", zIndex: 9999, display: "flex", alignItems: "center", justifyContent: "center", padding: "20px" }}>
      <div style={{ background: "#f0f0f0", borderRadius: "8px", width: "960px", maxHeight: "90vh", display: "flex", flexDirection: "column", overflow: "hidden", boxShadow: "0 8px 40px rgba(0,0,0,0.3)" }}>
        <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", padding: "12px 20px", background: "#1976d2", color: "#fff" }}>
          <span style={{ fontWeight: "700", fontSize: "15px" }}>Sale Invoice Preview</span>
          <div style={{ display: "flex", gap: "10px" }}>
            <button onClick={handlePrint} style={{ padding: "7px 20px", background: "#fff", color: "#1976d2", border: "none", borderRadius: "4px", fontWeight: "700", cursor: "pointer", fontSize: "13px" }}>🖨 Print / Save PDF</button>
            <button onClick={onClose} style={{ padding: "7px 16px", background: "rgba(255,255,255,0.2)", color: "#fff", border: "none", borderRadius: "4px", cursor: "pointer", fontSize: "13px" }}>✕ Close</button>
          </div>
        </div>
        <div style={{ overflowY: "auto", flex: 1, padding: "20px", display: "flex", justifyContent: "center" }}>
          <div ref={printRef} style={{ background: "#fff", width: "880px", fontFamily: "'Roboto', Arial, sans-serif", border: "1px solid #ccc", padding: "0", fontSize: "12px" }}>
            <div style={{ textAlign: "center", padding: "10px 0 4px 0", fontWeight: "700", fontSize: "16px", letterSpacing: "1px" }}>Sale Invoice</div>
            <div style={{ display: "flex", alignItems: "flex-start", justifyContent: "space-between", padding: "8px 16px 4px 16px" }}>
              <div style={{ width: "70px", height: "70px", border: "1px solid #bbb", display: "flex", alignItems: "center", justifyContent: "center", fontSize: "11px", color: "#999", background: "#f5f5f5", flexShrink: 0, borderRadius: "4px", overflow: "hidden" }}>
              {logoSrc
                ? <img src={logoSrc} alt="logo" style={{ width: "100%", height: "100%", objectFit: "contain" }} />
                : bill.imageDataUrl
                ? <img src={bill.imageDataUrl} alt="logo" style={{ width: "100%", height: "100%", objectFit: "contain" }} />
                : "LOGO"}
            </div>
            <div style={{ textAlign: "right", fontSize: "11px", lineHeight: "1.6" }}>
              <div style={{ fontWeight: "700", fontSize: "14px" }}>{myCompany?.businessName || "Your Company"}</div>
              <div style={{ color: "#555" }}>{myCompany?.businessAddress || ""}</div>
              <div style={{ color: "#555" }}>{myCompany?.phoneNumber ? `Ph: ${myCompany.phoneNumber}` : ""}</div>
              {myCompany?.gstin && <div style={{ color: "#555" }}>GSTIN: {myCompany.gstin}</div>}
              {myCompany?.emailId && <div style={{ color: "#555" }}>{myCompany.emailId}</div>}
            </div>
            </div>
            <table style={{ borderCollapse: "collapse", width: "100%", margin: "4px 0" }}>
              <tbody>
                <tr>
                  <td style={{ ...HDR, width: "50%", border: "1px solid #ccc" }}>Bill To</td>
                  <td style={{ ...HDR, textAlign: "right", border: "1px solid #ccc" }}>Invoice Details</td>
                </tr>
                <tr>
                  <td style={{ ...cellStyle, verticalAlign: "top", paddingTop: "8px" }}>
                    <div style={{ fontWeight: "600" }}>{bill.partyName || "—"}</div>
                    {bill.phoneNo && <div style={{ color: "#555", marginTop: "2px" }}>{bill.phoneNo}</div>}
                  </td>
                  <td style={{ ...cellStyle, textAlign: "right", lineHeight: "1.8", verticalAlign: "top", paddingTop: "8px" }}>
                    <div>Invoice No : {bill.invoicePrefix !== "NONE" ? `${bill.invoicePrefix}-` : ""}{bill.invoiceNumber}</div>
                    <div>Date : {bill.invoiceDate ? new Date(bill.invoiceDate).toLocaleDateString("en-GB").replace(/\//g, "-") : ""}</div>
                    <div>Payment : {bill.isCash ? "Cash" : "Credit"}</div>
                    {bill.stateOfSupply && <div>State : {bill.stateOfSupply}</div>}
                  </td>
                </tr>
              </tbody>
            </table>
            <table style={{ borderCollapse: "collapse", width: "100%", marginTop: "4px" }}>
              <thead>
                <tr>
                  <th style={{ ...thStyle, width: "28px" }}>#</th>
                  <th style={{ ...thStyle, textAlign: "left" }}>Item name</th>
                  <th style={{ ...thStyle, width: "70px" }}>HSN/SAC</th>
                  <th style={{ ...thStyle, width: "55px" }}>Qty</th>
                  <th style={{ ...thStyle, width: "45px" }}>Unit</th>
                  <th style={{ ...thStyle, width: "75px" }}>Price/Unit</th>
                  <th style={{ ...thStyle, width: "55px" }}>Disc %</th>
                  <th style={{ ...thStyle, width: "70px" }}>Disc Amt</th>
                  <th style={{ ...thStyle, width: "80px" }}>Taxable Amt</th>
                  <th style={{ ...thStyle, width: "80px" }}>CGST</th>
                  <th style={{ ...thStyle, width: "80px" }}>SGST</th>
                  <th style={{ ...thStyle, width: "75px" }}>Amount</th>
                </tr>
              </thead>
              <tbody>
                {rows.filter(r => r.item).map((r, i) => {
                  const gstPct = getGstPct(r.tax);
                  const halfPct = gstPct / 2;
                  return (
                    <tr key={r.id} style={{ background: i % 2 === 0 ? "#fff" : "#fafafa" }}>
                      <td style={{ ...cellStyle, textAlign: "center" }}>{i + 1}</td>
                      <td style={{ ...cellStyle }}>{r.item}</td>
                      <td style={{ ...cellStyle, textAlign: "center" }}>{r.hsn || ""}</td>
                      <td style={{ ...cellStyle, textAlign: "right" }}>{r.qty}</td>
                      <td style={{ ...cellStyle, textAlign: "center" }}>{r.unit !== "NONE" ? r.unit : ""}</td>
                      <td style={{ ...cellStyle, textAlign: "right" }}>₹ {fmt(parseFloat(r.priceWithoutTax) || 0)}</td>
                      <td style={{ ...cellStyle, textAlign: "right" }}>{r.discountPct ? `${r.discountPct}%` : "—"}</td>
                      <td style={{ ...cellStyle, textAlign: "right" }}>{r.discAmt > 0 ? `₹ ${fmt(r.discAmt)}` : "—"}</td>
                      <td style={{ ...cellStyle, textAlign: "right" }}>₹ {fmt(r.taxable)}</td>
                      <td style={{ ...cellStyle, textAlign: "right" }}>₹ {fmt(r.cgst)}{halfPct > 0 ? ` (${halfPct}%)` : ""}</td>
                      <td style={{ ...cellStyle, textAlign: "right" }}>₹ {fmt(r.sgst)}{halfPct > 0 ? ` (${halfPct}%)` : ""}</td>
                      <td style={{ ...cellStyle, textAlign: "right", fontWeight: "600" }}>₹ {fmt(r.amount)}</td>
                    </tr>
                  );
                })}
                <tr style={{ background: "#f5f5f5" }}>
                  <td colSpan={3} style={{ ...cellStyle, fontWeight: "700" }}>Total</td>
                  <td style={{ ...cellStyle, textAlign: "right", fontWeight: "700" }}>{rows.filter(r => r.item).reduce((s, r) => s + (parseFloat(r.qty) || 0), 0)}</td>
                  <td style={cellStyle}></td>
                  <td style={cellStyle}></td>
                  <td style={cellStyle}></td>
                  <td style={{ ...cellStyle, textAlign: "right", fontWeight: "700" }}>₹ {fmt(totalDisc)}</td>
                  <td style={{ ...cellStyle, textAlign: "right", fontWeight: "700" }}>₹ {fmt(subTotal)}</td>
                  <td style={{ ...cellStyle, textAlign: "right", fontWeight: "700" }}>₹ {fmt(totalCgst)}</td>
                  <td style={{ ...cellStyle, textAlign: "right", fontWeight: "700" }}>₹ {fmt(totalSgst)}</td>
                  <td style={{ ...cellStyle, textAlign: "right", fontWeight: "700" }}>₹ {fmt(totalAmt)}</td>
                </tr>
              </tbody>
            </table>
            <table style={{ borderCollapse: "collapse", width: "100%", marginTop: "4px" }}>
              <tbody>
                <tr>
                  <td style={{ border: "1px solid #ccc", width: "50%", verticalAlign: "top", padding: 0 }}>
                    <table style={{ borderCollapse: "collapse", width: "100%" }}>
                      <thead>
                        <tr>
                          <th style={{ ...thStyle, fontSize: "11px" }}>Tax type</th>
                          <th style={{ ...thStyle, fontSize: "11px" }}>Taxable amount</th>
                          <th style={{ ...thStyle, fontSize: "11px" }}>Rate</th>
                          <th style={{ ...thStyle, fontSize: "11px" }}>Tax amount</th>
                        </tr>
                      </thead>
                      <tbody>
                        {Object.entries(taxSummary).length === 0 ? (
                          <tr><td colSpan={4} style={{ ...cellStyle, textAlign: "center", color: "#aaa" }}>No tax applied</td></tr>
                        ) : Object.entries(taxSummary).map(([key, t]) => (
                          <React.Fragment key={key}>
                            <tr>
                              <td style={{ ...cellStyle, fontWeight: "500" }}>SGST</td>
                              <td style={{ ...cellStyle, textAlign: "right" }}>₹ {fmt(t.taxable)}</td>
                              <td style={{ ...cellStyle, textAlign: "center" }}>{t.rate / 2}%</td>
                              <td style={{ ...cellStyle, textAlign: "right" }}>₹ {fmt(t.sgst)}</td>
                            </tr>
                            <tr>
                              <td style={{ ...cellStyle, fontWeight: "500" }}>CGST</td>
                              <td style={{ ...cellStyle, textAlign: "right" }}>₹ {fmt(t.taxable)}</td>
                              <td style={{ ...cellStyle, textAlign: "center" }}>{t.rate / 2}%</td>
                              <td style={{ ...cellStyle, textAlign: "right" }}>₹ {fmt(t.cgst)}</td>
                            </tr>
                          </React.Fragment>
                        ))}
                      </tbody>
                    </table>
                  </td>
                  <td style={{ border: "1px solid #ccc", width: "50%", verticalAlign: "top", padding: 0 }}>
                    <table style={{ borderCollapse: "collapse", width: "100%" }}>
                      <tbody>
                        <tr><td style={{ ...cellStyle, fontWeight: "500" }}>Amounts</td><td style={{ ...cellStyle }}></td></tr>
                        {totalDisc > 0 && (
                          <tr>
                            <td style={{ ...cellStyle }}>Discount</td>
                            <td style={{ ...cellStyle, textAlign: "right", color: "#c0392b" }}>- ₹ {fmt(totalDisc)}</td>
                          </tr>
                        )}
                        <tr>
                          <td style={{ ...cellStyle }}>Sub Total</td>
                          <td style={{ ...cellStyle, textAlign: "right" }}>₹ {fmt(totalAmt)}</td>
                        </tr>
                        {bill.roundOff && roundOffAmt !== 0 && (
                          <tr>
                            <td style={{ ...cellStyle }}>Round Off</td>
                            <td style={{ ...cellStyle, textAlign: "right" }}>₹ {fmt(roundOffAmt)}</td>
                          </tr>
                        )}
                        <tr style={{ background: "#f5f5f5" }}>
                          <td style={{ ...cellStyle, fontWeight: "700", fontSize: "13px" }}>Total</td>
                          <td style={{ ...cellStyle, textAlign: "right", fontWeight: "700", fontSize: "13px" }}>₹ {fmt(grandTotal)}</td>
                        </tr>

                         {/* ── ADD THESE TWO ROWS ── */}
                        {bill.received && bill.receivedAmount && (
                          <tr>
                            <td style={{ ...cellStyle }}>Received</td>
                            <td style={{ ...cellStyle, textAlign: "right", color: "#27ae60" }}>
                              ₹ {fmt(parseFloat(bill.receivedAmount))}
                            </td>
                          </tr>
                        )}
                        {bill.received && bill.receivedAmount && (
                          <tr>
                            <td style={{ ...cellStyle, fontWeight: "600" }}>Balance</td>
                            <td style={{ ...cellStyle, textAlign: "right", fontWeight: "600",
                              color: (grandTotal - parseFloat(bill.receivedAmount)) > 0 ? "#c0392b" : "#27ae60" }}>
                              ₹ {fmt(grandTotal - parseFloat(bill.receivedAmount))}
                            </td>
                          </tr>
                        )}
                 
                    </tbody>
                    </table>
                  </td>
                </tr>
              </tbody>
            </table>
            <table style={{ borderCollapse: "collapse", width: "100%", marginTop: "4px" }}>
              <tbody>
                <tr>
                  <td style={{ border: "1px solid #ccc", width: "50%", padding: 0, verticalAlign: "top" }}>
                    <div style={{ ...HDR, border: "none" }}>Amount in Words</div>
                    <div style={{ padding: "8px 10px", fontSize: "11px", fontStyle: "italic" }}>{amountInWords(grandTotal)}</div>
                  </td>
                  <td style={{ border: "1px solid #ccc", width: "50%", padding: 0, verticalAlign: "top" }}>
                    <div style={{ ...HDR, border: "none" }}>Description</div>
                    <div style={{ padding: "8px 10px", fontSize: "11px", minHeight: "30px" }}>{bill.description || ""}</div>
                  </td>
                </tr>
              </tbody>
            </table>
            <table style={{ borderCollapse: "collapse", width: "100%", marginTop: "4px" }}>
              <tbody>
                <tr>
                  <td style={{ border: "1px solid #ccc", width: "50%", padding: 0, verticalAlign: "top" }}>
                    <div style={{ ...HDR, border: "none" }}>Terms and Conditions</div>
                    <div style={{ padding: "8px 10px", fontSize: "11px", minHeight: "60px" }}>{bill.termsConditions || ""}</div>
                  </td>
                  <td style={{ border: "1px solid #ccc", width: "50%", padding: 0, verticalAlign: "top" }}>
                    <div style={{ padding: "8px 10px", minHeight: "80px", display: "flex", flexDirection: "column", alignItems: "flex-end", justifyContent: "space-between" }}>
                      <div style={{ fontSize: "11px", textAlign: "right" }}>For : {COMPANY.name}</div>
                    {signatureSrc && (
                      <img src={signatureSrc} alt="signature"
                        style={{ maxHeight: "50px", maxWidth: "120px", objectFit: "contain", marginTop: "8px" }} />
                    )}
                    <div style={{ fontSize: "11px", fontWeight: "600", textAlign: "right", marginTop: "8px" }}>Authorized Signatory</div>                    </div>
                  </td>
                </tr>
              </tbody>
            </table>
            <div style={{ height: "12px" }} />
          </div>
        </div>
      </div>
    </div>
  );
};

// ═══════════════════════════════════════════════════════════════════════════════
// MAIN COMPONENT
// ═══════════════════════════════════════════════════════════════════════════════
const AddSale = () => {
  const navigate = useNavigate();
  const { id } = useParams();
  const [units, setUnits] = useState([]);

  //const isViewMode = Boolean(id); // ← true whenever we're loading an existing bill (read-only)
  const location = useLocation();
  const isEditRoute = location.pathname.startsWith("/editsale");
  const isViewMode = Boolean(id) && !isEditRoute;  // read-only
  const isEditMode = Boolean(id) && isEditRoute;   // editable, updates existing bill
  const { gstSettings, itemSettings } = useContext(GlobalStateContext);
  const token = sessionStorage.getItem("token");
  const tabCounter = useRef(2);
  const fileInputRef = useRef();

  // ── invoice number counter ──
  const invoiceCounter = useRef(1);

  const [bills, setBills] = useState([]);
  const [activeTabId, setActiveTabId] = useState(1);
  const [showPreview, setShowPreview] = useState(false);
  const [saving, setSaving] = useState(false);

  // ── item search state ──
  const [itemSearchResults, setItemSearchResults] = useState([]);
  const [activeItemSearchIndex, setActiveItemSearchIndex] = useState(null);

  // ── customer search state ──
  const [customerSearchResults, setCustomerSearchResults] = useState([]);
  const [showCustomerDropdown, setShowCustomerDropdown] = useState(false);

  const [myCompany, setMyCompany] = useState(null);

  // ═══════════════════════════════════════════════
  // FETCH NEXT INVOICE NUMBER ON PAGE LOAD (new sale only)
  // ═══════════════════════════════════════════════
  useEffect(() => {
    if (id) return; // we're viewing an existing bill — don't create a blank one
    const fetchNextInvoiceNumber = async () => {
      try {
        const res = await axios.get(`${baseUrl}/getNextInvoiceNumber`, {
          headers: { Authorization: token },
        });
        const nextNo = res.data;
        invoiceCounter.current = nextNo;
        // create first tab with correct invoice number
        setBills([defaultBill(1, nextNo)]);
      } catch (err) {
        console.error("Failed to fetch invoice number", err);
        // fallback — start from 1
        setBills([defaultBill(1, 1)]);
      }
    };
    fetchNextInvoiceNumber();
  }, [id]);

  useEffect(() => {
  axios
    .get(`${baseUrl}/getUnits`, {
      headers: { Authorization: token },
    })
    .then((res) => {
      setUnits(res.data || []);
    })
    .catch(() => {
      console.error("Failed to load units");
    });
}, []);

  useEffect(() => {
  const fetchCompany = async () => {
    try {
      const res = await axios.get(`${baseUrl}/admin/getMyCompany`, {
        headers: { Authorization: token },
      });
      if (res.status === 200 && res.data) {
        setMyCompany(res.data);
      }
    } catch (err) {
      console.error("Failed to fetch company", err);
    }
  };
  fetchCompany();
}, []);

  // ═══════════════════════════════════════════════
  // VIEW MODE — fetch an existing bill and populate the form (read-only)
  // ═══════════════════════════════════════════════
  useEffect(() => {
    if (!id) return;

    axios.get(`${baseUrl}/getBill/${id}`, {
      headers: { Authorization: token }
    })
    .then((res) => {
      const mapped = mapBillToFormState(res.data);
      setBills([mapped]);
      setActiveTabId(mapped.id);
    })
    .catch((err) => {
      console.error("Failed to load bill", err);
      alert("Failed to load invoice. Please try again.");
    });

  }, [id]);


  const getActiveBill = () => bills.find((b) => b.id === activeTabId) || bills[0];

  const updateActiveBill = (updater) => {
    setBills((prev) =>
      prev.map((b) => (b.id === activeTabId ? { ...b, ...updater(b) } : b))
    );
  };

  const handleItemChange = (index, field, value) => {
    updateActiveBill((b) => {
      const updated = b.items.map((item, i) =>
        i !== index ? item : { ...item, [field]: value }
      );
      return { items: updated };
    });
  };

  const handleItemMultiChange = (index, fields) => {
    updateActiveBill((b) => {
      const updated = b.items.map((item, i) =>
        i !== index ? item : { ...item, ...fields }
      );
      return { items: updated };
    });
  };

  const addRow = () => updateActiveBill((b) => ({ items: [...b.items, defaultItem()] }));

  const removeRow = (index) => {
    updateActiveBill((b) => {
      if (b.items.length === 1) return {};
      return { items: b.items.filter((_, i) => i !== index) };
    });
  };

  // ── add new tab with auto incremented invoice number ──
  const addNewBillTab = () => {
    const newId = tabCounter.current++;
    invoiceCounter.current = invoiceCounter.current + 1;
    const newInvoiceNo = invoiceCounter.current;
    setBills((prev) => [...prev, defaultBill(newId, newInvoiceNo)]);
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

  // debounce customer search
  const customerSearchTimer = useRef(null);
  const handlePartyInput = (value) => {
    updateActiveBill(() => ({ partyName: value }));
    clearTimeout(customerSearchTimer.current);
    customerSearchTimer.current = setTimeout(() => {
      searchCustomer(value);
    }, 300);
  };

  const selectCustomer = (customer) => {
    updateActiveBill(() => ({
      partyName: customer.name,
      phoneNo: customer.phone || "",
      stateOfSupply: customer.state || "",
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

  // debounce item search
  const itemSearchTimer = useRef(null);
  const handleItemNameInput = (index, value) => {
    handleItemChange(index, "item", value);
    clearTimeout(itemSearchTimer.current);
    itemSearchTimer.current = setTimeout(() => {
      searchItem(value, index);
    }, 300);
  };

 const selectItem = (rowIndex, selectedItem) => {

  let priceToUse = 0;
  let taxString  = "Select";
  let taxPct     = selectedItem.taxRate || 0;

  // ── MRP available → use MRP, no GST ──
  if (selectedItem.mrp) {
    priceToUse = selectedItem.mrp;
    taxString  = "Select";   // no GST on MRP
    taxPct     = 0;

  // ── No MRP → use salePrice, apply GST ──
  } else {
    priceToUse = selectedItem.salePrice || 0;
    taxString  = taxPct > 0 ? `GST ${taxPct}%` : "Select";

    // if salePrice stored as with_tax → back calculate to without tax
    if (selectedItem.salePriceTaxType === "with_tax" && taxPct > 0) {
      priceToUse = priceToUse / (1 + taxPct / 100);
      priceToUse = Math.round(priceToUse * 100) / 100;
    }
  }

  handleItemMultiChange(rowIndex, {
    item:            selectedItem.itemName,
    hsn:             selectedItem.itemHsn || "",
    unit:            selectedItem.unit || "NONE",
    priceWithoutTax: String(priceToUse),
    tax:             taxString,
    qty: "1",
    mrp:             selectedItem.mrp ? String(selectedItem.mrp) : "",
    addcess:         selectedItem.additionalCessPerUnit
                     ? String(selectedItem.additionalCessPerUnit) : "",
    discountPct:     selectedItem.discountOnSale
                     ? String(selectedItem.discountOnSale) : "",
    _discAmtManual:  false,
  });

  setItemSearchResults([]);
  setActiveItemSearchIndex(null);
};

  // ═══════════════════════════════════════════════
  // SAVE BILL — calls backend
  // ═══════════════════════════════════════════════
  const handleSave = async () => {
    const bill = getActiveBill();

    if (!bill.received) {
      alert("Please check Received before saving the bill.");
      return;
    }


    // validate — at least one item must be entered
    const filledItems = bill.items.filter(
      (i) => i.item && i.item.trim() !== ""
    );
    if (filledItems.length === 0) {
      alert("Please add at least one item.");
      return;
    }

    setSaving(true);
    try {
      // build request payload
      const rows = bill.items
        .filter((i) => i.item && i.item.trim() !== "")
        .map((item, index) => {
          const taxPct = getGstPct(item.tax);
          return {
            lineNumber:      index + 1,
            itemName:        item.item,
            itemCode:        "",
            modelNo:         item.modelNo || null,
            mfgDate:         item.mfgDate || null,
            expDate:         item.expDate || null,
            mrp:             item.mrp ? parseFloat(item.mrp) : null,
            size:            item.size || null,
            addCess:         item.addcess ? parseFloat(item.addcess) : null,
            hsnCode:         item.hsn || null,
            qty:             parseFloat(item.qty) || 0,
            unit:            item.unit,
            priceWithoutTax: parseFloat(item.priceWithoutTax) || 0,
            discountPct:     parseFloat(item.discountPct) || 0,
            taxLabel:        item.tax !== "Select" ? item.tax : null,
            taxPct:          taxPct,
          };
        });

      const payload = {
        billType:        "SALE",
        invoiceNumber:   parseInt(bill.invoiceNumber),
        invoicePrefix:   bill.invoicePrefix,
        invoiceDate:     bill.invoiceDate,
        partyName:       bill.partyName,
        phoneNo:         bill.phoneNo,
        stateOfSupply:   bill.stateOfSupply,
        isCash:          bill.isCash,
        paymentMode:     bill.paymentTypes?.[0]?.type || "Cash",
        roundOffEnabled: bill.roundOff,
        received:        bill.received,
        amountReceived:  bill.receivedAmount
                         ? parseFloat(bill.receivedAmount) : null,
        description:     bill.description,
        termsConditions: bill.termsConditions,
        items:           rows,
        payments:        bill.paymentTypes
                         .filter((p) => p.amount)
                         .map((p) => ({
                           paymentType: p.type,
                           amount: parseFloat(p.amount),
                         })),
      };

       if (isEditMode) {
        await axios.put(`${baseUrl}/updateBill/${id}`, payload, {
          headers: { Authorization: token },
        });
      } else {
        await axios.post(`${baseUrl}/saveBill`, payload, {
          headers: { Authorization: token },
        });
      }

      // on success → show preview
      setShowPreview(true);

    } catch (err) {
      console.error("Save failed", err);
      alert("Failed to save bill. Please try again.");
    } finally {
      setSaving(false);
    }
  };

  const bill = getActiveBill();
  if (!bill) return <div>Loading...</div>;

  const rows = bill.items.map((item) => ({ ...item, ...calcRow(item) }));
  const totalQty    = rows.reduce((s, r) => s + (parseFloat(r.qty) || 0), 0);
  const totalDisc   = rows.reduce((s, r) => s + r.discAmt, 0);
  const subTotal    = rows.reduce((s, r) => s + r.taxable, 0);
  const totalCgst   = rows.reduce((s, r) => s + r.cgst, 0);
  const totalSgst   = rows.reduce((s, r) => s + r.sgst, 0);
  const totalAmt    = rows.reduce((s, r) => s + r.amount, 0);
  const roundOffAmt = bill.roundOff ? Math.round(totalAmt) - totalAmt : 0;
  const grandTotal  = totalAmt + roundOffAmt;
  const receivedAmt = parseFloat(bill.receivedAmount) || 0;
  const balanceAmt  = grandTotal - receivedAmt;

  const thBase = {
    padding: "10px 8px", fontSize: "12px", fontWeight: "600",
    color: "#555", borderBottom: "1px solid #e0e0e0",
    borderRight: "1px solid #ececec", background: "#fff",
    whiteSpace: "nowrap", textAlign: "center",
  };
  const thSub = { fontSize: "10px", fontWeight: "400", color: "#999", display: "block" };
  const tdBase = {
    padding: "4px 6px", borderBottom: "1px solid #f0f0f0",
    borderRight: "1px solid #f5f5f5", verticalAlign: "middle",
    fontSize: "13px", color: "#333",
  };
  const cellInput = {
    width: "100%", border: "none", outline: "none",
    background: "transparent", fontSize: "13px", color: "#333",
    padding: "4px 2px", textAlign: "right",
  };

  // dropdown style
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
    <div>
      {showPreview && bill && (
      <BillPreview bill={bill} myCompany={myCompany} onClose={() => setShowPreview(false)} />
    )}

      <div className="invoice-card-wrapper" style={{ marginTop: "-158px" }}>
        <div>
          <div className="card invoice-card">
            <div className="card-body p-0" style={{ display: "flex", flexDirection: "column", height: "calc(100vh - 140px)", minHeight: "640px", background: "#f5f6fa" }}>

              {/* ══ TABS BAR (hidden in read-only view mode — only one invoice to show) ══ */}
             {!id && (
              <div style={{ display: "flex", alignItems: "center", background: "#fff", borderBottom: "1px solid #e8e8e8", padding: "0", minHeight: "44px", gap: "0", flexShrink: 0 }}>
                {bills.map((tab) => (
                  <div key={tab.id} onClick={() => setActiveTabId(tab.id)}
                    style={{ display: "flex", alignItems: "center", gap: "8px", padding: "0 18px", height: "44px", background: activeTabId === tab.id ? "#fff" : "#f5f6fa", borderRight: "1px solid #e8e8e8", borderBottom: activeTabId === tab.id ? "2px solid #1976d2" : "2px solid transparent", cursor: "pointer", fontSize: "13px", fontWeight: activeTabId === tab.id ? "600" : "400", color: activeTabId === tab.id ? "#1976d2" : "#666", userSelect: "none" }}>
                    <span>{tab.label}</span>
                    <span onClick={(e) => { e.stopPropagation(); closeTab(tab.id); }}
                      style={{ display: "flex", alignItems: "center", justifyContent: "center", width: "16px", height: "16px", borderRadius: "50%", fontSize: "10px", color: "#aaa", cursor: "pointer", fontWeight: "700" }}>✕</span>
                  </div>
                ))}
                <div onClick={addNewBillTab}
                  style={{ display: "flex", alignItems: "center", justifyContent: "center", width: "44px", height: "44px", cursor: "pointer", borderRight: "1px solid #e8e8e8", color: "#1976d2", fontSize: "20px", fontWeight: "300" }}
                  title="New Sale">+</div>
                <div style={{ flex: 1 }} />
                <div style={{ display: "flex", alignItems: "center", gap: "10px", paddingRight: "16px" }}>
                  <span style={{ cursor: "pointer", color: "#888", fontSize: "18px" }}><i className="fa-solid fa-calculator" /></span>
                  <span style={{ cursor: "pointer", color: "#888", fontSize: "18px" }}><i className="fa-solid fa-gear" /></span>
                  <span style={{ cursor: "pointer", color: "#888", fontSize: "18px" }}><i className="fa-solid fa-xmark" /></span>
                </div>
              </div>
              )}

              {isEditMode && (
                <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", background: "#d1ecf1", borderBottom: "1px solid #bee5eb", padding: "10px 20px", flexShrink: 0 }}>
                  <span style={{ fontSize: "13px", color: "#0c5460", fontWeight: "600" }}>
                    <i className="fa-solid fa-pen-to-square" style={{ marginRight: "8px" }} />
                    Editing Invoice #{bill.invoicePrefix !== "NONE" ? `${bill.invoicePrefix}-` : ""}{bill.invoiceNumber}
                  </span>
                </div>
              )}

              {/* ══ MAIN FORM AREA ══ */}
              <div style={{ flex: 1, overflowY: "auto", background: "#f5f6fa", padding: "20px 28px 0 28px" }}
                onClick={() => {
                  // close dropdowns when clicking outside
                  setItemSearchResults([]);
                  setActiveItemSearchIndex(null);
                  setShowCustomerDropdown(false);
                }}>

                {/* ── TOP ROW ── */}
                <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", marginBottom: "20px", gap: "20px" }}>
                  <div style={{ display: "flex", gap: "12px", alignItems: "flex-end", flex: 1, maxWidth: "480px" }}>

                    {/* ── PARTY SEARCH ── */}
                    <div style={{ flex: 1, position: "relative" }}>
                      <div style={{ position: "relative" }}>
                        <input
                          type="text"
                          value={bill.partyName}
                          onChange={(e) => handlePartyInput(e.target.value)}
                          onClick={(e) => e.stopPropagation()}
                          placeholder="Search by Name/Phone *"
                          disabled={isViewMode}
                          style={{ width: "100%", padding: "8px 32px 8px 10px", border: "1px solid #1976d2", borderRadius: "4px", fontSize: "13px", outline: "none", background: isViewMode ? "#f5f5f5" : "#fff", boxSizing: "border-box" }}
                        />
                        <i className="fa-solid fa-magnifying-glass" style={{ position: "absolute", right: "10px", top: "50%", transform: "translateY(-50%)", color: "#888", fontSize: "12px", pointerEvents: "none" }} />
                      </div>
                      {/* customer dropdown */}
                      {!isViewMode && showCustomerDropdown && customerSearchResults.length > 0 && (
                        <div style={{ ...dropdownStyle }} onClick={(e) => e.stopPropagation()}>
                          {customerSearchResults.map((c) => (
                            <div key={c.id}
                              style={{ ...dropdownItemStyle }}
                              onMouseEnter={(e) => e.target.style.background = "#f0f7ff"}
                              onMouseLeave={(e) => e.target.style.background = "#fff"}
                              onClick={() => selectCustomer(c)}>
                              <div style={{ fontWeight: "600", fontSize: "13px" }}>{c.name}</div>
                              {c.phone && <div style={{ fontSize: "11px", color: "#888" }}>{c.phone}</div>}
                            </div>
                          ))}
                        </div>
                      )}
                    </div>

                    <div style={{ width: "160px" }}>
                      <input
                        type="text"
                        value={bill.phoneNo}
                        onChange={(e) => updateActiveBill(() => ({ phoneNo: e.target.value }))}
                        placeholder="Phone No."
                        disabled={isViewMode}
                        style={{ width: "100%", padding: "8px 10px", border: "1px solid #ddd", borderRadius: "4px", fontSize: "13px", outline: "none", background: isViewMode ? "#f5f5f5" : "#fff", boxSizing: "border-box" }}
                      />
                    </div>
                  </div>

                  <div style={{ display: "flex", flexDirection: "column", gap: "8px", alignItems: "flex-end", minWidth: "360px" }}>
                    {/* ── INVOICE NUMBER ── */}
                    <div style={{ display: "flex", alignItems: "center", gap: "12px" }}>
                      <span style={{ fontSize: "13px", color: "#555", fontWeight: "500", minWidth: "110px", textAlign: "right" }}>Invoice Number</span>
                      <div style={{ display: "flex", alignItems: "center", border: "1px solid #ddd", borderRadius: "4px", overflow: "hidden", background: "#fff" }}>
                        <select
                          value={bill.invoicePrefix}
                          onChange={(e) => updateActiveBill(() => ({ invoicePrefix: e.target.value }))}
                          disabled={isViewMode}
                          style={{ padding: "5px 6px", border: "none", outline: "none", fontSize: "13px", background: "#f5f5f5", borderRight: "1px solid #ddd", cursor: isViewMode ? "default" : "pointer" }}>
                          {INVOICE_PREFIX_OPTIONS.map((p) => <option key={p}>{p}</option>)}
                        </select>
                        <input
                          type="text"
                          value={bill.invoiceNumber}
                          onChange={(e) => updateActiveBill(() => ({ invoiceNumber: e.target.value }))}
                          disabled={isViewMode}
                          style={{ width: "60px", padding: "5px 8px", border: "none", outline: "none", fontSize: "13px", textAlign: "right" }}
                        />
                      </div>
                    </div>
                    {/* ── INVOICE DATE ── */}
                    <div style={{ display: "flex", alignItems: "center", gap: "12px" }}>
                      <span style={{ fontSize: "13px", color: "#555", fontWeight: "500", minWidth: "110px", textAlign: "right" }}>Invoice Date</span>
                      <div style={{ position: "relative" }}>
                        <input type="date" value={bill.invoiceDate}
                          onChange={(e) => updateActiveBill(() => ({ invoiceDate: e.target.value }))}
                          disabled={isViewMode}
                          style={{ padding: "5px 32px 5px 8px", border: "1px solid #ddd", borderRadius: "4px", fontSize: "13px", outline: "none", width: "160px" }} />
                        <i className="fa-regular fa-calendar" style={{ position: "absolute", right: "8px", top: "50%", transform: "translateY(-50%)", color: "#1976d2", fontSize: "14px", pointerEvents: "none" }} />
                      </div>
                    </div>
                    {/* ── STATE OF SUPPLY ── */}
                    <div style={{ display: "flex", alignItems: "center", gap: "12px" }}>
                      <span style={{ fontSize: "13px", color: "#555", fontWeight: "500", minWidth: "110px", textAlign: "right" }}>State of supply</span>
                      <div style={{ position: "relative" }}>
                        <select value={bill.stateOfSupply}
                          onChange={(e) => updateActiveBill(() => ({ stateOfSupply: e.target.value }))}
                          disabled={isViewMode}
                          style={{ padding: "5px 28px 5px 8px", border: "1px solid #ddd", borderRadius: "4px", fontSize: "13px", outline: "none", appearance: "none", background: "#fff", width: "180px" }}>
                          <option value="">Select</option>
                          {STATES.map((s) => <option key={s} value={s}>{s}</option>)}
                        </select>
                        <i className="fa-solid fa-chevron-down" style={{ position: "absolute", right: "8px", top: "50%", transform: "translateY(-50%)", color: "#888", fontSize: "11px", pointerEvents: "none" }} />
                      </div>
                    </div>
                  </div>
                </div>

                {/* ── TABLE ── */}
                <div style={{ background: "#fff", borderRadius: "6px", boxShadow: "0 1px 4px rgba(0,0,0,0.06)", overflow: "hidden", marginBottom: "0" }}>
                  <div style={{ overflowX: "auto" }}>
                    <table className="table table-hover table-bordered table-sm invoice-table"
                      style={{ width: gstSettings.enableGST ? "160%" : "130%", borderCollapse: "collapse", fontSize: "13px", tableLayout: "fixed" }}>
                      <thead>
                        <tr style={{ borderBottom: "1px solid #e0e0e0" }}>
                          <th style={{ ...thBase, width: "40px" }}>
                            <i className="fa-solid fa-grip-vertical" style={{ color: "#ccc", fontSize: "12px" }} />
                          </th>
                          <th style={{ ...thBase, textAlign: "center", minWidth: "160px" }}>ITEM</th>
                          {itemSettings.modelNo && <th style={{ ...thBase, width: "100px" }}>MODEL NO</th>}
                          {itemSettings.mfgDate && <th style={{ ...thBase, width: "110px" }}>MFG DATE</th>}
                          {itemSettings.expDate && <th style={{ ...thBase, width: "110px" }}>EXP DATE</th>}
                          {itemSettings.mrp     && <th style={{ ...thBase, width: "80px" }}>MRP</th>}
                          {itemSettings.size    && <th style={{ ...thBase, width: "70px" }}>SIZE</th>}
                          {gstSettings.additionalCess && <th style={{ ...thBase, width: "70px" }}>ADD CESS</th>}
                          {gstSettings.enableHSN      && <th style={{ ...thBase, width: "80px" }}>HSN/SAC</th>}
                          <th style={{ ...thBase, width: "70px" }}>QTY</th>
                          <th style={{ ...thBase, width: "80px" }}>UNIT</th>
                          <th style={{ ...thBase, width: "110px" }}>
                            PRICE/UNIT
                            <span style={thSub}>Without Tax</span>
                          </th>
                          <th style={{ ...thBase, width: "160px" }} colSpan={2}>
                            DISCOUNT
                            <div style={{ display: "flex" }}>
                              <span style={{ ...thSub, flex: 1, textAlign: "center" }}>%</span>
                              <span style={{ ...thSub, flex: 1, textAlign: "center" }}>AMOUNT</span>
                            </div>
                          </th>
                          {gstSettings.enableGST && <th style={{ ...thBase, width: "110px" }}>TAXABLE AMT</th>}
                          {gstSettings.enableGST && (
                            <th style={{ ...thBase, width: "170px" }} colSpan={2}>
                              TAX (GST)
                              <div style={{ display: "flex" }}>
                                <span style={{ ...thSub, flex: 1, textAlign: "center" }}>%</span>
                                <span style={{ ...thSub, flex: 1, textAlign: "center" }}>CGST+SGST</span>
                              </div>
                            </th>
                          )}
                          <th style={{ ...thBase, width: "100px" }}>AMOUNT</th>
                          <th style={{ ...thBase, width: "36px", border: "none" }}></th>
                        </tr>
                      </thead>
                      <tbody>
                        {bill.items.map((item, index) => {
                          const r = calcRow(item);
                          return (
                            <tr key={item.id} style={{ background: "#fff" }}>
                              <td style={{ ...tdBase, textAlign: "center", color: "#aaa", fontSize: "12px" }}>{index + 1}</td>

                              {/* ── ITEM with search dropdown ── */}
                              <td style={{ ...tdBase, textAlign: "left", position: "relative" }}
                                onClick={(e) => e.stopPropagation()}>
                                <input
                                  type="text"
                                  value={item.item}
                                  onChange={(e) => handleItemNameInput(index, e.target.value)}
                                  disabled={isViewMode}
                                  style={{ ...cellInput, textAlign: "left" }}
                                  placeholder="Type or select item"
                                />
                                {/* item search dropdown */}
                                {!isViewMode && activeItemSearchIndex === index && itemSearchResults.length > 0 && (
                                  <div style={{ ...dropdownStyle, minWidth: "280px" }}>
                                    {itemSearchResults.map((si) => (
                                      <div key={si.itemId}
                                        style={{ ...dropdownItemStyle }}
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

                              {/* ── MODEL NO — fixed: condition added ── */}
                              {itemSettings.modelNo && (
                                <td style={tdBase}>
                                  <input type="text" value={item.modelNo}
                                    onChange={(e) => handleItemChange(index, "modelNo", e.target.value)}
                                    disabled={isViewMode}
                                    style={{ ...cellInput, textAlign: "left" }} placeholder="Model" />
                                </td>
                              )}

                              {/* ── MFG DATE ── */}
                              {itemSettings.mfgDate && (
                                <td style={tdBase}>
                                  <input type="date" value={item.mfgDate}
                                    onChange={(e) => handleItemChange(index, "mfgDate", e.target.value)}
                                    disabled={isViewMode}
                                    style={{ ...cellInput, fontSize: "11px" }} />
                                </td>
                              )}

                              {/* ── EXP DATE ── */}
                              {itemSettings.expDate && (
                                <td style={tdBase}>
                                  <input type="date" value={item.expDate}
                                    onChange={(e) => handleItemChange(index, "expDate", e.target.value)}
                                    disabled={isViewMode}
                                    style={{ ...cellInput, fontSize: "11px" }} />
                                </td>
                              )}

                              {/* ── MRP — fixed: condition added ── */}
                              {itemSettings.mrp && (
                                <td style={tdBase}>
                                  <input type="number" value={item.mrp}
                                    onChange={(e) => handleItemChange(index, "mrp", e.target.value)}
                                    disabled={isViewMode}
                                    style={cellInput} placeholder="0" />
                                </td>
                              )}

                              {/* ── SIZE — fixed: condition added ── */}
                              {itemSettings.size && (
                                <td style={tdBase}>
                                  <input type="text" value={item.size}
                                    onChange={(e) => handleItemChange(index, "size", e.target.value)}
                                    disabled={isViewMode}
                                    style={{ ...cellInput, textAlign: "left" }} placeholder="Size" />
                                </td>
                              )}

                              {/* ── ADD CESS — fixed: using item.addcess ── */}
                              {gstSettings.additionalCess && (
                                <td style={tdBase}>
                                  <input type="text" value={item.addcess}
                                    onChange={(e) => handleItemChange(index, "addcess", e.target.value)}
                                    disabled={isViewMode}
                                    style={cellInput} placeholder="0" />
                                </td>
                              )}

                              {/* ── HSN ── */}
                              {gstSettings.enableHSN && (
                                <td style={tdBase}>
                                  <input type="text" value={item.hsn}
                                    onChange={(e) => handleItemChange(index, "hsn", e.target.value)}
                                    disabled={isViewMode}
                                    style={cellInput} placeholder="HSN" />
                                </td>
                              )}

                              {/* ── QTY ── */}
                              <input
                                type="number"
                                value={item.qty}
                                onChange={(e) => handleItemChange(index, "qty", e.target.value)}
                                disabled={isViewMode}
                                style={cellInput}
                                placeholder="0"
                                max={Math.pow(10, itemSettings.quantityDecimalPlaces) - 1}
                                onInput={(e) => {
                                  if (e.target.value.length > itemSettings.quantityDecimalPlaces) {
                                    e.target.value = e.target.value.slice(
                                      0,
                                      itemSettings.quantityDecimalPlaces
                                    );
                                  }
                                }}
                              />

                              {/* ── UNIT ── */}
                              <td style={tdBase}>
                                <div style={{ position: "relative" }}>
                                  <select
                                    value={item.unit}
                                    onChange={(e) => handleItemChange(index, "unit", e.target.value)}
                                    disabled={isViewMode}
                                    style={{ ...cellInput, appearance: "none", paddingRight: "18px", cursor: isViewMode ? "default" : "pointer" }}
                                  >
                                    <option value="">NONE</option>
                                    {units.map((u) => (
                                      <option key={u.id} value={u.name}>
                                        {u.name}
                                      </option>
                                    ))}
                                  </select>
                                  <i
                                    className="fa-solid fa-chevron-down"
                                    style={{ position: "absolute", right: "2px", top: "50%", transform: "translateY(-50%)", color: "#bbb", fontSize: "10px", pointerEvents: "none" }}
                                  />
                                </div>
                              </td>

                              {/* ── PRICE ── */}
                              <td style={tdBase}>
                                <input type="number" value={item.priceWithoutTax}
                                  onChange={(e) => handleItemChange(index, "priceWithoutTax", e.target.value)}
                                  disabled={isViewMode}
                                  style={cellInput} placeholder="0" />
                              </td>

                              {/* ── DISCOUNT % ── */}
                              <td style={{ ...tdBase, borderRight: "1px solid #f0f0f0" }}>
                                <input type="number" min="0" max="100" value={item.discountPct}
                                  onChange={(e) => {
                                    const pct = parseFloat(e.target.value) || 0;
                                    const grossAmt = (parseFloat(item.qty) || 0) * (parseFloat(item.priceWithoutTax) || 0);
                                    handleItemMultiChange(index, {
                                      discountPct: e.target.value,
                                      discountAmt: ((grossAmt * pct) / 100).toFixed(2),
                                      _discAmtManual: false,
                                    });
                                  }}
                                  disabled={isViewMode}
                                  style={cellInput} placeholder="0" />
                              </td>

                              {/* ── DISCOUNT AMOUNT ── */}
                              <td style={tdBase}>
                                <input type="number" min="0"
                                  value={item._discAmtManual ? (item.discountAmt ?? "") : (r.discAmt > 0 ? r.discAmt.toFixed(2) : "")}
                                  onChange={(e) => {
                                    const enteredAmt = parseFloat(e.target.value) || 0;
                                    const grossAmt = (parseFloat(item.qty) || 0) * (parseFloat(item.priceWithoutTax) || 0);
                                    const backPct = grossAmt > 0 ? ((enteredAmt / grossAmt) * 100).toFixed(2) : "0";
                                    handleItemMultiChange(index, {
                                      _discAmtManual: true,
                                      discountAmt: e.target.value,
                                      discountPct: backPct,
                                    });
                                  }}
                                  disabled={isViewMode}
                                  style={{ ...cellInput, color: r.discAmt > 0 ? "#c0392b" : "#333" }} placeholder="0" />
                              </td>

                              {/* ── TAXABLE AMT ── */}
                              {gstSettings.enableGST && (
                                <td style={{ ...tdBase, fontWeight: "500", textAlign: "right" }}>
                                  {r.taxable > 0 ? fmt(r.taxable) : ""}
                                </td>
                              )}

                              {/* ── TAX % ── */}
                              {gstSettings.enableGST && (
                                <td style={{ ...tdBase, borderRight: "1px solid #f0f0f0" }}>
                                  <div style={{ position: "relative" }}>
                                    <select value={item.tax}
                                      onChange={(e) => handleItemChange(index, "tax", e.target.value)}
                                      disabled={isViewMode}
                                      style={{ ...cellInput, appearance: "none", paddingRight: "18px", cursor: isViewMode ? "default" : "pointer", color: item.tax === "Select" ? "#aaa" : "#333" }}>
                                      {TAX_OPTIONS.map((t) => <option key={t}>{t}</option>)}
                                    </select>
                                    <i className="fa-solid fa-chevron-down" style={{ position: "absolute", right: "2px", top: "50%", transform: "translateY(-50%)", color: "#bbb", fontSize: "10px", pointerEvents: "none" }} />
                                  </div>
                                </td>
                              )}

                              {/* ── CGST+SGST ── */}
                              {gstSettings.enableGST && (
                                <td style={{ ...tdBase, textAlign: "right", color: "#666" }}>
                                  {r.cgst > 0 ? `₹${fmt(r.cgst + r.sgst)}` : ""}
                                </td>
                              )}

                              {/* ── AMOUNT ── */}
                              <td style={{ ...tdBase, fontWeight: "600", textAlign: "right", color: "#222" }}>
                                {r.amount > 0 ? fmt(r.amount) : ""}
                              </td>

                              {/* ── DELETE (hidden in view mode) ── */}
                              <td style={{ ...tdBase, border: "none", textAlign: "center" }}>
                                {!isViewMode && (
                                  <span onClick={() => removeRow(index)}
                                    style={{ color: "#e74c3c", cursor: "pointer", fontSize: "12px" }}>
                                    <i className="fa-solid fa-trash-can" />
                                  </span>
                                )}
                              </td>
                            </tr>
                          );
                        })}

                        {/* ── TOTALS ROW ── */}
                        <tr style={{ background: "#fafafa", borderTop: "2px solid #e8e8e8" }}>
                          <td colSpan={7} style={{ padding: "10px 12px" }}>
                            {!isViewMode && (
                              <button onClick={addRow} style={{ background: "none", border: "none", color: "#1976d2", fontWeight: "600", fontSize: "13px", cursor: "pointer", padding: "0", display: "flex", alignItems: "center", gap: "6px" }}>
                                <i className="fa-solid fa-plus" style={{ fontSize: "11px" }} /> ADD ROW
                              </button>
                            )}
                          </td>
                          <td style={{ padding: "10px 8px" }}></td>
                          <td style={{ padding: "10px 8px", fontWeight: "600", textAlign: "right", fontSize: "13px", color: "#333" }}>{totalQty || 0}</td>
                          <td style={{ padding: "10px 8px" }}></td>
                          <td style={{ padding: "10px 8px", fontWeight: "600", textAlign: "right", fontSize: "13px", color: "#555" }}>TOTAL</td>
                          <td style={{ padding: "10px 8px" }}></td>
                          <td style={{ padding: "10px 8px", fontWeight: "700", textAlign: "right", fontSize: "13px", color: totalDisc > 0 ? "#c0392b" : "#aaa" }}>
                            {totalDisc > 0 ? fmt(totalDisc) : "0"}
                          </td>
                          {gstSettings.enableGST && (
                            <td style={{ padding: "10px 8px", fontWeight: "700", textAlign: "right", fontSize: "13px", color: "#222" }}>
                              {subTotal > 0 ? fmt(subTotal) : "0"}
                            </td>
                          )}
                          {gstSettings.enableGST && (
                            <td colSpan={2} style={{ padding: "10px 8px", fontWeight: "700", textAlign: "right", fontSize: "13px", color: "#222" }}>
                              {(totalCgst + totalSgst) > 0 ? fmt(totalCgst + totalSgst) : "0"}
                            </td>
                          )}
                          <td style={{ padding: "10px 8px", fontWeight: "700", textAlign: "right", fontSize: "13px", color: "#222" }}>
                            {totalAmt > 0 ? fmt(totalAmt) : "0"}
                          </td>
                          <td></td>
                        </tr>
                      </tbody>
                    </table>
                  </div>
                </div>

                {/* ── BOTTOM SECTION ── */}
                <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", padding: "16px 0 8px 0", gap: "20px" }}>
                  <div style={{ display: "flex", flexDirection: "column", gap: "10px", marginTop: "4px" }}>
                    {itemSettings.description && (
                      <div>
                        <label style={{ fontSize: "11px", color: "#888", fontWeight: "600", marginBottom: "2px", display: "block" }}>DESCRIPTION</label>
                        <textarea value={bill.description}
                          onChange={(e) => updateActiveBill(() => ({ description: e.target.value }))}
                          placeholder="Add description..." rows={2}
                          disabled={isViewMode}
                          style={{ width: "480px", padding: "6px 10px", border: "1px solid #e0e0e0", borderRadius: "4px", fontSize: "13px", outline: "none", resize: "vertical", fontFamily: "inherit", boxSizing: "border-box", background: isViewMode ? "#f5f5f5" : "#fff" }} />
                      </div>
                    )}
                    <div>
                      <label style={{ fontSize: "11px", color: "#888", fontWeight: "600", marginBottom: "2px", display: "block" }}>TERMS & CONDITIONS</label>
                      <textarea value={bill.termsConditions}
                        onChange={(e) => updateActiveBill(() => ({ termsConditions: e.target.value }))}
                        placeholder="Terms and conditions..." rows={2}
                        disabled={isViewMode}
                        style={{ width: "480px", padding: "6px 10px", border: "1px solid #e0e0e0", borderRadius: "4px", fontSize: "13px", outline: "none", resize: "vertical", fontFamily: "inherit", boxSizing: "border-box", background: isViewMode ? "#f5f5f5" : "#fff" }} />
                    </div>
                    {!isViewMode && (
                      <div>
                        <button onClick={() => fileInputRef.current?.click()}
                          style={{ display: "flex", alignItems: "center", gap: "8px", padding: "8px 16px", background: "#fff", border: "1px solid #e0e0e0", borderRadius: "4px", fontSize: "13px", color: bill.imageFile ? "#333" : "#888", cursor: "pointer", fontWeight: "500" }}>
                          <i className="fa-regular fa-image" style={{ color: "#aaa" }} />
                          {bill.imageFile ? bill.imageFile.name.substring(0, 20) : "ADD LOGO / IMAGE"}
                        </button>
                        <input ref={fileInputRef} type="file" accept="image/*" style={{ display: "none" }}
                          onChange={(e) => {
                            const file = e.target.files?.[0];
                            if (!file) return;
                            const reader = new FileReader();
                            reader.onload = (ev) => { updateActiveBill(() => ({ imageFile: file, imageDataUrl: ev.target.result })); };
                            reader.readAsDataURL(file);
                          }} />
                      </div>
                    )}
                  </div>

                  {/* ── RIGHT TOTALS ── */}
                  <div style={{ display: "flex", flexDirection: "column", gap: "10px", alignItems: "flex-end", minWidth: "340px" }}>
                    {totalDisc > 0 && (
                      <div style={{ display: "flex", alignItems: "center", gap: "12px" }}>
                        <span style={{ fontSize: "13px", color: "#c0392b", fontWeight: "500" }}>Discount</span>
                        <input type="text" value={`- ${fmt(totalDisc)}`} readOnly
                          style={{ width: "120px", padding: "5px 8px", border: "1px solid #ddd", borderRadius: "4px", fontSize: "13px", outline: "none", textAlign: "right", background: "#fff6f6", color: "#c0392b" }} />
                      </div>
                    )}
                    <div style={{ display: "flex", alignItems: "center", gap: "12px" }}>
                      <label style={{ display: "flex", alignItems: "center", gap: "6px", fontSize: "13px", color: "#555", cursor: isViewMode ? "default" : "pointer" }}>
                        <input type="checkbox" checked={bill.roundOff}
                          onChange={(e) => updateActiveBill(() => ({ roundOff: e.target.checked }))}
                          disabled={isViewMode}
                          style={{ accentColor: "#1976d2", width: "15px", height: "15px" }} />
                        Round Off
                      </label>
                      <input type="number" value={bill.roundOff ? roundOffAmt.toFixed(2) : "0"} readOnly
                        style={{ width: "100px", padding: "5px 8px", border: "1px solid #ddd", borderRadius: "4px", fontSize: "13px", outline: "none", textAlign: "right", background: "#f9f9f9", color: "#555" }} />
                    </div>
                    <div style={{ display: "flex", alignItems: "center", gap: "12px" }}>
                      <span style={{ fontSize: "14px", fontWeight: "600", color: "#333" }}>Total</span>
                      <input type="text" value={grandTotal > 0 ? fmt(grandTotal) : ""} readOnly
                        style={{ width: "180px", padding: "8px 12px", border: "1px solid #ddd", borderRadius: "4px", fontSize: "15px", fontWeight: "700", outline: "none", textAlign: "right", background: "#fff", color: "#222" }} />
                    </div>
                    {grandTotal > 0 && (
                      <div style={{ fontSize: "11px", color: "#888", fontStyle: "italic", textAlign: "right", maxWidth: "280px" }}>
                        {amountInWords(grandTotal)}
                      </div>
                    )}
                    <div style={{ display: "flex", alignItems: "center", gap: "12px" }}>
                      <label style={{ display: "flex", alignItems: "center", gap: "6px", fontSize: "13px", color: "#555", cursor: isViewMode ? "default" : "pointer" }}>
                        <input type="checkbox" checked={bill.received}
                          onChange={(e) => updateActiveBill(() => ({ received: e.target.checked, receivedAmount: e.target.checked ? String(Math.round(grandTotal)) : "" }))}
                          disabled={isViewMode}
                          style={{ accentColor: "#1976d2", width: "15px", height: "15px" }} />
                        Received
                      </label>
                      <input type="number" value={bill.receivedAmount}
                        onChange={(e) => updateActiveBill(() => ({ receivedAmount: e.target.value, received: true }))}
                        disabled={isViewMode}
                        style={{ width: "180px", padding: "7px 12px", border: "1px solid #ddd", borderRadius: "4px", fontSize: "14px", outline: "none", textAlign: "right", background: isViewMode ? "#f5f5f5" : "#fff", color: "#222" }} />
                    </div>
                    <div style={{ display: "flex", alignItems: "center", gap: "12px" }}>
                      <span style={{ fontSize: "13px", fontWeight: "600", color: "#333", minWidth: "60px", textAlign: "right" }}>Balance</span>
                      <input type="text" value={grandTotal > 0 ? fmt(balanceAmt) : ""} readOnly
                        style={{ width: "180px", padding: "7px 12px", border: "1px solid #ddd", borderRadius: "4px", fontSize: "14px", fontWeight: "600", outline: "none", textAlign: "right", background: "#f9f9f9", color: balanceAmt > 0 ? "#c0392b" : "#27ae60" }} />
                    </div>
                  </div>
                </div>
              </div>

              {/* ══ FOOTER ACTION BAR ══ */}
              <div style={{ display: "flex", alignItems: "center", justifyContent: "flex-end", padding: "12px 28px", borderTop: "1px solid #e8e8e8", background: "#fff", gap: "10px", flexShrink: 0 }}>
                {isViewMode ? (
                  <button
                    onClick={() => navigate(-1)}
                    style={{ padding: "9px 32px", background: "#1976d2", border: "none", borderRadius: "4px", fontSize: "14px", fontWeight: "700", color: "#fff", cursor: "pointer", letterSpacing: "0.3px" }}>
                    ← Back
                  </button>
                ) : (
                  <button
                    onClick={handleSave}
                    disabled={saving || !bill.received}
                    style={{ padding: "9px 32px", background: saving ? "#aaa" : "linear-gradient(135deg, #0f2027, #1a3a4a)", border: "none", borderRadius: "4px", fontSize: "14px", fontWeight: "700", color: "#fff", cursor: saving || !bill.received ? "not-allowed" : "pointer", letterSpacing: "0.3px" }}>
                    {saving ? "Saving..." : "Save"}
                  </button>
                )}
              </div>

            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default AddSale;