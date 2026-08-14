import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/providers/database_provider.dart';
import '../../core/theme/colors.dart';
import '../../data/database/traum_database.dart';
import 'open_food_facts_service.dart';

class BarcodeScannerScreen extends ConsumerStatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  ConsumerState<BarcodeScannerScreen> createState() =>
      _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends ConsumerState<BarcodeScannerScreen> {
  final _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );
  bool _isProcessing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: const BackButton(color: Colors.white),
        title: Text(
          AppLocalizations.of(context)!.a11yScanBarcode,
          style: const TextStyle(fontFamily: 'DMSans', color: Colors.white),
        ),
        actions: [
          IconButton(
            tooltip: AppLocalizations.of(context)!.a11yToggleTorch,
            icon: const Icon(Icons.flash_on, color: Colors.white),
            onPressed: () => _controller.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          Center(
            child: Container(
              width: 260,
              height: 160,
              decoration: BoxDecoration(
                border: Border.all(color: TraumColors.mintGreen, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Text(
              AppLocalizations.of(context)!.pointCameraAtBarcode,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'DMSans',
                fontSize: 14,
              ),
            ),
          ),
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                      color: TraumColors.mintGreen,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context)!.fetchingProduct,
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'DMSans',
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    final barcode = capture.barcodes.firstOrNull?.rawValue;
    if (barcode == null) return;

    setState(() => _isProcessing = true);
    _controller.stop();

    final dao = ref.read(foodProductsDaoProvider);

    FoodProduct? product = await dao.getByBarcode(barcode);

    if (product == null) {
      final companion = await OpenFoodFactsService.fetchProduct(barcode);
      if (companion != null) {
        final id = await dao.insertProduct(companion);
        product = await dao.getById(id);
      }
    }

    if (!mounted) return;

    if (product == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.productNotFound),
          backgroundColor: TraumColors.surface,
          action: SnackBarAction(
            label: AppLocalizations.of(context)!.manualEntry,
            textColor: TraumColors.mintGreen,
            onPressed: () => Navigator.pop(context),
          ),
        ),
      );
      setState(() => _isProcessing = false);
      _controller.start();
      return;
    }

    Navigator.pop(context, product);
  }
}
