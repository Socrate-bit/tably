import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../features/recipe/model/recipe.dart';
import '../theme/app_theme.dart';

/// Renders a recipe photo from [url], or a bundled one from [photoKey], with
/// the design's neutral gradient while loading or when there is no image.
class RecipePhoto extends StatelessWidget {
  const RecipePhoto({
    super.key,
    this.url = '',
    this.photoKey = '',
    required this.height,
    this.width,
    this.radius,
    this.opacity = 1,
  });

  final String url;
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
          child: url.isNotEmpty
              ? Image.network(
                  url,
                  fit: BoxFit.cover,
                  loadingBuilder: (_, child, progress) => progress == null ? child : const _Placeholder(),
                  errorBuilder: (_, _, _) => const _Placeholder(),
                )
              : asset == null
                  ? const _Placeholder()
                  : Image.asset(
                      asset,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const ColoredBox(color: AppColors.fill),
                    ),
        ),
      ),
    );
  }
}

/// The design's neutral gradient, shown when there is no photo to draw.
class _Placeholder extends StatelessWidget {
  const _Placeholder();

  @override
  Widget build(BuildContext context) => const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.photoPlaceholder, AppColors.trackDark],
          ),
        ),
      );
}
