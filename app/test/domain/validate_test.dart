// Validator cases mirror the spike harness auto_checks (T3 step 2).

import 'package:flutter_test/flutter_test.dart';
import 'package:myrecibook/domain/validate.dart';

Map<String, dynamic> validContent() => {
      'title': 'Pancakes',
      'ingredients': <Map<String, dynamic>>[
        {'raw': '2 eggs'},
        {'raw': '250 g flour'},
      ],
      'steps': <Map<String, dynamic>>[
        {'raw': 'Mix.'},
        {'raw': 'Fry.'},
      ],
    };

void main() {
  group('contentProblems', () {
    test('happy path is clean', () {
      expect(contentProblems(validContent()), isEmpty);
    });

    test('empty title', () {
      expect(contentProblems(validContent()..['title'] = ''),
          contains('empty title'));
    });

    test('missing title', () {
      expect(contentProblems(validContent()..remove('title')),
          contains('empty title'));
    });

    test('non-string title', () {
      expect(contentProblems(validContent()..['title'] = 42),
          contains('empty title'));
    });

    test('zero ingredients', () {
      expect(contentProblems(validContent()..['ingredients'] = <Object?>[]),
          contains('only 0 ingredients'));
    });

    test('one ingredient', () {
      expect(
          contentProblems(validContent()
            ..['ingredients'] = [
              {'raw': '2 eggs'}
            ]),
          contains('only 1 ingredients'));
    });

    test('missing ingredients counts as 0', () {
      expect(contentProblems(validContent()..remove('ingredients')),
          contains('only 0 ingredients'));
    });

    test('ingredient without raw', () {
      final content = validContent();
      (content['ingredients'] as List)[1] = {'item': 'flour'};
      expect(contentProblems(content), contains('ingredients[1] no raw'));
    });

    test('ingredient with empty raw', () {
      final content = validContent();
      (content['ingredients'] as List)[0] = {'raw': ''};
      expect(contentProblems(content), contains('ingredients[0] no raw'));
    });

    test('steps present but empty', () {
      expect(contentProblems(validContent()..['steps'] = <Object?>[]),
          contains('no steps'));
    });

    test('steps missing', () {
      expect(
          contentProblems(validContent()..remove('steps')), contains('no steps'));
    });

    test('step without raw', () {
      final content = validContent();
      (content['steps'] as List)[0] = {'confidence': 0.5};
      expect(contentProblems(content), contains('steps[0] no raw'));
    });
  });

  group('fileProblems', () {
    Map<String, dynamic> validFile() => validContent()
      ..addAll({
        'schema_version': 1,
        'id': 'abc-123',
        'source': {'type': 'screenshot'},
      });

    test('valid file is clean', () {
      expect(fileProblems(validFile()), isEmpty);
    });

    for (final field in [
      'schema_version',
      'id',
      'title',
      'source',
      'ingredients',
      'steps',
    ]) {
      test('absent $field', () {
        expect(fileProblems(validFile()..remove(field)),
            contains('missing:$field'));
      });

      test('null $field flags the same as absent', () {
        expect(fileProblems(validFile()..[field] = null),
            contains('missing:$field'));
      });
    }

    test('schema_version 2 is unknown', () {
      final problems = fileProblems(validFile()..['schema_version'] = 2);
      expect(problems, contains('unknown schema_version 2'));
      expect(problems, isNot(contains('missing:schema_version')));
    });
  });

  group('isSaveBlocking', () {
    test('no steps is non-blocking (D4/D5 retake flow)', () {
      expect(isSaveBlocking('no steps'), isFalse);
    });

    test('only N ingredients is non-blocking', () {
      expect(isSaveBlocking('only 0 ingredients'), isFalse);
      expect(isSaveBlocking('only 1 ingredients'), isFalse);
    });

    test('everything else blocks', () {
      for (final p in [
        'empty title',
        'ingredients[0] no raw',
        'steps[2] no raw',
        'missing:id',
        'missing:schema_version',
        'unknown schema_version 2',
      ]) {
        expect(isSaveBlocking(p), isTrue, reason: p);
      }
    });
  });
}
