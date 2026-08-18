// Cook mode (design 3f): hands-off step-by-step. Big text (≥24sp), whole-zone
// tap targets for steamy hands, wakelock while open. Per-step ingredient chips
// wait for a step↔ingredient mapping in the schema (post-alpha); the timer
// parses the first duration it can find in the step text.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../domain/recipe.dart';
import '../domain/units.dart';
import 'theme.dart';
import 'units_model.dart';

class CookModeScreen extends StatefulWidget {
  const CookModeScreen({super.key, required this.recipe});

  final Recipe recipe;

  @override
  State<CookModeScreen> createState() => _CookModeScreenState();
}

class _CookModeScreenState extends State<CookModeScreen> {
  int _step = 0;
  Timer? _timer;
  int _remaining = 0; // seconds; 0 = idle
  bool _wakelockOn = false;

  @override
  void initState() {
    super.initState();
    // Wakelock is best-effort: absent plugin (tests) must never break cooking.
    WakelockPlus.enable().then((_) {
      if (mounted) setState(() => _wakelockOn = true);
    }).catchError((Object _) {});
  }

  @override
  void dispose() {
    _timer?.cancel();
    WakelockPlus.disable().catchError((Object _) {});
    super.dispose();
  }

  /// First "N min" / "N hour" mention in the step text, in minutes.
  static int? parseTimerMinutes(String text) {
    final m = RegExp(r'(\d+)\s*(?:–|-|to\s+\d+\s*)?(min|minute|hour|h)\w*',
            caseSensitive: false)
        .firstMatch(text);
    if (m == null) return null;
    final n = int.tryParse(m.group(1)!);
    if (n == null || n == 0) return null;
    return m.group(2)!.toLowerCase().startsWith('h') ? n * 60 : n;
  }

  void _startTimer(int minutes) {
    _timer?.cancel();
    setState(() => _remaining = minutes * 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _remaining--);
      if (_remaining <= 0) {
        t.cancel();
        HapticFeedback.vibrate();
      }
    });
  }

  void _goto(int step) {
    _timer?.cancel();
    setState(() {
      _step = step;
      _remaining = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = context.scheme;
    final steps = widget.recipe.steps;
    final total = steps.length;
    // Display-only conversion; the timer parses minutes, which convert to
    // themselves, so reading it off the converted text changes nothing.
    final text =
        convertUnits(steps[_step].raw, context.watch<UnitsModel>().system);
    final timerMin = parseTimerMinutes(text);
    final last = _step == total - 1;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  for (var i = 0; i < total; i++) ...[
                    if (i > 0) const SizedBox(width: 5),
                    Expanded(
                      child: Container(
                        height: 5,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          color: i <= _step
                              ? scheme.primary
                              : scheme.surfaceContainerHighest,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Step ${_step + 1} of $total · ${widget.recipe.title}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(color: scheme.onSurfaceVariant, fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => Navigator.of(context).maybePop(),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                          color: scheme.surfaceContainerHigh,
                          shape: BoxShape.circle),
                      child: Icon(Icons.close_rounded,
                          size: 19, color: scheme.onSurface),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Text(
                      text,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineMedium?.copyWith(
                          fontSize: 27,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                          letterSpacing: -0.27),
                    ),
                  ),
                ),
              ),
              if (timerMin != null) ...[
                FilledButton.tonalIcon(
                  onPressed:
                      _remaining > 0 ? null : () => _startTimer(timerMin),
                  icon: const Icon(Icons.timer_rounded),
                  label: Text(_remaining > 0
                      ? '${(_remaining ~/ 60)}:${(_remaining % 60).toString().padLeft(2, '0')}'
                      : (_timer != null && _remaining <= 0
                          ? 'Timer done'
                          : 'Start $timerMin min timer')),
                ),
                const SizedBox(height: 12),
              ],
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 60,
                      child: Material(
                        color: scheme.surfaceContainerHigh,
                        shape: const StadiumBorder(),
                        child: InkWell(
                          customBorder: const StadiumBorder(),
                          onTap: _step == 0 ? null : () => _goto(_step - 1),
                          child: Icon(Icons.arrow_back_rounded,
                              color: _step == 0
                                  ? scheme.outlineVariant
                                  : scheme.onSurfaceVariant),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 60,
                      child: FilledButton.icon(
                        onPressed: () => last
                            ? Navigator.of(context).maybePop()
                            : _goto(_step + 1),
                        icon: Text(last ? 'Done' : 'Next',
                            style: theme.textTheme.labelLarge?.copyWith(
                                fontSize: 16, color: scheme.onPrimary)),
                        label: Icon(
                            last
                                ? Icons.check_rounded
                                : Icons.arrow_forward_rounded,
                            size: 20),
                      ),
                    ),
                  ),
                ],
              ),
              if (_wakelockOn) ...[
                const SizedBox(height: 10),
                Text(
                  'Screen stays awake while you cook',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 11.5, color: scheme.onSurfaceVariant),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
