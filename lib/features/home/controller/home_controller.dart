// lib/features/home/controller/home_controller.dart

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/note.dart';
import '../../../services/storage_service.dart';

enum NoteFilterType { tous, cornell, audio, fiches }

class HomeState {
  final String searchQuery;
  final NoteFilterType selectedFilter;
  final List<Note> allNotes;
  final bool isLoading;

  const HomeState({
    this.searchQuery = '',
    this.selectedFilter = NoteFilterType.tous,
    this.allNotes = const [],
    this.isLoading = false,
  });

  HomeState copyWith({
    String? searchQuery,
    NoteFilterType? selectedFilter,
    List<Note>? allNotes,
    bool? isLoading,
  }) {
    return HomeState(
      searchQuery: searchQuery ?? this.searchQuery,
      selectedFilter: selectedFilter ?? this.selectedFilter,
      allNotes: allNotes ?? this.allNotes,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  List<Note> get filteredNotes {
    var notes = allNotes;

    if (searchQuery.trim().isNotEmpty) {
      final query = searchQuery.toLowerCase();
      notes = notes.where((n) {
        final titleMatch = n.title.toLowerCase().contains(query);
        final contentMatch = n.rawText?.toLowerCase().contains(query) ?? false;
        final subjectMatch = n.subject.toLowerCase().contains(query);
        return titleMatch || contentMatch || subjectMatch;
      }).toList();
    }

    switch (selectedFilter) {
      case NoteFilterType.audio:
        notes = notes.where((n) => n.audioPaths.isNotEmpty).toList();
        break;
      case NoteFilterType.cornell:
        notes = notes
            .where((n) =>
                n.subject.toLowerCase().contains('cornell') ||
                (n.rawText?.toLowerCase().contains('cornell') ?? false))
            .toList();
        break;
      case NoteFilterType.fiches:
        notes = notes.where((n) => n.rawSketchPaths.isNotEmpty).toList();
        break;
      case NoteFilterType.tous:
        break;
    }

    return notes;
  }
}

class HomeController extends Notifier<HomeState> {
  StreamSubscription<List<Note>>? _notesSubscription;

  @override
  HomeState build() {
    final storage = ref.watch(storageServiceProvider);
    _notesSubscription?.cancel();
    _notesSubscription = storage.watchNotes().listen((notes) {
      state = state.copyWith(allNotes: notes, isLoading: false);
    });

    ref.onDispose(() {
      _notesSubscription?.cancel();
    });

    return const HomeState(isLoading: true);
  }

  Future<void> loadNotes() async {
    try {
      final notes = await ref.read(storageServiceProvider).getNotes();
      state = state.copyWith(allNotes: notes, isLoading: false);
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  void updateSearch(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void selectFilter(NoteFilterType filter) {
    state = state.copyWith(selectedFilter: filter);
  }
}

final homeControllerProvider =
    NotifierProvider<HomeController, HomeState>(HomeController.new);
