// Exercise-sample generator (SOM §19).
//
// Emits `samples/exercise_full_model.docspecs.yaml`: a specialized exercise
// specification whose sole purpose is to instantiate every model structure
// reachable from the `D00SolutionBlueprint` root — the remainder that the
// narrative samples (Meridian, the UAM access hub) do not plausibly reach.
// Together with them it drives `tool/sample_coverage_manifest.yaml` to empty,
// which is full instantiation coverage under the sample-coverage gate
// (`tool/check_sample_coverage.dart`).
//
// The walk mirrors the gate's (same meta, same root, same kind switch), and
// the emission mirrors the hierarchical format v2 the Dart codec writes (SOM
// §12). The document must pass all three tiers — decode, the DocSpecs schema
// over its rendition, and the instance tier — which the conformance driver
// checks (`sample_decode`, `sample_schema`, `sample_validate`):
//
//   * every field with a `sectionId` emits its `<ID> <name>:` key once per
//     class body; `section`/`complex` fields without a field id fall back to
//     the target class's id. A class's body is emitted at its first encounter
//     (the visited set); a revisit emits the key with a null value;
//   * a list emits `@Min` items (at least one), each keyed by the list's
//     `@SectionIdPattern` with `xxx` as the position (`RVENT-REVS-1`) — the id
//     a document gives an item and the one the codec writes itself — and each
//     with a full body, so a revisited element still carries what the schema
//     requires of it; `onPath` stops a list that holds its own element type;
//   * a `@Reference` list owns nothing, so its one item is the id of an
//     element instance declared elsewhere, with an empty body;
//   * a diagram or code `contentType` gets a fenced block, which the schema
//     demands; other text is one line of prose;
//   * a form emits its `content` preamble plus every required field: an enum
//     takes its first constant, `bool`/`int` a literal, a `refersTo` field the
//     id or value the sample declares for its target, and every field some
//     `refersTo` names is filled so the reference resolves;
//   * a `@OneOf` container whose discriminator is required emits one case per
//     instance — a list one item per case, a single container the next case
//     at each encounter — so every case subsection is still instantiated;
//   * the document is emitted twice and the first pass discarded: it records
//     the id of each class's first instance, which `CLS.@sectionId`
//     references name.
//
// This file is generated content by design: re-run after model changes,
// commit the diff. Like its neighbours the tool is dependency-free.
//
// Usage: dart tool/build_exercise_sample.dart [confDir]
//   confDir defaults to this script's parent (tom_som_conformance).
library;

import 'dart:convert';
import 'dart:io';

const _root = 'D00SolutionBlueprint';

void main(List<String> args) {
  final confDir = args.isNotEmpty
      ? args.first
      : Directory(File(Platform.script.toFilePath()).parent.path).parent.path;
  final metaFile = File(
    '${Directory(confDir).parent.path}/tom_som_dart_v0/meta/spec_model.meta.json',
  );
  final outFile = File('$confDir/samples/exercise_full_model.docspecs.yaml');

  if (!metaFile.existsSync()) {
    stderr.writeln('model meta missing: ${metaFile.path}');
    exit(1);
  }

  final meta = jsonDecode(metaFile.readAsStringSync()) as Map<String, dynamic>;
  final classes = meta['classes'] as Map<String, dynamic>;
  final rootClass = classes[_root] as Map<String, dynamic>?;
  if (rootClass == null) {
    stderr.writeln('root class $_root missing from ${metaFile.path}');
    exit(1);
  }

  final b = StringBuffer()
    ..writeln('# TomSpecs document (*.docspecs.yaml). Hierarchical format v2.')
    ..writeln('#')
    ..writeln(
      '# GENERATED exercise sample — instantiates every model structure',
    )
    ..writeln('# reachable from the D00SolutionBlueprint root, for the sample')
    ..writeln('# instantiation-coverage gate (SOM §19). Not a narrative')
    ..writeln('# specification: every value is placeholder prose.')
    ..writeln('# Regenerate with: dart tool/build_exercise_sample.dart')
    ..writeln('version: 2')
    ..writeln('modelVersion: "1.0"')
    ..writeln('document:');

  // Every `refersTo` target the model declares: `CLS.field` (the value of a
  // form field of a CLS instance) or `CLS.@sectionId` (the id of a CLS
  // instance). The emission fills each target field with a fixed value and
  // records each instance id, and every referring field then names one of
  // those — so a required reference resolves instead of dangling.
  var classBodies = 0;
  var keysEmitted = 0;
  final refTargetFields = <String>{};
  for (final c in classes.values) {
    for (final f in ((c as Map<String, dynamic>)['fields'] as List<dynamic>)) {
      for (final ff
          in ((f as Map<String, dynamic>)['formFields'] as List<dynamic>? ??
              const [])) {
        for (final r
            in ((ff as Map<String, dynamic>)['refersTo'] as List<dynamic>? ??
                const [])) {
          if (!(r as String).endsWith('.@sectionId')) refTargetFields.add(r);
        }
      }
    }
  }

  // Filled by a first, discarded emission: the id of the first instance of
  // each class id, which a `CLS.@sectionId` reference names.
  final instanceIds = <String, String>{};

  String emitDocument() {
    final out = StringBuffer();
    final visited = <String>{};
    final onPath = <String>{};
    // For a `@OneOf` container whose discriminator is required, the cases
    // not yet emitted. Each instance selects the next one, so every case
    // subsection is still instantiated somewhere (a list emits one item per
    // case; a single container takes the next case at each encounter).
    final pendingCases = <String, List<String>>{};
    classBodies = 0;
    keysEmitted = 0;

    String refValue(String target) {
      if (target.endsWith('.@sectionId')) {
        final cls = target.substring(0, target.length - '.@sectionId'.length);
        return instanceIds[cls] ?? cls;
      }
      return 'exercise-${target.replaceAll('.', '-').toLowerCase()}';
    }

    String formValue(
      String? classId,
      Map<String, dynamic> ff, {
      String? chosen,
    }) {
      if (chosen != null) return chosen;
      final refs = (ff['refersTo'] as List<dynamic>?)?.cast<String>();
      if (refs != null && refs.isNotEmpty) return refValue(refs.first);
      final enums = (ff['enumValues'] as List<dynamic>?)?.cast<String>();
      if (enums != null && enums.isNotEmpty) return enums.first;
      switch (ff['type']) {
        case 'bool':
          return 'true';
        case 'int':
          return '1';
      }
      if (classId != null &&
          refTargetFields.contains('$classId.${ff['name']}')) {
        return refValue('$classId.${ff['name']}');
      }
      return 'Exercise value.';
    }

    /// The `@OneOf` discriminator of [cls] when it is required, else null.
    Map<String, dynamic>? requiredOneOf(Map<String, dynamic> cls) {
      for (final a in (cls['annotations'] as List<dynamic>? ?? const [])) {
        final ann = a as Map<String, dynamic>;
        if (ann['name'] != 'OneOf') continue;
        final d = (ann['arguments'] as Map<String, dynamic>)['discriminator'];
        for (final f in cls['fields'] as List<dynamic>) {
          for (final ff
              in ((f as Map<String, dynamic>)['formFields'] as List<dynamic>? ??
                  const [])) {
            final m = ff as Map<String, dynamic>;
            if (m['name'] == d && m['required'] == true) return m;
          }
        }
      }
      return null;
    }

    List<String> caseValues(Map<String, dynamic> field) => [
      for (final a in (field['annotations'] as List<dynamic>? ?? const []))
        if ((a as Map<String, dynamic>)['name'] == 'Case')
          ((a['arguments'] as Map<String, dynamic>)['value'] as String)
              .split('.')
              .last,
    ];

    /// The cases [type] binds a subsection to, in field order.
    List<String> casesOf(String type) {
      final cls = classes[type] as Map<String, dynamic>;
      return [
        for (final f in cls['fields'] as List<dynamic>)
          if (caseValues(f as Map<String, dynamic>).isNotEmpty)
            caseValues(f).first,
      ];
    }

    /// Emits a block scalar holding [lines] at [pad].
    void block(String pad, String key, List<String> lines) {
      out.writeln('$pad$key: |-');
      for (final l in lines) {
        out.writeln('$pad  $l');
      }
    }

    /// The body of a text field: a fenced block for a diagram or code
    /// format, which the schema demands, else one line of prose.
    void text(String pad, String key, String? contentType) {
      if (contentType != null && contentType.startsWith('mermaid')) {
        block(pad, key, ['```mermaid', 'flowchart TD', '  A --> B', '```']);
      } else if (contentType != null && contentType.startsWith('code-')) {
        block(pad, key, [
          '```${contentType.substring(5)}',
          'void main() {}',
          '```',
        ]);
      } else {
        out.writeln('$pad$key: Exercise text.');
      }
    }

    late void Function(String type, int indent, String? chosenCase) emitBody;

    /// Emits a form's preamble and its required fields.
    void emitForm(
      String pad,
      String key,
      List<dynamic> formFields,
      String? classId,
      Map<String, dynamic>? discriminator,
      String? chosenCase,
    ) {
      out
        ..writeln('$pad$key:')
        ..writeln('$pad  content: Exercise form preamble.');
      for (final f in formFields) {
        final ff = f as Map<String, dynamic>;
        final name = ff['name'] as String;
        final isDiscriminator =
            discriminator != null && discriminator['name'] == name;
        final isTarget =
            classId != null && refTargetFields.contains('$classId.$name');
        if (ff['required'] != true && !isTarget && !isDiscriminator) continue;
        final value = formValue(
          classId,
          ff,
          chosen: isDiscriminator ? chosenCase : null,
        );
        if (isDiscriminator && value.isEmpty) continue;
        out.writeln('$pad  $name: ${jsonEncode(value)}');
      }
    }

    emitBody = (String type, int indent, String? chosenCase) {
      final cls = classes[type] as Map<String, dynamic>?;
      if (cls == null) return;
      classBodies++;
      final pad = ' ' * indent;
      final classId = cls['sectionId'] as String?;
      final discriminator = requiredOneOf(cls);
      for (final f in (cls['fields'] as List<dynamic>? ?? const [])) {
        final field = f as Map<String, dynamic>;
        final name = field['name'] as String;
        final fieldId = field['sectionId'] as String?;
        final kind = field['kind'] as String;
        final cases = caseValues(field);
        if (discriminator != null &&
            cases.isNotEmpty &&
            !cases.contains(chosenCase)) {
          // A case subsection the chosen discriminator does not select.
          continue;
        }
        switch (kind) {
          case 'content':
            text(
              pad,
              fieldId == null ? name : '$fieldId $name',
              field['contentType'] as String?,
            );
            keysEmitted++;
          case 'form':
            // An id-less form is chiefly a class-level `@Form` carried on the
            // class's `content` member; the coverage gate does not count it.
            emitForm(
              pad,
              fieldId == null ? name : '$fieldId $name',
              field['formFields'] as List<dynamic>? ?? const [],
              classId,
              discriminator,
              chosenCase,
            );
            if (fieldId != null) keysEmitted++;
          case 'complex':
          case 'section':
            final target =
                (kind == 'complex' ? field['type'] : field['sectionType'])
                    as String;
            final targetCls = classes[target] as Map<String, dynamic>?;
            final targetId = targetCls?['sectionId'] as String?;
            final id = fieldId ?? targetId;
            final key = id == null ? name : '$id $name';
            keysEmitted++;
            if (targetCls == null) {
              // A wrapper section (`TextSection`, …): no exported class, its
              // text stored at its own path (SOM §11.6).
              out.writeln('$pad$key:');
              text('$pad  ', 'content', field['contentType'] as String?);
              break;
            }
            if (targetId != null) instanceIds.putIfAbsent(targetId, () => id!);
            out.writeln('$pad$key:');
            final targetOneOf = requiredOneOf(targetCls);
            if (targetOneOf != null) {
              // A single container takes the next case at each encounter.
              final pending = pendingCases.putIfAbsent(
                target,
                () => casesOf(target),
              );
              if (visited.add(target) || pending.isNotEmpty) {
                final chosen = pending.isNotEmpty
                    ? pending.removeAt(0)
                    : casesOf(target).first;
                emitBody(target, indent + 2, chosen);
              }
            } else if (visited.add(target)) {
              emitBody(target, indent + 2, null);
            }
          case 'list':
            final listId = field['sectionId'] as String;
            final element = field['elementType'] as String;
            final elementCls = classes[element] as Map<String, dynamic>?;
            final elementId = elementCls?['sectionId'] as String?;
            final pattern = field['sectionIdPattern'] as String?;
            final stem = listId.endsWith('-LST')
                ? listId.substring(0, listId.length - 4)
                : listId;
            // The id a document gives its n-th item: the `@SectionIdPattern`
            // with `xxx` as the position, which is the codec's own canonical
            // anonymous id; `<stem>-n` where the list declares no pattern.
            String itemKey(int n) =>
                pattern == null ? '$stem-$n' : pattern.replaceAll('xxx', '$n');
            final min = (field['min'] as int?) ?? 1;
            out.writeln('$pad$listId $name:');
            keysEmitted++;
            if (elementCls == null) {
              // Scalar-element list: direct scalar items.
              for (var n = 1; n <= (min < 1 ? 1 : min); n++) {
                out.writeln('$pad  ${itemKey(n)}: Exercise item.');
              }
              break;
            }
            final isReference =
                (field['annotations'] as List<dynamic>? ?? const []).any(
                  (a) => (a as Map<String, dynamic>)['name'] == 'Reference',
                );
            if (isReference) {
              // A `@Reference` list owns nothing: its item is the id of an
              // element instance declared elsewhere (tom_specs_model_rules.md
              // §7.2), with no body of its own.
              out.writeln(
                '$pad  ${instanceIds[elementId] ?? elementId ?? itemKey(1)}: {}',
              );
              break;
            }
            if (elementId != null) {
              instanceIds.putIfAbsent(elementId, () => itemKey(1));
            }
            // Every item carries a full body, so a revisited element still
            // holds what the schema requires of it; the classes nested below
            // are emitted once (the visited set) and [onPath] stops a list
            // that contains its own element type from recursing.
            final oneOf = requiredOneOf(elementCls);
            final cases = oneOf == null || !visited.add(element)
                ? const <String>[]
                : casesOf(element);
            visited.add(element);
            final count = cases.length > min
                ? cases.length
                : (min < 1 ? 1 : min);
            for (var n = 1; n <= count; n++) {
              final chosen = oneOf == null
                  ? null
                  : (n <= cases.length ? cases[n - 1] : casesOf(element).first);
              final saved = out.toString();
              out.clear();
              if (onPath.add(element)) {
                emitBody(element, indent + 4, chosen);
                onPath.remove(element);
              }
              final body = out.toString();
              out
                ..clear()
                ..write(saved);
              if (body.isEmpty) {
                // Empty item bodies must be maps (`{}`), not null.
                out.writeln('$pad  ${itemKey(n)}: {}');
              } else {
                out
                  ..writeln('$pad  ${itemKey(n)}:')
                  ..write(body);
              }
            }
        }
      }
    };

    final rootId = rootClass['sectionId'] as String?;
    final rootKey = rootId == null ? _root : '$rootId $_root';
    out.writeln('  $rootKey:');
    visited.add(_root);
    emitBody(_root, 4, null);
    return out.toString();
  }

  emitDocument(); // records every instance id a reference may name
  b.write(emitDocument());

  outFile.writeAsStringSync(b.toString());
  stdout.writeln('wrote ${outFile.path}');
  stdout.writeln(
    'class bodies emitted: $classBodies, keys emitted: $keysEmitted',
  );
}
