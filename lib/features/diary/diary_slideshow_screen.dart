import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/colors.dart';
import 'diary_provider.dart';

class DiarySlideShowScreen extends ConsumerStatefulWidget {
  const DiarySlideShowScreen({super.key});

  @override
  ConsumerState<DiarySlideShowScreen> createState() =>
      _DiarySlideShowScreenState();
}

class _DiarySlideShowScreenState
    extends ConsumerState<DiarySlideShowScreen> {
  final _controller = PageController();
  int _currentPage = 0;
  int _totalPages = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (_controller.hasClients && _currentPage < _totalPages - 1) {
        _controller.animateToPage(
          _currentPage + 1,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entriesAsync = ref.watch(recentDiaryEntriesProvider(7));

    return Scaffold(
      backgroundColor: Colors.black,
      body: entriesAsync.when(
        data: (entries) {
          if (entries.isEmpty) {
            return const Center(
              child: Text(
                'Keine Einträge der letzten 7 Tage',
                style: TextStyle(
                    fontFamily: 'DMSans',
                    color: TraumColors.onBackgroundMuted),
              ),
            );
          }
          _totalPages = entries.length;

          return Stack(children: [
            PageView.builder(
              controller: _controller,
              onPageChanged: (i) => setState(() => _currentPage = i),
              itemCount: entries.length,
              itemBuilder: (_, i) {
                final entry = entries[i];
                final mediaPath = entry.mediaPath;
                final exists = File(mediaPath).existsSync();

                return Stack(fit: StackFit.expand, children: [
                  exists
                      ? Image.file(File(mediaPath), fit: BoxFit.cover)
                      : Container(color: TraumColors.surfaceVariant),

                  // Top gradient + date
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 120,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.black54, Colors.transparent],
                        ),
                      ),
                      padding: const EdgeInsets.fromLTRB(20, 56, 20, 0),
                      child: Text(
                        _formatDate(entry.date),
                        style: const TextStyle(
                          fontFamily: 'DMSans',
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  // Bottom gradient + note
                  if (entry.note.isNotEmpty)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [Colors.black87, Colors.transparent],
                          ),
                        ),
                        padding: const EdgeInsets.fromLTRB(20, 40, 20, 80),
                        child: Text(
                          entry.note,
                          style: const TextStyle(
                            fontFamily: 'DMSans',
                            color: Colors.white,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                ]);
              },
            ),

            // Close button
            Positioned(
              top: 48,
              right: 16,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black38,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.close,
                      color: Colors.white, size: 22),
                ),
              ),
            ),

            // Dot indicators
            Positioned(
              bottom: 32,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  entries.length,
                  (i) => Container(
                    width: i == _currentPage ? 12 : 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: i == _currentPage
                          ? TraumColors.coralOrange
                          : Colors.white.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ),
          ]);
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: TraumColors.lavender),
        ),
        error: (_, __) => const SizedBox.shrink(),
      ),
    );
  }

  String _formatDate(String dateStr) {
    final d = DateTime.tryParse(dateStr);
    if (d == null) return dateStr;
    const months = ['Jan','Feb','Mär','Apr','Mai','Jun',
        'Jul','Aug','Sep','Okt','Nov','Dez'];
    return '${d.day}. ${months[d.month - 1]} ${d.year}';
  }
}
