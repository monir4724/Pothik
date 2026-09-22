import React from 'react';
import { WifiOff } from 'lucide-react';

export interface OfflineBannerProps {
  isOffline: boolean;
}

export const OfflineBanner: React.FC<OfflineBannerProps> = ({ isOffline }) => {
  if (!isOffline) return null;

  return (
    <div
      style={{
        position: 'fixed',
        bottom: '0',
        left: '0',
        right: '0',
        zIndex: 150,
        height: '40px',
        backgroundColor: 'var(--warning-bg)',
        borderTop: '1px solid var(--warning)',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        gap: '8px',
        color: 'var(--warning)',
        fontFamily: 'var(--font-ui)',
        fontSize: '14px',
        fontWeight: 600,
      }}
    >
      <WifiOff size={16} />
      <span>ইন্টারনেট সংযোগ নেই — ডেটা সিঙ্ক করা যাচ্ছে না</span>
    </div>
  );
};
