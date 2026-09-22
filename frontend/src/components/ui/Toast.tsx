import React, { useEffect } from 'react';
import { CheckCircle, AlertCircle, Info, X } from 'lucide-react';

export type ToastType = 'success' | 'error' | 'info';

export interface ToastProps {
  message: string;
  type?: ToastType;
  isOpen: boolean;
  onDismiss: () => void;
  durationMs?: number;
}

export const Toast: React.FC<ToastProps> = ({
  message,
  type = 'info',
  isOpen,
  onDismiss,
  durationMs = 3000,
}) => {
  useEffect(() => {
    if (isOpen && durationMs > 0) {
      const timer = setTimeout(() => {
        onDismiss();
      }, durationMs);
      return () => clearTimeout(timer);
    }
  }, [isOpen, durationMs, onDismiss]);

  if (!isOpen) return null;

  let leftBorder = '4px solid var(--navy-400)';
  let bg = 'var(--navy-50)';
  let icon = <Info size={20} color="var(--navy-600)" />;

  if (type === 'success') {
    leftBorder = '4px solid var(--success)';
    bg = 'var(--success-bg)';
    icon = <CheckCircle size={20} color="var(--success)" />;
  } else if (type === 'error') {
    leftBorder = '4px solid var(--danger)';
    bg = 'var(--danger-bg)';
    icon = <AlertCircle size={20} color="var(--danger)" />;
  }

  return (
    <div
      style={{
        position: 'fixed',
        bottom: '80px',
        left: '50%',
        transform: 'translateX(-50%)',
        zIndex: 200,
        width: 'calc(100% - 32px)',
        maxWidth: '400px',
        backgroundColor: bg,
        borderLeft: leftBorder,
        borderRadius: '12px',
        boxShadow: 'var(--shadow-sm)',
        padding: '12px 16px',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'space-between',
        fontFamily: 'var(--font-ui)',
        fontSize: '14px',
        color: 'var(--text-primary)',
        transition: 'all 200ms ease',
      }}
    >
      <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
        {icon}
        <span>{message}</span>
      </div>
      <button
        onClick={onDismiss}
        style={{
          border: 'none',
          background: 'none',
          cursor: 'pointer',
          color: 'var(--text-secondary)',
          display: 'flex',
          alignItems: 'center',
        }}
      >
        <X size={16} />
      </button>
    </div>
  );
};
