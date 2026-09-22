import React, { useState } from 'react';
import { MapView } from '../../components/ui/MapView';
import { SosButton } from '../../components/ui/SosButton';
import { Button } from '../../components/ui/Button';
import { RatingStars } from '../../components/ui/RatingStars';
import { BottomSheet } from '../../components/ui/BottomSheet';
import { formatTaka } from '../../theme/tokens';

export interface InTripViewProps {
  pickup: string;
  destination: string;
  fare: number;
  onTripCompleted: () => void;
}

export const InTripView: React.FC<InTripViewProps> = ({
  pickup,
  destination,
  fare,
  onTripCompleted,
}) => {
  const [showRatingSheet, setShowRatingSheet] = useState(false);

  const handleFinish = () => {
    setShowRatingSheet(true);
  };

  const handleRatingSubmit = () => {
    setShowRatingSheet(false);
    onTripCompleted();
  };

  return (
    <div style={{ position: 'relative', width: '100%', height: '100%', minHeight: '640px' }}>
      {/* Active Route Map */}
      <MapView height="calc(100% - 220px)" passengerLocName={pickup} destinationLocName={destination} showRoute />

      {/* Persistent SOS Floating Action Button (1s press-and-hold) */}
      <SosButton />

      {/* Active Trip Details Bottom Bar */}
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
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <div>
              <div style={{ fontSize: '13px', color: 'var(--success)', fontWeight: 600 }}>
                • রাইড চলছ (গন্তব্যের দিকে)
              </div>
              <div style={{ fontSize: '18px', fontWeight: 600, color: 'var(--text-primary)' }}>
                গন্তব্যে পৌঁছাতে ১২ মিনিট
              </div>
            </div>

            <div className="font-num" style={{ fontSize: '24px', fontWeight: 600, color: 'var(--amber-600)' }}>
              {formatTaka(fare)}
            </div>
          </div>

          <div style={{ fontSize: '14px', color: 'var(--text-secondary)' }}>
            পিকআপ: {pickup} ➔ গন্তব্য: {destination}
          </div>

          {/* Simulate Driver Arrival at Destination */}
          <Button fullWidth onClick={handleFinish}>
            গন্তব্যে পৌঁছেছেন (রাইড সম্পন্ন)
          </Button>
        </div>
      </div>

      {/* Rating & Payment Bottom Sheet */}
      <BottomSheet isOpen={showRatingSheet} title="রাইড সম্পন্ন হয়েছে! পেমেন্ট ও রেটিং">
        <div style={{ textAlign: 'center', marginBottom: '16px' }}>
          <div style={{ fontSize: '14px', color: 'var(--text-secondary)' }}>ক্যাশ প্রদান করুন</div>
          <div className="font-num" style={{ fontSize: '36px', fontWeight: 600, color: 'var(--navy-900)' }}>
            {formatTaka(fare)}
          </div>
        </div>

        <RatingStars type="passenger" onSubmit={handleRatingSubmit} />
      </BottomSheet>
    </div>
  );
};
