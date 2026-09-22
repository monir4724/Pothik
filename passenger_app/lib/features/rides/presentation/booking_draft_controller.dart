import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../domain/ride_models.dart';

/// Pickup/drop-off the user is composing before requesting a quote.
final class BookingDraft {
  const BookingDraft({this.pickup, this.dropoff, this.note});

  final Place? pickup;
  final Place? dropoff;
  final String? note;

  bool get isComplete => pickup != null && dropoff != null;

  BookingDraft copyWith({
    Object? pickup = _s,
    Object? dropoff = _s,
    Object? note = _s,
  }) => BookingDraft(
    pickup: pickup == _s ? this.pickup : pickup as Place?,
    dropoff: dropoff == _s ? this.dropoff : dropoff as Place?,
    note: note == _s ? this.note : note as String?,
  );

  static const _s = Object();
}

final bookingDraftProvider =
    NotifierProvider<BookingDraftController, BookingDraft>(
      BookingDraftController.new,
    );

final class BookingDraftController extends Notifier<BookingDraft> {
  @override
  BookingDraft build() => const BookingDraft();

  void setPickup(Place? p) => state = state.copyWith(pickup: p);
  void setDropoff(Place? p) => state = state.copyWith(dropoff: p);
  void setNote(String? n) => state = state.copyWith(note: n);
  void clear() => state = const BookingDraft();
}

/// Server quote for the current draft. Re-created whenever pickup/drop-off
/// change; the estimate screen invalidates it when the quote expires.
final fareQuoteProvider = FutureProvider.autoDispose<FareQuote>((ref) async {
  final draft = ref.watch(bookingDraftProvider);
  if (!draft.isComplete) throw StateError('draft incomplete');
  return ref
      .read(rideRepositoryProvider)
      .estimate(pickup: draft.pickup!, dropoff: draft.dropoff!);
});
