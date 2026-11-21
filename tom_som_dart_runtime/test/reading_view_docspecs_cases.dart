// The reading view's DocSpecs validator cases (04a_rdv2, SOM §14; the DocSpecs
// specification's *Form Types* (Form Tables), *List Bodies*, *Section Anchors*
// and *Styled-div headings*): form tables, `refs` and `records` list bodies
// and section tables turned into virtual sections, styled-div headings, and
// the `malformedBlock` / `unknownField` / `unknownSection` / `rejectedBlock`
// findings. `_docSpecsCases` in conformance_test.dart appends them to
// `docspecs_cases.json` with their violations computed by the Dart validator;
// each carries `"readingView": true`, which the runtimes that do not read the
// table forms yet skip (the reading view's parity audit, 05a_rdv4, ports
// them). TypeScript runs them.
//
// Each case is a minimal edit of the clean demo document, so the reported
// lines are legible against it. The expected violations were checked by hand
// against the grammar of the reading view's part *Parser and DocSpecs*.

/// The cases as `{name, markdown}`, each an edit of [validDoc] (the corpus's
/// clean demo document).
List<Map<String, String>> readingViewDocSpecsCases(String validDoc) {
  Map<String, String> c(String name, String markdown) => {
    'name': name,
    'markdown': markdown,
  };
  String header(String table) =>
      validDoc.replaceFirst('Author: Alice\nReviewer: Bob\n', table);
  String append(String sections) => '$validDoc$sections';

  const formTable =
      '| TomSpecField | Value |\n'
      '| --- | --- |\n';
  const refsHead = '\n## <!--[REFS-LST]--> References\n\n';
  const critHead = '\n## <!--[CRIT-LST]--> Acceptance Criteria\n\n';
  const attrHead =
      '\n## <!--[ATTR]--> Attribute name\n\n'
      '| Section | TomSpecField | Value |\n'
      '| --- | --- | --- |\n';
  const div7 =
      '<div class="heading7" '
      'style="margin:1em 0 0.5em;padding-left:0.75em;font-weight:bold">';

  return [
    // --- Form tables ------------------------------------------------------
    // Required field given only as a row; a link cell reads as its link text
    // (so `^[A-Z]` holds), `\|` as a pipe.
    c(
      'readingView: form table gives a required field',
      header(
        '$formTable'
        '| Author | Alice \\| Ann |\n'
        '| reviewer | [Bob](people.md#bob) |\n',
      ),
    ),
    c(
      'readingView: required field missing from table and paragraphs',
      header('$formTable| Reviewer | Bob |\n'),
    ),
    c(
      'readingView: fieldPatternMismatch points at the row',
      header('$formTable| Author | Alice |\n| Reviewer | bob |\n'),
    ),
    c(
      'readingView: form table without its delimiter row',
      header('| TomSpecField | Value |\n| Author | Alice |\n'),
    ),
    c(
      'readingView: a row of another cell count',
      header('$formTable| Author | Alice |\n| Reviewer | Bob | x |\n'),
    ),
    c(
      'readingView: a row naming no field',
      header('$formTable| Author | Alice |\n| Editor | Carol |\n'),
    ),
    // The second occurrence is reported and the first kept, whether row or
    // paragraph: the paragraph's lowercase reviewer is never pattern-checked.
    c(
      'readingView: a field given twice keeps the first',
      header(
        '$formTable| Author | Alice |\n| Reviewer | Bob |\n\n'
        'Reviewer: bob\n',
      ),
    ),
    // --- refs -------------------------------------------------------------
    c(
      'readingView: refs line below min-count',
      append('$refsHead::: {.refs}\n[GOAL-ITEM-1](#GOAL-ITEM-1)\n:::\n'),
    ),
    c(
      'readingView: refs container passes max-text-length 0',
      append(
        '$refsHead::: {.refs}\n'
        '[GOAL-ITEM-1](#GOAL-ITEM-1), GOAL-ITEM-2\n'
        ':::\n',
      ),
    ),
    // The item type has no form: the reference goes to a virtual child of its
    // one subsection type with a one-field form, where the pattern applies.
    c(
      'readingView: refs into a virtual child section',
      append(
        '\n## <!--[LINK-LST]--> Links\n\n'
        '::: refs\nGOAL-ITEM-1 goal-item-2\n:::\n',
      ),
    ),
    c(
      'readingView: refs div beside other text',
      append('${refsHead}Stray text.\n\n::: {.refs}\nA, B\n:::\n'),
    ),
    c(
      'readingView: unclosed refs fence',
      append('$refsHead::: {.refs}\nA, B\n'),
    ),
    // --- records ----------------------------------------------------------
    c(
      'readingView: records table satisfies min-count',
      append(
        '$critHead::: {.records}\n'
        '| Id | Title | Given | When | Then |\n'
        '| --- | --- | --- | --- | --- |\n'
        '| <a id="CRIT-1"></a>CRIT-1 | Second admin | a tenant | an invite '
        '| both confirm |\n'
        '| <a id="CRIT-2"></a>CRIT-2 | | an expired invite | it is opened '
        '| ask again |\n'
        ':::\n',
      ),
    ),
    // Per-row findings point at the row: an id off its pattern, an empty
    // required cell, a value off its pattern; three rows exceed max-count 3
    // only with a fourth.
    c(
      'readingView: records row findings',
      append(
        '$critHead::: {.records}\n'
        '| Id | Given | Then |\n'
        '| --- | --- | --- |\n'
        '| CRIT-X | a tenant | ok |\n'
        '| CRIT-2 | | ok |\n'
        '| CRIT-3 | a user | Not ok |\n'
        '| CRIT-4 | a user | ok |\n'
        ':::\n',
      ),
    ),
    c(
      'readingView: records div holding no table',
      append('$critHead::: {.records}\nCRIT-1, CRIT-2\n:::\n'),
    ),
    c(
      'readingView: records table whose first column is not Id',
      append(
        '$critHead::: {.records}\n'
        '| Given | Then |\n| --- | --- |\n| a | b |\n'
        ':::\n',
      ),
    ),
    c(
      'readingView: records column naming no field',
      append(
        '$critHead::: {.records}\n'
        '| Id | Given | Owner |\n'
        '| --- | --- | --- |\n'
        '| CRIT-1 | a | b |\n'
        '| CRIT-2 | a | b |\n'
        ':::\n',
      ),
    ),
    c(
      'readingView: records div beside item headings',
      append(
        '$critHead::: {.records}\n'
        '| Id | Given |\n| --- | --- |\n| CRIT-1 | a |\n'
        ':::\n\n'
        '### <!--[CRIT-2]--> Criterion\n\nGiven: b\n',
      ),
    ),
    // --- Section tables ---------------------------------------------------
    c(
      'readingView: section table with a list item',
      append(
        '$attrHead'
        '| <a id="IDEN"></a>IDEN | ColumnName | name |\n'
        '| | Description | Display name \\| label. |\n'
        '| CONS-LST / <a id="CONS-1"></a>CONS-1 | Mandatory | Yes |\n',
      ),
    ),
    c(
      'readingView: section table findings at their rows',
      append(
        '$attrHead'
        '| IDEN | Description | Display name. |\n'
        '| CONS-LST / CONS-1 | Mandatory | Maybe |\n',
      ),
    ),
    c(
      'readingView: section table cell naming no child',
      append(
        '$attrHead'
        '| IDEN | ColumnName | name |\n'
        '| GOALS | ColumnName | x |\n'
        '| | Description | skipped |\n'
        '| NOPE | Description | y |\n',
      ),
    ),
    // --- Notation, styled-div headings ------------------------------------
    c(
      'readingView: rejected block',
      validDoc.replaceFirst(
        'Some overview text.\n',
        'Some overview text.\n\n'
            '::: {.rejected reason="malformedBlock"}\n'
            'Owner: Platform team\n'
            ':::\n',
      ),
    ),
    c(
      'readingView: styled-div headings count at their level',
      validDoc
          .replaceFirst(
            '### <!--[GOAL-ITEM-1]--> Goal 1',
            '$div7<!--[GOAL-ITEM-1]--> <a id="GOAL-ITEM-1"></a> '
                'Goal &amp; 1</div>',
          )
          .replaceFirst(
            '### <!--[GOAL-ITEM-2]--> Goal 2',
            '$div7<!--[GOAL-ITEM-B]--> Goal 2</div>',
          ),
    ),
    c(
      'readingView: a heading6 div is content',
      validDoc
          .replaceFirst(
            '### <!--[GOAL-ITEM-1]--> Goal 1',
            '<div class="heading6"><!--[GOAL-ITEM-1]--> Goal 1</div>',
          )
          .replaceFirst(
            '### <!--[GOAL-ITEM-2]--> Goal 2',
            '<div class="heading6"><!--[GOAL-ITEM-2]--> Goal 2</div>',
          ),
    ),
  ];
}
