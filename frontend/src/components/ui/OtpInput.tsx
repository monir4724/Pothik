import React, { useState, useRef } from 'react';

export interface OtpInputProps {
  length?: number;
  onComplete?: (otp: string) => void;
  isError?: boolean;
}

export const OtpInput: React.FC<OtpInputProps> = ({ length = 6, onComplete, isError = false }) => {
  const [digits, setDigits] = useState<string[]>(Array(length).fill(''));
  const [activeIndex, setActiveIndex] = useState<number>(0);
  const inputRefs = useRef<(HTMLInputElement | null)[]>([]);

  const handleChange = (index: number, value: string) => {
    const digit = value.replace(/\D/g, '').slice(-1);
    const newDigits = [...digits];
    newDigits[index] = digit;
    setDigits(newDigits);

    if (digit && index < length - 1) {
      setActiveIndex(index + 1);
      inputRefs.current[index + 1]?.focus();
    }

    const fullOtp = newDigits.join('');
    if (fullOtp.length === length && onComplete) {
      onComplete(fullOtp);
    }
  };

  const handleKeyDown = (index: number, e: React.KeyboardEvent<HTMLInputElement>) => {
    if (e.key === 'Backspace') {
      if (!digits[index] && index > 0) {
        setActiveIndex(index - 1);
        inputRefs.current[index - 1]?.focus();
      }
    }
  };

  return (
    <div
      className={isError ? 'animate-otp-shake' : ''}
      style={{ display: 'flex', gap: '8px', justifyContent: 'center', margin: '16px 0' }}
    >
      {digits.map((digit, idx) => {
        let borderColor = 'var(--border-strong)';
        let bgColor = 'var(--surface)';

        if (isError) {
          borderColor = 'var(--danger)';
          bgColor = 'var(--danger-bg)';
        } else if (idx === activeIndex) {
          borderColor = 'var(--amber-500)';
          bgColor = 'var(--amber-50)';
        } else if (digit) {
          borderColor = 'var(--interactive-primary)';
          bgColor = 'var(--navy-50)';
        }

        return (
          <input
            key={idx}
            ref={(el) => { inputRefs.current[idx] = el; }}
            type="text"
            inputMode="numeric"
            maxLength={1}
            value={digit}
            onFocus={() => setActiveIndex(idx)}
            onChange={(e) => handleChange(idx, e.target.value)}
            onKeyDown={(e) => handleKeyDown(idx, e)}
            style={{
              width: '52px',
              height: '60px',
              borderRadius: '12px',
              border: `2px solid ${borderColor}`,
              backgroundColor: bgColor,
              textAlign: 'center',
              fontFamily: 'var(--font-num)',
              fontSize: '32px',
              fontWeight: 600,
              color: 'var(--text-primary)',
              outline: 'none',
              transition: 'border-color 150ms ease, background-color 150ms ease',
            }}
          />
        );
      })}
    </div>
  );
};
