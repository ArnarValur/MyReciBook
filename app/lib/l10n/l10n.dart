// The one import a screen needs: `import '../l10n/l10n.dart';` then
// `context.l10n.settingsTitle`. Keeps the generated-file path out of 90 files,
// so moving or renaming the output touches exactly one line.

import 'package:flutter/widgets.dart';

import 'generated/app_localizations.dart';

export 'generated/app_localizations.dart' show AppLocalizations;

extension L10nContext on BuildContext {
  /// Non-null by construction: nullable-getter is off in l10n.yaml and the
  /// delegates are installed on both MaterialApps, so a missing lookup is a
  /// wiring bug that fails loudly instead of rendering blank.
  AppLocalizations get l10n => AppLocalizations.of(this);
}
