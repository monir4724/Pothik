import React from 'react';
import { Button } from '../../components/ui/Button';

export interface PickupOtpCardProps {
  otp?: string;
  onStartRide: () => void;
}

export const PickupOtpCard: React.FC<PickupOtpCardProps> = ({ otp = '123456', onStartRide }) => {
  const digits = otp.split('');

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
        padding: '24px 20px 28px 20px',
        zIndex: 40,
        textAlign: 'center',
      }}
    >
      <div style={{ fontSize: '13px', fontWeight: 600, color: 'var(--success)', marginBottom: '4px' }}>
        ✓ ড্রাইভার পিকআপ পয়েন্টে পৌঁছেছেন
      </div>
      <h2 style={{ fontSize: '20px', fontWeight: 600, color: 'var(--text-primary)', marginBottom: '4px' }}>
        ড্রাইভারকে এই OTP দিন
      </h2>
      <p style={{ fontSize: '14px', color: 'var(--text-secondary)', marginBottom: '16px' }}>
        ড্রাইভার OTP ইনপুট দিলে ট্রিপ শুরু হবে
      </p>

      {/* Prominent OTP Digit Boxes */}
      <div style={{ display: 'flex', gap: '8px', justifyContent: 'center', marginBottom: '16px' }}>
        {digits.map((digit, index) => (
          <div
            key={index}
            style={{
              width: '48px',
              height: '56px',
              borderRadius: '12px',
              backgroundColor: 'var(--navy-50)',
              border: '2px solid var(--interactive-primary)',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              fontFamily: 'var(--font-num)',
              fontSize: '32px',
              fontWeight: 600,
              color: 'var(--navy-900)',
            }}
          >
            {digit}
          </div>
        ))}
      </div>

      <Button fullWidth onClick={onStartRide}>
        রাইড শুরু করুন (ড্রাইভার OTP ভেরিফাইড)
      </Button>
    </div>
  );
};
