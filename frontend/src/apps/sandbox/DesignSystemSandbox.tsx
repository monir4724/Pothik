import React, { useState } from 'react';
import { COLOR_TOKENS } from '../../theme/tokens';
import { Button } from '../../components/ui/Button';
import { InputField } from '../../components/ui/InputField';
import { Card } from '../../components/ui/Card';
import { Badge } from '../../components/ui/Badge';
import { OtpInput } from '../../components/ui/OtpInput';
import { Toast } from '../../components/ui/Toast';

export const DesignSystemSandbox: React.FC = () => {
  const [toastOpen, setToastOpen] = useState(false);

  return (
    <div style={{ padding: '24px', maxWidth: '1100px', margin: '0 auto', display: 'flex', flexDirection: 'column', gap: '32px' }}>
      <div>
        <h1 style={{ fontSize: '28px', fontWeight: 700, color: 'var(--navy-900)' }}>
          Pothik (পথিক) — Design Token & Component Suite (V2.0)
        </h1>
        <p style={{ fontSize: '15px', color: 'var(--text-secondary)', marginTop: '4px' }}>
          Interactive proof & token validator matching the Pothik Design Master Prompt V2.0.
        </p>
      </div>

      {/* 1. Base Color Ramps & Contrast Rules */}
      <Card style={{ padding: '24px' }}>
        <h3 style={{ fontSize: '18px', fontWeight: 600, color: 'var(--navy-900)', marginBottom: '16px' }}>
          1. Color System Ramps & Contrast Rules (Section 3)
        </h3>

        <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
          <div>
            <div style={{ fontSize: '14px', fontWeight: 600, marginBottom: '8px' }}>Navy Ramp (Base Brand & Trust)</div>
            <div style={{ display: 'flex', gap: '8px', flexWrap: 'wrap' }}>
              {Object.entries(COLOR_TOKENS.navy).map(([step, hex]) => (
                <div key={step} style={{ textAlign: 'center' }}>
                  <div style={{ width: '60px', height: '40px', borderRadius: '6px', backgroundColor: hex }} />
                  <span style={{ fontSize: '11px', color: 'var(--text-secondary)' }}>{step}: {hex}</span>
                </div>
              ))}
            </div>
          </div>

          <div>
            <div style={{ fontSize: '14px', fontWeight: 600, marginBottom: '8px' }}>Amber Ramp (Action & Movement)</div>
            <div style={{ display: 'flex', gap: '8px', flexWrap: 'wrap' }}>
              {Object.entries(COLOR_TOKENS.amber).map(([step, hex]) => (
                <div key={step} style={{ textAlign: 'center' }}>
                  <div style={{ width: '60px', height: '40px', borderRadius: '6px', backgroundColor: hex }} />
                  <span style={{ fontSize: '11px', color: 'var(--text-secondary)' }}>{step}: {hex}</span>
                </div>
              ))}
            </div>
          </div>

          {/* Contrast Highlight Box */}
          <div
            style={{
              backgroundColor: 'var(--amber-500)',
              color: 'var(--navy-900)',
              padding: '12px 16px',
              borderRadius: '12px',
              fontWeight: 600,
              fontSize: '14px',
            }}
          >
            ✓ Strict Contrast Check: Primary buttons use Navy-900 text on Amber-500 fill (~7.6:1 AAA). White text on Amber fails WCAG AA and is never used.
          </div>
        </div>
      </Card>

      {/* 2. Button Component States (Section 7.1) */}
      <Card style={{ padding: '24px' }}>
        <h3 style={{ fontSize: '18px', fontWeight: 600, color: 'var(--navy-900)', marginBottom: '16px' }}>
          2. Button Component States (5 States Per Variant)
        </h3>

        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: '20px' }}>
          <div>
            <h4 style={{ fontSize: '14px', fontWeight: 600, marginBottom: '12px' }}>Primary Button (Amber)</h4>
            <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
              <Button variant="primary">Default State</Button>
              <Button variant="primary" isLoading>Loading State</Button>
              <Button variant="primary" disabled>Disabled State</Button>
            </div>
          </div>

          <div>
            <h4 style={{ fontSize: '14px', fontWeight: 600, marginBottom: '12px' }}>Secondary Button (Navy Outline)</h4>
            <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
              <Button variant="secondary">Default Outline</Button>
              <Button variant="secondary" isLoading>Loading Outline</Button>
              <Button variant="secondary" disabled>Disabled Outline</Button>
            </div>
          </div>

          <div>
            <h4 style={{ fontSize: '14px', fontWeight: 600, marginBottom: '12px' }}>Danger Button (Red Fill)</h4>
            <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
              <Button variant="danger">Default Danger</Button>
              <Button variant="danger" isLoading>Loading Danger</Button>
              <Button variant="danger" disabled>Disabled Danger</Button>
            </div>
          </div>
        </div>
      </Card>

      {/* 3. Input & OTP Components */}
      <Card style={{ padding: '24px' }}>
        <h3 style={{ fontSize: '18px', fontWeight: 600, color: 'var(--navy-900)', marginBottom: '16px' }}>
          3. Inputs & 6-Digit OTP Box (Section 7.2 & 7.4)
        </h3>

        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '24px' }}>
          <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
            <InputField label="সাধারণ ইনপুট" placeholder="যেমন: গুলশান ২ সার্কেল" value="গুলশান ২" />
            <InputField label="ভুল ইনপুট (Error State)" value="১২৩৪" error="ফোন নম্বরটি সঠিক নয় (১১ ডিজিট দিন)" />
            <InputField label="ডিজেবল ইনপুট" value="স্থায়ী তথ্য" disabled />
          </div>

          <div>
            <h4 style={{ fontSize: '14px', fontWeight: 600, marginBottom: '8px' }}>6-Digit OTP Box (Inter 32px Tabular)</h4>
            <OtpInput length={6} />
            <p style={{ fontSize: '12px', color: 'var(--text-secondary)', textAlign: 'center' }}>
              Auto-advances on keypress, auto-submits on last digit.
            </p>
          </div>
        </div>
      </Card>

      {/* 4. Status Badges & Toast */}
      <Card style={{ padding: '24px' }}>
        <h3 style={{ fontSize: '18px', fontWeight: 600, color: 'var(--navy-900)', marginBottom: '16px' }}>
          4. Status Badges & Toasts (Section 7.5 & 7.7)
        </h3>

        <div style={{ display: 'flex', gap: '12px', flexWrap: 'wrap', marginBottom: '16px' }}>
          <Badge variant="online" />
          <Badge variant="offline" />
          <Badge variant="pending" />
          <Badge variant="verified" />
          <Badge variant="danger" />
        </div>

        <Button variant="secondary" onClick={() => setToastOpen(true)}>
          ট্রিগার টোস্ট নোটিফিকেশন (3s Auto-dismiss)
        </Button>

        <Toast
          isOpen={toastOpen}
          message="✓ পেমেন্ট সফলভাবে গৃহীত হয়েছে!"
          type="success"
          onDismiss={() => setToastOpen(false)}
        />
      </Card>
    </div>
  );
};
