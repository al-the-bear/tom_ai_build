"""Reading back what a Phase-4 run wrote: the per-area **extract** files and
the Stage-B **gate record** (`codespecs_mapping.md` §1.1.1,
`codespecs_prompt.md` §6.3) — a faithful port of
``tom_som_dart_runtime/lib/src/spec_codespecs_records.dart``.

The extractor (:class:`CodeSpecsExtractor`) writes ``<CE-CODE>.extract.yaml``;
this module is the other half, so a consumer that did not run the extractor —
a validator, an editor tool, an agent asking which areas are in scope — reads
the files with the same rules everywhere instead of re-deriving the shape. The
gate record has a writer here too, because it is otherwise written by hand and
only checked when something reads it.

Both readers **refuse** an unknown ``formatVersion``: a later format that moved
a key would otherwise read as an extract with no entries, or a scope with no
verdicts, and a check with no input passes.

The YAML is read with PyYAML (the parser the docspecs YAML load path uses),
through a loader narrowed to YAML 1.2's core schema for booleans and
timestamps and refusing duplicate keys — the reading Dart's ``package:yaml``
gives, so ``verdict: no`` stays a string here as it does there.
"""

from __future__ import annotations

import os
import re
from dataclasses import dataclass
from enum import Enum
from typing import Any, Iterable, Optional, Union

from .spec_codespecs_extract import (
    K_CODE_SPECS_EXTRACT_FORMAT,
    CodeSpecsArea,
    CodeSpecsAreaCatalog,
    CodeSpecsExtract,
    CodeSpecsExtractEntry,
    _yaml_string,
)

try:  # PyYAML is the parser the docspecs YAML load path uses.
    import yaml as _yaml
except ImportError:  # pragma: no cover - surfaced clearly at call sites.
    _yaml = None  # type: ignore[assignment]

#: The file name of the gate record, written beside the extracts. Fixed so a
#: partial pass cannot hide its record under a name no reader looks for.
K_CODE_SPECS_GATE_RECORD_FILE = "gate.verdicts.yaml"

#: The gate record ``formatVersion`` this runtime reads and writes.
K_CODE_SPECS_GATE_RECORD_FORMAT = 1

#: The suffix every extract artifact of record carries.
K_CODE_SPECS_EXTRACT_FILE_SUFFIX = ".extract.yaml"

#: The one resolution a gate record may carry: an insufficient area the user
#: decided to leave out.
K_CODE_SPECS_GATE_DESCOPED = "descoped"

_AREA_CODE_PATTERN = re.compile(r"CE-[A-Z]+")


class CodeSpecsRecordError(Exception):
    """A malformed or unreadable extract file or gate record."""

    def __init__(self, message: str) -> None:
        super().__init__(message)
        #: What is wrong, naming the file it was read from.
        self.message = message

    def __str__(self) -> str:
        return f"CodeSpecsRecordError: {self.message}"


# ---------------------------------------------------------------------------
# Extract files
# ---------------------------------------------------------------------------


def parse_code_specs_extract_yaml(text: str, source: str = "") -> CodeSpecsExtract:
    """Parses one ``<CE-CODE>.extract.yaml``. *source* names the file in errors.

    Only ``extract.formatVersion`` and ``extract.area.code`` are required; any
    other absent key reads as empty (a string as ``''``, a list as ``[]``), so
    a hand-written fixture stays readable. A key that is present with the wrong
    type is an error, and so is a ``document.entryCount`` that disagrees with
    the entries — a truncated file would otherwise read as a complete one.

    The inverse of :meth:`CodeSpecsExtract.to_yaml`: for any extract the
    extractor wrote, ``parse(x.to_yaml()).to_yaml() == x.to_yaml()``.
    """
    name = "the extract" if source == "" else source
    root = _root_mapping(text, name, "extract")
    version = root.get("formatVersion")
    if not _num_equals(version, K_CODE_SPECS_EXTRACT_FORMAT):
        raise CodeSpecsRecordError(
            f"{name} declares extract format {_show(version)}; this reader "
            f"understands {K_CODE_SPECS_EXTRACT_FORMAT} only — reading it "
            f"would silently drop entries"
        )
    area = root.get("area")
    if not isinstance(area, dict):
        raise CodeSpecsRecordError(f"{name} has no `area:` mapping")
    code = _str(area.get("code"), name, "area.code")
    if code == "":
        raise CodeSpecsRecordError(f"{name} names no area code")
    part = _str(area.get("part"), name, "area.part")
    if part.startswith("CodeSpecPart."):
        part = part[len("CodeSpecPart."):]
    document_node = root.get("document")
    if document_node is not None and not isinstance(document_node, dict):
        raise CodeSpecsRecordError(f"{name}: `document` must be a mapping")
    entries_node = root.get("entries")
    if entries_node is not None and not isinstance(entries_node, list):
        raise CodeSpecsRecordError(f"{name}: `entries` must be a list")
    entries: list[CodeSpecsExtractEntry] = []
    for raw in entries_node or []:
        if not isinstance(raw, dict):
            raise CodeSpecsRecordError(f"{name} has an entry that is not a mapping")

        def req(key: str, raw: dict = raw) -> str:
            return _str(raw.get(key), name, f"entries[].{key}")

        def opt(key: str, raw: dict = raw) -> Optional[str]:
            return _opt_str(raw.get(key), name, f"entries[].{key}")

        entries.append(
            CodeSpecsExtractEntry(
                area_code=code,
                section_id=req("sectionId"),
                headline=opt("headline"),
                instance_id=opt("instanceId"),
                path=req("path"),
                class_name=req("className"),
                field_name=req("fieldName"),
                form_field=opt("formField"),
                routed_by=req("routedBy"),
                routed_at=req("routedAt"),
                routing_note=opt("routingNote"),
                value=req("value"),
            )
        )
    declared = None if document_node is None else document_node.get("entryCount")
    if declared is not None and not _num_equals(declared, len(entries)):
        raise CodeSpecsRecordError(
            f"{name} declares entryCount {_show(declared)} but carries "
            f"{len(entries)} entries — a truncated extract must not read as a "
            f"complete one"
        )
    return CodeSpecsExtract(
        area=CodeSpecsArea(
            code=code,
            canonical_id=_str(area.get("canonicalId"), name, "area.canonicalId"),
            part=part,
            annotations=_str_list(area.get("annotations"), name, "area.annotations"),
            built_on=_str(area.get("builtOn"), name, "area.builtOn"),
            attribute_surface=_str(
                area.get("attributeSurface"), name, "area.attributeSurface"
            ),
            slices=_int_list(area.get("slices"), name, "area.slices"),
            authoring_steps=_int_list(
                area.get("authoringSteps"), name, "area.authoringSteps"
            ),
        ),
        document_root=_str(
            None if document_node is None else document_node.get("root"),
            name,
            "document.root",
        ),
        catalog_source=_str(root.get("catalogSource"), name, "catalogSource"),
        projects=_str_list(area.get("projects"), name, "area.projects"),
        citable_parts=_str_list(area.get("citableParts"), name, "area.citableParts"),
        entries=entries,
    )


def _extract_from_yaml(text: str, source: str = "") -> CodeSpecsExtract:
    return parse_code_specs_extract_yaml(text, source)


# `CodeSpecsExtract.from_yaml(text, source)` — the inverse of `to_yaml`, as the
# Dart reference exposes it on the class.
CodeSpecsExtract.from_yaml = staticmethod(_extract_from_yaml)  # type: ignore[attr-defined]


# ---------------------------------------------------------------------------
# The gate record
# ---------------------------------------------------------------------------


class CodeSpecsGateVerdict(Enum):
    """One of `codespecs_prompt.md` §6.2's three per-area verdicts. The value
    is the verdict word exactly as §6.2 states it."""

    #: The extract carries every input the derivation contract requires.
    SUFFICIENT = "sufficient"
    #: The area does not apply — nothing was routed, with positive evidence of
    #: absence (`codespecs_prompt.md` §6.4).
    NOT_APPLICABLE = "not applicable"
    #: The extract is missing required inputs; only a recorded descope lets a
    #: run continue without the area.
    INSUFFICIENT = "insufficient"

    @property
    def word(self) -> str:
        """The verdict word exactly as `codespecs_prompt.md` §6.2 states it."""
        return self.value

    @staticmethod
    def parse(word: str) -> Optional["CodeSpecsGateVerdict"]:
        """The verdict for *word*, or ``None`` for a word §6.2 does not know."""
        for v in CodeSpecsGateVerdict:
            if v.value == word:
                return v
        return None


@dataclass(frozen=True)
class CodeSpecsGateEntry:
    """One area's recorded verdict. Shape is checked by
    :class:`CodeSpecsGateRecord`, which is the only thing that reads or writes
    entries."""

    #: The area's ``CE-*`` code.
    area: str
    #: The verdict.
    verdict: CodeSpecsGateVerdict
    #: ``descoped``, on an insufficient area only; otherwise ``None``.
    resolution: Optional[str] = None
    #: A free-text note — why the verdict was taken. Never read as data.
    note: Optional[str] = None

    @property
    def descoped(self) -> bool:
        """Whether this is an insufficient area resolved by descoping."""
        return self.resolution == K_CODE_SPECS_GATE_DESCOPED


_GATE_ENTRY_KEYS = ("area", "verdict", "resolution", "note")


class CodeSpecsGateRecord:
    """The Stage-B gate record, ``gate.verdicts.yaml``
    (`codespecs_prompt.md` §6.3).

    Constructing one checks it: every area is a ``CE-*`` code named once, and
    a ``resolution:`` appears only as ``descoped`` on an insufficient area. So
    a record that exists is a record of the checked shape, whether it was read
    or built to be written."""

    def __init__(
        self,
        verdicts: Iterable[CodeSpecsGateEntry],
        source: str = K_CODE_SPECS_GATE_RECORD_FILE,
    ) -> None:
        #: The verdicts, in the order they were recorded.
        self.verdicts: tuple[CodeSpecsGateEntry, ...] = tuple(verdicts)
        self._check(source)

    @staticmethod
    def from_yaml(
        text: str, source: str = K_CODE_SPECS_GATE_RECORD_FILE
    ) -> "CodeSpecsGateRecord":
        """Parses ``gate.verdicts.yaml``. *source* names the file in errors."""
        root = _root_mapping(text, source, "gate")
        for key in root:
            if key != "formatVersion" and key != "verdicts":
                raise CodeSpecsRecordError(
                    f"{source} has an unknown key `gate.{_show(key)}` — the "
                    f"record knows `formatVersion` and `verdicts` only"
                )
        version = root.get("formatVersion")
        if not _num_equals(version, K_CODE_SPECS_GATE_RECORD_FORMAT):
            raise CodeSpecsRecordError(
                f"{source} declares gate record format {_show(version)}; this "
                f"reader understands {K_CODE_SPECS_GATE_RECORD_FORMAT} only — "
                f"reading it would silently change the scope"
            )
        lst = root.get("verdicts")
        if not isinstance(lst, list):
            raise CodeSpecsRecordError(f"{source} has no `verdicts:` list")
        entries: list[CodeSpecsGateEntry] = []
        for raw in lst:
            if not isinstance(raw, dict):
                raise CodeSpecsRecordError(
                    f"{source} has a verdict that is not a mapping"
                )
            for key in raw:
                if key not in _GATE_ENTRY_KEYS:
                    raise CodeSpecsRecordError(
                        f"{source} has an unknown key `{_show(key)}` in a "
                        f"verdict — an entry knows `area`, `verdict`, "
                        f"`resolution` and `note` only"
                    )
            area = _str(raw.get("area"), source, "verdicts[].area")
            word = _str(raw.get("verdict"), source, "verdicts[].verdict")
            verdict = CodeSpecsGateVerdict.parse(word)
            if verdict is None:
                raise CodeSpecsRecordError(
                    f"{source} gives {area} the verdict `{word}` — "
                    f"codespecs_prompt.md §6.2 knows `sufficient`, "
                    f"`not applicable` and `insufficient` only"
                )
            entries.append(
                CodeSpecsGateEntry(
                    area=area,
                    verdict=verdict,
                    resolution=_opt_str(
                        raw.get("resolution"), source, "verdicts[].resolution"
                    ),
                    note=_opt_str(raw.get("note"), source, "verdicts[].note"),
                )
            )
        return CodeSpecsGateRecord(entries, source=source)

    def _check(self, source: str) -> None:
        seen: set[str] = set()
        for e in self.verdicts:
            if e.area == "":
                raise CodeSpecsRecordError(
                    f"{source} has a verdict that names no area"
                )
            if not _AREA_CODE_PATTERN.fullmatch(e.area):
                raise CodeSpecsRecordError(
                    f"{source} names the area `{e.area}`, which is not a CE-* code"
                )
            if e.area in seen:
                raise CodeSpecsRecordError(
                    f"{source} carries two verdicts for {e.area} — a scope with "
                    f"two answers for one area is no scope"
                )
            seen.add(e.area)
            resolution = e.resolution
            if resolution is None:
                continue
            if e.verdict is not CodeSpecsGateVerdict.INSUFFICIENT:
                raise CodeSpecsRecordError(
                    f"{source} gives {e.area} a `resolution:` on verdict "
                    f"`{e.verdict.word}` — only an insufficient area has an L0 "
                    f"decision to resolve"
                )
            if resolution != K_CODE_SPECS_GATE_DESCOPED:
                raise CodeSpecsRecordError(
                    f"{source} gives {e.area} the resolution `{resolution}` — "
                    f"`descoped` is the one resolution that admits a partial "
                    f"pass; any other resolution means the area was completed "
                    f"and its verdict re-taken"
                )

    def verdict_for(self, area: str) -> Optional[CodeSpecsGateEntry]:
        """The entry for *area*, or ``None`` when the record says nothing
        about it."""
        for e in self.verdicts:
            if e.area == area:
                return e
        return None

    def check_against(
        self,
        catalog: CodeSpecsAreaCatalog,
        source: str = K_CODE_SPECS_GATE_RECORD_FILE,
    ) -> None:
        """Raises :class:`CodeSpecsRecordError` when an area is not an active
        area of *catalog* — a verdict for an area that does not exist scopes
        nothing."""
        for e in self.verdicts:
            area = catalog.by_code(e.area)
            if area is None or not area.active:
                raise CodeSpecsRecordError(
                    f"{source} gives a verdict for {e.area}, which is not an "
                    f"active area of the catalogue"
                )

    def with_verdict(self, entry: CodeSpecsGateEntry) -> "CodeSpecsGateRecord":
        """A copy with *entry* recorded — replacing the area's earlier verdict
        in place, or appended when the area had none."""
        out: list[CodeSpecsGateEntry] = []
        replaced = False
        for e in self.verdicts:
            if e.area == entry.area:
                out.append(entry)
                replaced = True
            else:
                out.append(e)
        if not replaced:
            out.append(entry)
        return CodeSpecsGateRecord(out)

    def to_yaml(self) -> str:
        """The record as ``gate.verdicts.yaml``. Byte-stable: the same record
        always writes the same text, and
        ``from_yaml(r.to_yaml()).to_yaml() == r.to_yaml()``.

        ``area`` and ``verdict`` are written plain, as `codespecs_prompt.md`
        §6.3 shows them — both are from a closed vocabulary the constructor
        checked — and a note as a double-quoted scalar, the extract's one
        escaping rule."""
        lines = ["gate:", f"  formatVersion: {K_CODE_SPECS_GATE_RECORD_FORMAT}"]
        if not self.verdicts:
            lines.append("  verdicts: []")
            return "\n".join(lines) + "\n"
        lines.append("  verdicts:")
        for e in self.verdicts:
            lines.append(f"    - area: {e.area}")
            lines.append(f"      verdict: {e.verdict.word}")
            if e.resolution is not None:
                lines.append(f"      resolution: {e.resolution}")
            if e.note is not None:
                lines.append(f"      note: {_yaml_string(e.note)}")
        return "\n".join(lines) + "\n"


# ---------------------------------------------------------------------------
# A tree of extracts, scoped by its gate record
# ---------------------------------------------------------------------------


@dataclass(frozen=True)
class CodeSpecsExcludedArea:
    """One area the gate record left out of scope. Kept visible rather than
    dropped, so a consumer can say so: a scoped-out area must never read as a
    covered one."""

    #: The ``CE-*`` code.
    area: str
    #: ``NOT_APPLICABLE``, or ``INSUFFICIENT`` with a recorded descope.
    verdict: CodeSpecsGateVerdict
    #: Whether an insufficient verdict was resolved by descoping.
    descoped: bool = False
    #: How many routed entries the excluded extract carried (0 with no file).
    entry_count: int = 0
    #: The file the excluded extract was read from, or '' when there was none.
    source: str = ""


_Files = Union[dict, Iterable]


class CodeSpecsExtractSet:
    """Every extract one run produced, read back and scoped by its gate
    record."""

    def __init__(
        self,
        extracts: list[CodeSpecsExtract],
        sources: list[str],
        excluded: list[CodeSpecsExcludedArea],
        gate: Optional[CodeSpecsGateRecord],
    ) -> None:
        #: The in-scope extracts, in source order. With a gate record: the
        #: areas it marks ``sufficient``, in the record's order. Without:
        #: every extract.
        self.extracts: tuple[CodeSpecsExtract, ...] = tuple(extracts)
        #: The file each in-scope extract was read from, parallel to
        #: :attr:`extracts`.
        self.sources: tuple[str, ...] = tuple(sources)
        #: The areas the gate record excluded — empty without a record.
        self.excluded: tuple[CodeSpecsExcludedArea, ...] = tuple(excluded)
        #: The gate record, when one was among the sources.
        self.gate = gate

    @staticmethod
    def from_files(files: _Files) -> "CodeSpecsExtractSet":
        """Reads *files* — an ordered ``{name: text}`` dict or an ordered
        iterable of ``(name, text)`` pairs — into a scoped set.

        The file whose basename is :data:`K_CODE_SPECS_GATE_RECORD_FILE` is the
        gate record; every other file is an extract. The area code comes from
        the file's content, never its name. With a record, an area is in scope
        **iff** its verdict is ``sufficient``, and:

        * the record must carry a verdict for every extract supplied — a scope
          silent about an area would let a skipped area read as a passed one;
        * a ``not applicable`` area whose extract has entries is an error — a
          routed value is evidence the area applies (`codespecs_prompt.md`
          §6.4);
        * an ``insufficient`` area without ``resolution: descoped`` is an error
          — the run may not have continued past it (`codespecs_prompt.md`
          §6.2).

        Two extracts for one area, or two gate records, are errors.
        """
        pairs = list(files.items()) if isinstance(files, dict) else list(files)
        gate_name: Optional[str] = None
        gate_text = ""
        extracts: list[CodeSpecsExtract] = []
        sources: list[str] = []
        for file_name, text in pairs:
            basename = file_name.split("/")[-1]
            if basename == K_CODE_SPECS_GATE_RECORD_FILE:
                if gate_name is not None:
                    raise CodeSpecsRecordError(
                        f"both {gate_name} and {file_name} are gate records — "
                        f"the scope must have one author"
                    )
                gate_name = file_name
                gate_text = text
                continue
            x = parse_code_specs_extract_yaml(text, source=file_name)
            earlier = next(
                (i for i, e in enumerate(extracts) if e.area.code == x.area.code),
                -1,
            )
            if earlier >= 0:
                raise CodeSpecsRecordError(
                    f"{sources[earlier]} and {file_name} are both extracts for "
                    f"{x.area.code}"
                )
            extracts.append(x)
            sources.append(file_name)
        if gate_name is None:
            return CodeSpecsExtractSet(extracts, sources, [], None)
        gate = CodeSpecsGateRecord.from_yaml(gate_text, source=gate_name)
        for i, x in enumerate(extracts):
            if gate.verdict_for(x.area.code) is None:
                raise CodeSpecsRecordError(
                    f"{gate_name} carries no verdict for {x.area.code} "
                    f"({sources[i]}) — the gate record must be total over the "
                    f"supplied extracts"
                )
        in_scope: list[CodeSpecsExtract] = []
        in_scope_sources: list[str] = []
        excluded: list[CodeSpecsExcludedArea] = []
        for v in gate.verdicts:
            i = next(
                (j for j, e in enumerate(extracts) if e.area.code == v.area), -1
            )
            x = None if i < 0 else extracts[i]
            src = "" if i < 0 else sources[i]
            count = 0 if x is None else len(x.entries)
            if v.verdict is CodeSpecsGateVerdict.SUFFICIENT:
                if x is not None:
                    in_scope.append(x)
                    in_scope_sources.append(src)
            elif v.verdict is CodeSpecsGateVerdict.NOT_APPLICABLE:
                if x is not None and x.entries:
                    n = len(x.entries)
                    raise CodeSpecsRecordError(
                        f"{gate_name} marks {v.area} `not applicable`, but "
                        f"{src} carries {n} routed "
                        f"entr{'y' if n == 1 else 'ies'} — a routed value is "
                        f"evidence the area applies (codespecs_prompt.md §6.4)"
                    )
                excluded.append(
                    CodeSpecsExcludedArea(
                        area=v.area,
                        verdict=v.verdict,
                        entry_count=count,
                        source=src,
                    )
                )
            else:
                if not v.descoped:
                    raise CodeSpecsRecordError(
                        f"{gate_name} marks {v.area} `insufficient` without "
                        f"`resolution: descoped` — codespecs_prompt.md §6.2 "
                        f"says the run does not continue past an unresolved "
                        f"insufficient area; recording the descope is what "
                        f"legitimizes a partial pass"
                    )
                excluded.append(
                    CodeSpecsExcludedArea(
                        area=v.area,
                        verdict=v.verdict,
                        descoped=True,
                        entry_count=count,
                        source=src,
                    )
                )
        return CodeSpecsExtractSet(in_scope, in_scope_sources, excluded, gate)

    @staticmethod
    def from_directory(path: str) -> "CodeSpecsExtractSet":
        """Reads a directory of extracts — ``<CE-CODE>.extract.yaml`` plus an
        optional ``gate.verdicts.yaml``; other files (the ``.extract.md``
        views) are ignored. Files are read in name order, so the set is the
        same on every file system."""
        if not os.path.isdir(path):
            raise CodeSpecsRecordError(f"extract directory not found: {path}")
        names = sorted(
            n
            for n in os.listdir(path)
            if os.path.isfile(os.path.join(path, n))
            and (
                n.endswith(K_CODE_SPECS_EXTRACT_FILE_SUFFIX)
                or n == K_CODE_SPECS_GATE_RECORD_FILE
            )
        )
        pairs = []
        for n in names:
            with open(os.path.join(path, n), "r", encoding="utf-8") as fh:
                pairs.append((n, fh.read()))
        return CodeSpecsExtractSet.from_files(pairs)

    def by_area(self, area: str) -> Optional[CodeSpecsExtract]:
        """The in-scope extract for *area*, or ``None``."""
        for x in self.extracts:
            if x.area.code == area:
                return x
        return None

    def entries_for_section(self, section_id: str) -> list[CodeSpecsExtractEntry]:
        """Every in-scope entry routed from *section_id* — the back-link token
        a ``DocRef`` names — across every area, in extract order."""
        return [
            e for x in self.extracts for e in x.entries if e.section_id == section_id
        ]

    def entries_at_path(self, path: str) -> list[CodeSpecsExtractEntry]:
        """Every in-scope entry read from document *path*, in extract order."""
        return [e for x in self.extracts for e in x.entries if e.path == path]


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


def _make_loader() -> Any:
    """A SafeLoader narrowed to what Dart's ``package:yaml`` reads: YAML 1.2
    core booleans (``yes``/``no``/``on``/``off`` stay strings), no implicit
    timestamps, and duplicate mapping keys refused."""
    if _yaml is None:  # pragma: no cover
        return None

    class _Loader(_yaml.SafeLoader):  # type: ignore[misc, valid-type]
        pass

    _Loader.yaml_implicit_resolvers = {
        first: [
            (tag, rx)
            for tag, rx in resolvers
            if tag not in ("tag:yaml.org,2002:bool", "tag:yaml.org,2002:timestamp")
        ]
        for first, resolvers in _yaml.SafeLoader.yaml_implicit_resolvers.items()
    }
    _Loader.add_implicit_resolver(
        "tag:yaml.org,2002:bool",
        re.compile(r"^(?:true|True|TRUE|false|False|FALSE)$"),
        list("tTfF"),
    )

    def construct_mapping(loader: Any, node: Any, deep: bool = False) -> Any:
        seen: set = set()
        for key_node, _ in node.value:
            key = loader.construct_object(key_node, deep=deep)
            try:
                duplicate = key in seen
                seen.add(key)
            except TypeError:  # an unhashable key cannot repeat a hashable one
                continue
            if duplicate:
                raise _yaml.constructor.ConstructorError(
                    None, None, "Duplicate mapping key.", key_node.start_mark
                )
        return _yaml.SafeLoader.construct_mapping(loader, node, deep=deep)

    _Loader.construct_mapping = construct_mapping  # type: ignore[assignment]
    return _Loader


_LOADER = _make_loader()


def _root_mapping(text: str, name: str, key: str) -> dict:
    if _yaml is None:  # pragma: no cover
        raise RuntimeError(
            "PyYAML is required to read CodeSpecs records; install it with "
            "`pip install pyyaml`."
        )
    try:
        document = _yaml.load(text, Loader=_LOADER)
    except _yaml.YAMLError as e:
        raise CodeSpecsRecordError(f"{name} is not valid YAML: {e}") from None
    if not isinstance(document, dict):
        raise CodeSpecsRecordError(f"{name} does not hold a YAML mapping")
    root = document.get(key)
    if not isinstance(root, dict):
        raise CodeSpecsRecordError(f"{name} has no top-level `{key}:` mapping")
    return root


def _is_int(v: Any) -> bool:
    return isinstance(v, int) and not isinstance(v, bool)


def _num_equals(v: Any, want: int) -> bool:
    """Dart's ``==`` between a YAML scalar and an int: numbers compare by
    value (``3.0 == 3``), a bool or string never equals a number."""
    if isinstance(v, bool):
        return False
    return isinstance(v, (int, float)) and v == want


def _show(v: Any) -> str:
    """A scalar as Dart's string interpolation shows it."""
    if v is None:
        return "null"
    if isinstance(v, bool):
        return "true" if v else "false"
    return str(v)


def _str(v: Any, name: str, key: str) -> str:
    if v is None:
        return ""
    if isinstance(v, str):
        return v
    raise CodeSpecsRecordError(f"{name}: `{key}` must be a string")


def _opt_str(v: Any, name: str, key: str) -> Optional[str]:
    if v is None:
        return None
    if isinstance(v, str):
        return v
    raise CodeSpecsRecordError(f"{name}: `{key}` must be a string or null")


def _str_list(v: Any, name: str, key: str) -> list[str]:
    if v is None:
        return []
    if not isinstance(v, list):
        raise CodeSpecsRecordError(f"{name}: `{key}` must be a list")
    return [_str(e, name, key) for e in v]


def _int_list(v: Any, name: str, key: str) -> list[int]:
    if v is None:
        return []
    if not isinstance(v, list):
        raise CodeSpecsRecordError(f"{name}: `{key}` must be a list")
    out: list[int] = []
    for e in v:
        if not _is_int(e):
            raise CodeSpecsRecordError(f"{name}: `{key}` must hold integers")
        out.append(e)
    return out
