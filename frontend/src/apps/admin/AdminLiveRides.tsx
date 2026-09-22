import React, { useState } from 'react';
import { MapView } from '../../components/ui/MapView';
import { Card } from '../../components/ui/Card';
import { Badge } from '../../components/ui/Badge';
import { formatTaka } from '../../theme/tokens';

export const AdminLiveRides: React.FC = () => {
  const [selectedRideId, setSelectedRideId] = useState('r1');

  const liveRides = [
    {
      id: 'r1',
      driver: 'মো: রফিকুল ইসলাম (Toyota Premio)',
      passenger: 'তানভীর আহমেদ',
      route: 'গুলশান ২ ➔ ধানমন্ডি ৩২',
      fare: 185,
      eta: '১২ মি',
      status: 'intrip',
    },
    {
      id: 'r2',
      driver: 'আব্দুস সালাম (Yamaha FZ)',
      passenger: 'মেহেদী হাসান',
      route: 'উত্তরা সেক্টর ৩ ➔ বিমানবন্দর',
      fare: 95,
      eta: '৫ মি',
      status: 'pickup',
    },
    {
      id: 'r3',
      driver: 'কামাল হোসেন (Honda Livo)',
      passenger: 'সাদিয়া পারভীন',
      route: 'মহাখালী ➔ ফার্মগেট',
      fare: 110,
      eta: '৮ মি',
      status: 'intrip',
    },
  ];

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '16px', height: 'calc(100vh - 120px)' }}>
      <h2 style={{ fontSize: '22px', fontWeight: 600, color: 'var(--text-primary)' }}>
        লাইভ রাইড মনিটরিং (Real-Time Fleet View)
      </h2>

      {/* Split Desktop Layout: Left 40% List, Right 60% Map */}
      <div style={{ display: 'flex', gap: '16px', flex: 1, overflow: 'hidden' }}>
        {/* Left 40% Active Rides List */}
        <div style={{ width: '40%', display: 'flex', flexDirection: 'column', gap: '12px', overflowY: 'auto' }}>
          {liveRides.map((ride) => {
            const isSelected = selectedRideId === ride.id;
            return (
              <Card
                key={ride.id}
                interactive
                onClick={() => setSelectedRideId(ride.id)}
                style={{
                  borderColor: isSelected ? 'var(--navy-900)' : 'var(--border-default)',
                  borderWidth: isSelected ? '2px' : '1px',
                  backgroundColor: isSelected ? 'var(--navy-50)' : 'var(--surface)',
                }}
              >
                <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '4px' }}>
                  <Badge variant={ride.status === 'intrip' ? 'online' : 'pending'} label={ride.status === 'intrip' ? 'চলমান রাইড' : 'পিকআপের পথে'} />
                  <span className="font-num" style={{ fontSize: '16px', fontWeight: 600, color: 'var(--amber-600)' }}>
                    {formatTaka(ride.fare)}
                  </span>
                </div>

                <div style={{ fontSize: '15px', fontWeight: 600, color: 'var(--text-primary)', marginTop: '4px' }}>
                  {ride.route}
                </div>

                <div style={{ fontSize: '13px', color: 'var(--text-secondary)', marginTop: '4px' }}>
                  ড্রাইভার: {ride.driver}
                </div>
                <div style={{ fontSize: '13px', color: 'var(--text-secondary)' }}>
                  যাত্রী: {ride.passenger} • ETA: {ride.eta}
                </div>
              </Card>
            );
          })}
        </div>

        {/* Right 60% Map View */}
        <div style={{ width: '60%', borderRadius: '12px', overflow: 'hidden', border: '1px solid var(--border-default)' }}>
          <MapView height="100%" showDriver showRoute />
        </div>
      </div>
    </div>
  );
};
