const DHaka = { lat: 23.8103, lng: 90.4125 };
const state = { currentUser: null, isLoggedIn: false, currentRide: null, driverStatus: 'offline', earnings: { today: 0, week: 0, month: 0 }, rides: [], ratings: [], drivers: [], favorites: [], notifications: [], pricing: { base: 30, perKm: 12 } };
const API_BASE = `${window.location.protocol === 'file:' ? 'http:' : window.location.protocol}//${window.location.hostname || 'localhost'}:3000/api/v1`;
const api = { async request(path, options = {}) { const headers = { 'Content-Type': 'application/json', ...(options.headers || {}) }; const accessToken = localStorage.getItem('pothik_access_token'); if (accessToken) headers.Authorization = `Bearer ${accessToken}`; const response = await fetch(`${API_BASE}${path}`, { ...options, headers }); const body = await response.json().catch(() => ({})); if (!response.ok) throw new Error(body.message || `API request failed (${response.status})`); return body; }, requestOtp(phone) { return this.request('/auth/otp/request', { method: 'POST', body: JSON.stringify({ phone }) }); }, verifyOtp(phone, code) { return this.request('/auth/otp/verify', { method: 'POST', body: JSON.stringify({ phone, code }) }); }, createRide(payload) { return this.request('/rides', { method: 'POST', body: JSON.stringify(payload) }); } };
let currentLang = localStorage.getItem('pothik_lang') || 'bn';
let translations = {};
let map; let pickupMarker; let destinationMarker; let driverMarker; let routeLine; let currentPosition = { ...DHaka };
let searchTimer; let requestTimer; let bookingTimer; let toastTimer; let toastHideTimer;
const $ = (selector) => document.querySelector(selector);
const $$ = (selector) => [...document.querySelectorAll(selector)];
const bnDigits = (value) => String(Math.round(value)).replace(/\d/g, (digit) => '০১২৩৪৫৬৭৮৯'[digit]);
const store = { get(key, fallback) { try { return JSON.parse(localStorage.getItem(`pothik_${key}`)) ?? fallback; } catch { return fallback; } }, set(key, value) { localStorage.setItem(`pothik_${key}`, JSON.stringify(value)); } };

function renderIcons() { if (window.lucide) window.lucide.createIcons(); else $$('[data-lucide]').forEach((icon) => { icon.textContent = '•'; icon.classList.add('fallback-icon'); }); }
function t(key) { return translations[key] || key; }
function applyTranslations() {
  $$('[data-i18n]').forEach((element) => { element.textContent = t(element.dataset.i18n); });
  $$('[data-i18n-placeholder]').forEach((element) => { element.placeholder = t(element.dataset.i18nPlaceholder); });
  const map = { '#bookingTitle': 'where_to_go', '#pickupLabel': 'your_location', '#selectedDestination': 'select_destination', '#paymentChoice': 'cash', '#bookButtonText': state.currentRide ? 'driver_found' : 'select_destination', '#rideModalTitle': 'ride_complete', '#rideModal p': 'how_was_ride', '#submitRating': 'submit_rating', '#driverStatusBadge': state.driverStatus === 'offline' ? 'offline' : 'online', '#driverToday': null, '#todayEarnings': null, '#weekEarnings': null, '#monthEarnings': null };
  Object.entries(map).forEach(([selector, key]) => { if (key && $(selector) && !$(selector).dataset.userText) $(selector).textContent = t(key); });
  const authButton = $('#authButton span'); if (authButton) authButton.textContent = $('#otpField').hidden ? t('send_otp') : t('login_button');
  const search = $('#searchInput'); if (search) search.placeholder = t('search_placeholder');
  $$('[data-passenger-tab]').forEach((item) => { const key = item.dataset.passengerTab === 'home' ? 'home' : item.dataset.passengerTab; const label = item.querySelector('span'); if (label) label.textContent = t(key); });
  $('#onlineText')?.replaceChildren(document.createTextNode(state.driverStatus === 'offline' ? t('go_online') : t('go_offline')));
  $$('.earnings-grid article span')[0]?.replaceChildren(document.createTextNode(t('today'))); $$('.earnings-grid article span')[1]?.replaceChildren(document.createTextNode(t('this_week'))); $$('.earnings-grid article span')[2]?.replaceChildren(document.createTextNode(t('this_month')));
  $$('.lang-toggle').forEach((button) => { button.textContent = currentLang === 'bn' ? 'EN' : 'বাংলা'; button.setAttribute('aria-label', currentLang === 'bn' ? 'Switch to English' : 'বাংলায় পরিবর্তন করুন'); });
  document.documentElement.lang = currentLang; document.title = `${t('app_name')} | ${t('tagline')}`; renderIcons();
}
const originalApplyTranslations = applyTranslations;
function applyStaticTranslations() { const textMap = { '#driverScreen .driver-content .eyebrow': 'your_location', '#driverScreen .section-heading h1': 'where_to_go', '#adminScreen .admin-heading .eyebrow': 'dashboard', '#adminScreen .admin-heading h1': 'dashboard', '#adminScreen .panel-heading h2': 'driver_approval', '#adminScreen .pricing-panel h2': 'pricing' }; Object.entries(textMap).forEach(([selector, key]) => { if ($(selector)) $(selector).textContent = t(key); }); const driverStatus = $('#driverStatusBadge'); if (driverStatus) driverStatus.textContent = t(state.driverStatus === 'offline' ? 'offline' : 'online'); $$('.role-option b').forEach((element) => { const role = element.closest('.role-option')?.querySelector('input')?.value; if (role) element.textContent = t(role); }); $$('.sidebar-item').forEach((item, index) => { const keys = ['dashboard', 'driver', 'live_rides', 'pricing']; const icon = item.querySelector('svg'); item.textContent = t(keys[index]); if (icon) item.prepend(icon); }); }
applyTranslations = function translatedApply() { originalApplyTranslations(); applyStaticTranslations(); };
const translatedApplyWithUi = applyTranslations;
applyTranslations = function applyAllTranslations() {
  translatedApplyWithUi();
  const textTargets = {
    '#passengerScreen .booking-sheet .eyebrow': 'pickup_location',
    '#bookingTitle': 'where_to_go',
    '#passengerScreen .fare-block .detail-label': 'fare_estimate',
    '#passengerScreen .payment-block .detail-label': 'payment',
    '#passengerScreen .secure-note': 'book_cash_note',
    '#driverScreen .driver-hero .eyebrow': 'today_earnings',
    '#driverScreen .section-heading .eyebrow': 'your_area',
    '#driverScreen .section-heading h1': 'ready_for_ride',
    '#driverScreen .request-header .status-badge': 'new_request',
    '#driverScreen .request-card p:first-of-type': 'from_location',
    '#driverScreen .request-card p:nth-of-type(2)': 'to_location',
    '#driverScreen .request-card > strong': 'cash_fare',
    '#adminScreen .admin-heading .eyebrow': 'operations_center',
    '#adminScreen .admin-heading h1': 'today_dashboard',
    '#adminScreen .admin-heading .status-badge': 'system_online',
    '#adminScreen .kpi-card:nth-child(1) small': 'total_rides',
    '#adminScreen .kpi-card:nth-child(2) small': 'online_drivers',
    '#adminScreen .kpi-card:nth-child(2) .trend': 'registered_drivers',
    '#adminScreen .kpi-card:nth-child(3) small': 'today_revenue',
    '#adminScreen .panel-heading h2': 'driver_approval_title',
    '#adminScreen .panel-heading .text-button': 'view_all',
    '#adminScreen .admin-columns .admin-panel:nth-child(2) h2': 'live_rides_title',
    '#adminScreen .pricing-panel h2': 'pricing_settings',
    '#adminScreen .pricing-panel .eyebrow': 'demo_configuration',
    '#rideModalTitle': 'ride_completed',
    '#sosTitle': 'emergency_sos',
    '#cancelSos': 'sos_cancel'
  };
  Object.entries(textTargets).forEach(([selector, key]) => { const element = $(selector); if (element) element.textContent = t(key); });
  const ariaTargets = { '.map-area': 'location_map', '#map': 'interactive_map', '#zoomIn': 'zoom_in', '#zoomOut': 'zoom_out', '#locateBtn': 'locate_me', '#savedPlacesButton': 'saved_destination', '#searchInput': 'search_placeholder', '#menuButton': 'menu_label', '#notificationButton': 'notification_label', '#driverMenuButton': 'menu_label', '#driverNotificationButton': 'notification_label', '#sosButton': 'sos_hold_label', '#closeSos': 'close_sos_label', '#subpageBack': 'back_label', '.bottom-nav': state.currentUser?.role === 'driver' ? 'driver_navigation' : 'passenger_navigation' };
  Object.entries(ariaTargets).forEach(([selector, key]) => { const element = $(selector); if (element) element.setAttribute('aria-label', t(key)); });
  renderIcons();
};
async function loadLanguage(lang) { try { const response = await fetch(`locales/${lang}.json`); if (!response.ok) throw new Error('locale unavailable'); translations = await response.json(); currentLang = lang; localStorage.setItem('pothik_lang', lang); applyTranslations(); } catch { showToast('Language file could not be loaded', 'error'); } }
function toggleLanguage() { loadLanguage(currentLang === 'bn' ? 'en' : 'bn').then(() => showToast(currentLang === 'bn' ? 'বাংলা ভাষা চালু হয়েছে' : 'Switched to English', 'info')); }
function setTheme(theme) { document.documentElement.setAttribute('data-theme', theme); localStorage.setItem('pothik_theme', theme); const iconName = theme === 'dark' ? 'sun' : 'moon'; ['#themeIcon', '#authThemeIcon'].forEach((selector) => { const icon = $(selector); if (icon) icon.setAttribute('data-lucide', iconName); }); renderIcons(); }
function loadTheme() { const saved = localStorage.getItem('pothik_theme'); const systemDark = window.matchMedia?.('(prefers-color-scheme: dark)').matches; setTheme(saved || (systemDark ? 'dark' : 'light')); }
function toggleTheme() { const next = document.documentElement.getAttribute('data-theme') === 'dark' ? 'light' : 'dark'; setTheme(next); showToast(next === 'dark' ? `${t('dark_mode')} enabled` : `${t('light_mode')} enabled`, 'info'); }
function showToast(message, type = 'info') { const toast = $('#toast'); clearTimeout(toastTimer); clearTimeout(toastHideTimer); toast.className = 'toast'; toast.style.background = ({ success: '#1E8A5F', error: '#D64545', warning: '#C97A1E', info: '#14213D' })[type] || '#14213D'; toast.textContent = message; toast.hidden = false; requestAnimationFrame(() => toast.classList.add('visible')); toastTimer = setTimeout(() => { toast.classList.remove('visible'); toast.classList.add('hiding'); toastHideTimer = setTimeout(() => { toast.hidden = true; toast.className = 'toast'; }, 300); }, 3500); }
function loadSavedData() { state.rides = store.get('rides', []); state.ratings = store.get('ratings', []); state.earnings = store.get('earnings', state.earnings); state.drivers = store.get('drivers', []); state.favorites = store.get('favorites', []); state.notifications = store.get('notifications', []); state.pricing = store.get('pricing', state.pricing); updateEarningsUI(); }
function updateEarningsUI() { ['driverToday', 'todayEarnings'].forEach((id) => { if ($(`#${id}`)) $(`#${id}`).textContent = bnDigits(state.earnings.today); }); if ($('#weekEarnings')) $('#weekEarnings').textContent = bnDigits(state.earnings.week); if ($('#monthEarnings')) $('#monthEarnings').textContent = bnDigits(state.earnings.month); }
function showScreen(role) { $('#authScreen').hidden = role !== 'auth'; $('#passengerScreen').hidden = role !== 'passenger'; $('#driverScreen').hidden = role !== 'driver'; $('#adminScreen').hidden = role !== 'admin'; if (role !== 'auth' && map) setTimeout(() => { map.invalidateSize(); if (role === 'passenger') locateUser(); }, 100); applyTranslations(); }
function login(phone, otp, role) { if (!/^01\d{9}$/.test(phone.replace(/\D/g, ''))) { showToast('সঠিক ফোন নম্বর লিখুন', 'error'); return; } if (otp !== '1234') { showToast(currentLang === 'bn' ? 'OTP সঠিক নয়। ডেমো OTP: ১২৩৪' : 'Incorrect OTP. Demo OTP: 1234', 'error'); return; } state.currentUser = { role, phone, name: role === 'driver' ? t('driver') : role === 'admin' ? t('admin') : t('passenger') }; state.isLoggedIn = true; store.set('session', state.currentUser); showScreen(role); if (role === 'driver') resetDriverView(); showToast(`${state.currentUser.name} ${currentLang === 'bn' ? 'হিসেবে লগইন সফল হয়েছে' : 'logged in successfully'}`, 'success'); }
function normalizePhone(phone) { const digits = phone.replace(/\D/g, ''); return digits.startsWith('0') ? `+880${digits.slice(1)}` : `+${digits}`; }
async function login(phone, otp, role) { if (!/^01\d{9}$/.test(phone.replace(/\D/g, ''))) { showToast('সঠিক ১১ সংখ্যার ফোন নম্বর লিখুন', 'error'); return; } try { const result = await api.verifyOtp(normalizePhone(phone), otp); localStorage.setItem('pothik_access_token', result.tokens.accessToken); localStorage.setItem('pothik_refresh_token', result.tokens.refreshToken); const backendRole = String(result.user?.role || '').toLowerCase(); state.currentUser = { ...result.user, role: backendRole === 'driver' || backendRole === 'admin' ? backendRole : role, phone }; } catch { if (otp !== '1234') { showToast(currentLang === 'bn' ? 'OTP সঠিক নয়। ডেমো OTP: ১২৩৪' : 'Incorrect OTP. Demo OTP: 1234', 'error'); return; } state.currentUser = { role, phone, name: role === 'driver' ? t('driver') : role === 'admin' ? t('admin') : t('passenger') }; showToast(currentLang === 'bn' ? 'Backend পাওয়া যায়নি, ডেমো মোড চালু' : 'Backend unavailable, demo mode enabled', 'warning'); } state.isLoggedIn = true; store.set('session', state.currentUser); showScreen(state.currentUser.role); if (state.currentUser.role === 'driver') resetDriverView(); showToast(`${state.currentUser.name || t(state.currentUser.role)} ${currentLang === 'bn' ? 'হিসেবে লগইন সফল হয়েছে' : 'logged in successfully'}`, 'success'); }
function initMap() { if (!window.L || !$('#map')) return; map = window.L.map('map', { zoomControl: false }).setView([DHaka.lat, DHaka.lng], 13); window.L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', { attribution: '© OpenStreetMap', maxZoom: 19 }).addTo(map); const icon = window.L.divIcon({ className: '', html: '<div class="pickup-marker"></div>', iconSize: [20, 20], iconAnchor: [10, 10] }); pickupMarker = window.L.marker([DHaka.lat, DHaka.lng], { icon }).addTo(map).bindPopup(t('your_location')); }
function setDestination(coords, name, source = 'search') { const icon = window.L.divIcon({ className: '', html: '<div class="destination-marker"></div>', iconSize: [20, 20], iconAnchor: [10, 10] }); if (!destinationMarker) destinationMarker = window.L.marker([coords.lat, coords.lng], { icon }).addTo(map); else destinationMarker.setLatLng([coords.lat, coords.lng]); destinationMarker.bindPopup(name); routeLine?.remove(); routeLine = window.L.polyline([[currentPosition.lat, currentPosition.lng], [coords.lat, coords.lng]], { color: '#14213D', weight: 4, opacity: .85 }).addTo(map); map.fitBounds([[currentPosition.lat, currentPosition.lng], [coords.lat, coords.lng]], { padding: [42, 42] }); const distance = map.distance([currentPosition.lat, currentPosition.lng], [coords.lat, coords.lng]) / 1000; const fare = Math.max(state.pricing.base, Math.round(state.pricing.base + distance * state.pricing.perKm)); $('#selectedDestination').textContent = name.split(',')[0]; $('#fareAmount').textContent = currentLang === 'bn' ? bnDigits(fare) : fare; $('#routeSummary').hidden = false; $('#bookButton').disabled = false; $('#bookButtonText').textContent = `${t('book_ride')} ৳${currentLang === 'bn' ? bnDigits(fare) : fare}`; $('#searchInput').value = source === 'search' ? name.split(',')[0] : name; $('#clearSearch').hidden = false; $('#searchResults').hidden = true; return { name, coords, fare, distance }; }
function locateUser() { if (!navigator.geolocation) { map?.setView([DHaka.lat, DHaka.lng], 13); showToast(currentLang === 'bn' ? 'ঢাকা দেখানো হচ্ছে' : 'Showing Dhaka as fallback', 'warning'); return; } navigator.geolocation.getCurrentPosition((position) => { currentPosition = { lat: position.coords.latitude, lng: position.coords.longitude }; pickupMarker?.setLatLng([currentPosition.lat, currentPosition.lng]); map?.setView([currentPosition.lat, currentPosition.lng], 14); $('#pickupLabel').textContent = t('your_location'); }, () => { currentPosition = { ...DHaka }; map?.setView([DHaka.lat, DHaka.lng], 13); showToast(currentLang === 'bn' ? 'লোকেশন পাওয়া যায়নি, ঢাকা দেখানো হচ্ছে' : 'Location unavailable, showing Dhaka', 'warning'); }, { enableHighAccuracy: true, timeout: 8000 }); }
async function searchLocation(query) { const url = `https://nominatim.openstreetmap.org/search?q=${encodeURIComponent(query)}&format=json&limit=5&addressdetails=1&countrycodes=bd`; const response = await fetch(url, { headers: { Accept: 'application/json' } }); if (!response.ok) throw new Error('search failed'); return response.json(); }
function renderSearchResults(results) { const box = $('#searchResults'); box.innerHTML = ''; if (!results.length) { box.innerHTML = `<p class="empty-search">${currentLang === 'bn' ? 'কোনো বাংলাদেশি লোকেশন পাওয়া যায়নি' : 'No Bangladesh locations found'}</p>`; box.hidden = false; return; } results.forEach((result) => { const button = document.createElement('button'); button.className = 'search-result'; button.type = 'button'; button.setAttribute('role', 'option'); button.innerHTML = '<i data-lucide="map-pin"></i><span><strong></strong><small></small></span>'; button.querySelector('strong').textContent = result.display_name.split(',')[0]; button.querySelector('small').textContent = result.display_name; button.addEventListener('click', () => setDestination({ lat: Number(result.lat), lng: Number(result.lon) }, result.display_name)); box.appendChild(button); }); box.hidden = false; renderIcons(); }
function bookRide() { const fare = $('#fareAmount').textContent; const button = $('#bookButton'); let dots = 0; button.disabled = true; button.classList.add('loading'); $('#bookButtonText').textContent = t('finding_driver'); showToast(t('finding_driver'), 'info'); clearInterval(bookingTimer); bookingTimer = setInterval(() => { dots = (dots + 1) % 4; $('#bookButtonText').textContent = `${t('finding_driver')}${'.'.repeat(dots)}`; }, 500); setTimeout(() => { clearInterval(bookingTimer); button.classList.remove('loading'); button.classList.add('success'); $('#bookButtonText').textContent = t('driver_found'); state.currentRide = { id: Date.now(), fare, status: 'matched', driver: 'করিম', destination: $('#selectedDestination').textContent, createdAt: new Date().toISOString() }; showToast(t('driver_arriving'), 'success'); showDriverTracking(); }, 3000); }
async function bookRide() { const fare = $('#fareAmount').textContent; const button = $('#bookButton'); const dropoff = destinationMarker?.getLatLng(); button.disabled = true; button.classList.add('loading'); $('#bookButtonText').textContent = t('finding_driver'); try { if (!localStorage.getItem('pothik_access_token') || !dropoff) throw new Error('demo fallback'); const ride = await api.createRide({ pickupLat: currentPosition.lat, pickupLng: currentPosition.lng, pickupAddress: t('your_location'), dropoffLat: dropoff.lat, dropoffLng: dropoff.lng, dropoffAddress: $('#selectedDestination').textContent, vehicleType: 'economy' }); button.classList.remove('loading'); button.classList.add('success'); $('#bookButtonText').textContent = t('driver_found'); state.currentRide = { ...ride, fare: ride.estimatedFare, destination: ride.dropoffAddress }; showToast(t('driver_arriving'), 'success'); showDriverTracking(); } catch { button.classList.remove('loading'); button.classList.add('success'); $('#bookButtonText').textContent = t('driver_found'); state.currentRide = { id: Date.now(), fare, status: 'matched', destination: $('#selectedDestination').textContent }; showToast(t('driver_arriving'), 'success'); showDriverTracking(); } }
function showDriverTracking() { if (!driverMarker && map) { const icon = window.L.divIcon({ className: '', html: '<div class="driver-marker"></div>', iconSize: [18, 18], iconAnchor: [9, 9] }); driverMarker = window.L.marker([23.802, 90.416], { icon }).addTo(map).bindPopup('করিম · ৪ মিনিট দূরে'); } $('#bookButtonText').textContent = currentLang === 'bn' ? 'ড্রাইভার ট্র্যাক হচ্ছে' : 'Tracking driver'; setTimeout(() => { if (state.currentRide) { state.currentRide.status = 'completed'; $('#rideModal').hidden = false; $('#closeRideModal').focus(); } }, 5000); }
function resetDriverView() { state.driverStatus = 'offline'; $('#rideRequest').hidden = true; $('#onlineToggle').classList.remove('is-online'); $('#onlineToggle').setAttribute('aria-pressed', 'false'); applyTranslations(); }
function toggleDriver() { const online = state.driverStatus === 'offline'; state.driverStatus = online ? 'online' : 'offline'; $('#onlineToggle').classList.toggle('is-online', online); $('#onlineToggle').setAttribute('aria-pressed', String(online)); $('#driverStatusBadge').className = `status-badge ${online ? 'online' : 'offline'}`; $('#rideRequest').hidden = !online; applyTranslations(); if (online) { startRequestCountdown(); showToast(currentLang === 'bn' ? 'আপনি এখন রাইডের জন্য অনলাইন' : 'You are now online for rides', 'success'); } else { clearInterval(requestTimer); showToast(currentLang === 'bn' ? 'আপনি অফলাইনে আছেন' : 'You are offline', 'info'); } }
function startRequestCountdown() { let seconds = 20; $('#requestCountdown').textContent = `${seconds}s`; clearInterval(requestTimer); requestTimer = setInterval(() => { seconds -= 1; $('#requestCountdown').textContent = `${seconds}s`; if (seconds <= 0) { clearInterval(requestTimer); $('#rideRequest').hidden = true; showToast(currentLang === 'bn' ? 'রাইডের সময় শেষ হয়েছে' : 'Ride request expired', 'warning'); } }, 1000); }
function acceptRide() { clearInterval(requestTimer); state.driverStatus = 'on-trip'; $('#rideRequest').hidden = true; $('#driverMapPreview').innerHTML = `<i data-lucide="navigation"></i><span>${currentLang === 'bn' ? 'প্যাসেঞ্জারের কাছে যাচ্ছেন · ২.৩ কিমি' : 'Heading to passenger · 2.3 km'}</span>`; renderIcons(); showToast(currentLang === 'bn' ? 'রাইড গ্রহণ করা হয়েছে' : 'Ride accepted', 'success'); setTimeout(() => { state.earnings.today += 85; state.earnings.week += 85; state.earnings.month += 85; store.set('earnings', state.earnings); state.driverStatus = 'online'; updateEarningsUI(); applyTranslations(); showToast(currentLang === 'bn' ? 'রাইড সম্পন্ন, ৳৮৫ আয় হয়েছে' : 'Ride completed, ৳85 earned', 'success'); }, 3500); }
function setupAuth() { let otpSent = false; $('#authForm').addEventListener('submit', (event) => { event.preventDefault(); const phone = $('#phoneInput').value.trim(); const role = $('input[name="role"]:checked').value; if (!otpSent) { if (!/^01\d{9}$/.test(phone.replace(/\D/g, ''))) { showToast(currentLang === 'bn' ? 'সঠিক ১১ সংখ্যার ফোন নম্বর লিখুন' : 'Enter a valid 11-digit phone number', 'error'); return; } otpSent = true; $('#otpField').hidden = false; $('#otpInput').required = true; applyTranslations(); $('#otpInput').focus(); showToast(currentLang === 'bn' ? 'OTP পাঠানো হয়েছে · ডেমো: ১২৩৪' : 'OTP sent · Demo: 1234', 'info'); } else login(phone, $('#otpInput').value.trim(), role); }); }
function setupAuth() { let otpSent = false; $('#authForm').addEventListener('submit', async (event) => { event.preventDefault(); const phone = $('#phoneInput').value.trim(); const role = $('input[name="role"]:checked').value; if (!otpSent) { if (!/^01\d{9}$/.test(phone.replace(/\D/g, ''))) { showToast(currentLang === 'bn' ? 'সঠিক ১১ সংখ্যার ফোন নম্বর লিখুন' : 'Enter a valid 11-digit phone number', 'error'); return; } try { const result = await api.requestOtp(normalizePhone(phone)); otpSent = true; $('#otpField').hidden = false; $('#otpInput').required = true; applyTranslations(); $('#otpInput').focus(); showToast(`${currentLang === 'bn' ? 'OTP পাঠানো হয়েছে' : 'OTP sent'}${result.devOtp ? ` · ${result.devOtp}` : ''}`, 'info'); } catch { otpSent = true; $('#otpField').hidden = false; $('#otpInput').required = true; applyTranslations(); $('#otpInput').focus(); showToast(currentLang === 'bn' ? 'Backend পাওয়া যায়নি, ডেমো OTP: ১২৩৪' : 'Backend unavailable, demo OTP: 1234', 'warning'); } } else login(phone, $('#otpInput').value.trim(), role); }); }
function setupPassenger() { $('#searchInput').addEventListener('input', () => { const query = $('#searchInput').value.trim(); $('#clearSearch').hidden = !query; clearTimeout(searchTimer); if (query.length < 2) { $('#searchResults').hidden = true; return; } searchTimer = setTimeout(async () => { try { renderSearchResults(await searchLocation(query)); } catch { showToast(currentLang === 'bn' ? 'লোকেশন সার্চ করা যায়নি' : 'Location search failed', 'error'); } }, 450); }); $('#clearSearch').addEventListener('click', () => { $('#searchInput').value = ''; $('#clearSearch').hidden = true; $('#searchResults').hidden = true; $('#searchInput').focus(); }); $('#bookButton').addEventListener('click', bookRide); $('#locateBtn').addEventListener('click', locateUser); $('#zoomIn').addEventListener('click', () => map?.zoomIn()); $('#zoomOut').addEventListener('click', () => map?.zoomOut()); $('#paymentChoice').addEventListener('click', () => showToast(currentLang === 'bn' ? 'শুধুমাত্র নগদ পেমেন্ট সাপোর্টেড' : 'Cash payment only in demo', 'info')); $$('.nav-item[data-passenger-tab]').forEach((item) => item.addEventListener('click', () => { $$('.nav-item[data-passenger-tab]').forEach((nav) => { nav.classList.remove('active'); nav.removeAttribute('aria-current'); }); item.classList.add('active'); item.setAttribute('aria-current', 'page'); const key = item.dataset.passengerTab; if (key === 'history') showToast(`${t('history')}: ${state.rides.length} ${currentLang === 'bn' ? 'টি রাইড' : 'rides'}`, 'info'); if (key === 'profile') showToast(`${t('profile')} ${currentLang === 'bn' ? 'শিগগিরই আসছে' : 'coming soon'}`, 'info'); })); }
function setupFavorites() {}
function setupDriver() { $('#onlineToggle').addEventListener('click', toggleDriver); $('#acceptRide').addEventListener('click', acceptRide); $('#declineRide').addEventListener('click', () => { $('#rideRequest').hidden = true; showToast(t('decline'), 'info'); }); $('#driverEarningsTab').addEventListener('click', () => showToast(`${t('earnings')}: ৳${currentLang === 'bn' ? bnDigits(state.earnings.week) : state.earnings.week}`, 'info')); }
function setupAdmin() { $$('.approve-button').forEach((button) => button.addEventListener('click', () => { const row = button.closest('.table-row'); row.querySelector('.status-badge').textContent = t('approved'); row.querySelector('.status-badge').className = 'status-badge online'; row.querySelector('.row-actions').innerHTML = `<span class="status-badge online">${t('approved')}</span>`; state.drivers.push({ name: 'রহমান', status: 'approved' }); store.set('drivers', state.drivers); showToast(t('approved'), 'success'); })); $$('.reject-button').forEach((button) => button.addEventListener('click', () => { const row = button.closest('.table-row'); row.querySelector('.status-badge').textContent = t('rejected'); row.querySelector('.status-badge').style.cssText = 'background:#fbeaea;color:#d64545'; row.querySelector('.row-actions').innerHTML = `<span class="status-badge">${t('rejected')}</span>`; state.drivers.push({ name: 'রহমান', status: 'rejected' }); store.set('drivers', state.drivers); showToast(t('rejected'), 'warning'); })); $('#savePricing').addEventListener('click', () => { state.pricing.base = Number($('#baseFareInput').value) || 30; state.pricing.perKm = Number($('#perKmInput').value) || 12; store.set('pricing', state.pricing); showToast(currentLang === 'bn' ? 'প্রাইসিং সেটিংস সেভ হয়েছে' : 'Pricing settings saved', 'success'); }); $$('.sidebar-item').forEach((item) => item.addEventListener('click', () => { $$('.sidebar-item').forEach((nav) => nav.classList.remove('active')); item.classList.add('active'); showToast(item.textContent.trim(), 'info'); })); }
function setupShared() { ['#themeToggle', '#authThemeToggle', '#driverThemeToggle', '#adminThemeToggle'].forEach((selector) => $(selector)?.addEventListener('click', toggleTheme)); ['#langToggle', '#authLangToggle', '#driverLangToggle', '#adminLangToggle'].forEach((selector) => $(selector)?.addEventListener('click', toggleLanguage)); $('#closeRideModal').addEventListener('click', () => { $('#rideModal').hidden = true; $('#bookButton').classList.remove('success'); $('#bookButton').disabled = false; }); $('#rideModal').addEventListener('click', (event) => { if (event.target === $('#rideModal')) $('#rideModal').hidden = true; }); $$('#ratingStars button').forEach((button, index) => button.addEventListener('click', () => $$('#ratingStars button').forEach((star, starIndex) => star.classList.toggle('selected', starIndex <= index)))); $('#submitRating').addEventListener('click', () => { const rating = $$('#ratingStars button.selected').length; if (!rating) { showToast(currentLang === 'bn' ? 'একটি রেটিং নির্বাচন করুন' : 'Select a rating', 'warning'); return; } state.currentRide.rating = rating; state.ratings.push({ rideId: state.currentRide.id, rating }); state.rides.push(state.currentRide); store.set('ratings', state.ratings); store.set('rides', state.rides); $('#rideModal').hidden = true; showToast(currentLang === 'bn' ? 'রেটিং জমা দেওয়ার জন্য ধন্যবাদ' : 'Thanks for your rating', 'success'); }); $('#adminLogout').addEventListener('click', () => { state.isLoggedIn = false; store.set('session', null); showScreen('auth'); }); $('#menuButton')?.addEventListener('click', () => showToast(currentLang === 'bn' ? 'মেনু শিগগিরই আসছে' : 'Menu coming soon', 'info')); $('#notificationButton')?.addEventListener('click', () => showToast(state.notifications.length ? t('notifications') : t('no_notifications'), 'info')); }
function injectAdminControls() { const header = $('.admin-topbar'); if (!header || header.querySelector('#adminThemeToggle')) return; const controls = document.createElement('div'); controls.className = 'app-controls'; controls.innerHTML = '<button class="icon-button" id="adminThemeToggle" type="button" aria-label="Toggle theme"><i data-lucide="moon"></i></button><button class="lang-toggle" id="adminLangToggle" type="button" aria-label="Switch language">EN</button>'; header.appendChild(controls); }
async function boot() { showSplash(); loadTheme(); loadSavedData(); injectAdminControls(); await loadLanguage(currentLang); renderIcons(); setupAuth(); setupPassenger(); setupFavorites(); setupDriver(); setupAdmin(); setupEmergencyAdmin(); setupShared(); setupNavigation(); setupSos(); initMap(); if ('serviceWorker' in navigator && location.protocol !== 'file:') navigator.serviceWorker.register('./sw.js?v=6').catch(() => {}); const session = store.get('session', null); if (session?.role) { state.currentUser = session; state.isLoggedIn = true; showScreen(session.role); $('#sosButton').hidden = false; } }
if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', boot, { once: true }); else boot();
window.matchMedia?.('(prefers-color-scheme: dark)').addEventListener('change', (event) => { if (!localStorage.getItem('pothik_theme')) setTheme(event.matches ? 'dark' : 'light'); });
function navigateTo(page) {
  const subpage = $('#subpageScreen');
  if (page === 'home') { subpage.hidden = true; $('.app-screen:not(.admin-screen)')?.removeAttribute('aria-hidden'); return; }
  subpage.hidden = false;
  const titleMap = { history: 'history', profile: 'profile', notifications: 'notifications', favorites: 'favorites', driverProfile: 'profile' };
  $('#subpageTitle').textContent = t(titleMap[page] || page);
  $('#subpageAction').hidden = !['history'].includes(page);
  $('#subpageContent').innerHTML = renderSubpage(page);
  renderIcons();
}

function renderSubpage(page) {
  if (page === 'history') {
    const rides = state.rides;
    return `<div class="filter-row"><button class="filter-chip active" data-filter="all" type="button">${currentLang === 'bn' ? 'সব' : 'All'}</button><button class="filter-chip" data-filter="completed" type="button">${currentLang === 'bn' ? 'সম্পন্ন' : 'Completed'}</button><button class="filter-chip" data-filter="cancelled" type="button">${currentLang === 'bn' ? 'বাতিল' : 'Cancelled'}</button></div><div id="historyList">${rides.length ? rides.map((ride) => `<article class="page-card history-row" data-status="${ride.status || 'completed'}" data-ride-id="${ride.id}"><span class="history-icon"><i data-lucide="receipt-text"></i></span><div><h3>${ride.destination || 'ঢাকা'}</h3><p>${new Date(ride.createdAt || Date.now()).toLocaleString(currentLang === 'bn' ? 'bn-BD' : 'en-US')} · ৳${ride.fare}</p></div><span class="status-badge online">${t('completed')}</span></article>`).join('') : `<article class="page-card empty-state"><i data-lucide="car-front"></i><h2>${t('no_rides')}</h2><p>${currentLang === 'bn' ? 'আপনার প্রথম রাইড বুক করুন' : 'Book your first ride'}</p><button class="primary-button" data-empty-action="home" type="button">${t('book_ride')}</button></article>`}</div>`;
  }
  if (page === 'favorites') return `<div class="panel-heading"><h2>${t('favorites')}</h2><button class="accent-button" id="addFavorite" type="button">${currentLang === 'bn' ? 'নতুন যোগ করুন' : 'Add new'}</button></div>${state.favorites.length ? state.favorites.map((favorite, index) => `<article class="page-card favorite-row"><span class="favorite-icon"><i data-lucide="heart"></i></span><div><h3>${favorite}</h3><p>${currentLang === 'bn' ? 'সংরক্ষিত গন্তব্য' : 'Saved destination'}</p></div><button class="row-action" data-favorite-select="${index}" type="button">${currentLang === 'bn' ? 'নির্বাচন' : 'Select'}</button><button class="row-action" data-favorite-remove="${index}" type="button" aria-label="Remove favorite">×</button></article>`).join('') : `<article class="page-card empty-state"><i data-lucide="heart"></i><h2>${currentLang === 'bn' ? 'কোনো ফেভারিট নেই' : 'No favorites yet'}</h2></article>`}`;
  if (page === 'notifications') return `<div class="panel-heading"><h2>${t('notifications')}</h2><button class="text-button" id="markAllRead" type="button">${currentLang === 'bn' ? 'সব পড়া হয়েছে' : 'Mark all read'}</button></div>${state.notifications.length ? state.notifications.map((item, index) => `<article class="page-card notification-row ${item.read ? '' : 'unread'}"><span class="notification-icon"><i data-lucide="${item.type === 'sos' ? 'siren' : 'bell'}"></i></span><div><h3>${item.title}</h3><p>${item.description}</p><small class="muted">${item.time || 'just now'}</small></div><button class="row-action" data-notification-dismiss="${index}" type="button" aria-label="Dismiss notification">×</button></article>`).join('') : `<article class="page-card empty-state"><i data-lucide="bell-off"></i><h2>${t('no_notifications')}</h2></article>`}`;
  const driver = page === 'driverProfile';
  return `<article class="page-card profile-hero"><span class="avatar">${(state.currentUser?.name || (driver ? 'D' : 'P')).charAt(0)}</span><div><h2>${state.currentUser?.name || (driver ? t('driver') : t('passenger'))}</h2><p>${state.currentUser?.phone || '01700000000'}</p><span class="status-badge ${driver && state.driverStatus === 'online' ? 'online' : 'offline'}">${driver ? t(state.driverStatus === 'online' ? 'online' : 'offline') : t('passenger')}</span></div></article><article class="page-card"><h2>${driver ? (currentLang === 'bn' ? 'গাড়ির তথ্য' : 'Vehicle details') : (currentLang === 'bn' ? 'ব্যক্তিগত তথ্য' : 'Personal information')}</h2>${driver ? '<p>টয়োটা প্রিয়াস · সাদা</p><p>ঢাকা মেট্রো · গাড়ি নং ঢাকা-১২৩৪</p>' : `<p>${currentLang === 'bn' ? 'নাম' : 'Name'}: ${state.currentUser?.name || t('passenger')}</p><p>${currentLang === 'bn' ? 'ফোন' : 'Phone'}: ${state.currentUser?.phone || '01700000000'}</p>`}</article><article class="page-card"><div class="profile-grid"><div class="profile-stat"><strong>${driver ? state.rides.length : state.rides.length}</strong><span>${currentLang === 'bn' ? 'মোট রাইড' : 'Total rides'}</span></div><div class="profile-stat"><strong>৪.৮</strong><span>${currentLang === 'bn' ? 'রেটিং' : 'Rating'}</span></div><div class="profile-stat"><strong>৳${currentLang === 'bn' ? bnDigits(state.earnings.today) : state.earnings.today}</strong><span>${t('today')}</span></div></div></article><article class="page-card"><h2>${currentLang === 'bn' ? 'পছন্দ ও অ্যাকাউন্ট' : 'Preferences & account'}</h2><button class="secondary-button" id="editProfile" type="button">${currentLang === 'bn' ? 'প্রোফাইল এডিট' : 'Edit profile'}</button><button class="secondary-button" id="profileLogout" type="button">${t('logout')}</button></article>`;
}

function refreshSubpageHandlers() {
  $('#subpageContent')?.querySelectorAll('[data-filter]').forEach((button) => button.addEventListener('click', () => { $('#subpageContent').querySelectorAll('.filter-chip').forEach((chip) => chip.classList.remove('active')); button.classList.add('active'); $('#historyList')?.querySelectorAll('[data-status]').forEach((ride) => { ride.hidden = button.dataset.filter !== 'all' && ride.dataset.status !== button.dataset.filter; }); }));
  $('#subpageContent')?.querySelector('[data-empty-action="home"]')?.addEventListener('click', () => navigateTo('home'));
  $('#subpageContent')?.querySelector('#addFavorite')?.addEventListener('click', () => { const name = window.prompt(currentLang === 'bn' ? 'ফেভারিটের নাম লিখুন' : 'Favorite name'); if (name) { state.favorites.push(name); store.set('favorites', state.favorites); navigateTo('favorites'); } });
  $('#subpageContent')?.querySelectorAll('[data-favorite-remove]').forEach((button) => button.addEventListener('click', () => { state.favorites.splice(Number(button.dataset.favoriteRemove), 1); store.set('favorites', state.favorites); navigateTo('favorites'); }));
  $('#subpageContent')?.querySelectorAll('[data-favorite-select]').forEach((button) => button.addEventListener('click', () => { $('#searchInput').value = state.favorites[Number(button.dataset.favoriteSelect)]; navigateTo('home'); $('#searchInput').dispatchEvent(new Event('input')); }));
  $('#subpageContent')?.querySelector('#markAllRead')?.addEventListener('click', () => { state.notifications.forEach((item) => { item.read = true; }); store.set('notifications', state.notifications); navigateTo('notifications'); });
  $('#subpageContent')?.querySelectorAll('[data-notification-dismiss]').forEach((button) => button.addEventListener('click', () => { state.notifications.splice(Number(button.dataset.notificationDismiss), 1); store.set('notifications', state.notifications); navigateTo('notifications'); }));
  $('#subpageContent')?.querySelector('#profileLogout')?.addEventListener('click', () => { store.set('session', null); state.isLoggedIn = false; navigateTo('home'); showScreen('auth'); });
  $('#subpageContent')?.querySelector('#editProfile')?.addEventListener('click', () => { const name = window.prompt(currentLang === 'bn' ? 'নতুন নাম লিখুন' : 'Enter your name', state.currentUser?.name); if (name) { state.currentUser.name = name; store.set('session', state.currentUser); navigateTo('profile'); } });
}

function setupNavigation() {
  $('#subpageBack')?.addEventListener('click', () => navigateTo('home'));
  $$('.nav-item[data-passenger-tab]').forEach((item) => item.addEventListener('click', () => navigateTo(item.dataset.passengerTab)));
  $$('.driver-nav .nav-item').forEach((item, index) => item.addEventListener('click', () => { if (index === 2) navigateTo('driverProfile'); else if (index === 1) showToast(`${t('earnings')}: ৳${currentLang === 'bn' ? bnDigits(state.earnings.week) : state.earnings.week}`, 'info'); else navigateTo('home'); }));
  $('#notificationButton')?.addEventListener('click', () => navigateTo('notifications'));
  $('#driverNotificationButton')?.addEventListener('click', () => navigateTo('notifications'));
  $('#savedPlacesButton')?.addEventListener('click', () => navigateTo('favorites'));
}

let sosTimer; let sosLocationTimer;
function updateSosLocation() { navigator.geolocation?.getCurrentPosition((position) => { $('#sosLocation').textContent = `${position.coords.latitude.toFixed(5)}, ${position.coords.longitude.toFixed(5)}`; }, () => { $('#sosLocation').textContent = `${DHaka.lat}, ${DHaka.lng} · ${currentLang === 'bn' ? 'ঢাকা' : 'Dhaka'}`; }); }
function triggerSos() { if (state.currentUser?.role !== 'passenger') { showToast(currentLang === 'bn' ? 'SOS শুধু প্যাসেঞ্জারের জন্য সক্রিয়' : 'SOS is available to passengers', 'warning'); return; } $('#sosModal').hidden = false; $('#closeSos').focus(); renderContacts(); updateSosLocation(); clearInterval(sosLocationTimer); sosLocationTimer = setInterval(updateSosLocation, 3000); state.notifications.unshift({ type: 'sos', title: currentLang === 'bn' ? 'SOS সতর্কতা' : 'SOS alert', description: currentLang === 'bn' ? 'আপনার জরুরি যোগাযোগকে জানানো হয়েছে' : 'Your emergency contacts were notified', time: 'just now', read: false }); store.set('notifications', state.notifications); showToast(currentLang === 'bn' ? 'SOS Alert! Contacts notified.' : 'SOS Alert! Contacts notified.', 'error'); }
function renderContacts() { const contacts = store.get('emergencyContacts', [{ name: 'মা', phone: '01700000001' }, { name: 'জরুরি যোগাযোগ', phone: '01700000002' }]); $('#emergencyContacts').innerHTML = contacts.map((contact) => `<div class="contact-row"><span><strong>${contact.name}</strong><small>${contact.phone}</small></span><i data-lucide="phone"></i></div>`).join(''); renderIcons(); }
function setupSos() { const button = $('#sosButton'); const start = () => { button.classList.add('is-pressing'); sosTimer = setTimeout(() => { button.classList.remove('is-pressing'); triggerSos(); }, 1000); }; const cancel = () => { clearTimeout(sosTimer); button.classList.remove('is-pressing'); }; button.addEventListener('pointerdown', start); button.addEventListener('pointerup', cancel); button.addEventListener('pointerleave', cancel); button.addEventListener('keydown', (event) => { if (event.key === ' ') start(); }); $('#cancelSos').addEventListener('click', () => { $('#sosModal').hidden = true; clearInterval(sosLocationTimer); }); $('#closeSos').addEventListener('click', () => { $('#sosModal').hidden = true; clearInterval(sosLocationTimer); }); }

function setupEmergencyAdmin() { const content = $('.admin-content'); if (!content || $('#adminContactsPanel')) return; const panel = document.createElement('section'); panel.className = 'admin-panel pricing-panel'; panel.id = 'adminContactsPanel'; panel.innerHTML = `<div class="panel-heading"><h2>${currentLang === 'bn' ? 'জরুরি যোগাযোগ' : 'Emergency contacts'}</h2><button class="text-button" id="addEmergencyContact" type="button">${currentLang === 'bn' ? 'যোগ করুন' : 'Add'}</button></div><div id="adminContactsList"></div>`; content.appendChild(panel); const render = () => { const contacts = store.get('emergencyContacts', [{ name: 'মা', phone: '01700000001' }, { name: 'জরুরি যোগাযোগ', phone: '01700000002' }]); $('#adminContactsList').innerHTML = contacts.map((contact, index) => `<div class="contact-row"><span><strong>${contact.name}</strong><small>${contact.phone}</small></span><button class="row-action" data-edit-contact="${index}" type="button">${currentLang === 'bn' ? 'এডিট' : 'Edit'}</button><button class="row-action" data-remove-contact="${index}" type="button">×</button></div>`).join(''); $('#adminContactsList').querySelectorAll('[data-remove-contact]').forEach((button) => button.addEventListener('click', () => { contacts.splice(Number(button.dataset.removeContact), 1); store.set('emergencyContacts', contacts); render(); })); $('#adminContactsList').querySelectorAll('[data-edit-contact]').forEach((button) => button.addEventListener('click', () => { const index = Number(button.dataset.editContact); const name = window.prompt('Name', contacts[index].name); const phone = window.prompt('Phone', contacts[index].phone); if (name && phone) { contacts[index] = { name, phone }; store.set('emergencyContacts', contacts); render(); } })); }; $('#addEmergencyContact').addEventListener('click', () => { const name = window.prompt('Name'); const phone = window.prompt('Phone'); if (name && phone) { const contacts = store.get('emergencyContacts', []); contacts.push({ name, phone }); store.set('emergencyContacts', contacts); render(); } }); render(); }
const originalShowScreen = showScreen;
showScreen = function showScreenWithSos(role) { originalShowScreen(role); $('#sosButton').hidden = role === 'auth'; if (role === 'auth') $('#subpageScreen').hidden = true; };
const originalNavigateTo = navigateTo;
navigateTo = function navigateWithHandlers(page) { originalNavigateTo(page); refreshSubpageHandlers(); };
window.addEventListener('resize', () => map?.invalidateSize());

function showSplash() {
  const splash = document.querySelector('#splashScreen');
  if (!splash) return;
  splash.hidden = false;
  splash.classList.remove('is-leaving');
  const dismissDelay = window.matchMedia?.('(prefers-reduced-motion: reduce)').matches ? 0 : 2850;
  window.setTimeout(() => splash.classList.add('is-leaving'), dismissDelay);
  window.setTimeout(() => { splash.hidden = true; }, dismissDelay + 650);
}

function setupRoleCardFeedback() {
  document.querySelectorAll('.role-card').forEach((card) => {
    card.addEventListener('click', () => {
      card.classList.remove('is-clicked');
      requestAnimationFrame(() => card.classList.add('is-clicked'));
      window.setTimeout(() => card.classList.remove('is-clicked'), 180);
    });
  });
}

setupRoleCardFeedback();

function haptic(pattern = 10) {
  if (navigator.vibrate) navigator.vibrate(pattern);
}

function setupEnhancedUX() {
  document.addEventListener('click', (event) => {
    const interactive = event.target.closest('button, .search-result, .page-card');
    if (interactive) haptic(10);
  }, { passive: true });

  document.addEventListener('touchstart', (event) => {
    const item = event.target.closest('.history-row, .notification-row, .favorite-row');
    if (!item) return;
    const startX = event.touches[0].clientX;
    const startTime = Date.now();
    let longPressTimer = window.setTimeout(() => {
      item.classList.add('is-clicked');
      haptic([10, 50, 10]);
      showToast(currentLang === 'bn' ? 'অ্যাকশন মেনু খুলতে ট্যাপ করুন' : 'Tap to open actions', 'info');
    }, 650);
    const finish = (endEvent) => {
      clearTimeout(longPressTimer);
      item.classList.remove('is-clicked');
      const endX = endEvent.changedTouches?.[0]?.clientX ?? startX;
      const deltaX = endX - startX;
      if (Math.abs(deltaX) > 70) {
        item.classList.add('swipe-removing');
        haptic(10);
        window.setTimeout(() => item.remove(), 250);
      } else if (Date.now() - startTime < 500) {
        item.classList.add('is-clicked');
        window.setTimeout(() => item.classList.remove('is-clicked'), 160);
      }
      item.removeEventListener('touchend', finish);
      item.removeEventListener('touchcancel', finish);
    };
    item.addEventListener('touchend', finish, { once: true });
    item.addEventListener('touchcancel', finish, { once: true });
  }, { passive: true });

  ['#subpageContent', '#driverScreen', '#adminScreen'].forEach((selector) => {
    const container = $(selector);
    if (!container) return;
    let startY = 0;
    container.addEventListener('touchstart', (event) => { if (container.scrollTop === 0) startY = event.touches[0].clientY; }, { passive: true });
    container.addEventListener('touchend', (event) => {
      const distance = event.changedTouches[0].clientY - startY;
      if (startY && distance > 90 && container.scrollTop === 0) {
        showToast(currentLang === 'bn' ? 'তথ্য রিফ্রেশ হয়েছে' : 'Content refreshed', 'success');
        haptic([10, 50, 10]);
      }
      startY = 0;
    }, { passive: true });
  });

  if (map) {
    let lastTap = 0;
    $('#map')?.addEventListener('touchend', () => {
      const now = Date.now();
      if (now - lastTap < 300) map.zoomIn();
      lastTap = now;
    }, { passive: true });
  }
}

setupEnhancedUX();
