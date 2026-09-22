import React from 'react';

export interface BottomSheetProps {
  isOpen: boolean;
  onClose?: () => void;
  title?: string;
  children: React.ReactNode;
}

export const BottomSheet: React.FC<BottomSheetProps> = ({ isOpen, onClose, title, children }) => {
  if (!isOpen) return null;

  return (
    <div
      style={{
        position: 'fixed',
        inset: 0,
        zIndex: 100,
        display: 'flex',
        flexDirection: 'column',
        justifyContent: 'flex-end',
      }}
    >
      {/* Scrim Overlay */}
      <div
        onClick={onClose}
        style={{
          position: 'absolute',
          inset: 0,
          backgroundColor: 'rgba(22, 24, 29, 0.4)',
          transition: 'opacity 300ms ease',
        }}
      />

      {/* Sheet Content */}
      <div
        style={{
          position: 'relative',
          width: '100%',
          maxHeight: '85vh',
          overflowY: 'auto',
          backgroundColor: 'var(--surface)',
          borderTopLeftRadius: '20px',
          borderTopRightRadius: '20px',
          boxShadow: 'var(--shadow-md)',
          padding: '16px 20px 24px 20px',
          transition: 'transform 300ms cubic-bezier(0.18, 0.89, 0.32, 1.28)',
        }}
      >
        {/* Drag Handle */}
        <div style={{ display: 'flex', justifyContent: 'center', marginBottom: '12px' }}>
          <div
            style={{
              width: '36px',
              height: '4px',
              borderRadius: '2px',
              backgroundColor: 'var(--gray-300)',
            }}
          />
        </div>

        {title && (
          <h3 style={{ fontSize: '18px', fontWeight: 600, color: 'var(--text-primary)', marginBottom: '12px' }}>
            {title}
          </h3>
        )}

        {children}
      </div>
    </div>
  );
};
