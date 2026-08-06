// Storage — 6e (turn 6): "manage state", superseding the 3h post-setup
// presentation (3h remains the conceptual setup flow; this single screen now
// follows 6e). Live over StorageModel; every state line is truthful (turn-5
// honesty rule: never 'synced' when nothing synced). Card copy verbatim from
// the mock: This phone ('<folder> · N recipes' + 'Change folder'), the
// connected provider ('MyReciBook/recipes · synced X ago' + 'Restore from
// <Provider>' + 'Disconnect' → the 6f dialog), the unconnected provider
// (dimmed 'awaiting keys in this build' on placeholder creds, waking to
// Connect when real keys land), and the dashed leave-anytime promise.
//
// Restore snackbar counts FILES, not recipes: the engine's unit is files
// (a recipe = json + images), so 'N recipes' would overcount — dishonest.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/remote_store.dart';
import '../data/saf_store.dart' show GrantLostException;
import '../data/sync_engine.dart';
import 'library_model.dart';
import 'storage_model.dart';
import 'theme.dart';
import 'widgets/skin.dart';

class StorageScreen extends StatelessWidget {
  const StorageScreen(
      {super.key, this.folderName, this.onChangeFolder, this.onRestored});

  /// Display name of the picked recipes folder (This-phone card).
  final String? folderName;

  /// Deliberate folder change — the existing BootGate re-pick flow.
  final VoidCallback? onChangeFolder;

  /// Fired after a successful restore so the library rescans.
  final VoidCallback? onRestored;

  Future<void> _restore(
      BuildContext context, StorageModel model, String provider) async {
    final display = model.displayName(provider);
    // The existing restore confirm — kept by 6e ("existing restore w/ confirm
    // + count snackbar"). Additive, not destructive: not a 6f dialog.
    final ok = await showDialog<bool>(
      context: context,
      builder: (dctx) => AlertDialog(
        title: Text('Restore from $display?'),
        content: Text('Recipes in your $display folder that aren\'t in your '
            'phone folder are copied back. Nothing is overwritten.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(dctx, true),
              child: const Text('Restore')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final n = await model.restore();
      onRestored?.call();
      messenger.showSnackBar(SnackBar(
          content: Text(n == 0
              ? 'Nothing to restore — your folder already has everything.'
              : 'Restored $n file${n == 1 ? '' : 's'} from $display')));
    } on AuthRevokedException {
      messenger.showSnackBar(
          SnackBar(content: Text('Access expired — reconnect to $display')));
    } on SyncIoException {
      messenger.showSnackBar(
          SnackBar(content: Text("Couldn't reach $display — try again later")));
    } on GrantLostException {
      // The gate re-entry unmounts this screen; the re-pick flow owns it.
    }
  }

  // 6f — the canonical destructive confirm: what SURVIVES (both copies)
  // before what STOPS, then the verb repeated on the filled error button.
  Future<void> _disconnect(BuildContext context, StorageModel model) async {
    final provider = model.active;
    if (provider == null) return;
    final ok = await showDestructiveConfirm(
      context,
      title: 'Disconnect ${model.displayName(provider)}?',
      body: 'Nothing is deleted. Your recipes stay in your '
          '${model.shortName(provider)} folder and in the copy on this phone '
          '— they just stop syncing.',
      verb: 'Disconnect',
    );
    if (ok) await model.disconnect();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = context.scheme;
    final model = context.watch<StorageModel>();
    final recipeCount = context.watch<LibraryModel>().recipes.length;

    Widget card({
      required IconData icon,
      required String title,
      required List<Widget> captions,
      Widget? trailing,
      Widget? secondary,
      bool dimmed = false,
    }) {
      final body = TokenCard(
        padding: const EdgeInsets.all(13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                    color: scheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(12)),
                child:
                    Icon(icon, size: 21, color: scheme.onSurfaceVariant),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontSize: 14.5)),
                      const SizedBox(height: 2),
                      ...captions,
                    ]),
              ),
              ?trailing,
            ]),
            ?secondary,
          ],
        ),
      );
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: dimmed ? Opacity(opacity: 0.55, child: body) : body,
      );
    }

    Text caption(String text) => Text(text,
        style:
            theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant));

    Widget smallButton(String label, {VoidCallback? onPressed}) =>
        OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
              minimumSize: const Size(82, 36),
              padding: const EdgeInsets.symmetric(horizontal: 14)),
          child: Text(label),
        );

    Widget providerCard(String provider) {
      final display = model.displayName(provider);
      final connected = model.active == provider;
      // Dimmed on placeholder credentials (6e) — the honest awaiting state,
      // shown up front rather than after a doomed Connect tap.
      final awaitingKeys = !model.configured(provider);
      final error = model.connectErrorFor(provider);

      if (connected) {
        final revoked = model.status.state == SyncState.authRevoked;
        return card(
          icon: Icons.cloud_rounded,
          title: display,
          captions: [caption(model.statusLine(provider)!)],
          secondary: Align(
            alignment: Alignment.centerRight,
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              TextButton(
                  onPressed: () => _disconnect(context, model),
                  child: const Text('Disconnect')),
              const SizedBox(width: 8),
              revoked
                  ? smallButton('Reconnect',
                      onPressed: () => model.connect(provider))
                  : smallButton('Restore from $display',
                      onPressed: () => _restore(context, model, provider)),
            ]),
          ),
        );
      }
      return card(
        icon: Icons.cloud_rounded,
        title: display,
        dimmed: awaitingKeys,
        captions: [
          if (awaitingKeys) caption('awaiting keys in this build'),
          if (error != null) caption('connect didn\'t finish — try again'),
        ],
        // The card wakes to Connect when real keys land — the existing
        // connect wiring, absent while credentials are placeholders.
        trailing: awaitingKeys
            ? null
            : model.connecting == provider
                ? smallButton('Connecting…')
                : smallButton('Connect',
                    onPressed: () => model.connect(provider)),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Row(children: [
              IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () => Navigator.of(context).maybePop()),
              Text('Storage', style: theme.textTheme.titleLarge),
            ]),
            const SizedBox(height: 4),
            Text('Plain files, one per recipe. Yours.',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: scheme.onSurfaceVariant)),
            const SizedBox(height: 14),
            card(
              icon: Icons.smartphone_rounded,
              title: 'This phone',
              captions: [
                caption([
                  ?folderName,
                  '$recipeCount recipe${recipeCount == 1 ? '' : 's'}',
                ].join(' · ')),
              ],
              trailing: smallButton('Change folder', onPressed: onChangeFolder),
            ),
            providerCard(StorageModel.drive),
            providerCard(StorageModel.dropbox),
            const DashedInfoCard(
                text: 'Move, export or leave anytime. If MyReciBook vanished '
                    'tomorrow, your recipes wouldn\'t.'),
          ],
        ),
      ),
    );
  }
}
