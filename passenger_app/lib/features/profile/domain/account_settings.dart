import 'package:equatable/equatable.dart';

enum PaymentKind {
  cash('cash'),
  bkash('bkash'),
  nagad('nagad'),
  rocket('rocket'),
  card('card'),
  wallet('wallet');

  const PaymentKind(this.wire);
  final String wire;

  static PaymentKind fromWire(String w) => values.firstWhere(
    (k) => k.wire == w,
    orElse: () => PaymentKind.cash,
  );
}

final class SavedPaymentMethod extends Equatable {
  const SavedPaymentMethod({
    required this.id,
    required this.kind,
    required this.label,
    this.detail,
    this.isDefault = false,
  });

  factory SavedPaymentMethod.fromJson(Map<String, Object?> j) =>
      SavedPaymentMethod(
        id: j['id'].toString(),
        kind: PaymentKind.fromWire(j['kind'] as String? ?? 'cash'),
        label: j['label'] as String? ?? '',
        detail: j['detail'] as String?,
        isDefault: j['is_default'] as bool? ?? false,
      );

  final String id;
  final PaymentKind kind;
  final String label;
  final String? detail;
  final bool isDefault;

  SavedPaymentMethod copyWith({bool? isDefault}) => SavedPaymentMethod(
    id: id,
    kind: kind,
    label: label,
    detail: detail,
    isDefault: isDefault ?? this.isDefault,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'kind': kind.wire,
    'label': label,
    'detail': detail,
    'is_default': isDefault,
  };

  @override
  List<Object?> get props => [id, kind, label, detail, isDefault];
}

final class DriverReviewGiven extends Equatable {
  const DriverReviewGiven({
    required this.id,
    required this.driverName,
    required this.stars,
    required this.at,
    this.comment,
    this.tripId,
  });

  factory DriverReviewGiven.fromJson(Map<String, Object?> j) =>
      DriverReviewGiven(
        id: j['id'].toString(),
        driverName: j['driver_name'] as String? ?? '',
        stars: (j['stars'] as num?)?.toInt() ?? 0,
        at: DateTime.parse(j['at'] as String),
        comment: j['comment'] as String?,
        tripId: j['trip_id'] as String?,
      );

  final String id;
  final String driverName;
  final int stars;
  final DateTime at;
  final String? comment;
  final String? tripId;

  Map<String, Object?> toJson() => {
    'id': id,
    'driver_name': driverName,
    'stars': stars,
    'at': at.toUtc().toIso8601String(),
    'comment': comment,
    'trip_id': tripId,
  };

  @override
  List<Object?> get props => [id, driverName, stars, at, comment, tripId];
}

final class AccountSettings extends Equatable {
  const AccountSettings({
    this.walletBalance = 0,
    this.defaultPayment = PaymentKind.cash,
    this.methods = const [
      SavedPaymentMethod(
        id: 'pay-cash',
        kind: PaymentKind.cash,
        label: 'Cash',
        isDefault: true,
      ),
    ],
    this.referralCode = '',
    this.rewardPoints = 0,
    this.promos = const [],
    this.notifRide = true,
    this.notifPromo = false,
    this.notifSms = true,
    this.notifEmail = false,
    this.themeMode = 'light',
    this.mapType = 'normal',
    this.googleLinked = false,
    this.facebookLinked = false,
    this.twoFactor = true,
    this.reviews = const [],
    this.accessibilityLargeText = false,
    this.overallRating = 4.9,
    this.tripsCompleted = 0,
  });

  factory AccountSettings.seed(String phone) {
    final tail = phone.replaceAll(RegExp(r'\D'), '');
    final code = 'PTH${tail.length >= 4 ? tail.substring(tail.length - 4) : tail}';
    return AccountSettings(
      referralCode: code,
      rewardPoints: 120,
      tripsCompleted: 18,
      overallRating: 4.9,
      reviews: [
        DriverReviewGiven(
          id: 'rv1',
          driverName: 'Rahim Uddin',
          stars: 5,
          at: DateTime.now().subtract(const Duration(days: 3)),
          comment: 'Safe and on time',
          tripId: 'h0',
        ),
        DriverReviewGiven(
          id: 'rv2',
          driverName: 'Karim Mia',
          stars: 4,
          at: DateTime.now().subtract(const Duration(days: 12)),
          tripId: 'h2',
        ),
      ],
    );
  }

  factory AccountSettings.fromJson(Map<String, Object?> j) => AccountSettings(
    walletBalance: (j['wallet_balance'] as num?)?.toDouble() ?? 0,
    defaultPayment: PaymentKind.fromWire(
      j['default_payment'] as String? ?? 'cash',
    ),
    methods: () {
      final raw = (j['methods'] as List? ?? const [])
          .map(
            (e) => SavedPaymentMethod.fromJson(
              Map<String, Object?>.from(e as Map),
            ),
          )
          .toList();
      return raw.isEmpty
          ? const [
              SavedPaymentMethod(
                id: 'pay-cash',
                kind: PaymentKind.cash,
                label: 'Cash',
                isDefault: true,
              ),
            ]
          : raw;
    }(),
    referralCode: j['referral_code'] as String? ?? '',
    rewardPoints: (j['reward_points'] as num?)?.toInt() ?? 0,
    promos: (j['promos'] as List? ?? const []).map((e) => e.toString()).toList(),
    notifRide: j['notif_ride'] as bool? ?? true,
    notifPromo: j['notif_promo'] as bool? ?? false,
    notifSms: j['notif_sms'] as bool? ?? true,
    notifEmail: j['notif_email'] as bool? ?? false,
    themeMode: j['theme_mode'] as String? ?? 'light',
    mapType: j['map_type'] as String? ?? 'normal',
    googleLinked: j['google_linked'] as bool? ?? false,
    facebookLinked: j['facebook_linked'] as bool? ?? false,
    twoFactor: j['two_factor'] as bool? ?? true,
    reviews: (j['reviews'] as List? ?? const [])
        .map((e) => DriverReviewGiven.fromJson(Map<String, Object?>.from(e as Map)))
        .toList(),
    accessibilityLargeText: j['a11y_large_text'] as bool? ?? false,
    overallRating: (j['overall_rating'] as num?)?.toDouble() ?? 4.9,
    tripsCompleted: (j['trips_completed'] as num?)?.toInt() ?? 0,
  );

  final double walletBalance;
  final PaymentKind defaultPayment;
  final List<SavedPaymentMethod> methods;
  final String referralCode;
  final int rewardPoints;
  final List<String> promos;
  final bool notifRide;
  final bool notifPromo;
  final bool notifSms;
  final bool notifEmail;
  final String themeMode;
  final String mapType;
  final bool googleLinked;
  final bool facebookLinked;
  final bool twoFactor;
  final List<DriverReviewGiven> reviews;
  final bool accessibilityLargeText;
  final double overallRating;
  final int tripsCompleted;

  Map<String, Object?> toJson() => {
    'wallet_balance': walletBalance,
    'default_payment': defaultPayment.wire,
    'methods': methods.map((m) => m.toJson()).toList(),
    'referral_code': referralCode,
    'reward_points': rewardPoints,
    'promos': promos,
    'notif_ride': notifRide,
    'notif_promo': notifPromo,
    'notif_sms': notifSms,
    'notif_email': notifEmail,
    'theme_mode': themeMode,
    'map_type': mapType,
    'google_linked': googleLinked,
    'facebook_linked': facebookLinked,
    'two_factor': twoFactor,
    'reviews': reviews.map((r) => r.toJson()).toList(),
    'a11y_large_text': accessibilityLargeText,
    'overall_rating': overallRating,
    'trips_completed': tripsCompleted,
  };

  AccountSettings copyWith({
    double? walletBalance,
    PaymentKind? defaultPayment,
    List<SavedPaymentMethod>? methods,
    String? referralCode,
    int? rewardPoints,
    List<String>? promos,
    bool? notifRide,
    bool? notifPromo,
    bool? notifSms,
    bool? notifEmail,
    String? themeMode,
    String? mapType,
    bool? googleLinked,
    bool? facebookLinked,
    bool? twoFactor,
    List<DriverReviewGiven>? reviews,
    bool? accessibilityLargeText,
    double? overallRating,
    int? tripsCompleted,
  }) => AccountSettings(
    walletBalance: walletBalance ?? this.walletBalance,
    defaultPayment: defaultPayment ?? this.defaultPayment,
    methods: methods ?? this.methods,
    referralCode: referralCode ?? this.referralCode,
    rewardPoints: rewardPoints ?? this.rewardPoints,
    promos: promos ?? this.promos,
    notifRide: notifRide ?? this.notifRide,
    notifPromo: notifPromo ?? this.notifPromo,
    notifSms: notifSms ?? this.notifSms,
    notifEmail: notifEmail ?? this.notifEmail,
    themeMode: themeMode ?? this.themeMode,
    mapType: mapType ?? this.mapType,
    googleLinked: googleLinked ?? this.googleLinked,
    facebookLinked: facebookLinked ?? this.facebookLinked,
    twoFactor: twoFactor ?? this.twoFactor,
    reviews: reviews ?? this.reviews,
    accessibilityLargeText: accessibilityLargeText ?? this.accessibilityLargeText,
    overallRating: overallRating ?? this.overallRating,
    tripsCompleted: tripsCompleted ?? this.tripsCompleted,
  );

  @override
  List<Object?> get props => [
    walletBalance,
    defaultPayment,
    methods,
    referralCode,
    rewardPoints,
    promos,
    notifRide,
    notifPromo,
    notifSms,
    notifEmail,
    themeMode,
    mapType,
    googleLinked,
    facebookLinked,
    twoFactor,
    reviews,
    accessibilityLargeText,
    overallRating,
    tripsCompleted,
  ];
}
