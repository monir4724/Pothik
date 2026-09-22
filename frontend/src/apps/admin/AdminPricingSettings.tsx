import React, { useState } from 'react';
import { Save, History } from 'lucide-react';
import { Card } from '../../components/ui/Card';

export interface PricingField {
  id: string;
  label: string;
  unit: string;
  value: number;
}

export const AdminPricingSettings: React.FC = () => {
  const [pricing, setPricing] = useState<PricingField[]>([
    { id: 'base', label: 'বেস ভাড়া (Base Fare)', unit: '৳', value: 40 },
    { id: 'per_km', label: 'প্রতি কি.মি. হার (Per KM Rate)', unit: '৳', value: 18 },
    { id: 'per_min', label: 'প্রতি মিনিট ওয়েটিং হার (Per Min Rate)', unit: '৳', value: 2.5 },
    { id: 'min_fare', label: 'সর্বনিম্ন ভাড়া (Minimum Fare)', unit: '৳', value: 60 },
    { id: 'surge_cap', label: 'সার্জ মাল্টিপ্লায়ার ক্যাপ (Surge Cap)', unit: '×', value: 2.0 },
    { id: 'cancel_fee', label: 'বাতিল ফি (Cancellation Fee)', unit: '৳', value: 30 },
  ]);

  const [savedFieldId, setSavedFieldId] = useState<string | null>(null);

  const auditLogs = [
    { id: 'a1', date: '০৭ সেপ্টেম্বর ২০২৬, ০৪:১৫ PM', admin: 'কামরুল হাসান', field: 'প্রতি কি.মি. হার', oldVal: '৳ ১৭', newVal: '৳ ১৮' },
    { id: 'a2', date: '০১ সেপ্টেম্বর ২০২৬, ১০:০০ AM', admin: 'মাহমুদুল হক', field: 'বেস ভাড়া', oldVal: '৳ ৩৫', newVal: '৳ ৪০' },
  ];

  const handleFieldChange = (id: string, val: number) => {
    setPricing(pricing.map((p) => (p.id === id ? { ...p, value: val } : p)));
  };

  const handleSaveField = (id: string) => {
    setSavedFieldId(id);
    setTimeout(() => setSavedFieldId(null), 2000);
  };

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '24px' }}>
      <h2 style={{ fontSize: '22px', fontWeight: 600, color: 'var(--text-primary)' }}>
        ভাড়া ও প্রাক্কলন কনফিগারেশন (Pricing Settings)
      </h2>

      {/* Per-Field Labeled Pricing Form */}
      <Card style={{ padding: '24px' }}>
        <h3 style={{ fontSize: '16px', fontWeight: 600, color: 'var(--navy-900)', marginBottom: '16px' }}>
          ঢাকা জোন পিকআপ ও রাইড রেট (Dhaka Zone MVP Rates)
        </h3>

        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '20px' }}>
          {pricing.map((field) => (
            <div
              key={field.id}
              style={{
                display: 'flex',
                flexDirection: 'column',
                gap: '6px',
                padding: '16px',
                borderRadius: '12px',
                border: '1px solid var(--border-default)',
                backgroundColor: 'var(--gray-50)',
              }}
            >
              <label style={{ fontSize: '14px', fontWeight: 600, color: 'var(--text-primary)' }}>
                {field.label}
              </label>

              <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                <div
                  style={{
                    position: 'relative',
                    flex: 1,
                    display: 'flex',
                    alignItems: 'center',
                    backgroundColor: 'var(--surface)',
                    borderRadius: '8px',
                    border: '1px solid var(--border-strong)',
                    padding: '0 12px',
                    height: '44px',
                  }}
                >
                  <span style={{ fontSize: '16px', color: 'var(--text-secondary)', marginRight: '6px' }}>
                    {field.unit}
                  </span>
                  <input
                    type="number"
                    value={field.value}
                    onChange={(e) => handleFieldChange(field.id, parseFloat(e.target.value) || 0)}
                    className="font-num"
                    style={{
                      width: '100%',
                      border: 'none',
                      outline: 'none',
                      fontSize: '16px',
                      fontWeight: 600,
                      color: 'var(--text-primary)',
                      textAlign: 'right',
                    }}
                  />
                </div>

                {/* Inline Save Text Button */}
                <button
                  onClick={() => handleSaveField(field.id)}
                  style={{
                    border: 'none',
                    backgroundColor: 'transparent',
                    color: savedFieldId === field.id ? 'var(--success)' : 'var(--navy-600)',
                    fontSize: '14px',
                    fontWeight: 600,
                    cursor: 'pointer',
                    display: 'flex',
                    alignItems: 'center',
                    gap: '4px',
                    padding: '8px 12px',
                  }}
                >
                  <Save size={16} />
                  <span>{savedFieldId === field.id ? 'Saved!' : 'Save'}</span>
                </button>
              </div>
            </div>
          ))}
        </div>
      </Card>

      {/* Read-Only Pricing Modification Audit Log */}
      <Card style={{ padding: '0', overflow: 'hidden' }}>
        <div style={{ padding: '16px 20px', backgroundColor: 'var(--gray-50)', borderBottom: '1px solid var(--border-default)', display: 'flex', alignItems: 'center', gap: '8px' }}>
          <History size={18} color="var(--text-secondary)" />
          <h3 style={{ fontSize: '16px', fontWeight: 600, color: 'var(--text-primary)' }}>ভাড়া পরিবর্তনের অডিট লগ (Audit Log)</h3>
        </div>

        <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left', fontSize: '14px' }}>
          <thead>
            <tr style={{ backgroundColor: 'var(--gray-50)', borderBottom: '1px solid var(--border-default)', color: 'var(--text-secondary)' }}>
              <th style={{ padding: '12px 16px' }}>তারিখ ও সময়</th>
              <th style={{ padding: '12px 16px' }}>অ্যাডমিন</th>
              <th style={{ padding: '12px 16px' }}>ফিল্ড</th>
              <th style={{ padding: '12px 16px' }}>পূর্বের মান</th>
              <th style={{ padding: '12px 16px' }}>নতুন মান</th>
            </tr>
          </thead>
          <tbody>
            {auditLogs.map((log) => (
              <tr key={log.id} style={{ borderBottom: '1px solid var(--border-default)' }}>
                <td style={{ padding: '14px 16px' }}>{log.date}</td>
                <td style={{ padding: '14px 16px', fontWeight: 600 }}>{log.admin}</td>
                <td style={{ padding: '14px 16px' }}>{log.field}</td>
                <td className="font-num" style={{ padding: '14px 16px', color: 'var(--danger)' }}>{log.oldVal}</td>
                <td className="font-num" style={{ padding: '14px 16px', color: 'var(--success)', fontWeight: 600 }}>{log.newVal}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </Card>
    </div>
  );
};
