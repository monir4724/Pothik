import React, { useState } from 'react';
import { Check, X, ShieldCheck } from 'lucide-react';
import { Card } from '../../components/ui/Card';
import { Button } from '../../components/ui/Button';

export interface DriverDocItem {
  id: string;
  type: string;
  name: string;
  url: string;
  status: 'pending' | 'approved' | 'rejected';
  rejectNote?: string;
}

export interface DriverApplicant {
  id: string;
  name: string;
  phone: string;
  nidNumber: string;
  address: string;
  vehicle: string;
  submittedDate: string;
  status: 'PENDING_REVIEW' | 'APPROVED' | 'REJECTED';
  rejectionReason?: string;
  docs: DriverDocItem[];
}

export const AdminDriverApproval: React.FC = () => {
  const [applicants, setApplicants] = useState<DriverApplicant[]>([
    {
      id: 'drv-101',
      name: 'কাজী মো: রফিকুল ইসলাম',
      phone: '+880 1521-700014',
      nidNumber: '19921598274019283',
      address: 'বাসা ১২, রোড ৪, ব্লক সি, মিরপুর ১০, ঢাকা',
      vehicle: 'Honda Livo 110cc • DHAKA METRO-HA-5839',
      submittedDate: '০৮ সেপ্টেম্বর ২০২৬',
      status: 'PENDING_REVIEW',
      docs: [
        { id: 'd1', type: 'NID', name: 'জাতীয় পরিচয়পত্র (NID)', url: 'https://images.unsplash.com/photo-1557804506-669a67965ba0?w=400&auto=format&fit=crop&q=80', status: 'pending' },
        { id: 'd2', type: 'DRIVING_LICENSE', name: 'ড্রাইভিং লাইসেন্স', url: 'https://images.unsplash.com/photo-1544717305-2782549b5136?w=400&auto=format&fit=crop&q=80', status: 'pending' },
        { id: 'd3', type: 'VEHICLE_REGISTRATION', name: 'গাড়ির রেজিস্ট্রেশন কাগজ', url: 'https://images.unsplash.com/photo-1568605117036-5fe5e7bab0b7?w=400&auto=format&fit=crop&q=80', status: 'pending' },
        { id: 'd4', type: 'TAX_TOKEN', name: 'ট্যাক্স টোকেন', url: 'https://images.unsplash.com/photo-1554224155-8d04cb21cd6c?w=400&auto=format&fit=crop&q=80', status: 'pending' },
        { id: 'd5', type: 'VEHICLE_PHOTO', name: 'গাড়ির ছবি (নম্বর প্লেট সহ)', url: 'https://images.unsplash.com/photo-1503376780353-7e6692767b70?w=400&auto=format&fit=crop&q=80', status: 'pending' },
        { id: 'd6', type: 'PROFILE_PHOTO', name: 'ড্রাইভারের ছবি (সেলফি)', url: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400&auto=format&fit=crop&q=80', status: 'pending' },
      ],
    },
  ]);

  const [selectedDocForReject, setSelectedDocForReject] = useState<{ applicantId: string; docId: string } | null>(null);
  const [selectedApplicantForGlobalReject, setSelectedApplicantForGlobalReject] = useState<string | null>(null);
  const [rejectionReason, setRejectionReason] = useState('');

  const handleApproveDoc = (applicantId: string, docId: string) => {
    setApplicants(
      applicants.map((app) => {
        if (app.id === applicantId) {
          return {
            ...app,
            docs: app.docs.map((d) => (d.id === docId ? { ...d, status: 'approved', rejectNote: undefined } : d)),
          };
        }
        return app;
      })
    );
  };

  const handleConfirmDocReject = () => {
    if (!selectedDocForReject || rejectionReason.length < 5) return;
    setApplicants(
      applicants.map((app) => {
        if (app.id === selectedDocForReject.applicantId) {
          return {
            ...app,
            docs: app.docs.map((d) => (d.id === selectedDocForReject.docId ? { ...d, status: 'rejected', rejectNote: rejectionReason } : d)),
          };
        }
        return app;
      })
    );
    setSelectedDocForReject(null);
    setRejectionReason('');
  };

  const handleApproveAllDriver = (applicantId: string) => {
    setApplicants(
      applicants.map((app) => {
        if (app.id === applicantId) {
          return {
            ...app,
            status: 'APPROVED',
            docs: app.docs.map((d) => ({ ...d, status: 'approved' })),
          };
        }
        return app;
      })
    );
    alert('✓ ড্রাইভার অনুমোদন সফল হয়েছে! অ্যাকাউন্ট সক্রিয় এবং ড্রাইভার পুশ নোটিফিকেশন পাঠানো হয়েছে।');
  };

  const handleConfirmGlobalReject = () => {
    if (!selectedApplicantForGlobalReject || rejectionReason.length < 10) return;
    setApplicants(
      applicants.map((app) => {
        if (app.id === selectedApplicantForGlobalReject) {
          return {
            ...app,
            status: 'REJECTED',
            rejectionReason: rejectionReason,
          };
        }
        return app;
      })
    );
    setSelectedApplicantForGlobalReject(null);
    setRejectionReason('');
    alert('✗ আবেদন প্রত্যাখ্যান করা হয়েছে এবং কারণসহ ড্রাইভারকে পুশ নোটিফিকেশন পাঠানো হয়েছে।');
  };

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '24px' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <div>
          <h2 style={{ fontSize: '22px', fontWeight: 600, color: 'var(--text-primary)' }}>
            ড্রাইভার অনবোর্ডিং ভেরিফিকেশন কিউ (Driver Review Queue)
          </h2>
          <p style={{ fontSize: '13px', color: 'var(--text-secondary)', marginTop: '2px' }}>
            আবেদনকারী ড্রাইভারদের NID, লাইসেন্স ও ডকুমেন্টস রিভিউ করে অনুমোদন বা প্রত্যাখ্যান করুন।
          </p>
        </div>
      </div>

      {applicants.map((applicant) => (
        <Card key={applicant.id} style={{ padding: '24px', position: 'relative' }}>
          {/* Header Info */}
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '16px' }}>
            <div>
              <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                <h3 style={{ fontSize: '18px', fontWeight: 600, color: 'var(--navy-900)' }}>{applicant.name}</h3>
                <span
                  style={{
                    backgroundColor: applicant.status === 'APPROVED' ? 'var(--success-bg)' : applicant.status === 'REJECTED' ? 'var(--danger-bg)' : 'var(--warning-bg)',
                    color: applicant.status === 'APPROVED' ? 'var(--success)' : applicant.status === 'REJECTED' ? 'var(--danger)' : 'var(--warning)',
                    padding: '2px 10px',
                    borderRadius: '6px',
                    fontSize: '12px',
                    fontWeight: 600,
                  }}
                >
                  {applicant.status === 'APPROVED' ? '✓ APPROVED' : applicant.status === 'REJECTED' ? '✗ REJECTED' : '● PENDING REVIEW'}
                </span>
              </div>
              <div style={{ fontSize: '14px', color: 'var(--text-secondary)', marginTop: '4px' }}>
                ফোন: <span className="font-num" style={{ fontWeight: 600 }}>{applicant.phone}</span> • NID: <span className="font-num">{applicant.nidNumber}</span>
              </div>
              <div style={{ fontSize: '14px', color: 'var(--navy-900)', fontWeight: 600, marginTop: '2px' }}>
                গাড়ি: {applicant.vehicle}
              </div>
              <div style={{ fontSize: '13px', color: 'var(--text-secondary)' }}>
                ঠিকানা: {applicant.address}
              </div>
            </div>

            <div style={{ textAlign: 'right' }}>
              <div style={{ fontSize: '12px', color: 'var(--text-secondary)', marginBottom: '8px' }}>
                আবেদনের তারিখ: {applicant.submittedDate}
              </div>

              {applicant.status === 'PENDING_REVIEW' && (
                <div style={{ display: 'flex', gap: '8px' }}>
                  <Button
                    variant="danger"
                    onClick={() => setSelectedApplicantForGlobalReject(applicant.id)}
                    style={{ padding: '0 14px', height: '40px', fontSize: '14px' }}
                  >
                    <X size={16} style={{ marginRight: '4px' }} /> Reject Application
                  </Button>

                  <Button
                    onClick={() => handleApproveAllDriver(applicant.id)}
                    style={{ padding: '0 16px', height: '40px', fontSize: '14px' }}
                  >
                    <ShieldCheck size={16} style={{ marginRight: '4px' }} /> Approve Driver
                  </Button>
                </div>
              )}
            </div>
          </div>

          {applicant.rejectionReason && (
            <div style={{ backgroundColor: 'var(--danger-bg)', border: '1px solid var(--danger)', borderRadius: '8px', padding: '10px 14px', marginBottom: '16px', color: 'var(--danger)', fontSize: '13px' }}>
              ⚠ প্রত্যাখানের বিশ্বজনীন কারণ: {applicant.rejectionReason}
            </div>
          )}

          <h4 style={{ fontSize: '14px', fontWeight: 600, color: 'var(--text-secondary)', marginBottom: '12px' }}>
            আপলোডকৃত নথিপত্র ({applicant.docs.length} টি Document)
          </h4>

          {/* Horizontal Scroll Document Image Cards (240x180dp) */}
          <div style={{ display: 'flex', gap: '16px', overflowX: 'auto', paddingBottom: '12px' }}>
            {applicant.docs.map((doc) => (
              <div
                key={doc.id}
                style={{
                  width: '240px',
                  borderRadius: '12px',
                  border: '1px solid var(--border-default)',
                  overflow: 'hidden',
                  backgroundColor: 'var(--surface)',
                  flexShrink: 0,
                  boxShadow: 'var(--shadow-sm)',
                }}
              >
                <div style={{ position: 'relative', width: '240px', height: '150px' }}>
                  <img src={doc.url} alt={doc.name} style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
                  <div
                    style={{
                      position: 'absolute',
                      top: '8px',
                      right: '8px',
                      backgroundColor: doc.status === 'approved' ? 'var(--success-bg)' : doc.status === 'rejected' ? 'var(--danger-bg)' : 'var(--warning-bg)',
                      color: doc.status === 'approved' ? 'var(--success)' : doc.status === 'rejected' ? 'var(--danger)' : 'var(--warning)',
                      padding: '2px 8px',
                      borderRadius: '6px',
                      fontSize: '11px',
                      fontWeight: 600,
                    }}
                  >
                    {doc.status === 'approved' ? '✓ VERIFIED' : doc.status === 'rejected' ? '✗ REJECTED' : '● PENDING'}
                  </div>
                </div>

                <div style={{ padding: '12px' }}>
                  <div style={{ fontSize: '13px', fontWeight: 600, color: 'var(--text-primary)', marginBottom: '6px', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
                    {doc.name}
                  </div>

                  {doc.rejectNote && (
                    <div style={{ fontSize: '11px', color: 'var(--danger)', marginBottom: '6px' }}>
                      ⚠ {doc.rejectNote}
                    </div>
                  )}

                  {applicant.status === 'PENDING_REVIEW' && (
                    <div style={{ display: 'flex', gap: '6px' }}>
                      <button
                        onClick={() => handleApproveDoc(applicant.id, doc.id)}
                        style={{
                          flex: 1,
                          padding: '6px',
                          borderRadius: '6px',
                          border: 'none',
                          backgroundColor: 'var(--success-bg)',
                          color: 'var(--success)',
                          fontWeight: 600,
                          fontSize: '12px',
                          cursor: 'pointer',
                          display: 'flex',
                          alignItems: 'center',
                          justifyContent: 'center',
                          gap: '2px',
                        }}
                      >
                        <Check size={14} /> Approve
                      </button>

                      <button
                        onClick={() => setSelectedDocForReject({ applicantId: applicant.id, docId: doc.id })}
                        style={{
                          flex: 1,
                          padding: '6px',
                          borderRadius: '6px',
                          border: 'none',
                          backgroundColor: 'var(--danger-bg)',
                          color: 'var(--danger)',
                          fontWeight: 600,
                          fontSize: '12px',
                          cursor: 'pointer',
                          display: 'flex',
                          alignItems: 'center',
                          justifyContent: 'center',
                          gap: '2px',
                        }}
                      >
                        <X size={14} /> Reject
                      </button>
                    </div>
                  )}
                </div>
              </div>
            ))}
          </div>
        </Card>
      ))}

      {/* Mandatory Document Rejection Modal */}
      {selectedDocForReject && (
        <div
          style={{
            position: 'fixed',
            inset: 0,
            zIndex: 100,
            backgroundColor: 'rgba(0,0,0,0.5)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            padding: '16px',
          }}
        >
          <div
            style={{
              width: '100%',
              maxWidth: '420px',
              backgroundColor: 'var(--surface)',
              borderRadius: '16px',
              padding: '24px',
              boxShadow: 'var(--shadow-md)',
            }}
          >
            <h3 style={{ fontSize: '18px', fontWeight: 600, color: 'var(--danger)', marginBottom: '8px' }}>
              নথিপত্র প্রত্যাখ্যান নোট (Document Reject Note)
            </h3>
            <p style={{ fontSize: '13px', color: 'var(--text-secondary)', marginBottom: '12px' }}>
              ড্রাইভার অ্যাপে এই ডকুমেন্টের নিচে সুনির্দিষ্ট কারণ প্রদর্শন করা হবে।
            </p>

            <textarea
              placeholder="যেমন: NID কার্ডের পিছনের ছবি স্পষ্ট নয়। আবার ছবি তুলে আপলোড করুন..."
              value={rejectionReason}
              onChange={(e) => setRejectionReason(e.target.value)}
              style={{
                width: '100%',
                height: '90px',
                borderRadius: '12px',
                border: '1px solid var(--border-strong)',
                padding: '12px',
                fontFamily: 'var(--font-ui)',
                fontSize: '14px',
                outline: 'none',
                resize: 'none',
                marginBottom: '16px',
              }}
            />

            <div style={{ display: 'flex', gap: '12px' }}>
              <Button variant="secondary" fullWidth onClick={() => setSelectedDocForReject(null)}>
                বাতিল
              </Button>
              <Button variant="danger" fullWidth disabled={rejectionReason.length < 5} onClick={handleConfirmDocReject}>
                রিজেক্ট নোট যোগ করুন
              </Button>
            </div>
          </div>
        </div>
      )}

      {/* Mandatory Application Rejection Modal */}
      {selectedApplicantForGlobalReject && (
        <div
          style={{
            position: 'fixed',
            inset: 0,
            zIndex: 100,
            backgroundColor: 'rgba(0,0,0,0.5)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            padding: '16px',
          }}
        >
          <div
            style={{
              width: '100%',
              maxWidth: '440px',
              backgroundColor: 'var(--surface)',
              borderRadius: '16px',
              padding: '24px',
              boxShadow: 'var(--shadow-md)',
            }}
          >
            <h3 style={{ fontSize: '18px', fontWeight: 600, color: 'var(--danger)', marginBottom: '8px' }}>
              সম্পূর্ণ আবেদন প্রত্যাখ্যান (Global Rejection)
            </h3>
            <p style={{ fontSize: '13px', color: 'var(--text-secondary)', marginBottom: '12px' }}>
              ড্রাইভার অ্যাপে প্রধান স্ট্যাটাস হিসেবে এই প্রত্যাখ্যান কারণটি দেখানো হবে (সর্বনিম্ন ১০ অক্ষর)।
            </p>

            <textarea
              placeholder="যেমন: আপনার ড্রাইভিং লাইসেন্সের মেয়াদ শেষ এবং গাড়ির রেজিস্ট্রেশনের তথ্য মেলেনি..."
              value={rejectionReason}
              onChange={(e) => setRejectionReason(e.target.value)}
              style={{
                width: '100%',
                height: '100px',
                borderRadius: '12px',
                border: '1px solid var(--border-strong)',
                padding: '12px',
                fontFamily: 'var(--font-ui)',
                fontSize: '14px',
                outline: 'none',
                resize: 'none',
                marginBottom: '16px',
              }}
            />

            <div style={{ display: 'flex', gap: '12px' }}>
              <Button variant="secondary" fullWidth onClick={() => setSelectedApplicantForGlobalReject(null)}>
                বাতিল
              </Button>
              <Button variant="danger" fullWidth disabled={rejectionReason.length < 10} onClick={handleConfirmGlobalReject}>
                আবেদন প্রত্যাখ্যান করুন
              </Button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
