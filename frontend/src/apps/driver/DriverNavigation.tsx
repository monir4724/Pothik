import React, { useState } from 'react';
import { Phone } from 'lucide-react';
import { Button } from '../../components/ui/Button';
import { OtpInput } from '../../components/ui/OtpInput';

export interface DriverNavigationProps {
  step: 'pickup' | 'intrip';
  pickup: string;
  destination: string;
  passengerName: string;
  onOtpVerified?: () => void;
  onArrivedDestination?: () => void;
  onCancelTrip?: () => void;
}

export const DriverNavigation: React.FC<DriverNavigationProps> = ({
  step,
  pickup,
  destination,
  passengerName,
  onOtpVerified,
  onArrivedDestination,
}) => {
  const [showOtpModal, setShowOtpModal] = useState(false);
  const [otpError, setOtpError] = useState(false);

  const handleOtpComplete = (otp: string) => {
    if (otp === '123456' || otp.length === 6) {
      setOtpError(false);
      setShowOtpModal(false);
      if (onOtpVerified) onOtpVerified();
    } else {
      setOtpError(true);
      setTimeout(() => setOtpError(false), 1000);
    }
  };

  return (
    <div
      style={{
        position: 'absolute',
        bottom: 0,
        left: 0,
        right: 0,
        backgroundColor: 'var(--surface)',
        borderTopLeftRadius: '20px',
        borderTopRightRadius: '20px',
        boxShadow: 'var(--shadow-md)',
        padding: '20px 16px 24px 16px',
        zIndex: 40,
      }}
    >
      <div style={{ display: 'flex', flexDirection: 'column', gap: '14px' }}>
        {/* Navigation Step Banner */}
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <div style={{ fontSize: '13px', fontWeight: 600, color: 'var(--navy-600)' }}>
            {step === 'pickup' ? '📍 পিকআপ পয়েন্টে যান' : '🏁 গন্তব্যে নিয়ে যান'}
          </div>

          <button
            onClick={() => alert(`📞 ${passengerName} কে কল দেওয়া হচ্ছে...`)}
            style={{
              backgroundColor: 'var(--navy-50)',
              border: 'none',
              borderRadius: '8px',
              padding: '6px 12px',
              color: 'var(--navy-900)',
              fontSize: '13px',
              fontWeight: 600,
              cursor: 'pointer',
              display: 'flex',
              alignItems: 'center',
              gap: '4px',
            }}
          >
            <Phone size={14} /> কল করুন
          </button>
        </div>

        <div style={{ fontSize: '18px', fontWeight: 600, color: 'var(--text-primary)' }}>
          {step === 'pickup' ? pickup : destination}
        </div>

        <div style={{ fontSize: '14px', color: 'var(--text-secondary)' }}>যাত্রী: {passengerName}</div>

        {step === 'pickup' ? (
          <Button fullWidth onClick={() => setShowOtpModal(true)}>
            পিকআপে পৌঁছেছি (OTP ইনপুট দিন)
          </Button>
        ) : (
          <Button fullWidth onClick={onArrivedDestination}>
            গন্তব্যে পৌঁছেছি (পেমেন্ট সংগ্রহ)
          </Button>
        )}
      </div>

      {/* OTP Verification Sheet */}
      {showOtpModal && (
        <div
          style={{
            position: 'fixed',
            inset: 0,
            zIndex: 100,
            backgroundColor: 'rgba(0,0,0,0.5)',
            display: 'flex',
            alignItems: 'flex-end',
          }}
        >
          <div
            style={{
              width: '100%',
              backgroundColor: 'var(--surface)',
              borderTopLeftRadius: '20px',
              borderTopRightRadius: '20px',
              padding: '24px 20px',
              textAlign: 'center',
            }}
          >
            <h3 style={{ fontSize: '18px', fontWeight: 600, color: 'var(--navy-900)' }}>
              যাত্রীর OTP ইনপুট দিন
            </h3>
            <p style={{ fontSize: '13px', color: 'var(--text-secondary)', marginBottom: '8px' }}>
              (পরীক্ষার জন্য সঠিক OTP: <strong style={{ color: 'var(--amber-600)' }}>123456</strong>)
            </p>

            <OtpInput length={6} isError={otpError} onComplete={handleOtpComplete} />

            <div style={{ display: 'flex', gap: '8px', marginTop: '12px' }}>
              <Button variant="secondary" fullWidth onClick={() => setShowOtpModal(false)}>
                বাতিল
              </Button>
              <Button fullWidth onClick={() => handleOtpComplete('123456')}>
                সঠিক OTP সাবমিট (123456)
              </Button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
