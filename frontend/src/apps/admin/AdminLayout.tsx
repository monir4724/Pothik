import React from 'react';
import { LayoutDashboard, ShieldCheck, MapPin, DollarSign, LogOut } from 'lucide-react';

export interface AdminLayoutProps {
  currentTab: 'dashboard' | 'approvals' | 'live' | 'pricing';
  onSelectTab: (tab: 'dashboard' | 'approvals' | 'live' | 'pricing') => void;
  children: React.ReactNode;
}

export const AdminLayout: React.FC<AdminLayoutProps> = ({ currentTab, onSelectTab, children }) => {
  const navItems = [
    { id: 'dashboard', label: 'ড্যাশবোর্ড (Dashboard)', icon: <LayoutDashboard size={20} /> },
    { id: 'approvals', label: 'ড্রাইভার ভেরিফিকেশন (Approvals)', icon: <ShieldCheck size={20} /> },
    { id: 'live', label: 'লাইভ রাইড ম্যাপ (Live Rides)', icon: <MapPin size={20} /> },
    { id: 'pricing', label: 'ভাড়া ও প্রাক্কলন (Pricing)', icon: <DollarSign size={20} /> },
  ];

  return (
    <div style={{ display: 'flex', flexDirection: 'column', width: '100%', height: '100vh', backgroundColor: 'var(--bg)' }}>
      {/* 64px Top Bar */}
      <div
        style={{
          height: '64px',
          backgroundColor: 'var(--navy-900)',
          color: '#FFFFFF',
          padding: '0 24px',
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          boxShadow: 'var(--shadow-sm)',
          zIndex: 40,
        }}
      >
        <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
          <div
            style={{
              backgroundColor: 'var(--amber-500)',
              color: 'var(--navy-900)',
              fontWeight: 700,
              fontSize: '18px',
              borderRadius: '8px',
              padding: '4px 10px',
            }}
          >
            Pothik
          </div>
          <span style={{ fontSize: '18px', fontWeight: 600 }}>Admin Operations Panel</span>
        </div>

        <div style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
          <div style={{ textAlign: 'right', fontSize: '14px' }}>
            <div style={{ fontWeight: 600 }}>কামরুল হাসান</div>
            <div style={{ fontSize: '12px', opacity: 0.7 }}>Senior Operations Manager</div>
          </div>
          <button
            onClick={() => alert('Admin Signed Out')}
            style={{
              border: 'none',
              backgroundColor: 'rgba(255, 255, 255, 0.1)',
              borderRadius: '8px',
              padding: '8px',
              color: '#FFFFFF',
              cursor: 'pointer',
            }}
          >
            <LogOut size={18} />
          </button>
        </div>
      </div>

      {/* Sidebar + Main Content Layout */}
      <div style={{ display: 'flex', flex: 1, overflow: 'hidden' }}>
        {/* 240px Sidebar */}
        <div
          style={{
            width: '240px',
            backgroundColor: 'var(--navy-900)',
            borderRight: '1px solid var(--navy-800)',
            display: 'flex',
            flexDirection: 'column',
            paddingTop: '16px',
            flexShrink: 0,
          }}
        >
          {navItems.map((item) => {
            const isActive = currentTab === item.id;
            return (
              <button
                key={item.id}
                onClick={() => onSelectTab(item.id as any)}
                style={{
                  height: '44px',
                  display: 'flex',
                  alignItems: 'center',
                  gap: '12px',
                  padding: '0 20px',
                  backgroundColor: isActive ? 'var(--navy-700)' : 'transparent',
                  borderLeft: isActive ? '4px solid var(--amber-500)' : '4px solid transparent',
                  color: '#FFFFFF',
                  fontFamily: 'var(--font-ui)',
                  fontSize: '15px',
                  fontWeight: isActive ? 600 : 500,
                  cursor: 'pointer',
                  borderTop: 'none',
                  borderRight: 'none',
                  borderBottom: 'none',
                  textAlign: 'left',
                  transition: 'all 150ms ease',
                }}
              >
                {item.icon}
                <span>{item.label}</span>
              </button>
            );
          })}
        </div>

        {/* Fluid Content Area */}
        <div
          style={{
            flex: 1,
            padding: '24px',
            overflowY: 'auto',
            backgroundColor: 'var(--bg)',
          }}
        >
          <div style={{ maxWidth: '1200px', margin: '0 auto' }}>{children}</div>
        </div>
      </div>
    </div>
  );
};
