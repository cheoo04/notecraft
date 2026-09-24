// lib/features/document_result/view/document_result_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:printing/printing.dart';
import 'package:universal_io/io.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_svg_viewer.dart';
import '../../../core/widgets/flashcard_deck_viewer.dart';
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

  Future<void> _confirmDelete() async {
    final current = _document;
    if (current == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Supprimer ce document ?',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
        ),
        content: const Text(
          'Cette synthèse sera définitivement supprimée. Le cours brut d\'origine restera conservé.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(storageServiceProvider).deleteDocument(current.id);
      if (!mounted) return;
      context.pop();
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
        content: Text('Export Word (.docx) : prévu en V2'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final document = _document;
    final hasContent =
        document?.content != null && document!.content!.trim().isNotEmpty;
    final isFlashcards = document?.format == DocumentFormat.flashcards;

    return Scaffold(
      backgroundColor: AppColors.canvasGrey,
      appBar: AppBar(
        title: Text(
          document != null ? formatLabel(document.format) : 'Document généré',
        ),
        actions: [
          if (document != null) ...[
            if (hasContent && !_editing)
              IconButton(
                icon: const Icon(Icons.share_outlined),
                tooltip: 'Partager le document',
                onPressed: _exportPdf,
              ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              tooltip: 'Supprimer ce document',
              onPressed: _confirmDelete,
            ),
          ],
        ],
      ),
      body: document == null
          ? const Center(child: Text('Aucun document trouvé'))
          : !hasContent
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.neutralBorder),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            size: 48,
                            color: Colors.orangeAccent,
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'Génération incomplète ou vide',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.inkDark,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Ce document n\'a pas pu être finalisé par l\'IA.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _confirmDelete,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.redAccent,
                                    side: const BorderSide(
                                        color: Colors.redAccent),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: const Text('Supprimer'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => context.pop(),
                                  child: const Text('Retour'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                )
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
                                  border: Border.all(
                                      color: AppColors.neutralBorder),
                                ),
                                padding: const EdgeInsets.all(16),
                                child: TextField(
                                  controller: _editController,
                                  maxLines: null,
                                  expands: true,
                                  textAlignVertical: TextAlignVertical.top,
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    hintText:
                                        'Contenu du document en Markdown ou JSON...',
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
                                  if (isFlashcards) ...[
                                    FlashcardDeckViewer(
                                      rawJsonContent: document.content!,
                                    ),
                                  ] else ...[
                                    Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                            color: AppColors.neutralBorder),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black
                                                .withValues(alpha: 0.03),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.accentTealLight,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              formatLabel(document.format)
                                                  .toUpperCase(),
                                              style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w800,
                                                color: AppColors.accentTeal,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          if (document.cleanedSketchSvgPaths
                                              .isNotEmpty) ...[
                                            for (final path in document
                                                .cleanedSketchSvgPaths)
                                              Container(
                                                width: double.infinity,
                                                margin: const EdgeInsets.only(
                                                    bottom: 20),
                                                padding:
                                                    const EdgeInsets.all(16),
                                                decoration: BoxDecoration(
                                                  color: AppColors.canvasGrey,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color:
                                                        AppColors.neutralBorder,
                                                  ),
                                                ),
                                                child: Column(
                                                  children: [
                                                    SizedBox(
                                                      height: 180,
                                                      child: AppSvgViewer(
                                                          path: path),
                                                    ),
                                                    const SizedBox(height: 8),
                                                    const Text(
                                                      'SCHÉMA VECTORISÉ RECONSTRUIT',
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        color:
                                                            AppColors.textMuted,
                                                        letterSpacing: 0.5,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                          ],
                                          GptMarkdown(
                                            document.content!,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyLarge
                                                ?.copyWith(
                                                  height: 1.6,
                                                  fontSize: 14.5,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 30),
                                ],
                              ),
                            ),
                    ),

                    // Barre d'actions basse fixe
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
                          top: BorderSide(
                              color: AppColors.neutralBorder, width: 1),
                        ),
                      ),
                      child: _editing
                          ? Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: _cancelEditing,
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                      side: const BorderSide(
                                          color: AppColors.neutralBorder),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: const Text(
                                      'Annuler',
                                      style:
                                          TextStyle(color: AppColors.inkDark),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: _saving ? null : _save,
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
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
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
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
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
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
                                    icon: const Icon(Icons.edit_outlined,
                                        size: 18),
                                    label: const Text(
                                      'Éditer',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w700),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
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
