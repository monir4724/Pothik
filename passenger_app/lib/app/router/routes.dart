/// Route path constants. Keep in one place so redirects and deep links
/// never drift from the screens.
abstract final class Routes {
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const phone = '/auth/phone';
  static const otp = '/auth/otp';
  static const profileSetup = '/auth/profile';
  static const locationPermission = '/permission/location';
  static const home = '/home';
  static const search = '/search';
  static const estimate = '/estimate';
  static const history = '/history';
  static const places = '/places';
  static const profile = '/profile';
  static const profileEdit = '/profile/edit';
  static const emergencyContacts = '/profile/emergency-contacts';
  static const accountSecurity = '/profile/security';
  static const changePhone = '/profile/change-phone';
  static const payments = '/profile/payments';
  static const ratings = '/profile/ratings';
  static const promotions = '/profile/promotions';
  static const notifications = '/profile/notifications';
  static const help = '/profile/help';
  static const appSettings = '/profile/settings';
  static const scheduledRides = '/profile/scheduled';

  static String ride(String id) => '/ride/$id';
  static String finding(String id) => '/ride/$id/finding';
  static String chat(String id) => '/ride/$id/chat';
  static String complete(String id) => '/ride/$id/complete';
  static String rate(String id) => '/ride/$id/rate';
  static String historyDetail(String id) => '/history/$id';

  static bool isAuthRoute(String path) => path.startsWith('/auth/');
  static bool isRideRoute(String path) => path.startsWith('/ride/');
}
