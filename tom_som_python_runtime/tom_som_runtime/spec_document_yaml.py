"""Generic YAML codec for the native ``*.docspecs.yaml`` document format —
**hierarchical format v2** (SOM §12); a faithful port of
`tom_som_dart_runtime/lib/src/spec_document_yaml.dart`.

One nested YAML tree whose indentation mirrors the document structure: every
model node becomes a mapping key (``<section-id> <member-name>``, SOM §12.2),
sections nest their children, list items appear under their container keyed by
their stored section id (or an anonymous positional ``<member>-<n>`` key), a
node's own body text uses the literal key ``content``, a node's **stored
headline** (YRD3) uses the literal key ``headline``, and form fields use
their bare field names. A ``@Form`` node's mapping carries its own preamble
text — the free text before the first field (SOM §11.4 rule 7) — under the
same literal ``content`` key, so a form section stores its body exactly as
every other section does. A scalar-valued node (content/scalar/enum leaf or
scalar list item) that carries a stored headline is emitted as a
``{headline: …, content: …}`` mapping instead of a direct scalar. The former
flat two-level path-map format
(``document: {content: {"A/b": …}}``) is **retired**; readers reject
``version: 1`` files with a clear error (no compatibility path).

Text values are written as literal block scalars (``|2-``), with the SOM §12.4
escaping rules: the emitter is **self-verifying** (it re-parses each scalar it
produces and falls back to a double-quoted JSON-escaped flow scalar when the
parse differs), and **runs of 2+ consecutive empty lines are collapsed to
one** before serialization (a deliberate, documented lossy normalization —
round-trip guarantees are stated "modulo empty-line dedup"). Non-text values
(``int``/``double``/``bool``, enum member names) are plain scalars when they
self-verify (SOM §12.5).

Both :func:`encode` and :func:`decode` walk the :class:`SomMetaTree` of the
document root: the file carries **no paths** — the runtime reconstructs them
by matching keys against the metadata tree, and a key that matches nothing at
its position is a structured load error (:class:`SpecYamlFormatException`; no
silent skips). Symmetrically, :func:`encode` raises when the document holds
values the tree cannot place (nothing is silently dropped).

The optional ``review:`` pass stays opaque to the runtime (:func:`decode`
returns it as a raw map for the editor to interpret).
"""

from __future__ import annotations

import json
import re
from typing import Any, Optional

from .spec_document import SpecDocument
from .spec_meta import SomFormMeta, SomMetaKind, SomMetaNode, SomMetaTree
from .spec_paths import spec_path_join

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
#: Version 2 is the hierarchical tree format; version-1 flat files are
#: rejected on read.
FORMAT_VERSION = 2


class SpecYamlFormatException(Exception):
    """A structural error in a ``*.docspecs.yaml`` file: wrong/unsupported
    format version, a key that does not match the metadata tree at its
    position, a malformed value shape, or (on encode) document values the tree
    cannot place."""

    def __init__(self, message: str) -> None:
        super().__init__(message)
        #: What went wrong, naming the offending path/key where applicable.
        self.message = message

    def __str__(self) -> str:
        return f"SpecYamlFormatException: {self.message}"


class SpecYamlContents:
    """The decoded passes of a ``*.docspecs.yaml`` file: the ``document:``
    pass as a populated :class:`SpecDocument`, the ``review:`` pass as a raw
    map (the runtime is review-agnostic), and the optional authoring
    model-version stamp."""

    def __init__(
        self,
        document: SpecDocument,
        review: dict,
        model_version: Optional[str] = None,
    ) -> None:
        #: The ``document:`` pass, loaded into a live document (its
        #: :attr:`SpecDocument.model_version` is already set from the file
        #: stamp).
        self.document = document
        #: The ``review:`` pass exactly as parsed (empty when absent). The
        #: runtime does not interpret it; the editor maps it onto its own
        #: review entries.
        self.review = review
        #: The authoring object-model version (``major.minor``) this document
        #: was last written against, or ``None`` for an unstamped/hand-written
        #: file. Distinct from :data:`FORMAT_VERSION` (the on-disk format
        #: version).
        self.model_version = model_version


# --- Shared scalar machinery (public for the editor's review writer) ---------


def node_key(node: SomMetaNode) -> str:
    """The mapping key a metadata node writes (SOM §12.2): its section id, one
    space, then the exact member name (class name on the document root); just
    the name when the node carries no id.

    A section/complex node's key resolves the id as **field id, else the target
    class's id** — mirroring the markdown codec's class fallback — so a
    sub-section whose ``@SectionId`` lives on the target class still heads under
    its id (e.g. ``CTRL control:``). Content/scalar/enum/form/list-item keys use
    only the field-level id. The path :attr:`SomMetaNode.segment` stays
    field-level regardless, so document-store paths are unaffected; encode and
    decode both route through this one function, so they stay symmetric."""
    name = node.member_name if node.member_name is not None else node.class_name
    id = node.section_id
    if id is None and node.kind in (SomMetaKind.SECTION, SomMetaKind.COMPLEX):
        id = node.class_section_id
    return name if id is None else f"{id} {name}"


def yaml_key(key: str) -> str:
    """A safely-quoted mapping key. JSON strings are valid YAML flow scalars,
    so this both quotes and escapes any path/field name unambiguously."""
    return json.dumps(key, ensure_ascii=False)


_PLAIN_KEY_PATTERN = re.compile(
    r"^[A-Za-z0-9_][A-Za-z0-9_. -]*[A-Za-z0-9_.\-]$|^[A-Za-z0-9_]$"
)


def plain_key(key: str) -> str:
    """A plain key when the key is YAML-safe by construction (section ids,
    member names, ``<id> <name>`` pairs), else a JSON-quoted one."""
    return key if _PLAIN_KEY_PATTERN.match(key) else yaml_key(key)


_BLANK_RUNS = re.compile(r"\n{3,}")


def dedup_empty_lines(value: str) -> str:
    """Collapses runs of two or more consecutive empty lines to a single empty
    line (SOM §12.4 — the deliberate lossy normalization applied to every
    text value before serialization)."""
    return _BLANK_RUNS.sub("\n\n", value)


def _parsed_scalar_str(v: Any) -> str:
    """The Dart-``toString``-compatible string of a parsed YAML scalar
    (``true``/``false`` for booleans, matching the document's string-typed
    stores)."""
    if isinstance(v, bool):
        return "true" if v else "false"
    return str(v)


def _trailing_newlines(value: str) -> int:
    n = 0
    i = len(value)
    while i > 0 and value[i - 1] == "\n":
        n += 1
        i -= 1
    return n


def _literal_block(value: str) -> Optional[str]:
    """Builds a literal block scalar (``|2<chomp>``) with body at relative
    indent 2, or ``None`` when chomping can't reproduce the value's trailing
    newlines (two or more) — those fall back to JSON quoting."""
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
    """Whether re-parsing ``_v: <block>`` yields exactly *value* (the
    emitter's correctness guard)."""
    try:
        parsed = _require_yaml().safe_load(f"_v: {block}\n")
        return isinstance(parsed, dict) and parsed.get("_v") == value
    except Exception:
        return False


def _scalar(value: str) -> str:
    """The scalar representation of *value*: a literal block at relative
    indent 2 when that round-trips, else a JSON-quoted scalar."""
    block = _literal_block(value)
    if block is not None and _round_trips(block, value):
        return block
    return json.dumps(value, ensure_ascii=False)


_YAML11_BOOL = re.compile(r"^(y|Y|yes|Yes|YES|n|N|no|No|NO|on|On|ON|off|Off|OFF)$")
_YAML11_SEXAGESIMAL_INT = re.compile(r"^[-+]?[1-9][0-9_]*(:[0-5]?[0-9])+$")
_YAML11_SEXAGESIMAL_FLOAT = re.compile(r"^[-+]?[0-9][0-9_]*(:[0-5]?[0-9])+\.[0-9_]*$")


def _is_yaml11_special(value: str) -> bool:
    """Whether *value*'s text is a YAML **1.1** special that a 1.1 parser would
    resolve to a non-string, so it must never be emitted as a plain scalar
    (SOM §12.5). Covers the 1.1-only boolean words and sexagesimal int/float
    literals. Mirrors the Dart reference rule so every emitter's plain-scalar
    decision is identical regardless of the local YAML library's schema."""
    return bool(
        _YAML11_BOOL.match(value)
        or _YAML11_SEXAGESIMAL_INT.match(value)
        or _YAML11_SEXAGESIMAL_FLOAT.match(value)
    )


def _plain_scalar(value: str) -> Optional[str]:
    """A plain one-line scalar for a non-text value (int/double/bool/enum
    member name, SOM §12.5) when writing it plainly re-parses to exactly *value*
    (string compare, matching the document's string-typed stores); ``None``
    otherwise. Values whose text is a YAML 1.1 special are forced to the
    quoted/block path so cross-language round-trips stay identical."""
    if value == "" or "\n" in value:
        return None
    if _is_yaml11_special(value):
        return None
    try:
        parsed = _require_yaml().safe_load(f"_v: {value}\n")
        if not isinstance(parsed, dict):
            return None
        v = parsed.get("_v")
        if v is None or isinstance(v, (dict, list)):
            return None
        return value if _parsed_scalar_str(v) == value else None
    except Exception:
        return None


class _Buffer:
    """A minimal stand-in for Dart's ``StringBuffer`` (writeln semantics)."""

    def __init__(self) -> None:
        self._parts: list[str] = []

    def writeln(self, text: str = "") -> None:
        self._parts.append(text)
        self._parts.append("\n")

    def write(self, text: str) -> None:
        self._parts.append(text)

    def __str__(self) -> str:
        return "".join(self._parts)


def _write_rendered(
    b: _Buffer, key_indent: int, rendered_key: str, repr_: str
) -> None:
    pad = " " * key_indent
    lines = repr_.split("\n")
    b.writeln(f"{pad}{rendered_key}: {lines[0]}")
    for line in lines[1:]:
        if line == "":
            b.writeln("")
        else:
            b.writeln(f"{pad}{line}")


def write_scalar(b: _Buffer, key_indent: int, key: str, value: str) -> None:
    """Writes ``<indent><key>: <scalar>`` where the scalar is a self-verified
    block scalar (or a JSON-quoted fallback). Block body lines, which the
    builder emits at a relative indent of 2, are re-indented past
    *key_indent*."""
    _write_rendered(b, key_indent, yaml_key(key), _scalar(value))


def write_header(b: _Buffer, model_version: Optional[str] = None) -> None:
    """Writes the file header comment + ``version:`` line, and the optional
    ``modelVersion:`` stamp when *model_version* is non-empty."""
    b.writeln("# TomSpecs document (*.docspecs.yaml). Hierarchical format v2.")
    b.writeln(f"version: {FORMAT_VERSION}")
    if model_version:
        b.writeln(f"modelVersion: {json.dumps(model_version, ensure_ascii=False)}")


# --- Encode -------------------------------------------------------------------


def encode(
    document: SpecDocument,
    tree: SomMetaTree,
    model_version: Optional[str] = None,
) -> str:
    """Serializes *document* to a header + ``version:`` (+ ``modelVersion:``)
    + hierarchical ``document:`` pass, walking *tree* (the metadata tree of
    the document's root).

    Sibling order is the tree's child order (``@SerializationOrder``), list
    items follow their stored sequence; emission is sparse (only populated
    subtrees appear). Raises :class:`SpecYamlFormatException` when the
    document holds values *tree* cannot place — nothing is silently
    dropped."""
    b = _Buffer()
    write_header(b, model_version=model_version)
    _Encoder(document, tree).write_document_pass(b)
    return str(b)


class _Encoder:
    """One encode run: walks the metadata tree, consuming values from
    snapshots of the document's stores so anything left unconsumed at the end
    is a structured error (nothing is silently dropped)."""

    def __init__(self, doc: SpecDocument, tree: SomMetaTree) -> None:
        self.doc = doc
        self.tree = tree
        self._content: dict[str, str] = {
            p: doc.content(p) or "" for p in doc.content_paths
        }
        self._forms: dict[str, dict[str, str]] = {
            p: {f: doc.form_field(p, f) or "" for f in doc.form_field_names(p)}
            for p in doc.form_paths
        }
        self._lists: set[str] = set(doc.list_paths)
        self._headlines: dict[str, str] = {
            p: doc.headline(p) or "" for p in doc.headline_paths
        }
        self._code_specs: dict[str, str] = {
            p: doc.code_spec(p) or "" for p in doc.code_spec_paths
        }

    def write_document_pass(self, b: _Buffer) -> None:
        root = self.tree.root
        body = self._mapping_body(root, root.segment, 4)
        self._assert_nothing_left()
        if body == "":
            b.writeln("document: {}")
            return
        b.writeln("document:")
        b.writeln(f"  {plain_key(node_key(root))}:")
        b.write(body)

    def _mapping_body(self, node: SomMetaNode, path: str, indent: int) -> str:
        """Renders the mapping body of *node* at *path* (root, a collapsed
        section/complex field, or a list item's element), one line per
        populated entry at *indent*. Empty when nothing under the node is
        populated."""
        b = _Buffer()

        # The node's own stored headline — the literal `headline` key (YRD3).
        own_headline = self._headlines.pop(path, None)
        if own_headline is not None:
            if any(node_key(c) == "headline" for c in node.children):
                raise SpecYamlFormatException(
                    f"cannot emit the stored headline at `{path}`: a child of "
                    f"{node.debug_name} also serializes as key `headline`"
                )
            self._write_text(b, indent, "headline", own_headline)

        # The node's own codeSpec mapping — the literal `codeSpec` key
        # (codespecs_mapping.md §9.2).
        own_code_spec = self._code_specs.pop(path, None)
        if own_code_spec is not None:
            if any(node_key(c) == "codeSpec" for c in node.children):
                raise SpecYamlFormatException(
                    f"cannot emit the stored codeSpec at `{path}`: a child of "
                    f"{node.debug_name} also serializes as key `codeSpec`"
                )
            self._write_text(b, indent, "codeSpec", own_code_spec)

        # The node's own body text — the literal `content` key (SOM §12.2).
        own = self._content.pop(path, None)
        if own is not None:
            if any(node_key(c) == "content" for c in node.children):
                raise SpecYamlFormatException(
                    f"cannot emit body text at `{path}`: a child of "
                    f"{node.debug_name} also serializes as key `content`"
                )
            self._write_text(b, indent, "content", own)

        for child in node.children:
            child_path = spec_path_join(path, child.segment)
            key = node_key(child)
            if child.kind is SomMetaKind.CONTENT:
                v = self._content.pop(child_path, None)
                h = self._headlines.pop(child_path, None)
                cs = self._code_specs.pop(child_path, None)
                if h is not None or cs is not None:
                    self._write_scalar_with_meta(
                        b, indent, key, h, cs, v, text=True
                    )
                elif v is not None:
                    self._write_text(b, indent, key, v)
            elif child.kind in (SomMetaKind.SCALAR, SomMetaKind.ENUM_VALUE):
                v = self._content.pop(child_path, None)
                h = self._headlines.pop(child_path, None)
                cs = self._code_specs.pop(child_path, None)
                if h is not None or cs is not None:
                    self._write_scalar_with_meta(
                        b, indent, key, h, cs, v, text=False
                    )
                elif v is not None:
                    self._write_value(b, indent, key, v)
            elif child.kind is SomMetaKind.FORM:
                self._write_form(b, indent, key, child, child_path)
            elif child.kind in (SomMetaKind.SECTION, SomMetaKind.COMPLEX):
                sub = self._mapping_body(child, child_path, indent + 2)
                if sub != "":
                    b.writeln(f"{' ' * indent}{plain_key(key)}:")
                    b.write(sub)
            elif child.kind is SomMetaKind.LIST:
                self._write_list(b, indent, key, child, child_path)
        return str(b)

    def _write_scalar_with_meta(
        self,
        b: _Buffer,
        indent: int,
        key: str,
        headline: Optional[str],
        code_spec: Optional[str],
        value: Optional[str],
        *,
        text: bool,
    ) -> None:
        """Emits a scalar-valued node (content/scalar/enum leaf) that carries a
        stored headline and/or a codeSpec mapping as a
        ``{headline?: …, codeSpec?: …, content?: …}`` mapping (YRD3 + codespecs_mapping.md §9.2). At
        least one of *headline*/*code_spec* is non-``None`` at every call
        site."""
        b.writeln(f"{' ' * indent}{plain_key(key)}:")
        if headline is not None:
            self._write_text(b, indent + 2, "headline", headline)
        if code_spec is not None:
            self._write_text(b, indent + 2, "codeSpec", code_spec)
        if value is not None:
            if text:
                self._write_text(b, indent + 2, "content", value)
            else:
                self._write_value(b, indent + 2, "content", value)

    def _write_form(
        self, b: _Buffer, indent: int, key: str, node: SomMetaNode, path: str
    ) -> None:
        fields = self._forms.pop(path, None) or {}
        headline = self._headlines.pop(path, None)
        code_spec = self._code_specs.pop(path, None)
        # The form's preamble — the free text before its first field (SOM §11.4
        # rule 7, the DocSpecs `${text[]}` region) — rides in the same mapping
        # under the literal `content` key, exactly as a section's body does.
        content = self._content.pop(path, None)
        if (
            not fields
            and headline is None
            and code_spec is None
            and content is None
        ):
            return
        meta = node.form if node.form is not None else SomFormMeta(fields=[])
        for name in fields:
            field = meta.field_named(name)
            if field is None:
                raise SpecYamlFormatException(
                    f"form `{path}` holds a field `{name}` unknown to the "
                    "model"
                )
        if headline is not None and meta.field_named("headline") is not None:
            raise SpecYamlFormatException(
                f"cannot emit the stored headline at `{path}`: the form "
                "declares a field literally named `headline`"
            )
        if code_spec is not None and meta.field_named("codeSpec") is not None:
            raise SpecYamlFormatException(
                f"cannot emit the stored codeSpec at `{path}`: the form "
                "declares a field literally named `codeSpec`"
            )
        if content is not None and meta.field_named("content") is not None:
            raise SpecYamlFormatException(
                f"cannot emit the preamble content at `{path}`: the form "
                "declares a field literally named `content`"
            )
        b.writeln(f"{' ' * indent}{plain_key(key)}:")
        if headline is not None:
            self._write_text(b, indent + 2, "headline", headline)
        if code_spec is not None:
            self._write_text(b, indent + 2, "codeSpec", code_spec)
        if content is not None:
            self._write_text(b, indent + 2, "content", content)
        for f in meta.fields:
            v = fields.get(f.name)
            if v is None:
                continue
            if _is_numeric_or_bool(f.type_name):
                self._write_value(b, indent + 2, f.name, v)
            else:
                self._write_text(b, indent + 2, f.name, v)

    def _write_list(
        self, b: _Buffer, indent: int, key: str, node: SomMetaNode, path: str
    ) -> None:
        self._lists.discard(path)
        headline = self._headlines.pop(path, None)
        code_spec = self._code_specs.pop(path, None)
        items = self.doc.list_items(path)
        if not items and headline is None and code_spec is None:
            return
        b.writeln(f"{' ' * indent}{plain_key(key)}:")
        if headline is not None:
            self._write_text(b, indent + 2, "headline", headline)
        if code_spec is not None:
            self._write_text(b, indent + 2, "codeSpec", code_spec)
        used: set[str] = {"headline", "codeSpec"}
        pos = 0
        for item_path in items:
            pos += 1
            stored_id = self.doc.item_section_id(item_path)
            item_key = (
                stored_id if stored_id is not None
                else f"{node.member_name}-{pos}"
            )
            if stored_id is not None:
                if item_key in used:
                    raise SpecYamlFormatException(
                        f"duplicate list item key `{item_key}` at `{path}`"
                    )
                used.add(item_key)
            else:
                bump = pos
                while item_key in used:
                    bump += 1
                    item_key = f"{node.member_name}-{bump}"
                used.add(item_key)
            element = node.element_node
            if element is None:
                # Scalar list: the item is a direct value — unless it carries
                # a stored headline and/or codeSpec, in which case it becomes a
                # `{headline?: …, codeSpec?: …, content: …}` mapping
                # (YRD3 + codespecs_mapping.md §9.2).
                v = self._content.pop(item_path, None)
                ih = self._headlines.pop(item_path, None)
                ics = self._code_specs.pop(item_path, None)
                if ih is not None or ics is not None:
                    self._write_scalar_with_meta(
                        b, indent + 2, item_key, ih, ics, v, text=False
                    )
                else:
                    self._write_value(b, indent + 2, item_key, v or "")
            else:
                sub = self._mapping_body(element, item_path, indent + 4)
                if sub == "":
                    b.writeln(f"{' ' * (indent + 2)}{plain_key(item_key)}: {{}}")
                else:
                    b.writeln(f"{' ' * (indent + 2)}{plain_key(item_key)}:")
                    b.write(sub)

    def _write_text(
        self, b: _Buffer, indent: int, key: str, value: str
    ) -> None:
        """Text value: empty-line dedup, then a self-verified block scalar (or
        the JSON-quoted fallback)."""
        _write_rendered(
            b, indent, plain_key(key), _scalar(dedup_empty_lines(value))
        )

    def _write_value(
        self, b: _Buffer, indent: int, key: str, value: str
    ) -> None:
        """Non-text value (SOM §12.5): plain when it self-verifies, else the text
        path."""
        plain = _plain_scalar(value)
        if plain is not None:
            b.writeln(f"{' ' * indent}{plain_key(key)}: {plain}")
        else:
            self._write_text(b, indent, key, value)

    def _assert_nothing_left(self) -> None:
        leftovers = sorted(
            [f"content at `{p}`" for p in self._content]
            + [f"form values at `{p}`" for p in self._forms]
            + [f"list items at `{p}`" for p in self._lists]
            + [f"headline at `{p}`" for p in self._headlines]
            + [f"codeSpec at `{p}`" for p in self._code_specs]
        )
        if leftovers:
            raise SpecYamlFormatException(
                "document holds values the metadata tree cannot place: "
                + "; ".join(leftovers)
            )


def _is_numeric_or_bool(type_name: str) -> bool:
    return type_name in ("int", "double", "num", "bool")


# --- Decode -------------------------------------------------------------------


def decode(yaml_text: str, tree: SomMetaTree) -> SpecYamlContents:
    """Parses a ``*.docspecs.yaml`` file into its passes, matching every
    ``document:`` key against *tree*.

    Raises :class:`SpecYamlFormatException` for a missing/unsupported
    ``version:`` (version 1 is rejected explicitly — the flat format has no
    compatibility path), for any key the metadata tree cannot place, and for
    malformed value shapes. A missing/empty ``document:`` pass decodes as an
    empty document."""
    root = None if yaml_text.strip() == "" else _require_yaml().safe_load(
        yaml_text
    )
    if not isinstance(root, dict):
        raise SpecYamlFormatException(
            "not a *.docspecs.yaml mapping (expected version/document keys)"
        )
    version = root.get("version")
    if _parsed_scalar_str(version) != str(FORMAT_VERSION):
        if version is None:
            raise SpecYamlFormatException(
                f"missing `version:` (expected version: {FORMAT_VERSION})"
            )
        if _parsed_scalar_str(version) == "1":
            raise SpecYamlFormatException(
                "format version 1 (flat path-map) is no longer supported; "
                "re-save the document in the hierarchical v2 format"
            )
        raise SpecYamlFormatException(
            f"unsupported format version `{version}` "
            f"(expected {FORMAT_VERSION})"
        )

    stamp_raw = root.get("modelVersion")
    stamp = (
        _parsed_scalar_str(stamp_raw)
        if stamp_raw is not None and _parsed_scalar_str(stamp_raw) != ""
        else None
    )
    rev = root.get("review")

    document = SpecDocument()
    document.model_version = stamp
    doc_pass = root.get("document")
    if doc_pass is not None and not isinstance(doc_pass, dict):
        raise SpecYamlFormatException("`document:` must be a mapping")
    if isinstance(doc_pass, dict) and doc_pass:
        root_key = node_key(tree.root)
        keys = list(doc_pass.keys())
        if len(keys) != 1 or str(keys[0]) != root_key:
            found = ", ".join(f"`{k}`" for k in keys)
            raise SpecYamlFormatException(
                f"expected the single document root key `{root_key}`, "
                f"found: {found}"
            )
        body = doc_pass[keys[0]]
        if body is not None:
            if not isinstance(body, dict):
                raise SpecYamlFormatException(
                    f"root `{root_key}` must hold a mapping, not a scalar"
                )
            _Decoder(document, tree).load_mapping(
                tree.root, tree.root.segment, body
            )

    return SpecYamlContents(
        document=document,
        review=rev if isinstance(rev, dict) else {},
        model_version=stamp,
    )


class _Decoder:
    """One decode run: walks a parsed YAML mapping alongside the metadata tree
    and populates *doc*. Any key that matches nothing at its position
    raises."""

    def __init__(self, doc: SpecDocument, tree: SomMetaTree) -> None:
        self.doc = doc
        self.tree = tree

    def load_mapping(self, node: SomMetaNode, path: str, body: dict) -> None:
        for raw_key, value in body.items():
            key = str(raw_key)
            child = self._child_by_key(node, key)
            if child is not None:
                self._load_child(
                    child, spec_path_join(path, child.segment), key, value
                )
                continue
            if key == "content":
                self.doc.set_content(
                    path, self._scalar_of(value, f"{path}/content")
                )
                continue
            if key == "headline":
                self.doc.set_headline(
                    path, self._scalar_of(value, f"{path} (headline)")
                )
                continue
            if key == "codeSpec":
                self.doc.set_code_spec(
                    path, self._scalar_of(value, f"{path} (codeSpec)")
                )
                continue
            expected = ", ".join(self._expected_keys(node))
            raise SpecYamlFormatException(
                f"key `{key}` under `{path}` matches no member of "
                f"{node.debug_name} (expected one of: {expected})"
            )

    @staticmethod
    def _child_by_key(node: SomMetaNode, key: str) -> Optional[SomMetaNode]:
        for c in node.children:
            if node_key(c) == key:
                return c
        return None

    @staticmethod
    def _expected_keys(node: SomMetaNode) -> list[str]:
        return [f"`{node_key(c)}`" for c in node.children] + [
            "`content`",
            "`headline`",
            "`codeSpec`",
        ]

    def _load_child(
        self, child: SomMetaNode, path: str, key: str, value: Any
    ) -> None:
        if child.kind in (
            SomMetaKind.CONTENT,
            SomMetaKind.SCALAR,
            SomMetaKind.ENUM_VALUE,
        ):
            if isinstance(value, dict):
                # Headline-/codeSpec-extended scalar node (YRD3 +
                # codespecs_mapping.md §9.2): `{headline?: …, codeSpec?: …,
                # content: …}`.
                self._load_scalar_with_meta(path, key, value)
            else:
                self.doc.set_content(path, self._scalar_of(value, path))
        elif child.kind is SomMetaKind.FORM:
            if not isinstance(value, dict):
                raise SpecYamlFormatException(
                    f"form `{key}` at `{path}` must hold a field mapping"
                )
            meta = child.form if child.form is not None else SomFormMeta(
                fields=[]
            )
            for f, v in value.items():
                name = str(f)
                field = meta.field_named(name)
                if field is None:
                    if name == "headline":
                        self.doc.set_headline(
                            path, self._scalar_of(v, f"{path} (headline)")
                        )
                        continue
                    if name == "codeSpec":
                        self.doc.set_code_spec(
                            path, self._scalar_of(v, f"{path} (codeSpec)")
                        )
                        continue
                    if name == "content":
                        # The form's preamble (SOM §11.4 rule 7 / §12.2).
                        self.doc.set_content(
                            path, self._scalar_of(v, f"{path}/content")
                        )
                        continue
                    raise SpecYamlFormatException(
                        f"form `{path}` has no field `{name}` in the model"
                    )
                self.doc.set_form_field(
                    path, name, self._scalar_of(v, f"{path}.{name}")
                )
        elif child.kind in (SomMetaKind.SECTION, SomMetaKind.COMPLEX):
            if value is None:
                return
            if not isinstance(value, dict):
                raise SpecYamlFormatException(
                    f"section `{key}` at `{path}` must hold a mapping, "
                    "not a scalar"
                )
            self.load_mapping(child, path, value)
        elif child.kind is SomMetaKind.LIST:
            if value is None:
                return
            if not isinstance(value, dict):
                raise SpecYamlFormatException(
                    f"list `{key}` at `{path}` must hold an item mapping"
                )
            self._load_list(child, path, value)

    def _load_list(self, node: SomMetaNode, path: str, items: dict) -> None:
        anonymous = re.compile(
            "^" + re.escape(node.member_name or "") + "-[0-9]+$"
        )
        for raw_key, value in items.items():
            key = str(raw_key)
            if key == "headline":
                # The list container's own stored headline (YRD3), not an
                # item.
                self.doc.set_headline(
                    path, self._scalar_of(value, f"{path} (headline)")
                )
                continue
            if key == "codeSpec":
                # The list container's own codeSpec mapping
                # (codespecs_mapping.md §9.2), not an item.
                self.doc.set_code_spec(
                    path, self._scalar_of(value, f"{path} (codeSpec)")
                )
                continue
            item_path = self.doc.add_list_item(
                path, section_id=None if anonymous.match(key) else key
            )
            element = node.element_node
            if element is None:
                # Scalar list item: the value is the item itself — or a
                # `{headline?: …, codeSpec?: …, content: …}` mapping when it
                # carries a stored headline and/or codeSpec (YRD3 +
                # codespecs_mapping.md §9.2).
                if isinstance(value, dict):
                    self._load_scalar_with_meta(item_path, key, value)
                    continue
                if isinstance(value, list):
                    raise SpecYamlFormatException(
                        f"scalar list item `{key}` at `{path}` must hold a "
                        "scalar"
                    )
                if value is not None:
                    self.doc.set_content(item_path, _parsed_scalar_str(value))
                continue
            if value is None:
                continue
            if not isinstance(value, dict):
                raise SpecYamlFormatException(
                    f"list item `{key}` at `{path}` must hold a mapping "
                    "(use `{}` for an empty item)"
                )
            self.load_mapping(element, item_path, value)

    def _load_scalar_with_meta(
        self, path: str, key: str, value: dict
    ) -> None:
        """Loads a headline-/codeSpec-extended scalar node (YRD3 + codespecs_mapping.md §9.2): a
        mapping holding only the literal keys ``headline``, ``codeSpec`` and
        ``content``."""
        for k, v in value.items():
            name = str(k)
            if name == "headline":
                self.doc.set_headline(
                    path, self._scalar_of(v, f"{path} (headline)")
                )
            elif name == "codeSpec":
                self.doc.set_code_spec(
                    path, self._scalar_of(v, f"{path} (codeSpec)")
                )
            elif name == "content":
                self.doc.set_content(
                    path, self._scalar_of(v, f"{path}/content")
                )
            else:
                raise SpecYamlFormatException(
                    f"scalar node `{key}` at `{path}` may only hold "
                    f"`headline`/`codeSpec`/`content` keys when written as a "
                    f"mapping, found `{name}`"
                )

    @staticmethod
    def _scalar_of(value: Any, where: str) -> str:
        if value is None:
            return ""
        if isinstance(value, (dict, list)):
            raise SpecYamlFormatException(
                f"expected a scalar value at `{where}`"
            )
        return _parsed_scalar_str(value)
