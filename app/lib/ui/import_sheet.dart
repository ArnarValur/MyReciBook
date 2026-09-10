// Import sheet (design 3a). A chooser that owns the pick: a single shot (or
// camera page) pops straight into the one-recipe flow; two or more picks
// surface the designed segmented choice — "One recipe · N shots" vs
// "N separate recipes" — with the CTA label mirroring it ("Rescue as one
// recipe" / "Rescue N recipes"). The link door (2a, "Or fetch from the
// internet") opened 2026-09-10 at Arnar's ask: the row unfolds into a box,
// pre-filled from the clipboard when a link is sitting there, and pops with
// the URL — the shell hands it to the same review the share sheet uses.
//
// DEVIATIONS (for Arnar to ratify):
// - 3a draws no manual-entry door — the promise lives on 4c/4d/5b ("Typing
//   recipes in yourself is always unlimited"). Placed as a third row in the
//   sheet's own language (camera-row pattern, edit icon); copy drafted here:
//   "New Recipe / no AI, no cap — always unlimited" (renamed from "Type it
//   in yourself" 2026-08-20, when the row editor became the one screen for
//   creating AND editing).
// - screenshots-tile caption redrafted ("one recipe or a whole pile — you
//   decide next"): the old "pick every shot of one recipe" line became untrue
//   the moment batch landed.
//
// The allowance line (docs/ai-cap-mechanics.md §2, 2026-09-03): the counter
// sits where the decision happens — one quiet line under the AI section
// saying what is left and that an import uses one. Exactly two nudges: the
// wording turns into a heads-up at ~80%, and when the grant is spent the AI
// doors lead to the cap screen instead of the picker, so nobody meets the
// cap as a failed extraction. Own key: no cap, and the line says so.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'
    show Clipboard, PlatformException, TextInputAction;
import 'package:provider/provider.dart';

import '../domain/quota.dart';
import 'byok_model.dart';
import 'cap_reached_screen.dart';
import 'quota_model.dart';
import 'theme.dart';
import 'widgets/quota_counter_card.dart' show formatRescues;
import 'widgets/skin.dart';

/// What the user chose. [ImportPicked.separate] carries the 3a segmented
/// decision: false = stacked multi-shot single recipe, true = one batch-queue
/// item per shot.
sealed class ImportChoice {
  const ImportChoice();
}

class ImportPicked extends ImportChoice {
  const ImportPicked(this.images, {required this.separate});

  final List<File> images;
  final bool separate;
}

class ImportManual extends ImportChoice {
  const ImportManual();
}

/// A pasted recipe link — the shell opens the link review with it.
class ImportLink extends ImportChoice {
  const ImportLink(this.url);

  final String url;
}

/// The first http(s) link inside pasted text, or null. Same shape the
/// Android share bridge uses to pull a URL out of a shared caption.
String? linkIn(String text) =>
    RegExp(r'https?://\S+').firstMatch(text)?.group(0);

/// Slides up over a 45% scrim; resolves to the user's choice or null.
Future<ImportChoice?> showImportSheet(
  BuildContext context, {
  required Future<List<File>> Function() picker,
  Future<List<File>> Function()? camera,
}) {
  return showModalBottomSheet<ImportChoice>(
    context: context,
    barrierColor: const Color(0x730B0D16),
    isScrollControlled: true,
    builder: (context) => _ImportSheet(picker: picker, camera: camera),
  );
}

class _ImportSheet extends StatefulWidget {
  const _ImportSheet({required this.picker, this.camera});

  final Future<List<File>> Function() picker;
  final Future<List<File>> Function()? camera;

  @override
  State<_ImportSheet> createState() => _ImportSheetState();
}

class _ImportSheetState extends State<_ImportSheet> {
  List<File> _picked = const [];
  bool _separate = false;
  bool _picking = false;
  bool _linkOpen = false;
  String? _linkError;
  final _linkCtl = TextEditingController();

  @override
  void dispose() {
    _linkCtl.dispose();
    super.dispose();
  }

  /// The link door: unfold the box. A link already on the clipboard lands in
  /// it, so the common case is one tap and one more.
  Future<void> _openLink() async {
    String? clip;
    try {
      clip = (await Clipboard.getData(Clipboard.kTextPlain))?.text;
    } catch (_) {} // no clipboard (tests, odd OEMs) — the box just stays empty
    if (!mounted) return;
    final found = clip == null ? null : linkIn(clip);
    if (found != null) _linkCtl.text = found;
    setState(() {
      _linkOpen = true;
      _linkError = null;
    });
  }

  void _submitLink() {
    final url = linkIn(_linkCtl.text.trim());
    if (url == null) {
      setState(() => _linkError = "That doesn't look like a link — it "
          'should start with http.');
      return;
    }
    Navigator.pop(context, ImportLink(url));
  }

  Future<void> _pick(Future<List<File>> Function() source) async {
    if (_picking) return;
    _picking = true;
    final List<File> picks;
    try {
      picks = await source();
    } on PlatformException {
      return; // double-tap races the native picker ('already_active')
    } finally {
      _picking = false;
    }
    if (!mounted || picks.isEmpty) return;
    if (picks.length == 1) {
      Navigator.pop(context, ImportPicked(picks, separate: false));
      return;
    }
    // ≥2 shots: the segmented choice appears (3a) instead of popping.
    setState(() {
      _picked = picks;
      _separate = false;
    });
  }

  /// The grant is spent: the AI doors open the cap screen, whose free door
  /// pops this sheet with the manual choice exactly as the typed-in row does.
  Future<void> _capReached() async {
    final result = await Navigator.of(context).push<CapReachedResult>(
      MaterialPageRoute(builder: (_) => const CapReachedScreen()),
    );
    if (!mounted || result != CapReachedResult.typeIt) return;
    Navigator.pop(context, const ImportManual());
  }

  /// One sentence of truth about the allowance, or nothing at all before the
  /// proxy has ever answered — no number the app cannot stand behind.
  static String? allowanceLine(QuotaSnapshot? q, {required bool ownKey}) {
    if (ownKey) return 'Running on your own Gemini key — no cap.';
    if (q == null) return null;
    if (q.inGrace) return "Free for now — your first two weeks don't count.";
    final cap = formatRescues(q.cap);
    if (q.exhausted) {
      return 'Your $cap included rescues are used up — typing it in is '
          'always free.';
    }
    final left = formatRescues(q.left);
    if (q.nearlyUsed) {
      return 'Heads-up: ${formatRescues(q.used)} of $cap used — $left left, '
          'plenty for now.';
    }
    return '$left of $cap rescues left — each import uses one.';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = context.scheme;
    // The keyboard rises under the link box: the sheet lifts with it.
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 10, 20, 26 + inset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: scheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text('Add to your book',
                style: theme.textTheme.titleLarge?.copyWith(fontSize: 20)),
            const SizedBox(height: 12),
            if (_picked.length >= 2)
              ..._selection(theme, scheme)
            else if (_linkOpen)
              ..._linkEntry(theme, scheme)
            else
              ..._chooser(theme, scheme),
          ],
        ),
      ),
    );
  }

  // ── Phase 1: pick a source ────────────────────────────────────────────────

  List<Widget> _chooser(ThemeData theme, ColorScheme scheme) {
    // Nullable watches: tests and previews without the providers stay in
    // plain proxy mode with no line, same as the counter card.
    final quota = context.watch<QuotaModel?>()?.quota;
    final ownKey = context.watch<ByokModel?>()?.active ?? false;
    final line = allowanceLine(quota, ownKey: ownKey);
    final exhausted = !ownKey && (quota?.exhausted ?? false);
    const spentCaption = 'included rescues used up — see your options';
    return [
        const SectionLabel('From your screenshots'),
        if (line != null) ...[
          const SizedBox(height: 4),
          Text(
            line,
            key: const Key('import-allowance-line'),
            style: theme.textTheme.bodySmall
                ?.copyWith(color: scheme.onSurfaceVariant, height: 1.4),
          ),
        ],
        const SizedBox(height: 8),
        InkWell(
          key: const Key('import-screenshots-tile'),
          borderRadius: BorderRadius.circular(12),
          onTap: exhausted ? _capReached : () => _pick(widget.picker),
          child: Ink(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.photo_library_rounded,
                      size: 20, color: scheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Choose screenshots',
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontSize: 14)),
                      const SizedBox(height: 2),
                      Text(
                        exhausted
                            ? spentCaption
                            : 'one recipe or a whole pile — you decide next',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: scheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        const SectionLabel('Or fetch from the internet'),
        const SizedBox(height: 8),
        _doorRow(
          theme,
          scheme,
          key: const Key('import-link-tile'),
          icon: Icons.link_rounded,
          title: 'Paste a link',
          caption: exhausted ? spentCaption : 'TikTok, IG, blog…',
          onTap: exhausted ? _capReached : _openLink,
        ),
        const SizedBox(height: 6),
        Text(
          _linkNote,
          style: theme.textTheme.bodySmall
              ?.copyWith(color: scheme.onSurfaceVariant, height: 1.4),
        ),
        if (widget.camera != null) ...[
          const SizedBox(height: 12),
          Divider(height: 1, color: context.rb.hairline),
          const SizedBox(height: 12),
          _doorRow(
            theme,
            scheme,
            key: const Key('import-camera-tile'),
            icon: Icons.photo_camera_rounded,
            title: 'Snap a page',
            caption: exhausted
                ? spentCaption
                : "cookbook or grandma's card — handwriting welcome",
            onTap: exhausted ? _capReached : () => _pick(widget.camera!),
          ),
        ],
        const SizedBox(height: 12),
        Divider(height: 1, color: context.rb.hairline),
        const SizedBox(height: 12),
        // The 5b promise as a door: typed-in recipes never touch the AI cap.
        _doorRow(
          theme,
          scheme,
          key: const Key('import-manual-tile'),
          icon: Icons.edit_rounded,
          title: 'New Recipe',
          caption: 'no AI, no cap — always unlimited',
          onTap: () => Navigator.pop(context, const ImportManual()),
        ),
      ];
  }

  // 2a's footnote under the link door, kept honest: a video with the recipe
  // only spoken aloud has nothing on the page to read.
  static const _linkNote = 'Links work when the recipe is written on the '
      "page or in the caption. Screenshots always work — that's why they "
      'come first.';

  // ── The link door, unfolded ──────────────────────────────────────────────

  List<Widget> _linkEntry(ThemeData theme, ColorScheme scheme) {
    return [
      const SectionLabel('Or fetch from the internet'),
      const SizedBox(height: 8),
      TextField(
        key: const Key('import-link-field'),
        controller: _linkCtl,
        autofocus: true,
        keyboardType: TextInputType.url,
        textInputAction: TextInputAction.go,
        autocorrect: false,
        enableSuggestions: false,
        onChanged: (_) {
          if (_linkError != null) setState(() => _linkError = null);
        },
        onSubmitted: (_) => _submitLink(),
        decoration: InputDecoration(
          hintText: 'https://…',
          prefixIcon: const Icon(Icons.link_rounded),
          errorText: _linkError,
          suffixIcon: IconButton(
            key: const Key('import-link-paste'),
            tooltip: 'Paste',
            icon: const Icon(Icons.content_paste_rounded, size: 20),
            onPressed: () async {
              String? clip;
              try {
                clip = (await Clipboard.getData(Clipboard.kTextPlain))?.text;
              } catch (_) {}
              if (!mounted || clip == null || clip.isEmpty) return;
              final text = clip.trim();
              setState(() {
                _linkCtl.text = text;
                _linkError = null;
              });
            },
          ),
        ),
      ),
      const SizedBox(height: 8),
      Text(
        _linkNote,
        style: theme.textTheme.bodySmall
            ?.copyWith(color: scheme.onSurfaceVariant, height: 1.4),
      ),
      const SizedBox(height: 16),
      FilledButton(
        key: const Key('import-link-cta'),
        onPressed: _submitLink,
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Rescue from link'),
            SizedBox(width: 6),
            Icon(Icons.arrow_forward_rounded, size: 18),
          ],
        ),
      ),
    ];
  }

  Widget _doorRow(
    ThemeData theme,
    ColorScheme scheme, {
    required Key key,
    required IconData icon,
    required String title,
    required String caption,
    required VoidCallback onTap,
  }) {
    return InkWell(
      key: key,
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: scheme.onSurfaceVariant),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: theme.textTheme.titleSmall?.copyWith(fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(caption,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  // ── Phase 2: ≥2 picked — the 3a segmented choice ──────────────────────────

  List<Widget> _selection(ThemeData theme, ColorScheme scheme) {
    final n = _picked.length;
    return [
      const SectionLabel('From your screenshots'),
      const SizedBox(height: 8),
      ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 190),
        child: GridView.builder(
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 74 / 86,
          ),
          itemCount: n,
          itemBuilder: (context, i) => _thumb(theme, scheme, i),
        ),
      ),
      const SizedBox(height: 12),
      // Segmented control (3a): decides stacked-multi-shot vs batch.
      Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          children: [
            _segment(theme, scheme,
                key: const Key('batch-one-recipe'),
                label: 'One recipe · $n shots',
                value: false),
            _segment(theme, scheme,
                key: const Key('batch-separate'),
                label: '$n separate recipes',
                value: true),
          ],
        ),
      ),
      const SizedBox(height: 16),
      FilledButton(
        key: const Key('import-rescue-cta'),
        onPressed: () => Navigator.pop(
            context, ImportPicked(_picked, separate: _separate)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_separate ? 'Rescue $n recipes' : 'Rescue as one recipe'),
            const SizedBox(width: 6),
            const Icon(Icons.arrow_forward_rounded, size: 18),
          ],
        ),
      ),
    ];
  }

  Widget _thumb(ThemeData theme, ColorScheme scheme, int i) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: scheme.primary, width: 2),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CoverImage(_picked[i]),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: Container(
              width: 20,
              height: 20,
              alignment: Alignment.center,
              decoration:
                  BoxDecoration(color: scheme.primary, shape: BoxShape.circle),
              child: Text('${i + 1}',
                  style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: scheme.onPrimary)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _segment(
    ThemeData theme,
    ColorScheme scheme, {
    required Key key,
    required String label,
    required bool value,
  }) {
    final selected = _separate == value;
    return Expanded(
      child: InkWell(
        key: key,
        borderRadius: BorderRadius.circular(999),
        onTap: () => setState(() => _separate = value),
        child: Container(
          height: 38,
          alignment: Alignment.center,
          decoration: selected
              ? BoxDecoration(
                  color: scheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: context.rb.cardShadow,
                )
              : null,
          child: Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: selected ? scheme.primary : scheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
