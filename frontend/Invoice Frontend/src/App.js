import { BrowserRouter as Router, Route, Routes } from "react-router-dom";
import { useState, useEffect } from "react";
import { Navigate } from "react-router-dom";
import ForgetPassword from "./AuthenticationPages/forgetpassword";
import Login from "./AuthenticationPages/login";
import PrivateRoute from "./AuthenticationPages/PrivateRoute";
import Missing from "./AuthenticationPages/Missing";
import Unauthorized from "./AuthenticationPages/Unauthorized";
import CertificateInputs from "./certificate/CertificateInputs";
import Template from "./certificate/Template";
import EditCourse from "./course/Update/EditCourse";
import CourseView from "./course/Components/CourseView";
import ViewItem from "./course/Components/CourseView";
import EditCourseForm from "./course/Update/EditCourseForm.js";
import Layout from "./Common Components/Layout.js";
import ViewStudentList from "./Student/ViewStudentList";
import AssignCourse from "./Student/AssignCourse.js";
import Mycourse from "./Student/Mycourse";
import MyCertificateList from "./certificate/MyCertificateList";
import AddSupplier from "./Trainer/AddSupplier.js";
import AddCustomer from "./Student/AddCustomer.js";
import ViewTrainerList from "./Trainer/ViewTrainerList";
import UploadVideo from "./course/Components/UploadVideo";
import CourseCreation from "./course/Components/CourseCreation";
import ViewVideo from "./course/Components/ViewVideo";
import LessonList from "./course/Components/LessonList";
import TrainerProfile from "./Trainer/TrainerProfile.js";
import StudentProfile from "./Student/StudentProfile.js";
import EditLesson from "./course/Update/EditLesson.js";
import EditStudent from "./Student/EditStudent.js";
import EditTrainer from "./Trainer/EditTrainer.js";
import ProfileView from "./Common Components/ProfileView.js";
import CustomViewvideo from "./course/Components/CustomViewvideo.js";
import Dashboard from "./AuthenticationPages/Dashboard.js";
import AboutUs from "./AuthenticationPages/AboutUs.js";
import baseUrl from "./api/utils.js";
import axios from "axios";
import RefreshToken from "./AuthenticationPages/RefreshToken.js";
import MyPayments from "./Student/MyPayments.js";
import Paymenttransactions from "./course/Components/Paymenttransactions.js";

import AdminRegister from "./Registration/AdminRegister.js";
import LicenceExpired from "./AuthenticationPages/LicenceExpired.js";
import ViewAdmin from "./SysAdmin/ViewAdmin.js";
import ViewTrainers from "./SysAdmin/ViewTrainers.js";
import ViewStudents from "./SysAdmin/ViewStudents.js";
import ViewCashier from "./SysAdmin/ViewCashier.js"
import SysadminLicenceupload from "./AuthenticationPages/SysadminLicenceupload.js";
import LicenceDetails from "./AuthenticationPages/LicenceDetails.js";
import Footer from "./Common Components/Footer.js";
import Affiliates from "./SysAdmin/Affiliates.js";
import SlideViewer from "./course/Components/SlideViewer.js";
import AdminProfileView from "./SysAdmin/AdminProfileView.js";
import StudentRegister from "./Registration/StudentRegister.js";
import RedirectComponent from "./RedirectComponent.js";
import TrainerRegistration from "./Registration/TrainerRegistration.js";
// import ViewCourseVps from "./course/Components/ViewCourseVps.js";
import ErrorBoundary from "./ErrorBoundary.js";
import SettingsComponent from "./UserSettings/SettingsComponent.js";
import DisplayName from "./UserSettings/DisplayName.js";
// import SocialLoginKeys from "./SysAdmin/SocialLoginKeys.js";
import MailSettings from "./UserSettings/MailSettings.js";
import MyCompany from "./Common Components/MyCompany.js";////my company file
import "./assets/css/style.css";
import "./assets/css/invoicestyle.css";

import Approvals from "./Registration/Approvals.js";
// import SocialLoginKeysAdmin from "./UserSettings/SocialLoginKeysAdmin.js";
import FooterDetails from "./UserSettings/FooterDetails.js";
import pcoded from "./assets/js/pcoded.js";
import MainPaymentSettingPage from "./course/Payments/MainPaymentSettingPage.js";
import UpdateStripePayment from "./course/Payments/UpdateStripepayment.js";
import UpdatePaypalPayment from "./course/Payments/UpdatePaypalPayment.js";
import ScrollToTop from "./ScrollToTop.js";

import WeightageSetting from "./UserSettings/WeightageSetting.js";


import Partialpaymentsetting from "./course/Components/Partialpaymentsetting.js";
import PendingInstallments from "./Student/PendingInstallments.js";

import LicenceFileCreation from "./AuthenticationPages/LicenceFileCreation.js";
import UserCommonSetting from "./UserSettings/UserCommonSetting.js";
import BackupManager from "./backupmanager/BackupManager.js";
import DriveBackupKeys from "./backupmanager/DriveBackupKeys.js";
import RestorePage from "./backupmanager/RestorePage.js";
//sales page imported
import ViewSaleInvoices from "./Sales/ViewInvoiceSale.js";
import InvoicePOS from "./Sales/InvoicePOS.js";
import EstimateQuotation from "./Sales/EstimateQuotation.js";
import AddSale from "./Sales/AddSale.js";
import AddEstimate from "./Sales/AddEstimate.js";
import Category from "./course/Components/Category.js";
//settings page of invoice
import TaxesGST from "./UserSettings/TaxesGST.js";
import Itemsettings from "./UserSettings/Itemsettings.js";
import Units from  "./course/Components/Units.js";
import ManageUsers from "./UserSettings/ManageUsers.js";
import AddUsers from "./UserSettings/AddUsers.js";

function App() {
  useEffect(() => {
    pcoded();
  }, []);
  const isAuthenticated = sessionStorage.getItem("token") !== null;
  const [searchQuery, setSearchQuery] = useState("");
  const [loading, setloading] = useState(false);
  // const [course, setCourse] = useState([
  //   {
  //     courseId: "",
  //     courseName: "",
  //     courseUrl: "",
  //     courseDescription: "",
  //     courseCategory: "",
  //     amount: "",
  //     courseImage: "",
  //     Duration: "",
  //     Noofseats: "",
  //   },
  // ]);
  // const [filter, setFilter] = useState({ paid: true, unpaid: true }); // Filter state
  // const [aiAvailable, setAiAvailable] = useState(false);

  // useEffect(() => {
  //   axios
  //     .get(`${baseUrl}/ai/available`)
  //     .then((res) => setAiAvailable(res.data.available))
  //     .catch(() => setAiAvailable(false));
  // }, []);
  // const handleSearchChange = (e) => {
  //   setSearchQuery(e.target.value);
  // };
  // const handleFilterChange = (name) => {
  //   setFilter((prev) => {
  //     const updatedFilter = {
  //       ...prev,
  //       [name]: !prev[name], // Toggle the selected filter state
  //     };
  //     return updatedFilter;
  //   });
  // };

  const [items, setItems] = useState([]);

useEffect(() => {
  const fetchItems = async () => {
    try {
      const token = sessionStorage.getItem("token");
      const role  = sessionStorage.getItem("role");
      if (token && role !== "SYSADMIN") {
        setloading(true);
        const response = await axios.get(`${baseUrl}/item/viewAll`, {
          headers: { Authorization: token },
        });
        setItems(response.data);
      }
    } catch (error) {
      console.error("Failed to fetch items:", error);
    } finally {
      setloading(false);
    }
  };
  fetchItems(); // ← remove the isAuthenticated check
}, []); // ← empty array, runs once on mount

const filteredCourses = items.filter((item) =>
  (item.itemName || "").toLowerCase().includes(searchQuery.toLowerCase())
);

  // const filteredCourses = course.filter((item) => {
  //   const name = item.courseName ? item.courseName.toLowerCase() : "";
  //   const matchesSearchQuery = name.includes(searchQuery.toLowerCase());

  //   // If both paid and unpaid filters are selected, show all courses that match the search query
  //   if (filter.paid && filter.unpaid) {
  //     return matchesSearchQuery; // No amount filtering, just search query match
  //   }

  //   // Condition for Paid courses (if filter.paid is selected)
  //   const matchesPaidCondition = filter.paid ? item.amount > 0 : true;

  //   // Condition for Unpaid courses (if filter.unpaid is selected)
  //   const matchesUnpaidCondition = filter.unpaid ? item.amount === 0 : true;

  //   // Return courses that match the search query and the appropriate paid/unpaid condition
  //   return matchesSearchQuery && matchesPaidCondition && matchesUnpaidCondition;
  // });

  // useEffect(() => {
  //   const fetchItems = async () => {
  //     try {
  //       const token = sessionStorage.getItem("token");
  //       const role = sessionStorage.getItem("role");
  //       if (token) {
  //         if (role !== "SYSADMIN") {
  //           setloading(true);
  //           const response = await axios.get(`${baseUrl}/course/viewAll`, {
  //             headers: {
  //               Authorization: token,
  //             },
  //           });
  //           const data = response.data;
  //           setCourse(data);
  //         }
  //       }
  
  //     } catch (error) {
  //       console.error(error);
  //       throw error;
  //     } finally {
  //       setloading(false);
  //     }
  //   };
  //   if (isAuthenticated) {
  //     fetchItems();
  //   }
  // }, [isAuthenticated]);

  return (
    <Router>
      <ScrollToTop />
      <div className="App ">
        <Routes>
          <Route
            element={
              <Layout
               // aiAvailable={aiAvailable}
                searchQuery={searchQuery}
                // handleSearchChange={handleSearchChange}
                setSearchQuery={setSearchQuery}
              />
            }
          >
            <Route
              path="/admin/dashboard"
              element={
                 <ErrorBoundary>
                <PrivateRoute
                   onlyadmin={true}
                  authenticationRequired={true}
                  authorizationRequired={true}
                  // licence={true}
                >
                  <Dashboard />
                </PrivateRoute>
               </ErrorBoundary>
              }
            />
            <Route
              path="/lessonList/:courseName/:courseId"
              element={
                <ErrorBoundary>
                  <PrivateRoute
                    authenticationRequired={true}
                    authorizationRequired={true}
                  >
                    <LessonList />
                  </PrivateRoute>
                </ErrorBoundary>
              }
            />
            <Route
              path="/edit/:courseName/:courseId/:Lessontitle/:lessonId"
              element={
                <ErrorBoundary>
                  <PrivateRoute
                    authenticationRequired={true}
                    authorizationRequired={true}
                  >
                    <EditLesson />
                  </PrivateRoute>
                </ErrorBoundary>
              }
            />
            
            
            
           
            <Route
              path="/courses/:courseName/:courseId/"
              element={
                <ErrorBoundary>
                  <PrivateRoute authenticationRequired={true}>
                    <ViewVideo />
                  </PrivateRoute>
                </ErrorBoundary>
              }
            />
            <Route
              path="/courses/:courseName/:courseId/:current"
              element={
                <ErrorBoundary>
                  <PrivateRoute
                    authenticationRequired={true}
                    authorizationRequired={true}
                  >
                    <CustomViewvideo />
                  </PrivateRoute>
                </ErrorBoundary>
              }
            />
            <Route
              path="/course/Addlesson/:courseName/:courseId"
              element={
                <ErrorBoundary>
                  <PrivateRoute
                    authenticationRequired={true}
                    authorizationRequired={true}
                  >
                    <UploadVideo />
                  </PrivateRoute>
                </ErrorBoundary>
              }
            />
            <Route
              path="/item/additem"
              element={
                <ErrorBoundary>
                  <PrivateRoute
                    authenticationRequired={true}
                    authorizationRequired={true}
                  >
                    <CourseCreation />
                  </PrivateRoute>
                </ErrorBoundary>
              }
            />

            <Route
              path="/addSupplier"
              element={
                <ErrorBoundary>
                  <PrivateRoute
                    authenticationRequired={true}
                    authorizationRequired={true}
                  >
                    <AddSupplier  partyType="SUPPLIER"/>
                  </PrivateRoute>
                </ErrorBoundary>
              }
            />
            <Route
              path="/addCustomer"
              element={
                <ErrorBoundary>
                  <PrivateRoute
                    authenticationRequired={true}
                    authorizationRequired={true}
                  >
                    <AddCustomer partyType="CUSTOMER"/>
                  </PrivateRoute>
                </ErrorBoundary>
              }
            />
            <Route
              path="/mycourses"
              element={
                <ErrorBoundary>
                  <PrivateRoute authenticationRequired={true}>
                    <Mycourse />
                  </PrivateRoute>
                </ErrorBoundary>
              }
            />
           

            <Route
              path="/pendingInstallments"
              element={
                <ErrorBoundary>
                  <PrivateRoute authenticationRequired={true} onlyuser={true}>
                    <PendingInstallments />
                  </PrivateRoute>
                </ErrorBoundary>
              }
            />
           
            
            
            <Route
              path="/dashboard/viewitem"
              element={
                <ErrorBoundary>
                  <PrivateRoute authenticationRequired={true}>
                    <CourseView
                     
                    />
                  </PrivateRoute>
                </ErrorBoundary>
              }
            />
           <Route
                path="/dashboard/category"
                element={
                  <ErrorBoundary>
                    <PrivateRoute authenticationRequired={true}>
                      <Category
                        
                      />
                    </PrivateRoute>
                  </ErrorBoundary>
                }
              />
 
              <Route
              path="/dashboard/unit"
              element={
                <ErrorBoundary>
                  <PrivateRoute authenticationRequired={true}>
                    <Units
                      
                    />
                  </PrivateRoute>
                </ErrorBoundary>
              }
            />

            <Route
              path="/course/admin/edit"
              element={
                <ErrorBoundary>
                  <PrivateRoute
                    onlyadmin={true}
                    authenticationRequired={true}
                    authorizationRequired={true}
                  >
                    <EditCourse
                      filteredCourses={filteredCourses}
                      loading={loading}
                    />
                  </PrivateRoute>
                </ErrorBoundary>
              }
            />
            
           
            <Route
              path="/course/edit/:courseId"
              element={
                <ErrorBoundary>
                  <PrivateRoute
                    authenticationRequired={true}
                    authorizationRequired={true}
                  >
                    <EditCourseForm />
                  </PrivateRoute>
                </ErrorBoundary>
              }
            />
           
            <Route
              path="/course/dashboard/profile"
              element={
                <ErrorBoundary>
                  <PrivateRoute authenticationRequired={true}>
                    <ProfileView />
                  </PrivateRoute>
                </ErrorBoundary>
              }
            />
            <Route
              path="/MyCertificateList"
              element={
                <ErrorBoundary>
                  <PrivateRoute authenticationRequired={true}>
                    <MyCertificateList />
                  </PrivateRoute>
                </ErrorBoundary>
              }
            />
            <Route
              path="/template/:activityId"
              element={
                <ErrorBoundary>
                  <PrivateRoute authenticationRequired={true}>
                    <Template />
                  </PrivateRoute>
                </ErrorBoundary>
              }
            />
            <Route
              path="/assignCourse/Student/:userId"
              element={
                <ErrorBoundary>
                  <PrivateRoute
                    authenticationRequired={true}
                    authorizationRequired={true}
                  >
                    <AssignCourse />
                  </PrivateRoute>
                </ErrorBoundary>
              }
            />
            


            <Route
              path="/view/Students"
              element={
                <ErrorBoundary>
                  <PrivateRoute
                    authenticationRequired={true}
                    authorizationRequired={true}
                  >
                    <ViewStudentList />
                  </PrivateRoute>
                </ErrorBoundary>
              }
            />
           
            <Route
              path="/view/Trainer"
              element={
                <ErrorBoundary>
                  <PrivateRoute
                    authenticationRequired={true}
                    authorizationRequired={true}
                  >
                    <ViewTrainerList />
                  </PrivateRoute>
                </ErrorBoundary>
              }
            />
            <Route
              path="/view/Approvals"
              element={
                <ErrorBoundary>
                  <PrivateRoute
                    authenticationRequired={true}
                    authorizationRequired={true}
                  >
                    <Approvals />
                  </PrivateRoute>
                </ErrorBoundary>
              }
            />


            <Route
              path="/payment/keys"
              element={
                <ErrorBoundary>
                  <PrivateRoute
                    onlyadmin={true}
                    authenticationRequired={true}
                    authorizationRequired={true}
                  >
                    <MainPaymentSettingPage />
                  </PrivateRoute>
                </ErrorBoundary>
              }
            />
            <Route
              path="/certificate"
              element={
                <ErrorBoundary>
                  <PrivateRoute
                    onlyadmin={true}
                    authenticationRequired={true}
                    authorizationRequired={true}
                  >
                    <CertificateInputs />
                  </PrivateRoute>
                </ErrorBoundary>
              }
            />
            <Route
              path="/view/Trainer/profile/:traineremail"
              element={
                <ErrorBoundary>
                  <PrivateRoute
                    authenticationRequired={true}
                    authorizationRequired={true}
                  >
                    <TrainerProfile />
                  </PrivateRoute>
                </ErrorBoundary>
              }
            />
            
            <Route
              path="/view/Student/profile/:studentemail"
              element={
                <ErrorBoundary>
                  <PrivateRoute
                    authenticationRequired={true}
                    authorizationRequired={true}
                  >
                    <StudentProfile />
                  </PrivateRoute>
                </ErrorBoundary>
              }
            />
            <Route
              path="/student/edit/:email"
              element={
                <ErrorBoundary>
                  <PrivateRoute
                    authenticationRequired={true}
                    authorizationRequired={true}
                  >
                    <EditStudent />
                  </PrivateRoute>
                </ErrorBoundary>
              }
            />
            <Route
              path="/trainer/edit/:email"
              element={
                <ErrorBoundary>
                  <PrivateRoute
                    authenticationRequired={true}
                    authorizationRequired={true}
                  >
                    <EditTrainer />
                  </PrivateRoute>
                </ErrorBoundary>
              }
            />
            {/* <Route
              path="/AssignedCourses"
              element={
                <ErrorBoundary>
                  <PrivateRoute
                    onlytrainer={true}
                    authenticationRequired={true}
                  >
                    <MyAssignedcourses />
                  </PrivateRoute>
                </ErrorBoundary>
              }
            /> */}
            <Route
              path="/about"
              element={
                <ErrorBoundary>
                  <PrivateRoute
                    onlyadmin={true}
                    authenticationRequired={true}
                    authorizationRequired={true}
                    licence={true}
                  >
                    <AboutUs/>
                  </PrivateRoute>
                </ErrorBoundary>
              }
            />
            <Route
              path="/myPayments"
              element={
                <ErrorBoundary>
                  <PrivateRoute authenticationRequired={true} onlyuser={true}>
                    <MyPayments />
                  </PrivateRoute>
                </ErrorBoundary>
              }
            />
            <Route
              path="/payment/transactionHitory"
              element={
                <ErrorBoundary>
                  <PrivateRoute
                    authenticationRequired={true}
                    onlyadmin={true}
                    authorizationRequired={true}
                  >
                    <Paymenttransactions />
                  </PrivateRoute>
                </ErrorBoundary>
              }
            />

            <Route
              path="/licenceDetails"
              element={
                <ErrorBoundary>
                  <PrivateRoute
                    authenticationRequired={true}
                    onlyadmin={true}
                    authorizationRequired={true}
                    licence={true}
                  >
                    <LicenceDetails />
                  </PrivateRoute>
                </ErrorBoundary>
              }
            />

            
           
           
            {/* <Route
              path="/mailSending"
              element={
                <ErrorBoundary>
                  <PrivateRoute
                    authenticationRequired={true}
                    authorizationRequired={true}
                  >
                    <MailSending />
                  </PrivateRoute>
                </ErrorBoundary>
              }
            /> */}
            <Route
              path="/settings/Weightage"
              element={
                <ErrorBoundary>
                  <PrivateRoute authenticationRequired={true} onlyadmin={true}>
                    <WeightageSetting />
                  </PrivateRoute>{" "}
                </ErrorBoundary>
              }
            />
            <Route
              path="/settings/mailSettings"
              element={
                <ErrorBoundary>
                  <PrivateRoute authenticationRequired={true} onlyadmin={true}>
                    <MailSettings />
                  </PrivateRoute>{" "}
                </ErrorBoundary>
              }
            />
            {/* <Route
              path="/settings/socialLogins"
              element={
                <ErrorBoundary>
                  <PrivateRoute authenticationRequired={true} onlyadmin={true}>
                    <SocialLoginKeysAdmin />
                  </PrivateRoute>
                </ErrorBoundary>
              }
            /> */}
            <Route
              path="/viewDocument/:documentPath/:lessonId/:docid"
              element={
                <ErrorBoundary>
                  <PrivateRoute authenticationRequired={true}>
                    <SlideViewer />
                  </PrivateRoute>
                </ErrorBoundary>
              }
            />
            <Route
              path="/settings/footer"
              element={
                <ErrorBoundary>
                  <PrivateRoute authenticationRequired={true} onlyadmin={true}>
                    <FooterDetails />
                  </PrivateRoute>
                </ErrorBoundary>
              }
            />
            <Route
              path="/settings/displayname"
              element={
                <ErrorBoundary>
                  <PrivateRoute
                    authenticationRequired={true}
                    authorizationRequired={true}
                    onlyadmin={true}
                  >
                    <DisplayName />
                  </PrivateRoute>
                </ErrorBoundary>
              }
            />
            <Route
              path="/settings/viewsettings"
              element={
                <ErrorBoundary>
                  <PrivateRoute authorizationRequired={true} onlyadmin={true}>
                    <SettingsComponent/>
                  </PrivateRoute>
                </ErrorBoundary>
              }
            />
            <Route
              path="/batch/save/partpay/:batchTitle/:batchId"
              element={
                <ErrorBoundary>
                  <PrivateRoute authorizationRequired={true} onlyadmin={true}>
                    <Partialpaymentsetting />
                  </PrivateRoute>
                </ErrorBoundary>
              }
            />
           
          

            {/* SysAdminRoutes */}
            <Route
              path="/viewAll/Admins"
              element={
                <ErrorBoundary>
                  <PrivateRoute authenticationRequired={true} sysadmin={true}>
                    <ViewAdmin />
                  </PrivateRoute>
                </ErrorBoundary>
              }
            />
            <Route
              path="/viewAll/Trainers"
              element={
                <ErrorBoundary>
                  <PrivateRoute authenticationRequired={true} sysadmin={true}>
                    <ViewTrainers />
                  </PrivateRoute>
                </ErrorBoundary>
              }
            />
            <Route
              path="/viewAll/Students"
              element={
                <ErrorBoundary>
                  <PrivateRoute authenticationRequired={true} sysadmin={true}>
                    <ViewStudents />
                  </PrivateRoute>
                </ErrorBoundary>
              }
            />
             <Route
              path="/viewAll/Cashiers"
              element={
                <ErrorBoundary>
                  <PrivateRoute authenticationRequired={true} sysadmin={true}>
                    <ViewCashier />
                  </PrivateRoute>
                </ErrorBoundary>
              }
            />

            <Route
              path="/settings"
              element={
                <ErrorBoundary>
                  <PrivateRoute authenticationRequired={true} onlyuser={true}>
                    <UserCommonSetting />
                  </PrivateRoute>
                </ErrorBoundary>
              }
            />
            <Route
              path="/licenceupload"
              element={
                <ErrorBoundary>
                  <PrivateRoute authenticationRequired={true} sysadmin={true}>
                    <SysadminLicenceupload />
                  </PrivateRoute>
                </ErrorBoundary>
              }
            />
            <Route
              path="/getlicence"
              element={
                <ErrorBoundary>
                  <PrivateRoute authenticationRequired={true} sysadmin={true}>
                    <LicenceFileCreation />
                  </PrivateRoute>
                </ErrorBoundary>
              }
            />

            
            {/* <Route
              path="/view/SocialLogin"
              element={
                <ErrorBoundary>
                  <PrivateRoute authenticationRequired={true} sysadmin={true}>
                    <SocialLoginKeys />
                  </PrivateRoute>
                </ErrorBoundary>
              }
            /> */}
            <Route
              path="/Affiliates"
              element={
                <ErrorBoundary>
                  <PrivateRoute authenticationRequired={true} sysadmin={true}>
                    <Affiliates />
                  </PrivateRoute>
                </ErrorBoundary>
              }
            />
            <Route
              path="/viewAdmin/profile/:adminemail"
              element={
                <ErrorBoundary>
                  <PrivateRoute authenticationRequired={true} sysadmin={true}>
                    <AdminProfileView />
                  </PrivateRoute>
                </ErrorBoundary>
              }
            />
            <Route
            path="/admin/mycompany"
            element={
              <ErrorBoundary>
                <PrivateRoute
                  authenticationRequired={true}
                  authorizationRequired={true}
                >
                  <MyCompany />
                </PrivateRoute>
              </ErrorBoundary>
            }
          />
          {/* Sales related routers */}
           {/* newly sales page routers*/}
            <Route
                path="/view/salesinvoice"
                element={
                  <ErrorBoundary>
                    <PrivateRoute
                      authenticationRequired={true}
                      authorizationRequired={true}
                    >
                      <ViewSaleInvoices />
                    </PrivateRoute>
                  </ErrorBoundary>
                }
              />

                {/* newly estimate page routers*/}
            <Route
                path="/view/estimateinvoice"
                element={
                  <ErrorBoundary>
                    <PrivateRoute
                      authenticationRequired={true}
                      authorizationRequired={true}
                    >
                      <EstimateQuotation />
                    </PrivateRoute>
                  </ErrorBoundary>
                }
              />

              {/* Add Sale page — new bill (no id) */}
              <Route path="/addsale" element={
                <ErrorBoundary>
                  <PrivateRoute authenticationRequired={true} authorizationRequired={true}>
                    <AddSale />
                  </PrivateRoute>
                </ErrorBoundary>
              } />

                {/* Add Sale page pos form    */}
                <Route path="/addsale/:id" element={
                  <ErrorBoundary>
                    <PrivateRoute authenticationRequired={true} authorizationRequired={true}>
                    <AddSale />
                 </PrivateRoute></ErrorBoundary>
                } />  

                <Route path="/editsale/:id" element={
                <ErrorBoundary>
                  <PrivateRoute authenticationRequired={true} authorizationRequired={true}>
                     <AddSale />
                  </PrivateRoute>
                </ErrorBoundary>
              } />

                  {/* Add Estimate page pos form    */}
                <Route path="/addestimate" element={
                  <ErrorBoundary>
                    <PrivateRoute authenticationRequired={true} authorizationRequired={true}>
                    <AddEstimate />
                 </PrivateRoute></ErrorBoundary>
                } /> 

                <Route path="/addestimate/:id" element={
                  <ErrorBoundary>
                    <PrivateRoute authenticationRequired={true} authorizationRequired={true}>
                    <AddEstimate />
                 </PrivateRoute></ErrorBoundary>
                } />    

                <Route path="/editestimate/:id" element={
                  <ErrorBoundary>
                    <PrivateRoute authenticationRequired={true} authorizationRequired={true}>
                    <AddEstimate />
                 </PrivateRoute></ErrorBoundary>
                } />     



                {/*  pos form    */}
                <Route path="view/POSform" element={
                  <ErrorBoundary>
                    <PrivateRoute authenticationRequired={true} authorizationRequired={true}>
                    <InvoicePOS />
                 </PrivateRoute></ErrorBoundary>
                } />  

                {/* taxes & GST   */}
                  <Route path="settings/taxes&gstpage" element={
                  <ErrorBoundary>
                    <PrivateRoute authenticationRequired={true} authorizationRequired={true}>
                    <TaxesGST/>
                 </PrivateRoute></ErrorBoundary>
                } /> 

                  {/* items settings   */}
                  <Route path="settings/Items" element={
                  <ErrorBoundary>
                    <PrivateRoute authenticationRequired={true} authorizationRequired={true}>
                    <Itemsettings/>
                 </PrivateRoute></ErrorBoundary>
                } />  

                   {/* manage user settings   */}
                  <Route path="settings/users" element={
                  <ErrorBoundary>
                    <PrivateRoute authenticationRequired={true} authorizationRequired={true}>
                    <ManageUsers/>
                 </PrivateRoute></ErrorBoundary>
                } /> 
                 {/* Manage user add user   */}
                <Route path="/addusers" element={
                  <ErrorBoundary>
                    <PrivateRoute authenticationRequired={true} authorizationRequired={true}>
                    < AddUsers/>
                 </PrivateRoute></ErrorBoundary>
                } />  

               <Route path="/edititem/:id" element={
                <ErrorBoundary>
                  <PrivateRoute authenticationRequired={true} authorizationRequired={true}>
                    <CourseCreation/>
                  </PrivateRoute>
                </ErrorBoundary>
              } />


              <Route
              path="/admin/backup-shedule"
              element={
                <PrivateRoute
                  authenticationRequired={true}
                  authorizationRequired={true}
                  vpsonly={true}
                >
                  <BackupManager />
                </PrivateRoute>
              }
            />
            <Route
              path="/admin/driveCredentials"
              element={
                <PrivateRoute
                  authenticationRequired={true}
                  authorizationRequired={true}
                  vpsonly={true}
                >
                  <DriveBackupKeys />
                </PrivateRoute>
              }
            />
            <Route
              path="/restore"
              element={
                <ErrorBoundary>
                  <PrivateRoute
                    authenticationRequired={true}
                    vpsonly={true}
                     licence={true}
                    sysandadmin={true}
                  >
                  <RestorePage />
                  </PrivateRoute>
                </ErrorBoundary>
              }
            />

            {/* SysAdminRoutes */}
          </Route>
          <Route
            path="/updatePayment"
            element={
              <PrivateRoute authenticationRequired={true} onlyuser={true}>
                <UpdateStripePayment />
              </PrivateRoute>
            }
          />

          <Route
            path="/updatePaypalPayment"
            element={
              <PrivateRoute authenticationRequired={true} onlyuser={true}>
                <UpdatePaypalPayment />
              </PrivateRoute>
            }
          />
          {/* <Route
            path="/"
            element={
              <ErrorBoundary>
                <RedirectComponent vpsonly={true} checkvisible={true}>
                  {" "}
                  <ViewCourseVps
                    filter={filter}
                    handleFilterChange={handleFilterChange}
                  />
                </RedirectComponent>
              </ErrorBoundary>
            }
          /> */}
          <Route
            path="/"
            element={<Navigate to="/login" replace />}
          />
          
          <Route
            path="/login"
            element={
              <ErrorBoundary>
                <Login />
              </ErrorBoundary>
            }
          />
          <Route
            path="/refresh"
            element={
              <ErrorBoundary>
                <PrivateRoute authenticationRequired={true}>
                  <RefreshToken />
                </PrivateRoute>
              </ErrorBoundary>
            }
          />
          <Route
            path="/unauthorized"
            element={
              <ErrorBoundary>
                <Unauthorized />
              </ErrorBoundary>
            }
          />
          <Route
            path="/forgot-password"
            element={
              <ErrorBoundary>
                <ForgetPassword />
              </ErrorBoundary>
            }
          />
          <Route
            path="/RegisterInstitute"
            element={
              <ErrorBoundary>
                <RedirectComponent sasonly={true}>
                  <AdminRegister />
                </RedirectComponent>
              </ErrorBoundary>
            }
          />
          <Route
            path="/adminRegistration"
            element={
              <ErrorBoundary>
                <RedirectComponent admincount={true} vpsonly={true}>
                  <AdminRegister />
                </RedirectComponent>
              </ErrorBoundary>
            }
          />

          <Route
            path="/TrainerRegistration"
            element={
              <ErrorBoundary>
                <RedirectComponent vpsonly={true}>
                  <TrainerRegistration />
                </RedirectComponent>
              </ErrorBoundary>
            }
          />
          <Route
            path="/StudentRegistration"
            element={
              <ErrorBoundary>
                <RedirectComponent vpsonly={true}>
                  <StudentRegister />
                </RedirectComponent>
              </ErrorBoundary>
            }
          />
          <Route
            path="/LicenceExpired"
            element={
              <ErrorBoundary>
                <LicenceExpired />
              </ErrorBoundary>
            }
          />

          <Route
            path="*"
            element={
              <ErrorBoundary>
                <Missing />
              </ErrorBoundary>
            }
          />

           


        </Routes>
        <Footer />
      </div>
    </Router>
  );
}

export default App;
