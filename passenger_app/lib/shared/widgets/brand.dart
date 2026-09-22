import 'package:flutter/material.dart';

import '../../app/theme/brand_assets.dart';

/// Full wordmark (Pothik + Bangla tagline). Width-bounded so it never
/// overflows a phone column; [height] is the cap, not a crop.
class PothikLogo extends StatelessWidget {
  const PothikLogo({
    this.height = 88,
    this.alignment = Alignment.center,
    this.semanticLabel,
    super.key,
  });

  final double height;
  final Alignment alignment;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      BrandAssets.logo,
      height: height,
      width: double.infinity,
      fit: BoxFit.contain,
      alignment: alignment,
      filterQuality: FilterQuality.high,
      semanticLabel: semanticLabel,
    );
  }
}

/// Squircle monogram (launcher art) for compact placements.
class PothikAppMark extends StatelessWidget {
  const PothikAppMark({this.size = 96, this.semanticLabel, super.key});

  final double size;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      BrandAssets.appIcon,
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      semanticLabel: semanticLabel,
    );
  }
}
