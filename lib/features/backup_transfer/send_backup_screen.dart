import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/platform/desktop.dart';
import '../../core/providers/database_provider.dart';
import '../../core/services/backup_service.dart';
import '../../core/services/backup_transfer/backup_send_client.dart';
import '../../core/services/backup_transfer/backup_transfer_models.dart';
import '../../core/services/backup_transfer/device_name.dart';
import '../../core/theme/colors.dart';
import '../../l10n/app_localizations.dart';
import 'pairing_manual_entry_sheet.dart';

/// Settings → "Send backup to device". Builds a fresh backup of this
/// device's data, then pairs with a receiving device (QR scan, or manual
/// IP/code entry on desktop) and drives the upload — see
/// [BackupSendClient]/[BackupReceiveServer] for the protocol itself. Nothing
/// is written on the *other* device until its own user confirms twice; this
/// screen only reports the resulting status.
class SendBackupScreen extends ConsumerStatefulWidget {
  const SendBackupScreen({
    super.key,
    this.backupService,
    this.clientFactory,
    this.debugBackupBytes,
    this.debugDeviceName,
  });

  /// Test-only override so widget tests can inject a service backed by an
  /// in-memory database instead of the real one from [databaseProvider].
  final BackupService? backupService;

  /// Test-only override: build a fake [BackupSendClient] instead of a real
  /// one, so a widget test can control exactly what "sending" reports (no
  /// real sockets). Protocol correctness is covered by
  /// backup_transfer_roundtrip_test.dart; this screen's job is only to
  /// drive pairing (scan/manual entry) and reflect the resulting status.
  final BackupSendClient Function()? clientFactory;

  /// Test-only override: skip the real `buildBackupZip()` call (which
  /// spawns a genuine background isolate — real async work that widget
  /// tests can't reliably wait on) and use these bytes instead.
  final Uint8List? debugBackupBytes;

  /// Test-only override: skip [currentDeviceName]'s platform-channel call
  /// (`device_info_plus`), which never resolves under `testWidgets` — real
  /// platform-channel I/O has the same "needs the real event loop" problem
  /// as sockets, but unlike those it can't be waited out with `runAsync`
  /// since it's triggered deep inside a widget callback, not something the
  /// test drives directly.
  final String? debugDeviceName;

  @override
  ConsumerState<SendBackupScreen> createState() => _SendBackupScreenState();
}

class _SendBackupScreenState extends ConsumerState<SendBackupScreen> {
  MobileScannerController? _scannerController;
  Uint8List? _backupBytes;
  PairingInfo? _target;
  TransferStatus? _status;
  String? _error;
  bool _sending = false;
  StreamSubscription<TransferStatus>? _sub;

  @override
  void initState() {
    super.initState();
    if (!isDesktop) {
      _scannerController = MobileScannerController(
        detectionSpeed: DetectionSpeed.normal,
        facing: CameraFacing.back,
      );
    }
    _prepareBackup();
  }

  Future<void> _prepareBackup() async {
    if (widget.debugBackupBytes != null) {
      setState(() => _backupBytes = widget.debugBackupBytes);
      return;
    }
    final BackupService service =
        widget.backupService ?? ref.read(backupServiceProvider);
    final result = await service.buildBackupZip();
    if (!mounted) return;
    setState(() => _backupBytes = Uint8List.fromList(result.zipBytes));
  }

  Future<void> _onQrDetected(BarcodeCapture capture) async {
    if (_target != null) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null) return;
    final info = PairingInfo.tryParse(raw);
    if (info == null) return;
    _scannerController?.stop();
    await _startSend(info);
  }

  Future<void> _openManualEntry() async {
    final info = await showPairingManualEntrySheet(context);
    if (info == null || !mounted) return;
    await _startSend(info);
  }

  Future<void> _startSend(PairingInfo target) async {
    final bytes = _backupBytes;
    if (bytes == null || _sending) return;
    setState(() {
      _target = target;
      _sending = true;
      _error = null;
    });

    final client = widget.clientFactory?.call() ?? BackupSendClient();
    _sub = client.statusStream.listen((status) {
      if (mounted) setState(() => _status = status);
    });

    try {
      final deviceName = widget.debugDeviceName ?? await currentDeviceName();
      final platform = currentPlatformName();
      final result = await client.send(
        target: target,
        backupBytes: bytes,
        senderDeviceName: deviceName,
        senderPlatform: platform,
      );
      if (!mounted) return;
      setState(() => _status = result.status);
    } on BackupTransferException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } finally {
      await _sub?.cancel();
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _scannerController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: TraumColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          l10n.transferSendTitle,
          style: const TextStyle(
            fontFamily: 'DMSans',
            color: TraumColors.onBackground,
          ),
        ),
      ),
      body: SafeArea(child: _buildBody(l10n)),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_error != null) {
      return _CenteredMessage(
        icon: Icons.error_rounded,
        color: TraumColors.roseRed,
        text: l10n.transferSendFailed(_error!),
      );
    }
    if (_status == TransferStatus.done) {
      return _CenteredMessage(
        icon: Icons.check_circle_rounded,
        color: TraumColors.mintGreen,
        text: l10n.transferDone,
      );
    }
    if (_status == TransferStatus.declined1 || _status == TransferStatus.declined2) {
      return _CenteredMessage(
        icon: Icons.cancel_rounded,
        color: TraumColors.roseRed,
        text: l10n.transferDeclinedByUser,
      );
    }
    if (_status == TransferStatus.error) {
      return _CenteredMessage(
        icon: Icons.error_rounded,
        color: TraumColors.roseRed,
        text: l10n.transferErrorGeneric,
      );
    }
    if (_backupBytes == null) {
      return _CenteredMessage(
        icon: null,
        color: TraumColors.coralOrange,
        text: l10n.transferPreparingBackup,
        spinner: true,
      );
    }
    if (_sending) {
      return _CenteredMessage(
        icon: null,
        color: TraumColors.coralOrange,
        text: _sendingStatusText(l10n),
        spinner: true,
      );
    }
    return _buildPairingChooser(l10n);
  }

  String _sendingStatusText(AppLocalizations l10n) {
    switch (_status) {
      case TransferStatus.uploading:
        return l10n.transferUploading;
      case TransferStatus.pendingConfirmation2:
      case TransferStatus.importing:
        return l10n.transferWaitingSecondConfirmation;
      default:
        return l10n.transferWaitingFirstConfirmation;
    }
  }

  Widget _buildPairingChooser(AppLocalizations l10n) {
    if (isDesktop) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ElevatedButton.icon(
            onPressed: _openManualEntry,
            icon: const Icon(Icons.keyboard_rounded),
            label: Text(l10n.transferManualEntryButton),
            style: ElevatedButton.styleFrom(
              backgroundColor: TraumColors.coralOrange,
            ),
          ),
        ),
      );
    }
    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              MobileScanner(
                controller: _scannerController,
                onDetect: _onQrDetected,
              ),
              Center(
                child: Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    border: Border.all(color: TraumColors.mintGreen, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextButton(
            onPressed: _openManualEntry,
            child: Text(l10n.transferManualEntryButton),
          ),
        ),
      ],
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({
    required this.icon,
    required this.color,
    required this.text,
    this.spinner = false,
  });

  final IconData? icon;
  final Color color;
  final String text;
  final bool spinner;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (spinner) CircularProgressIndicator(color: color),
            if (icon != null) Icon(icon, color: color, size: 64),
            const SizedBox(height: 16),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'DMSans',
                color: TraumColors.onBackground,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
