import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notecraft/features/generation/controller/generation_config_controller.dart';
import 'package:notecraft/models/document.dart';

void main() {
  group('GenerationConfigController', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
      addTearDown(container.dispose);
    });

    test('état initial : fiche de révision, mode express', () {
      final state = container.read(generationConfigControllerProvider);
      expect(state.format, DocumentFormat.ficheDeRevision);
      expect(state.mode, GenerationMode.express);
    });

    test('selectFormat change le format sans changer le mode', () {
      final controller =
          container.read(generationConfigControllerProvider.notifier);

      controller.selectFormat(DocumentFormat.rapport);

      final state = container.read(generationConfigControllerProvider);
      expect(state.format, DocumentFormat.rapport);
      expect(state.mode, GenerationMode.express);
    });

    test('selectMode change le mode sans changer le format', () {
      final controller =
          container.read(generationConfigControllerProvider.notifier);

      controller.selectMode(GenerationMode.affine);

      final state = container.read(generationConfigControllerProvider);
      expect(state.mode, GenerationMode.affine);
      expect(state.format, DocumentFormat.ficheDeRevision);
    });

    test('formatLabel donne un libellé pour chaque format', () {
      for (final format in DocumentFormat.values) {
        expect(formatLabel(format), isNotEmpty);
      }
    });
  });
}
