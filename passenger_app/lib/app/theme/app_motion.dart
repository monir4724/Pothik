import 'package:flutter/widgets.dart';

/// Animation timing tokens + the reduce-motion contract.
///
/// Every animated element must go through [AppMotion.duration] (or check
/// [AppMotion.reduced]) so the OS "remove animations" setting is honoured
/// app-wide. Static fallbacks are the *default* when motion is reduced.
abstract final class AppMotion {
  static const Duration instant = Duration.zero;
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);
  static const Duration pulse = Duration(milliseconds: 1400);
  static const Duration markerInterpolation = Duration(milliseconds: 900);
  static const Duration sosHold = Duration(seconds: 3);
  static const Duration shake = Duration(milliseconds: 350);

  static const Curve standard = Curves.easeInOutCubic;
  static const Curve emphasized = Curves.easeOutBack;
  static const Curve decelerate = Curves.decelerate;

  /// True when the platform asks for reduced motion
  /// (Android "Remove animations", iOS "Reduce Motion").
  static bool reduced(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context);

  /// Returns [d], or zero when the user has asked for reduced motion.
  static Duration duration(BuildContext context, Duration d) =>
      reduced(context) ? instant : d;
}
