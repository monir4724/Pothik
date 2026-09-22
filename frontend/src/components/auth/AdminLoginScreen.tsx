import React, { useState } from 'react';
import { Lock, Mail, ShieldCheck } from 'lucide-react';
import { Button } from '../ui/Button';
import { InputField } from '../ui/InputField';
import { Card } from '../ui/Card';

export interface AdminLoginScreenProps {
  onLoginSuccess: () => void;
}

export const AdminLoginScreen: React.FC<AdminLoginScreenProps> = ({ onLoginSuccess }) => {
  const [email, setEmail] = useState('admin@pothik.bd');
  const [password, setPassword] = useState('••••••••••••');
  const [isLoading, setIsLoading] = useState(false);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);
    setTimeout(() => {
      setIsLoading(false);
      onLoginSuccess();
    }, 600);
  };

  return (
    <div
      style={{
        width: '100%',
        height: '100vh',
        backgroundColor: 'var(--navy-950)',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        padding: '24px',
      }}
    >
      <Card
        style={{
          width: '100%',
          maxWidth: '420px',
          padding: '32px 28px',
          backgroundColor: 'var(--surface)',
          boxShadow: 'var(--shadow-md)',
          borderRadius: '16px',
        }}
      >
        <div style={{ textAlign: 'center', marginBottom: '24px' }}>
          <div
            style={{
              display: 'inline-flex',
              alignItems: 'center',
              justifyContent: 'center',
              backgroundColor: 'var(--navy-900)',
              color: 'var(--amber-500)',
              fontSize: '22px',
              fontWeight: 700,
              padding: '6px 14px',
              borderRadius: '10px',
              marginBottom: '12px',
            }}
          >
            Pothik Admin
          </div>
          <h2 style={{ fontSize: '20px', fontWeight: 600, color: 'var(--navy-900)' }}>
            অপারেশনস প্যানেলে প্রবেশ করুন
          </h2>
          <p style={{ fontSize: '13px', color: 'var(--text-secondary)', marginTop: '4px' }}>
            অনুমোদিত অ্যাডমিন কর্মীদের জন্য সংরক্ষিত সাইন-ইন
          </p>
        </div>

        <form onSubmit={handleSubmit} style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
          <InputField
            label="ইমেইল এড্রেস (Official Email)"
            type="email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            icon={<Mail size={18} color="var(--navy-600)" />}
          />

          <InputField
            label="পাসওয়ার্ড (Password)"
            type="password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            icon={<Lock size={18} color="var(--navy-600)" />}
          />

          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', fontSize: '13px' }}>
            <label style={{ display: 'flex', alignItems: 'center', gap: '6px', cursor: 'pointer', color: 'var(--text-secondary)' }}>
              <input type="checkbox" defaultChecked style={{ accentColor: 'var(--navy-900)' }} />
              মনে রাখুন (Remember Me)
            </label>

            <a href="#forgot" onClick={(e) => { e.preventDefault(); alert('Password reset link sent to admin mail'); }} style={{ color: 'var(--navy-600)', textDecoration: 'none', fontWeight: 500 }}>
              পাসওয়ার্ড ভুলে গেছেন?
            </a>
          </div>

          <Button fullWidth type="submit" isLoading={isLoading}>
            <ShieldCheck size={18} style={{ marginRight: '8px' }} /> লগইন করুন (Sign In)
          </Button>
        </form>
      </Card>
    </div>
  );
};
