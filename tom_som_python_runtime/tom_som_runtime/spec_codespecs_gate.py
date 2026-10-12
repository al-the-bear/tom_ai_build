"""The Phase-4 mechanical gate — Stage A of `codespecs_prompt.md` §4, all five
checks run as one, over (model, document, catalogue, schema) — a port of
``tom_som_dart_runtime/lib/src/spec_codespecs_gate.dart``.

Every check runs; none stops the others. A project fixing one wants to see the
rest, and a gate that stopped at the first failure would report a different set
of problems on every run (`codespecs_prompt.md` §4).

A check that could not run is reported as **not run**, with its reason, and the
gate does not pass: a skipped check must never read as a passed one.
"""

from __future__ import annotations

from dataclasses import dataclass, field as dataclass_field
from enum import Enum
from typing import Optional

from .docspecs_validator import DocSpecsSchema, DocSpecsValidator
from .spec_codespecs_extract import (
    CodeSpecsAreaCatalog,
    CodeSpecsExtract,
    CodeSpecsExtractError,
    CodeSpecsExtractor,
    CodeSpecsRoutingVerdict,
)
from .spec_document import SpecDocument
from .spec_model import SpecModel
from .spec_validator import validate_document


class CodeSpecsGateCheck(Enum):
    """The five Stage-A checks."""

    #: The document is complete against its DocSpecs schema.
    A1 = "a1"
    #: The document's values are valid (``validate_document``).
    A2 = "a2"
    #: Every section the walk reaches carries a routing verdict (ROUTE-TOTAL).
    A3 = "a3"
    #: Every required marker argument of a used area has a populated source.
    A4 = "a4"
    #: The model still offers every structured carrier.
    A5 = "a5"

    @property
    def label(self) -> str:
        """``A1`` … ``A5``, as `codespecs_prompt.md` §4 names them."""
        return self.value.upper()


@dataclass(frozen=True)
class CodeSpecsGateFinding:
    """One thing a check found wrong."""

    #: The check that found it.
    check: CodeSpecsGateCheck
    #: What kind of finding — the DocSpecs rule (A1), the validation code (A2),
    #: ``unrouted`` / ``root`` (A3), ``missingSource`` /
    #: ``unresolvedReference`` (A4), ``missingCarrier`` (A5).
    code: str
    #: Where: a section id or document path (A1–A4), or the carrier
    #: ``Class.member[.formField]`` (A5).
    location: str
    #: One sentence a user acts on.
    message: str

    def __str__(self) -> str:
        return f"{self.check.label} {self.code} {self.location}: {self.message}"


@dataclass(frozen=True)
class CodeSpecsGateCheckResult:
    """One check's outcome."""

    #: Which check.
    check: CodeSpecsGateCheck
    #: Whether it ran. A check that did not run never passes.
    ran: bool = True
    #: Why it did not run; ``None`` when it ran.
    not_run_reason: Optional[str] = None
    #: What it found, in the order found.
    findings: list[CodeSpecsGateFinding] = dataclass_field(default_factory=list)

    @property
    def passed(self) -> bool:
        """Ran and found nothing."""
        return self.ran and not self.findings


@dataclass(frozen=True)
class CodeSpecsGateReport:
    """The gate's report: one result per check, A1 to A5."""

    #: The five results, in check order.
    results: list[CodeSpecsGateCheckResult]
    #: The extraction run's extracts, when A3 passed (A4 reads them; Stage B is
    #: handed them). ``None`` when the walk could not complete.
    extracts: Optional[list[CodeSpecsExtract]]

    def __getitem__(self, check: CodeSpecsGateCheck) -> CodeSpecsGateCheckResult:
        """The result of *check*."""
        for r in self.results:
            if r.check == check:
                return r
        raise KeyError(check)

    def result_for(self, check: CodeSpecsGateCheck) -> CodeSpecsGateCheckResult:
        """The result of *check* (same as ``report[check]``)."""
        return self[check]

    @property
    def passed(self) -> bool:
        """Every check ran and found nothing — the run may begin."""
        return all(r.passed for r in self.results)

    @property
    def findings(self) -> list[CodeSpecsGateFinding]:
        """Every finding, in check order."""
        return [f for r in self.results for f in r.findings]


_NO_TABLES_REASON = (
    "the catalogue carries no gate tables (written before "
    "`codespecs_prompt.md` §4.4/§4.5 were transcribed)"
)

_NO_EXTRACTS_REASON = (
    "A3 did not complete, so there is no extraction run to read "
    "the used areas from"
)


class CodeSpecsGate:
    """Stage A of `codespecs_prompt.md` §4."""

    def __init__(
        self,
        model: SpecModel,
        document: SpecDocument,
        catalog: CodeSpecsAreaCatalog,
        schema: Optional[DocSpecsSchema] = None,
        root_type: Optional[str] = None,
    ) -> None:
        """Holds the inputs; :meth:`run` does the work.

        *schema* is the DocSpecs schema of the document's root; A1 does not
        run without it. *root_type* is the document root to walk — type name
        or section id; defaults to the document's single populated root, as
        the extractor does."""
        #: The resolved object model.
        self.model = model
        #: The document under Phase 4.
        self.document = document
        #: The area catalogue — its ``gate`` tables drive A4 and A5.
        self.catalog = catalog
        #: The DocSpecs schema of the document's root.
        self.schema = schema
        #: The document root to walk.
        self.root_type = root_type

    def run(self) -> CodeSpecsGateReport:
        """Runs all five checks."""
        a1 = self._a1()
        a2 = self._a2()
        a3, extracts = self._a3()
        if not self.catalog.has_gate_tables:
            a4 = self._no_tables(CodeSpecsGateCheck.A4)
        elif extracts is None:
            a4 = CodeSpecsGateCheckResult(
                check=CodeSpecsGateCheck.A4,
                ran=False,
                not_run_reason=_NO_EXTRACTS_REASON,
            )
        else:
            a4 = self._a4(extracts)
        a5 = (
            self._a5()
            if self.catalog.has_gate_tables
            else self._no_tables(CodeSpecsGateCheck.A5)
        )
        return CodeSpecsGateReport([a1, a2, a3, a4, a5], extracts)

    @staticmethod
    def _no_tables(check: CodeSpecsGateCheck) -> CodeSpecsGateCheckResult:
        return CodeSpecsGateCheckResult(
            check=check, ran=False, not_run_reason=_NO_TABLES_REASON
        )

    def _a1(self) -> CodeSpecsGateCheckResult:
        if self.schema is None:
            return CodeSpecsGateCheckResult(
                check=CodeSpecsGateCheck.A1,
                ran=False,
                not_run_reason="no DocSpecs schema was supplied",
            )
        markdown = self.document.to_markdown(self.model, root_type=self.root_type)
        return CodeSpecsGateCheckResult(
            check=CodeSpecsGateCheck.A1,
            findings=[
                CodeSpecsGateFinding(
                    check=CodeSpecsGateCheck.A1,
                    code=v.rule.value,
                    location=(
                        v.section_id
                        if v.section_id is not None
                        else v.path
                        if v.path is not None
                        else f"line {v.line}"
                    ),
                    message=f"line {v.line}: {v.message}",
                )
                for v in DocSpecsValidator(self.schema).validate_markdown(markdown)
            ],
        )

    def _a2(self) -> CodeSpecsGateCheckResult:
        return CodeSpecsGateCheckResult(
            check=CodeSpecsGateCheck.A2,
            findings=[
                CodeSpecsGateFinding(
                    check=CodeSpecsGateCheck.A2,
                    code=e.code.value,
                    location=e.path,
                    message=e.message,
                )
                for e in validate_document(self.model, self.document)
            ],
        )

    def _a3(
        self,
    ) -> tuple[CodeSpecsGateCheckResult, Optional[list[CodeSpecsExtract]]]:
        """A3 collects **every** unrouted class over the non-strict walk,
        rather than the first one the strict walk raises on; only when there
        is none does it run the extraction itself."""
        try:
            extractor = CodeSpecsExtractor(
                model=self.model,
                document=self.document,
                catalog=self.catalog,
                root_type=self.root_type,
            )
        except CodeSpecsExtractError as e:
            return (
                CodeSpecsGateCheckResult(
                    check=CodeSpecsGateCheck.A3,
                    findings=[
                        CodeSpecsGateFinding(
                            check=CodeSpecsGateCheck.A3,
                            code="root",
                            location=e.path,
                            message=e.message,
                        )
                    ],
                ),
                None,
            )
        unrouted = [
            CodeSpecsGateFinding(
                check=CodeSpecsGateCheck.A3,
                code="unrouted",
                location=r.path,
                message=f"{r.class_name} carries no @CodeSpecKind, @FollowUpKind "
                "or @NoArtifact — its content would reach no extract",
            )
            for r in extractor.routings()
            if r.verdict == CodeSpecsRoutingVerdict.UNROUTED
        ]
        if unrouted:
            return (
                CodeSpecsGateCheckResult(
                    check=CodeSpecsGateCheck.A3, findings=unrouted
                ),
                None,
            )
        return (
            CodeSpecsGateCheckResult(check=CodeSpecsGateCheck.A3),
            extractor.extract_all(),
        )

    def _a4(self, extracts: list[CodeSpecsExtract]) -> CodeSpecsGateCheckResult:
        """A4 over the extraction run: for each obligation whose area's
        extract is non-empty, every instance of the obligation's class that
        the extract carries must carry the source value, populated
        (non-blank); a ``resolves_to`` obligation's value must also equal a
        value the run carries at the target."""
        findings: list[CodeSpecsGateFinding] = []
        all_entries = [e for x in extracts for e in x.entries]
        for o in self.catalog.required_arguments:
            extract = next((x for x in extracts if x.area.code == o.area), None)
            if extract is None or not extract.entries:
                continue
            # The instances the extract carries of the obligation's class, in
            # document order, each with the populated source value it holds.
            instances: dict[str, Optional[str]] = {}
            applies: set[str] = set()
            when = o.when
            for e in extract.entries:
                if e.class_name != o.class_name:
                    continue
                instance = _parent_path(e.path)
                instances.setdefault(instance, None)
                if (
                    when is not None
                    and e.field_name == when.member
                    and e.form_field == when.form_field
                    and e.value == o.when_equals
                ):
                    applies.add(instance)
                if (
                    e.field_name == o.member
                    and e.form_field == o.form_field
                    and e.value.strip() != ""
                ):
                    instances[instance] = e.value
            for instance, value in instances.items():
                if when is not None and instance not in applies:
                    continue
                if value is None:
                    findings.append(
                        CodeSpecsGateFinding(
                            check=CodeSpecsGateCheck.A4,
                            code="missingSource",
                            location=instance,
                            message=f"{o.marker}.{o.argument} ({o.area}) is "
                            f"required, and its source {o.source} is empty here",
                        )
                    )
                    continue
                target = o.resolves_to
                if target is None:
                    continue
                known = any(
                    e.class_name == target.class_name
                    and e.field_name == target.member
                    and e.form_field == target.form_field
                    and e.value == value
                    for e in all_entries
                )
                if not known:
                    findings.append(
                        CodeSpecsGateFinding(
                            check=CodeSpecsGateCheck.A4,
                            code="unresolvedReference",
                            location=instance,
                            message=f"{o.source} names `{value}`, which no "
                            f"{target.source} in this document carries — "
                            f"{o.marker}.{o.argument} ({o.area}) has nothing "
                            "to resolve against",
                        )
                    )
        return CodeSpecsGateCheckResult(check=CodeSpecsGateCheck.A4, findings=findings)

    def _a5(self) -> CodeSpecsGateCheckResult:
        """A5 against the model, not the document: each carrier's class,
        member and form field must still exist."""
        findings: list[CodeSpecsGateFinding] = []
        for c in self.catalog.carriers:
            cls = self.model.class_named(c.class_name)
            fld = None if cls is None else cls.field_named(c.member)
            present = fld is not None and (
                c.form_field is None
                or any(f.name == c.form_field for f in fld.form_fields)
            )
            if not present:
                findings.append(
                    CodeSpecsGateFinding(
                        check=CodeSpecsGateCheck.A5,
                        code="missingCarrier",
                        location=c.source,
                        message=f"the model no longer offers {c.source} "
                        f"({c.introduced_by}) — a project with that structured "
                        "fact would have to write prose again",
                    )
                )
        return CodeSpecsGateCheckResult(check=CodeSpecsGateCheck.A5, findings=findings)


def _parent_path(path: str) -> str:
    i = path.rfind("/")
    return "" if i < 0 else path[:i]

