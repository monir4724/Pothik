import React, { useState, useEffect } from 'react';
import { MapPin, Navigation } from 'lucide-react';
import { Button } from '../../components/ui/Button';
import { formatTaka } from '../../theme/tokens';

export interface DriverRequestCardProps {
  destination?: string;
  pickup?: string;
  fare?: number;
  distanceKm?: number;
  onAccept: () => void;
  onDecline: () => void;
}

export const DriverRequestCard: React.FC<DriverRequestCardProps> = ({
  destination = 'ধানমন্ডি ৩২, ঢাকা',
  pickup = 'গুলশান ২ সার্কেল',
  fare = 185,
  distanceKm = 4.2,
  onAccept,
  onDecline,
}) => {
  const [secondsLeft, setSecondsLeft] = useState(25);

  useEffect(() => {
    const timer = setInterval(() => {
      setSecondsLeft((prev) => {
        if (prev <= 1) {
          clearInterval(timer);
          onDecline();
          return 0;
        }
        return prev - 1;
      });
    }, 1000);
    return () => clearInterval(timer);
  }, [onDecline]);

  const radius = 24;
  const circumference = 2 * Math.PI * radius;
  const progressPct = (secondsLeft / 25) * 100;
  const strokeDashoffset = circumference - (progressPct / 100) * circumference;

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
        zIndex: 50,
      }}
    >
      <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
        {/* Top Bar: Countdown Ring & Dominant Fare Display */}
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          {/* 56x56dp Countdown Ring */}
          <div
            style={{
              position: 'relative',
              width: '56px',
              height: '56px',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
            }}
          >
            <svg width="56" height="56" style={{ transform: 'rotate(-90deg)' }}>
              <circle cx="28" cy="28" r={radius} stroke="var(--gray-200)" strokeWidth="4" fill="none" />
              <circle
                cx="28"
                cy="28"
                r={radius}
                stroke="var(--amber-500)"
                strokeWidth="4"
                fill="none"
                strokeDasharray={circumference}
                strokeDashoffset={strokeDashoffset}
                strokeLinecap="round"
                style={{ transition: 'stroke-dashoffset 1s linear' }}
              />
            </svg>
            <span
              className="font-num"
              style={{
                position: 'absolute',
                fontSize: '18px',
                fontWeight: 600,
                color: 'var(--navy-900)',
              }}
            >
              {secondsLeft}
            </span>
          </div>

          {/* Fare + Distance — Amber 22px Inter Tabular (Dominant factor for driver) */}
          <div style={{ textAlign: 'right' }}>
            <div className="font-num" style={{ fontSize: '24px', fontWeight: 700, color: 'var(--amber-600)' }}>
              {formatTaka(fare)}
            </div>
            <div className="font-num" style={{ fontSize: '13px', color: 'var(--text-secondary)' }}>
              {distanceKm} কি.মি. • ক্যাশ
            </div>
          </div>
        </div>

        {/* Route Details */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
            <MapPin size={18} color="var(--success)" />
            <div>
              <div style={{ fontSize: '12px', color: 'var(--text-secondary)' }}>পিকআপ পয়েন্ট</div>
              <div style={{ fontSize: '15px', fontWeight: 600, color: 'var(--text-primary)' }}>{pickup}</div>
            </div>
          </div>

          <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
            <Navigation size={18} color="var(--danger)" />
            <div>
              <div style={{ fontSize: '12px', color: 'var(--text-secondary)' }}>গন্তব্য</div>
              <div style={{ fontSize: '16px', fontWeight: 600, color: 'var(--navy-900)' }}>{destination}</div>
            </div>
          </div>
        </div>

        {/* Action Button Row */}
        <div style={{ display: 'flex', gap: '12px' }}>
          <Button variant="secondary" fullWidth onClick={onDecline} style={{ flex: 1 }}>
            বাতিল (Decline)
          </Button>

          <Button variant="primary" fullWidth onClick={onAccept} style={{ flex: 2 }}>
            গ্রহণ করুন (Accept)
          </Button>
        </div>
      </div>
    </div>
  );
};
