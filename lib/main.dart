import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

// TODO: initialiser Firebase ici avant runApp (Firebase.initializeApp)
void main() {
  runApp(const ProviderScope(child: NoteCraftApp()));
}
