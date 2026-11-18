#!/usr/bin/env python3
"""TomSpecs sample — building tooling ON a specification (Python).

The Python port of ``../bin/build_a_specification_tool.dart``: the same five
steps over the same fixture. Its output differs from the Dart sample in the
two places where the Dart text names a Dart-only surface; ``expected_output.txt``
here records the Python output, and README.md says where it differs.

Run (from this folder; see README.md for the install)::

    python3 main.py

For the reader who is not authoring specifications but writing programs that
read them: an editor, a linter, a report, an importer, a migration. That reader
needs four things, and this sample walks them in the order they are needed:

  1. REFLECTION   — what the model CAN hold, read from the metadata tree
  2. GENERIC      — what a document DOES hold, with no compile-time knowledge
                    of its shape
  3. SCHEMA       — the generated schema, where it comes from and what it is
  4. VALIDATION   — the two runtime tiers, and the third that is not here
  5. A TOOL       — a completeness report built on all four

The individual APIs are demonstrated one at a time in the facade's own
examples (``tom_som_python_v0/examples/``): ``b_generic_document.py`` and
``c_reflection_metadata.py``.
"""

from __future__ import annotations

import datetime as _dt
import os
from enum import Enum
from typing import Iterable, List, Optional, Set

from tom_som_runtime import (
    DocSpecsSchema,
    DocSpecsValidator,
    DocSpecsViolationRule,
    SpecDocument,
    SpecField,
    SpecFieldKind,
    SpecModel,
    SpecReflection,
    SpecValidationCode,
    validate_document,
)
from tom_som_python_v0 import (
    D00SolutionBlueprint,
    d00SolutionBlueprint,
    d00SolutionBlueprintMetaTree,
)
from tom_som_python_v0_data import schemas_root, spec_model

#: The document root this sample inspects.
_K_ROOT = "D00SolutionBlueprint"

#: That root's addressable segment — the first element of every path in it.
_K_ROOT_SEGMENT = "SBP"

#: The creation date section-id generation is pinned to. ``SomList.add``
#: derives an item's id from the current date, so an unpinned run would emit
#: different ids every day and ``expected_output.txt`` would record the day it
#: was taken rather than the pipeline.
_K_AUTHORED_ON = _dt.date(2026, 1, 1)

#: The report's title column width. Titles are clipped to it rather than
#: wrapped: a completeness report is scanned down its numbers, and a wrapped
#: title puts a row's two halves on different lines.
_K_TITLE_WIDTH = 38


def main() -> int:
    model = spec_model()
    schema = _load_schema()

    doc = SpecDocument()
    _author_fixture(D00SolutionBlueprint(doc))

    _section(0, "The document this run inspects")
    print("A Solution Blueprint with a handful of sections written and the")
    print("rest left blank — small enough that every number below can be")
    print("checked by reading `_author_fixture` in this file.")
    print("")
    print(f"  content leaves written : {len(doc.content_paths)}")
    print(f"  form sections written  : {len(doc.form_paths)}")
    print(f"  lists with items       : {len(doc.list_paths)}")

    _reflection(model)
    _generic_access(model, doc)
    _the_schema(schema)
    _validation(model, schema, doc)
    _the_tool(model, schema, doc)
    return 0


# ===========================================================================
# 1. Reflection — what the model CAN hold
# ===========================================================================


def _reflection(model: SpecModel) -> None:
    _section(1, "Reflection — what the model CAN hold")
    print("`SpecModel` is the exported class graph; `SpecReflection` is the")
    print("value-free query surface over it. No document is involved here.")
    print("")

    print("THE TWO VERSION STAMPS. They answer different questions and a tool")
    print("that checks one for the other will accept a file it cannot read:")
    print(f"  modelVersion      = {model.model_version}"
          "  — WHICH MODEL this snapshot describes")
    print(f"  metaSchemaVersion = {model.meta_schema_version}"
          "  — the FILE FORMAT the snapshot itself is written in")
    print(f"  modelVersionLabel = {model.model_version_label}")
    print(f"  generatedAt       = {_iso(model.generated_at)}")
    print("")
    print("A tool reads `metaSchemaVersion` to decide whether it can parse the")
    print("file at all, and `modelVersion` to decide whether the documents it")
    print("holds are the ones this model describes. `modelVersionLabel` is a")
    print("build label for humans — never branch on it.")
    print("")

    # A snapshot is a photograph. `check_stamp` compares what the exporter
    # DECLARED against what survived to the reader, and ages the file out.
    # `now` is derived from the model's own stamp so the printed age stays at
    # exactly the offset this sample means to demonstrate.
    exported_at = model.generated_at or _dt.datetime(2026, 1, 1, tzinfo=_dt.timezone.utc)
    stamp = model.check_stamp(now=exported_at + _dt.timedelta(days=3))
    print("SNAPSHOT CHECK (`checkStamp`), against a fixed clock:")
    age_days = stamp.age.days if stamp.age is not None else None
    print(f"  age                 : {age_days} days (aged: {_b(stamp.is_aged)})")
    print("  classes  declared/actual : "
          f"{stamp.declared_class_count}/{stamp.actual_class_count}"
          f"  disagrees: {_b(stamp.class_count_disagrees)}")
    print("  roots    declared/actual : "
          f"{stamp.declared_root_count}/{stamp.actual_root_count}"
          f"  disagrees: {_b(stamp.root_count_disagrees)}")
    print("  Declared-vs-actual is not redundant: the declared value is what")
    print("  the exporter recorded, the actual value is what survived to the")
    print("  reader, and a truncated file is exactly where they part.")
    print("")

    reflection = SpecReflection(model)
    print("SHAPE:")
    print(f"  document roots : {len(list(reflection.roots))}")
    print(f"  classes        : {len(list(reflection.classes))}")
    print(f"  container root : {model.container_root}"
          " — the one true tree root, which is not itself a document")
    print("")

    root = reflection.root_for_segment("SBP")
    fields = reflection.fields_of(root.type)
    print(f"FIELDS of {root.type} ({len(fields)} total, first 4):")
    for f in fields[:4]:
        print(f"  {f.name.ljust(24)} kind={_kind(f.kind).ljust(8)} {f.type or ''}")
    print("")

    # A form's slots are on the field itself, not on a separate class — the
    # shape a tool must handle to render or fill one.
    form = next(f for f in reflection.fields_of("DataEntityEntry")
                if f.kind == SpecFieldKind.FORM)
    print(f"FORM SLOTS of DataEntityEntry.{form.name} "
          f"(section id {form.section_id}):")
    for slot in form.form_fields:
        print(f"  {slot.name.ljust(16)} {slot.label}")
    print("")

    print("ANNOTATIONS the meta carries — the model's own metadata, exported")
    print("into the snapshot and therefore visible in ALL NINE language")
    print("runtimes, not just Dart:")
    for a in reflection.annotations_of(root.type):
        args = ", ".join(a.arguments.keys())
        print(f"  @{a.name}" + (f"({args})" if args else ""))
    # The display semantics of these annotations (`kRenderedAnnotations`) are
    # in the Dart runtime only: they are what the two Flutter apps share.
    print("  How each is displayed is the Dart runtime's (`kRenderedAnnotations`,")
    print("  shared by the two Flutter apps); the annotations themselves are")
    print("  data every runtime reads.")
    print("")

    print("PATH RESOLUTION — a document path to the model node it lands on:")
    for path in [
        "SBP",
        "SBP/content",
        "SBP/informationAndDataModel/dataModel/DAENT-ENTI-LST",
        "SBP/informationAndDataModel/nosuchthing",
    ]:
        r = reflection.resolve(path)
        shown = ("(unresolved)" if r is None
                 else f"kind={_name(r.kind)}  leaf={_b(r.is_value_leaf)}")
        print(f"  {path.ljust(50)} {shown}")


# ===========================================================================
# 2. Generic access — what a document DOES hold
# ===========================================================================


def _generic_access(model: SpecModel, doc: SpecDocument) -> None:
    _section(2, "Generic access — what the document DOES hold")
    print("`SpecDocument` is a sparse, path-keyed store. A tool reads it")
    print("without knowing the document's shape, and asks the model what each")
    print("path means. That pairing is the whole of generic access.")
    print("")

    reflection = SpecReflection(model)
    print("EVERY written content leaf, resolved against the model:")
    for path in sorted(doc.content_paths):
        r = reflection.resolve(path)
        value = doc.content(path) or ""
        print(f"  {path.ljust(52)} {_name(r.kind) if r else '?'}")
        print(f"      {_clip(value, 66)}")
    print("")

    print("EVERY written form section, slot by slot:")
    for path in sorted(doc.form_paths):
        print(f"  {path}")
        for slot in sorted(doc.form_field_names(path)):
            print(f"      {slot.ljust(16)} {_clip(doc.form_field(path, slot) or '', 52)}")
    print("")

    print("EVERY list, with its items' section ids:")
    for path in sorted(doc.list_paths):
        print(f"  {path.ljust(52)} {doc.list_item_count(path)} item(s)")
        for id_ in doc.list_item_section_ids(path):
            print(f"      {id_}")
    print("")

    print("WHERE PATHS COME FROM. A tool must never hard-code a path literal —")
    print("a literal is undiscoverable and rots silently when the model moves.")
    print("Two safe sources, both from the generated metadata module:")
    print("")
    print("  1. the generated metadata refs —")
    print("     d00SolutionBlueprint.informationAndDataModel.dataModel.path")
    print(f"       = {d00SolutionBlueprint.informationAndDataModel.dataModel.path}")
    print("  2. the id-keyed metadata tree, for a path known only at runtime —")
    node = d00SolutionBlueprintMetaTree.by_id("DAENT-ENTI-LST")
    print("     d00SolutionBlueprintMetaTree.by_id('DAENT-ENTI-LST')")
    print(f"       = {node.path if node else None}")
    print("")
    print("  The tree also goes the other way: by_path gives the node, and with")
    print("  it the class, kind and children a generic renderer needs.")
    by_path = d00SolutionBlueprintMetaTree.by_path("SBP/informationAndDataModel/dataModel")
    print("     by_path('SBP/informationAndDataModel/dataModel')")
    print(f"       class={by_path.class_name} kind={_name(by_path.kind)} "
          f"children={len(by_path.children)}")


# ===========================================================================
# 3. The generated schema
# ===========================================================================


def _the_schema(schema: DocSpecsSchema) -> None:
    _section(3, "The generated schema")
    print("Each of the 14 document roots has a schema GENERATED from the model")
    print("and SHIPPED as data inside the facade package, under")
    print("`schemas/<document>/<document>.1.0.docspecs-schema.yaml`. A tool")
    print("loads one; it never writes one, and never derives one itself.")
    print("")
    print("IT IS A DocSpecs SCHEMA, NOT JSON SCHEMA. It describes a *markdown*")
    print("document — headings, their ids, their formats, the form fields a")
    print("section carries and which of them are required. A tool reaching for")
    print("a JSON-Schema validator will not find one, because the artifact the")
    print("schema governs is not JSON.")
    print("")
    print(f"  root section id : {schema.root_section_id}")
    print(f"  section types   : {len(schema.section_types)}")
    print("")
    print("  That count is large because a Solution Blueprint SEEDS the twelve")
    print("  Phase-3 documents: its own section classes ARE those documents'")
    print("  types, so its schema covers every section id they define. Step 5")
    print("  meets the same fact from the other side.")
    print("")
    print("  A section type resolves by ID PREFIX, which is how a generated id")
    print("  like `DAENT-ENTI-7` finds its type without the schema listing")
    print("  every instance:")
    for id_ in ["DAENT-IDEN", "DAENT-ENTI-7", "NOSUCH-1"]:
        t = schema.resolve_section_type(id_)
        shown = ("(no type — a tool treats this as unknownSection)"
                 if t is None else t.prefix)
        print(f"    {id_.ljust(16)} -> {shown}")


# ===========================================================================
# 4. Validation — the tiers
# ===========================================================================


def _validation(model: SpecModel, schema: DocSpecsSchema, doc: SpecDocument) -> None:
    _section(4, "Validation — three tiers, two of them here")
    print("THIS IS THE DISTINCTION TOOLING AUTHORS MISS. A tool that wants one")
    print("tier and calls another gets nothing useful — not an error, just an")
    print("empty list that reads like a pass.")
    print("")
    print("  STATIC tier   — checks the MODEL'S OWN ANNOTATIONS: field-type")
    print("                  rules, @ContentType compatibility, cycles, the")
    print("                  §10.2 structural invariants. Runs ONCE at")
    print("                  generation time, in")
    print("                  `tom_specs_clitool/lib/src/validator.dart`, and is")
    print("                  deliberately NOT part of the nine-language runtime")
    print("                  surface. Not reachable from this sample, and that")
    print("                  is the point: by the time a document exists, this")
    print("                  tier has already run.")
    print("  INSTANCE tier — checks A DOCUMENT'S VALUES against the model:")
    print("                  `validateDocument` (SOM §9). In every runtime.")
    print("  DOCUMENT tier — checks a MARKDOWN RENDITION against the generated")
    print("                  schema: `DocSpecsValidator` (SOM §14).")
    print("")
    print("The two runtime tiers overlap and neither implies the other:")
    print("`validateDocument` reports a required field left empty in a form the")
    print("document holds, but not a required section that is absent; the")
    print("schema validator reports the absent section, but does not follow a")
    print('reference it sees filled. A tool that wants "is this document good?"')
    print("runs BOTH.")
    print("")

    instance = validate_document(model, doc)
    document = DocSpecsValidator(schema).validate_markdown(
        doc.to_markdown(model, root_type=_K_ROOT)
    )
    print("THE FIXTURE, both tiers:")
    print(f"  instance tier : {len(instance)} error(s)")
    print(f"  document tier : {len(document)} violation(s)")
    for v in document[:4]:
        print(f"    line {v.line}: {v.rule.value} [{v.section_id}] {_clip(v.message, 54)}")
    if len(document) > 4:
        print(f"    … and {len(document) - 4} more")
    print("")

    # A document broken on purpose, to show the instance tier firing where the
    # document tier cannot see anything wrong.
    broken = SpecDocument()
    _author_fixture(D00SolutionBlueprint(broken))
    broken.set_content("SBP/informationAndDataModel/nosuchsection/content", "x")
    broken.set_form_field(
        "SBP/informationAndDataModel/dataModel/DAENT-ENTI-LST-1/DAENT-IDEN",
        "notAField",
        "x",
    )
    print("A DELIBERATELY BROKEN COPY — one path the model does not have, one")
    print("form slot the form does not declare:")
    for e in validate_document(model, broken):
        print(f"  {e.code.value.ljust(20)} {_clip(e.path, 50)}")
    print("")

    print("THE CLOSED VERDICT SETS. Both are enums, so a tool switches over")
    print("them exhaustively rather than matching on message text:")
    codes = [c.value for c in SpecValidationCode]
    print(f"  SpecValidationCode  ({len(codes)}): {', '.join(codes)}")
    rules = [r.value for r in DocSpecsViolationRule]
    print(f"  DocSpecsViolationRule ({len(rules)}):")
    for chunk in _chunk(rules, 4):
        print(f"    {', '.join(chunk)}")


# ===========================================================================
# 5. The tool
# ===========================================================================


def _the_tool(model: SpecModel, schema: DocSpecsSchema, doc: SpecDocument) -> None:
    _section(5, "A tool: the completeness report")
    print("Built on all four surfaces above, and it reports something NEITHER")
    print("validator can. The schema names what is REQUIRED and missing; an")
    print("optional section left blank is perfectly valid and no validator will")
    print('ever mention it. But "which parts of this specification has nobody')
    print('written yet?" is the question a specification author actually has,')
    print("and answering it means walking the model and asking the document.")
    print("")

    report = specification_coverage(model, doc, root_segment=_K_ROOT_SEGMENT)
    print(f"  {'SECTION'.ljust(_K_TITLE_WIDTH)} WRITTEN / OFFERED")
    for row in report.rows:
        bar = "" if row.offered == 0 else f"{_pct(row.written, row.offered)}%".rjust(6)
        print(f"  {row.title.ljust(_K_TITLE_WIDTH)} "
              f"{str(row.written).rjust(5)} / {str(row.offered).rjust(5)}{bar}")
    print(f"  {'-' * _K_TITLE_WIDTH} {'-' * 19}")
    print(f"  {'TOTAL'.ljust(_K_TITLE_WIDTH)} "
          f"{str(report.written).rjust(5)} / {str(report.offered).rjust(5)}"
          f"{(str(_pct(report.written, report.offered)) + '%').rjust(6)}")
    print("")
    largest = max(report.rows, key=lambda r: r.offered)
    print(f"  {largest.title.split(' ')[0]} offers {largest.offered} positions"
          " because a Solution Blueprint SEEDS")
    print("  the twelve Phase-3 documents: its section classes ARE those")
    print("  documents' types, so the model surface under an SBP root includes")
    print('  everything it seeds. A tool that reports "0 %" against a number')
    print("  like that should say what the denominator is — which is why the")
    print("  report is per section and not one headline figure.")
    print("")
    print("  Required-and-missing, from the schema tier, for contrast:")
    required = sum(
        1
        for v in DocSpecsValidator(schema).validate_markdown(
            doc.to_markdown(model, root_type=_K_ROOT)
        )
        if v.rule == DocSpecsViolationRule.MISSING_REQUIRED_FIELD
    )
    print(f"    {required} missing required field(s) — the only gaps a validator")
    print(f"    will name, out of {report.offered - report.written} unwritten "
          "positions.")
    print("")
    print("That gap between the two numbers is the tool's reason to exist.")


class CoverageRow:
    """One row of a :class:`SpecificationCoverage` — a top-level section."""

    def __init__(self, title: str, offered: int, written: int) -> None:
        #: The section's human-readable title, from the model.
        self.title = title
        #: Content positions the model offers anywhere beneath this section.
        self.offered = offered
        #: How many of them the document has written.
        self.written = written


class SpecificationCoverage:
    """What a document has written, against what its model offers."""

    def __init__(self, rows: List[CoverageRow]) -> None:
        #: One row per top-level section, in model order.
        self.rows = rows

    @property
    def offered(self) -> int:
        return sum(r.offered for r in self.rows)

    @property
    def written(self) -> int:
        return sum(r.written for r in self.rows)


def specification_coverage(
    model: SpecModel, doc: SpecDocument, *, root_segment: str
) -> SpecificationCoverage:
    """Walks *model* from *root_segment* and counts, per top-level section, how
    many content positions the model offers and how many *doc* has written.

    **Lists count as one position, not as their items.** A list the author
    left empty offers exactly one thing to write — the first item — and a list
    with forty items has not made the document forty times more complete.

    The walk is entirely generic: it knows no class or field name, so it works
    unchanged against any of the fourteen document roots.
    """
    reflection = SpecReflection(model)
    root = reflection.root_for_segment(root_segment)
    rows: List[CoverageRow] = []
    for field in reflection.fields_of(root.type):
        if field.kind == SpecFieldKind.CONTENT:
            continue  # the root's own body
        path = f"{root_segment}/{reflection.field_segment(field)}"
        counter = _Counter(doc)
        counter.walk(reflection, field, path, {root.type})
        if counter.offered == 0:
            continue
        rows.append(CoverageRow(_row_title(field), counter.offered, counter.written))
    return SpecificationCoverage(rows)


def _row_title(field: SpecField) -> str:
    """A section's title for the report — its model doc comment's first
    sentence, falling back to the field name where the model carries no doc."""
    text = (field.doc or "").split("\n")[0].strip()
    stop = text.find(". ")
    if stop >= 0:
        text = text[:stop]
    while text.endswith("."):
        text = text[:-1]
    text = text.strip()
    if not text:
        return field.name
    return text if len(text) <= _K_TITLE_WIDTH else text[: _K_TITLE_WIDTH - 1] + "…"


class _Counter:
    """Accumulates offered/written positions over one subtree."""

    def __init__(self, doc: SpecDocument) -> None:
        self.doc = doc
        self.offered = 0
        self.written = 0

    def walk(self, reflection: SpecReflection, field: SpecField, path: str,
             seen: Set[str]) -> None:
        """Adds every content position under *field* at *path*. *seen* carries
        the class names already on this branch; the model is a graph, and a
        section type that can contain itself would otherwise recurse forever."""
        kind = field.kind
        if kind in (SpecFieldKind.CONTENT, SpecFieldKind.SCALAR, SpecFieldKind.ENUM):
            self.offered += 1
            if self.doc.has_content(path):
                self.written += 1
        elif kind == SpecFieldKind.FORM:
            for slot in field.form_fields:
                self.offered += 1
                if self.doc.form_field(path, slot.name) or "":
                    self.written += 1
        elif kind == SpecFieldKind.LIST:
            self.offered += 1
            if self.doc.list_item_count(path) > 0:
                self.written += 1
        elif kind in (SpecFieldKind.SECTION, SpecFieldKind.COMPLEX):
            type_ = field.type
            if type_ is None or type_ in seen:
                return
            for child in reflection.fields_of(type_):
                self.walk(reflection, child,
                          f"{path}/{reflection.field_segment(child)}",
                          seen | {type_})


# ===========================================================================
# The fixture
# ===========================================================================


def _author_fixture(sbp: D00SolutionBlueprint) -> None:
    """Writes the small, deliberately incomplete document this run inspects —
    the same one the Dart sample writes."""
    sbp.content = "A platform that unifies our fragmented order systems."
    sbp.introductionAndScope.content = (
        "Replace three regional order desks with one intake service."
    )
    sbp.currentLandscape.content = "Three legacy systems with no shared customer record."

    metrics = sbp.currentLandscape.operationalMetrics
    metrics.add_content("Average order turnaround: 4.2 days.", date=_K_AUTHORED_ON)
    metrics.add_content("Manual reconciliation: ~12 hours per week.", date=_K_AUTHORED_ON)

    customer = sbp.informationAndDataModel.dataModel.entities.add(date=_K_AUTHORED_ON)
    customer.spec_headline = "Customer"
    identity = customer.identity
    identity.entityName = "Customer"
    identity.tableName = "customers"
    identity.description = "A party that places orders."
    # `category` is written and `aggregateRoot` is not, and `aggregateRoot` is
    # REQUIRED — so the schema tier has one real violation to report in step 4.
    customer.classification.category = "MasterData"


# ===========================================================================
# Loading, and small helpers
# ===========================================================================


def _load_schema() -> DocSpecsSchema:
    """The generated DocSpecs schema for the Solution Blueprint root, read from
    the data the facade package ships."""
    path = os.path.join(schemas_root(), "solution-blueprint",
                        "solution-blueprint.1.0.docspecs-schema.yaml")
    with open(path, encoding="utf-8") as f:
        return DocSpecsSchema.from_yaml_text(f.read())


def _section(n: int, title: str) -> None:
    print("")
    print("=" * 74)
    print(f"{n}. {title}")
    print("=" * 74)


def _clip(s: str, width: int) -> str:
    flat = s.replace("\n", " ")
    return flat if len(flat) <= width else flat[: width - 1] + "…"


def _chunk(items: List[str], size: int) -> Iterable[List[str]]:
    for i in range(0, len(items), size):
        yield items[i : i + size]


def _pct(written: int, offered: int) -> int:
    """Rounded like Dart's ``num.round()`` (half away from zero), not Python's
    banker's rounding."""
    return int((200 * written + offered) // (2 * offered))


def _b(value: bool) -> str:
    """A bool as the Dart sample prints it."""
    return "true" if value else "false"


def _name(value) -> str:
    """An enum's wire name (its value), or the text itself."""
    return value.value if isinstance(value, Enum) else str(value)


def _kind(kind: SpecFieldKind) -> str:
    """A field kind by the name the Dart enum gives it (`enum` is `enumValue`)."""
    return "enumValue" if kind == SpecFieldKind.ENUM else kind.value


def _iso(moment: Optional[_dt.datetime]) -> Optional[str]:
    """An instant as Dart's ``toIso8601String`` writes a UTC one."""
    if moment is None:
        return None
    utc = moment.astimezone(_dt.timezone.utc)
    return utc.strftime("%Y-%m-%dT%H:%M:%S.%f") + "Z"


if __name__ == "__main__":
    raise SystemExit(main())
