import React from 'react';
import { Banknote, CheckCircle } from 'lucide-react';
import { Button } from '../../components/ui/Button';
import { formatTaka } from '../../theme/tokens';

export interface CashCollectionModalProps {
  fare: number;
  onCashConfirmed: () => void;
}

export const CashCollectionModal: React.FC<CashCollectionModalProps> = ({ fare, onCashConfirmed }) => {
  return (
    <div
      style={{
        position: 'fixed',
        inset: 0,
        zIndex: 100,
        backgroundColor: 'rgba(0,0,0,0.5)',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        padding: '16px',
      }}
    >
      <div
        style={{
          width: '100%',
          maxWidth: '360px',
          backgroundColor: 'var(--surface)',
          borderRadius: '20px',
          padding: '24px 20px',
          textAlign: 'center',
          boxShadow: 'var(--shadow-md)',
        }}
      >
        <div
          style={{
            width: '64px',
            height: '64px',
            borderRadius: '50%',
            backgroundColor: 'var(--amber-50)',
            color: 'var(--amber-600)',
            display: 'inline-flex',
            alignItems: 'center',
            justifyContent: 'center',
            marginBottom: '16px',
          }}
        >
          <Banknote size={36} />
        </div>

        <h3 style={{ fontSize: '18px', fontWeight: 600, color: 'var(--text-primary)', marginBottom: '4px' }}>
          যাত্রীর কাছ থেকে ক্যাশ নিন
        </h3>
        <p style={{ fontSize: '14px', color: 'var(--text-secondary)', marginBottom: '16px' }}>
          যাত্রী ক্যাশ প্রদান করলে "ক্যাশ পেয়েছি" বাটনে চাপুন
        </p>

        {/* Hero Cash Fare Display */}
        <div
          className="font-num"
          style={{
            fontSize: '36px',
            fontWeight: 700,
            color: 'var(--navy-900)',
            marginBottom: '20px',
          }}
        >
          {formatTaka(fare)}
        </div>

        <Button fullWidth onClick={onCashConfirmed}>
          <CheckCircle size={20} style={{ marginRight: '8px' }} /> ক্যাশ পেয়েছি (Confirm Cash)
        </Button>
      </div>
    </div>
  );
};
