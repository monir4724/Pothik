// Pothik (পথিক) Design System Tokens & Constants - Version 2.0

export const COLOR_TOKENS = {
  navy: {
    50: '#EEF1F6',
    100: '#D6DCE8',
    200: '#AEBBD1',
    300: '#8698B9',
    400: '#5E75A1',
    500: '#3B5389',
    600: '#24406F',
    700: '#1B325A',
    800: '#172946',
    900: '#14213D',
    950: '#0D1729',
  },
  amber: {
    50: '#FEF6E9',
    100: '#FCE7C2',
    200: '#F9D28E',
    300: '#F6BD5A',
    400: '#F4B646',
    500: '#F2A93C',
    600: '#D6902B',
    700: '#B37423',
    800: '#8F5C1C',
    900: '#6B4515',
    950: '#4C3110',
  },
  gray: {
    50: '#F7F7F5',
    100: '#EFEFEC',
    200: '#E3E5E8',
    300: '#C7CBD1',
    400: '#9CA3AF',
    500: '#6B7280',
    600: '#4B5262',
    700: '#363B47',
    800: '#23262E',
    900: '#16181D',
    950: '#0E0F13',
  },
  status: {
    success: '#1E8A5F',
    successBg: '#E7F5EE',
    danger: '#D64545',
    dangerBg: '#FBEAEA',
    warning: '#C97A1E',
    warningBg: '#FBF0E2',
  },
};

// Map custom theme override JSON (Section 11.1)
export const POTHIK_MAP_STYLE = [
  { featureType: "water", elementType: "geometry", stylers: [{ color: "#AEBBD1" }] },
  { featureType: "road.arterial", elementType: "geometry", stylers: [{ color: "#EFEFEC" }] },
  { featureType: "road.local", elementType: "geometry", stylers: [{ color: "#F7F7F5" }] },
  { featureType: "poi", elementType: "all", stylers: [{ visibility: "off" }] },
  { featureType: "poi.park", elementType: "geometry", stylers: [{ color: "#E7F5EE" }, { visibility: "on" }] },
  { featureType: "administrative", elementType: "labels.text.fill", stylers: [{ color: "#363B47" }] },
  { featureType: "road", elementType: "labels.text.fill", stylers: [{ color: "#6B7280" }] },
  { featureType: "transit", elementType: "all", stylers: [{ visibility: "off" }] },
  { featureType: "landscape", elementType: "geometry", stylers: [{ color: "#F7F7F5" }] }
];

export function formatTaka(amount: number, compact: boolean = false): string {
  const formatted = amount.toLocaleString('en-US');
  return compact ? `৳${formatted}` : `৳\u202F${formatted}`;
}
