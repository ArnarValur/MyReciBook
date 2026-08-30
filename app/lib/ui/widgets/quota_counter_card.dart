// Quota counter — the quiet "what's left" card (docs/ai-cap-mechanics.md §2).
// Visuals first (Arnar 2026-08-30): fed demo numbers from Settings until the
// quota object the proxy already returns on every /extract is cached app-side
// (mvp-build plan, "Quota counter UI"). Same card will ride the import sheet
// and paywall when the wiring lands. Look borrowed from the 4d cap preview.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'skin.dart';
import '../byok_model.dart';
import '../theme.dart';

class QuotaCounterCard extends StatelessWidget {
  const QuotaCounterCard({
    super.key,
    required this.used,
    required this.cap,
    this.resetsOn,
    this.inGrace = false,
  });

  /// Rescues consumed this cap year.
  final int used;

  /// The yearly fair-use cap (1200 in the offer).
  final int cap;

  /// Human date the counter resets on, e.g. '1 January'. Null hides the
  /// reset clause (no date decided / not wired yet).
  final String? resetsOn;

  /// Free-fortnight window: nothing counts yet (§2 grace wording).
  final bool inGrace;

  static String _fmt(int n) {
    final s = n.toString();
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
      b.write(s[i]);
    }
    return b.toString();
  }

  void _showKeyDialog(BuildContext context, ByokModel? byok) {
    final ctl = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) {
        final scheme = ctx.scheme;
        final active = byok?.active ?? false;
        return AlertDialog(
          title: const Text('Use your own Gemini key'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: ctl,
                autofocus: true,
                obscureText: true,
                decoration: InputDecoration(
                  labelText:
                      active ? 'Replace saved key' : 'Gemini API key',
                  hintText: 'AIza…',
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'AI runs on your key and your Google bill — the counter '
                'above stops metering. On Google’s free tier, Google '
                'may train on what you send; the paid tier doesn’t. The '
                'key stays on this phone and is only ever sent to Google.',
                style: Theme.of(ctx)
                    .textTheme
                    .bodySmall
                    ?.copyWith(height: 1.4, color: scheme.onSurfaceVariant),
              ),
            ],
          ),
          actions: [
            if (active)
              TextButton(
                  onPressed: () {
                    byok?.setKey(null);
                    Navigator.of(ctx).pop();
                  },
                  child: Text('Remove key',
                      style: TextStyle(color: scheme.error))),
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel')),
            FilledButton(
                onPressed: () {
                  final k = ctl.text.trim();
                  if (k.isNotEmpty) byok?.setKey(k);
                  Navigator.of(ctx).pop();
                },
                child: const Text('Save')),
          ],
        );
      },
    );
    // No manual dispose: the pop's exit animation still draws the TextField
    // after the route future completes, and touching a disposed controller
    // throws. Short-lived and unreferenced afterwards — GC takes it.
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = context.scheme;
    final left = cap - used;
    // Nullable watch: previews/tests without the provider stay proxy-mode.
    final byok = context.watch<ByokModel?>();
    final byokActive = byok?.active ?? false;
    return TokenCard(
      radius: 16,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    size: 16,
                    color: scheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'MyReciBook   AI requests',
                    style: theme.textTheme.titleSmall?.copyWith(fontSize: 13),
                  ),
                ],
              ),
              Text(
                byokActive ? 'your key' : '${_fmt(used)} / ${_fmt(cap)}',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontSize: 13,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          // No cap UI in BYOK mode (mvp-build plan): their Google console
          // is their meter, so the bar and the countdown disappear.
          if (!byokActive) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: cap == 0 ? 0 : (used / cap).clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: scheme.surfaceContainerHigh,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  byokActive
                      ? 'Running on your own Gemini key — the counter '
                          'doesn’t apply.'
                      : inGrace
                          ? 'Still in your free two weeks — nothing counts yet.'
                          : '${_fmt(left)} of ${_fmt(cap)} requests left'
                              '${resetsOn == null ? '' : ' — resets $resetsOn'}.',
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                ),
              ),
              // BYOK door (mvp-build plan, parked): visuals only — the key
              // is neither stored nor sent anywhere yet.
              InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () => _showKeyDialog(context, byok),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.settings_rounded,
                    size: 18,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
