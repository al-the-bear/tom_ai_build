/// The doc lines the two spec-tree surfaces state twice.
///
/// `tom_specs_reviewer` and `tom_forge/tom_specs_editor` render the same class
/// graph through parallel widget trees. Keeping the *trees* separate is a
/// recorded decision — the hosts and per-row affordances differ — but the
/// explanations were forked along with the code, and **the hazard is
/// asymmetric**: the reviewer is at 100 % dartdoc with
/// `public_member_api_docs` enabled, while the editor is out of documentation
/// scope (`tom_specs_documentation_standard.md` §6). So the reviewer's copies
/// get maintained and the editor's do not, and the two drift apart with nothing
/// saying so. A reader of the editor is then told something that stopped being
/// true.
///
/// ## Why this is a ratchet rather than a "must be empty" check
///
/// Some duplication is correct and must stay. When a rule moves to
/// `tom_som_dart_runtime` and both trees *cite* it, the citation reads the same
/// in both — which is the intended end state, and it counts as a shared line.
/// Demanding zero would push a writer to paraphrase one of the two citations
/// apart, which is the drift this exists to prevent.
///
/// So the shared set may **shrink and never grow**. A new shared line is a new
/// forked explanation and fails; a removed one is progress and asks for the
/// baseline to be re-recorded.
///
/// Measuring the raw count is also not the goal, and it is worth saying why:
/// replacing two *divergent* implementations with two thin calls onto one
/// shared rule adds identical lines while removing the duplication that
/// mattered. The count went 115 → 112 across exactly such a change, and the
/// identical-code count went *up*. The gate catches new forks; it does not
/// score the refactor.
library;

import 'dart:io';

/// Doc-comment lines shorter than this are ignored.
///
/// Below it a match is usually incidental — `/// The document root.` says
/// nothing a reader could be misled by, and two surfaces naming the same field
/// the same way is not a fork. The threshold picks out *explanations*.
const int sharedDocMinLength = 45;

/// The reviewer's tree, relative to the container root.
const String reviewerTreeRoot = 'tom_ai/ai_build/tom_specs_reviewer/lib';

/// The editor's tree, relative to the container root.
const String editorTreeRoot = 'tom_forge/tom_specs_editor/lib';

/// The committed baseline, relative to `tom_specs_clitool`.
const String sharedDocBaselinePath = 'tool/spec_tree_shared_docs.txt';

/// Every doc-comment line over [sharedDocMinLength] characters under [root].
///
/// Text only: the `///` marker and surrounding whitespace are stripped, so two
/// lines differing solely in indentation still count as the same statement —
/// which they are, to a reader.
Set<String> docCommentLines(Directory root) {
  final out = <String>{};
  if (!root.existsSync()) return out;
  for (final entity in root.listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    for (final line in entity.readAsLinesSync()) {
      final trimmed = line.trim();
      if (!trimmed.startsWith('///')) continue;
      final text = trimmed.substring(3).trim();
      if (text.length > sharedDocMinLength) out.add(text);
    }
  }
  return out;
}

/// The doc lines both trees state, given the container root.
Set<String> sharedSpecTreeDocs(String containerRoot) => docCommentLines(
  Directory('$containerRoot/$reviewerTreeRoot'),
).intersection(docCommentLines(Directory('$containerRoot/$editorTreeRoot')));

/// Reads the committed baseline: one shared line per record, blank lines and
/// `#` comments ignored.
Set<String> readSharedDocBaseline(File file) => {
  for (final line in file.readAsLinesSync())
    if (line.trim().isNotEmpty && !line.startsWith('#')) line,
};

/// Writes [lines] as the baseline, sorted, with a header explaining the file.
///
/// Sorted so a diff shows what changed rather than where it moved.
void writeSharedDocBaseline(File file, Set<String> lines) {
  final sorted = lines.toList()..sort();
  file.writeAsStringSync(
    '# Doc lines stated in BOTH spec-tree surfaces — the reviewer\'s and the\n'
    '# editor\'s. Generated; see `lib/src/spec_tree_duplication.dart` for what\n'
    '# it is for and why it is a ratchet.\n'
    '#\n'
    '# The set may SHRINK and never GROW. A new line here is a new forked\n'
    '# explanation: move the rule to `tom_som_dart_runtime` and have both trees\n'
    '# cite it. When it shrinks, re-record this file in the same commit.\n'
    '#\n'
    '# Regenerate: dart run bin/check_spec_tree_duplication.dart --record\n'
    '\n'
    '${sorted.join('\n')}\n',
  );
}
