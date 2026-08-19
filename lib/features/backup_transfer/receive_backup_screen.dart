import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/providers/database_provider.dart';
import '../../core/services/backup_service.dart';
import '../../core/services/backup_transfer/backup_receive_server.dart';
import '../../core/services/backup_transfer/backup_transfer_models.dart';
import '../../core/services/backup_transfer/local_ip.dart';
import '../../core/theme/colors.dart';
import '../../l10n/app_localizations.dart';

/// Settings → "Receive backup from device". Starts a short-lived local HTTP
/// server (see [BackupReceiveServer]'s doc comment for the protocol), shows
/// a QR/PIN for another device to pair with, and drives both confirmation
/// dialogs required before anything is written to this device's database.
class ReceiveBackupScreen extends ConsumerStatefulWidget {
  const ReceiveBackupScreen({
    super.key,
    this.backupService,
    this.onReady,
    this.server,
  });

  /// Test-only override so widget tests can inject a service backed by an
  /// in-memory database instead of the real one from [databaseProvider].
  final BackupService? backupService;

  /// Test-only hook, called once the server is bound and [PairingInfo] is
  /// known — lets a widget test observe the code/URI the screen ends up
  /// showing without reaching into private state.
  final ValueChanged<PairingInfo>? onReady;

  /// Test-only override: inject a fake [BackupReceiveServer] so a widget
  /// test can drive [TransferStatus] transitions directly (no real sockets,
  /// no flakiness) — protocol correctness itself is covered by
  /// backup_transfer_roundtrip_test.dart; this screen's job is only to map
  /// those transitions to the right dialogs.
  final BackupReceiveServer? server;

  @override
  ConsumerState<ReceiveBackupScreen> createState() =>
      _ReceiveBackupScreenState();
}

class _ReceiveBackupScreenState extends ConsumerState<ReceiveBackupScreen> {
  late final BackupReceiveServer _server;
  StreamSubscription<TransferStatus>? _sub;
  PairingInfo? _info;
  List<String> _localIps = [];
  TransferStatus? _status;
  bool _dialogShowing = false;

  @override
  void initState() {
    super.initState();
    final BackupService service =
        widget.backupService ?? ref.read(backupServiceProvider);
    _server = widget.server ?? BackupReceiveServer(service);
    _start();
  }

  Future<void> _start() async {
    final boundInfo = await _server.start();
    final ips = await listLocalIPv4Addresses();
    if (!mounted) return;
    setState(() {
      _localIps = ips;
      _info = ips.isNotEmpty
          ? PairingInfo(host: ips.first, port: boundInfo.port, code: boundInfo.code)
          : boundInfo;
    });
    widget.onReady?.call(_info!);
    _sub = _server.statusStream.listen(_onStatus);
  }

  void _onStatus(TransferStatus status) {
    if (!mounted) return;
    setState(() => _status = status);
    if (status == TransferStatus.pendingConfirmation1) {
      _showConfirmation1Dialog();
    } else if (status == TransferStatus.pendingConfirmation2) {
      _showConfirmation2Dialog();
    }
  }

  Future<void> _showConfirmation1Dialog() async {
    if (_dialogShowing) return;
    _dialogShowing = true;
    final l10n = AppLocalizations.of(context)!;
    final accept = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: TraumColors.surfaceElevated,
        title: Text(
          l10n.transferIncomingRequestTitle,
          style: const TextStyle(
            color: TraumColors.onBackground,
            fontFamily: 'DMSans',
          ),
        ),
        content: Text(
          l10n.transferIncomingRequestBody(_server.pairedSenderName ?? '?'),
          style: const TextStyle(
            color: TraumColors.onBackgroundMuted,
            fontFamily: 'DMSans',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.transferDecline),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: TraumColors.coralOrange,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.transferAccept),
          ),
        ],
      ),
    );
    _dialogShowing = false;
    _server.respondToConfirmation1(accept ?? false);
  }

  Future<void> _showConfirmation2Dialog() async {
    if (_dialogShowing) return;
    _dialogShowing = true;
    final l10n = AppLocalizations.of(context)!;
    final preview = _server.preview;
    final accept = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: TraumColors.surfaceElevated,
        title: Text(
          l10n.transferConfirmImportTitle,
          style: const TextStyle(
            color: TraumColors.onBackground,
            fontFamily: 'DMSans',
          ),
        ),
        content: Text(
          preview != null
              ? l10n.transferConfirmImportBody(
                  preview.tableCount,
                  preview.rowCount,
                  preview.mediaCount,
                )
              : '',
          style: const TextStyle(
            color: TraumColors.onBackgroundMuted,
            fontFamily: 'DMSans',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.transferDecline),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: TraumColors.coralOrange,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.transferAccept),
          ),
        ],
      ),
    );
    _dialogShowing = false;
    await _server.respondToConfirmation2(accept ?? false);
  }

  @override
  void dispose() {
    _sub?.cancel();
    _server.stop();
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
          l10n.transferReceiveTitle,
          style: const TextStyle(
            fontFamily: 'DMSans',
            color: TraumColors.onBackground,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(padding: const EdgeInsets.all(24), child: _buildBody(l10n)),
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    final info = _info;
    if (info == null) {
      return const Center(
        child: CircularProgressIndicator(color: TraumColors.coralOrange),
      );
    }
    if (_status == TransferStatus.done) {
      return _StatusResult(
        icon: Icons.check_circle_rounded,
        color: TraumColors.mintGreen,
        text: l10n.transferImportSuccess,
      );
    }
    if (_status == TransferStatus.declined1 || _status == TransferStatus.declined2) {
      return _StatusResult(
        icon: Icons.cancel_rounded,
        color: TraumColors.roseRed,
        text: l10n.transferDeclinedByUser,
      );
    }
    if (_status == TransferStatus.error) {
      return _StatusResult(
        icon: Icons.error_rounded,
        color: TraumColors.roseRed,
        text: l10n.transferErrorGeneric,
      );
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: QrImageView(data: info.toUri().toString(), size: 220),
        ),
        const SizedBox(height: 24),
        Text(
          info.code.formatted,
          style: const TextStyle(
            fontFamily: 'DMSans',
            color: TraumColors.onBackground,
            fontSize: 28,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          l10n.transferShowCodeHint,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'DMSans',
            color: TraumColors.onBackgroundMuted,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 24),
        if (_localIps.isEmpty)
          Text(
            l10n.transferLocalIpUnavailable,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'DMSans',
              color: TraumColors.amberGold,
              fontSize: 12,
            ),
          )
        else if (_status == null)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: TraumColors.onBackgroundMuted,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                l10n.transferWaitingForSender,
                style: const TextStyle(
                  fontFamily: 'DMSans',
                  color: TraumColors.onBackgroundMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _StatusResult extends StatelessWidget {
  const _StatusResult({required this.icon, required this.color, required this.text});

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 64),
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
    );
  }
}
