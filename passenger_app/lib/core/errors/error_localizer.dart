import '../../l10n/generated/app_localizations.dart';
import '../network/api_exception.dart';

/// Maps any thrown error to user-facing copy in the active language.
/// Raw server text never reaches the screen.
abstract final class ErrorLocalizer {
  static String message(AppLocalizations l, Object error) {
    if (error is! ApiException) return l.errorUnknown;

    // Business codes take precedence over HTTP class.
    switch (error.serverCode) {
      case ServerErrorCodes.activeRideExists:
        return l.errorActiveRideExists;
      case ServerErrorCodes.otpInvalid:
        return l.errorOtpInvalid;
      case ServerErrorCodes.otpExpired:
        return l.errorOtpExpired;
      case ServerErrorCodes.rideNotCancellable:
        return l.errorRideNotCancellable;
      case ServerErrorCodes.chatClosed:
        return l.errorChatClosed;
      case ServerErrorCodes.tripNotActive:
        return l.errorTripNotActive;
    }

    return switch (error.code) {
      ApiErrorCode.network => l.errorNetwork,
      ApiErrorCode.timeout => l.errorTimeout,
      ApiErrorCode.unauthenticated => l.errorSessionExpired,
      ApiErrorCode.forbidden => l.errorForbidden,
      ApiErrorCode.notFound => l.errorNotFound,
      ApiErrorCode.conflict => l.errorConflict,
      ApiErrorCode.validation => l.errorValidation,
      ApiErrorCode.rateLimited => l.errorRateLimited(
        ((error.retryAfter ?? const Duration(minutes: 10)).inSeconds / 60)
            .ceil()
            .clamp(1, 60),
      ),
      ApiErrorCode.server => l.errorServer,
      ApiErrorCode.cancelled || ApiErrorCode.unknown => l.errorUnknown,
    };
  }
}
