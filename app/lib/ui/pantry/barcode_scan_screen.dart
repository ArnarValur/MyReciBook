// Pantry barcode scan — poc/pantry-scan spike (2026-08-17). Live EAN/UPC
// capture: full-screen camera with a torch toggle, plus a gallery fallback
// that reuses the app-wide PhotoSources seam (the same provider the detail
// screen's cover picker reads). The screen only CAPTURES digits — what a
// product code means is the caller's business.
//
// Two modes (Arnar's S21 pass, same day: "scanning mode sorta speak"):
// - collect != null — the shelf-sweep flow. Each detection hands digits to
//   [collect], flashes its feedback over the live preview, cools down ~3 s,
//   and keeps scanning. Back ends the session; the caller's list is already
//   up to date because collect did the saving.
// - collect == null — legacy one-shot: haptic + green flash, then pops the
//   digits as a String (null when the user backs out).

import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'
    show HapticFeedback, SystemUiOverlayStyle;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../photo_sources.dart';
import '../theme.dart';
import '../widgets/skin.dart';

/// What a collect-mode detection came to: one line for the flash chip.
class ScanFeedback {
  const ScanFeedback(this.message, {this.ok = true, this.action, this.actionLabel});

  final String message;

  /// false = shown in error red (not found / lookup down), true = success.
  final bool ok;

  /// What tapping the flash bar does. Null leaves the bar inert, which is
  /// what "Open Food Facts didn't answer" wants — there is nothing to open
  /// and nothing to create, only a rescan.
  ///
  /// Awaited, and the scan screen pauses its camera while it runs: the action
  /// pushes a route, and a scanner running behind a form is battery spent on
  /// nothing.
  final Future<void> Function()? action;

  /// Short verb on the bar's right, so the tap is visibly offered rather than
  /// hidden behind a guess. Ignored when [action] is null.
  final String? actionLabel;
}

typedef ScanCollect = Future<ScanFeedback> Function(String digits);

class BarcodeScanScreen extends StatefulWidget {
  const BarcodeScanScreen({super.key, this.collect});

  /// Collect mode: called per detection; the screen stays open and scans on.
  final ScanCollect? collect;

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

  /// Post-flash breather before the next detection counts.
  static const _cooldown = Duration(seconds: 3);

  /// The same breather when the bar carries something to tap.
  static const _actionCooldown = Duration(seconds: 6);

  /// A jar still in frame right after cooldown must not re-add itself.
  static const _sameCodeGrace = Duration(seconds: 8);

  final _controller = MobileScannerController(formats: _formats);
  String? _found; // one-shot mode: digits once detected — the confirm flash
  bool _busy = false; // gallery decode in flight

  // Collect-mode state: the flash chip and the detection gate.
  String? _flash;
  bool _flashOk = true;
  Future<void> Function()? _flashAction;
  String? _flashActionLabel;
  bool _looking = false;
  bool _cooling = false;
  String? _lastDigits;
  DateTime _lastAt = DateTime.fromMillisecondsSinceEpoch(0);

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

  void _onDetect(BarcodeCapture capture) {
    final digits = _digitsOf(capture);
    if (digits == null) return;
    if (widget.collect != null) {
      unawaited(_handleCollect(digits));
    } else {
      unawaited(_confirmOneShot(digits));
    }
  }

  /// Collect mode: save through the caller, flash the verdict, cool down,
  /// keep the camera rolling — the next product needs no button press.
  Future<void> _handleCollect(String digits) async {
    if (_cooling || _looking) return;
    if (digits == _lastDigits &&
        DateTime.now().difference(_lastAt) < _sameCodeGrace) {
      return;
    }
    HapticFeedback.vibrate(); // same confirm gesture as cook mode's timer
    setState(() {
      _looking = true;
      _flash = 'Looking it up…';
      _flashOk = true;
    });
    final fb = await widget.collect!(digits);
    if (!mounted) return;
    _lastDigits = digits;
    _lastAt = DateTime.now();
    setState(() {
      _looking = false;
      _cooling = true;
      _flash = fb.message;
      _flashOk = fb.ok;
      _flashAction = fb.action;
      _flashActionLabel = fb.actionLabel;
    });
    // A bar you can act on gets longer than one you can only read: three
    // seconds is a glance, not a decision.
    await Future<void>.delayed(fb.action == null ? _cooldown : _actionCooldown);
    if (!mounted) return;
    setState(() {
      _flash = null;
      _flashAction = null;
      _flashActionLabel = null;
      _cooling = false;
    });
  }

  /// Run the flash bar's action with the camera stopped. Returning to a live
  /// scanner with the same pack still in frame would re-fire the detection
  /// the user just dealt with, so the grace window is reset on the way back.
  Future<void> _runFlashAction() async {
    final action = _flashAction;
    if (action == null) return;
    setState(() {
      _flash = null;
      _flashAction = null;
      _flashActionLabel = null;
    });
    await _controller.stop();
    try {
      await action();
    } finally {
      if (mounted) {
        _lastAt = DateTime.now();
        _cooling = false;
        await _controller.start();
      }
    }
  }

  /// One-shot mode's way out with a result: haptic + green flash, then pop.
  Future<void> _confirmOneShot(String digits) async {
    if (_found != null) return; // live frames can double-fire
    unawaited(_controller.stop());
    HapticFeedback.vibrate();
    setState(() => _found = digits);
    // Long enough to read the flash, short enough to feel instant.
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (mounted) Navigator.of(context).pop(digits);
  }

  /// Gallery fallback — screenshots of barcodes exist too. Reuses the
  /// injected picker, so tests and future platforms swap it for free.
  /// One code per image for now (multi-barcode shelf shots: known gap).
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
        if (widget.collect != null) {
          await _handleCollect(digits);
        } else {
          await _confirmOneShot(digits);
        }
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
    final collectMode = widget.collect != null;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        // Same status-bar discipline as OriginalsViewer: dark chrome must set
        // light icons itself, or popping leaves them wrong over cream.
        systemOverlayStyle: SystemUiOverlayStyle.light,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: const AppBackButton(),
        title: Text(collectMode ? 'Collect your pantry' : 'Scan a barcode',
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
                    Text(
                        collectMode
                            ? 'Point at a barcode — each product saves as '
                                'you go. Back when the shelf is done.'
                            : 'Point the camera at the product barcode',
                        textAlign: TextAlign.center,
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
                                onTap: _found != null || _looking
                                    ? null
                                    : _fromGallery,
                              ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Collect-mode flash: verdict chip over the live preview — no dim,
          // the user is already aiming at the next product.
          if (_flash != null)
            Align(
              alignment: const Alignment(0, -0.62),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Material(
                  color: _flashOk ? RbColors.success : theme.colorScheme.error,
                  borderRadius: BorderRadius.circular(999),
                  child: InkWell(
                    key: const Key('scan-flash-bar'),
                    borderRadius: BorderRadius.circular(999),
                    // Null keeps the bar inert — the old IgnorePointer, now
                    // conditional instead of absolute.
                    onTap: _flashAction == null ? null : _runFlashAction,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_looking)
                            const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                          else
                            Icon(
                                _flashOk
                                    ? Icons.check_rounded
                                    : Icons.error_outline_rounded,
                                size: 18,
                                color: Colors.white),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(_flash!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleSmall
                                    ?.copyWith(color: Colors.white)),
                          ),
                          if (_flashAction != null &&
                              _flashActionLabel != null) ...[
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.22),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(_flashActionLabel!,
                                  style: theme.textTheme.labelMedium?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          // One-shot confirm flash: dim the preview, show the digits.
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
