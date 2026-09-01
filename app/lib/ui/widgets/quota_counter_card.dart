// Quota counter — the quiet "what's left" card (docs/ai-cap-mechanics.md §2).
// Fed by QuotaModel from the quota object the proxy hangs on every answer;
// Settings mounts it, and the import sheet and paywall get it next. Look
// borrowed from the 4d cap preview.
//
// Three states besides the plain count, all §2's wording rules: no numbers at
// all until the proxy has answered once, "nothing counts yet" inside the free
// fortnight, and no cap whatsoever on the user's own key. The meter only
// draws when there is real spending to draw — §2 forbids showing a cap
// nobody has started spending.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'skin.dart';
import '../byok_model.dart';
import '../theme.dart';

class QuotaCounterCard extends StatelessWidget {
  const QuotaCounterCard({
    super.key,
    this.used,
    this.cap,
    this.inGrace = false,
  });

  /// Rescues consumed from the included grant. Null with [cap] means this
  /// install has never had an answer from the proxy — the card says so rather
  /// than show a zero it cannot stand behind.
  final int? used;

  /// The included grant (1200 in the offer). It never refills — the card must
  /// never hint at a reset date (Decision 1). Null: see [used].
  final int? cap;

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
    final used = this.used;
    final cap = this.cap;
    // Nullable watch: previews/tests without the provider stay proxy-mode.
    final byok = context.watch<ByokModel?>();
    final byokActive = byok?.active ?? false;
    final counted = used != null && cap != null;
    // Only meter what is actually being spent: their own key has no cap, an
    // install the proxy has never answered has no number, and the free
    // fortnight is spending nothing off the allowance (§2).
    final showMeter = counted && !byokActive && !inGrace;
    // Never a negative "left": a cap that moved under existing spending must
    // read as empty, not as "-5 requests left".
    final left = counted && cap > used ? cap - used : 0;
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
                byokActive
                    ? 'your key'
                    : counted
                        ? '${_fmt(used)} / ${_fmt(cap)}'
                        : '—',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontSize: 13,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          // No cap UI in BYOK mode (mvp-build plan): their Google console
          // is their meter, so the bar and the countdown disappear.
          if (showMeter) ...[
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
                          ? 'Still in your free two weeks — your allowance is '
                              'untouched.'
                          : !counted
                              ? 'Your allowance shows up here after the first '
                                  'AI import.'
                              : '${_fmt(left)} of ${_fmt(cap)} '
                                  'requests left.',
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                ),
              ),
              // BYOK door (mvp-build plan): the key it saves lands in
              // device.json and flips the extractor's transport per call.
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
