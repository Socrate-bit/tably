import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../features/recipe/model/recipe.dart';
import '../theme/app_theme.dart';

/// Renders a recipe's bundled photo, falling back to the design's neutral
/// gradient placeholder when the key has no image.
class RecipePhoto extends StatelessWidget {
  const RecipePhoto({
    super.key,
    required this.photoKey,
    required this.height,
    this.width,
    this.radius,
    this.opacity = 1,
  });

  final String photoKey;
  final double height;
  final double? width;
  final double? radius;

  /// Leftover meals show their photo slightly faded.
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final asset = RecipePhotos.assetFor(photoKey);
    return Opacity(
      opacity: opacity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius ?? 16.r),
        child: SizedBox(
          width: width,
          height: height,
          child: asset == null
              ? const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.photoPlaceholder, AppColors.trackDark],
                    ),
                  ),
                )
              : Image.asset(
                  asset,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) =>
                      const ColoredBox(color: AppColors.fill),
                ),
        ),
      ),
    );
  }
}
