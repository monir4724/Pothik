import 'dart:convert';

import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../features/auth/domain/user.dart';

ImageProvider? userPhotoProvider(String? url) {
  if (url == null || url.isEmpty) return null;
  if (url.startsWith('data:')) {
    final comma = url.indexOf(',');
    if (comma < 0) return null;
    try {
      return MemoryImage(base64Decode(url.substring(comma + 1)));
    } on FormatException {
      return null;
    }
  }
  if (url.startsWith('http://') || url.startsWith('https://')) {
    return NetworkImage(url);
  }
  return null;
}

class UserAvatar extends StatelessWidget {
  const UserAvatar({required this.user, this.radius = 32, super.key});

  final User? user;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final photo = userPhotoProvider(user?.photoUrl);
    final name = (user?.name ?? '').trim();
    final letter = name.isEmpty ? '?' : name.characters.first.toUpperCase();
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.amber100,
      backgroundImage: photo,
      child: photo == null
          ? Text(
              letter,
              style: (radius >= 32
                      ? AppTypography.headingLg
                      : AppTypography.headingMd)
                  .copyWith(color: AppColors.amber800),
            )
          : null,
    );
  }
}
