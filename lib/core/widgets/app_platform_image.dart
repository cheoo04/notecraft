// lib/core/widgets/app_platform_image.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:universal_io/io.dart';

class AppPlatformImage extends StatelessWidget {
  final String path;
  final double? width;
  final double? height;
  final BoxFit fit;

  const AppPlatformImage({
    super.key,
    required this.path,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Cas Web : URL blob ou HTTP
    if (kIsWeb) {
      if (path.startsWith('http') || path.startsWith('blob:')) {
        return Image.network(
          path,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (_, __, ___) => _fallback(),
        );
      }
      return _fallback();
    }

    // 2. Cas Mobile (Android / iOS) : Fichier physique local inchangé
    final file = File(path);
    if (!file.existsSync()) {
      return _fallback();
    }

    return Image.file(
      file,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, __, ___) => _fallback(),
    );
  }

  Widget _fallback() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey.shade100,
      alignment: Alignment.center,
      child: const Icon(Icons.image_outlined, color: Colors.grey, size: 24),
    );
  }
}
