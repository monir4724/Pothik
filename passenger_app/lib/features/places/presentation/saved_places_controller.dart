import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../rides/domain/ride_models.dart';
import '../domain/saved_place.dart';

final savedPlacesProvider =
    AsyncNotifierProvider<SavedPlacesController, List<SavedPlace>>(
      SavedPlacesController.new,
    );

final class SavedPlacesController extends AsyncNotifier<List<SavedPlace>> {
  @override
  Future<List<SavedPlace>> build() =>
      ref.read(placesRepositoryProvider).saved();

  Future<void> add({
    required SavedPlaceKind kind,
    required String label,
    required Place place,
  }) async {
    final created = await ref
        .read(placesRepositoryProvider)
        .save(kind: kind, label: label, place: place);
    state = AsyncData([...state.value ?? const [], created]);
  }

  /// Optimistic delete with undo support: returns the removed item so the
  /// caller can restore it if the user taps Undo before the server call.
  Future<void> remove(String id) async {
    final before = state.value ?? const <SavedPlace>[];
    state = AsyncData(before.where((p) => p.id != id).toList());
    try {
      await ref.read(placesRepositoryProvider).delete(id);
    } on Object {
      state = AsyncData(before);
      rethrow;
    }
  }

  void restore(SavedPlace p) {
    final current = state.value ?? const <SavedPlace>[];
    if (current.any((x) => x.id == p.id)) return;
    state = AsyncData([...current, p]);
  }
}
