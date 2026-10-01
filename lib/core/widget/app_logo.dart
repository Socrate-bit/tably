import 'package:flutter/material.dart';

/// The Tably chef's-hat mark.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) =>
      Image.asset('assets/brand/logo.png', width: size, height: size, filterQuality: FilterQuality.medium);
}

/// The full logo: the chef's hat beside the "Tably" wordmark, sized by height.
class AppWordmark extends StatelessWidget {
  const AppWordmark({super.key, required this.height});

  final double height;

  @override
  Widget build(BuildContext context) =>
      Image.asset('assets/brand/logo_V2.png', height: height, filterQuality: FilterQuality.medium);
}
