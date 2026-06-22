import React, { useEffect, useState, useContext } from "react";
import baseUrl from "../api/utils.js";
import axios from "axios";
import { GlobalStateContext } from "../Context/GlobalStateProvider.js";
import MODULES from "../utils/modules";
import { getPermission } from "../utils/permissionUtils";
import { Link, useNavigate } from "react-router-dom";
import $ from "jquery";

const Sidebar = ({ filter, handleFilterChange }) => {
  const [ActiveLink, setActiveLink] = useState();
  const userRole = sessionStorage.getItem("role");
  const token = sessionStorage.getItem("token");
  

  const navigate = useNavigate();
  const { displayname, Activeprofile,generalSettings } = useContext(GlobalStateContext);
  const profile = sessionStorage.getItem("Activeprofile");
  const result = profile === "SAS" ? true : false;

 
  function updateActiveMenu(routePath) {
    $(".pcoded-navbar .active").not(".pcoded-trigger").removeClass("active");
    $(".pcoded-navbar .pcoded-inner-navbar a").each(function () {
      if ($(this).data("path") === routePath) {
        $(this).parent("li").addClass("active");
        if (!$(".pcoded-navbar").hasClass("theme-horizontal")) {
          $(this).parent("li").parents(".pcoded-hasmenu").addClass("active");
        }
        if ($("body").hasClass("layout-7") || $("body").hasClass("layout-6")) {
          $(".theme-horizontal .pcoded-inner-navbar")
            .find("li.pcoded-trigger")
            .removeClass("pcoded-trigger");
          $(this).parent("li").parents(".pcoded-hasmenu").addClass("active ");
        }
      }
    });
  }

  const handleClick = (e, link) => {
    e.preventDefault();
    setActiveLink(link);
    updateActiveMenu(link);
    navigate(link);
  };

  return (
    <nav className="pcoded-navbar menu-light">
      <div className="navbar-wrapper">
        <div className="navbar-content scroll-div">

          {/* Admin Sidebar */}
          {userRole === "ADMIN" && (
            <>
              <ul className="nav pcoded-inner-navbar">
                <li className="nav-item no-hasmenu pt-2">
                  <a
                    href="#"
                    onClick={(e) => handleClick(e, "/admin/dashboard")}
                    className="nav-link has-ripple"
                  >
                    <span className="pcoded-micon">
                      <i className="feather icon-home"></i>
                    </span>
                    <span className="pcoded-mtext">Dashboard</span>
                  </a>
                </li>

                <li className="nav-item pcoded-hasmenu">
                  <a href="#!" className="nav-link">
                    <span className="pcoded-micon">
                      <i className="feather icon-layout"></i>
                    </span>
                    <span className="pcoded-mtext">Items</span>
                  </a>
                  <ul className="pcoded-submenu">
                    <li>
                      <a
                        href="#"
                        data-path="/item/additem"
                        onClick={(e) => handleClick(e, "/item/additem")}
                      >
                        <i className="fa-solid fa-file-circle-plus pr-2"></i>
                        Add Item
                      </a>
                    </li>
                    <li className="view-course">
                      <a
                        href="#"
                        data-path="/dashboard/viewitem"
                        onClick={(e) => handleClick(e, "/dashboard/viewitem")}
                      >
                        <i className="fa-regular fa-eye pr-2"></i>
                        View Item
                      </a>
                     
                    </li>
                    {/* <li className="view-course">
                      <a
                        href="#"
                        data-path="/course/admin/edit"
                        onClick={(e) => handleClick(e, "/course/admin/edit")}
                      >
                        <i className="fa-solid fa-edit pr-2"></i>
                        Edit Courses
                      </a>
                      <ul className="toggle-list">
                        <li>
                          <label className="checkbox-label">
                            <input
                              type="checkbox"
                              checked={filter?.paid}
                              name="paid"
                              onChange={() => handleFilterChange("paid")}
                              className="mr-1"
                            />
                            <span className="checkbox-custom"></span>
                            Paid
                          </label>
                        </li>
                        <li>
                          <label className="checkbox-label">
                            <input
                              type="checkbox"
                              checked={filter?.unpaid}
                              name="unpaid"
                              onChange={() => handleFilterChange("unpaid")}
                              className="mr-1"
                            />
                            <span className="checkbox-custom"></span>
                            Free
                          </label>
                        </li>
                      </ul>
                    </li> */}
                  </ul>
                </li>

                <li className="nav-item pcoded-hasmenu">
                  <a href="#!" className="nav-link">
                    <span className="pcoded-micon">
                     <i className="fa fa-users"></i>
                    </span>
                    <span className="pcoded-mtext">Parties/Customer</span>
                  </a>
                  <ul className="pcoded-submenu">
                    <li>
                      <a
                        href="#"
                        data-path="/view/Trainer"
                        onClick={(e) => handleClick(e, "/view/Trainer")}
                        className="nav-link"
                      >
                        <span className="pcoded-micon">
                         <i className="fa-solid fa-handshake"></i>  
                        </span>
                        <span className="pcoded-mtext">
                          {displayname && displayname.trainer_name
                            ? displayname.trainer_name
                            : "Trainers"}
                        </span>
                      </a>
                    </li>
                    <li>
                      <a
                        href="#"
                        data-path="/view/Students"
                        onClick={(e) => handleClick(e, "/view/Students")}
                        className="nav-link"
                      >
                        <span className="pcoded-micon">
                       <i className="fa-solid fa-user-tie"></i>                    
                        </span>
                        <span className="pcoded-mtext">
                          {displayname && displayname.student_name
                            ? displayname.student_name
                            : "Student"}
                        </span>
                      </a>
                    </li>
                    
                    {/* <li>
                      <a
                        href="#"
                        data-path="/view/Approvals"
                        onClick={(e) => handleClick(e, "/view/Approvals")}
                        className="nav-link"
                      >
                        <span className="pcoded-micon">
                          <i className="fa-solid fa-person-circle-check"></i>
                        </span>
                        <span className="pcoded-mtext">Approvals</span>
                      </a>
                    </li> */}
                  </ul>
                </li>

               {/* sales page added                */}

             <li className="nav-item pcoded-hasmenu">
  <a href="#!" className="nav-link">
    <span className="pcoded-micon">
      <i className="fa fa-chart-line"></i>
    </span>
    <span className="pcoded-mtext">Sales</span>
  </a>
  <ul className="pcoded-submenu">
      {/* Sale Invoices — controlled by salesInvoiceOrder */}
  {generalSettings.salesInvoiceOrder && (
    <li>
      
      <a
        href="#"
        data-path="/view/salesinvoice"
        onClick={(e) => handleClick(e, "/view/salesinvoice")}
        className="nav-link"
      >
        <span className="pcoded-micon">
          <i className="fa-solid fa-file-invoice-dollar"></i>
        </span>
        <span className="pcoded-mtext">Sale Invoices</span>
      </a>
      
    </li>
  )}
  {generalSettings.estimateQuotation && (
    <li>
  <a
    href="#"
    data-path="/view/estimateinvoice"
    onClick={(e) => handleClick(e, "/view/estimateinvoice")}
    className="nav-link"
    style={{ display: "flex", alignItems: "flex-start", gap: "8px" }}
  >
    <span className="pcoded-micon" style={{ flexShrink: 0, marginTop: "2px" }}>
      <i className="fa-solid fa-file-lines"></i>
    </span>
    <span
      className="pcoded-mtext"
      style={{ lineHeight: "1.4", whiteSpace: "normal" }}
    >
      Estimate/<br />Quotation
    </span>
  </a>
</li>
  )}
    <li>
     <a 
        href="#"
        data-path="/view/posform"
        onClick={(e) => handleClick(e, "/view/posform")}
        className="nav-link"
      >
        <span className="pcoded-micon">
          <i className="fa-solid fa-cash-register"></i>
        </span>
        <span className="pcoded-mtext">Invoice POS</span>
      </a>
    </li>
  </ul>
</li>


                <li className="nav-item pcoded-hasmenu">
                  <a href="#!" className="nav-link">
                    <span className="pcoded-micon">
                      <i className="fa fa-gear"></i>
                    </span>
                    <span className="pcoded-mtext">Settings</span>
                  </a>
                  <ul className="pcoded-submenu">
                    <li>
                      <a
                        data-path="/settings/viewsettings"
                        onClick={(e) => handleClick(e, "/settings/viewsettings")}
                        href="#"
                      >
                        <i className="fa-solid fa-gears pr-2"></i>
                        General
                      </a>
                    </li>
                    {/* <li>
                      <a
                        href="#"
                        data-path="/certificate"
                        onClick={(e) => handleClick(e, "/certificate")}
                      >
                        <i className="fa-solid fa-award pr-2"></i> Certificate
                      </a>
                    </li> */}
                    {/* <li>
                      <a
                        href="#"
                        data-path="/settings/mailSettings"
                        onClick={(e) => handleClick(e, "/settings/mailSettings")}
                      >
                        <i className="fa-solid fa-envelope pr-2"></i> Mail
                      </a>
                    </li> */}
                    {/* {Activeprofile === "VPS" && (
                      <li>
                        <a
                          href="#"
                          data-path="/settings/footer"
                          onClick={(e) => handleClick(e, "/settings/footer")}
                        >
                          <i className="fa-solid fa-shoe-prints pr-2"></i> Footer
                        </a>
                      </li>
                    )} */}
                    {/* <li>
                      <a
                        href="#"
                        data-path="/settings/displayname"
                        onClick={(e) => handleClick(e, "/settings/displayname")}
                      >
                        <i className="fa-solid fa-users-gear"></i> Roles
                      </a>
                    </li> */}

                     {/* taxes and items settings page  */}
                    
                     <li>
                      <a
                        href="#"
                        data-path="/settings/taxes&gstpage"   /* ✅ added "/" */
                        onClick={(e) => handleClick(e, "/settings/taxes&gstpage")}  /* ✅ removed space, added "/" */
                      >
                        <i className="fa-solid fa-building-columns"></i> Taxes & GST
                      </a>
                    </li>

                    <li>
                      <a
                      
                        href="#"
                        data-path="/settings/Items"   /* ✅ added "/" */
                        onClick={(e) => handleClick(e, "/settings/Items")}  /* ✅ removed space, added "/" */
                      >
                        <i className="fa-solid fa-box"></i> Items
                      </a>
                    </li>
                    <li>
                      <a
                      
                        href="#"
                        data-path="/settings/users"   /* ✅ added "/" */
                        onClick={(e) => handleClick(e, "/settings/users")}  /* ✅ removed space, added "/" */
                      >
                        <i className="fa-solid fa-users-gear"></i> Manage Users
                      </a>
                    </li>
                                      


                  </ul>
                </li>

                <li className="nav-item pcoded-hasmenu">
                  <a href="#!" className="nav-link">
                    <span className="pcoded-micon">
                      <i className="fa-regular fa-credit-card"></i>
                    </span>
                    <span className="pcoded-mtext">payments</span>
                  </a>
                  <ul className="pcoded-submenu">
                    <li>
                      <a
                        href="#"
                        data-path="/payment/keys"
                        onClick={(e) => handleClick(e, "/payment/keys")}
                        className="nav-link"
                      >
                        <span className="pcoded-micon">
                          <i className="fa-solid fa-gear"></i>
                        </span>
                        <span className="pcoded-mtext">payment Keys</span>
                      </a>
                    </li>
                    <li>
                      <a
                        href="#"
                        data-path="/payment/transactionHitory"
                        onClick={(e) => handleClick(e, "/payment/transactionHitory")}
                        className="nav-link"
                      >
                        <span className="pcoded-micon">
                          <i className="fa-solid fa-clock-rotate-left"></i>
                        </span>
                        <span className="pcoded-mtext">Transactions</span>
                      </a>
                    </li>
                  </ul>
                </li>

                <li className={`nav-item pcoded-hasmenu ${Activeprofile !== "VPS" ? "d-none" : ""}`}>
                  <a href="#!" className="nav-link">
                    <span className="pcoded-micon">
                      <i className="fa-solid fa-arrows-rotate"></i>
                    </span>
                    <span className="pcoded-mtext">Manage Backups</span>
                  </a>
                  <ul className="pcoded-submenu">
                    <li>
                      <a
                        href="#"
                        data-path="/admin/driveCredentials"
                        onClick={(e) => handleClick(e, "/admin/driveCredentials")}
                        className="nav-link"
                      >
                        <span className="pcoded-micon">
                          <i className="fa-solid fa-key"></i>
                        </span>
                        <span className="pcoded-mtext">Drive keys</span>
                      </a>
                    </li>
                    <li>
                      <a
                        href="#"
                        data-path="/admin/backup-shedule"
                        onClick={(e) => handleClick(e, "/admin/backup-shedule")}
                        className="nav-link"
                      >
                        <span className="pcoded-micon">
                          <i className="fa-solid fa-calendar-days"></i>
                        </span>
                        <span className="pcoded-mtext">Shedule backup</span>
                      </a>
                    </li>
                  </ul>
                </li>

                <li className={`nav-item no-hasmenu ${Activeprofile !== "VPS" ? "d-none" : ""}`}>
                  <a
                    href="#"
                    data-path="/restore"
                    onClick={(e) => handleClick(e, "/restore")}
                    className="nav-link"
                  >
                    <span className="pcoded-micon">
                      <i className="fa-solid fa-window-restore"></i>
                    </span>
                    <span className="pcoded-mtext">Restore data</span>
                  </a>
                </li>
                

                {/* <li className="nav-item no-hasmenu">
                  <a
                    href="#"
                    onClick={(e) => handleClick(e, "/about")}
                    className="nav-link"
                  >
                    <span className="pcoded-micon">
                      <i className="fa-solid fa-circle-info"></i>
                    </span>
                    <span className="pcoded-mtext">About us</span>
                  </a>
                </li> */}
                {/* NEW - My Company (last item) */}
                <li className="nav-item no-hasmenu">
                  
                  <a  href="#"
                    data-path="/admin/mycompany"
                    onClick={(e) => handleClick(e, "/admin/mycompany")}
                    className="nav-link"
                  >
                    <span className="pcoded-micon">
                      <i className="fa-solid fa-building"></i>
                    </span>
                    <span className="pcoded-mtext">My Company</span>
                  </a>
                </li>  

              </ul>
            </>
          )}
          {/* Admin Sidebar */}

          {/* Sysadmin Sidebar */}
          {userRole === "SYSADMIN" && (
            <ul className="nav pcoded-inner-navbar">
              <li className="nav-item no-hasmenu pt-2">
                <a
                  href="#"
                  onClick={(e) => handleClick(e, "/admin/dashboard")}
                  className="nav-link has-ripple"
                >
                  <span className="pcoded-micon">
                    <i className="feather icon-home"></i>
                  </span>
                  <span className="pcoded-mtext">Dashboard</span>
                </a>
              </li>
              <li className="nav-item no-hasmenu pt-2">
                <a
                  href="#"
                  data-path="/viewAll/Admins"
                  onClick={(e) => handleClick(e, "/viewAll/Admins")}
                  className="nav-link"
                >
                  <span className="pcoded-micon">
                    <i className="fa-solid fa-user-tie"></i>
                  </span>
                  <span className="pcoded-mtext">Admins</span>
                </a>
              </li>
              <li className="nav-item no-hasmenu">
                <a
                  href="#"
                  data-path="/viewAll/Cashiers"
                  onClick={(e) => handleClick(e, "/viewAll/Cashiers")}
                  className="nav-link"
                >
                  <span className="pcoded-micon">
                    <i className="fa-solid fa-cash-register"></i>
                  </span>
                  <span className="pcoded-mtext">Cashiers</span>
                </a>
              </li>
              <li className="nav-item no-hasmenu">
                <a
                  href="#"
                  data-path="/restore"
                  onClick={(e) => handleClick(e, "/restore")}
                  className="nav-link"
                >
                  <span className="pcoded-micon">
                    <i className="fa-solid fa-window-restore"></i>
                  </span>
                  <span className="pcoded-mtext">Restore data</span>
                </a>
              </li>
            </ul>
          )}
          {/* Sysadmin Sidebar */}

          {/* //cashier sidebar */}
 {/* //cashier sidebar */}
{userRole === "CASHIER" && (
  <ul className="nav pcoded-inner-navbar">

    {/* Dashboard */}
    <li className="nav-item no-hasmenu pt-2">
      <a href="#" data-path="/admin/dashboard" onClick={(e) => handleClick(e, "/admin/dashboard")} className="nav-link">
        <span className="pcoded-micon"><i className="feather icon-home"></i></span>
        <span className="pcoded-mtext">Dashboard</span>
      </a>
    </li>

    {/* Items */}
    {(getPermission(MODULES.ADD_ITEM, "canView") || getPermission(MODULES.VIEW_ITEM, "canView")) && (
      <li className="nav-item pcoded-hasmenu">
        <a href="#!" className="nav-link">
          <span className="pcoded-micon"><i className="feather icon-layout"></i></span>
          <span className="pcoded-mtext">Items</span>
        </a>
        <ul className="pcoded-submenu">
          {getPermission(MODULES.ADD_ITEM, "canView") && (
            <li>
              <a href="#" data-path="/item/additem" onClick={(e) => handleClick(e, "/item/additem")}>
                <i className="fa-solid fa-file-circle-plus pr-2"></i>Add Item
              </a>
            </li>
          )}
          {getPermission(MODULES.VIEW_ITEM, "canView") && (
            <li>
              <a href="#" data-path="/dashboard/viewitem" onClick={(e) => handleClick(e, "/dashboard/viewitem")}>
                <i className="fa-regular fa-eye pr-2"></i>View Item
              </a>
            </li>
          )}
        </ul>
      </li>
    )}

    {/* Parties/Customer */}
    {(getPermission(MODULES.PARTIES, "canView") || getPermission(MODULES.CUSTOMER, "canView")) && (
      <li className="nav-item pcoded-hasmenu">
        <a href="#!" className="nav-link">
          <span className="pcoded-micon"><i className="fa fa-users"></i></span>
          <span className="pcoded-mtext">Parties/Customer</span>
        </a>
        <ul className="pcoded-submenu">
          {getPermission(MODULES.PARTIES, "canView") && (
            <li>
              <a href="#" data-path="/view/Trainer" onClick={(e) => handleClick(e, "/view/Trainer")} className="nav-link">
                <span className="pcoded-micon"><i className="fa-solid fa-handshake"></i></span>
                <span className="pcoded-mtext">Suppliers</span>
              </a>
            </li>
          )}
          {getPermission(MODULES.CUSTOMER, "canView") && (
            <li>
              <a href="#" data-path="/view/Students" onClick={(e) => handleClick(e, "/view/Students")} className="nav-link">
                <span className="pcoded-micon"><i className="fa-solid fa-user-tie"></i></span>
                <span className="pcoded-mtext">Customer</span>
              </a>
            </li>
          )}
        </ul>
      </li>
    )}

    {/* Sales */}
    {(getPermission(MODULES.SALE_INVOICE, "canView") || getPermission(MODULES.ESTIMATE_QUOTATION, "canView") || getPermission(MODULES.INVOICE_POS, "canView")) && (
      <li className="nav-item pcoded-hasmenu">
        <a href="#!" className="nav-link">
          <span className="pcoded-micon"><i className="fa fa-chart-line"></i></span>
          <span className="pcoded-mtext">Sales</span>
        </a>
        <ul className="pcoded-submenu">
          {getPermission(MODULES.SALE_INVOICE, "canView") && generalSettings.salesInvoiceOrder && (
            <li>
              <a href="#" data-path="/view/salesinvoice" onClick={(e) => handleClick(e, "/view/salesinvoice")} className="nav-link">
                <span className="pcoded-micon"><i className="fa-solid fa-file-invoice-dollar"></i></span>
                <span className="pcoded-mtext">Sale Invoices</span>
              </a>
            </li>
          )}
          {getPermission(MODULES.ESTIMATE_QUOTATION, "canView") && generalSettings.estimateQuotation && (
            <li>
              
              <a  href="#"
                data-path="/view/estimateinvoice"
                onClick={(e) => handleClick(e, "/view/estimateinvoice")}
                className="nav-link"
                style={{ display: "flex", alignItems: "flex-start", gap: "8px" }}
              >
                <span className="pcoded-micon" style={{ flexShrink: 0, marginTop: "2px" }}>
                  <i className="fa-solid fa-file-lines"></i>
                </span>
                <span className="pcoded-mtext" style={{ lineHeight: "1.4", whiteSpace: "normal" }}>
                  Estimate/<br />Quotation
                </span>
              </a>
            </li>
          )}
          {getPermission(MODULES.INVOICE_POS, "canView") && (
            <li>
              <a href="#" data-path="/view/posform" onClick={(e) => handleClick(e, "/view/posform")} className="nav-link">
                <span className="pcoded-micon"><i className="fa-solid fa-cash-register"></i></span>
                <span className="pcoded-mtext">Invoice POS</span>
              </a>
            </li>
          )}
        </ul>
      </li>
    )}

    {/* Settings */}
    {getPermission(MODULES.SETTINGS, "canView") && (
      <li className="nav-item pcoded-hasmenu">
        <a href="#!" className="nav-link">
          <span className="pcoded-micon"><i className="fa fa-gear"></i></span>
          <span className="pcoded-mtext">Settings</span>
        </a>
        <ul className="pcoded-submenu">
          <li>
            <a href="#" data-path="/settings/viewsettings" onClick={(e) => handleClick(e, "/settings/viewsettings")}>
              <i className="fa-solid fa-gears pr-2"></i>General
            </a>
          </li>
          <li>
            <a href="#" data-path="/settings/taxes&gstpage" onClick={(e) => handleClick(e, "/settings/taxes&gstpage")}>
              <i className="fa-solid fa-building-columns pr-2"></i>Taxes & GST
            </a>
          </li>
          <li>
            <a href="#" data-path="/settings/Items" onClick={(e) => handleClick(e, "/settings/Items")}>
              <i className="fa-solid fa-box pr-2"></i>Items
            </a>
          </li>
        </ul>
      </li>
    )}

    {/* My Company */}
    {getPermission(MODULES.MY_COMPANY, "canView") && (
      <li className="nav-item no-hasmenu">
        <a href="#" data-path="/admin/mycompany" onClick={(e) => handleClick(e, "/admin/mycompany")} className="nav-link">
          <span className="pcoded-micon"><i className="fa-solid fa-building"></i></span>
          <span className="pcoded-mtext">My Company</span>
        </a>
      </li>
    )}

  </ul>
)}
{/* ///cashier sidebar */}
{/* ///cashier sidebar */}

          {/* Trainer Sidebar
          {userRole === "TRAINER" && (
            <ul className="nav pcoded-inner-navbar">
              <li className="nav-item no-hasmenu pt-2 view-course">
                <a
                  href="#"
                  data-path="/dashboard/course"
                  onClick={(e) => handleClick(e, "/dashboard/course")}
                  className="nav-link has-ripple"
                >
                  <span className="pcoded-micon">
                   <i className="fa-regular fa-eye pr-2"></i>
                  </span>
                  <span className="pcoded-mtext">View Item</span>
                </a>
                
              </li>
             
              <li className="nav-item no-hasmenu">
                <a
                  href="#"
                  data-path="course/addcourse"
                  onClick={(e) => handleClick(e, "course/addcourse")}
                  className="nav-link has-ripple"
                >
                  <span className="pcoded-micon">
                    <i className="fa-solid fa-file-circle-plus pr-2"></i>
                  </span>
                  <span className="pcoded-mtext">Add Item</span>
                </a>
              </li>

                
              <li className="nav-item no-hasmenu">
                <a
                  href="#"
                  data-path="/view/Students"
                  onClick={(e) => handleClick(e, "/view/Students")}
                  className="nav-link"
                >
                  <span className="pcoded-micon">
                    <i className="fa-solid fa-users"></i>
                  </span>
                  <span className="pcoded-mtext">
                    {displayname && displayname.student_name
                      ? displayname.student_name
                      : "All Students"}
                  </span>
                </a>
              </li>
              {generalSettings.salesInvoiceOrder && (
              <li className="nav-item no-hasmenu">
                <a
                  href="#"
                  data-path="view/salesinvoice"
                  onClick={(e) => handleClick(e, "view/salesinvoice")}
                  className="nav-link"
                >
                  <span className="pcoded-micon">
                    <i className="fa-solid fa-file-invoice-dollar"></i>
                  </span>
                  <span className="pcoded-mtext">
                   Sale Invoices
                  </span>
                </a>
              </li>
              )}

              {generalSettings.salesInvoiceOrder && (
               <li className="nav-item no-hasmenu">
                <a
                  href="#"
                  data-path="view/estimateinvoice"
                  onClick={(e) => handleClick(e, "view/estimateinvoice")}
                  className="nav-link"
                >
                  <span className="pcoded-micon">
                     <i className="fa-solid fa-file-lines"></i>
                  </span>
                  <span className="pcoded-mtext">
                  EstimateQuotation
                  </span>
                </a>
              </li>
              )}

               <li className="nav-item no-hasmenu">
                <a
                  href="#"
                  data-path="view/posform"
                  onClick={(e) => handleClick(e, "view/posform")}
                  className="nav-link"
                >
                  <span className="pcoded-micon">
                    <i className="fa-solid fa-cash-register"></i>
                  </span>
                  <span className="pcoded-mtext">
                  InvoicePOS
                  </span>
                </a>
              </li>
              
            </ul>
          )} */}
          {/* Trainer Sidebar */}

          {/* User Sidebar */}
          {/* {userRole === "USER" && (
            <ul className="nav pcoded-inner-navbar">
              <li className="nav-item no-hasmenu pt-2 view-course">
                <a
                  href="#"
                  data-path="/dashboard/course"
                  onClick={(e) => handleClick(e, "/dashboard/course")}
                  className="nav-link has-ripple"
                >
                  <span className="pcoded-micon">
                    <i className="feather icon-layout"></i>
                  </span>
                  <span className="pcoded-mtext">Courses</span>
                </a>
                <ul className="toggle-list pl-4">
                  <li>
                    <label className="checkbox-label">
                      <input
                        type="checkbox"
                        checked={filter.paid}
                        name="paid"
                        onChange={() => handleFilterChange("paid")}
                        className="mr-1"
                      />
                      <span className="checkbox-custom"></span>
                      Paid
                    </label>
                  </li>
                  <li>
                    <label className="checkbox-label">
                      <input
                        type="checkbox"
                        checked={filter.unpaid}
                        name="unpaid"
                        onChange={() => handleFilterChange("unpaid")}
                        className="mr-1"
                      />
                      <span className="checkbox-custom"></span>
                      Free
                    </label>
                  </li>
                </ul>
              </li>
              <li className="nav-item no-hasmenu">
                <a
                  href="#"
                  data-path="/mycourses"
                  onClick={(e) => handleClick(e, "/mycourses")}
                  className="nav-link has-ripple"
                >
                  <span className="pcoded-micon">
                    <i className="fa-solid fa-book"></i>
                  </span>
                  <span className="pcoded-mtext">My Courses</span>
                </a>
              </li>
              
              
             
              
              <li className="nav-item no-hasmenu">
                <a
                  href="#"
                  data-path="/user/ProgramCalender"
                  onClick={(e) => handleClick(e, "/user/ProgramCalender")}
                  className="nav-link"
                >
                  <span className="pcoded-micon">
                    <i className="fa-solid fa-calendar-plus"></i>
                  </span>
                  <span className="pcoded-mtext">Program Calender</span>
                </a>
              </li>
              <li className="nav-item no-hasmenu">
                <a
                  href="#"
                  data-path="/myGrades"
                  onClick={(e) => handleClick(e, "/myGrades")}
                  className="nav-link"
                >
                  <span className="pcoded-micon">
                    <i className="fa-solid fa-award"></i>
                  </span>
                  <span className="pcoded-mtext">Grades</span>
                </a>
              </li>
              
              <li className="nav-item pcoded-hasmenu">
                <a href="#!" className="nav-link">
                  <span className="pcoded-micon">
                    <i className="fa-solid fa-credit-card"></i>
                  </span>
                  <span className="pcoded-mtext">payments</span>
                </a>
                <ul className="pcoded-submenu">
                  <li>
                    <a
                      href="#"
                      data-path="/myPayments"
                      onClick={(e) => handleClick(e, "/myPayments")}
                      className="nav-link"
                    >
                      <span className="pcoded-micon">
                        <i className="fa-solid fa-clock-rotate-left"></i>
                      </span>
                      <span className="pcoded-mtext">History</span>
                    </a>
                  </li>
                  <li>
                    <a
                      href="#"
                      data-path="/pendingInstallments"
                      onClick={(e) => handleClick(e, "/pendingInstallments")}
                      className="nav-link"
                    >
                      <span className="pcoded-micon">
                        <i className="fa-solid fa-list"></i>
                      </span>
                      <span className="pcoded-mtext">Pendings</span>
                    </a>
                  </li>
                </ul>
              </li>
              <li className="nav-item no-hasmenu">
                <a
                  href="#"
                  data-path="/MyCertificateList"
                  onClick={(e) => handleClick(e, "/MyCertificateList")}
                  className="nav-link"
                >
                  <span className="pcoded-micon">
                    <i className="fa-solid fa-award"></i>
                  </span>
                  <span className="pcoded-mtext">Certificates</span>
                </a>
              </li>
              <li className="nav-item no-hasmenu">
                <a
                  href="#"
                  data-path="/settings"
                  onClick={(e) => handleClick(e, "/settings")}
                  className="nav-link"
                >
                  <span className="pcoded-micon">
                    <i className="fa-solid fa-gear"></i>
                  </span>
                  <span className="pcoded-mtext">Settings</span>
                </a>
              </li>
              
            </ul>
          )}
          User Sidebar */}

        </div>
      </div>
    </nav>
  );
};

export default Sidebar;