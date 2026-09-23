// lib/features/document_result/view/document_result_screen.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:printing/printing.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/document.dart';
import '../../../services/export_service.dart';
import '../../../services/storage_service.dart';
import '../../generation/controller/generation_config_controller.dart';

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Document mis à jour avec succès')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Échec de la sauvegarde : $e')),
      );
    }
  }

  void _startEditing() {
    HapticFeedback.selectionClick();
    _editController.text = _document?.content ?? '';
    setState(() => _editing = true);
  }

  void _cancelEditing() {
    HapticFeedback.selectionClick();
    setState(() => _editing = false);
  }

  Future<void> _exportPdf() async {
    final current = _document;
    if (current == null) return;
    HapticFeedback.mediumImpact();
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

  void _exportWord() {
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Export Word (.docx) : fonctionnalité prévue en V2'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final document = _document;

    return Scaffold(
      backgroundColor: AppColors.canvasGrey,
      appBar: AppBar(
        title: Text(
          document != null ? formatLabel(document.format) : 'Document généré',
        ),
        actions: [
          if (document?.content != null && !_editing)
            IconButton(
              icon: const Icon(Icons.share_outlined),
              tooltip: 'Partager le document',
              onPressed: _exportPdf,
            ),
        ],
      ),
      body: document?.content == null
          ? const Center(child: Text('Aucun document reçu'))
          : Column(
              children: [
                Expanded(
                  child: _editing
                      ? Padding(
                          padding: const EdgeInsets.all(16),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border:
                                  Border.all(color: AppColors.neutralBorder),
                            ),
                            padding: const EdgeInsets.all(16),
                            child: TextField(
                              controller: _editController,
                              maxLines: null,
                              expands: true,
                              textAlignVertical: TextAlignVertical.top,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: 'Contenu du document en Markdown...',
                              ),
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ),
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Feuille de document universitaire (Diapositive 7)
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                      color: AppColors.neutralBorder),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.03),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Badge supérieur
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.accentTealLight,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'MÉTHODE CORNELL • FICHE OFFICIELLE',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.accentTeal,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),

                                    // Schémas vectorisés joints
                                    if (document!
                                        .cleanedSketchSvgPaths.isNotEmpty) ...[
                                      for (final path
                                          in document.cleanedSketchSvgPaths)
                                        Container(
                                          width: double.infinity,
                                          margin:
                                              const EdgeInsets.only(bottom: 20),
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: AppColors.canvasGrey,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                              color: AppColors.neutralBorder,
                                            ),
                                          ),
                                          child: Column(
                                            children: [
                                              SizedBox(
                                                height: 180,
                                                child: SvgPicture.file(
                                                  File(path),
                                                  fit: BoxFit.contain,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              const Text(
                                                'SCHÉMA VECTORISÉ RECONSTRUIT',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.textMuted,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],

                                    // Contenu Markdown enrichi
                                    SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: ConstrainedBox(
                                        constraints: BoxConstraints(
                                          minWidth: MediaQuery.of(context)
                                                  .size
                                                  .width -
                                              72,
                                        ),
                                        child: GptMarkdown(
                                          document.content!,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyLarge
                                              ?.copyWith(
                                                height: 1.6,
                                                fontSize: 14.5,
                                              ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 30),
                            ],
                          ),
                        ),
                ),

                // Barre d'actions inférieure
                Container(
                  padding: EdgeInsets.only(
                    top: 12,
                    bottom: MediaQuery.of(context).padding.bottom > 0
                        ? MediaQuery.of(context).padding.bottom
                        : 12,
                    left: 20,
                    right: 20,
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      top: BorderSide(color: AppColors.neutralBorder, width: 1),
                    ),
                  ),
                  child: _editing
                      ? Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _cancelEditing,
                                style: OutlinedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  side: const BorderSide(
                                      color: AppColors.neutralBorder),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text(
                                  'Annuler',
                                  style: TextStyle(color: AppColors.inkDark),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _saving ? null : _save,
                                style: ElevatedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: _saving
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        'Enregistrer',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w700),
                                      ),
                              ),
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _exporting ? null : _exportPdf,
                                icon: _exporting
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2),
                                      )
                                    : const Icon(
                                        Icons.picture_as_pdf_outlined,
                                        size: 18,
                                        color: AppColors.accentTeal,
                                      ),
                                label: const Text(
                                  'PDF',
                                  style: TextStyle(
                                    color: AppColors.inkDark,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  side: const BorderSide(
                                      color: AppColors.neutralBorder),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _exportWord,
                                icon: const Icon(
                                  Icons.description_outlined,
                                  size: 18,
                                  color: Color(0xFF2563EB),
                                ),
                                label: const Text(
                                  'Word',
                                  style: TextStyle(
                                    color: AppColors.inkDark,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  side: const BorderSide(
                                      color: AppColors.neutralBorder),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _startEditing,
                                icon: const Icon(Icons.edit_outlined, size: 18),
                                label: const Text(
                                  'Éditer',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                                style: ElevatedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
    );
  }
}
