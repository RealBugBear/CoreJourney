import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../domain/models/exercise.dart';

/// Resolves the correct image source for an exercise:
/// prefers the remote Supabase Storage URL when available,
/// falls back to the bundled local asset otherwise.
class ExerciseImageWidget extends StatelessWidget {
  final Exercise exercise;
  final bool isDuo;
  final BoxFit fit;
  final double? width;
  final double? height;

  const ExerciseImageWidget({
    super.key,
    required this.exercise,
    this.isDuo = false,
    this.fit = BoxFit.contain,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final url = exercise.imageUrlFor(duo: isDuo);
    final localPath = exercise.imagePathFor(duo: isDuo);

    if (url != null) {
      return CachedNetworkImage(
        imageUrl: url,
        fit: fit,
        width: width,
        height: height,
        placeholder: (_, __) =>
            Image.asset(localPath, fit: fit, width: width, height: height),
        errorWidget: (_, __, ___) =>
            Image.asset(localPath, fit: fit, width: width, height: height),
      );
    }

    return Image.asset(localPath, fit: fit, width: width, height: height);
  }
}
