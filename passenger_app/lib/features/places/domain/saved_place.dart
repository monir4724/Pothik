import 'package:equatable/equatable.dart';

import '../../rides/domain/ride_models.dart';

enum SavedPlaceKind {
  home('home'),
  work('work'),
  other('other');

  const SavedPlaceKind(this.wire);

  final String wire;

  static SavedPlaceKind fromWire(String w) =>
      values.firstWhere((k) => k.wire == w, orElse: () => SavedPlaceKind.other);
}

final class SavedPlace extends Equatable {
  const SavedPlace({
    required this.id,
    required this.kind,
    required this.label,
    required this.place,
  });

  factory SavedPlace.fromJson(Map<String, Object?> j) => SavedPlace(
    id: j['id'].toString(),
    kind: SavedPlaceKind.fromWire(j['kind'] as String),
    label: j['label'] as String,
    place: Place.fromJson(j['place'] as Map<String, Object?>),
  );

  final String id;
  final SavedPlaceKind kind;
  final String label;
  final Place place;

  Map<String, Object?> toJson() => {
    'id': id,
    'kind': kind.wire,
    'label': label,
    'place': place.toJson(),
  };

  @override
  List<Object?> get props => [id, kind, label, place];
}
