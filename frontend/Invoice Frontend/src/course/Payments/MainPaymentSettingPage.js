import React from 'react'
import { useNavigate } from 'react-router-dom';
import ErrorBoundary from '../../ErrorBoundary';
import Razorpay_Settings from './Razorpay_Settings';
import StripeKeys from './StripeKeys';
import Enablepayments from './Enablepayments.js';
import PaypalSettings from './PaypalSettings.js';

const MainPaymentSettingPage = () => {
    const navigate = useNavigate();
  return (
    <div>
    <div className="page-header"></div>
    <ErrorBoundary>
      <Enablepayments/>
    </ErrorBoundary>
    <ErrorBoundary>
        <Razorpay_Settings/>
    </ErrorBoundary>
    <ErrorBoundary>
        <StripeKeys/>
    </ErrorBoundary>
    <ErrorBoundary>
      <PaypalSettings/>
    </ErrorBoundary>
    </div>
  )
}

export default MainPaymentSettingPage