// Pantry barcode scan — poc/pantry-scan spike (2026-08-17). Live EAN/UPC
// capture for a future pantry surface: full-screen camera with a torch
// toggle, plus a gallery fallback that reuses the app-wide PhotoSources seam
// (the same provider the detail screen's cover picker reads). The screen only
// CAPTURES the digits — what a product code means is the caller's business.
//
// Hidden behind kPantryEnabled (features.dart) and wired into no navigation;
// the wiring session does that. Push with `Navigator.push<String>`; resolves
// to the barcode digits, or null when the user backs out.

import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'
    show HapticFeedback, SystemUiOverlayStyle;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../photo_sources.dart';
import '../theme.dart';
import '../widgets/skin.dart';

class BarcodeScanScreen extends StatefulWidget {
  const BarcodeScanScreen({super.key});

  @override
  State<BarcodeScanScreen> createState() => _BarcodeScanScreenState();
}

class _BarcodeScanScreenState extends State<BarcodeScanScreen> {
  /// Retail product codes only — anything else on a pantry shelf is noise.
  static const _formats = [
    BarcodeFormat.ean13,
    BarcodeFormat.ean8,
    BarcodeFormat.upcA,
    BarcodeFormat.upcE,
  ];

  final _controller = MobileScannerController(formats: _formats);
  String? _found; // digits once detected — drives the confirm flash
  bool _busy = false; // gallery decode in flight

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// EAN/UPC rawValue is the digit string; the guard keeps a mis-detected
  /// frame (or a QR in a gallery shot) from popping garbage to the caller.
  String? _digitsOf(BarcodeCapture? capture) {
    for (final b in capture?.barcodes ?? const <Barcode>[]) {
      final v = b.rawValue ?? b.displayValue;
      if (v != null && RegExp(r'^\d{6,14}$').hasMatch(v)) return v;
    }
    return null;
  }

  /// The one way out with a result: haptic + green flash, then pop.
  Future<void> _confirm(String digits) async {
    if (_found != null) return; // live frames can double-fire
    unawaited(_controller.stop());
    HapticFeedback.vibrate(); // same confirm gesture as cook mode's timer
    setState(() => _found = digits);
    // Long enough to read the flash, short enough to feel instant.
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (mounted) Navigator.of(context).pop(digits);
  }

  void _onDetect(BarcodeCapture capture) {
    final digits = _digitsOf(capture);
    if (digits != null) unawaited(_confirm(digits));
  }

  /// Gallery fallback — screenshots of barcodes exist too. Reuses the
  /// injected picker, so tests and future platforms swap it for free.
  Future<void> _fromGallery() async {
    final photos = context.read<PhotoSources>();
    setState(() => _busy = true);
    try {
      final file = await photos.pickOne(photos.gallery);
      if (file == null) return; // backed out of the picker
      final digits = _digitsOf(
          await _controller.analyzeImage(file.path, formats: _formats));
      if (!mounted) return;
      if (digits != null) {
        await _confirm(digits);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('No barcode in that image — try a closer, '
                'sharper shot of the code.')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        // Same status-bar discipline as OriginalsViewer: dark chrome must set
        // light icons itself, or popping leaves them wrong over cream.
        systemOverlayStyle: SystemUiOverlayStyle.light,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: const AppBackButton(),
        title: Text('Scan a barcode',
            style: theme.textTheme.titleLarge?.copyWith(color: Colors.white)),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error) =>
                _CameraUnavailable(error: error),
          ),
          // Framing guide — roughly a product barcode's aspect.
          IgnorePointer(
            child: Center(
              child: Container(
                width: 250,
                height: 150,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white70, width: 2),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Point the camera at the product barcode',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: Colors.white70)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Torch state lives on the controller's notifier.
                        ValueListenableBuilder<MobileScannerState>(
                          valueListenable: _controller,
                          builder: (context, state, _) {
                            final on = state.torchState == TorchState.on;
                            return GlassCircle(
                              icon: on
                                  ? Icons.flash_on_rounded
                                  : Icons.flash_off_rounded,
                              filled: on,
                              tooltip: on ? 'Torch off' : 'Torch on',
                              onTap:
                                  state.torchState == TorchState.unavailable
                                      ? null
                                      : () =>
                                          unawaited(_controller.toggleTorch()),
                            );
                          },
                        ),
                        const SizedBox(width: 14),
                        _busy
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2.5))
                            : GlassPill(
                                icon: Icons.photo_library_rounded,
                                label: 'From a photo',
                                onTap: _found != null ? null : _fromGallery,
                              ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Confirm flash: dim the preview, show the digits on success green.
          if (_found != null)
            ColoredBox(
              color: Colors.black54,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 11),
                  decoration: BoxDecoration(
                    color: RbColors.success,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_rounded,
                          size: 20, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(_found!,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Honest degraded state: no camera (or no permission) still leaves the
/// gallery path usable, so say so instead of a dead black screen.
class _CameraUnavailable extends StatelessWidget {
  const _CameraUnavailable({required this.error});

  final MobileScannerException error;

  @override
  Widget build(BuildContext context) {
    final denied =
        error.errorCode == MobileScannerErrorCode.permissionDenied;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.no_photography_rounded,
                size: 40, color: Colors.white38),
            const SizedBox(height: 12),
            Text(
              denied
                  ? 'Camera permission was denied — allow it in system '
                      'settings, or scan from a photo below.'
                  : 'Camera unavailable — you can still scan from a '
                      'photo below.',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.white70, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
