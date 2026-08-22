// Language picker. Eleven languages plus System no longer fit the segmented
// pill the Theme and Units controls use, so this follows the pushed-screen
// shape the Storage row already established: back arrow, title, one card per
// choice, a check on the active one.
//
// The list is drawn in ENDONYMS — every language names itself, in its own
// alphabet. Someone who lands in the wrong language by accident can still
// read their way out, which a list translated into the current language
// would not allow. "System" is the one exception: it is a word, not a
// language, so it is translated like everything else.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../domain/app_language.dart';
import '../l10n/l10n.dart';
import 'language_model.dart';
import 'theme.dart';
import 'widgets/skin.dart';

class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = context.scheme;
    final model = context.watch<LanguageModel>();

    Widget choice(AppLanguage l) {
      final selected = model.language == l;
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => model.setLanguage(l),
          child: TokenCard(
            padding: const EdgeInsets.fromLTRB(14, 13, 13, 13),
            child: Row(children: [
              Expanded(
                child: Text(
                    l == AppLanguage.system
                        ? context.l10n.languageSystem
                        : appLanguageEndonym(l),
                    style: theme.textTheme.titleSmall?.copyWith(
                        fontSize: 14.5,
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.w500)),
              ),
              if (selected)
                Icon(Icons.check_rounded, size: 20, color: scheme.onSurface),
            ]),
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Row(children: [
              const AppBackButton(),
              Text(context.l10n.sectionLanguage,
                  style: theme.textTheme.titleLarge),
            ]),
            const SizedBox(height: 16),
            for (final l in kOfferedLanguages) choice(l),
          ],
        ),
      ),
    );
  }
}
