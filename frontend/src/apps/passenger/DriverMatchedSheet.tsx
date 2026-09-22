import React, { useState, useEffect } from 'react';
import { Phone, Clock, ShieldCheck } from 'lucide-react';
import { Button } from '../../components/ui/Button';

export interface DriverMatchedSheetProps {
  onCancelRide: () => void;
  onArrived: () => void;
}

export const DriverMatchedSheet: React.FC<DriverMatchedSheetProps> = ({ onCancelRide, onArrived }) => {
  const [cancelCountdown, setCancelCountdown] = useState(300); // 5 minutes in seconds

  useEffect(() => {
    const timer = setInterval(() => {
      setCancelCountdown((prev) => (prev > 0 ? prev - 1 : 0));
    }, 1000);
    return () => clearInterval(timer);
  }, []);

  const minutes = Math.floor(cancelCountdown / 60);
  const seconds = cancelCountdown % 60;
  const formattedCountdown = `${minutes}:${seconds < 10 ? '0' : ''}${seconds}`;

  return (
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
        zIndex: 40,
      }}
    >
      <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
        {/* ETA & Free Cancellation Chip */}
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <div
            style={{
              backgroundColor: 'var(--amber-50)',
              color: 'var(--amber-700)',
              borderRadius: '8px',
              padding: '4px 10px',
              fontSize: '13px',
              fontWeight: 600,
              display: 'flex',
              alignItems: 'center',
              gap: '6px',
            }}
          >
            <Clock size={16} />
            ৬ মিনিটে আসছে
          </div>

          <div
            style={{
              backgroundColor: cancelCountdown > 0 ? 'var(--amber-50)' : 'var(--danger-bg)',
              color: cancelCountdown > 0 ? 'var(--amber-700)' : 'var(--danger)',
              borderRadius: '8px',
              padding: '4px 10px',
              fontSize: '12px',
              fontWeight: 500,
            }}
          >
            {cancelCountdown > 0 ? `${formattedCountdown} মিনিটে বিনামূল্যে বাতিল` : 'বাতিল করলে ৳ ৫০ চার্জ হবে'}
          </div>
        </div>

        {/* Driver Profile & Vehicle Info */}
        <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
          {/* Driver Photo with Verified Shield Badge */}
          <div style={{ position: 'relative' }}>
            <img
              src="https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&auto=format&fit=crop&q=80"
              alt="Driver profile"
              style={{
                width: '64px',
                height: '64px',
                borderRadius: '50%',
                objectFit: 'cover',
                border: '2px solid var(--border-strong)',
              }}
            />
            <div
              title="Verified Driver"
              style={{
                position: 'absolute',
                bottom: 0,
                right: 0,
                width: '20px',
                height: '20px',
                borderRadius: '50%',
                backgroundColor: 'var(--navy-900)',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                boxShadow: 'var(--shadow-sm)',
              }}
            >
              <ShieldCheck size={14} color="#FFFFFF" />
            </div>
          </div>

          {/* Driver Details */}
          <div style={{ flex: 1 }}>
            <h3 style={{ fontSize: '18px', fontWeight: 600, color: 'var(--text-primary)' }}>কাজী মো: রফিকুল ইসলাম</h3>
            <div style={{ display: 'flex', alignItems: 'center', gap: '8px', fontSize: '14px', color: 'var(--text-secondary)' }}>
              <span className="font-num" style={{ fontWeight: 600, color: 'var(--amber-600)' }}>4.8 ★</span>
              <span>•</span>
              <span>৩২৮ ট্রিপ</span>
            </div>
            <div style={{ fontSize: '15px', fontWeight: 600, color: 'var(--navy-900)', marginTop: '2px' }}>
              Toyota Premio • ঢাকা মেট্রো গ-১২৩৪
            </div>
          </div>
        </div>

        {/* Action Row */}
        <div style={{ display: 'flex', gap: '12px', alignItems: 'center' }}>
          <Button variant="secondary" fullWidth style={{ flex: 2 }} onClick={() => alert('📞 ড্রাইভারকে কল দেওয়া হচ্ছে...')}>
            <Phone size={18} style={{ marginRight: '8px' }} /> কল করুন
          </Button>

          <Button variant="secondary" onClick={onArrived} style={{ flex: 2 }}>
            পিকআপে আগমন
          </Button>

          <button
            onClick={onCancelRide}
            style={{
              flex: 1,
              border: 'none',
              backgroundColor: 'transparent',
              color: 'var(--danger)',
              fontSize: '14px',
              fontWeight: 500,
              cursor: 'pointer',
              textDecoration: 'underline',
            }}
          >
            বাতিল
          </button>
        </div>
      </div>
    </div>
  );
};
