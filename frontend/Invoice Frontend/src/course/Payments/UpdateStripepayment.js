import axios from 'axios';
import React, { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import MySwal from 'sweetalert2';
import baseUrl from '../../api/utils';

const UpdateStripePayment = () => {
  const sessionId = sessionStorage.getItem("sessionId");
  const token = sessionStorage.getItem("token");
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null); // State for error
  const navigate = useNavigate();

  const copyToClipboard = (text) => {
    navigator.clipboard.writeText(text);
    MySwal.fire({
      title: "Copied!",
      text: "Session ID copied to clipboard.",
      icon: "success",
      confirmButtonText: "OK",
    });
  };

  useEffect(() => {
    const updatePayment = async () => {
      try {
        setLoading(true);

        if (token && sessionId) {
          const response = await axios.post(
            `${baseUrl}/buyCourse/updateStripepaymentid`,
            { sessionId },
            {
              headers: {
                'Content-Type': 'application/json',
                'Authorization': token,
              },
            }
          );

          const data = response.data;
          sessionStorage.removeItem("sessionId");

          MySwal.fire({
            title: "Saved!",
            text: "Payment details updated successfully.",
            icon: "success",
            confirmButtonText: "OK",
          }).then(() => {
           window.location.href="/mycourses"
          });
        }
      } catch (error) {
        setLoading(false);
        setError(error.response?.data || 'Failed to update payment details.');

        if (error.response && error.response.status === 404) {
          MySwal.fire({
            title: "Error!",
            text: error.response.data || 'Failed to update payment details.',
            icon: "error",
            confirmButtonText: "OK",
          });
        }
      }
    };

    updatePayment();
  }, [sessionId, navigate, token]);

  return (
    <div className='vh-100' style={{ backgroundColor: "transparent", padding: "50px" }}>
      <div className="card">
        <div className='card-body' style={{ height: "75vh" }}>
          <div className="text-center mt-5">
            {loading ? (
              <h4>Updating your payment, please do not close the window...</h4>
            ) : (
              <div>
                <h4>Error updating Payment details. Kindly contact the administrator.</h4>
                {sessionId && (
                  <div>
                    <p>
                      <strong>Session ID:</strong>{" "}
                      <span
                        style={{  cursor: "pointer", textDecoration: "underline" }}
                        onClick={() => copyToClipboard(sessionId)}
                      >
                        {sessionId}
                      </span>
                    </p>
                    <p>
                      Please copy the above <strong>Session ID</strong> and share it with the administrator for troubleshooting.
                    </p>
                  </div>
                )}
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
};

export default UpdateStripePayment;
