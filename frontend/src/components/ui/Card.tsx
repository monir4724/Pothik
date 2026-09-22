import React from 'react';

export interface CardProps extends React.HTMLAttributes<HTMLDivElement> {
  children: React.ReactNode;
  interactive?: boolean;
}

export const Card: React.FC<CardProps> = ({ children, interactive = false, className = '', style, ...props }) => {
  return (
    <div
      style={{
        backgroundColor: 'var(--surface)',
        border: '1px solid var(--border-default)',
        borderRadius: '12px',
        padding: '16px',
        cursor: interactive ? 'pointer' : 'default',
        transition: 'border-color 150ms ease, background-color 150ms ease',
        ...style,
      }}
      className={className}
      {...props}
    >
      {children}
    </div>
  );
};
