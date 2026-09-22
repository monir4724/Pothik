import React, { useState } from 'react';
import { Power, DollarSign, FileText } from 'lucide-react';
import { MapView } from '../../components/ui/MapView';
import { Button } from '../../components/ui/Button';
import { Badge } from '../../components/ui/Badge';
import { DriverRequestCard } from './DriverRequestCard';
import { DriverNavigation } from './DriverNavigation';
import { CashCollectionModal } from './CashCollectionModal';
import { DriverEarnings } from './DriverEarnings';
import { DriverDocUpload } from './DriverDocUpload';
import { DriverOnboardingWizard } from './DriverOnboardingWizard';

export interface DriverHomeProps {
  onOpenNotifications?: () => void;
}

export const DriverHome: React.FC<DriverHomeProps> = () => {
  const [isOnboarded, setIsOnboarded] = useState(true); // Default true for instant demo; toggleable
  const [isOnline, setIsOnline] = useState(true);
  const [driverState, setDriverState] = useState<'idle' | 'incoming' | 'pickup' | 'intrip' | 'cash' | 'earnings' | 'docs'>('idle');

  const toggleOnline = () => {
    setIsOnline(!isOnline);
    if (!isOnline) {
      setDriverState('idle');
    }
  };

  if (!isOnboarded) {
    return (
      <DriverOnboardingWizard
        initialStep="personal"
        onCompleteOnboarding={() => setIsOnboarded(true)}
      />
    );
  }

  return (
    <div style={{ position: 'relative', width: '100%', height: '100%', minHeight: '640px', backgroundColor: 'var(--bg)' }}>
      {/* Top Header Bar */}
      <div
        style={{
          position: 'absolute',
          top: 0,
          left: 0,
          right: 0,
          zIndex: 30,
          backgroundColor: 'var(--navy-900)',
          color: '#FFFFFF',
          padding: '12px 16px',
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          boxShadow: 'var(--shadow-sm)',
        }}
      >
        <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
          <Badge variant={isOnline ? 'online' : 'offline'} label={isOnline ? 'অনলাইন' : 'অফলাইন'} />
        </div>

        <div style={{ display: 'flex', gap: '8px' }}>
          <button
            onClick={() => setIsOnboarded(false)}
            style={{
              backgroundColor: 'rgba(255, 255, 255, 0.15)',
              border: 'none',
              borderRadius: '8px',
              padding: '6px 10px',
              color: 'var(--amber-400)',
              fontSize: '12px',
              fontWeight: 600,
              cursor: 'pointer',
            }}
          >
            অনবোর্ডিং উইজার্ড
          </button>

          <button
            onClick={() => setDriverState('earnings')}
            style={{
              backgroundColor: 'rgba(255, 255, 255, 0.15)',
              border: 'none',
              borderRadius: '8px',
              padding: '6px 12px',
              color: '#FFFFFF',
              fontSize: '13px',
              fontWeight: 600,
              cursor: 'pointer',
              display: 'flex',
              alignItems: 'center',
              gap: '4px',
            }}
          >
            <DollarSign size={16} /> আয়
          </button>

          <button
            onClick={() => setDriverState('docs')}
            style={{
              backgroundColor: 'rgba(255, 255, 255, 0.15)',
              border: 'none',
              borderRadius: '8px',
              padding: '6px 12px',
              color: '#FFFFFF',
              fontSize: '13px',
              fontWeight: 600,
              cursor: 'pointer',
              display: 'flex',
              alignItems: 'center',
              gap: '4px',
            }}
          >
            <FileText size={16} /> ডকুমেন্টস
          </button>
        </div>
      </div>

      {/* Driver Screen Sub-Views */}
      {driverState === 'earnings' ? (
        <DriverEarnings onBack={() => setDriverState('idle')} />
      ) : driverState === 'docs' ? (
        <DriverDocUpload onBack={() => setDriverState('idle')} />
      ) : (
        <>
          {/* Active Map */}
          <MapView height="calc(100% - 120px)" showRoute={driverState !== 'idle'} />

          {/* Online/Offline Floating Controls */}
          {driverState === 'idle' && (
            <div
              style={{
                position: 'absolute',
                bottom: '24px',
                left: '16px',
                right: '16px',
                zIndex: 30,
                display: 'flex',
                flexDirection: 'column',
                gap: '12px',
              }}
            >
              {isOnline && (
                <Button fullWidth onClick={() => setDriverState('incoming')}>
                  ⚡ সিমুলেট ইনকামিং রাইড রিকোয়েস্ট (Test 25s Card)
                </Button>
              )}

              <Button
                variant={isOnline ? 'secondary' : 'primary'}
                fullWidth
                onClick={toggleOnline}
                style={{
                  backgroundColor: isOnline ? 'var(--surface)' : 'var(--interactive-accent)',
                  borderColor: isOnline ? 'var(--danger)' : 'none',
                  color: isOnline ? 'var(--danger)' : 'var(--text-on-accent)',
                }}
              >
                <Power size={20} style={{ marginRight: '8px' }} />
                {isOnline ? 'অফলাইনে যান (Go Offline)' : 'অনলাইনে যান (Go Online)'}
              </Button>
            </div>
          )}

          {/* Incoming Request Card */}
          {driverState === 'incoming' && (
            <DriverRequestCard
              onAccept={() => setDriverState('pickup')}
              onDecline={() => setDriverState('idle')}
            />
          )}

          {/* Navigation to Pickup & OTP Verification */}
          {driverState === 'pickup' && (
            <DriverNavigation
              step="pickup"
              pickup="গুলশান ২ সার্কেল"
              destination="ধানমন্ডি ৩২"
              passengerName="রাফসান আহমেদ"
              onOtpVerified={() => setDriverState('intrip')}
            />
          )}

          {/* Navigation In-Trip */}
          {driverState === 'intrip' && (
            <DriverNavigation
              step="intrip"
              pickup="গুলশান ২ সার্কেল"
              destination="ধানমন্ডি ৩২"
              passengerName="রাফসান আহমেদ"
              onArrivedDestination={() => setDriverState('cash')}
            />
          )}

          {/* Cash Collection Modal */}
          {driverState === 'cash' && (
            <CashCollectionModal
              fare={185}
              onCashConfirmed={() => {
                setDriverState('idle');
                alert('✓ ক্যাশ পেমেন্ট নিশ্চিত করা হয়েছে! আপনার ওয়ালেটে ৳ ১৮৫ যোগ হয়েছে।');
              }}
            />
          )}
        </>
      )}
    </div>
  );
};
