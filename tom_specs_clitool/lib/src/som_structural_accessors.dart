/// The **structural accessor surface** of a generated node facade, and the
/// per-language names a generated *field* accessor must therefore never take.
///
/// Every generated section facade in every one of the nine languages is a thin
/// wrapper over the runtime's `SomNode`, which carries a small fixed set of
/// **structural** members — the document and path it is bound to, its section
/// id, its stored headline, its CodeSpecs forward link, and the two emptiness /
/// content predicates. A generated field accessor that happens to take one of
/// those names does not fail to compile in every language: where the facade
/// *inherits* (Dart, TypeScript, JavaScript, Java, Python) or *embeds*
/// (Go) the node, a same-named member silently **shadows** the structural one,
/// and the symptom is a wrong read rather than a build error.
///
/// This file is the single place that knows those names. Emitters do not carry
/// their own literal lists: each one asks [somReservedAccessorNames] for its
/// language, so **adding a structural accessor is one entry here** rather than
/// nine independent edits, eight of which are easy to forget.
///
/// Two guards keep it honest, both in `test/som_structural_accessors_test.dart`:
///
/// 1. **Completeness** — every [SomStructuralMember] has an entry for every
///    [SomLanguage]. A new member does not compile-and-pass until nine explicit
///    decisions have been recorded, including the deliberate empty ones.
/// 2. **Agreement with the runtime** — the `dart` entry is checked against the
///    real `SomNode` in `tom_som_dart_runtime`, which is the reference
///    implementation the other eight mirror. Adding `$foo` to the Dart facade
///    turns that test red until this table records it.
library;

import 'spec_object_model_config.dart' show SomLanguage;

/// A structural member of the runtime `SomNode` that every generated facade
/// carries, independent of the model.
///
/// The enum is the language-neutral concept; [somStructuralAccessorNames] maps
/// each one to the identifier(s) it is actually emitted as per language.
enum SomStructuralMember {
  /// The bound generic document (`doc`).
  doc,

  /// The bound section path (`path`).
  path,

  /// The list-item section id (`$sectionId` / `SectionID` / `spec_section_id`).
  sectionId,

  /// The stored headline (YRD3).
  headline,

  /// The CodeSpecs forward link (`codespecs_mapping.md` §9.2).
  codeSpec,

  /// The "is this subtree empty *now*?" state predicate (SOM §21).
  isEmpty,

  /// The "*can* this section type hold body text?" schema predicate (SOM §21).
  canHaveContent,
}

/// The identifiers each [SomStructuralMember] is emitted as, per language —
/// getter **and** setter form where the language spells them separately.
///
/// An **empty** list is a positive statement, not an omission: it records that a
/// generated field accessor in that language cannot collide with that member,
/// because of how the language's facade is built.
///
/// - **rust** — the generated struct *composes* the node (`pub node: SomNode`)
///   instead of inheriting it. `SomNode`'s methods live on `SomNode`, so an
///   `impl` method of any name reaches them only through `self.node`, and
///   nothing can be shadowed. (The emitted `new` constructor *is* a collision
///   risk, but it belongs to the generated impl, not to the structural surface,
///   and a duplicate there is a hard compile error.)
/// - **c** — there is no facade type to inherit from. Every emitted function
///   name is `<type>_<member>` and is allocated from one flat namespace with
///   deduplication, so a field named `can_have_content` is renamed rather than
///   silently overriding `<type>_can_have_content`.
const Map<SomLanguage, Map<SomStructuralMember, List<String>>>
    somStructuralAccessorNames = {
  // Facade `extends SomNode`; `doc`/`path` are fields, the three sparse
  // accessors are `$`-prefixed getter/setter pairs sharing one name.
  SomLanguage.dart: {
    SomStructuralMember.doc: ['doc'],
    SomStructuralMember.path: ['path'],
    SomStructuralMember.sectionId: [r'$sectionId'],
    SomStructuralMember.headline: [r'$headline'],
    SomStructuralMember.codeSpec: [r'$codeSpec'],
    SomStructuralMember.isEmpty: ['isEmpty'],
    SomStructuralMember.canHaveContent: ['canHaveContent'],
  },
  // Facade `extends SomNode`; mirrors Dart name for name (decision AE-D1).
  SomLanguage.typescript: {
    SomStructuralMember.doc: ['doc'],
    SomStructuralMember.path: ['path'],
    SomStructuralMember.sectionId: [r'$sectionId'],
    SomStructuralMember.headline: [r'$headline'],
    SomStructuralMember.codeSpec: [r'$codeSpec'],
    SomStructuralMember.isEmpty: ['isEmpty'],
    SomStructuralMember.canHaveContent: ['canHaveContent'],
  },
  SomLanguage.javascript: {
    SomStructuralMember.doc: ['doc'],
    SomStructuralMember.path: ['path'],
    SomStructuralMember.sectionId: [r'$sectionId'],
    SomStructuralMember.headline: [r'$headline'],
    SomStructuralMember.codeSpec: [r'$codeSpec'],
    SomStructuralMember.isEmpty: ['isEmpty'],
    SomStructuralMember.canHaveContent: ['canHaveContent'],
  },
  // Facade `extends SomNode`; Java allows `$` in identifiers, so the same
  // `$`-prefixed names are used — as overloaded zero-arg / one-arg methods.
  SomLanguage.java: {
    SomStructuralMember.doc: ['doc'],
    SomStructuralMember.path: ['path'],
    SomStructuralMember.sectionId: [r'$sectionId'],
    SomStructuralMember.headline: [r'$headline'],
    SomStructuralMember.codeSpec: [r'$codeSpec'],
    SomStructuralMember.isEmpty: ['isEmpty'],
    SomStructuralMember.canHaveContent: ['canHaveContent'],
  },
  // Facade subclasses `SomNode`. `$` is not a legal Python identifier
  // character, so the three sparse accessors take a `spec_` prefix instead and
  // the predicates are snake_cased.
  SomLanguage.python: {
    SomStructuralMember.doc: ['doc'],
    SomStructuralMember.path: ['path'],
    SomStructuralMember.sectionId: ['spec_section_id'],
    SomStructuralMember.headline: ['spec_headline'],
    SomStructuralMember.codeSpec: ['spec_code_spec'],
    SomStructuralMember.isEmpty: ['is_empty'],
    SomStructuralMember.canHaveContent: ['can_have_content'],
  },
  // Facade struct *embeds* `som.SomNode`, so every one of these is a promoted
  // method a same-named generated method would shadow. Go has no `$` and no
  // property syntax: setters are separate `Set…` methods and are reserved too.
  SomLanguage.go: {
    SomStructuralMember.doc: ['Doc'],
    SomStructuralMember.path: ['Path'],
    SomStructuralMember.sectionId: ['SectionID', 'SetSectionID'],
    SomStructuralMember.headline: ['Headline', 'SetHeadline'],
    SomStructuralMember.codeSpec: ['CodeSpec', 'SetCodeSpec'],
    SomStructuralMember.isEmpty: ['IsEmpty'],
    SomStructuralMember.canHaveContent: ['CanHaveContent'],
  },
  // Facade `: public som::SomNode`. The members are non-virtual (except
  // `canHaveContent`), so a same-named derived method hides rather than
  // overrides — the silent case this table exists for.
  SomLanguage.cpp: {
    SomStructuralMember.doc: ['doc'],
    SomStructuralMember.path: ['path'],
    SomStructuralMember.sectionId: ['sectionId', 'setSectionId'],
    SomStructuralMember.headline: ['headline', 'setHeadline'],
    SomStructuralMember.codeSpec: ['codeSpec', 'setCodeSpec'],
    SomStructuralMember.isEmpty: ['isEmpty'],
    SomStructuralMember.canHaveContent: ['canHaveContent'],
  },
  // Composition, not inheritance — see the library doc above.
  SomLanguage.rust: {
    SomStructuralMember.doc: [],
    SomStructuralMember.path: [],
    SomStructuralMember.sectionId: [],
    SomStructuralMember.headline: [],
    SomStructuralMember.codeSpec: [],
    SomStructuralMember.isEmpty: [],
    SomStructuralMember.canHaveContent: [],
  },
  // One flat, deduplicated function namespace — see the library doc above.
  SomLanguage.c: {
    SomStructuralMember.doc: [],
    SomStructuralMember.path: [],
    SomStructuralMember.sectionId: [],
    SomStructuralMember.headline: [],
    SomStructuralMember.codeSpec: [],
    SomStructuralMember.isEmpty: [],
    SomStructuralMember.canHaveContent: [],
  },
};

/// The flat set of accessor names a generated field accessor must not take in
/// [language].
///
/// Emitters call this once and consult the result from their accessor-name
/// allocator; a name in the set is sanitised the same way a language keyword is
/// (a trailing `_`), so the collision resolves to a *different* accessor rather
/// than to a shadowed structural one.
Set<String> somReservedAccessorNames(SomLanguage language) => {
      for (final names in somStructuralAccessorNames[language]!.values) ...names,
    };
