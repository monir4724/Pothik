import React, { useState } from 'react';
import { ArrowLeft, UploadCloud, Clock, ShieldCheck, AlertCircle } from 'lucide-react';
import { Card } from '../../components/ui/Card';
import { Button } from '../../components/ui/Button';

export interface DriverDocUploadProps {
  onBack: () => void;
}

export type DocStatus = 'not_uploaded' | 'uploading' | 'pending' | 'verified' | 'rejected';

export interface DocItem {
  id: string;
  title: string;
  subtitle: string;
  status: DocStatus;
  rejectReason?: string;
}

export const DriverDocUpload: React.FC<DriverDocUploadProps> = ({ onBack }) => {
  const [docs, setDocs] = useState<DocItem[]>([
    {
      id: 'nid',
      title: 'জাতীয় পরিচয়পত্র (NID)',
      subtitle: 'NID এর সামনের ও পিছনের স্পষ্ট ছবি',
      status: 'verified',
    },
    {
      id: 'license',
      title: 'ড্রাইভিং লাইসেন্স (Driving License)',
      subtitle: 'মেয়াদ থাকা লাইসেন্সের ছবি',
      status: 'pending',
    },
    {
      id: 'registration',
      title: 'গাড়ির রেজিস্ট্রেশন (Vehicle Reg)',
      subtitle: 'ব্লু বুক বা রেজি ট্যাক্স টোকেন',
      status: 'rejected',
      rejectReason: 'ছবি স্পষ্ট নয় এবং মেয়াদের তারিখ আবছা। আবার তুলুন।',
    },
    {
      id: 'vehicle_photo',
      title: 'গাড়ির ছবি (Vehicle Photo)',
      subtitle: 'লাইসেন্স নম্বর প্লেট সহ সামনের ছবি',
      status: 'not_uploaded',
    },
  ]);

  const handleSimulateUpload = (id: string) => {
    setDocs(
      docs.map((doc) => {
        if (doc.id === id) {
          return { ...doc, status: 'uploading' };
        }
        return doc;
      })
    );

    setTimeout(() => {
      setDocs(
        docs.map((doc) => {
          if (doc.id === id) {
            return { ...doc, status: 'pending' };
          }
          return doc;
        })
      );
    }, 1500);
  };

  return (
    <div style={{ padding: '16px', display: 'flex', flexDirection: 'column', gap: '16px' }}>
      {/* App Bar */}
      <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
        <button
          onClick={onBack}
          style={{
            border: 'none',
            backgroundColor: 'transparent',
            cursor: 'pointer',
            padding: '8px',
            borderRadius: '50%',
            display: 'flex',
            alignItems: 'center',
          }}
        >
          <ArrowLeft size={24} color="var(--navy-900)" />
        </button>
        <h2 style={{ fontSize: '20px', fontWeight: 600, color: 'var(--text-primary)' }}>কাগজপত্র ভেরিফিকেশন</h2>
      </div>

      <p style={{ fontSize: '14px', color: 'var(--text-secondary)' }}>
        Pothik প্ল্যাটফর্মে গাড়ি চালানোর জন্য নিচের চারটি নথি ভেরিফাই করা বাধ্যতামূলক।
      </p>

      <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
        {docs.map((doc) => {
          let borderColor = 'var(--border-strong)';
          let bgColor = 'var(--surface)';
          let icon = <UploadCloud size={24} color="var(--gray-400)" />;
          let labelText = 'আপলোড করুন';

          if (doc.status === 'not_uploaded') {
            borderColor = 'var(--border-strong)';
            bgColor = 'var(--surface)';
            icon = <UploadCloud size={24} color="var(--gray-400)" />;
            labelText = 'আপলোড করুন';
          } else if (doc.status === 'uploading') {
            borderColor = 'var(--amber-500)';
            bgColor = 'var(--amber-50)';
            icon = <div className="animate-spin" style={{ width: '20px', height: '20px', borderRadius: '50%', border: '2px solid var(--amber-500)', borderTopColor: 'transparent' }} />;
            labelText = 'আপলোড হচ্ছে...';
          } else if (doc.status === 'pending') {
            borderColor = 'var(--warning-500)';
            bgColor = 'var(--warning-bg)';
            icon = <Clock size={24} color="var(--warning)" />;
            labelText = 'পর্যালোচনা হচ্ছে';
          } else if (doc.status === 'verified') {
            borderColor = 'var(--success-500)';
            bgColor = 'var(--success-bg)';
            icon = <ShieldCheck size={24} color="var(--success)" />;
            labelText = 'অনুমোদিত';
          } else if (doc.status === 'rejected') {
            borderColor = 'var(--danger-500)';
            bgColor = 'var(--danger-bg)';
            icon = <AlertCircle size={24} color="var(--danger)" />;
            labelText = 'প্রত্যাখ্যাত';
          }

          return (
            <Card
              key={doc.id}
              style={{
                borderColor: borderColor,
                backgroundColor: bgColor,
                borderStyle: doc.status === 'not_uploaded' ? 'dashed' : 'solid',
              }}
            >
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                <div>
                  <h4 style={{ fontSize: '16px', fontWeight: 600, color: 'var(--text-primary)' }}>{doc.title}</h4>
                  <p style={{ fontSize: '13px', color: 'var(--text-secondary)', marginTop: '2px' }}>
                    {doc.subtitle}
                  </p>
                </div>
                <div style={{ display: 'flex', alignItems: 'center', gap: '6px', fontSize: '13px', fontWeight: 600 }}>
                  {icon}
                  <span>{labelText}</span>
                </div>
              </div>

              {/* Rejection Details */}
              {doc.status === 'rejected' && doc.rejectReason && (
                <div style={{ marginTop: '12px', fontSize: '13px', color: 'var(--danger)' }}>
                  ⚠ {doc.rejectReason}
                </div>
              )}

              {/* Upload CTA */}
              {(doc.status === 'not_uploaded' || doc.status === 'rejected') && (
                <div style={{ marginTop: '12px' }}>
                  <Button fullWidth onClick={() => handleSimulateUpload(doc.id)}>
                    {doc.status === 'rejected' ? 'আবার আপলোড করুন' : 'ছবি তুলুন / আপলোড'}
                  </Button>
                </div>
              )}
            </Card>
          );
        })}
      </div>
    </div>
  );
};
