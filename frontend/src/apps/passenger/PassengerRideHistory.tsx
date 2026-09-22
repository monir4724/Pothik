import React from 'react';
import { ArrowLeft, Car, Calendar } from 'lucide-react';
import { Card } from '../../components/ui/Card';
import { formatTaka } from '../../theme/tokens';
import { Button } from '../../components/ui/Button';

export interface PassengerRideHistoryProps {
  onBack: () => void;
}

export const PassengerRideHistory: React.FC<PassengerRideHistoryProps> = ({ onBack }) => {
  const rides = [
    {
      id: 'ride-1',
      date: '০৭ সেপ্টেম্বর ২০২৬, ৩:৪৫ PM',
      pickup: 'গুলশান ২ সার্কেল',
      destination: 'ধানমন্ডি ৩২, ঢাকা',
      fare: 185,
      driver: 'কাজী মো: রফিকুল ইসলাম',
      status: 'সম্পন্ন',
    },
    {
      id: 'ride-2',
      date: '০৫ সেপ্টেম্বর ২০২৬, ১১:২০ AM',
      pickup: 'মিরপুর ১০ গোলচত্বর',
      destination: 'কারওয়ান বাজার',
      fare: 140,
      driver: 'মো: জহিরুল ইসলাম',
      status: 'সম্পন্ন',
    },
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
        <h2 style={{ fontSize: '20px', fontWeight: 600, color: 'var(--text-primary)' }}>রাইড হিস্ট্রি</h2>
      </div>

      {rides.length === 0 ? (
        <div style={{ textAlign: 'center', padding: '48px 16px' }}>
          <Car size={64} color="var(--gray-300)" style={{ marginBottom: '12px' }} />
          <h3 style={{ fontSize: '18px', fontWeight: 600, color: 'var(--text-primary)' }}>কোনো যাত্রা নেই</h3>
          <p style={{ fontSize: '14px', color: 'var(--text-secondary)', marginBottom: '16px' }}>
            আপনার প্রথম রাইড বুক করুন
          </p>
          <Button onClick={onBack}>রাইড বুক করুন</Button>
        </div>
      ) : (
        <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
          {rides.map((ride) => (
            <Card key={ride.id}>
              <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '8px' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '6px', fontSize: '13px', color: 'var(--text-secondary)' }}>
                  <Calendar size={14} />
                  <span>{ride.date}</span>
                </div>
                <div className="font-num" style={{ fontSize: '18px', fontWeight: 600, color: 'var(--navy-900)' }}>
                  {formatTaka(ride.fare)}
                </div>
              </div>

              <div style={{ fontSize: '15px', fontWeight: 600, color: 'var(--text-primary)', marginBottom: '4px' }}>
                {ride.pickup} ➔ {ride.destination}
              </div>

              <div style={{ fontSize: '13px', color: 'var(--text-secondary)' }}>ড্রাইভার: {ride.driver}</div>
            </Card>
          ))}
        </div>
      )}
    </div>
  );
};
