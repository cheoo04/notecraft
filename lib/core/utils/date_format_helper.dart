/// Petit helper pour éviter d'ajouter la dépendance `intl` juste pour ça
/// (elle n'est que transitive dans le projet actuellement, pas déclarée
/// en dépendance directe dans pubspec.yaml).
String formatNoteDate(DateTime date) {
  final d = date.day.toString().padLeft(2, '0');
  final m = date.month.toString().padLeft(2, '0');
  final h = date.hour.toString().padLeft(2, '0');
  final min = date.minute.toString().padLeft(2, '0');
  return '$d/$m/${date.year} $h:$min';
}
