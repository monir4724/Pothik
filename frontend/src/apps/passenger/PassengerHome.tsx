import React, { useState } from 'react';
import { MapPin, Search, Clock, ShieldCheck } from 'lucide-react';
import { MapView } from '../../components/ui/MapView';
import { Button } from '../../components/ui/Button';
import { Card } from '../../components/ui/Card';
import { formatTaka } from '../../theme/tokens';

export interface PassengerHomeProps {
  onBookRide: (pickup: string, destination: string, fare: number) => void;
  onOpenHistory: () => void;
  onOpenGuardians: () => void;
}

export const PassengerHome: React.FC<PassengerHomeProps> = ({
  onBookRide,
  onOpenHistory,
  onOpenGuardians,
}) => {
  const [pickup, setPickup] = useState('গুলশান ২ সার্কেল (বর্তমান অবস্থান)');
  const [destination, setDestination] = useState('ধানমন্ডি ৩২, ঢাকা');
  const [selectedRideType, setSelectedRideType] = useState<'bike' | 'car'>('car');

  const fareEstimate = selectedRideType === 'car' ? 185 : 95;

  return (
    <div style={{ position: 'relative', width: '100%', height: '100%', minHeight: '640px' }}>
      {/* Map Background */}
      <MapView height="calc(100% - 280px)" passengerLocName="গুলশান ২" destinationLocName="ধানমন্ডি ৩২" />

      {/* Top Header Floating Controls */}
      <div
        style={{
          position: 'absolute',
          top: '16px',
          left: '16px',
          right: '16px',
          zIndex: 20,
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
        }}
      >
        <button
          onClick={onOpenHistory}
          style={{
            backgroundColor: 'var(--surface)',
            border: '1px solid var(--border-default)',
            borderRadius: '12px',
            padding: '10px 14px',
            fontSize: '14px',
            fontWeight: 600,
            color: 'var(--navy-900)',
            boxShadow: 'var(--shadow-sm)',
            cursor: 'pointer',
            display: 'flex',
            alignItems: 'center',
            gap: '6px',
          }}
        >
          <Clock size={16} />
          রাইড হিস্ট্রি
        </button>

        <button
          onClick={onOpenGuardians}
          style={{
            backgroundColor: 'var(--surface)',
            border: '1px solid var(--border-default)',
            borderRadius: '12px',
            padding: '10px 14px',
            fontSize: '14px',
            fontWeight: 600,
            color: 'var(--navy-900)',
            boxShadow: 'var(--shadow-sm)',
            cursor: 'pointer',
            display: 'flex',
            alignItems: 'center',
            gap: '6px',
          }}
        >
          <ShieldCheck size={16} color="var(--success)" />
          অভিভাবক সেটিংস
        </button>
      </div>

      {/* Booking Bottom Sheet Container */}
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
          padding: '20px 16px 24px 16px',
          zIndex: 30,
        }}
      >
        <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
          {/* Pickup Input */}
          <div
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: '12px',
              backgroundColor: 'var(--gray-50)',
              borderRadius: '12px',
              padding: '12px 14px',
              border: '1px solid var(--border-default)',
            }}
          >
            <MapPin size={20} color="var(--success)" />
            <input
              type="text"
              value={pickup}
              onChange={(e) => setPickup(e.target.value)}
              placeholder="পিকআপ লোকেশন"
              style={{
                width: '100%',
                border: 'none',
                backgroundColor: 'transparent',
                outline: 'none',
                fontFamily: 'var(--font-ui)',
                fontSize: '15px',
                color: 'var(--text-primary)',
              }}
            />
          </div>

          {/* Destination Input */}
          <div
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: '12px',
              backgroundColor: 'var(--gray-50)',
              borderRadius: '12px',
              padding: '12px 14px',
              border: '1px solid var(--border-default)',
            }}
          >
            <Search size={20} color="var(--danger)" />
            <input
              type="text"
              value={destination}
              onChange={(e) => setDestination(e.target.value)}
              placeholder="কোথায় যাবেন?"
              style={{
                width: '100%',
                border: 'none',
                backgroundColor: 'transparent',
                outline: 'none',
                fontFamily: 'var(--font-ui)',
                fontSize: '15px',
                color: 'var(--text-primary)',
              }}
            />
          </div>

          {/* Ride Options Selection */}
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px', marginTop: '4px' }}>
            <Card
              interactive
              onClick={() => setSelectedRideType('car')}
              style={{
                borderColor: selectedRideType === 'car' ? 'var(--navy-900)' : 'var(--border-default)',
                borderWidth: selectedRideType === 'car' ? '2px' : '1px',
                backgroundColor: selectedRideType === 'car' ? 'var(--navy-50)' : 'var(--surface)',
              }}
            >
              <div style={{ fontSize: '14px', fontWeight: 600, color: 'var(--navy-900)' }}>Pothik Car</div>
              <div style={{ fontSize: '12px', color: 'var(--text-secondary)' }}>৪ আসন • ৭ মিনিট</div>
              <div className="font-num" style={{ fontSize: '20px', fontWeight: 600, color: 'var(--amber-600)', marginTop: '4px' }}>
                {formatTaka(185)}
              </div>
            </Card>

            <Card
              interactive
              onClick={() => setSelectedRideType('bike')}
              style={{
                borderColor: selectedRideType === 'bike' ? 'var(--navy-900)' : 'var(--border-default)',
                borderWidth: selectedRideType === 'bike' ? '2px' : '1px',
                backgroundColor: selectedRideType === 'bike' ? 'var(--navy-50)' : 'var(--surface)',
              }}
            >
              <div style={{ fontSize: '14px', fontWeight: 600, color: 'var(--navy-900)' }}>Pothik Bike</div>
              <div style={{ fontSize: '12px', color: 'var(--text-secondary)' }}>১ আসন • ৪ মিনিট</div>
              <div className="font-num" style={{ fontSize: '20px', fontWeight: 600, color: 'var(--amber-600)', marginTop: '4px' }}>
                {formatTaka(95)}
              </div>
            </Card>
          </div>

          {/* Primary CTA */}
          <Button fullWidth onClick={() => onBookRide(pickup, destination, fareEstimate)}>
            রাইড বুক করুন — {formatTaka(fareEstimate)} (ক্যাশ)
          </Button>
        </div>
      </div>
    </div>
  );
};
