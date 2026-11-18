#!/usr/bin/env python3
"""TomSpecs sample — a Phase 4 CodeSpecs run, as far as the Python runtime goes.

The Python port of ``../bin/phase4_codespecs_run.dart``. Phase 4 has four
stages, and the Python runtime carries the first two:

  stage 1  the starting prompt's quality gate   [MECHANICAL]  here
  stage 2  the extract generator                [MECHANICAL]  here
  stage 3  the authoring agent                  [JUDGMENT]    the IR, Dart tools
  stage 4  validating the emitted trio          [MECHANICAL]  Dart tools

Stages 3 and 4 run on the Dart tools (``tomspecs :ir-map``,
``tomspecs :codespecs-validate``); the Dart sample shows them. This port runs
the same specification through the gate and the extract generator in Python,
and its extracts are the ones the Dart sample writes (``CodeSpecsExtract`` is
in all nine runtimes, byte for byte the same).

Run (from this folder; see README.md for the install)::

    python3 main.py
"""

from __future__ import annotations

import datetime as _dt
import json
import os
import sys
from typing import List

from tom_som_runtime import (
    CodeSpecsAreaCatalog,
    CodeSpecsExtract,
    CodeSpecsGate,
    CodeSpecsGateCheck,
    CodeSpecsGateReport,
    DocSpecsSchema,
    SpecDocument,
    SpecModel,
)
from tom_som_python_v0 import D00SolutionBlueprint
from tom_som_python_v0_data import schemas_root, spec_model

#: The one ``@Document`` root this run extracts from (codespecs_prompt.md §5).
_K_ROOT = "D00SolutionBlueprint"

#: The creation date section-id generation is pinned to, so the ids (and with
#: them ``expected_output.txt``) do not change with the calendar.
_K_AUTHORED_ON = _dt.date(2026, 1, 1)

_HERE = os.path.dirname(os.path.abspath(__file__))

#: The 27-area catalogue (codespecs_mapping.md §4.1 + §4.4.3 + §4.4.6). The
#: Dart package ``tom_specs_model`` ships it with an accessor; the Python
#: runtime has none, so the source install reads it from the checkout.
_CATALOG = os.path.normpath(os.path.join(
    _HERE, "..", "..", "..", "tom_specs_model", "generated-doc", "codespecs",
    "codespecs_areas.json"))


def main() -> int:
    inputs = _Inputs.load()

    _rule("A Phase 4 CodeSpecs run, stage by stage")
    print("Every step is marked [MECHANICAL] or [JUDGMENT].")
    print("")

    extracts = _variant_a(inputs)
    _variant_b(inputs)

    print("")
    print(f"Extracts written to build/codespecs_extracts/ ({len(extracts) * 2} files).")
    return 0


# ---------------------------------------------------------------------------
# Variant A — a document that passes, taken as far as the extracts.
# ---------------------------------------------------------------------------


def _variant_a(inputs: "_Inputs") -> List[CodeSpecsExtract]:
    doc = SpecDocument()
    _author_specification(D00SolutionBlueprint(doc), aggregate_roots=True)

    _rule("Variant A — a sufficient specification")
    print("0. The document under Phase 4                 [input]")
    print("   a Solution Blueprint whose information model holds 2 entities")
    print("   and 4 stored attributes; every other section is unwritten.")
    print("")

    gate = _run_gate(inputs, doc)
    if not gate.passed:
        print("variant A was supposed to pass the gate", file=sys.stderr)
        for f in gate.findings:
            print(f"  {f}", file=sys.stderr)
        raise SystemExit(1)
    print("   gate verdict             : PASS — the run may begin")
    print("")

    extracts = gate.extracts
    _stage2(extracts)
    _stages3and4()
    return extracts


# ---------------------------------------------------------------------------
# Variant B — the same document with one required field cleared.
# ---------------------------------------------------------------------------


def _variant_b(inputs: "_Inputs") -> None:
    doc = SpecDocument()
    _author_specification(D00SolutionBlueprint(doc), aggregate_roots=False)

    _rule("Variant B — the same document, one required field cleared")
    print("Both entities keep their `DAENT-CLAS` section and its `category`, and")
    print("both have `aggregateRoot` cleared. Nothing else changed.")
    print("")

    gate = _run_gate(inputs, doc)
    if gate.passed:
        print("variant B was supposed to be rejected", file=sys.stderr)
        raise SystemExit(1)
    print("   gate verdict             : REJECTED — the run may not begin")
    print("")
    print("   What the gate names, per finding:")
    for f in gate.findings:
        print(f"     {f.check.label} {f.code} [{f.location}] {f.message}")
    print("")
    a2 = len(gate[CodeSpecsGateCheck.A2].findings)
    print(f"   A2 moved too: {a2} violations, against 0 for variant A. The")
    print("   classification form still holds other values, so its empty")
    print("   required field is reported by both tiers. They part where a value")
    print("   is absent rather than empty: a missing required section is seen by")
    print("   A1 alone. That is why the gate runs both tiers and not either one")
    print("   (codespecs_prompt.md §4.1/§4.2 and its §10.1/§10.2 fixtures).")
    print("")


# ---------------------------------------------------------------------------
# Stage 1 — the mechanical gate (codespecs_prompt.md §4).
# ---------------------------------------------------------------------------

_TITLES = {
    CodeSpecsGateCheck.A1: "schema completeness  ",
    CodeSpecsGateCheck.A2: "instance-tier values ",
    CodeSpecsGateCheck.A3: "routing totality     ",
    CodeSpecsGateCheck.A4: "required arguments   ",
    CodeSpecsGateCheck.A5: "structured carriers  ",
}


def _run_gate(inputs: "_Inputs", doc: SpecDocument) -> CodeSpecsGateReport:
    """Runs the mechanical tier over *doc* and prints each check's verdict. All
    five checks run as one gate and none stops the others; a check that could
    not run says so, and the gate does not pass."""
    print("1. The starting prompt's quality gate        [MECHANICAL]")
    report = CodeSpecsGate(
        model=inputs.model,
        document=doc,
        catalog=inputs.catalog,
        schema=inputs.schema,
        root_type=_K_ROOT,
    ).run()
    for r in report.results:
        if not r.ran:
            verdict = f"NOT RUN — {r.not_run_reason}"
        elif not r.findings:
            verdict = "pass — 0 findings"
        else:
            verdict = f"FAIL — {len(r.findings)} findings"
        print(f"   {r.check.label} {_TITLES[r.check]}: {verdict}")
    print(f"   (A4 held {len(inputs.catalog.required_arguments)} required-argument "
          f"rows, A5 {len(inputs.catalog.carriers)} carriers, both from the "
          "catalogue's gate tables)")
    return report


# ---------------------------------------------------------------------------
# Stage 2 — the extract generator.
# ---------------------------------------------------------------------------


def _stage2(extracts: List[CodeSpecsExtract]) -> None:
    print("2. The extract generator                      [MECHANICAL]")
    populated = [e for e in extracts if e.entries]
    print(f"   areas in the catalogue   : {len(extracts)}")
    print(f"   populated                : {len(populated)}")
    for e in populated:
        print(f"     {e.area.code.ljust(6)} {len(e.entries)} entries  "
              f"→ {', '.join(e.projects)}")
    print(f"   empty                    : {len(extracts) - len(populated)}")
    print("   Most areas are empty because this document says nothing about")
    print("   screens, jobs, reports or migrations. An empty extract is a")
    print('   CANDIDATE for "not applicable" — never the verdict itself, which')
    print("   is a judgment and belongs to stage B (codespecs_prompt.md §6.4).")

    out = os.path.join("build", "codespecs_extracts")
    os.makedirs(out, exist_ok=True)
    for e in extracts:
        _write(os.path.join(out, f"{e.file_stem}.yaml"), e.to_yaml())
        _write(os.path.join(out, f"{e.file_stem}.md"), e.to_markdown())
    print("")

    db = next(e for e in extracts if e.area.code == "CE-DB")
    print(f"   Area {db.area.code} — {db.area.canonical_id}, the extract the")
    print("   authoring agent reads in stage 3:")
    print(f"   built on   : {db.area.built_on}")
    print(f"   may cite   : {', '.join(db.citable_parts)}")
    print(f"   entries carried to the agent ({len(db.entries)}):")
    for entry in db.entries:
        print(f"     {entry.section_id.ljust(11)} {entry.field_name.ljust(14)} "
              f"{_short(entry.value)}")
    print("")


def _stages3and4() -> None:
    print("3. The authoring agent                        [JUDGMENT]")
    print("4. Validating the emitted trio                [MECHANICAL]")
    print("   Not in the Python runtime. The authoring agent writes the IR from")
    print("   these extracts, and the Dart tools map and validate it")
    print("   (`tomspecs :ir-map`, `tomspecs :codespecs-validate`); the Dart")
    print("   sample in ../bin/ shows both stages on this same specification.")
    print("")


# ---------------------------------------------------------------------------
# The specification — the one the Dart sample authors.
# ---------------------------------------------------------------------------


def _author_specification(sbp: D00SolutionBlueprint, *, aggregate_roots: bool) -> None:
    """Two entities, four attributes and their keys: one area populated and
    the rest empty. *aggregate_roots* ``False`` clears the one required field
    variant B removes — ``DAENT-CLAS.aggregateRoot`` — and nothing else."""
    sbp.content = "Order intake for a single region."

    # The bounded context CE-SU's required `boundedContext` argument resolves
    # against: an unauthored registry would make the reference dangle at A2.
    ordering = (sbp.solutionArchitectureAndTechnology.technicalFramework
                .softwareDesign.layeringAndModuleStructure.boundedContexts
                .add(date=_K_AUTHORED_ON))
    ordering.spec_headline = "Ordering"
    ordering.content.contextName = "Ordering"
    ordering.content.domainArea = "Order management"

    entities = sbp.informationAndDataModel.dataModel.entities

    customer = entities.add(date=_K_AUTHORED_ON)
    customer.spec_headline = "Customer"
    customer.content = "A party that places orders."
    identity = customer.identity
    identity.entityName = "Customer"
    identity.tableName = "customers"
    identity.entityAlias = "CUST"
    identity.description = "A person or organisation that places orders."
    customer.classification.category = "MasterData"
    customer.classification.boundedContext = "Ordering"
    if aggregate_roots:
        customer.classification.aggregateRoot = "Customer"

    email = customer.attributes.add(date=_K_AUTHORED_ON)
    email.spec_headline = "email"
    email.identity.columnName = "email"
    email.identity.description = "The address order confirmations are sent to."
    email.dataTypeSpec.physicalType = "VARCHAR"

    display_name = customer.attributes.add(date=_K_AUTHORED_ON)
    display_name.spec_headline = "displayName"
    display_name.identity.columnName = "display_name"
    display_name.identity.description = "The name the customer trades under."
    display_name.dataTypeSpec.physicalType = "VARCHAR"

    # A customer is identified by the address it trades under: a natural key.
    customer_key = customer.keyAttributes.add(date=_K_AUTHORED_ON)
    customer_key.spec_headline = "pk_customers"
    customer_key.content.keyType = "Natural"
    customer_key.content.keyColumns = "email"
    customer_key.content.description = "A customer is identified by its e-mail address."

    order = entities.add(date=_K_AUTHORED_ON)
    order.spec_headline = "Order"
    order.content = "One accepted customer order."
    identity = order.identity
    identity.entityName = "Order"
    identity.tableName = "orders"
    identity.entityAlias = "ORD"
    identity.description = "A single order placed by a customer."
    order.classification.category = "TransactionData"
    order.classification.boundedContext = "Ordering"
    if aggregate_roots:
        order.classification.aggregateRoot = "Order"

    order_id = order.attributes.add(date=_K_AUTHORED_ON)
    order_id.spec_headline = "orderId"
    order_id.identity.columnName = "order_id"
    order_id.identity.description = "The identifier the order is filed under."
    order_id.dataTypeSpec.physicalType = "UUID"

    order_key = order.keyAttributes.add(date=_K_AUTHORED_ON)
    order_key.spec_headline = "pk_orders"
    order_key.content.keyType = "Primary"
    order_key.content.keyColumns = "order_id"
    order_key.content.description = "The order identifier."
    order_key.generation.generationStrategy = "UUID"

    placed_at = order.attributes.add(date=_K_AUTHORED_ON)
    placed_at.spec_headline = "placedAt"
    placed_at.identity.columnName = "placed_at"
    placed_at.identity.description = "The moment the order was accepted."
    placed_at.dataTypeSpec.physicalType = "TIMESTAMP"


# ---------------------------------------------------------------------------
# Helpers.
# ---------------------------------------------------------------------------


def _short(value: str) -> str:
    return value if len(value) <= 44 else value[:41] + "..."


def _rule(title: str) -> None:
    print("=" * 72)
    print(title)
    print("=" * 72)


def _write(path: str, text: str) -> None:
    with open(path, "w", encoding="utf-8") as f:
        f.write(text)


class _Inputs:
    """The three data inputs a Phase 4 run needs."""

    def __init__(self, model: SpecModel, schema: DocSpecsSchema,
                 catalog: CodeSpecsAreaCatalog) -> None:
        #: The resolved object model — ``to_markdown`` and the A2 validator take it.
        self.model = model
        #: The DocSpecs schema A1 checks the markdown rendition against.
        self.schema = schema
        #: The 27-area catalogue the extractor walks.
        self.catalog = catalog

    @staticmethod
    def load() -> "_Inputs":
        schema_path = os.path.join(schemas_root(), "solution-blueprint",
                                   "solution-blueprint.1.0.docspecs-schema.yaml")
        with open(schema_path, encoding="utf-8") as f:
            schema = DocSpecsSchema.from_yaml_text(f.read())
        with open(_CATALOG, encoding="utf-8") as f:
            catalog = CodeSpecsAreaCatalog.from_json(json.load(f))
        return _Inputs(spec_model(), schema, catalog)


if __name__ == "__main__":
    raise SystemExit(main())
