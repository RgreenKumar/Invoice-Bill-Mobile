import axios from "axios";
import React, { useContext, useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import Swal from "sweetalert2";
import withReactContent from "sweetalert2-react-content";
import baseUrl from "../api/utils";
import { GlobalStateContext } from "../Context/GlobalStateProvider";
import undraw_profile from "../images/profile.png";
import RadialProgressBar from "./RadialProgressBar";
import SupportChart from "./SupportChart";


const Dashboard = () => {
  const navigate = useNavigate();
  const Currency = sessionStorage.getItem("Currency");
  const Role = sessionStorage.getItem("role");
  const MySwal = withReactContent(Swal);
  const token = sessionStorage.getItem("token");
  const { displayname } = useContext(GlobalStateContext);

  const [storagedetail, setStoragedetail] = useState({ total: "", StorageUsed: "", balanceStorage: "" });
  const [countdetails, setcountdetails] = useState({ coursecount: "", trainercount: "", usercount: "", availableseats: "", paidcourse: "", amountRecived: "" });
  const [trainerFest, settrainerFest] = useState([{ name: "", profile: null, freeCourses: "", paidCourses: "", totalStudents: "" }]);
  const [StudentFest, setStudentFest] = useState([{ name: "", profile: null, freeCourses: "", paidCourses: "", totalStudents: "", pending: "" }]);
  const [StudentFestSysAdmin, setStudentFestSysAdmin] = useState([{ name: "", batchName: "", courseName: "", amount: "" }]);
  const [selectedInstitution, setSelectedInstitution] = useState("");
  const [institutionNames, setInstitutionNames] = useState([]);

  // useEffect(() => {
  //   if (Role !== "ADMIN") return;
  //   const fetchAll = async () => {
  //     try {
  //       const [counts, storage, students, trainers] = await Promise.all([
  //         axios.get(`${baseUrl}/course/countcourse`, { headers: { Authorization: token } }),
  //         axios.get(`${baseUrl}/dashboard/storage`, { headers: { Authorization: token } }),
  //         axios.get(`${baseUrl}/dashboard/StudentSats`, { headers: { Authorization: token } }),
  //         axios.get(`${baseUrl}/dashboard/trainerSats`, { headers: { Authorization: token } }),
  //       ]);
  //       if (counts.status === 200) setcountdetails(counts.data);
  //       setStoragedetail(storage.data);
  //       setStudentFest(students.data);
  //       settrainerFest(trainers.data);
  //     } catch (error) {
  //       if (error.response?.status === 401) navigate("/unauthorized");
  //       else throw error;
  //     }
  //   };
  
  //   fetchAll();
  // }, []);

  // useEffect(() => {
  //   if (Role !== "SYSADMIN") return;
  //   const fetchSysAdmin = async () => {
  //     try {
  //       const url = selectedInstitution === "*" || selectedInstitution === ""
  //         ? `${baseUrl}/sysadmin/dashboard`
  //         : `${baseUrl}/sysadmin/dashboard/${selectedInstitution}`;
  //       const [dash, adminsRes] = await Promise.all([
  //         axios.get(url, { headers: { Authorization: token } }),
  //         axios.get(`${baseUrl}/ViewAll/Admins`, { headers: { Authorization: token } }),
  //       ]);
  //       if (dash.status === 200) {
  //         setcountdetails(dash.data.paymentsummary || {});
  //         setStudentFestSysAdmin(dash.data.paymentlist || []);
  //       }
  //       if (adminsRes.data?.content) {
  //         const adminData = adminsRes.data.content;
  //         const names = Array.from(new Set(adminData.map((a) => a.institutionName).filter(Boolean)));
  //         setInstitutionNames(names);
  //         if (names.length === 1) setSelectedInstitution("*");
  //       }
  //     } catch (error) {
  //       if (error.response?.status === 401) navigate("/unauthorized");
  //       else throw error;
  //     }
  //   };
  //   fetchSysAdmin();
  // }, [selectedInstitution]);

  const convertToGB = (value) => {
    if (!value) return 0;
    if (value.toLowerCase().includes("mb")) return parseFloat(value) / 1024;
    if (value.toLowerCase().includes("gb")) return parseFloat(value);
    return 0;
  };
  const usedPercentage = (convertToGB(storagedetail.StorageUsed) / convertToGB(storagedetail.total)) * 100;
  const currencyIcon = Currency === "INR" ? "fa-indian-rupee-sign" : "fa-dollar-sign";

  // ── ADMIN DASHBOARD ──
  if (Role !== "SYSADMIN") {
    return (
      <>
        {/* Page Header */}
        <div className="page-header">
          <div className="page-block">
            <div className="row align-items-center">
              <div className="col-md-12">
                <div className="page-header-title">
                  <h5 className="m-b-10">Dashboard</h5>
                </div>
                <ul className="breadcrumb">
                  <li className="breadcrumb-item">
                    <a href="#" onClick={() => navigate("/admin/dashboard")}>
                      <i className="feather icon-home"></i>
                    </a>
                  </li>
                  <li className="breadcrumb-item"><a href="#">Dashboard</a></li>
                </ul>
              </div>
            </div>
          </div>
        </div>

        <div className="inv-dash-wrapper">

          {/* ── KPI STRIP ── */}
          <div className="inv-kpi-strip">

            <div className="inv-kpi-card" onClick={() => navigate("/dashboard/course")}>
              <div className="inv-kpi-icon yellow">
                <i className="feather icon-book-open"></i>
              </div>
              <div>
                <div className="inv-kpi-num">{countdetails.coursecount || 0}</div>
                <div className="inv-kpi-label">Total Courses</div>
              </div>
              <span className="inv-kpi-badge yellow">+{countdetails.paidcourse || 0} paid</span>
            </div>

            <div className="inv-kpi-card" onClick={() => navigate("/view/Students")}>
              <div className="inv-kpi-icon red">
                <i className="feather icon-users"></i>
              </div>
              <div>
                <div className="inv-kpi-num">{countdetails.usercount || 0}</div>
                <div className="inv-kpi-label">{displayname?.student_name || "Students"}</div>
              </div>
              <span className="inv-kpi-badge red">enrolled</span>
            </div>

            <div className="inv-kpi-card" onClick={() => navigate("/view/Trainer")}>
              <div className="inv-kpi-icon dark">
                <i className="feather icon-user-check"></i>
              </div>
              <div>
                <div className="inv-kpi-num">{countdetails.trainercount || 0}</div>
                <div className="inv-kpi-label">{displayname?.trainer_name || "Trainers"}</div>
              </div>
              <span className="inv-kpi-badge dark">active</span>
            </div>

            <div className="inv-kpi-card">
              <div className="inv-kpi-icon green">
                <i className="feather icon-grid"></i>
              </div>
              <div>
                <div className="inv-kpi-num">{countdetails.availableseats || 0}</div>
                <div className="inv-kpi-label">Available Seats</div>
              </div>
              <span className="inv-kpi-badge green">open</span>
            </div>

            <div className="inv-kpi-card inv-kpi-dark">
              <div className="inv-kpi-icon white">
                <i className={`fa-solid ${currencyIcon}`}></i>
              </div>
              <div>
                <div className="inv-kpi-num">{countdetails.amountRecived || 0}</div>
                <div className="inv-kpi-label">Total Revenue</div>
              </div>
              <span className="inv-kpi-badge blue">earned</span>
            </div>

          </div>

          {/* ── MAIN GRID ── */}
          <div className="inv-main-grid">

            {/* Revenue Chart */}
            <div className="inv-card span-2">
              <div className="inv-card-header">
                <div>
                  <div className="inv-card-title">Revenue Overview</div>
                  <div className="inv-card-sub">Course payment trends</div>
                </div>
                <span className="inv-pill">
                  <i className={`fa-solid ${currencyIcon}`} style={{ marginRight: 4 }}></i>
                  {countdetails.amountRecived || 0}
                </span>
              </div>
              <SupportChart data={[0, countdetails.paidcourse, countdetails.trainercount, countdetails.coursecount, 0]} />
              <div className="inv-chart-footer">
                <div className="inv-chart-stat"><span className="inv-dot yellow"></span>{countdetails.paidcourse || 0} Paid</div>
                <div className="inv-chart-stat"><span className="inv-dot green"></span>{countdetails.trainercount || 0} Trainers</div>
                <div className="inv-chart-stat"><span className="inv-dot dark"></span>{countdetails.coursecount || 0} Courses</div>
              </div>
            </div>

            {/* Storage */}
            {/* {/* <div className="inv-card">
              <div className="inv-card-header">
                <div>
                  <div className="inv-card-title">Storage</div>
                  <div className="inv-card-sub">Video space usage</div>
                </div>
                <span className="inv-pill green">{storagedetail.balanceStorage} free</span>
              </div>
              <div style={{ width: "160px", height: "160px", margin: "16px auto 0" }}>
                 <RadialProgressBar percentage={usedPercentage} total={storagedetail.total} />
            </div>
              <div className="inv-storage-row">
                <div className="inv-storage-item">
                  <div className="inv-storage-val dark">{storagedetail.total}</div>
                  <div className="inv-storage-lbl">Total</div>
                </div>
                <div className="inv-storage-item">
                  <div className="inv-storage-val red">{storagedetail.StorageUsed}</div>
                  <div className="inv-storage-lbl">Used</div>
                </div>
                <div className="inv-storage-item">
                  <div className="inv-storage-val green">{storagedetail.balanceStorage}</div>
                  <div className="inv-storage-lbl">Available</div>
                </div>
              </div>
            </div> */}

          </div> 

          {/* ── TABLES ── */}
          <div className="inv-table-grid">

            {/* Trainers */}
            <div className="inv-card">
              <div className="inv-card-header">
                <div>
                  <div className="inv-card-title">Parties</div>
                  <div className="inv-card-sub">Active trainer overview</div>
                </div>
                <button className="inv-view-btn" onClick={() => navigate("/view/Trainer")}>View all</button>
              </div>
              <div className="inv-table-scroll">
                <table className="inv-table">
                  <thead>
                    <tr>
                      <th>Name</th>
                      <th>Paid</th>
                      <th>Free</th>
                      <th>Students</th>
                    </tr>
                  </thead>
                  <tbody>
                    {trainerFest.map((t, i) => (
                      <tr key={i}>
                        <td>
                          <div className="inv-name-cell">
                            <img src={t.profile ? `data:image/jpeg;base64,${t.profile}` : undraw_profile} alt="trainer" className="inv-avatar" />
                            <span>{t.name || "—"}</span>
                          </div>
                        </td>
                        <td><span className="inv-badge yellow">{t.paidCourses || 0}</span></td>
                        <td><span className="inv-badge green">{t.freeCourses || 0}</span></td>
                        <td><span className="inv-badge dark">{t.students || 0}</span></td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>

            {/* Students */}
            <div className="inv-card">
              <div className="inv-card-header">
                <div>
                  <div className="inv-card-title">{displayname?.student_name || "Students"}</div>
                  <div className="inv-card-sub">Enrollment summary</div>
                </div>
                <button className="inv-view-btn" onClick={() => navigate("/view/Students")}>View all</button>
              </div>
              <div className="inv-table-scroll">
                <table className="inv-table">
                  <thead>
                    <tr>
                      <th>Name</th>
                      <th>Paid</th>
                      <th>Free</th>
                      <th>Pending</th>
                    </tr>
                  </thead>
                  <tbody>
                    {StudentFest.map((s, i) => (
                      <tr key={i}>
                        <td>
                          <div className="inv-name-cell">
                            <img src={s.profile ? `data:image/jpeg;base64,${s.profile}` : undraw_profile} alt="student" className="inv-avatar" />
                            <span>{s.name || "—"}</span>
                          </div>
                        </td>
                        <td><span className="inv-badge yellow">{s.paidCourses || 0}</span></td>
                        <td><span className="inv-badge green">{s.freeCourses || 0}</span></td>
                        <td><span className="inv-badge red">{s.pending || 0}</span></td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>

          </div>
        </div>
      </>
    );
  }

  // ── SYSADMIN DASHBOARD ──
  return (
    <>
      <div className="page-header">
        <div className="page-block">
          <div className="row align-items-center">
            <div className="col-md-12">
              <div className="page-header-title d-flex align-items-center justify-content-between">
                <h5 className="m-b-10">Dashboard</h5>
                {institutionNames.length > 1 && (
                  <select value={selectedInstitution} onChange={(e) => setSelectedInstitution(e.target.value)}
                    className="form-control" style={{ maxWidth: 250, color: "#000", backgroundColor: "#fff" }}>
                    <option value="*">All Institutions</option>
                    {institutionNames.map((inst, i) => <option key={i} value={inst}>{inst}</option>)}
                  </select>
                )}
              </div>
              <ul className="breadcrumb">
                <li className="breadcrumb-item"><a href="#" onClick={() => navigate("/admin/dashboard")}><i className="feather icon-home"></i></a></li>
                <li className="breadcrumb-item"><a href="#">Dashboard</a></li>
              </ul>
            </div>
          </div>
        </div>
      </div>

      <div className="inv-dash-wrapper">

        {/* KPI Strip */}
        <div className="inv-kpi-strip">
          <div className="inv-kpi-card">
            <div className="inv-kpi-icon yellow"><i className="feather icon-book-open"></i></div>
            <div>
              <div className="inv-kpi-num">{countdetails.coursecount || 0}</div>
              <div className="inv-kpi-label">Courses</div>
            </div>
          </div>
          <div className="inv-kpi-card">
            <div className="inv-kpi-icon red"><i className="feather icon-users"></i></div>
            <div>
              <div className="inv-kpi-num">{countdetails.usercount || 0}</div>
              <div className="inv-kpi-label">Students</div>
            </div>
          </div>
          <div className="inv-kpi-card">
            <div className="inv-kpi-icon dark"><i className="feather icon-user-check"></i></div>
            <div>
              <div className="inv-kpi-num">{countdetails.trainercount || 0}</div>
              <div className="inv-kpi-label">Trainers</div>
            </div>
          </div>
          <div className="inv-kpi-card inv-kpi-dark">
            <div className="inv-kpi-icon white"><i className={`fa-solid ${currencyIcon}`}></i></div>
            <div>
              <div className="inv-kpi-num">{countdetails.amountRecived || 0}</div>
              <div className="inv-kpi-label">Revenue</div>
            </div>
          </div>
        </div>

        {/* Revenue Chart */}
        <div className="inv-card" style={{ marginBottom: 24 }}>
          <div className="inv-card-header">
            <div>
              <div className="inv-card-title">Revenue Overview</div>
              <div className="inv-card-sub">Payment trends across institutions</div>
            </div>
          </div>
          <SupportChart data={[0, countdetails.paidcourse, countdetails.trainercount, countdetails.coursecount, 0]} />
          <div className="inv-chart-footer">
            <div className="inv-chart-stat"><span className="inv-dot yellow"></span>{countdetails.paidcourse || 0} Paid Courses</div>
            <div className="inv-chart-stat"><span className="inv-dot green"></span>{countdetails.trainercount || 0} Trainers</div>
            <div className="inv-chart-stat"><span className="inv-dot dark"></span>{countdetails.coursecount || 0} Total Courses</div>
          </div>
        </div>

        {/* Payments Table */}
        <div className="inv-card">
          <div className="inv-card-header">
            <div>
              <div className="inv-card-title">Recent Payments</div>
              <div className="inv-card-sub">Student payment records</div>
            </div>
          </div>
          <div className="inv-table-scroll">
            <table className="inv-table">
              <thead>
                <tr>
                  <th>Name</th>
                  <th>Batch</th>
                  <th>Course</th>
                  <th>Amount</th>
                </tr>
              </thead>
              <tbody>
                {StudentFestSysAdmin.map((s, i) => (
                  <tr key={i}>
                    <td>
                      <div className="inv-name-cell">
                        <img src={s.profile ? `data:image/jpeg;base64,${s.profile}` : undraw_profile} alt="student" className="inv-avatar" />
                        <span>{s.name || "—"}</span>
                      </div>
                    </td>
                    <td>{s.batchName || "—"}</td>
                    <td>{s.courseName || "—"}</td>
                    <td><span className="inv-badge green">{s.amount || 0}</span></td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>

      </div>
    </>
  );
};

export default Dashboard;