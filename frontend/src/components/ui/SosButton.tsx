import React, { useState, useRef, useEffect } from 'react';
import { ShieldAlert, AlertTriangle } from 'lucide-react';
import { BottomSheet } from './BottomSheet';
import { Button } from './Button';

export interface SosButtonProps {
  onSosTriggered?: () => void;
}

export const SosButton: React.FC<SosButtonProps> = ({ onSosTriggered }) => {
  const [isHolding, setIsHolding] = useState(false);
  const [progress, setProgress] = useState(0); // 0 to 100
  const [showConfirmSheet, setShowConfirmSheet] = useState(false);
  const [autoSendCountdown, setAutoSendCountdown] = useState<number | null>(null);

  const holdIntervalRef = useRef<number | null>(null);
  const countdownIntervalRef = useRef<number | null>(null);

  const startHold = () => {
    setIsHolding(true);
    setProgress(0);
    const startTime = Date.now();

    holdIntervalRef.current = window.setInterval(() => {
      const elapsed = Date.now() - startTime;
      const pct = Math.min(100, (elapsed / 1000) * 100);
      setProgress(pct);

      if (pct >= 100) {
        clearInterval(holdIntervalRef.current!);
        setIsHolding(false);
        triggerSosConfirmation();
      }
    }, 20);
  };

  const cancelHold = () => {
    if (holdIntervalRef.current) {
      clearInterval(holdIntervalRef.current);
    }
    setIsHolding(false);
    setProgress(0);
  };

  const triggerSosConfirmation = () => {
    if (navigator.vibrate) {
      navigator.vibrate([100, 50, 100]);
    }
    setShowConfirmSheet(true);
    setAutoSendCountdown(5);
  };

  useEffect(() => {
    if (autoSendCountdown !== null && autoSendCountdown > 0) {
      countdownIntervalRef.current = window.setInterval(() => {
        setAutoSendCountdown((prev) => (prev !== null && prev > 1 ? prev - 1 : 0));
      }, 1000);
      return () => {
        if (countdownIntervalRef.current) clearInterval(countdownIntervalRef.current);
      };
    } else if (autoSendCountdown === 0) {
      sendSosNow();
    }
  }, [autoSendCountdown]);

  const sendSosNow = () => {
    if (countdownIntervalRef.current) clearInterval(countdownIntervalRef.current);
    setAutoSendCountdown(null);
    setShowConfirmSheet(false);
    if (onSosTriggered) onSosTriggered();
    alert('🚨 SOS পাঠানো হয়েছে! অভিভাবক ও জরুরি পরিষেবায় বার্তা পৌঁছেছে।');
  };

  const radius = 26;
  const circumference = 2 * Math.PI * radius;
  const strokeDashoffset = circumference - (progress / 100) * circumference;

  return (
    <>
      <div
        onMouseDown={startHold}
        onMouseUp={cancelHold}
        onMouseLeave={cancelHold}
        onTouchStart={startHold}
        onTouchEnd={cancelHold}
        aria-label="Emergency SOS - Hold for 1 second"
        style={{
          position: 'fixed',
          bottom: '24px',
          right: '16px',
          zIndex: 90,
          width: '56px',
          height: '56px',
          borderRadius: '50%',
          backgroundColor: 'var(--danger)',
          boxShadow: 'var(--shadow-fab)',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          cursor: 'pointer',
          userSelect: 'none',
          touchAction: 'none',
        }}
      >
        {/* Hold Progress Ring Overlay */}
        <svg
          width="56"
          height="56"
          style={{ position: 'absolute', top: 0, left: 0, transform: 'rotate(-90deg)' }}
        >
          <circle
            cx="28"
            cy="28"
            r={radius}
            stroke="white"
            strokeWidth="4"
            fill="transparent"
            strokeDasharray={circumference}
            strokeDashoffset={strokeDashoffset}
            strokeLinecap="round"
            style={{ transition: isHolding ? 'stroke-dashoffset 20ms linear' : 'stroke-dashoffset 150ms ease-out' }}
          />
        </svg>

        <ShieldAlert size={24} color="#FFFFFF" />
      </div>

      {/* SOS Confirmation Sheet */}
      <BottomSheet isOpen={showConfirmSheet} onClose={() => setShowConfirmSheet(false)}>
        <div
          style={{
            backgroundColor: 'var(--danger-bg)',
            border: '1px solid var(--danger)',
            borderRadius: '12px',
            padding: '16px',
            textAlign: 'center',
            marginBottom: '16px',
          }}
        >
          <div style={{ display: 'flex', justifyContent: 'center', marginBottom: '8px' }}>
            <AlertTriangle size={40} color="var(--danger)" />
          </div>
          <h2 style={{ fontSize: '20px', fontWeight: 600, color: 'var(--danger)', marginBottom: '4px' }}>
            SOS সংকেত পাঠান?
          </h2>
          <p style={{ fontSize: '14px', color: 'var(--text-primary)', marginBottom: '8px' }}>
            আপনার সরাসরি লাইভ লোকেশন ও রাইডের তথ্য নিবন্ধিত অভিভাবক এবং Pothik হেল্পডেস্কে চলে যাবে।
          </p>

          {autoSendCountdown !== null && autoSendCountdown > 0 && (
            <div style={{ fontSize: '13px', fontWeight: 600, color: 'var(--danger)' }}>
              {autoSendCountdown} সেকেন্ডে স্বয়ংক্রিয়ভাবে SOS পাঠানো হবে...
            </div>
          )}
        </div>

        <div style={{ display: 'flex', gap: '12px' }}>
          <Button
            variant="secondary"
            fullWidth
            onClick={() => {
              setShowConfirmSheet(false);
              setAutoSendCountdown(null);
            }}
          >
            বাতিল করুন
          </Button>
          <Button variant="danger" fullWidth onClick={sendSosNow}>
            এখনই SOS পাঠান
          </Button>
        </div>
      </BottomSheet>
    </>
  );
};
