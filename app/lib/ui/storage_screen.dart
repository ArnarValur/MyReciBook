// Storage screen — the promoted 3h preview ("Storage setup — your files, not
// ours"), live over StorageModel. Designed copy verbatim; every state line is
// truthful (turn-5 honesty rule: never 'synced' when nothing synced).
//
// DEVIATIONS from the 3h mockup, for design to ratify:
// - 'Change folder' + the current folder name on the This-phone card: the
//   drawer Storage row now routes here, so the existing re-pick flow needs a
//   door. Undesigned control.
// - 'Restore from …' as the connected card's secondary action: 3h has no
//   restore affordance (5a reaches it via reconnect); placed per task spec.
// - 'awaiting keys in this build' caption: honest placeholder-credentials
//   state, undesigned copy.
// - Restore snackbar counts FILES, not recipes: the engine's unit is files
//   (a recipe = json + images), so 'N recipes' would overcount — dishonest.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/remote_store.dart';
import '../data/saf_store.dart' show GrantLostException;
import '../data/sync_engine.dart';
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
    // Confirm copy undesigned — flagged in the header DEVIATIONS.
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = context.scheme;
    final model = context.watch<StorageModel>();

    Widget option({
      required IconData icon,
      required String title,
      required List<Widget> captions,
      required Widget trailing,
      bool selected = false,
      Widget? secondary,
    }) =>
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TokenCard(
            selected: selected,
            padding: const EdgeInsets.all(13),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                        color: selected
                            ? scheme.secondaryContainer
                            : scheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(12)),
                    child: Icon(icon,
                        size: 21,
                        color: selected
                            ? scheme.onSecondaryContainer
                            : scheme.onSurfaceVariant),
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
                  trailing,
                ]),
                ?secondary,
              ],
            ),
          ),
        );

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

    Widget providerCard({
      required String provider,
      required IconData icon,
      required String designedCaption,
    }) {
      final connected = model.active == provider;
      final revoked =
          connected && model.status.state == SyncState.authRevoked;
      final error = model.connectErrorFor(provider);

      final Widget trailing;
      if (connected) {
        trailing = revoked
            ? smallButton('Reconnect', onPressed: () => model.connect(provider))
            : smallButton('Disconnect', onPressed: model.disconnect);
      } else if (model.connecting == provider) {
        trailing = smallButton('Connecting…');
      } else {
        trailing =
            smallButton('Connect', onPressed: () => model.connect(provider));
      }

      return option(
        icon: icon,
        title: model.displayName(provider),
        selected: connected,
        captions: [
          if (connected)
            caption(model.statusLine(provider)!)
          else ...[
            caption(designedCaption),
            if (model.notConfigured == provider)
              caption('awaiting keys in this build'),
            if (error != null) caption('connect didn\'t finish — try again'),
          ],
        ],
        trailing: trailing,
        secondary: connected
            ? Align(
                alignment: Alignment.centerRight,
                child: revoked
                    ? TextButton(
                        onPressed: model.disconnect,
                        child: const Text('Disconnect'))
                    : TextButton(
                        onPressed: () => _restore(context, model, provider),
                        child:
                            Text('Restore from ${model.displayName(provider)}')),
              )
            : null,
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
            Text('Where should your recipes live?',
                style: theme.textTheme.headlineSmall?.copyWith(height: 1.25)),
            const SizedBox(height: 5),
            Text('Plain files, one per recipe. Yours.',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: scheme.onSurfaceVariant)),
            const SizedBox(height: 14),
            option(
              icon: Icons.smartphone_rounded,
              title: 'This phone',
              selected: model.active == null,
              captions: [
                caption('zero setup · works offline'),
                if (folderName != null) caption(folderName!),
              ],
              trailing: model.active == null
                  ? Icon(Icons.check_circle_rounded,
                      size: 22, color: scheme.primary)
                  : const SizedBox.shrink(),
              secondary: onChangeFolder == null
                  ? null
                  : Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                          onPressed: onChangeFolder,
                          child: const Text('Change folder')),
                    ),
            ),
            providerCard(
              provider: StorageModel.drive,
              icon: Icons.add_to_drive_rounded,
              designedCaption: "app folder only — we can't see the rest",
            ),
            providerCard(
              provider: StorageModel.dropbox,
              icon: Icons.cloud_rounded,
              designedCaption: 'app folder only',
            ),
            const SectionLabel('What a recipe looks like on disk'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                  color: scheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(12)),
              child: DefaultTextStyle(
                style: const TextStyle(
                    fontFamily: 'monospace', fontSize: 11.5, height: 1.65),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('MyReciBook/recipes/creamy-garlic-pasta.json',
                          style: TextStyle(
                              color: scheme.primary,
                              fontWeight: FontWeight.w600)),
                      Text('{ "title": "Creamy garlic pasta",',
                          style: TextStyle(color: scheme.onSurfaceVariant)),
                      Text('  "servings": 4, "ingredients": [ … ] }',
                          style: TextStyle(color: scheme.onSurfaceVariant)),
                    ]),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
              decoration: BoxDecoration(
                border: Border.all(color: scheme.outline.withValues(alpha: 0.6)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                  'Move, export or leave anytime. If MyReciBook vanished '
                  'tomorrow, your recipes wouldn\'t.',
                  style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 12.5,
                      height: 1.5,
                      color: scheme.onSurfaceVariant)),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Text('Continue'),
              label: const Icon(Icons.arrow_forward_rounded, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}
