/// The ICU MessageFormat emitter (`irspecs_ir.md` §10.1): the text catalogue
/// (CE-TX) as one JSON object, each message key to its base copy written as an
/// ICU message — and the parser that checks the result, since ICU MessageFormat
/// has no meta-schema to validate against.
library;

import '../ir_model.dart';
import 'emit_common.dart';

/// The file the ICU emitter writes.
const String kIcuFile = 'messages.json';

/// Emits [documents]' text catalogue as `messages.json`: `{key: message}` in
/// catalogue order, each `@CsText` base copy rendered by [icuMessageFor].
IrEmission emitIcu(List<IrDocument> documents) {
  final index = IrIndex(documents);
  final notExpressed = <String>[];
  final messages = <String, String>{};
  var withRole = 0;
  for (final e in index.inArea('CE-TX')) {
    for (final m in index.membersOf(e)) {
      final text = irMarker(m, 'CsText');
      if (text == null) continue;
      final key = irInitialiserString(m);
      final copy = irString(text.named['baseCopy']);
      if (key == null || copy == null) {
        notExpressed.add(
          'CE-TX ${e.declaration.name}.${m.name}: no key or base copy',
        );
        continue;
      }
      messages[key] = icuMessageFor(copy);
      if (text.named.containsKey('role') ||
          text.named.containsKey('category')) {
        withRole++;
      }
    }
  }
  if (messages.isNotEmpty) {
    notExpressed.add(
      'CE-TX: the locale of the base copy, each message\'s doc comment'
      '${withRole == 0 ? '' : ', and the role and category of $withRole message(s)'}'
      ' (a catalogue holds key and message only)',
    );
  }
  return IrEmission({kIcuFile: irJson(messages)}, notExpressed);
}

/// The ICU message for a `@CsText` base copy (`codespecs_mapping.md` §5.21):
/// a `{name}` placeholder stays an ICU argument; every other brace and every
/// apostrophe is quoted, so the copy reads exactly as written.
String icuMessageFor(String baseCopy) {
  final b = StringBuffer();
  final placeholder = RegExp(r'\{([A-Za-z_][A-Za-z0-9_]*)\}');
  var i = 0;
  while (i < baseCopy.length) {
    final m = placeholder.matchAsPrefix(baseCopy, i);
    if (m != null) {
      b.write(m.group(0));
      i = m.end;
      continue;
    }
    final c = baseCopy[i];
    b.write(switch (c) {
      "'" => "''",
      '{' => "'{'",
      '}' => "'}'",
      _ => c,
    });
    i++;
  }
  return b.toString();
}

/// The syntax errors of [message] as an ICU MessageFormat pattern (the ICU
/// User Guide's MessageFormat syntax, apostrophe mode DOUBLE_OPTIONAL); empty
/// when it parses. Arguments are `{name}`, `{name, type}`, `{name, type,
/// style}` with type `number`, `date`, `time`, `spellout`, `ordinal` or
/// `duration`, and the complex `plural`, `selectordinal` and `select`, whose
/// cases are messages and which need an `other` case.
List<String> icuSyntaxErrors(String message) {
  final p = _IcuParser(message);
  try {
    p.message(inPlural: false, nested: false);
    if (p.i != message.length) {
      p.fail('unexpected `${message[p.i]}`');
    }
  } on _IcuSyntaxError catch (e) {
    return [e.message];
  }
  return const [];
}

class _IcuSyntaxError implements Exception {
  final String message;
  const _IcuSyntaxError(this.message);
}

class _IcuParser {
  final String s;
  int i = 0;
  _IcuParser(this.s);

  Never fail(String what) => throw _IcuSyntaxError('at $i: $what');

  bool get atEnd => i >= s.length;

  void skipSpace() {
    while (!atEnd && s[i].trim().isEmpty) {
      i++;
    }
  }

  /// A message: literal text, quoted text and arguments, up to a closing `}`
  /// when [nested].
  void message({required bool inPlural, required bool nested}) {
    while (!atEnd) {
      final c = s[i];
      if (c == "'") {
        quoted(inPlural: inPlural);
      } else if (c == '{') {
        argument();
      } else if (c == '}') {
        if (nested) return;
        fail('unmatched `}`');
      } else {
        i++;
      }
    }
    if (nested) fail('unclosed `{`');
  }

  /// An apostrophe: `''` is one; before `{`, `}`, `|` (and `#` in a plural
  /// case) it opens a quoted literal that the next lone apostrophe closes;
  /// otherwise it is a literal apostrophe.
  void quoted({required bool inPlural}) {
    if (i + 1 < s.length && s[i + 1] == "'") {
      i += 2;
      return;
    }
    final next = i + 1 < s.length ? s[i + 1] : '';
    if (next == '{' ||
        next == '}' ||
        next == '|' ||
        (inPlural && next == '#')) {
      i++;
      while (true) {
        if (atEnd) fail('unclosed quoted literal');
        if (s[i] == "'") {
          if (i + 1 < s.length && s[i + 1] == "'") {
            i += 2;
            continue;
          }
          i++;
          return;
        }
        i++;
      }
    }
    i++;
  }

  String name() {
    final m = RegExp(r'[A-Za-z0-9_]+').matchAsPrefix(s, i);
    if (m == null) fail('expected an argument name');
    i = m.end;
    return m.group(0)!;
  }

  void expect(String c) {
    if (atEnd) fail('unclosed: expected `$c` before the end');
    if (s[i] != c) fail('expected `$c`');
    i++;
  }

  static const _simpleTypes = {
    'number',
    'date',
    'time',
    'spellout',
    'ordinal',
    'duration',
  };

  void argument() {
    expect('{');
    skipSpace();
    name();
    skipSpace();
    if (!atEnd && s[i] == '}') {
      i++;
      return;
    }
    expect(',');
    skipSpace();
    final type = name();
    skipSpace();
    if (type == 'plural' || type == 'selectordinal' || type == 'select') {
      expect(',');
      complex(plural: type != 'select');
      return;
    }
    if (!_simpleTypes.contains(type)) fail('unknown argument type `$type`');
    if (!atEnd && s[i] == '}') {
      i++;
      return;
    }
    expect(',');
    // The style runs to the matching `}`; it may hold quoted text.
    var depth = 0;
    while (true) {
      if (atEnd) fail('unclosed argument style');
      final c = s[i];
      if (c == "'") {
        quoted(inPlural: false);
        continue;
      }
      if (c == '{') depth++;
      if (c == '}') {
        if (depth == 0) {
          i++;
          return;
        }
        depth--;
      }
      i++;
    }
  }

  void complex({required bool plural}) {
    skipSpace();
    if (plural && s.startsWith('offset:', i)) {
      i += 'offset:'.length;
      skipSpace();
      final m = RegExp(r'\d+').matchAsPrefix(s, i);
      if (m == null) fail('expected an offset');
      i = m.end;
    }
    final selectors = <String>{};
    while (true) {
      skipSpace();
      if (atEnd) fail('unclosed argument');
      if (s[i] == '}') {
        i++;
        break;
      }
      final selector = plural && s[i] == '='
          ? () {
              i++;
              final m = RegExp(r'-?\d+(\.\d+)?').matchAsPrefix(s, i);
              if (m == null) fail('expected a number after `=`');
              i = m.end;
              return '=${m.group(0)}';
            }()
          : name();
      if (!selectors.add(selector)) fail('selector `$selector` twice');
      skipSpace();
      expect('{');
      message(inPlural: plural, nested: true);
      expect('}');
    }
    if (!selectors.contains('other')) fail('no `other` case');
  }
}
