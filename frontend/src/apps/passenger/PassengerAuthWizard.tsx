import React, { useState, useEffect } from 'react';
import { ShieldCheck, Phone, ArrowRight, Camera, Plus, Trash2 } from 'lucide-react';
import { Card } from '../../components/ui/Card';
import { Button } from '../../components/ui/Button';
import { InputField } from '../../components/ui/InputField';
import { OtpInput } from '../../components/ui/OtpInput';

export interface PassengerAuthWizardProps {
  initialPhone?: string;
  onAuthSuccess: (passengerData: { phone: string; name: string; isNewUser: boolean }) => void;
}

export const PassengerAuthWizard: React.FC<PassengerAuthWizardProps> = ({
  initialPhone = '01521700014',
  onAuthSuccess,
}) => {
  const [step, setStep] = useState<'phone' | 'otp' | 'profile' | 'guardian'>('phone');
  const [phone, setPhone] = useState(initialPhone);
  const [name, setName] = useState('তানভীর আহমেদ');
  const [email, setEmail] = useState('tanveer@example.com');
  const [profilePhoto, setProfilePhoto] = useState<string | null>(null);

  // OTP Timer & Attempt Tracking State
  const [resendCountdown, setResendCountdown] = useState(60);
  const [canResend, setCanResend] = useState(false);
  const [otpAttempts, setOtpAttempts] = useState(0);
  const [otpError, setOtpError] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(false);

  // Guardian State
  const [guardians, setGuardians] = useState<{ name: string; phone: string; relationship: string }[]>([]);
  const [guardianName, setGuardianName] = useState('');
  const [guardianPhone, setGuardianPhone] = useState('01712345678');
  const [selectedRelationship, setSelectedRelationship] = useState('মা');

  const relationships = ['মা', 'বাবা', 'ভাই', 'বোন', 'স্বামী', 'স্ত্রী', 'বন্ধু/বান্ধবী', 'অন্যান্য'];

  useEffect(() => {
    let timer: number;
    if (step === 'otp' && resendCountdown > 0) {
      timer = window.setInterval(() => {
        setResendCountdown((prev) => prev - 1);
      }, 1000);
    } else if (resendCountdown === 0) {
      setCanResend(true);
    }
    return () => clearInterval(timer);
  }, [step, resendCountdown]);

  const handleSendOtp = () => {
    if (phone.length < 10) return;
    setIsLoading(true);
    setTimeout(() => {
      setIsLoading(false);
      setStep('otp');
      setResendCountdown(60);
      setCanResend(false);
    }, 500);
  };

  const handleVerifyOtp = (enteredOtp: string) => {
    if (enteredOtp === '123456' || enteredOtp.length === 6) {
      setOtpError(null);
      setIsLoading(true);
      setTimeout(() => {
        setIsLoading(false);
        // If phone is 01521700014, route to Profile Setup for demo
        setStep('profile');
      }, 600);
    } else {
      const newAttempts = otpAttempts + 1;
      setOtpAttempts(newAttempts);
      if (newAttempts >= 5) {
        setOtpError('বেশিবার ভুল OTP দেওয়া হয়েছে। নতুন OTP পাঠান।');
      } else {
        const remaining = 5 - newAttempts;
        setOtpError(`ভুল OTP। আর ${remaining} বার সুযোগ আছে।`);
      }
    }
  };

  const handleSaveProfile = () => {
    if (!name || name.trim().length < 2) return;
    setStep('guardian');
  };

  const handleAddGuardian = () => {
    if (!guardianName || !guardianPhone || guardians.length >= 3) return;
    setGuardians([...guardians, { name: guardianName, phone: guardianPhone, relationship: selectedRelationship }]);
    setGuardianName('');
    setGuardianPhone('01819876543');
  };

  const handleFinishOnboarding = () => {
    onAuthSuccess({
      phone: `+880${phone}`,
      name: name || 'তানভীর আহমেদ',
      isNewUser: true,
    });
  };

  return (
    <div
      style={{
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
        {/* Header Branding */}
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '24px' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
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
            <span style={{ fontSize: '13px', fontWeight: 600, color: 'var(--text-secondary)' }}>
              যাত্রী রেজিস্ট্রেশন
            </span>
          </div>

          <div style={{ fontSize: '12px', fontWeight: 600, color: 'var(--navy-600)' }}>
            {step === 'phone' && 'ধাপ ১ / ৩'}
            {step === 'otp' && 'ধাপ ২ / ৩'}
            {step === 'profile' && 'ধাপ ৩ / ৩'}
            {step === 'guardian' && 'অভিভাবক সেটআপ'}
          </div>
        </div>

        {/* STEP 1: PHONE NUMBER INPUT */}
        {step === 'phone' && (
          <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
            <div>
              <h2 style={{ fontSize: '22px', fontWeight: 600, color: 'var(--text-primary)', marginBottom: '4px' }}>
                আপনার মোবাইল নম্বর দিন
              </h2>
              <p style={{ fontSize: '14px', color: 'var(--text-secondary)' }}>
                রাইড বুক করতে ৬ ডিজিটের OTP SMS পাঠানো হবে।
              </p>
            </div>

            <InputField
              label="মোবাইল নম্বর (+880)"
              placeholder="01XXXXXXXXX"
              value={phone}
              onChange={(e) => setPhone(e.target.value)}
              icon={<Phone size={20} color="var(--navy-600)" />}
              autoFocus
            />

            <Button fullWidth isLoading={isLoading} onClick={handleSendOtp}>
              OTP পান <ArrowRight size={18} style={{ marginLeft: '8px' }} />
            </Button>
          </div>
        )}

        {/* STEP 2: 6-DIGIT OTP VERIFICATION */}
        {step === 'otp' && (
          <div style={{ display: 'flex', flexDirection: 'column', gap: '16px', textAlign: 'center' }}>
            <div>
              <h2 style={{ fontSize: '22px', fontWeight: 600, color: 'var(--text-primary)', marginBottom: '4px' }}>
                OTP কোড দিন
              </h2>
              <p style={{ fontSize: '14px', color: 'var(--text-secondary)' }}>
                <strong style={{ color: 'var(--navy-900)' }}>+880{phone}</strong> নম্বরে SMS গেছে।
              </p>
              <p style={{ fontSize: '12px', color: 'var(--amber-600)', fontWeight: 600, marginTop: '4px' }}>
                (টেস্টিং OTP: 123456)
              </p>
            </div>

            <OtpInput length={6} isError={Boolean(otpError)} onComplete={handleVerifyOtp} />

            {otpError && (
              <div style={{ fontSize: '13px', color: 'var(--danger)', fontWeight: 600 }}>
                ⚠ {otpError}
              </div>
            )}

            {/* 60s Resend Timer */}
            <div style={{ fontSize: '13px', color: 'var(--text-secondary)' }}>
              {canResend ? (
                <button
                  onClick={handleSendOtp}
                  style={{
                    border: 'none',
                    backgroundColor: 'transparent',
                    color: 'var(--navy-600)',
                    fontWeight: 600,
                    cursor: 'pointer',
                    textDecoration: 'underline',
                  }}
                >
                  আবার OTP পাঠান
                </button>
              ) : (
                <span>আবার পাঠান {resendCountdown} সেকেন্ড পর</span>
              )}
            </div>

            <Button fullWidth onClick={() => handleVerifyOtp('123456')}>
              সঠিক OTP সাবমিট (123456)
            </Button>
          </div>
        )}

        {/* STEP 3: PROFILE SETUP (NEW USER) */}
        {step === 'profile' && (
          <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
            <div>
              <h2 style={{ fontSize: '22px', fontWeight: 600, color: 'var(--text-primary)', marginBottom: '4px' }}>
                আপনার তথ্য দিন
              </h2>
              <p style={{ fontSize: '14px', color: 'var(--text-secondary)' }}>
                রাইড বুকিং ও নিরাপত্তার জন্য নাম লিখুন।
              </p>
            </div>

            {/* Photo Picker */}
            <div style={{ textAlign: 'center', marginBottom: '8px' }}>
              <div
                style={{
                  width: '80px',
                  height: '80px',
                  borderRadius: '50%',
                  backgroundColor: 'var(--navy-50)',
                  display: 'inline-flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  border: '2px solid var(--border-strong)',
                  cursor: 'pointer',
                }}
                onClick={() => setProfilePhoto('https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&auto=format&fit=crop&q=80')}
              >
                {profilePhoto ? (
                  <img src={profilePhoto} alt="Profile" style={{ width: '100%', height: '100%', borderRadius: '50%', objectFit: 'cover' }} />
                ) : (
                  <Camera size={32} color="var(--navy-600)" />
                )}
              </div>
              <div style={{ fontSize: '12px', color: 'var(--text-secondary)', marginTop: '4px' }}>
                {profilePhoto ? '✓ ছবি সিলেক্ট করা হয়েছে' : 'ছবি যোগ করুন (ঐচ্ছিক)'}
              </div>
            </div>

            <InputField
              label="আপনার পূর্ণ নাম (Required)"
              value={name}
              onChange={(e) => setName(e.target.value)}
              placeholder="যেমন: তানভীর আহমেদ"
            />

            <InputField
              label="ইমেইল এড্রেস (Optional)"
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              placeholder="tanveer@example.com"
            />

            <Button fullWidth onClick={handleSaveProfile} disabled={name.trim().length < 2}>
              সেভ করুন ও পরবর্তী <ArrowRight size={18} style={{ marginLeft: '8px' }} />
            </Button>
          </div>
        )}

        {/* STEP 4: GUARDIAN SETTING PROMPT (OPTIONAL / SKIPABLE) */}
        {step === 'guardian' && (
          <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
            <div>
              <h2 style={{ fontSize: '20px', fontWeight: 600, color: 'var(--text-primary)', marginBottom: '4px' }}>
                Emergency Contact (অভিভাবক)
              </h2>
              <p style={{ fontSize: '13px', color: 'var(--text-secondary)' }}>
                SOS ট্রিগার করলে এই নম্বরগুলোতে আপনার লাইভ লোকেশন ও রাইডের তথ্য চলে যাবে।
              </p>
            </div>

            {/* Added Guardians List */}
            {guardians.length > 0 && (
              <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
                {guardians.map((g, idx) => (
                  <Card key={idx} style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '10px 14px' }}>
                    <div>
                      <div style={{ fontSize: '14px', fontWeight: 600 }}>{g.name} ({g.relationship})</div>
                      <div className="font-num" style={{ fontSize: '12px', color: 'var(--text-secondary)' }}>{g.phone}</div>
                    </div>
                    <button
                      onClick={() => setGuardians(guardians.filter((_, i) => i !== idx))}
                      style={{ border: 'none', backgroundColor: 'transparent', color: 'var(--danger)', cursor: 'pointer' }}
                    >
                      <Trash2 size={16} />
                    </button>
                  </Card>
                ))}
              </div>
            )}

            {/* Relationship Choice Chips */}
            {guardians.length < 3 && (
              <Card style={{ display: 'flex', flexDirection: 'column', gap: '10px', padding: '14px' }}>
                <h4 style={{ fontSize: '13px', fontWeight: 600 }}>জরুরি অভিভাবক যোগ করুন</h4>

                <InputField
                  label="অভিভাবকের নাম"
                  value={guardianName}
                  onChange={(e) => setGuardianName(e.target.value)}
                  placeholder="যেমন: মো: শফিকুল ইসলাম"
                />

                <InputField
                  label="ফোন নম্বর"
                  value={guardianPhone}
                  onChange={(e) => setGuardianPhone(e.target.value)}
                  placeholder="01700-000000"
                />

                <div style={{ display: 'flex', flexWrap: 'wrap', gap: '6px' }}>
                  {relationships.map((rel) => (
                    <button
                      key={rel}
                      onClick={() => setSelectedRelationship(rel)}
                      style={{
                        padding: '4px 10px',
                        borderRadius: '6px',
                        fontSize: '12px',
                        fontWeight: 500,
                        border: selectedRelationship === rel ? 'none' : '1px solid var(--border-strong)',
                        backgroundColor: selectedRelationship === rel ? 'var(--navy-900)' : 'transparent',
                        color: selectedRelationship === rel ? '#FFF' : 'var(--text-primary)',
                        cursor: 'pointer',
                      }}
                    >
                      {rel}
                    </button>
                  ))}
                </div>

                <Button variant="secondary" onClick={handleAddGuardian} disabled={!guardianName || !guardianPhone}>
                  <Plus size={16} style={{ marginRight: '6px' }} /> যোগ করুন
                </Button>
              </Card>
            )}

            <div style={{ display: 'flex', gap: '8px' }}>
              <Button variant="secondary" fullWidth onClick={handleFinishOnboarding}>
                পরে করব (Skip)
              </Button>
              <Button fullWidth onClick={handleFinishOnboarding}>
                সম্পন্ন করুন (Finish)
              </Button>
            </div>
          </div>
        )}
      </div>

      {/* Footer Security Note */}
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '6px', fontSize: '12px', color: 'var(--text-secondary)' }}>
        <ShieldCheck size={16} color="var(--success)" />
        <span>Pothik এন্ড-টু-এন্ড এনক্রিপ্টেড ও নিরাপদ প্ল্যাটফর্ম</span>
      </div>
    </div>
  );
};
