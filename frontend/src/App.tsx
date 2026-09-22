import { useState } from 'react';
import { User, Car, Shield, Palette, Wifi, WifiOff } from 'lucide-react';
import { PassengerHome } from './apps/passenger/PassengerHome';
import { DriverMatchedSheet } from './apps/passenger/DriverMatchedSheet';
import { PickupOtpCard } from './apps/passenger/PickupOtpCard';
import { InTripView } from './apps/passenger/InTripView';
import { PassengerRideHistory } from './apps/passenger/PassengerRideHistory';
import { GuardiansScreen } from './apps/passenger/GuardiansScreen';
import { PassengerAuthWizard } from './apps/passenger/PassengerAuthWizard';

import { DriverHome } from './apps/driver/DriverHome';

import { AdminLayout } from './apps/admin/AdminLayout';
import { AdminDashboard } from './apps/admin/AdminDashboard';
import { AdminDriverApproval } from './apps/admin/AdminDriverApproval';
import { AdminLiveRides } from './apps/admin/AdminLiveRides';
import { AdminPricingSettings } from './apps/admin/AdminPricingSettings';

import { DesignSystemSandbox } from './apps/sandbox/DesignSystemSandbox';
import { OfflineBanner } from './components/ui/OfflineBanner';
import { PhoneLoginModal } from './components/auth/PhoneLoginModal';
import { AdminLoginScreen } from './components/auth/AdminLoginScreen';

export function App() {
  const [activePersona, setActivePersona] = useState<'passenger' | 'driver' | 'admin' | 'sandbox'>('passenger');
  const [isOffline, setIsOffline] = useState(false);

  // Auth states
  const [passengerAuth, setPassengerAuth] = useState<{ isLoggedIn: boolean; name: string }>({ isLoggedIn: true, name: 'তানভীর আহমেদ' });
  const [driverAuth, setDriverAuth] = useState<{ isLoggedIn: boolean; name: string }>({ isLoggedIn: true, name: 'কাজী মো: রফিকুল ইসলাম' });
  const [adminAuth, setAdminAuth] = useState<boolean>(true);

  // Passenger state machine
  const [passengerView, setPassengerView] = useState<'home' | 'matched' | 'otp' | 'intrip' | 'history' | 'guardians'>('home');
  const [activeRideData, setActiveRideData] = useState({ pickup: 'গুলশান ২ সার্কেল', destination: 'ধানমন্ডি ৩২', fare: 185 });

  // Admin state machine
  const [adminTab, setAdminTab] = useState<'dashboard' | 'approvals' | 'live' | 'pricing'>('dashboard');

  return (
    <div style={{ minHeight: '100vh', display: 'flex', flexDirection: 'column', backgroundColor: 'var(--bg)' }}>
      {/* Top Persona Switcher & Offline Simulator Header */}
      <header
        style={{
          backgroundColor: 'var(--navy-950)',
          color: '#FFFFFF',
          padding: '8px 16px',
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          borderBottom: '2px solid var(--amber-500)',
          boxShadow: 'var(--shadow-sm)',
          zIndex: 200,
        }}
      >
        <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
          <span style={{ fontWeight: 700, fontSize: '18px', color: 'var(--amber-500)', fontFamily: 'var(--font-ui)' }}>
            Pothik (পথিক)
          </span>
          <span style={{ fontSize: '12px', opacity: 0.8, backgroundColor: 'rgba(255,255,255,0.1)', padding: '2px 8px', borderRadius: '4px' }}>
            V2.0 Prototype Suite
          </span>
        </div>

        {/* Persona Selector Navigation */}
        <div style={{ display: 'flex', gap: '6px' }}>
          <button
            onClick={() => setActivePersona('passenger')}
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: '6px',
              padding: '6px 12px',
              borderRadius: '8px',
              border: 'none',
              backgroundColor: activePersona === 'passenger' ? 'var(--amber-500)' : 'rgba(255,255,255,0.1)',
              color: activePersona === 'passenger' ? 'var(--navy-900)' : '#FFFFFF',
              fontWeight: 600,
              fontSize: '13px',
              cursor: 'pointer',
            }}
          >
            <User size={16} /> Passenger App
          </button>

          <button
            onClick={() => setActivePersona('driver')}
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: '6px',
              padding: '6px 12px',
              borderRadius: '8px',
              border: 'none',
              backgroundColor: activePersona === 'driver' ? 'var(--amber-500)' : 'rgba(255,255,255,0.1)',
              color: activePersona === 'driver' ? 'var(--navy-900)' : '#FFFFFF',
              fontWeight: 600,
              fontSize: '13px',
              cursor: 'pointer',
            }}
          >
            <Car size={16} /> Driver App
          </button>

          <button
            onClick={() => setActivePersona('admin')}
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: '6px',
              padding: '6px 12px',
              borderRadius: '8px',
              border: 'none',
              backgroundColor: activePersona === 'admin' ? 'var(--amber-500)' : 'rgba(255,255,255,0.1)',
              color: activePersona === 'admin' ? 'var(--navy-900)' : '#FFFFFF',
              fontWeight: 600,
              fontSize: '13px',
              cursor: 'pointer',
            }}
          >
            <Shield size={16} /> Admin Panel
          </button>

          <button
            onClick={() => setActivePersona('sandbox')}
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: '6px',
              padding: '6px 12px',
              borderRadius: '8px',
              border: 'none',
              backgroundColor: activePersona === 'sandbox' ? 'var(--amber-500)' : 'rgba(255,255,255,0.1)',
              color: activePersona === 'sandbox' ? 'var(--navy-900)' : '#FFFFFF',
              fontWeight: 600,
              fontSize: '13px',
              cursor: 'pointer',
            }}
          >
            <Palette size={16} /> Tokens Sandbox
          </button>
        </div>

        {/* Auth Toggle & Offline Simulation Controls */}
        <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
          {activePersona === 'passenger' && (
            <button
              onClick={() => setPassengerAuth({ ...passengerAuth, isLoggedIn: !passengerAuth.isLoggedIn })}
              style={{
                fontSize: '12px',
                padding: '4px 8px',
                borderRadius: '6px',
                backgroundColor: 'rgba(255,255,255,0.15)',
                color: '#FFF',
                border: 'none',
                cursor: 'pointer',
              }}
            >
              {passengerAuth.isLoggedIn ? 'লগআউট (Logout)' : 'লগইন (Login Wizard)'}
            </button>
          )}

          {activePersona === 'driver' && (
            <button
              onClick={() => setDriverAuth({ ...driverAuth, isLoggedIn: !driverAuth.isLoggedIn })}
              style={{
                fontSize: '12px',
                padding: '4px 8px',
                borderRadius: '6px',
                backgroundColor: 'rgba(255,255,255,0.15)',
                color: '#FFF',
                border: 'none',
                cursor: 'pointer',
              }}
            >
              {driverAuth.isLoggedIn ? 'লগআউট (Logout)' : 'লগইন (Driver Portal)'}
            </button>
          )}

          {activePersona === 'admin' && (
            <button
              onClick={() => setAdminAuth(!adminAuth)}
              style={{
                fontSize: '12px',
                padding: '4px 8px',
                borderRadius: '6px',
                backgroundColor: 'rgba(255,255,255,0.15)',
                color: '#FFF',
                border: 'none',
                cursor: 'pointer',
              }}
            >
              {adminAuth ? 'লগআউট (Logout)' : 'লগইন (Admin Login)'}
            </button>
          )}

          <button
            onClick={() => setIsOffline(!isOffline)}
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: '6px',
              padding: '6px 12px',
              borderRadius: '8px',
              border: isOffline ? '1px solid var(--warning)' : '1px solid rgba(255,255,255,0.2)',
              backgroundColor: isOffline ? 'var(--warning-bg)' : 'transparent',
              color: isOffline ? 'var(--warning)' : '#FFFFFF',
              fontSize: '12px',
              fontWeight: 600,
              cursor: 'pointer',
            }}
          >
            {isOffline ? <WifiOff size={16} /> : <Wifi size={16} />}
            {isOffline ? 'Offline Mode' : 'Simulate Offline'}
          </button>
        </div>
      </header>

      {/* Main View Area */}
      <main style={{ flex: 1, position: 'relative', display: 'flex', justifyContent: 'center' }}>
        {/* PASSENGER PERSONA */}
        {activePersona === 'passenger' && (
          <div style={{ width: '100%', maxWidth: '440px', height: 'calc(100vh - 54px)', backgroundColor: 'var(--surface)', boxShadow: 'var(--shadow-md)', position: 'relative', overflow: 'hidden' }}>
            {!passengerAuth.isLoggedIn ? (
              <PassengerAuthWizard
                initialPhone="01521700014"
                onAuthSuccess={(u) => setPassengerAuth({ isLoggedIn: true, name: u.name })}
              />
            ) : (
              <>
                {passengerView === 'home' && (
                  <PassengerHome
                    onBookRide={(p, d, f) => {
                      setActiveRideData({ pickup: p, destination: d, fare: f });
                      setPassengerView('matched');
                    }}
                    onOpenHistory={() => setPassengerView('history')}
                    onOpenGuardians={() => setPassengerView('guardians')}
                  />
                )}

                {passengerView === 'matched' && (
                  <div style={{ position: 'relative', height: '100%' }}>
                    <PassengerHome
                      onBookRide={() => {}}
                      onOpenHistory={() => {}}
                      onOpenGuardians={() => {}}
                    />
                    <DriverMatchedSheet
                      onCancelRide={() => setPassengerView('home')}
                      onArrived={() => setPassengerView('otp')}
                    />
                  </div>
                )}

                {passengerView === 'otp' && (
                  <div style={{ position: 'relative', height: '100%' }}>
                    <PassengerHome
                      onBookRide={() => {}}
                      onOpenHistory={() => {}}
                      onOpenGuardians={() => {}}
                    />
                    <PickupOtpCard
                      otp="123456"
                      onStartRide={() => setPassengerView('intrip')}
                    />
                  </div>
                )}

                {passengerView === 'intrip' && (
                  <InTripView
                    pickup={activeRideData.pickup}
                    destination={activeRideData.destination}
                    fare={activeRideData.fare}
                    onTripCompleted={() => setPassengerView('home')}
                  />
                )}

                {passengerView === 'history' && (
                  <PassengerRideHistory onBack={() => setPassengerView('home')} />
                )}

                {passengerView === 'guardians' && (
                  <GuardiansScreen onBack={() => setPassengerView('home')} />
                )}
              </>
            )}
          </div>
        )}

        {/* DRIVER PERSONA */}
        {activePersona === 'driver' && (
          <div style={{ width: '100%', maxWidth: '440px', height: 'calc(100vh - 54px)', backgroundColor: 'var(--surface)', boxShadow: 'var(--shadow-md)', position: 'relative', overflow: 'hidden' }}>
            {!driverAuth.isLoggedIn ? (
              <PhoneLoginModal
                role="driver"
                onLoginSuccess={(u) => setDriverAuth({ isLoggedIn: true, name: u.name })}
              />
            ) : (
              <DriverHome />
            )}
          </div>
        )}

        {/* ADMIN PERSONA */}
        {activePersona === 'admin' && (
          <div style={{ width: '100%', height: 'calc(100vh - 54px)' }}>
            {!adminAuth ? (
              <AdminLoginScreen onLoginSuccess={() => setAdminAuth(true)} />
            ) : (
              <AdminLayout currentTab={adminTab} onSelectTab={setAdminTab}>
                {adminTab === 'dashboard' && <AdminDashboard />}
                {adminTab === 'approvals' && <AdminDriverApproval />}
                {adminTab === 'live' && <AdminLiveRides />}
                {adminTab === 'pricing' && <AdminPricingSettings />}
              </AdminLayout>
            )}
          </div>
        )}

        {/* DESIGN SYSTEM SANDBOX */}
        {activePersona === 'sandbox' && (
          <div style={{ width: '100%', height: 'calc(100vh - 54px)', overflowY: 'auto' }}>
            <DesignSystemSandbox />
          </div>
        )}
      </main>

      {/* Global Offline Banner */}
      <OfflineBanner isOffline={isOffline} />
    </div>
  );
}

export default App;
