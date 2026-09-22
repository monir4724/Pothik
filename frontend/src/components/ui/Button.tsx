import React from 'react';
import { Loader2 } from 'lucide-react';

export type ButtonVariant = 'primary' | 'secondary' | 'danger';

export interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: ButtonVariant;
  isLoading?: boolean;
  fullWidth?: boolean;
  children: React.ReactNode;
}

export const Button: React.FC<ButtonProps> = ({
  variant = 'primary',
  isLoading = false,
  fullWidth = false,
  disabled = false,
  children,
  className = '',
  style,
  ...props
}) => {
  const isButtonDisabled = disabled || isLoading;

  let baseStyles: React.CSSProperties = {
    height: '48px',
    minHeight: '44px',
    minWidth: '44px',
    borderRadius: '12px',
    padding: '0 20px',
    fontFamily: 'var(--font-ui)',
    fontSize: '16px',
    fontWeight: 600,
    cursor: isButtonDisabled ? 'not-allowed' : 'pointer',
    display: 'inline-flex',
    alignItems: 'center',
    justifyContent: 'center',
    transition: 'background-color 150ms ease, border-color 150ms ease, color 150ms ease',
    width: fullWidth ? '100%' : 'auto',
    outline: 'none',
    border: 'none',
    userSelect: 'none',
  };

  if (variant === 'primary') {
    // Amber fill, navy-900 text (Section 3.4 & 7.1)
    if (isButtonDisabled) {
      baseStyles = {
        ...baseStyles,
        backgroundColor: 'var(--interactive-disabled-bg)',
        color: 'var(--interactive-disabled-text)',
      };
    } else {
      baseStyles = {
        ...baseStyles,
        backgroundColor: 'var(--interactive-accent)',
        color: 'var(--text-on-accent)',
      };
    }
  } else if (variant === 'secondary') {
    // Navy outline
    if (isButtonDisabled) {
      baseStyles = {
        ...baseStyles,
        backgroundColor: 'transparent',
        border: '1.5px solid var(--border-default)',
        color: 'var(--text-disabled)',
      };
    } else {
      baseStyles = {
        ...baseStyles,
        backgroundColor: 'transparent',
        border: '1.5px solid var(--interactive-primary)',
        color: 'var(--interactive-primary)',
      };
    }
  } else if (variant === 'danger') {
    // Red fill
    if (isButtonDisabled) {
      baseStyles = {
        ...baseStyles,
        backgroundColor: 'var(--interactive-disabled-bg)',
        color: 'var(--text-disabled)',
      };
    } else {
      baseStyles = {
        ...baseStyles,
        backgroundColor: 'var(--danger)',
        color: '#FFFFFF',
      };
    }
  }

  return (
    <button
      disabled={isButtonDisabled}
      style={{ ...baseStyles, ...style }}
      className={`pothik-btn-${variant} ${className}`}
      {...props}
    >
      {isLoading ? (
        <Loader2
          className="animate-spin"
          size={20}
          color={variant === 'primary' ? 'var(--navy-900)' : variant === 'danger' ? '#FFFFFF' : 'var(--navy-900)'}
        />
      ) : (
        children
      )}
    </button>
  );
};
