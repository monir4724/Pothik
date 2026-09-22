import React, { useState } from 'react';
import { UploadCloud, Clock, AlertCircle, CheckCircle2, Camera, Image, ArrowRight, ArrowLeft } from 'lucide-react';
import { Card } from '../../components/ui/Card';
import { Button } from '../../components/ui/Button';
import { InputField } from '../../components/ui/InputField';
import { BottomSheet } from '../../components/ui/BottomSheet';

export type DriverOnboardingStep = 'personal' | 'vehicle' | 'documents' | 'pending' | 'rejected' | 'approved';

export type DocumentType = 'NID' | 'DRIVING_LICENSE' | 'VEHICLE_REGISTRATION' | 'TAX_TOKEN' | 'FITNESS_CERTIFICATE' | 'VEHICLE_PHOTO' | 'PROFILE_PHOTO';

export interface DocUploadStatus {
  type: DocumentType;
  label: string;
  subtitle: string;
  isUploaded: boolean;
  status: 'empty' | 'uploading' | 'uploaded' | 'verified' | 'rejected';
  fileUrl?: string;
  rejectNote?: string;
}

export interface DriverOnboardingWizardProps {
  initialStep?: DriverOnboardingStep;
  onCompleteOnboarding: () => void;
}

export const DriverOnboardingWizard: React.FC<DriverOnboardingWizardProps> = ({
  initialStep = 'personal',
  onCompleteOnboarding,
}) => {
  const [currentStep, setCurrentStep] = useState<DriverOnboardingStep>(initialStep);

  // Step 1: Personal Info State
  const [name, setName] = useState('কাজী মো: রফিকুল ইসলাম');
  const [dob, setDob] = useState('1992-08-15');
  const [address, setAddress] = useState('বাসা ১২, রোড ৪, ব্লক সি, মিরপুর ১০, ঢাকা');
  const [nidNumber, setNidNumber] = useState('19921598274019283');

  // Step 2: Vehicle Info State
  const [vehicleType, setVehicleType] = useState<'bike' | 'car'>('bike');
  const [vehicleMake, setVehicleMake] = useState('Honda');
  const [vehicleModel, setVehicleModel] = useState('Livo 110');
  const [vehicleYear, setVehicleYear] = useState('2022');
  const [vehicleColor, setVehicleColor] = useState('Red');
  const [licensePlate, setLicensePlate] = useState('DHAKA METRO-HA-5839');

  // Step 3: Documents State
  const [documents, setDocuments] = useState<DocUploadStatus[]>([
    { type: 'NID', label: 'জাতীয় পরিচয়পত্র (NID)', subtitle: 'NID এর সামনের ও পিছনের স্পষ্ট ছবি', isUploaded: false, status: 'empty' },
    { type: 'DRIVING_LICENSE', label: 'ড্রাইভিং লাইসেন্স', subtitle: 'মেয়াদ থাকা পেশাদার বা অপেশাদার লাইসেন্স', isUploaded: false, status: 'empty' },
    { type: 'VEHICLE_REGISTRATION', label: 'গাড়ির রেজিস্ট্রেশন কাগজ', subtitle: 'ব্লু বুক বা অফিসিয়াল রেজি কাগজ', isUploaded: false, status: 'empty' },
    { type: 'TAX_TOKEN', label: 'ট্যাক্স টোকেন', subtitle: 'চলতি বছরের আপডেট ট্যাক্স টোকেন', isUploaded: false, status: 'empty' },
    { type: 'FITNESS_CERTIFICATE', label: 'ফিটনেস সার্টিফিকেট (Car Only)', subtitle: 'গাড়ির ফিটনেস অনুমোদনপত্র', isUploaded: false, status: 'empty' },
    { type: 'VEHICLE_PHOTO', label: 'গাড়ির ছবি', subtitle: 'রেজিস্ট্রেশন নম্বর প্লেট সহ স্পষ্ট ছবি', isUploaded: false, status: 'empty' },
    { type: 'PROFILE_PHOTO', label: 'আপনার ছবি (সেলফি)', subtitle: 'সাদা ব্যাকগ্রাউন্ডে স্পষ্ট মুখের ছবি', isUploaded: false, status: 'empty' },
  ]);

  const [activePickerDoc, setActivePickerDoc] = useState<DocumentType | null>(null);
  const [globalRejectionReason, setGlobalRejectionReason] = useState<string | null>(null);

  // Required docs filter based on Vehicle Type (6 for bike, 7 for car)
  const requiredDocTypes: DocumentType[] = vehicleType === 'car'
    ? ['NID', 'DRIVING_LICENSE', 'VEHICLE_REGISTRATION', 'TAX_TOKEN', 'FITNESS_CERTIFICATE', 'VEHICLE_PHOTO', 'PROFILE_PHOTO']
    : ['NID', 'DRIVING_LICENSE', 'VEHICLE_REGISTRATION', 'TAX_TOKEN', 'VEHICLE_PHOTO', 'PROFILE_PHOTO'];

  const requiredDocs = documents.filter((d) => requiredDocTypes.includes(d.type));
  const allRequiredUploaded = requiredDocs.every((d) => d.status === 'uploaded' || d.status === 'verified');

  const handleSavePersonalInfo = () => {
    if (!name || nidNumber.length < 10) return;
    setCurrentStep('vehicle');
  };

  const handleSaveVehicleInfo = () => {
    if (!vehicleMake || !licensePlate) return;
    setCurrentStep('documents');
  };

  const handleSimulatePickImage = (type: DocumentType) => {
    setActivePickerDoc(null);
    setDocuments((prev) =>
      prev.map((d) => (d.type === type ? { ...d, status: 'uploading' } : d))
    );

    setTimeout(() => {
      setDocuments((prev) =>
        prev.map((d) =>
          d.type === type
            ? {
                ...d,
                status: 'uploaded',
                isUploaded: true,
                fileUrl: 'https://images.unsplash.com/photo-1557804506-669a67965ba0?w=400&auto=format&fit=crop&q=80',
              }
            : d
        )
      );
    }, 1200);
  };

  const handleSubmitForReview = () => {
    if (!allRequiredUploaded) return;
    setCurrentStep('pending');
  };

  return (
    <div style={{ padding: '20px 16px 28px 16px', display: 'flex', flexDirection: 'column', gap: '20px', backgroundColor: 'var(--bg)', minHeight: '100%' }}>
      {/* Brand & Step Indicator Header */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
          <div
            style={{
              backgroundColor: 'var(--navy-900)',
              color: 'var(--amber-500)',
              fontSize: '16px',
              fontWeight: 700,
              padding: '4px 10px',
              borderRadius: '8px',
            }}
          >
            Pothik Driver
          </div>
          <span style={{ fontSize: '13px', fontWeight: 600, color: 'var(--text-secondary)' }}>
            অনবোর্ডিং রেজিস্টার
          </span>
        </div>

        {/* Dynamic Progress Step Badge */}
        <div style={{ fontSize: '13px', fontWeight: 600, color: 'var(--navy-600)' }}>
          {currentStep === 'personal' && 'ধাপ ১ / ৪ (ব্যক্তিগত)'}
          {currentStep === 'vehicle' && 'ধাপ ২ / ৪ (যানবাহন)'}
          {currentStep === 'documents' && 'ধাপ ৩ / ৪ (ডকুমেন্ট)'}
          {currentStep === 'pending' && 'ধাপ ৪ / ৪ (রিভিউ)'}
        </div>
      </div>

      {/* STEP 1: PERSONAL INFO FORM */}
      {currentStep === 'personal' && (
        <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
          <div>
            <h2 style={{ fontSize: '20px', fontWeight: 600, color: 'var(--text-primary)', marginBottom: '4px' }}>
              ব্যক্তিগত তথ্য (Personal Details)
            </h2>
            <p style={{ fontSize: '13px', color: 'var(--text-secondary)' }}>
              NID অনুযায়ী আপনার সঠিক তথ্য ইনপুট দিন।
            </p>
          </div>

          <InputField
            label="পূর্ণ নাম (NID অনুযায়ী)"
            value={name}
            onChange={(e) => setName(e.target.value)}
            placeholder="যেমন: কাজী মো: রফিকুল ইসলাম"
          />

          <InputField
            label="জন্ম তারিখ (Date of Birth)"
            type="date"
            value={dob}
            onChange={(e) => setDob(e.target.value)}
          />

          <InputField
            label="বর্তমান ঠিকানা (Address)"
            value={address}
            onChange={(e) => setAddress(e.target.value)}
            placeholder="আপনার বর্তমান পূর্ণ ঠিকানা"
          />

          <InputField
            label="NID নম্বর (10 বা 17 ডিজিট)"
            value={nidNumber}
            onChange={(e) => setNidNumber(e.target.value)}
            placeholder="10 বা 17 ডিজিটের NID"
            error={nidNumber.length > 0 && nidNumber.length !== 10 && nidNumber.length !== 17 ? 'সঠিক ১০ বা ১৭ ডিজিটের NID নম্বর দিন' : undefined}
          />

          <Button fullWidth onClick={handleSavePersonalInfo} disabled={nidNumber.length !== 10 && nidNumber.length !== 17}>
            পরবর্তী (Vehicle Details) <ArrowRight size={18} style={{ marginLeft: '8px' }} />
          </Button>
        </div>
      )}

      {/* STEP 2: VEHICLE INFO FORM */}
      {currentStep === 'vehicle' && (
        <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
          <div>
            <h2 style={{ fontSize: '20px', fontWeight: 600, color: 'var(--text-primary)', marginBottom: '4px' }}>
              যানবাহনের তথ্য (Vehicle Details)
            </h2>
            <p style={{ fontSize: '13px', color: 'var(--text-secondary)' }}>
              যে গাড়ি দিয়ে Pothik প্ল্যাটফর্মে রাইড শেয়ার করবেন তার সঠিক বিবরণ দিন।
            </p>
          </div>

          {/* Vehicle Type Selector (Bike vs Car) */}
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
            <Card
              interactive
              onClick={() => setVehicleType('bike')}
              style={{
                borderColor: vehicleType === 'bike' ? 'var(--navy-900)' : 'var(--border-default)',
                borderWidth: vehicleType === 'bike' ? '2px' : '1px',
                backgroundColor: vehicleType === 'bike' ? 'var(--navy-50)' : 'var(--surface)',
                textAlign: 'center',
              }}
            >
              <div style={{ fontSize: '16px', fontWeight: 600, color: 'var(--navy-900)' }}>🏍️ Pothik Bike</div>
              <div style={{ fontSize: '12px', color: 'var(--text-secondary)', marginTop: '2px' }}>৬ টি ডকুমেন্ট লাগবে</div>
            </Card>

            <Card
              interactive
              onClick={() => setVehicleType('car')}
              style={{
                borderColor: vehicleType === 'car' ? 'var(--navy-900)' : 'var(--border-default)',
                borderWidth: vehicleType === 'car' ? '2px' : '1px',
                backgroundColor: vehicleType === 'car' ? 'var(--navy-50)' : 'var(--surface)',
                textAlign: 'center',
              }}
            >
              <div style={{ fontSize: '16px', fontWeight: 600, color: 'var(--navy-900)' }}>🚗 Pothik Car</div>
              <div style={{ fontSize: '12px', color: 'var(--text-secondary)', marginTop: '2px' }}>৭ টি ডকুমেন্ট লাগবে</div>
            </Card>
          </div>

          <InputField
            label="গাড়ির ব্র্যান্ড / মেক (Make)"
            value={vehicleMake}
            onChange={(e) => setVehicleMake(e.target.value)}
            placeholder="যেমন: Honda, Toyota, Suzuki"
          />

          <InputField
            label="গাড়ির মডেল (Model)"
            value={vehicleModel}
            onChange={(e) => setVehicleModel(e.target.value)}
            placeholder="যেমন: Livo 110, Premio"
          />

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
            <InputField
              label="মডেলের বছর (Year)"
              value={vehicleYear}
              onChange={(e) => setVehicleYear(e.target.value)}
            />
            <InputField
              label="গাড়ির রঙ (Color)"
              value={vehicleColor}
              onChange={(e) => setVehicleColor(e.target.value)}
            />
          </div>

          <InputField
            label="লাইসেন্স প্লেট নম্বর (License Plate)"
            value={licensePlate}
            onChange={(e) => setLicensePlate(e.target.value)}
            placeholder="DHAKA METRO-HA-5839"
          />

          <div style={{ display: 'flex', gap: '8px' }}>
            <Button variant="secondary" onClick={() => setCurrentStep('personal')} style={{ flex: 1 }}>
              <ArrowLeft size={16} /> পিছনে
            </Button>
            <Button onClick={handleSaveVehicleInfo} style={{ flex: 2 }}>
              পরবর্তী (Upload Docs) <ArrowRight size={18} style={{ marginLeft: '8px' }} />
            </Button>
          </div>
        </div>
      )}

      {/* STEP 3: DOCUMENT UPLOAD SCREEN */}
      {currentStep === 'documents' && (
        <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
          <div>
            <h2 style={{ fontSize: '20px', fontWeight: 600, color: 'var(--text-primary)', marginBottom: '4px' }}>
              কাগজপত্র আপলোড (Document Upload)
            </h2>
            <p style={{ fontSize: '13px', color: 'var(--text-secondary)' }}>
              {vehicleType === 'car' ? 'Car এর জন্য ফিটনেস সহ ৭ টি' : 'Bike এর জন্য ৬ টি'} স্পষ্ট নথির ছবি তুলুন।
            </p>
          </div>

          <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
            {requiredDocs.map((doc) => (
              <Card
                key={doc.type}
                style={{
                  borderColor: doc.status === 'uploaded' || doc.status === 'verified' ? 'var(--success-500)' : doc.status === 'rejected' ? 'var(--danger-500)' : 'var(--border-strong)',
                  backgroundColor: doc.status === 'uploaded' || doc.status === 'verified' ? 'var(--success-bg)' : doc.status === 'rejected' ? 'var(--danger-bg)' : 'var(--surface)',
                  borderStyle: doc.status === 'empty' ? 'dashed' : 'solid',
                }}
              >
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <div>
                    <h4 style={{ fontSize: '15px', fontWeight: 600, color: 'var(--text-primary)' }}>{doc.label}</h4>
                    <p style={{ fontSize: '12px', color: 'var(--text-secondary)', marginTop: '2px' }}>{doc.subtitle}</p>
                  </div>

                  <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                    {doc.status === 'empty' && (
                      <button
                        onClick={() => setActivePickerDoc(doc.type)}
                        style={{
                          backgroundColor: 'var(--interactive-accent)',
                          color: 'var(--text-on-accent)',
                          border: 'none',
                          borderRadius: '8px',
                          padding: '6px 12px',
                          fontSize: '13px',
                          fontWeight: 600,
                          cursor: 'pointer',
                          display: 'flex',
                          alignItems: 'center',
                          gap: '4px',
                        }}
                      >
                        <UploadCloud size={16} /> আপলোড
                      </button>
                    )}

                    {doc.status === 'uploading' && (
                      <div className="animate-spin" style={{ width: '20px', height: '20px', borderRadius: '50%', border: '2px solid var(--amber-500)', borderTopColor: 'transparent' }} />
                    )}

                    {(doc.status === 'uploaded' || doc.status === 'verified') && (
                      <div style={{ display: 'flex', alignItems: 'center', gap: '4px', color: 'var(--success)', fontSize: '13px', fontWeight: 600 }}>
                        <CheckCircle2 size={18} /> আপলোড সম্পন্ন
                      </div>
                    )}

                    {doc.status === 'rejected' && (
                      <button
                        onClick={() => setActivePickerDoc(doc.type)}
                        style={{
                          backgroundColor: 'var(--danger)',
                          color: '#FFFFFF',
                          border: 'none',
                          borderRadius: '8px',
                          padding: '6px 12px',
                          fontSize: '12px',
                          fontWeight: 600,
                          cursor: 'pointer',
                        }}
                      >
                        আবার আপলোড
                      </button>
                    )}
                  </div>
                </div>

                {doc.rejectNote && (
                  <div style={{ marginTop: '8px', fontSize: '12px', color: 'var(--danger)', fontWeight: 500 }}>
                    ⚠ প্রত্যাখ্যানের কারণ: {doc.rejectNote}
                  </div>
                )}
              </Card>
            ))}
          </div>

          <Button fullWidth disabled={!allRequiredUploaded} onClick={handleSubmitForReview}>
            আবেদন জমা দিন (Submit for Review)
          </Button>
        </div>
      )}

      {/* STEP 4: PENDING REVIEW SCREEN */}
      {currentStep === 'pending' && (
        <div style={{ textAlign: 'center', padding: '32px 16px', display: 'flex', flexDirection: 'column', gap: '20px' }}>
          <div
            style={{
              width: '80px',
              height: '80px',
              borderRadius: '50%',
              backgroundColor: 'var(--warning-bg)',
              color: 'var(--warning)',
              display: 'inline-flex',
              alignItems: 'center',
              justifyContent: 'center',
              margin: '0 auto',
            }}
          >
            <Clock size={48} />
          </div>

          <div>
            <h2 style={{ fontSize: '22px', fontWeight: 600, color: 'var(--text-primary)', marginBottom: '8px' }}>
              আবেদন রিভিউ প্রক্রিয়াধীন (Pending Review)
            </h2>
            <p style={{ fontSize: '14px', color: 'var(--text-secondary)', lineHeight: 1.5 }}>
              ২৪–৪৮ ঘণ্টার মধ্যে Pothik এডমিন টিম আপনার দেওয়া NID ও নথিপত্র যাচাই করবে। অনুমোদন হলে আপনার ফোনে নোটিফিকেশন আসবে।
            </p>
          </div>

          {/* Real-Time Document Verification Checklist */}
          <Card style={{ padding: '16px', textAlign: 'left' }}>
            <h4 style={{ fontSize: '14px', fontWeight: 600, marginBottom: '12px', color: 'var(--navy-900)' }}>
              কাগজপত্র পর্যালোচনার বিবরণ
            </h4>

            <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
              {requiredDocs.map((doc) => (
                <div key={doc.type} style={{ display: 'flex', justifyContent: 'space-between', fontSize: '13px' }}>
                  <span>{doc.label}</span>
                  <span style={{ color: 'var(--warning)', fontWeight: 600 }}>● রিভিউ অপেক্ষমাণ</span>
                </div>
              ))}
            </div>
          </Card>

          {/* Simulate Fast Admin Approval for Demo */}
          <div style={{ display: 'flex', gap: '8px', marginTop: '12px' }}>
            <Button
              variant="secondary"
              fullWidth
              onClick={() => {
                setGlobalRejectionReason('NID ও ড্রাইভিং লাইসেন্স এর ছবি আবছা দেখাচ্ছে। আবার তুলুন।');
                setCurrentStep('rejected');
              }}
            >
              সিমুলেট রিজেকশন (Reject Demo)
            </Button>

            <Button
              fullWidth
              onClick={() => {
                setCurrentStep('approved');
                onCompleteOnboarding();
              }}
            >
              সিমুলেট অ্যাপ্রুভাল (Approve Demo)
            </Button>
          </div>
        </div>
      )}

      {/* STEP 5: REJECTED SCREEN */}
      {currentStep === 'rejected' && (
        <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
          <div
            style={{
              backgroundColor: 'var(--danger-bg)',
              border: '1px solid var(--danger)',
              borderRadius: '12px',
              padding: '16px',
              textAlign: 'center',
            }}
          >
            <AlertCircle size={40} color="var(--danger)" style={{ marginBottom: '8px' }} />
            <h3 style={{ fontSize: '18px', fontWeight: 600, color: 'var(--danger)', marginBottom: '4px' }}>
              আবেদন পুনরীক্ষণ প্রয়োজন
            </h3>
            <p style={{ fontSize: '13px', color: 'var(--text-primary)' }}>
              {globalRejectionReason || 'আপনার কিছু কাগজপত্রে ত্রুটি থাকায় অনুমোদন দেওয়া সম্ভব হয়নি।'}
            </p>
          </div>

          <Button fullWidth onClick={() => setCurrentStep('documents')}>
            কাগজপত্র সংশোধন ও আবার পাঠান
          </Button>
        </div>
      )}

      {/* IMAGE PICKER BOTTOM SHEET (CAMERA / GALLERY SIMULATION) */}
      <BottomSheet isOpen={activePickerDoc !== null} onClose={() => setActivePickerDoc(null)} title="ছবি সংগ্রহ মাধ্যম নির্বাচন করুন">
        <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
          <Button variant="secondary" fullWidth onClick={() => activePickerDoc && handleSimulatePickImage(activePickerDoc)}>
            <Camera size={20} style={{ marginRight: '8px' }} /> নতুন ছবি তুলুন (Take Photo)
          </Button>
          <Button variant="secondary" fullWidth onClick={() => activePickerDoc && handleSimulatePickImage(activePickerDoc)}>
            <Image size={20} style={{ marginRight: '8px' }} /> গ্যালাডারি থেকে বেছে নিন (Choose from Gallery)
          </Button>
        </div>
      </BottomSheet>
    </div>
  );
};
