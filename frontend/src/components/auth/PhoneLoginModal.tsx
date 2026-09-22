import React, { useState } from 'react';
import { Phone, ArrowRight, ShieldCheck, CheckCircle2 } from 'lucide-react';
import { Button } from '../ui/Button';
import { InputField } from '../ui/InputField';
import { OtpInput } from '../ui/OtpInput';

export interface PhoneLoginModalProps {
  role: 'passenger' | 'driver';
  onLoginSuccess: (userData: { phone: string; name: string }) => void;
  onCancel?: () => void;
}

export const PhoneLoginModal: React.FC<PhoneLoginModalProps> = ({ role, onLoginSuccess }) => {
  const [step, setStep] = useState<'phone' | 'otp' | 'name'>('phone');
  const [phone, setPhone] = useState('01521700014');
  const [name, setName] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [otpError, setOtpError] = useState(false);

  const handleSendOtp = () => {
    if (phone.length < 11) return;
    setIsLoading(true);
    setTimeout(() => {
      setIsLoading(false);
      setStep('otp');
    }, 600);
  };

  const handleVerifyOtp = (otp: string) => {
    if (otp === '123456' || otp.length === 6) {
      setOtpError(false);
      setIsLoading(true);
      setTimeout(() => {
        setIsLoading(false);
        setStep('name');
      }, 500);
    } else {
      setOtpError(true);
      setTimeout(() => setOtpError(false), 1200);
    }
  };

  const handleCompleteRegistration = () => {
    const finalName = name || (role === 'passenger' ? 'তানভীর আহমেদ' : 'মো: রফিকুল ইসলাম');
    onLoginSuccess({ phone, name: finalName });
  };

  return (
    <div
      style={{
        position: 'relative',
        width: '100%',
        height: '100%',
        backgroundColor: 'var(--surface)',
        display: 'flex',
        flexDirection: 'column',
        justifyContent: 'space-between',
        padding: '24px 20px',
      }}
    >
      <div>
        {/* Brand Header */}
        <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '24px' }}>
          <div
            style={{
              backgroundColor: 'var(--navy-900)',
              color: 'var(--amber-500)',
              fontSize: '18px',
              fontWeight: 700,
              padding: '4px 10px',
              borderRadius: '8px',
            }}
          >
            Pothik
          </div>
          <span style={{ fontSize: '14px', fontWeight: 600, color: 'var(--text-secondary)' }}>
            {role === 'passenger' ? 'যাত্রী লগইন / সাইনআপ' : 'ড্রাইভার পোর্টাল লগইন'}
          </span>
        </div>

        {/* STEP 1: PHONE INPUT */}
        {step === 'phone' && (
          <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
            <div>
              <h2 style={{ fontSize: '22px', fontWeight: 600, color: 'var(--text-primary)', marginBottom: '4px' }}>
                মোবাইল নম্বর লিখুন
              </h2>
              <p style={{ fontSize: '14px', color: 'var(--text-secondary)' }}>
                লগইন বা একাউন্ট খুলতে আপনার ১১ ডিজিটের মোবাইল নম্বর দিন।
              </p>
            </div>

            <InputField
              label="ফোন নম্বর (+880)"
              placeholder="01700-000000"
              value={phone}
              onChange={(e) => setPhone(e.target.value)}
              icon={<Phone size={20} color="var(--navy-600)" />}
              autoFocus
            />

            <Button fullWidth isLoading={isLoading} onClick={handleSendOtp}>
              OTP পাঠান <ArrowRight size={18} style={{ marginLeft: '8px' }} />
            </Button>
          </div>
        )}

        {/* STEP 2: OTP VERIFICATION */}
        {step === 'otp' && (
          <div style={{ display: 'flex', flexDirection: 'column', gap: '16px', textAlign: 'center' }}>
            <div>
              <h2 style={{ fontSize: '22px', fontWeight: 600, color: 'var(--text-primary)', marginBottom: '4px' }}>
                OTP কোড দিন
              </h2>
              <p style={{ fontSize: '14px', color: 'var(--text-secondary)' }}>
                <strong style={{ color: 'var(--navy-900)' }}>+88 {phone}</strong> নম্বরে ৬ ডিজিটের কোড পাঠানো হয়েছে।
              </p>
              <p style={{ fontSize: '12px', color: 'var(--amber-600)', fontWeight: 600, marginTop: '4px' }}>
                (পরীক্ষার জন্য টেস্ট OTP: 123456)
              </p>
            </div>

            <OtpInput length={6} isError={otpError} onComplete={handleVerifyOtp} />

            <Button fullWidth onClick={() => handleVerifyOtp('123456')}>
              টেস্ট OTP সাবমিট (123456)
            </Button>
          </div>
        )}

        {/* STEP 3: PROFILE SETUP */}
        {step === 'name' && (
          <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
            <div>
              <h2 style={{ fontSize: '22px', fontWeight: 600, color: 'var(--text-primary)', marginBottom: '4px' }}>
                আপনার নাম নিশ্চিত করুন
              </h2>
              <p style={{ fontSize: '14px', color: 'var(--text-secondary)' }}>
                রাইড বুকিং ও নিরাপত্তার জন্য আপনার এনআইডি অনুযায়ী সঠিক নাম দিন।
              </p>
            </div>

            <InputField
              label="আপনার নাম (Full Name)"
              placeholder={role === 'passenger' ? 'যেমন: তানভীর আহমেদ' : 'যেমন: মো: রফিকুল ইসলাম'}
              value={name}
              onChange={(e) => setName(e.target.value)}
              autoFocus
            />

            <Button fullWidth onClick={handleCompleteRegistration}>
              <CheckCircle2 size={18} style={{ marginRight: '8px' }} /> প্রবেশ করুন (Proceed to App)
            </Button>
          </div>
        )}
      </div>

      {/* Safety Micro-Copy */}
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '6px', fontSize: '12px', color: 'var(--text-secondary)', textAlign: 'center' }}>
        <ShieldCheck size={16} color="var(--success)" />
        <span>Pothik এন্ড-টু-এন্ড এনক্রিপ্টেড ও নিরাপদ প্ল্যাটফর্ম</span>
      </div>
    </div>
  );
};
