import 'package:equatable/equatable.dart';

enum Gender {
  male('male'),
  female('female'),
  other('other');

  const Gender(this.wire);
  final String wire;

  static Gender? fromWire(String? w) {
    if (w == null || w.isEmpty) return null;
    for (final g in values) {
      if (g.wire == w) return g;
    }
    return null;
  }
}

final class User extends Equatable {
  const User({
    required this.id,
    required this.phone,
    this.name,
    this.email,
    this.locale,
    this.photoUrl,
    this.username,
    this.gender,
    this.dateOfBirth,
  });

  factory User.fromJson(Map<String, Object?> j) => User(
    id: j['id'].toString(),
    phone: j['phone'] as String,
    name: j['name'] as String?,
    email: j['email'] as String?,
    locale: j['locale'] as String?,
    photoUrl: j['photo_url'] as String?,
    username: j['username'] as String?,
    gender: Gender.fromWire(j['gender'] as String?),
    dateOfBirth: j['date_of_birth'] == null
        ? null
        : DateTime.tryParse(j['date_of_birth'] as String),
  );

  final String id;
  final String phone;
  final String? name;
  final String? email;
  final String? locale;
  final String? photoUrl;
  final String? username;
  final Gender? gender;
  final DateTime? dateOfBirth;

  bool get isProfileComplete => (name ?? '').trim().isNotEmpty;

  Map<String, Object?> toJson() => {
    'id': id,
    'phone': phone,
    'name': name,
    'email': email,
    'locale': locale,
    'photo_url': photoUrl,
    'username': username,
    'gender': gender?.wire,
    'date_of_birth': dateOfBirth?.toUtc().toIso8601String(),
  };

  User copyWith({
    String? phone,
    String? name,
    String? email,
    String? locale,
    String? photoUrl,
    bool clearPhoto = false,
    String? username,
    Gender? gender,
    DateTime? dateOfBirth,
    bool clearDateOfBirth = false,
  }) => User(
    id: id,
    phone: phone ?? this.phone,
    name: name ?? this.name,
    email: email ?? this.email,
    locale: locale ?? this.locale,
    photoUrl: clearPhoto ? null : (photoUrl ?? this.photoUrl),
    username: username ?? this.username,
    gender: gender ?? this.gender,
    dateOfBirth: clearDateOfBirth
        ? null
        : (dateOfBirth ?? this.dateOfBirth),
  );

  @override
  List<Object?> get props => [
    id,
    phone,
    name,
    email,
    locale,
    photoUrl,
    username,
    gender,
    dateOfBirth,
  ];
}

/// Result of requesting an OTP. The server tells us when resend is allowed;
/// the client never invents its own throttle window.
final class OtpChallenge extends Equatable {
  const OtpChallenge({
    required this.phone,
    required this.resendAfter,
    required this.expiresIn,
  });

  factory OtpChallenge.fromJson(String phone, Map<String, Object?> j) =>
      OtpChallenge(
        phone: phone,
        resendAfter: Duration(seconds: (j['resend_after_s'] as num).toInt()),
        expiresIn: Duration(seconds: (j['expires_in_s'] as num).toInt()),
      );

  final String phone;
  final Duration resendAfter;
  final Duration expiresIn;

  @override
  List<Object?> get props => [phone, resendAfter, expiresIn];
}

final class EmergencyContact extends Equatable {
  const EmergencyContact({
    required this.id,
    required this.name,
    required this.phone,
    this.relation,
  });

  factory EmergencyContact.fromJson(Map<String, Object?> j) => EmergencyContact(
    id: j['id'].toString(),
    name: j['name'] as String,
    phone: j['phone'] as String,
    relation: j['relation'] as String?,
  );

  final String id;
  final String name;
  final String phone;
  final String? relation;

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'phone': phone,
    'relation': relation,
  };

  @override
  List<Object?> get props => [id, name, phone, relation];
}
