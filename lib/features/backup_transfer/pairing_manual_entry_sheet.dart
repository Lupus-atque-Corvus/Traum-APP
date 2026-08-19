import 'package:flutter/material.dart';

import '../../core/services/backup_transfer/backup_transfer_models.dart';
import '../../core/theme/colors.dart';
import '../../l10n/app_localizations.dart';

/// Desktop/no-camera fallback for pairing: IP + port + code, typed in by
/// hand from what the receiving device's screen shows. Returns the parsed
/// [PairingInfo] via `Navigator.pop`, or `null` if cancelled.
Future<PairingInfo?> showPairingManualEntrySheet(BuildContext context) {
  return showModalBottomSheet<PairingInfo>(
    context: context,
    isScrollControlled: true,
    backgroundColor: TraumColors.surfaceElevated,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const PairingManualEntrySheet(),
  );
}

class PairingManualEntrySheet extends StatefulWidget {
  const PairingManualEntrySheet({super.key});

  @override
  State<PairingManualEntrySheet> createState() =>
      _PairingManualEntrySheetState();
}

class _PairingManualEntrySheetState extends State<PairingManualEntrySheet> {
  final _hostController = TextEditingController();
  final _portController = TextEditingController();
  final _codeController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _submit() {
    final l10n = AppLocalizations.of(context)!;
    final host = _hostController.text.trim();
    final port = int.tryParse(_portController.text.trim());
    final code = PairingCode.tryParse(_codeController.text.trim());
    if (host.isEmpty || port == null || code == null) {
      setState(() => _error = l10n.transferInvalidInput);
      return;
    }
    Navigator.pop(context, PairingInfo(host: host, port: port, code: code));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.transferConnectManually,
            style: const TextStyle(
              color: TraumColors.onBackground,
              fontFamily: 'DMSans',
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _hostController,
            keyboardType: TextInputType.number,
            style: const TextStyle(
              color: TraumColors.onBackground,
              fontFamily: 'DMSans',
            ),
            decoration: InputDecoration(labelText: l10n.transferHostLabel),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _portController,
            keyboardType: TextInputType.number,
            style: const TextStyle(
              color: TraumColors.onBackground,
              fontFamily: 'DMSans',
            ),
            decoration: InputDecoration(labelText: l10n.transferPortLabel),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _codeController,
            textCapitalization: TextCapitalization.characters,
            style: const TextStyle(
              color: TraumColors.onBackground,
              fontFamily: 'DMSans',
            ),
            decoration: InputDecoration(
              labelText: l10n.transferCodeLabel,
              hintText: 'ABCDE-FGHJK',
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: const TextStyle(
                color: TraumColors.roseRed,
                fontFamily: 'DMSans',
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.cancel),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TraumColors.coralOrange,
                  ),
                  child: Text(l10n.transferConnect),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
