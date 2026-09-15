import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notecraft/features/note_editor/controller/note_editor_controller.dart';

void main() {
  group('NoteEditorController', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
      addTearDown(container.dispose);
    });

    test('état initial : vide, ne peut pas continuer', () {
      final state = container.read(noteEditorControllerProvider);
      expect(state.title, '');
      expect(state.content, '');
      expect(state.canProceed, isFalse);
    });

    test('canProceed passe à vrai dès qu\'il y a du contenu', () {
      final controller =
          container.read(noteEditorControllerProvider.notifier);

      controller.updateContent('Les forces intermoléculaires...');

      final state = container.read(noteEditorControllerProvider);
      expect(state.canProceed, isTrue);
    });

    test('un contenu composé uniquement d\'espaces ne compte pas', () {
      final controller =
          container.read(noteEditorControllerProvider.notifier);

      controller.updateContent('   ');

      final state = container.read(noteEditorControllerProvider);
      expect(state.canProceed, isFalse);
    });

    test('buildNote utilise "Note sans titre" si le titre est vide', () {
      final controller =
          container.read(noteEditorControllerProvider.notifier);

      controller.updateContent('Contenu de test');
      final note = controller.buildNote();

      expect(note.title, 'Note sans titre');
      expect(note.rawText, 'Contenu de test');
    });

    test('buildNote conserve le titre saisi', () {
      final controller =
          container.read(noteEditorControllerProvider.notifier);

      controller.updateTitle('Physique quantique');
      controller.updateContent('Contenu de test');
      final note = controller.buildNote();

      expect(note.title, 'Physique quantique');
    });
  });
}
