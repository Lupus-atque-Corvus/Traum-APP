import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/colors.dart';
import 'photo_stitch_service.dart';

class PhotoStitchScreen extends ConsumerStatefulWidget {
  const PhotoStitchScreen({super.key});

  @override
  ConsumerState<PhotoStitchScreen> createState() => _PhotoStitchScreenState();
}

class _PhotoStitchScreenState extends ConsumerState<PhotoStitchScreen> {
  final List<String> _paths = [];
  bool _processing = false;
  String? _resultPath;

  Future<void> _pick() async {
    final picked = await ImagePicker().pickMultiImage(maxWidth: 2400);
    if (picked.isEmpty) return;
    setState(() => _paths.addAll(picked.map((x) => x.path)));
  }

  Future<void> _stitch() async {
    if (_paths.length < 2) return;
    setState(() {
      _processing = true;
      _resultPath = null;
    });
    final result = await PhotoStitchService.stitchPhotos(_paths);
    if (!mounted) return;
    setState(() {
      _processing = false;
      _resultPath = result;
    });
    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Panorama-Stitching ist in diesem Build noch nicht verfügbar (experimentell).'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TraumColors.background,
      appBar: AppBar(
        backgroundColor: TraumColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: TraumColors.onBackground),
          onPressed: () => context.pop(),
        ),
        title: const Text('Panorama erstellen',
            style: TextStyle(
                fontFamily: 'DMSans',
                color: TraumColors.onBackground,
                fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: TraumColors.amberGold.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: TraumColors.amberGold.withValues(alpha: 0.4)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline,
                    color: TraumColors.amberGold, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Fotos sollten 30% überlappen, gleiche Belichtung, horizontal. '
                    'Funktion ist experimentell.',
                    style: TextStyle(
                        fontFamily: 'DMSans',
                        color: TraumColors.onBackground,
                        fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (_paths.isEmpty)
            GestureDetector(
              onTap: _pick,
              child: Container(
                height: 160,
                decoration: BoxDecoration(
                  color: TraumColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: TraumColors.cyanBlue.withValues(alpha: 0.4)),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_photo_alternate_outlined,
                        color: TraumColors.cyanBlue, size: 36),
                    SizedBox(height: 8),
                    Text('Fotos auswählen',
                        style: TextStyle(
                            fontFamily: 'DMSans',
                            color: TraumColors.cyanBlue)),
                  ],
                ),
              ),
            )
          else
            SizedBox(
              height: 140,
              child: ReorderableListView.builder(
                scrollDirection: Axis.horizontal,
                buildDefaultDragHandles: true,
                itemCount: _paths.length,
                // ignore: deprecated_member_use
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) newIndex--;
                    final item = _paths.removeAt(oldIndex);
                    _paths.insert(newIndex, item);
                  });
                },
                itemBuilder: (context, i) {
                  return Padding(
                    key: ValueKey(_paths[i]),
                    padding: const EdgeInsets.only(right: 8),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(File(_paths[i]),
                              width: 110, height: 140, fit: BoxFit.cover),
                        ),
                        Positioned(
                          left: 6,
                          top: 6,
                          child: Container(
                            width: 22,
                            height: 22,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                                color: TraumColors.cyanBlue,
                                shape: BoxShape.circle),
                            child: Text('${i + 1}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'DMSans')),
                          ),
                        ),
                        Positioned(
                          right: 4,
                          top: 4,
                          child: GestureDetector(
                            onTap: () => setState(() => _paths.removeAt(i)),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.6),
                                shape: BoxShape.circle,
                              ),
                              padding: const EdgeInsets.all(2),
                              child: const Icon(Icons.close,
                                  color: Colors.white, size: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          if (_paths.isNotEmpty) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _pick,
              icon: const Icon(Icons.add, color: TraumColors.cyanBlue),
              label: const Text('Mehr Fotos',
                  style: TextStyle(
                      fontFamily: 'DMSans', color: TraumColors.cyanBlue)),
            ),
          ],
          const SizedBox(height: 16),

          if (_processing)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  children: [
                    CircularProgressIndicator(color: TraumColors.cyanBlue),
                    SizedBox(height: 12),
                    Text('Panorama wird berechnet…',
                        style: TextStyle(
                            fontFamily: 'DMSans',
                            color: TraumColors.onBackgroundMuted)),
                  ],
                ),
              ),
            ),

          if (_resultPath != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(File(_resultPath!), fit: BoxFit.cover),
            ),
            const SizedBox(height: 16),
          ],

          SizedBox(
            width: double.infinity,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: TraumColors.gradientCool,
                borderRadius: BorderRadius.circular(14),
              ),
              child: TextButton(
                onPressed:
                    (_paths.length >= 2 && !_processing) ? _stitch : null,
                style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16)),
                child: const Text('Panorama erstellen',
                    style: TextStyle(
                        fontFamily: 'DMSans',
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
