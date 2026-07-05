"""Generic YAML codec for the native ``*.docspecs.yaml`` document format — a
faithful port of `tom_som_dart_runtime/lib/src/spec_document_yaml.dart`.

A header comment, ``version:`` (the on-disk format version), an optional
``modelVersion:`` stamp (the authoring object-model ``major.minor``), then the
``document:`` pass — the live object-model values, sorted by full section path.

**All text values are written as literal block scalars (`|2-`)** so multi-line
content round-trips verbatim. The emitter is **self-verifying**: it re-parses
each block it produces and falls back to a JSON-quoted scalar (always valid YAML)
for any value a clean block can't represent — values with two or more trailing
newlines, or anything the parser doesn't reproduce exactly.

Decoding uses a real YAML parser (PyYAML's ``safe_load``), mirroring the Dart
port's use of ``loadYaml``.
"""

from __future__ import annotations

import json
from dataclasses import dataclass
from typing import Any, Optional

from .spec_serialization_order import SpecSerializationOrder

try:  # PyYAML is the decode/self-verify parser, as `package:yaml` is in Dart.
    import yaml as _yaml
except ImportError:  # pragma: no cover - surfaced clearly at call sites.
    _yaml = None  # type: ignore[assignment]


def _require_yaml() -> Any:
    if _yaml is None:  # pragma: no cover
        raise RuntimeError(
            "PyYAML is required for *.docspecs.yaml decoding/self-verification; "
            "install it with `pip install pyyaml`."
        )
    return _yaml


#: The on-disk format version (independent of the model-version stamp).
FORMAT_VERSION = 1


@dataclass(frozen=True)
class SpecYamlContents:
    """The decoded passes of a ``*.docspecs.yaml`` file: the ``document:`` pass
    as a :meth:`SpecDocument.load_json`-shaped map, the ``review:`` pass as a raw
    map (the runtime is review-agnostic), and the optional authoring
    model-version stamp."""

    document: dict[Any, Any]
    review: dict[Any, Any]
    model_version: Optional[str] = None


def _yaml_key(key: str) -> str:
    """A safely-quoted mapping key. JSON strings are valid YAML flow scalars, so
    this both quotes and escapes any path/field name unambiguously."""
    return json.dumps(key, ensure_ascii=False)


def _trailing_newlines(value: str) -> int:
    n = 0
    i = len(value)
    while i > 0 and value[i - 1] == "\n":
        n += 1
        i -= 1
    return n


def _literal_block(value: str) -> Optional[str]:
    """Builds a literal block scalar (`|2<chomp>`) with body at relative indent
    2, or ``None`` when chomping can't reproduce the value's trailing newlines
    (two or more) — those fall back to JSON quoting."""
    trailing = _trailing_newlines(value)
    if trailing == 0:
        chomp = "-"
        core = value
    elif trailing == 1:
        chomp = ""
        core = value[:-1]
    else:
        return None
    parts = [f"|2{chomp}"]
    for line in core.split("\n"):
        parts.append("\n")
        if line:
            parts.append(f"  {line}")
    return "".join(parts)


def _round_trips(block: str, value: str) -> bool:
    """Whether re-parsing ``_v: <block>`` yields exactly *value* (the emitter's
    correctness guard)."""
    try:
        parsed = _require_yaml().safe_load(f"_v: {block}\n")
        return isinstance(parsed, dict) and parsed.get("_v") == value
    except Exception:
        return False


def _scalar(value: str) -> str:
    """The scalar representation of *value*: a literal block at relative indent 2
    when that round-trips, else a JSON-quoted scalar."""
    block = _literal_block(value)
    if block is not None and _round_trips(block, value):
        return block
    return json.dumps(value, ensure_ascii=False)


class _Buffer:
    """A minimal stand-in for Dart's ``StringBuffer`` (writeln semantics)."""

    def __init__(self) -> None:
        self._parts: list[str] = []

    def writeln(self, text: str = "") -> None:
        self._parts.append(text)
        self._parts.append("\n")

    def __str__(self) -> str:
        return "".join(self._parts)


def _write_scalar(b: _Buffer, key_indent: int, key: str, value: str) -> None:
    """Writes ``<indent><key>: <scalar>`` where the scalar is a self-verified
    block scalar (or a JSON-quoted fallback). Body lines, emitted at a relative
    indent of 2, are re-indented to *key_indent* + 2."""
    pad = " " * key_indent
    repr_ = _scalar(value)
    lines = repr_.split("\n")
    b.writeln(f"{pad}{_yaml_key(key)}: {lines[0]}")
    for line in lines[1:]:
        if line == "":
            b.writeln("")
        else:
            b.writeln(f"{pad}{line}")


def _sorted_string_keys(m: dict) -> list[str]:
    return sorted(str(k) for k in m.keys())


def _write_header(b: _Buffer, model_version: Optional[str]) -> None:
    b.writeln("# TomSpecs document (*.docspecs.yaml).")
    b.writeln(
        "# `document:` holds the object-model values, sorted by section id; text"
    )
    b.writeln(
        "# values use block scalars so multi-line content round-trips verbatim (§15.1)."
    )
    b.writeln(f"version: {FORMAT_VERSION}")
    if model_version:
        b.writeln(f"modelVersion: {json.dumps(model_version, ensure_ascii=False)}")


def _write_document_pass(
    b: _Buffer,
    doc: dict[str, Any],
    order: Optional[SpecSerializationOrder] = None,
) -> None:
    def order_keys(m: dict) -> list[str]:
        if order is None:
            return _sorted_string_keys(m)
        return order.order_paths(str(k) for k in m.keys())

    content = doc.get("content")
    forms = doc.get("forms")
    lists = doc.get("lists")
    if content is None and forms is None and lists is None:
        b.writeln("document: {}")
        return
    b.writeln("document:")

    if isinstance(content, dict) and content:
        b.writeln("  content:")
        for k in order_keys(content):
            _write_scalar(b, 4, k, str(content[k]))

    if isinstance(forms, dict) and forms:
        b.writeln("  forms:")
        for k in order_keys(forms):
            fields = forms[k]
            if not isinstance(fields, dict) or not fields:
                continue
            b.writeln(f"    {_yaml_key(k)}:")
            field_keys = (
                _sorted_string_keys(fields)
                if order is None
                else order.order_form_fields(k, (str(f) for f in fields.keys()))
            )
            for f in field_keys:
                _write_scalar(b, 6, f, str(fields[f]))

    if isinstance(lists, dict) and lists:
        b.writeln("  lists:")
        for k in order_keys(lists):
            spec = lists[k]
            if not isinstance(spec, dict):
                continue
            b.writeln(f"    {_yaml_key(k)}:")
            b.writeln(f"      seq: {spec.get('seq') or 0}")
            items = spec.get("items")
            if isinstance(items, list) and items:
                b.writeln("      items:")
                for it in items:
                    b.writeln(f"        - {_yaml_key(str(it))}")
            else:
                b.writeln("      items: []")


def encode(
    document: Any,
    model_version: Optional[str] = None,
    order: Optional[SpecSerializationOrder] = None,
) -> str:
    """Serializes *document* (a :class:`SpecDocument`) to a header + ``version:``
    (+ ``modelVersion:``) + ``document:`` pass.

    When *order* is supplied, members are emitted in ``@SerializationOrder``
    order (AA1 criterion 7); otherwise keys stay alphabetical (the diff-stable
    default the editor relies on)."""
    b = _Buffer()
    _write_header(b, model_version)
    _write_document_pass(b, document.to_json(), order)
    return str(b)


def decode(yaml_text: str) -> SpecYamlContents:
    """Parses a ``*.docspecs.yaml`` document into its passes. A missing pass
    decodes as empty rather than failing, so a partial/hand-written file still
    loads what it has."""
    root = None if yaml_text.strip() == "" else _require_yaml().safe_load(yaml_text)
    doc = root.get("document") if isinstance(root, dict) else None
    rev = root.get("review") if isinstance(root, dict) else None
    stamp = root.get("modelVersion") if isinstance(root, dict) else None
    return SpecYamlContents(
        document=doc if isinstance(doc, dict) else {},
        review=rev if isinstance(rev, dict) else {},
        model_version=str(stamp) if stamp is not None and str(stamp) != "" else None,
    )
