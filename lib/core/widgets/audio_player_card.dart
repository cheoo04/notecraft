// lib/core/widgets/audio_player_card.dart

import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

class AudioPlayerCard extends StatefulWidget {
  final String audioPath;
  final Duration? totalDuration;
  final VoidCallback? onDelete;

  const AudioPlayerCard({
    super.key,
    required this.audioPath,
    this.totalDuration,
    this.onDelete,
  });

  @override
  State<AudioPlayerCard> createState() => _AudioPlayerCardState();
}

class _AudioPlayerCardState extends State<AudioPlayerCard> {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  StreamSubscription? _stateSub;
  StreamSubscription? _posSub;
  StreamSubscription? _durSub;
  StreamSubscription? _completeSub;

  @override
  void initState() {
    super.initState();
    _duration = widget.totalDuration ?? Duration.zero;

    _stateSub = _player.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() => _isPlaying = state == PlayerState.playing);
      }
    });

    _posSub = _player.onPositionChanged.listen((pos) {
      if (mounted) {
        setState(() => _position = pos);
      }
    });

    _durSub = _player.onDurationChanged.listen((dur) {
      if (mounted && dur > Duration.zero) {
        setState(() => _duration = dur);
      }
    });

    _completeSub = _player.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _position = Duration.zero;
        });
      }
    });
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    _posSub?.cancel();
    _durSub?.cancel();
    _completeSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  String _formatTime(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Future<void> _togglePlay() async {
    HapticFeedback.selectionClick();
    final file = File(widget.audioPath);

    if (!await file.exists()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fichier audio introuvable sur le stockage local.'),
        ),
      );
      return;
    }

    try {
      if (_isPlaying) {
        await _player.pause();
      } else {
        await _player.play(DeviceFileSource(widget.audioPath));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lecture impossible : $e')),
      );
    }
  }

  Future<void> _seek(double value) async {
    final target = Duration(seconds: value.toInt());
    await _player.seek(target);
  }

  @override
  Widget build(BuildContext context) {
    final maxSeconds = _duration.inSeconds > 0
        ? _duration.inSeconds.toDouble()
        : (_position.inSeconds > 0 ? _position.inSeconds.toDouble() : 1.0);
    final currentSeconds =
        _position.inSeconds.toDouble().clamp(0.0, maxSeconds);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.neutralBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // Bouton Play / Pause
              GestureDetector(
                onTap: _togglePlay,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                    color: AppColors.accentTeal,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Curseur de progression
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: AppColors.accentTeal,
                        inactiveTrackColor: AppColors.neutralFill,
                        thumbColor: AppColors.accentTeal,
                        trackHeight: 3.5,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 6,
                        ),
                        overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 12,
                        ),
                      ),
                      child: Slider(
                        value: currentSeconds,
                        max: maxSeconds,
                        onChanged: _seek,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatTime(_position),
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            _formatTime(_duration),
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Bouton de suppression facultatif
              if (widget.onDelete != null)
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: AppColors.textMuted, size: 20),
                  onPressed: widget.onDelete,
                  tooltip: 'Supprimer l\'enregistrement',
                ),
            ],
          ),
        ],
      ),
    );
  }
}
