// Structural validation — mirrors the spike harness auto_checks plus the
// schema's required list. No jsonschema dependency on purpose (D1 keeps the
// format simple enough to check by hand).
//
// Never save a file that doesn't validate (architecture §7).

/// Problems in raw model output (content subset — no envelope fields yet).
List<String> contentProblems(Map<String, dynamic> content) {
  final problems = <String>[];
  final title = content['title'];
  if (title is! String || title.isEmpty) problems.add('empty title');

  final ings = content['ingredients'];
  if (ings is! List || ings.length < 2) {
    problems.add('only ${ings is List ? ings.length : 0} ingredients');
  } else {
    for (var i = 0; i < ings.length; i++) {
      final ing = ings[i];
      if (ing is! Map || ing['raw'] is! String || (ing['raw'] as String).isEmpty) {
        problems.add('ingredients[$i] no raw');
      }
    }
  }

  final steps = content['steps'];
  if (steps is List) {
    for (var i = 0; i < steps.length; i++) {
      final st = steps[i];
      if (st is! Map || st['raw'] is! String || (st['raw'] as String).isEmpty) {
        problems.add('steps[$i] no raw');
      }
    }
    if (steps.isEmpty) problems.add('no steps');
  } else {
    problems.add('no steps');
  }
  return problems;
}

/// Problems in a complete recipe file (envelope + content).
List<String> fileProblems(Map<String, dynamic> json) {
  final problems = <String>[];
  for (final field in ['schema_version', 'id', 'title', 'source', 'ingredients', 'steps']) {
    if (!json.containsKey(field) || json[field] == null) {
      problems.add('missing:$field');
    }
  }
  if (json['schema_version'] != null && json['schema_version'] != 1) {
    problems.add('unknown schema_version ${json['schema_version']}');
  }
  problems.addAll(contentProblems(json));
  return problems;
}

/// "No steps" is expected for incomplete captures (D4: ask for another
/// screenshot, never invent) — it blocks nothing, but must reach the review UI.
bool isSaveBlocking(String problem) =>
    problem != 'no steps' && !problem.startsWith('only ');
