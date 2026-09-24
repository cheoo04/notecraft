Future<void> _executePipeline() async {
  final args = widget.args;
  if (args == null) return;

  try {
    var note = args.note;
    final svgPaths = <String>[];

    // Etape 1 : Analyse du texte brut
    await Future.delayed(const Duration(milliseconds: 600));
    setState(() {
      _textStep = StepStatus.completed;
      _percentage = 35;
    });

    // Etape 2 : Retranscription audio si present
    if (note.audioPath != null) {
      setState(() => _audioStep = StepStatus.inProgress);
      await Future.delayed(const Duration(milliseconds: 800));
      setState(() {
        _audioStep = StepStatus.completed;
        _percentage = 50;
      });
    }

    // Etape 3 : Vectorisation des schemas
    if (note.rawSketchPaths.isNotEmpty) {
      setState(() => _sketchStep = StepStatus.inProgress);
      final sketchService = ref.read(sketchServiceProvider);
      final descriptions = <String>[];

      for (final path in note.rawSketchPaths) {
        try {
          final result = await sketchService.vectorize(path);
          svgPaths.add(result.svgPath);
          descriptions.add(result.description);
        } catch (_) {}
      }

      if (descriptions.isNotEmpty) {
        final schemaSection =
            '--- Schémas fournis avec la note ---\n${descriptions.join('\n\n')}';
        note = note.copyWith(
          rawText: '${note.rawText ?? ''}\n\n$schemaSection',
        );
      }

      setState(() {
        _sketchStep = StepStatus.completed;
        _percentage = 70;
      });
    }

    // Etape 4 : Redaction et mise en page IA
    setState(() => _layoutStep = StepStatus.inProgress);
    final aiService = ref.read(aiServiceProvider);
    var document = await aiService.generate(
      note: note,
      format: args.format,
      mode: args.mode,
    );

    if (svgPaths.isNotEmpty) {
      document = document.copyWith(cleanedSketchSvgPaths: svgPaths);
    }

    setState(() {
      _layoutStep = StepStatus.completed;
      _percentage = 100;
    });

    try {
      await ref.read(storageServiceProvider).saveDocument(document);
    } catch (_) {}

    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    context.replace('/document/${document.id}', extra: document);
  } catch (e) {
    if (!mounted) return;
    String message = e.toString();
    // Si l'erreur provient de Dio et contient une reponse du backend
    if (e is DioException && e.response?.data != null) {
      final data = e.response!.data;
      if (data is Map && data.containsKey('detail')) {
        message = data['detail'].toString();
      }
    }
    setState(() => _error = message);
  }
}
