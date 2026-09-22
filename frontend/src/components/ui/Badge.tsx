import React from 'react';
import { CheckCircle2, Circle, Clock, ShieldCheck, AlertCircle } from 'lucide-react';

export type BadgeVariant = 'online' | 'offline' | 'pending' | 'verified' | 'danger';

export interface BadgeProps {
  variant: BadgeVariant;
  label?: string;
}

export const Badge: React.FC<BadgeProps> = ({ variant, label }) => {
  let bg = 'var(--gray-100)';
  let color = 'var(--text-secondary)';
  let icon = <Circle size={14} />;
  let defaultLabel = 'অফলাইন';

  if (variant === 'online') {
    bg = 'var(--success-bg)';
    color = 'var(--success)';
    icon = <CheckCircle2 size={14} color="var(--success)" />;
    defaultLabel = 'অনলাইন';
  } else if (variant === 'offline') {
    bg = 'var(--gray-100)';
    color = 'var(--text-secondary)';
    icon = <Circle size={14} color="var(--text-secondary)" />;
    defaultLabel = 'অফলাইন';
  } else if (variant === 'pending') {
    bg = 'var(--warning-bg)';
    color = 'var(--warning)';
    icon = <Clock size={14} color="var(--warning)" />;
    defaultLabel = 'পর্যালোচনা';
  } else if (variant === 'verified') {
    bg = 'var(--navy-50)';
    color = 'var(--navy-600)';
    icon = <ShieldCheck size={14} color="var(--navy-600)" />;
    defaultLabel = 'ভেরিফাইড';
  } else if (variant === 'danger') {
    bg = 'var(--danger-bg)';
    color = 'var(--danger)';
    icon = <AlertCircle size={14} color="var(--danger)" />;
    defaultLabel = 'প্রত্যাখ্যাত';
  }

  return (
    <div
      style={{
        display: 'inline-flex',
        alignItems: 'center',
        gap: '4px',
        borderRadius: '8px',
        padding: '4px 8px',
        backgroundColor: bg,
        color: color,
        fontSize: '12px',
        fontWeight: 500,
        fontFamily: 'var(--font-ui)',
        userSelect: 'none',
      }}
    >
      {icon}
      <span>{label || defaultLabel}</span>
    </div>
  );
};
