#!/usr/bin/env python3
"""DR4 metadata-core tests — a port of
``tom_som_dart_runtime/test/spec_meta_test.dart``.

Hand-built DR1 §3.1 fixture tree mirroring the design doc's demo document
(DR4 acceptance: "the runtime compiles with a hand-built fixture tree").

Structure::

  DEMO D99DemoDocument                      (@Document)
    INSC introductionAndScope               (section, class-level id)
      summary                               (content, no id)
      GOAL goals                            (section)
        GOAL-ITEM-LST entries               (list of GoalEntry, pattern)
          [element GoalEntry]
            text                            (content)
            subTasks                        (nested list of TaskEntry)
              [element TaskEntry]  note     (content)
    DOCO documentControl                    (form)
    RISK primaryRisk / RISK fallbackRisk    (shared class, two positions)
    PHASE-2 phaseTwo                        (hyphen+digit section id)
    related                                 (recursive re-entry)
    OLD legacy                              (@Unused content)
    tags                                    (scalar list, no element node)

Run with: ``python3 tests/spec_meta_test.py``. Exit code 0 == all green.
"""

from __future__ import annotations

import os
import sys

_HERE = os.path.dirname(os.path.abspath(__file__))
_PKG_ROOT = os.path.dirname(_HERE)
sys.path.insert(0, _PKG_ROOT)

from tom_som_runtime import (  # noqa: E402
    SomContentTypeMeta,
    SomDocMeta,
    SomFormFieldMeta,
    SomFormMeta,
    SomMetaExtra,
    SomMetaKind,
    SomMetaNode,
    SomMetaTree,
    SomSecondLevelId,
)

_passed = 0
_failed: list[str] = []


def _check(name: str, condition: bool, detail: str = "") -> None:
    global _passed
    if condition:
        _passed += 1
    else:
        _failed.append(f"{name}{(': ' + detail) if detail else ''}")


def _raises(fn, exc_type) -> bool:
    try:
        fn()
        return False
    except exc_type:
        return True


def build_fixture_tree() -> SomMetaTree:
    element = SomMetaNode(
        class_name="GoalEntry",
        kind=SomMetaKind.SECTION,
        type_name="GoalEntry",
        doc_comment="One programme goal.",
        children=[
            SomMetaNode(
                class_name="GoalEntry",
                member_name="text",
                kind=SomMetaKind.CONTENT,
                type_name="String",
                serialization_order=1,
            ),
            SomMetaNode(
                class_name="GoalEntry",
                member_name="subTasks",
                section_id_pattern="GOAL-TASK-xxx",
                kind=SomMetaKind.LIST,
                type_name="List<TaskEntry>",
                serialization_order=2,
                element_node=SomMetaNode(
                    class_name="TaskEntry",
                    kind=SomMetaKind.SECTION,
                    type_name="TaskEntry",
                    children=[
                        SomMetaNode(
                            class_name="TaskEntry",
                            member_name="note",
                            kind=SomMetaKind.CONTENT,
                            type_name="String",
                        ),
                    ],
                ),
            ),
        ],
    )

    def risk(member: str) -> SomMetaNode:
        return SomMetaNode(
            class_name="Risk",
            member_name=member,
            section_id="RISK",
            kind=SomMetaKind.COMPLEX,
            type_name="Risk",
            class_doc_comment="A programme risk.",
            children=[
                SomMetaNode(
                    class_name="Risk",
                    member_name="probability",
                    kind=SomMetaKind.ENUM_VALUE,
                    type_name="Probability",
                ),
            ],
        )

    root = SomMetaNode(
        class_name="D99DemoDocument",
        section_id="DEMO",
        kind=SomMetaKind.SECTION,
        type_name="D99DemoDocument",
        document=SomDocMeta(
            name="Demo Document",
            description="The demo specification document.",
            based_on=["D00SolutionBlueprint"],
        ),
        doc_comment="Root of the demo document.",
        children=[
            SomMetaNode(
                class_name="IntroductionAndScope",
                member_name="introductionAndScope",
                section_id="INSC",
                kind=SomMetaKind.SECTION,
                type_name="IntroductionAndScope",
                serialization_order=1,
                content_help="Describe why the system exists.",
                comment="Keep this short.",
                maps_to="CurrentLandscape",
                detailed_in="D01RequirementsSpecification",
                second_level_ids=[
                    SomSecondLevelId(
                        document_class="D01RequirementsSpecification",
                        id="RS-INSC",
                    ),
                ],
                children=[
                    SomMetaNode(
                        class_name="IntroductionAndScope",
                        member_name="summary",
                        kind=SomMetaKind.CONTENT,
                        type_name="String",
                        min=1,
                        serialization_order=1,
                        content_type=SomContentTypeMeta(
                            type="diagram",
                            description="A mermaid context diagram.",
                        ),
                        doc_comment="What the system covers.",
                    ),
                    SomMetaNode(
                        class_name="Goals",
                        member_name="goals",
                        section_id="GOAL",
                        kind=SomMetaKind.SECTION,
                        type_name="Goals",
                        serialization_order=2,
                        children=[
                            SomMetaNode(
                                class_name="Goals",
                                member_name="entries",
                                section_id="GOAL-ITEM-LST",
                                section_id_pattern="GOAL-ITEM-xxx",
                                kind=SomMetaKind.LIST,
                                type_name="List<GoalEntry>",
                                min=1,
                                extra=[
                                    SomMetaExtra(
                                        annotation="Max", args={"count": 4}
                                    ),
                                ],
                                element_node=element,
                            ),
                        ],
                    ),
                ],
            ),
            SomMetaNode(
                class_name="DocumentControl",
                member_name="documentControl",
                section_id="DOCO",
                kind=SomMetaKind.FORM,
                type_name="DocumentControl",
                serialization_order=2,
                form=SomFormMeta(
                    fields=[
                        SomFormFieldMeta(
                            name="version",
                            type_name="String",
                            description="Version",
                            required=True,
                            hint="e.g. 1.0",
                            order=1,
                        ),
                        SomFormFieldMeta(
                            name="approvedBy", type_name="String", order=2
                        ),
                        SomFormFieldMeta(
                            name="reviewCount", type_name="int", order=3
                        ),
                    ]
                ),
            ),
            risk("primaryRisk"),
            risk("fallbackRisk"),
            SomMetaNode(
                class_name="PhaseTwo",
                member_name="phaseTwo",
                section_id="PHASE-2",
                kind=SomMetaKind.SECTION,
                type_name="PhaseTwo",
                children=[
                    SomMetaNode(
                        class_name="PhaseTwo",
                        member_name="outline",
                        kind=SomMetaKind.CONTENT,
                        type_name="String",
                    ),
                ],
            ),
            SomMetaNode(
                class_name="D99DemoDocument",
                member_name="related",
                kind=SomMetaKind.COMPLEX,
                type_name="D99DemoDocument",
                recursive=True,
            ),
            SomMetaNode(
                class_name="D99DemoDocument",
                member_name="legacy",
                section_id="OLD",
                kind=SomMetaKind.CONTENT,
                type_name="String",
                unused=True,
            ),
            SomMetaNode(
                class_name="D99DemoDocument",
                member_name="tags",
                kind=SomMetaKind.LIST,
                type_name="List<String>",
            ),
        ],
    )
    return SomMetaTree(root)


def test_wiring() -> None:
    tree = build_fixture_tree()

    # root path is the root segment and parent is None
    _check("wiring.root.path", tree.root.path == "DEMO", str(tree.root.path))
    _check("wiring.root.segment", tree.root.segment == "DEMO")
    _check("wiring.root.parent", tree.root.parent is None)
    _check("wiring.root.doc.name", tree.root.document.name == "Demo Document")
    _check(
        "wiring.root.doc.basedOn",
        tree.root.document.based_on == ["D00SolutionBlueprint"],
    )

    # child paths follow the §4 grammar (sectionId ?? memberName)
    insc = tree.root.child_by_member("introductionAndScope")
    _check("wiring.insc.path", insc.path == "DEMO/INSC", str(insc.path))
    _check(
        "wiring.summary.path",
        insc.child_by_member("summary").path == "DEMO/INSC/summary",
    )
    entries = insc.child_by_member("goals").child_by_member("entries")
    _check(
        "wiring.entries.path",
        entries.path == "DEMO/INSC/GOAL/GOAL-ITEM-LST",
        str(entries.path),
    )

    # parent links are wired for children and element subtrees
    _check("wiring.entries.parent", entries.parent.segment == "GOAL")
    _check(
        "wiring.element.parent", entries.element_node.parent is entries
    )
    _check(
        "wiring.element.child.parent",
        entries.element_node.children[0].parent is entries.element_node,
    )

    # element subtree nodes carry no static path
    entries2 = tree.by_path("DEMO/INSC/GOAL/GOAL-ITEM-LST")
    element = entries2.element_node
    _check("wiring.element.path", element.path is None)
    _check(
        "wiring.element.text.path",
        element.child_by_member("text").path is None,
    )
    _check(
        "wiring.element.subTasks.path",
        element.child_by_member("subTasks").path is None,
    )

    # allNodes covers children and element subtrees in document order
    names = [n.debug_name for n in tree.all_nodes]
    _check("wiring.allNodes.first", names[0] == "D99DemoDocument", names[0])
    _check("wiring.allNodes.goalEntry", "GoalEntry" in names)
    _check("wiring.allNodes.taskNote", "TaskEntry.note" in names)
    _check("wiring.allNodes.fallbackRisk", "Risk.fallbackRisk" in names)
    _check(
        "wiring.allNodes.elementAfterList",
        names.index("GoalEntry") > names.index("Goals.entries"),
    )

    # a root without @Document metadata is rejected
    _check(
        "wiring.noDocumentRejected",
        _raises(
            lambda: SomMetaTree(
                SomMetaNode(
                    class_name="X", kind=SomMetaKind.SECTION, type_name="X"
                )
            ),
            ValueError,
        ),
    )

    # a node belongs to exactly one tree
    _check(
        "wiring.oneTreeRule",
        _raises(lambda: SomMetaTree(tree.root), RuntimeError),
    )

    # an unattached node refuses path/parent access
    loose = SomMetaNode(
        class_name="X", kind=SomMetaKind.SCALAR, type_name="int"
    )
    _check(
        "wiring.loose.path",
        _raises(lambda: loose.path, RuntimeError),
    )
    _check(
        "wiring.loose.parent",
        _raises(lambda: loose.parent, RuntimeError),
    )


def test_metadata_slots() -> None:
    tree = build_fixture_tree()

    # section node carries help, comment and traceability links
    insc = tree.by_id("INSC")
    _check(
        "slots.insc.help",
        insc.content_help == "Describe why the system exists.",
    )
    _check("slots.insc.comment", insc.comment == "Keep this short.")
    _check("slots.insc.mapsTo", insc.maps_to == "CurrentLandscape")
    _check(
        "slots.insc.detailedIn",
        insc.detailed_in == "D01RequirementsSpecification",
    )
    _check(
        "slots.insc.secondLevel",
        len(insc.second_level_ids) == 1
        and insc.second_level_ids[0].document_class
        == "D01RequirementsSpecification"
        and insc.second_level_ids[0].id == "RS-INSC",
    )
    _check("slots.insc.order", insc.serialization_order == 1)

    # content node carries @Min, @ContentType and doc comment
    summary = tree.by_path("DEMO/INSC/summary")
    _check("slots.summary.kind", summary.kind is SomMetaKind.CONTENT)
    _check("slots.summary.min", summary.min == 1)
    _check("slots.summary.ct.type", summary.content_type.type == "diagram")
    _check(
        "slots.summary.ct.desc",
        summary.content_type.description == "A mermaid context diagram.",
    )
    _check(
        "slots.summary.doc",
        summary.doc_comment == "What the system covers.",
    )

    # form node exposes fields with description/required/hint/order
    form = tree.by_id("DOCO").form
    _check(
        "slots.form.fields",
        [f.name for f in form.fields]
        == ["version", "approvedBy", "reviewCount"],
    )
    version = form.field_named("version")
    _check("slots.form.version.required", version.required is True)
    _check("slots.form.version.hint", version.hint == "e.g. 1.0")
    _check("slots.form.version.desc", version.description == "Version")
    _check("slots.form.version.order", version.order == 1)
    _check(
        "slots.form.approvedBy.required",
        form.field_named("approvedBy").required is False,
    )
    _check("slots.form.missing", form.field_named("missing") is None)

    # list node carries @Min plus the lossless extra list (@Max)
    entries = tree.by_id("GOAL-ITEM-LST")
    _check("slots.entries.kind", entries.kind is SomMetaKind.LIST)
    _check("slots.entries.min", entries.min == 1)
    _check(
        "slots.entries.pattern",
        entries.section_id_pattern == "GOAL-ITEM-xxx",
    )
    _check(
        "slots.entries.extra",
        len(entries.extra) == 1
        and entries.extra[0].annotation == "Max"
        and entries.extra[0].args["count"] == 4,
    )

    # @Unused and recursive flags are carried
    _check("slots.old.unused", tree.by_id("OLD").unused is True)
    related = tree.root.child_by_member("related")
    _check("slots.related.recursive", related.recursive is True)
    _check("slots.related.children", related.children == [])

    # class doc comment is carried where it differs from the member one
    _check(
        "slots.risk.classDoc",
        tree.by_id("RISK").class_doc_comment == "A programme risk.",
    )


def test_by_id() -> None:
    tree = build_fixture_tree()

    # resolves an exact section id
    _check("byId.demo", tree.by_id("DEMO") is tree.root)
    _check("byId.goal", tree.by_id("GOAL").member_name == "goals")

    # a shared class at two positions: first wins, allById has both
    _check("byId.risk.first", tree.by_id("RISK").member_name == "primaryRisk")
    _check(
        "byId.risk.all",
        [n.member_name for n in tree.all_by_id("RISK")]
        == ["primaryRisk", "fallbackRisk"],
    )

    # a resolved @SectionIdPattern id resolves to the element subtree
    element = tree.by_id("GOAL-ITEM-3")
    _check("byId.pattern.class", element.class_name == "GoalEntry")
    _check(
        "byId.pattern.element",
        element is tree.by_id("GOAL-ITEM-LST").element_node,
    )
    _check(
        "byId.nestedPattern",
        tree.by_id("GOAL-TASK-12").class_name == "TaskEntry",
    )

    # unknown and non-matching ids return None / empty
    _check("byId.nope", tree.by_id("NOPE") is None)
    _check("byId.dangling", tree.by_id("GOAL-ITEM-") is None)
    _check("byId.nonNumeric", tree.by_id("GOAL-ITEM-x") is None)
    _check("byId.allNope", tree.all_by_id("NOPE") == [])


def test_by_path() -> None:
    tree = build_fixture_tree()

    # resolves the bare root and nested sections
    _check("byPath.root", tree.by_path("DEMO") is tree.root)
    _check("byPath.insc", tree.by_path("DEMO/INSC").section_id == "INSC")
    _check(
        "byPath.goal", tree.by_path("DEMO/INSC/GOAL").member_name == "goals"
    )
    _check("byPath.doco", tree.by_path("DEMO/DOCO").kind is SomMetaKind.FORM)

    # a list container resolves only as the final segment
    _check(
        "byPath.list.final",
        tree.by_path("DEMO/INSC/GOAL/GOAL-ITEM-LST").kind is SomMetaKind.LIST,
    )
    _check(
        "byPath.list.notFinal",
        tree.by_path("DEMO/INSC/GOAL/GOAL-ITEM-LST/text") is None,
    )

    # a `-<seq>` item suffix descends into the element subtree
    item = tree.by_path("DEMO/INSC/GOAL/GOAL-ITEM-LST-2")
    _check("byPath.item.class", item.class_name == "GoalEntry")
    text = tree.by_path("DEMO/INSC/GOAL/GOAL-ITEM-LST-2/text")
    _check("byPath.item.text", text.kind is SomMetaKind.CONTENT)

    # nested lists inside an element subtree resolve dynamically
    task = tree.by_path("DEMO/INSC/GOAL/GOAL-ITEM-LST-1/subTasks-3/note")
    _check(
        "byPath.nested",
        task is not None
        and task.class_name == "TaskEntry"
        and task.kind is SomMetaKind.CONTENT,
    )

    # a hyphen+digit section id is not mis-read as a list item
    phase = tree.by_path("DEMO/PHASE-2")
    _check(
        "byPath.phase",
        phase.kind is SomMetaKind.SECTION and phase.member_name == "phaseTwo",
    )
    _check(
        "byPath.phase.outline",
        tree.by_path("DEMO/PHASE-2/outline").kind is SomMetaKind.CONTENT,
    )

    # a scalar list item is a value leaf (resolves to the list node)
    _check(
        "byPath.scalarItem",
        tree.by_path("DEMO/tags-4") is tree.by_path("DEMO/tags"),
    )
    _check("byPath.scalarItem.deeper", tree.by_path("DEMO/tags-4/deeper") is None)

    # descending past a recursive re-entry terminates
    _check("byPath.recursive", tree.by_path("DEMO/related").recursive is True)
    _check("byPath.recursive.past", tree.by_path("DEMO/related/INSC") is None)

    # dangling paths and foreign roots return None
    _check("byPath.empty", tree.by_path("") is None)
    _check("byPath.other", tree.by_path("OTHER") is None)
    _check("byPath.missing", tree.by_path("DEMO/missing") is None)
    _check(
        "byPath.pastLeaf", tree.by_path("DEMO/INSC/summary/deeper") is None
    )
    _check(
        "byPath.itemMissing",
        tree.by_path("DEMO/INSC/GOAL/GOAL-ITEM-LST-2/missing") is None,
    )

    # byId and byPath agree on the node they address (DR1 §4.2)
    _check("agree.insc", tree.by_id("INSC") is tree.by_path("DEMO/INSC"))
    _check(
        "agree.list",
        tree.by_id("GOAL-ITEM-LST")
        is tree.by_path("DEMO/INSC/GOAL/GOAL-ITEM-LST"),
    )
    _check(
        "agree.item",
        tree.by_id("GOAL-ITEM-1")
        is tree.by_path("DEMO/INSC/GOAL/GOAL-ITEM-LST-1"),
    )


def test_item_path() -> None:
    tree = build_fixture_tree()

    # builds `<listPath>-<seq>` for a statically placed list
    entries = tree.by_id("GOAL-ITEM-LST")
    _check(
        "itemPath.build",
        entries.item_path(2) == "DEMO/INSC/GOAL/GOAL-ITEM-LST-2",
        entries.item_path(2),
    )
    _check(
        "itemPath.resolves",
        tree.by_path(entries.item_path(2)).class_name == "GoalEntry",
    )

    # rejects non-list nodes and lists inside element subtrees
    _check(
        "itemPath.nonList",
        _raises(lambda: tree.by_id("INSC").item_path(1), RuntimeError),
    )
    nested = tree.by_id("GOAL-ITEM-LST").element_node.child_by_member(
        "subTasks"
    )
    _check(
        "itemPath.nestedList",
        _raises(lambda: nested.item_path(1), RuntimeError),
    )


def main() -> int:
    test_wiring()
    test_metadata_slots()
    test_by_id()
    test_by_path()
    test_item_path()

    total = _passed + len(_failed)
    if _failed:
        print(f"FAIL: {len(_failed)}/{total} checks failed")
        for f in _failed:
            print(f"  - {f}")
        return 1
    print(f"OK: {total} checks passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
