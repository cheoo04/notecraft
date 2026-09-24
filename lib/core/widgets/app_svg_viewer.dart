// lib/core/widgets/app_svg_viewer.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:universal_io/io.dart';

import '../theme/app_theme.dart';

class AppSvgViewer extends StatelessWidget {
  final String path;
  final double? width;
  final double? height;

  const AppSvgViewer({
    super.key,
    required this.path,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Cas Web : pas de SvgPicture.file
    if (kIsWeb) {
      if (path.trim().startsWith('<svg')) {
        return SvgPicture.string(
          path,
          width: width,
          height: height,
          fit: BoxFit.contain,
        );
      }
      if (path.startsWith('http') || path.startsWith('blob:')) {
        return SvgPicture.network(
          path,
          width: width,
          height: height,
          fit: BoxFit.contain,
        );
      }
      return _fallback();
    }

    // 2. Cas Mobile (Android / iOS) : lecture du contenu local en texte
    try {
      final file = File(path);
      if (file.existsSync()) {
        final svgContent = file.readAsStringSync();
        return SvgPicture.string(
          svgContent,
          width: width,
          height: height,
          fit: BoxFit.contain,
        );
      }
    } catch (_) {}

    return _fallback();
  }

  Widget _fallback() {
    return SizedBox(
      width: width,
      height: height,
      child: const Center(
        child: Icon(
          Icons.draw_outlined,
          size: 36,
          color: AppColors.textMuted,
        ),
      ),
    );
  }
}
