"""A sparse, live instance of a TomSpecs document — a faithful port of
`tom_som_dart_runtime/lib/src/spec_document.dart`.

The structure is defined by the :class:`SpecModel` class graph; this holds only
the *values* the user/agent has actually set, keyed by the globally-unique
section-ID path. Nothing is materialised until written, so an untouched document
is empty (the "empty = no value" rule).

Four sparse stores cover the writable field kinds:

  * ``_content`` — ``content``/``scalar`` leaves: path → string value;
  * ``_form`` — ``@Form`` sections: path → (form-field name → value);
  * ``_list_items`` — lists: list path → ordered item paths;
  * ``_headline`` — stored headlines (YRD3): any section path → the headline
    the document actually renders/rendered. Sparse like content: unset means
    "use the effective default" (``@Headline`` default, else name derivation).

List item paths are ``"<list_path>-<seq>"`` where ``seq`` is a per-list
monotonic counter that never reuses a number.

Each list item also carries a **section id** (AA1 criteria 3–6): the
document-semantic identity generated from the list field's
``@SectionIdPattern``. This is distinct from the internal ``-<seq>`` path key:
the seq path keeps nested values attached across edits (never renumbered), while
the section id is what the document exposes and may be overridden
(:meth:`set_item_section_id`, criterion 5) or reused same-day after the last
item is deleted (criterion 6). Section ids live in ``_item_section_id``, keyed by
the internal item path.
"""

from __future__ import annotations

import re
from dataclasses import dataclass, field as dc_field
from typing import TYPE_CHECKING, Any, Iterable, Optional

from .spec_section_id import SpecSectionIdCollision

if TYPE_CHECKING:
    from .spec_document_assembly import SpecDocumentAssembly
    from .spec_document_markdown import (
        SpecMarkdownImport,
        SpecMarkdownRendition,
        SpecMarkdownResult,
    )
    from .spec_model import SpecModel, SpecRoot


class SpecDocument:
    def __init__(self) -> None:
        self._content: dict[str, str] = {}
        self._form: dict[str, dict[str, str]] = {}
        self._list_items: dict[str, list[str]] = {}
        self._list_seq: dict[str, int] = {}
        self._item_section_id: dict[str, str] = {}
        self._headline: dict[str, str] = {}
        #: The concrete instance-level forward DocSpecs→CodeSpecs link
        #(codespecs_mapping.md §9.2): : any section path → the comma-joined list
        #of CodeSpecs code locations : that section maps to. Sparse like
        #:attr:`_headline`: unset means : "no code mapping".
        self._code_spec: dict[str, str] = {}
        #: The authoring object-model version (``major.minor``) this document was
        #: loaded from, or ``None`` for a brand-new / unstamped document. Retained
        #: here by :meth:`from_yaml` so a consumer need not thread
        #: ``decoded.model_version`` to the typed facade by hand (the "forgot the
        #: stamp" class of bug); the generated ``load_yaml`` / ``load_file``
        #: classmethods apply it automatically.
        self.model_version: Optional[str] = None

    # --- one-call loading (SOM §21) ---------------------------------------

    @classmethod
    def from_yaml(cls, yaml: str, tree: Any) -> "SpecDocument":
        """Loads a hierarchical ``*.docspecs.yaml`` (v2) document in one call:
        decode the YAML against the :class:`SomMetaTree` *tree*, populate the
        sparse stores, and retain the parsed :attr:`model_version` (SOM §21;
        The tree-based signature — mirrors Dart's
        ``SpecDocument.fromYaml(yaml, tree)``)."""
        from .spec_document_yaml import decode

        return decode(yaml, tree).document

    @classmethod
    def from_file(cls, path: str, tree: Any) -> "SpecDocument":
        """Loads a ``*.docspecs.yaml`` document from the file at *path* — the file
        companion to :meth:`from_yaml` the generated ``load_file`` classmethod
        delegates to."""
        with open(path, "r", encoding="utf-8") as f:
            return cls.from_yaml(f.read(), tree)

    # --- one-call Markdown export (SOM §21) ------------------------------

    def to_markdown(
        self, model: "SpecModel", root_type: Optional[str] = None
    ) -> str:
        """Renders this document to Markdown in one call (SOM §21).

        Collapses the former ``SpecDocumentMarkdown(model, doc).export_root(
        model.root_by_type(…))`` incantation. When *root_type* is given, that
        root is exported (via :meth:`SpecModel.root_by_type`); when omitted, the
        document's single **populated** root is used — a root is populated when
        it has any value beneath its segment (:meth:`has_values_under`). Raises
        :class:`RuntimeError` when the default is ambiguous — zero populated
        roots, or more than one — so the caller names *root_type* explicitly.
        (Ambiguity is document *state*, not a bad argument, so it is a
        :class:`RuntimeError` where a genuine bad argument — an unknown
        *root_type* — surfaces as :meth:`SpecModel.root_by_type`'s
        :class:`ValueError`.)"""
        # Lazy imports avoid the spec_model / spec_document_markdown import cycle
        # (spec_document_markdown imports SpecDocument at module load).
        from .spec_document_markdown import SpecDocumentMarkdown

        if root_type is not None:
            root = model.root_by_type(root_type)
        else:
            root = self._single_populated_root(model)
        return SpecDocumentMarkdown(model, self).export_root(root)

    def to_markdown_with_map(
        self, model: "SpecModel", root_type: Optional[str] = None
    ) -> "SpecMarkdownRendition":
        """:meth:`to_markdown`, plus the document path behind every heading
        (:meth:`SpecDocumentMarkdown.export_root_with_map`). Root selection and
        errors are those of :meth:`to_markdown`."""
        from .spec_document_markdown import SpecDocumentMarkdown

        if root_type is not None:
            root = model.root_by_type(root_type)
        else:
            root = self._single_populated_root(model)
        return SpecDocumentMarkdown(model, self).export_root_with_map(root)

    # --- assembling from fragments ---------------------------------------

    @staticmethod
    def assemble(fragments: Any) -> "SpecDocumentAssembly":
        """Merges *fragments* — name → document, in order (a mapping or an
        ordered iterable of ``(name, document)`` pairs) — into one document.

        Refusing: a content path, form field, list, headline or code-spec
        location two fragments both write is an overlap, and an assembly with
        any overlap carries no document. See
        :func:`assemble_spec_documents`."""
        # Lazy import: spec_document_assembly imports SpecDocument at load.
        from .spec_document_assembly import assemble_spec_documents

        return assemble_spec_documents(fragments)

    # --- one-call Markdown import (SOM §11.7) -----------------------------

    @staticmethod
    def from_markdown(text: str, model: "SpecModel") -> "SpecMarkdownImport":
        """Loads a SOM-rendered Markdown document (SOM §11.7) into a fresh
        document in one call: parse, then :meth:`apply_markdown_result`.

        Blocks the parser rejects are not loaded, and are returned with the
        document, so a caller can show them or refuse to save: re-exporting a
        document whose source had rejections drops those blocks for good."""
        # Lazy import: spec_document_markdown imports SpecDocument at load.
        from .spec_document_markdown import (
            SpecDocumentMarkdown,
            SpecMarkdownImport,
        )

        document = SpecDocument()
        result = SpecDocumentMarkdown(model, document).parse(text)
        document.apply_markdown_result(result, allow_rejections=True)
        return SpecMarkdownImport(document=document, result=result)

    def apply_markdown_result(
        self, result: "SpecMarkdownResult", allow_rejections: bool = False
    ) -> None:
        """Applies a parsed Markdown import as a **full overwrite** of the roots
        it covers (SOM §11.7): every value under each of
        :attr:`SpecMarkdownResult.root_prefixes` is removed, then the parsed
        content, forms, lists, headlines and codeSpecs are written. Other roots
        are left as they are.

        A result with rejections is refused with a :class:`RuntimeError` (and
        the document is left unchanged) unless *allow_rejections* is true: the
        blocks it rejected would otherwise vanish from a document the caller
        believes it imported whole.

        Store-agnostic on both halves: the purge goes through
        :meth:`remove_values_under`, which clears every store, and the
        carry-over is whatever :meth:`to_json` emits. Paths are written as
        parsed — this port has no path normalizer."""
        if not allow_rejections and result.rejections:
            first = result.rejections[0]
            raise RuntimeError(
                f"markdown import has {len(result.rejections)} rejected "
                f"block(s); first at line {first.line}: {first.message}"
            )
        if not result.root_prefixes:
            return
        for prefix in result.root_prefixes:
            self.remove_values_under(prefix)

        held = self.to_json()

        def store(name: str) -> dict[str, Any]:
            values = held.get(name)
            if not isinstance(values, dict):
                return {}
            return {str(k): v for k, v in values.items()}

        lists = store("lists")
        for list_path, spec in result.lists.items():
            items = spec.get("items")
            ids = spec.get("ids")
            entry: dict[str, Any] = {
                "seq": spec.get("seq"),
                "items": [str(i) for i in items] if isinstance(items, list) else [],
            }
            if isinstance(ids, dict):
                entry["ids"] = {str(k): v for k, v in ids.items()}
            lists[list_path] = entry

        self.load_json({
            "content": {**store("content"), **result.content},
            "forms": {**store("forms"), **result.forms},
            "lists": lists,
            "headlines": {**store("headlines"), **result.headlines},
            "codeSpecs": {**store("codeSpecs"), **result.code_specs},
        })

    def _single_populated_root(self, model: "SpecModel") -> "SpecRoot":
        """The one root under which this document holds any value, for
        :meth:`to_markdown`'s default. Raises :class:`RuntimeError` when zero or
        more than one root is populated (an invalid-state condition, not a bad
        argument)."""
        populated = [
            r
            for r in model.roots
            if self.has_values_under(r.section_id or r.type)
        ]
        if len(populated) == 1:
            return populated[0]
        if not populated:
            raise RuntimeError(
                "document has no populated root to export; "
                "pass root_type to choose one"
            )
        types = ", ".join(r.type for r in populated)
        raise RuntimeError(
            f"document has {len(populated)} populated roots "
            f"({types}); pass root_type to choose one"
        )

    # --- content ------------------------------------------------------------

    def content(self, path: str) -> Optional[str]:
        return self._content.get(path)

    def has_content(self, path: str) -> bool:
        """Whether a non-empty content/scalar leaf value exists at exactly
        *path* — the ``None``-free companion to :meth:`content` (SOM §21).

        The one shared definition of "is this content leaf filled?": the typed
        facade's ``content`` getter coalesces a missing value to ``''`` while
        the generic :meth:`content` returns ``None``, so a consumer asking "is
        this section filled?" gets different-looking answers depending on the
        path. Routing both through :meth:`has_content` removes that divergence —
        it is ``True`` exactly when :meth:`content` would return a non-empty
        string."""
        return bool(self._content.get(path))

    def set_content(self, path: str, value: str) -> None:
        """Sets the content string at *path*. An empty value clears it."""
        if value == "":
            self._content.pop(path, None)
        else:
            self._content[path] = value

    # --- headlines (YRD3) ---------------------------------------------------

    def headline(self, path: str) -> Optional[str]:
        """The stored headline at *path*, or ``None`` when the section renders
        its effective default title (YRD3 — headlines are sparse like
        content)."""
        return self._headline.get(path)

    def set_headline(self, path: str, value: str) -> None:
        """Sets the stored headline at *path*. An empty value clears it,
        returning the section to its effective default title (YRD3)."""
        if value == "":
            self._headline.pop(path, None)
        else:
            self._headline[path] = value

    @property
    def headline_paths(self) -> Iterable[str]:
        """All section paths currently carrying a stored headline (unordered
        snapshot)."""
        return self._headline.keys()

    # --- codeSpec (codespecs_mapping.md §9.2)
    # ----------------------------------------------------

    def code_spec(self, path: str) -> Optional[str]:
        """The stored codeSpec mapping at *path* as the comma-joined list of
        CodeSpecs code locations, or ``None`` when the section carries no
        mapping (codespecs_mapping.md §9.2 — codeSpec is sparse like the headline)."""
        return self._code_spec.get(path)

    def set_code_spec(self, path: str, value: str) -> None:
        """Sets the stored codeSpec mapping at *path* (the comma-joined list of
        CodeSpecs code locations). An empty value clears it, returning the
        section to "no code mapping" (codespecs_mapping.md §9.2)."""
        if value == "":
            self._code_spec.pop(path, None)
        else:
            self._code_spec[path] = value

    @property
    def code_spec_paths(self) -> Iterable[str]:
        """All section paths currently carrying a stored codeSpec mapping
        (unordered snapshot)."""
        return self._code_spec.keys()

    # --- forms --------------------------------------------------------------

    def form_field(self, path: str, field_name: str) -> Optional[str]:
        return self._form.get(path, {}).get(field_name)

    def set_form_field(self, path: str, field_name: str, value: str) -> None:
        """Sets form *field_name* at *path*. An empty value clears that field
        (and the whole form entry once its last field is gone)."""
        fields = self._form.setdefault(path, {})
        if value == "":
            fields.pop(field_name, None)
            if not fields:
                self._form.pop(path, None)
        else:
            fields[field_name] = value

    # --- lists --------------------------------------------------------------

    def list_items(self, list_path: str) -> list[str]:
        return list(self._list_items.get(list_path, []))

    def add_list_item(self, list_path: str, section_id: Optional[str] = None) -> str:
        """Appends a new item to the list at *list_path* and returns its stable
        path.

        When *section_id* is given it becomes the item's section id after a
        uniqueness check against the list's other items (AA1 criterion 5); a
        collision raises :class:`SpecSectionIdCollision`. Section-id
        *generation* from a ``@SectionIdPattern`` lives in the caller (it needs
        the pattern); this layer only stores and guards uniqueness."""
        if section_id is not None:
            self._assert_section_id_free(list_path, section_id, None)
        seq = self._list_seq.get(list_path, 0) + 1
        self._list_seq[list_path] = seq
        item_path = f"{list_path}-{seq}"
        self._list_items.setdefault(list_path, []).append(item_path)
        if section_id is not None:
            self._item_section_id[item_path] = section_id
        return item_path

    def item_section_id(self, item_path: str) -> Optional[str]:
        """The section id assigned to the list item at *item_path*, or ``None``
        if none has been set (AA1 criterion 1 read path)."""
        return self._item_section_id.get(item_path)

    def set_item_section_id(self, item_path: str, id: str) -> None:
        """Overrides the section id of the list item at *item_path* (AA1
        criterion 5).

        Validates that the new *id* is unique among the *other* items of the
        same owning list; a collision raises :class:`SpecSectionIdCollision`.
        Assigning an id equal to the item's current id is a no-op. Raises
        :class:`ValueError` if *item_path* is not a live list item."""
        owning_list = self._owning_list_of(item_path)
        if owning_list is None:
            raise ValueError(f"{item_path!r} is not a live list item")
        if self._item_section_id.get(item_path) == id:
            return
        self._assert_section_id_free(owning_list, id, item_path)
        self._item_section_id[item_path] = id

    def list_item_section_ids(self, list_path: str) -> list[str]:
        """The section ids currently assigned within the list at *list_path*, in
        item order (items without an id are skipped). Feeds both id generation
        (``existing_ids``) and uniqueness checks."""
        return [
            self._item_section_id[item_path]
            for item_path in self._list_items.get(list_path, [])
            if item_path in self._item_section_id
        ]

    def _owning_list_of(self, item_path: str) -> Optional[str]:
        """The internal ``_list_items`` entry that owns *item_path*, or
        ``None``."""
        for key, items in self._list_items.items():
            if item_path in items:
                return key
        return None

    def _assert_section_id_free(
        self, list_path: str, id: str, except_item_path: Optional[str]
    ) -> None:
        """Raises :class:`SpecSectionIdCollision` if *id* is already used by an
        item of *list_path* other than *except_item_path*."""
        for item_path in self._list_items.get(list_path, []):
            if item_path == except_item_path:
                continue
            if self._item_section_id.get(item_path) == id:
                raise SpecSectionIdCollision(id, list_path)

    def move_list_item(
        self,
        model: "SpecModel",
        item_path: str,
        to_index: int,
        to_list: Optional[str] = None,
    ) -> "SpecListItemMove":
        """Moves the list item at *item_path* to position *to_index* (0-based)
        of its list, or of *to_list*, another list of the same element class
        (vsctsa44).

        **A path is a position, the section id is the identity.** Every
        affected list is renumbered to ``<list>-1 … <list>-n`` in its new
        order, and every value under each item — content, forms, nested lists,
        headline, code-spec, stored id — travels with it. An anonymous item
        whose positional id would change has its old id stored, so its
        identity survives the renumbering. The result maps every old item path
        to its new one; a caller holding anything else keyed by path (the
        ``review:`` pass) re-keys it with :func:`rekey_review`.

        Across lists, the destination must hold the same element class, and an
        item with a stored id keeps it only when the id fits the destination's
        ``@SectionIdPattern`` and is free there; otherwise the move is refused
        (:class:`ValueError` / :class:`SpecSectionIdCollision`) and nothing
        changes. A *to_index* outside ``0..len(destination without the item)``
        raises :class:`IndexError`. An anonymous item takes its positional id
        in the destination."""
        from .spec_model import SpecFieldKind
        from .spec_reflection import SpecReflection
        from .spec_section_id import effective_list_item_section_id

        item = item_path
        frm = self._owning_list_of(item)
        if frm is None:
            raise ValueError(f"{item_path!r} is not a live list item")
        to = frm if to_list is None else to_list
        refl = SpecReflection(model)
        from_res = refl.resolve(frm)
        to_res = refl.resolve(to)
        from_field = from_res.field if from_res is not None else None
        to_field = to_res.field if to_res is not None else None
        if to_field is None or to_field.kind != SpecFieldKind.LIST:
            raise ValueError(f"toList {to_list!r} is not a list of the model")
        from_element = from_field.element_type if from_field is not None else None
        if to != frm and to_field.element_type != from_element:
            raise ValueError(
                f"toList {to_list!r} holds {to_field.element_type}, but the "
                f"item is a {from_element} — an item moves only between lists "
                "of its own element class"
            )
        stored_id = self._item_section_id.get(item)
        if to != frm and stored_id is not None:
            pattern = to_field.section_id_pattern
            if pattern is not None and not _section_id_fits_pattern(
                pattern, stored_id
            ):
                raise ValueError(
                    f"section id {stored_id!r} does not fit the destination "
                    f"pattern {pattern} — set an id that does before moving "
                    "the item"
                )
            self._assert_section_id_free(to, stored_id, None)

        # The new orders.
        from_items = [p for p in self._list_items[frm] if p != item]
        to_items = from_items if to == frm else list(self._list_items.get(to, []))
        if to_index < 0 or to_index > len(to_items):
            raise IndexError(
                f"toIndex {to_index} is not in range 0..{len(to_items)}"
            )
        to_items.insert(to_index, item)

        def field_of(lst: str):
            return from_field if lst == frm else to_field

        def stem_of(lst: str) -> str:
            f = field_of(lst)
            return f.name if f is not None else lst.split("/")[-1]

        def pattern_of(lst: str) -> Optional[str]:
            f = field_of(lst)
            return f.section_id_pattern if f is not None else None

        # Each affected item's effective id before the move, so an anonymous
        # item keeps its identity when its position changes.
        before: dict[str, str] = {}
        lists_before = [frm] if to == frm else [frm, to]
        for lst in lists_before:
            items = self._list_items.get(lst, [])
            for pos, p in enumerate(items, start=1):
                before[p] = effective_list_item_section_id(
                    self._item_section_id.get(p), pattern_of(lst), pos, stem_of(lst)
                )

        # Old → new item paths, and the ids anonymous items must now store.
        renamed: dict[str, str] = {}
        pinned: dict[str, str] = {}

        def renumber(lst: str, items: list[str]) -> None:
            for i, old in enumerate(items):
                now = f"{lst}-{i + 1}"
                if old != now:
                    renamed[old] = now
                crossing = old == item and to != frm
                if self._item_section_id.get(old) is not None or crossing:
                    continue
                positional = effective_list_item_section_id(
                    None, pattern_of(lst), i + 1, stem_of(lst)
                )
                if positional != before[old]:
                    pinned[old] = before[old]

        renumber(frm, from_items)
        if to != frm:
            renumber(to, to_items)

        def remap(key: str) -> str:
            return _rekey_path(key, renamed)

        def rekey(store: dict) -> dict:
            return {remap(k): v for k, v in store.items()}

        content = rekey(self._content)
        form = rekey(self._form)
        headline = rekey(self._headline)
        code_spec = rekey(self._code_spec)
        ids = rekey(self._item_section_id)
        for old, id in pinned.items():
            ids[remap(old)] = id
        seq = rekey(self._list_seq)
        lists = {
            remap(k): [remap(p) for p in v] for k, v in self._list_items.items()
        }
        lists[remap(frm)] = [remap(p) for p in from_items]
        seq[remap(frm)] = len(from_items)
        if to != frm:
            lists[remap(to)] = [remap(p) for p in to_items]
            seq[remap(to)] = len(to_items)
        lists = {k: v for k, v in lists.items() if v}

        for store, fresh in (
            (self._content, content),
            (self._form, form),
            (self._headline, headline),
            (self._code_spec, code_spec),
            (self._item_section_id, ids),
            (self._list_seq, seq),
            (self._list_items, lists),
        ):
            store.clear()
            store.update(fresh)

        return SpecListItemMove(
            path=remap(item),
            renamed=dict(renamed),
            pinned_ids={remap(k): v for k, v in pinned.items()},
        )

    def remove_list_item(self, item_path: str) -> bool:
        """Removes the list item at *item_path* along with every value nested
        beneath it. The counter is left untouched so future items keep getting
        fresh sequence numbers (no renumbering)."""
        owning_list: Optional[str] = None
        for key, items in self._list_items.items():
            if item_path in items:
                owning_list = key
                break
        if owning_list is None:
            return False
        self._list_items[owning_list].remove(item_path)
        if not self._list_items[owning_list]:
            self._list_items.pop(owning_list, None)
        self._purge_under(item_path)
        return True

    def _purge_under(self, prefix: str) -> None:
        def is_under(key: str) -> bool:
            return (
                key == prefix
                or key.startswith(f"{prefix}/")
                or key.startswith(f"{prefix}-")
            )

        for store in (
            self._content,
            self._form,
            self._list_items,
            self._list_seq,
            self._item_section_id,
            self._headline,
            self._code_spec,
        ):
            for key in [k for k in store if is_under(k)]:
                store.pop(key, None)

    def remove_values_under(self, prefix: str) -> None:
        """Drops every value at *prefix* or nested beneath it — content, form
        entries, list items (with their nested values, ids and counters), and
        stored headlines (YRD7 generic modification API: "clear section").

        The predicate is the same one :meth:`has_values_under` uses, so after
        this call ``has_values_under(prefix)`` is ``False``. Note this clears
        *values under a section path*; removing a single list item from its
        owning list is :meth:`remove_list_item`.
        """
        self._purge_under(prefix)

    # --- queries ------------------------------------------------------------

    @property
    def is_empty(self) -> bool:
        return (
            not self._content
            and not self._form
            and not self._list_items
            and not self._headline
            and not self._code_spec
        )

    def has_values_under(self, prefix: str) -> bool:
        """Whether any value exists at *prefix* or nested beneath it — the
        structural "empty = no value" test (the exact inverse of the purge
        predicate, so emptiness and purge stay in lock-step)."""

        def is_under(key: str) -> bool:
            return (
                key == prefix
                or key.startswith(f"{prefix}/")
                or key.startswith(f"{prefix}-")
            )

        return (
            any(is_under(k) for k in self._content)
            or any(is_under(k) for k in self._form)
            or any(is_under(k) for k in self._list_items)
            or any(is_under(k) for k in self._headline)
            or any(is_under(k) for k in self._code_spec)
        )

    @property
    def content_paths(self) -> Iterable[str]:
        return self._content.keys()

    @property
    def form_paths(self) -> Iterable[str]:
        return self._form.keys()

    @property
    def list_paths(self) -> Iterable[str]:
        return self._list_items.keys()

    def form_field_names(self, path: str) -> Iterable[str]:
        return self._form.get(path, {}).keys()

    def list_item_count(self, list_path: str) -> int:
        return len(self._list_items.get(list_path, []))

    # --- persistence --------------------------------------------------------

    def to_json(self) -> dict[str, Any]:
        """A plain-data view of every value held, for persistence. Only
        non-empty stores are included, and each is sorted by full section-ID
        path so the saved file diffs/merges cleanly. The inverse of
        :meth:`load_json`."""
        out: dict[str, Any] = {}
        if self._content:
            out["content"] = {k: self._content[k] for k in sorted(self._content)}
        if self._form:
            out["forms"] = {
                k: {f: self._form[k][f] for f in sorted(self._form[k])}
                for k in sorted(self._form)
            }
        if self._list_items:
            lists: dict[str, Any] = {}
            for k in sorted(self._list_items):
                entry: dict[str, Any] = {
                    "seq": self._list_seq.get(k, len(self._list_items[k])),
                    "items": list(self._list_items[k]),
                }
                ids = {
                    item_path: self._item_section_id[item_path]
                    for item_path in self._list_items[k]
                    if item_path in self._item_section_id
                }
                if ids:
                    entry["ids"] = ids
                lists[k] = entry
            out["lists"] = lists
        if self._headline:
            out["headlines"] = {
                k: self._headline[k] for k in sorted(self._headline)
            }
        if self._code_spec:
            out["codeSpecs"] = {
                k: self._code_spec[k] for k in sorted(self._code_spec)
            }
        return out

    def load_json(self, json: dict[str, Any]) -> None:
        """Replaces every store from a :meth:`to_json`-shaped map. Coerces leaf
        values to strings and skips unknown/empty entries."""
        self._content.clear()
        self._form.clear()
        self._list_items.clear()
        self._list_seq.clear()
        self._item_section_id.clear()
        self._headline.clear()
        self._code_spec.clear()

        content = json.get("content")
        if isinstance(content, dict):
            for k, v in content.items():
                if v is not None:
                    self._content[str(k)] = str(v)

        forms = json.get("forms")
        if isinstance(forms, dict):
            for k, fields in forms.items():
                if isinstance(fields, dict):
                    entry = {str(f): str(v) for f, v in fields.items() if v is not None}
                    if entry:
                        self._form[str(k)] = entry

        lists = json.get("lists")
        if isinstance(lists, dict):
            for k, spec in lists.items():
                if isinstance(spec, dict):
                    items = spec.get("items")
                    item_list = [str(it) for it in items] if isinstance(items, list) else []
                    if item_list:
                        self._list_items[str(k)] = item_list
                    seq = spec.get("seq")
                    if isinstance(seq, int):
                        self._list_seq[str(k)] = seq
                    elif isinstance(seq, str) and seq.lstrip("-").isdigit():
                        self._list_seq[str(k)] = int(seq)
                    else:
                        self._list_seq[str(k)] = len(item_list)
                    ids = spec.get("ids")
                    if isinstance(ids, dict):
                        for item_path, id in ids.items():
                            if id is not None:
                                self._item_section_id[str(item_path)] = str(id)

        headlines = json.get("headlines")
        if isinstance(headlines, dict):
            for k, v in headlines.items():
                if v is not None and str(v) != "":
                    self._headline[str(k)] = str(v)

        code_specs = json.get("codeSpecs")
        if isinstance(code_specs, dict):
            for k, v in code_specs.items():
                if v is not None and str(v) != "":
                    self._code_spec[str(k)] = str(v)


@dataclass(frozen=True)
class SpecListItemMove:
    """The result of :meth:`SpecDocument.move_list_item`."""

    #: The moved item's path after the move.
    path: str
    #: Every item path the move changed, old → new: the moved item and each
    #: sibling whose position moved. Values under a renamed item moved with it.
    renamed: dict[str, str] = dc_field(default_factory=dict)
    #: The items (by new path) that were anonymous and now store the id they
    #: had by position, so their identity did not change with their position.
    pinned_ids: dict[str, str] = dc_field(default_factory=dict)


def _section_id_fits_pattern(pattern: str, id: str) -> bool:
    """Whether *id* fits the ``@SectionIdPattern`` *pattern* — its ``xxx``
    placeholder standing for one or more characters, the whole id matched."""
    regex = ".+".join(re.escape(part) for part in pattern.split("xxx"))
    return re.fullmatch(regex, id) is not None


def _rekey_path(key: str, renamed: dict[str, str]) -> str:
    """*key* with the first old path of *renamed* it equals or lies under
    (``old``, ``old/…``, ``old-…``) replaced by its new path; *key* itself when
    it lies under none."""
    for old, now in renamed.items():
        if key == old:
            return now
        if key.startswith(f"{old}/") or key.startswith(f"{old}-"):
            return now + key[len(old):]
    return key
