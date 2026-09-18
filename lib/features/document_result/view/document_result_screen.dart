import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:printing/printing.dart';

import '../../../models/document.dart';
import '../../../services/export_service.dart';
import '../../../services/storage_service.dart';

/// Écran 5 — Résultat généré & export.
/// TODO: export Word/SVG, rendu des schémas nettoyés.
class DocumentResultScreen extends ConsumerStatefulWidget {
  final GeneratedDocument? document;

  const DocumentResultScreen({super.key, this.document});

  @override
  ConsumerState<DocumentResultScreen> createState() =>
      _DocumentResultScreenState();
}

class _DocumentResultScreenState extends ConsumerState<DocumentResultScreen> {
  late GeneratedDocument? _document = widget.document;
  late final TextEditingController _editController =
      TextEditingController(text: _document?.content ?? '');
  bool _editing = false;
  bool _saving = false;
  bool _exporting = false;

  @override
  void dispose() {
    _editController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final current = _document;
    if (current == null) return;
    setState(() => _saving = true);
    final updated = current.copyWith(content: _editController.text);
    try {
      await ref.read(storageServiceProvider).saveDocument(updated);
      if (!mounted) return;
      setState(() {
        _document = updated;
        _editing = false;
        _saving = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Échec de la sauvegarde : $e')),
      );
    }
  }

  void _startEditing() {
    _editController.text = _document?.content ?? '';
    setState(() => _editing = true);
  }

  void _cancelEditing() {
    setState(() => _editing = false);
  }

  Future<void> _exportPdf() async {
    final current = _document;
    if (current == null) return;
    setState(() => _exporting = true);
    try {
      final path = await ref.read(exportServiceProvider).exportToPdf(current);
      final bytes = await File(path).readAsBytes();
      if (!mounted) return;
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'notecraft_${current.id}.pdf',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Échec de l\'export PDF : $e')),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final document = _document;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Document généré'),
        actions: [
          if (document?.content != null)
            if (_editing)
              _saving
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.close),
                          tooltip: 'Annuler',
                          onPressed: _cancelEditing,
                        ),
                        IconButton(
                          icon: const Icon(Icons.check),
                          tooltip: 'Enregistrer',
                          onPressed: _save,
                        ),
                      ],
                    )
            else
              Row(
                children: [
                  _exporting
                      ? const Padding(
                          padding: EdgeInsets.all(16),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : IconButton(
                          icon: const Icon(Icons.picture_as_pdf_outlined),
                          tooltip: 'Exporter en PDF',
                          onPressed: _exportPdf,
                        ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: 'Modifier',
                    onPressed: _startEditing,
                  ),
                ],
              ),
        ],
      ),
      body: document?.content == null
          ? const Center(child: Text('Aucun document reçu'))
          : _editing
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _editController,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Contenu du document (Markdown)...',
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: GptMarkdown(document!.content!),
                ),
    );
  }
}
