import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../theme/colors.dart';
import '../../l10n/app_localizations.dart';
import 'reference_templates.dart';

/// Ergebnis einer Aufnahme über [OverlayCameraScreen].
class CameraCaptureResult {
  final String path;
  final bool isVideo;
  const CameraCaptureResult({required this.path, required this.isVideo});
}

/// Eigener Kamera-Screen mit Live-Vorschau (statt der nativen Kamera-App via
/// `image_picker`), damit sich ein Referenzbild ("Geist" des letzten Fotos)
/// halbtransparent über das Live-Bild legen lässt — für Aufnahmen, die
/// über die Zeit an derselben Position/Ausrichtung bleiben sollen.
///
/// Feature-unabhängig gehalten (kein Import aus `features/`), damit er
/// später auch außerhalb des Tagebuchs wiederverwendbar ist.
class OverlayCameraScreen extends StatefulWidget {
  /// Pfad zu einem vorherigen Foto/Video-Vorschaubild, das als Ausrichtungs-
  /// Referenz halbtransparent über der Vorschau liegt. `null`, wenn es noch
  /// keine vorherige Aufnahme gibt.
  final String? ghostImagePath;
  final Duration maxVideoDuration;
  final bool initialVideoMode;

  const OverlayCameraScreen({
    super.key,
    this.ghostImagePath,
    this.maxVideoDuration = const Duration(seconds: 60),
    this.initialVideoMode = false,
  });

  @override
  State<OverlayCameraScreen> createState() => _OverlayCameraScreenState();
}

enum _CamStatus { checking, denied, permanentlyDenied, noCamera, ready }

class _OverlayCameraScreenState extends State<OverlayCameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  int _cameraIndex = 0;
  _CamStatus _status = _CamStatus.checking;
  late bool _isVideoMode;
  bool _isRecording = false;
  late ReferenceOverlayMode _refMode;
  Timer? _autoStopTimer;

  bool get _hasGhost =>
      widget.ghostImagePath != null && File(widget.ghostImagePath!).existsSync();

  @override
  void initState() {
    super.initState();
    _isVideoMode = widget.initialVideoMode;
    _refMode =
        _hasGhost ? ReferenceOverlayMode.lastPhoto : ReferenceOverlayMode.off;
    WidgetsBinding.instance.addObserver(this);
    _setup();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoStopTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      controller.dispose();
      _controller = null;
    } else if (state == AppLifecycleState.resumed) {
      _initController();
    }
  }

  Future<void> _setup() async {
    final camStatus = await Permission.camera.status;
    final micStatus = await Permission.microphone.status;
    if (camStatus.isPermanentlyDenied || micStatus.isPermanentlyDenied) {
      setState(() => _status = _CamStatus.permanentlyDenied);
      return;
    }
    if (!camStatus.isGranted) {
      final r = await Permission.camera.request();
      if (!r.isGranted) {
        setState(() => _status = r.isPermanentlyDenied
            ? _CamStatus.permanentlyDenied
            : _CamStatus.denied);
        return;
      }
    }
    // Mikrofon ist nur für Video nötig; wird ohne Blockieren der Vorschau
    // angefragt — bei Verweigerung bleibt Fotoaufnahme trotzdem möglich.
    if (!micStatus.isGranted) {
      await Permission.microphone.request();
    }

    try {
      _cameras = await availableCameras();
    } catch (_) {
      _cameras = [];
    }
    if (_cameras.isEmpty) {
      setState(() => _status = _CamStatus.noCamera);
      return;
    }
    _cameraIndex = _cameras.indexWhere(
        (c) => c.lensDirection == CameraLensDirection.back);
    if (_cameraIndex < 0) _cameraIndex = 0;
    await _initController();
  }

  Future<void> _initController() async {
    final controller = CameraController(
      _cameras[_cameraIndex],
      ResolutionPreset.high,
      enableAudio: true,
    );
    _controller = controller;
    try {
      await controller.initialize();
      if (!mounted) return;
      setState(() => _status = _CamStatus.ready);
    } catch (_) {
      if (!mounted) return;
      setState(() => _status = _CamStatus.denied);
    }
  }

  Future<void> _flipCamera() async {
    if (_cameras.length < 2) return;
    _cameraIndex = (_cameraIndex + 1) % _cameras.length;
    await _controller?.dispose();
    _controller = null;
    await _initController();
  }

  Future<void> _capturePhoto() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    try {
      final file = await controller.takePicture();
      if (mounted) {
        Navigator.pop(
            context, CameraCaptureResult(path: file.path, isVideo: false));
      }
    } catch (_) {}
  }

  Future<void> _toggleVideoRecording() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (_isRecording) {
      _autoStopTimer?.cancel();
      try {
        final file = await controller.stopVideoRecording();
        if (mounted) {
          Navigator.pop(
              context, CameraCaptureResult(path: file.path, isVideo: true));
        }
      } catch (_) {
        if (mounted) setState(() => _isRecording = false);
      }
      return;
    }
    try {
      await controller.startVideoRecording();
      setState(() => _isRecording = true);
      _autoStopTimer = Timer(widget.maxVideoDuration, () {
        if (_isRecording) _toggleVideoRecording();
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(child: _buildBody(context, l10n)),
    );
  }

  Widget _buildBody(BuildContext context, AppLocalizations l10n) {
    switch (_status) {
      case _CamStatus.checking:
        return const Center(
          child: CircularProgressIndicator(color: TraumColors.lavender),
        );
      case _CamStatus.noCamera:
        return _MessageState(
          icon: Icons.no_photography_outlined,
          title: l10n.cameraOverlayNoCameraFound,
          message: '',
          actionLabel: null,
          onAction: null,
        );
      case _CamStatus.permanentlyDenied:
        return _MessageState(
          icon: Icons.videocam_off_outlined,
          title: l10n.cameraOverlayPermissionDeniedTitle,
          message: l10n.cameraOverlayPermissionDeniedMessage,
          actionLabel: l10n.cameraOverlayOpenSettings,
          onAction: openAppSettings,
        );
      case _CamStatus.denied:
        return _MessageState(
          icon: Icons.videocam_off_outlined,
          title: l10n.cameraOverlayPermissionDeniedTitle,
          message: l10n.cameraOverlayPermissionDeniedMessage,
          actionLabel: l10n.cameraOverlayGrantAccess,
          onAction: _setup,
        );
      case _CamStatus.ready:
        return _buildCamera(context, l10n);
    }
  }

  Widget _buildCamera(BuildContext context, AppLocalizations l10n) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: TraumColors.lavender),
      );
    }
    final availableModes = [
      ReferenceOverlayMode.off,
      if (_hasGhost) ReferenceOverlayMode.lastPhoto,
      ReferenceOverlayMode.bodyFull,
      ReferenceOverlayMode.faceSingle,
      ReferenceOverlayMode.facesTwo,
      ReferenceOverlayMode.food,
    ];

    return Stack(fit: StackFit.expand, children: [
      Center(child: CameraPreview(controller)),

      // Drittel-Raster als Ausrichtungshilfe.
      const _GridOverlay(),

      // Geist-Foto oder eine der festen Umriss-Vorlagen.
      ReferenceOverlayLayer(mode: _refMode, ghostImagePath: widget.ghostImagePath),

      if (_refMode != ReferenceOverlayMode.off)
        Positioned(
          top: 8,
          left: 0,
          right: 0,
          child: Center(
            child: Text(
                _refMode == ReferenceOverlayMode.lastPhoto
                    ? l10n.cameraOverlayAlignHint
                    : l10n.cameraOverlayRefGenericHint,
                style: TextStyle(
                    fontFamily: 'DMSans',
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.6))),
          ),
        ),

      // Oberer Rand: Schließen, Kamera wechseln.
      Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _RoundIconButton(
                icon: Icons.close,
                onTap: () => Navigator.pop(context),
              ),
              _RoundIconButton(
                icon: Icons.cameraswitch_outlined,
                onTap: _cameras.length > 1 ? _flipCamera : null,
              ),
            ],
          ),
        ),
      ),

      // Vorlagen-Auswahl: alle Optionen als Icon-Leiste direkt sichtbar,
      // statt hinter einem Menü versteckt.
      Positioned(
        top: 52,
        left: 0,
        right: 0,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: availableModes
                .map((m) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: _TemplateChip(
                        mode: m,
                        label: _refModeLabel(m, l10n),
                        selected: _refMode == m,
                        onTap: () => setState(() => _refMode = m),
                      ),
                    ))
                .toList(),
          ),
        ),
      ),

      // Unterer Rand: Modus-Umschalter + Auslöser.
      Positioned(
        left: 0,
        right: 0,
        bottom: 16,
        child: Column(children: [
          if (!_isRecording)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ModeLabel(
                  label: l10n.cameraOverlayModePhoto,
                  selected: !_isVideoMode,
                  onTap: () => setState(() => _isVideoMode = false),
                ),
                const SizedBox(width: 26),
                _ModeLabel(
                  label: l10n.cameraOverlayModeVideo,
                  selected: _isVideoMode,
                  onTap: () => setState(() => _isVideoMode = true),
                ),
              ],
            ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _isVideoMode ? _toggleVideoRecording : _capturePhoto,
            child: Container(
              width: 68,
              height: 68,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
              ),
              child: Container(
                decoration: BoxDecoration(
                  shape: _isVideoMode && _isRecording
                      ? BoxShape.rectangle
                      : BoxShape.circle,
                  borderRadius: _isVideoMode && _isRecording
                      ? BorderRadius.circular(6)
                      : null,
                  color: _isVideoMode ? TraumColors.roseRed : Colors.white,
                ),
              ),
            ),
          ),
        ]),
      ),
    ]);
  }
}

String _refModeLabel(ReferenceOverlayMode m, AppLocalizations l10n) => switch (m) {
      ReferenceOverlayMode.off => l10n.cameraOverlayRefOff,
      ReferenceOverlayMode.lastPhoto => l10n.cameraOverlayRefLastPhoto,
      ReferenceOverlayMode.bodyFull => l10n.cameraOverlayRefBodyFull,
      ReferenceOverlayMode.faceSingle => l10n.cameraOverlayRefFaceSingle,
      ReferenceOverlayMode.facesTwo => l10n.cameraOverlayRefFacesTwo,
      ReferenceOverlayMode.food => l10n.cameraOverlayRefFood,
    };

class _TemplateChip extends StatelessWidget {
  final ReferenceOverlayMode mode;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TemplateChip({
    required this.mode,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: selected
                ? TraumColors.lavender.withValues(alpha: 0.9)
                : Colors.black38,
            shape: BoxShape.circle,
            border: Border.all(
                color: selected ? Colors.white : Colors.white24, width: 1),
          ),
          child: Icon(referenceOverlayModeIcon(mode),
              color: Colors.white, size: 17),
        ),
      ),
    );
  }
}

class _GridOverlay extends StatelessWidget {
  const _GridOverlay();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Opacity(
        opacity: 0.16,
        child: Stack(children: [
          Column(children: [
            const Spacer(),
            Container(height: 1, color: Colors.white),
            const Spacer(),
            Container(height: 1, color: Colors.white),
            const Spacer(),
          ]),
          Row(children: [
            const Spacer(),
            Container(width: 1, color: Colors.white),
            const Spacer(),
            Container(width: 1, color: Colors.white),
            const Spacer(),
          ]),
        ]),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _RoundIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.black38,
          shape: BoxShape.circle,
        ),
        child: Icon(icon,
            color: onTap == null ? Colors.white38 : Colors.white, size: 19),
      ),
    );
  }
}

class _ModeLabel extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ModeLabel(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(label,
          style: TextStyle(
              fontFamily: 'DMSans',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
              color: selected
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.45))),
    );
  }
}

class _MessageState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _MessageState({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, color: Colors.white38, size: 48),
            const SizedBox(height: 16),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontFamily: 'DMSans',
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16)),
            if (message.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontFamily: 'DMSans',
                      color: Colors.white70,
                      fontSize: 13)),
            ],
            if (actionLabel != null) ...[
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: TraumColors.lavender,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                ),
                child: Text(actionLabel!,
                    style: const TextStyle(
                        fontFamily: 'DMSans', fontWeight: FontWeight.w600)),
              ),
            ],
          ]),
        ),
      ),
      Positioned(
        top: 8,
        left: 8,
        child: _RoundIconButton(
            icon: Icons.close, onTap: () => Navigator.pop(context)),
      ),
    ]);
  }
}
