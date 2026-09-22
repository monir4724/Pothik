import React from 'react';
import { Car, MapPin, Flag } from 'lucide-react';

export interface MapViewProps {
  height?: string;
  showDriver?: boolean;
  driverHeading?: number;
  showRoute?: boolean;
  passengerLocName?: string;
  destinationLocName?: string;
}

export const MapView: React.FC<MapViewProps> = ({
  height = '100%',
  showDriver = true,
  driverHeading = 45,
  showRoute = true,
  passengerLocName = 'Gulshan 2 Circle',
  destinationLocName = 'Dhanmondi 32',
}) => {
  return (
    <div
      style={{
        position: 'relative',
        width: '100%',
        height: height,
        backgroundColor: '#F7F7F5', // Neutral land color from custom map spec
        overflow: 'hidden',
        userSelect: 'none',
      }}
    >
      {/* Custom Map Background Canvas Simulation */}
      <svg width="100%" height="100%" style={{ position: 'absolute', inset: 0 }}>
        {/* Lake / Water Body (Navy-200 #AEBBD1) */}
        <path d="M 0,250 Q 120,220 250,280 T 500,200 L 500,400 L 0,400 Z" fill="#AEBBD1" opacity="0.8" />

        {/* Arterial Roads (#EFEFEC) */}
        <path d="M -50,150 Q 200,100 450,250" stroke="#EFEFEC" strokeWidth="24" fill="none" />
        <path d="M 120,-20 L 180,450" stroke="#EFEFEC" strokeWidth="20" fill="none" />
        <path d="M 320,-20 L 300,450" stroke="#EFEFEC" strokeWidth="16" fill="none" />

        {/* Local Roads (#F7F7F5 outline) */}
        <path d="M -20,80 L 400,120" stroke="#E3E5E8" strokeWidth="8" fill="none" />
        <path d="M 50,300 L 400,320" stroke="#E3E5E8" strokeWidth="10" fill="none" />

        {/* Parks (#E7F5EE) */}
        <rect x="30" y="30" width="80" height="60" rx="12" fill="#E7F5EE" />
        <rect x="280" y="50" width="100" height="70" rx="16" fill="#E7F5EE" />

        {/* Route Polyline (Navy-600 #24406F, 4px stroke) */}
        {showRoute && (
          <path
            d="M 120,180 Q 200,160 260,220 T 340,300"
            stroke="var(--navy-600)"
            strokeWidth="5"
            strokeDasharray="8 0"
            fill="none"
            strokeLinecap="round"
          />
        )}
      </svg>

      {/* Markers Layer */}
      {/* Pickup Point Marker (Success-500) */}
      <div
        style={{
          position: 'absolute',
          left: '120px',
          top: '180px',
          transform: 'translate(-50%, -100%)',
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
        }}
      >
        <div
          style={{
            backgroundColor: 'var(--success)',
            color: '#FFF',
            padding: '4px 8px',
            borderRadius: '6px',
            fontSize: '11px',
            fontWeight: 600,
            boxShadow: 'var(--shadow-sm)',
            marginBottom: '2px',
            whiteSpace: 'nowrap',
          }}
        >
          {passengerLocName}
        </div>
        <div
          style={{
            width: '36px',
            height: '36px',
            borderRadius: '50%',
            backgroundColor: 'var(--success)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            boxShadow: '0 4px 8px rgba(0,0,0,0.2)',
          }}
        >
          <MapPin size={20} color="#FFFFFF" />
        </div>
      </div>

      {/* Destination Marker (Danger-500) */}
      {showRoute && (
        <div
          style={{
            position: 'absolute',
            left: '340px',
            top: '300px',
            transform: 'translate(-50%, -100%)',
            display: 'flex',
            flexDirection: 'column',
            alignItems: 'center',
          }}
        >
          <div
            style={{
              backgroundColor: 'var(--danger)',
              color: '#FFF',
              padding: '4px 8px',
              borderRadius: '6px',
              fontSize: '11px',
              fontWeight: 600,
              boxShadow: 'var(--shadow-sm)',
              marginBottom: '2px',
              whiteSpace: 'nowrap',
            }}
          >
            {destinationLocName}
          </div>
          <div
            style={{
              width: '36px',
              height: '36px',
              borderRadius: '50%',
              backgroundColor: 'var(--danger)',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              boxShadow: '0 4px 8px rgba(0,0,0,0.2)',
            }}
          >
            <Flag size={20} color="#FFFFFF" />
          </div>
        </div>
      )}

      {/* Driver Location Marker (Amber-500 rounded rect with rotation) */}
      {showDriver && (
        <div
          style={{
            position: 'absolute',
            left: '230px',
            top: '200px',
            transform: `translate(-50%, -50%) rotate(${driverHeading}deg)`,
            transition: 'all 500ms ease-in-out',
          }}
        >
          <div
            style={{
              width: '44px',
              height: '28px',
              borderRadius: '8px',
              backgroundColor: 'var(--amber-500)',
              border: '2px solid var(--navy-900)',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              boxShadow: 'var(--shadow-sm)',
            }}
          >
            <Car size={20} color="var(--navy-900)" />
          </div>
        </div>
      )}

      {/* Map Branding Badge */}
      <div
        style={{
          position: 'absolute',
          top: '12px',
          left: '12px',
          backgroundColor: 'rgba(255, 255, 255, 0.9)',
          backdropFilter: 'blur(4px)',
          borderRadius: '8px',
          padding: '4px 10px',
          fontSize: '12px',
          fontWeight: 600,
          color: 'var(--navy-900)',
          boxShadow: 'var(--shadow-sm)',
          display: 'flex',
          alignItems: 'center',
          gap: '6px',
        }}
      >
        <span style={{ width: '8px', height: '8px', borderRadius: '50%', backgroundColor: 'var(--success)' }} />
        Pothik Vector Map (Dhaka Zone)
      </div>
    </div>
  );
};
