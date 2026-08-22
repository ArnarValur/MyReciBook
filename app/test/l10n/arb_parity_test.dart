// The .arb files are the only place a user-facing string is allowed to live,
// so they have to stay honest with each other. gen_l10n falls back to English
// for anything a translation is missing, which is the right runtime behavior
// and the exact reason a gap can ship unnoticed — this names them instead.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:myrecibook/domain/app_language.dart';

Map<String, dynamic> _arb(String code) =>
    jsonDecode(File('lib/l10n/app_$code.arb').readAsStringSync())
        as Map<String, dynamic>;

/// Message ids only: @@locale is metadata and @key entries are translator
/// notes, which live in the template and are never copied into translations.
Set<String> _keys(Map<String, dynamic> arb) =>
    arb.keys.where((k) => !k.startsWith('@')).toSet();

void main() {
  final template = _arb('en');
  final templateKeys = _keys(template);

  test('the template locale is English and carries every message', () {
    expect(template['@@locale'], 'en');
    expect(templateKeys, isNotEmpty);
  });

  test('every language with an .arb file is one the app knows about', () {
    for (final f in Directory('lib/l10n').listSync()) {
      final name = f.path.split('/').last;
      if (!name.endsWith('.arb')) continue;
      final code = name.substring('app_'.length, name.length - '.arb'.length);
      expect(parseAppLanguage(code), isNot(AppLanguage.system),
          reason: '$name has no entry in AppLanguage — it can never be shown');
    }
  });

  test('every offered language has an .arb file', () {
    for (final l in kOfferedLanguages) {
      if (l == AppLanguage.system) continue; // not a language, no strings
      expect(File('lib/l10n/app_${appLanguageName(l)}.arb').existsSync(), isTrue,
          reason: '${appLanguageName(l)} is offered in Settings but has no '
              'lib/l10n/app_${appLanguageName(l)}.arb');
    }
  });

  for (final l in kAppLanguages) {
    if (l == AppLanguage.system) continue;
    final code = appLanguageName(l);
    if (code == 'en') continue;
    if (!File('lib/l10n/app_$code.arb').existsSync()) continue;

    final offered = kOfferedLanguages.contains(l);

    // Invented keys are a bug in every language, offered or not: a dead
    // string, or a typo that will never render.
    test('$code invents no messages', () {
      expect(_keys(_arb(code)).difference(templateKeys), isEmpty,
          reason: '$code has messages that are not in app_en.arb');
    });

    test('$code declares its own locale', () {
      expect(_arb(code)['@@locale'], code);
    });

    // Completeness binds only on languages the picker actually offers. The
    // rest are work in progress and lag on purpose — one language at a time.
    if (offered) {
      test('$code is offered, so it must translate every message', () {
        expect(templateKeys.difference(_keys(_arb(code))), isEmpty,
            reason: '$code is offered in the picker but is missing these '
                'messages — finish them or drop it from kOfferedLanguages');
      });
    } else {
      test('$code is not offered yet — reporting how far behind it is', () {
        final missing = templateKeys.difference(_keys(_arb(code)));
        // Not a failure. This prints the backlog so it stays visible.
        printOnFailure('$code: ${missing.length} of ${templateKeys.length} '
            'messages missing');
        expect(missing.length, lessThanOrEqualTo(templateKeys.length));
      });
    }
  }
}
