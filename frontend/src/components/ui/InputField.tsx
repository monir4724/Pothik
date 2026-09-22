import React, { useState } from 'react';
import { AlertCircle } from 'lucide-react';

export interface InputFieldProps extends React.InputHTMLAttributes<HTMLInputElement> {
  label?: string;
  error?: string;
  helperText?: string;
  icon?: React.ReactNode;
}

export const InputField: React.FC<InputFieldProps> = ({
  label,
  error,
  helperText,
  icon,
  disabled,
  value,
  onFocus,
  onBlur,
  className = '',
  id,
  style,
  ...props
}) => {
  const [isFocused, setIsFocused] = useState(false);
  const inputId = id || `input-${Math.random().toString(36).substr(2, 9)}`;

  const handleFocus = (e: React.FocusEvent<HTMLInputElement>) => {
    setIsFocused(true);
    if (onFocus) onFocus(e);
  };

  const handleBlur = (e: React.FocusEvent<HTMLInputElement>) => {
    setIsFocused(false);
    if (onBlur) onBlur(e);
  };

  let borderColor = 'var(--border-strong)';
  let bgColor = 'var(--surface)';

  if (disabled) {
    borderColor = 'var(--border-default)';
    bgColor = 'var(--gray-50)';
  } else if (error) {
    borderColor = 'var(--danger)';
    bgColor = 'var(--danger-bg)';
  } else if (isFocused) {
    borderColor = 'var(--navy-500)';
  } else if (value) {
    borderColor = 'var(--border-default)';
  }

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '4px', width: '100%', ...style }}>
      {label && (
        <label
          htmlFor={inputId}
          style={{
            fontSize: isFocused || value ? '12px' : '14px',
            fontWeight: isFocused ? 600 : 500,
            color: error
              ? 'var(--danger)'
              : isFocused
              ? 'var(--navy-500)'
              : disabled
              ? 'var(--text-disabled)'
              : 'var(--text-secondary)',
            transition: 'all 150ms ease',
          }}
        >
          {label}
        </label>
      )}
      <div
        style={{
          position: 'relative',
          display: 'flex',
          alignItems: 'center',
          height: '52px',
          borderRadius: '12px',
          border: `${isFocused || error ? '2px' : '1px'} solid ${borderColor}`,
          backgroundColor: bgColor,
          padding: '0 16px',
          transition: 'border-color 150ms ease, background-color 150ms ease',
        }}
      >
        {icon && <div style={{ marginRight: '12px', color: 'var(--text-secondary)' }}>{icon}</div>}
        <input
          id={inputId}
          disabled={disabled}
          value={value}
          onFocus={handleFocus}
          onBlur={handleBlur}
          style={{
            width: '100%',
            height: '100%',
            border: 'none',
            outline: 'none',
            backgroundColor: 'transparent',
            fontFamily: 'var(--font-ui)',
            fontSize: '16px',
            color: disabled ? 'var(--text-disabled)' : 'var(--text-primary)',
          }}
          {...props}
        />
      </div>
      {error ? (
        <div style={{ display: 'flex', alignItems: 'center', gap: '4px', color: 'var(--danger)', fontSize: '12px' }}>
          <AlertCircle size={14} />
          <span>{error}</span>
        </div>
      ) : helperText ? (
        <span style={{ fontSize: '12px', color: 'var(--text-secondary)' }}>{helperText}</span>
      ) : null}
    </div>
  );
};
