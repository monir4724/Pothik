import React from 'react';
import { ArrowLeft, AlertTriangle } from 'lucide-react';
import { Card } from '../../components/ui/Card';
import { formatTaka } from '../../theme/tokens';

export interface DriverEarningsProps {
  onBack: () => void;
}

export const DriverEarnings: React.FC<DriverEarningsProps> = ({ onBack }) => {
  const commissionDebt = 340;

  const trips = [
    { id: 't1', time: '৩:৪৫ PM', pickup: 'গুলশান ২', dest: 'ধানমন্ডি ৩২', fare: 185, commission: 27 },
    { id: 't2', time: '১:১৫ PM', pickup: 'বনানী', dest: 'উত্তরা সেক্টর ৭', fare: 260, commission: 39 },
    { id: 't3', time: '১১:৩০ AM', pickup: 'মহাখালী', dest: 'ফার্মগেট', fare: 120, commission: 18 },
  ];

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
        <h2 style={{ fontSize: '20px', fontWeight: 600, color: 'var(--text-primary)' }}>উপার্জন ও হিসাব</h2>
      </div>

      {/* Commission Debt Warning Alert (browner, deeper warning color distinct from amber CTA) */}
      {commissionDebt > 0 && (
        <div
          style={{
            backgroundColor: 'var(--warning-bg)',
            border: '1px solid var(--warning)',
            borderRadius: '12px',
            padding: '12px 14px',
            display: 'flex',
            alignItems: 'center',
            gap: '12px',
          }}
        >
          <AlertTriangle size={24} color="var(--warning)" />
          <div>
            <div style={{ fontSize: '14px', fontWeight: 600, color: 'var(--warning)' }}>
              বকেয়া কমিশন: {formatTaka(commissionDebt)}
            </div>
            <div style={{ fontSize: '12px', color: 'var(--text-secondary)' }}>
              ৳ ৫০০ টাকা বকেয়া হলে রাইড পাওয়া সাময়িক বন্ধ হবে। বিকাশে পরিশোধ করুন।
            </div>
          </div>
        </div>
      )}

      {/* KPI Row */}
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
        <Card style={{ backgroundColor: 'var(--navy-900)', color: '#FFFFFF' }}>
          <div style={{ fontSize: '13px', opacity: 0.8 }}>আজকের মোট আয়</div>
          <div className="font-num" style={{ fontSize: '24px', fontWeight: 700, marginTop: '4px' }}>
            {formatTaka(565)}
          </div>
          <div style={{ fontSize: '12px', opacity: 0.7, marginTop: '2px' }}>৩ টি ট্রিপ</div>
        </Card>

        <Card style={{ backgroundColor: 'var(--surface)' }}>
          <div style={{ fontSize: '13px', color: 'var(--text-secondary)' }}>এই সপ্তাহের আয়</div>
          <div className="font-num" style={{ fontSize: '24px', fontWeight: 700, color: 'var(--navy-900)', marginTop: '4px' }}>
            {formatTaka(3420)}
          </div>
          <div style={{ fontSize: '12px', color: 'var(--text-secondary)', marginTop: '2px' }}>১৯ টি ট্রিপ</div>
        </Card>
      </div>

      {/* Trip List */}
      <h3 style={{ fontSize: '16px', fontWeight: 600, color: 'var(--text-primary)', marginTop: '8px' }}>
        আজকের ট্রিপ বিবরণী
      </h3>

      <div style={{ display: 'flex', flexDirection: 'column', gap: '10px' }}>
        {trips.map((t) => (
          <Card key={t.id} style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <div>
              <div style={{ fontSize: '15px', fontWeight: 600, color: 'var(--text-primary)' }}>
                {t.pickup} ➔ {t.dest}
              </div>
              <div style={{ fontSize: '12px', color: 'var(--text-secondary)' }}>
                {t.time} • কমিশন: {formatTaka(t.commission)}
              </div>
            </div>
            <div className="font-num" style={{ fontSize: '18px', fontWeight: 600, color: 'var(--success)' }}>
              +{formatTaka(t.fare)}
            </div>
          </Card>
        ))}
      </div>
    </div>
  );
};
