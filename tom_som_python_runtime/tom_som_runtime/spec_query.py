"""Lexical/structural query + lazy cursor over a live :class:`SpecDocument`
(``llm_and_d4rt_tools.md`` §6, ``som_multiplatform_spec_model.md`` §15) — a
faithful port of ``tom_som_dart_runtime/lib/src/spec_query.dart``.

This is the **grep-like** facility the downstream D4rt scripting layer and the
editor's search tools reuse. It is **embedding-free** — exact substring or
:class:`SomTextPattern` match plus structural filters — so it is always current
and needs no model calls.

A :class:`SpecQuery` composes (AND-combined) over five dimensions:

  * **text** — substring or :class:`SomTextPattern` over content + form-field
    values and over a node's headline, stored or doc-comment (optionally
    case-insensitive);
  * **kind** — one or more :class:`SpecNodeKind`s;
  * **class** — the model class a node *is* (by class name);
  * **id / path** — exact ``@SectionId``, ``@SectionId`` prefix, path glob, or a
    ``@MapsTo`` / ``@DetailedIn`` target on the node's class;
  * **state** — empty / non-empty (the structural "empty = no value" test).

:meth:`SpecQueryEngine.query` returns a :class:`SpecQueryCursor` the caller
iterates lazily (:meth:`~SpecQueryCursor.next` / :meth:`~SpecQueryCursor.take` /
:attr:`~SpecQueryCursor.count`). The cursor captures the **structural**
candidate set when it is created, then **re-validates each path against the live
document on every step** — so a result whose list-item ancestor was removed
after the cursor was made is silently skipped (stable against concurrent edits,
llm_and_d4rt_tools.md §6).
"""

from __future__ import annotations

from dataclasses import dataclass, field
from enum import Enum
from typing import Iterator, Optional

from .spec_document import SpecDocument
from .spec_model import SpecClass, SpecFieldKind, SpecModel
from .spec_paths import spec_path_join, spec_path_segments, split_list_item_segment
from .spec_reflection import SpecNodeKind, SpecReflection, SpecResolution
from .spec_serialization_order import SpecSerializationOrder
from .spec_text_pattern import SomTextPattern, SpecMatchSpan


class SpecStateFilter(Enum):
    """Whether a node currently holds a value, used by the ``state``
    dimension."""

    #: The node (and everything beneath it) holds no value.
    EMPTY = "empty"
    #: The node holds at least one value at or beneath its path.
    NON_EMPTY = "nonEmpty"


@dataclass(frozen=True)
class SpecNodeProjection:
    """A flat, value-bearing projection of one document node — everything the
    tier-1 structural/lexical index (``llm_and_d4rt_tools.md`` §9.2) needs to
    index a section **without re-walking the model itself**: its path, kind,
    class, the structural facets (section id, ``@MapsTo`` / ``@DetailedIn``), the
    headline, the searchable strings (stored values + headline), and whether it
    currently holds a value.

    Produced by :meth:`SpecQueryEngine.project_nodes` /
    :meth:`SpecQueryEngine.project_node`, which reuse the same
    structural-closure walk and value extraction the live query uses — so the
    index and the live llm_and_d4rt_tools.md §6 search agree on what a node is
    and what text it carries — with no model (LLM) calls.
    """

    #: The globally-unique section-id path the node lives at.
    path: str
    #: What kind of node the path lands on.
    kind: SpecNodeKind
    #: The model class the node *is* (``None`` for value leaves and list
    #: containers).
    class_id: Optional[str] = None
    #: The node's ``@SectionId`` (field, class, or root), ``None`` when none.
    section_id: Optional[str] = None
    #: The ``@MapsTo`` target on the node's class, ``None`` when none.
    maps_to: Optional[str] = None
    #: The ``@DetailedIn`` target on the node's class, ``None`` when none.
    detailed_in: Optional[str] = None
    #: The node's headline — the stored one when the author set it, else the
    #: model's doc comment. ``None`` when neither exists.
    headline: Optional[str] = None
    #: The strings a text search indexes for this node: stored values (content,
    #: scalar item, every form-field value) followed by the headline. Empty for
    #: a container node that carries no direct value and has no headline.
    searchable_strings: list[str] = field(default_factory=list)
    #: Whether the node (or anything beneath it) currently holds a value — the
    #: ``state`` facet (empty vs non-empty).
    has_value: bool = False

    def __str__(self) -> str:
        return f"SpecNodeProjection({self.path}, {self.kind.value})"


@dataclass(frozen=True)
class SpecQueryMatch:
    """One node matched by a :class:`SpecQuery` (the llm_and_d4rt_tools.md §6
    cursor record)."""

    #: The globally-unique section-ID path the node lives at.
    path: str
    #: What kind of node the path lands on.
    kind: SpecNodeKind
    #: The model class the node *is* (``None`` for value leaves and list
    #: containers).
    class_id: Optional[str] = None
    #: The node's headline — stored if the author set one, else the model's doc
    #: comment (``None`` when neither exists).
    headline: Optional[str] = None
    #: The matched text, when the query carried a ``text`` dimension (``None``
    #: otherwise) — the value/headline that the pattern hit.
    snippet: Optional[str] = None
    #: The spans within :attr:`snippet` the ``text`` pattern matched (empty for
    #: non-text queries).
    match_spans: list[SpecMatchSpan] = field(default_factory=list)

    def __str__(self) -> str:
        return f"SpecQueryMatch({self.path}, {self.kind.value})"


@dataclass(frozen=True)
class SpecQuery:
    """An AND-combined lexical/structural query (llm_and_d4rt_tools.md §6).
    Every supplied dimension must hold for a node to match; an all-``None`` query
    matches every node in the document's structural closure."""

    #: Substring (or :attr:`regex` pattern) to find in content + form values and
    #: the headline.
    text: Optional[str] = None
    #: Treat :attr:`text` as a :class:`SomTextPattern` — the portable pattern
    #: subset (``.``, ``*``, ``+``, ``?``, ``[…]``, ``^``, ``$``) — instead of a
    #: literal substring. Named ``regex`` because that is what a caller reaches
    #: for it expecting; the grammar is deliberately narrower than a full regex,
    #: and :class:`SomPatternError` says so rather than silently reinterpreting.
    regex: bool = False
    #: Match :attr:`text` case-insensitively.
    case_insensitive: bool = False
    #: The node kinds to include (any-of); ``None`` admits every kind.
    kinds: Optional[set[SpecNodeKind]] = None
    #: The model class name a node must *be* (:attr:`SpecResolution.target_class`).
    class_name: Optional[str] = None
    #: The node's ``@SectionId`` must equal this exactly.
    section_id_exact: Optional[str] = None
    #: The node's ``@SectionId`` must start with this prefix.
    section_id_prefix: Optional[str] = None
    #: A glob over the node's path (``*`` matches within one segment, ``**``
    #: across segments).
    path_glob: Optional[str] = None
    #: The node's class must carry ``@MapsTo(<this>)``.
    maps_to: Optional[str] = None
    #: The node's class must carry ``@DetailedIn(<this>)``.
    detailed_in: Optional[str] = None
    #: The node's value-presence state must match this.
    state: Optional[SpecStateFilter] = None


class SpecQueryEngine:
    """Runs :class:`SpecQuery`s over a (:class:`SpecModel`,
    :class:`SpecDocument`) pair, producing :class:`SpecQueryCursor`s."""

    def __init__(self, model: SpecModel, document: SpecDocument) -> None:
        #: The meta-model describing the document's structure.
        self.model = model
        #: The live document whose values are searched.
        self.document = document
        self._reflection = SpecReflection(model)
        #: Model-declaration ordering for form fields — see
        #: :meth:`_searchable_strings`.
        self._order = SpecSerializationOrder(model)

    def query(self, query: SpecQuery) -> "SpecQueryCursor":
        """Builds a cursor over the nodes matching *query*. The structural
        candidate set is computed now (document order); value-dependent filters
        and path liveness are re-checked as the cursor advances.

        Raises :class:`SomPatternError` when ``query.regex`` is set and
        ``query.text`` is not in the portable subset. The pattern is compiled
        **here**, not on first use, for two reasons: a malformed pattern is the
        caller's mistake and should surface at the call that made it, and a
        cursor that happens to visit no candidate would otherwise swallow the
        error entirely.
        """
        pattern = None if query.text is None else self._pattern_for(query)
        candidates: list[str] = []
        for path in self._enumerate_paths():
            resolution = self._reflection.resolve(path)
            if resolution is None:
                continue
            if self._matches_structural(query, resolution):
                candidates.append(path)
        return SpecQueryCursor(
            engine=self,
            query=query,
            pattern=pattern,
            candidate_paths=candidates,
        )

    # --- flat node projection (tier-1 index source) -------------------------

    def project_nodes(self) -> Iterator[SpecNodeProjection]:
        """Projects every indexable node of the live document (the
        llm_and_d4rt_tools.md §6 structural closure) as a flat
        :class:`SpecNodeProjection`, in document order. Reuses the same walk and
        value extraction the query uses, so the index built from these
        projections and the live llm_and_d4rt_tools.md §6 search agree on what a
        node is and what text it carries. Pure object-model traversal — no model
        (LLM) calls."""
        for path in self._enumerate_paths():
            projection = self.project_node(path)
            if projection is not None:
                yield projection

    def project_node(self, path: str) -> Optional[SpecNodeProjection]:
        """Projects the single node at *path*, or ``None`` when the path no
        longer resolves against the model. Used for the index's incremental
        refresh: a caller re-projects only the changed section paths."""
        resolution = self._reflection.resolve(path)
        if resolution is None:
            return None
        target = resolution.target_class
        return SpecNodeProjection(
            path=path,
            kind=resolution.kind,
            class_id=target.name if target is not None else None,
            section_id=self._section_id_of(resolution),
            maps_to=target.maps_to if target is not None else None,
            detailed_in=target.detailed_in if target is not None else None,
            headline=self._headline_of(resolution),
            searchable_strings=list(self._searchable_strings(resolution)),
            has_value=self.document.has_values_under(path),
        )

    # --- structural-closure enumeration -------------------------------------

    def _enumerate_paths(self) -> Iterator[str]:
        """Every addressable node of the document in document order: the root,
        each singular complex/section node on the spine (bounded by cycle
        detection), each list container, each *existing* list item, and every
        declared leaf."""
        for root in self.model.roots:
            segment = self._reflection.root_segment(root)
            yield from self._walk(
                segment, self.model.class_named(root.type), {root.type}
            )

    def _walk(
        self,
        path: str,
        cls: Optional[SpecClass],
        ancestor_types: set[str],
    ) -> Iterator[str]:
        yield path  # the node itself (root / complex / section container)
        if cls is None:
            return
        for f in cls.fields:
            field_path = spec_path_join(path, self._reflection.field_segment(f))
            if f.kind in (
                SpecFieldKind.CONTENT,
                SpecFieldKind.ENUM,
                SpecFieldKind.SCALAR,
                SpecFieldKind.FORM,
            ):
                yield field_path  # a value leaf
            elif f.kind == SpecFieldKind.LIST:
                yield field_path  # the list container node
                for item_path in self.document.list_items(field_path):
                    if (
                        f.element_is_complex
                        and f.element_type is not None
                        and f.element_type not in ancestor_types
                    ):
                        yield from self._walk(
                            item_path,
                            self.model.class_named(f.element_type),
                            ancestor_types | {f.element_type},
                        )
                    else:
                        # scalar item, or a recursive/unknown element
                        yield item_path
            else:  # complex / section
                if f.type is not None and f.type not in ancestor_types:
                    yield from self._walk(
                        field_path,
                        self.model.class_named(f.type),
                        ancestor_types | {f.type},
                    )
                else:
                    yield field_path  # recursive/unknown target: a terminal node

    # --- predicates ----------------------------------------------------------

    def _matches_structural(
        self, query: SpecQuery, resolution: SpecResolution
    ) -> bool:
        """The model-fixed dimensions (kind / class / id / path / maps_to /
        detailed_in)."""
        target = resolution.target_class
        if query.kinds is not None and resolution.kind not in query.kinds:
            return False
        if query.class_name is not None and (
            target is None or target.name != query.class_name
        ):
            return False

        section_id = self._section_id_of(resolution)
        if query.section_id_exact is not None and section_id != query.section_id_exact:
            return False
        if query.section_id_prefix is not None and not (
            section_id is not None and section_id.startswith(query.section_id_prefix)
        ):
            return False
        if query.path_glob is not None and not _glob_matches(
            query.path_glob, resolution.path
        ):
            return False
        if query.maps_to is not None and (
            target is None or target.maps_to != query.maps_to
        ):
            return False
        if query.detailed_in is not None and (
            target is None or target.detailed_in != query.detailed_in
        ):
            return False
        return True

    def _evaluate_live(
        self, query: SpecQuery, pattern: Optional[SomTextPattern], path: str
    ) -> Optional[SpecQueryMatch]:
        """The value-reading dimensions (text / state), re-evaluated against the
        live document. Returns the built match (with snippet/spans) or ``None``
        when the node no longer satisfies the query. Assumes the path is
        structurally valid."""
        if not self._is_live_path(path):
            return None
        resolution = self._reflection.resolve(path)
        if resolution is None:
            return None

        if query.state is not None:
            has_value = self.document.has_values_under(path)
            want_value = query.state == SpecStateFilter.NON_EMPTY
            if has_value != want_value:
                return None

        snippet: Optional[str] = None
        spans: list[SpecMatchSpan] = []
        if pattern is not None:
            hit = self._match_text(pattern, resolution)
            if hit is None:
                return None
            snippet, spans = hit

        target = resolution.target_class
        return SpecQueryMatch(
            path=path,
            kind=resolution.kind,
            class_id=target.name if target is not None else None,
            headline=self._headline_of(resolution),
            snippet=snippet,
            match_spans=spans,
        )

    def _match_text(
        self, pattern: SomTextPattern, resolution: SpecResolution
    ) -> Optional[tuple[str, list[SpecMatchSpan]]]:
        # Search each candidate string in turn; the first that hits wins, so the
        # snippet is the actual text the pattern matched.
        for text in self._searchable_strings(resolution):
            spans = self._spans_in(pattern, text)
            if spans:
                return (text, spans)
        return None

    def _searchable_strings(self, resolution: SpecResolution) -> Iterator[str]:
        """The strings a ``text`` query searches at *resolution*: stored values
        first (content leaf, scalar list item, every form field), then the node's
        headline.

        Form fields are yielded in **model declaration order** (SOM §9,
        "Form-field order"), never in the document's storage order, via
        :meth:`SpecSerializationOrder.order_form_fields`. The order is
        observable: it decides which string a ``text`` query reports as its
        snippet, and it is pinned verbatim by ``projection_cases.json``. A field
        the document holds but the model does not declare is still yielded —
        dropping a stored value from a text search would hide it — but last and
        sorted."""
        path = resolution.path
        if resolution.kind in (
            SpecNodeKind.CONTENT,
            SpecNodeKind.ENUM_VALUE,
            SpecNodeKind.SCALAR,
            SpecNodeKind.LIST_ITEM_SCALAR,
        ):
            value = self.document.content(path)
            if value is not None:
                yield value
        elif resolution.kind == SpecNodeKind.FORM:
            for name in self._order.order_form_fields(
                path, self.document.form_field_names(path)
            ):
                value = self.document.form_field(path, name)
                if value is not None:
                    yield value
        # root / complex / section / list / listItemComplex: container nodes
        # carry no direct value.
        headline = self._headline_of(resolution)
        if headline is not None:
            yield headline

    def _pattern_for(self, query: SpecQuery) -> SomTextPattern:
        assert query.text is not None
        if query.regex:
            return SomTextPattern.compile(
                query.text, case_insensitive=query.case_insensitive
            )
        return SomTextPattern.literal(
            query.text, case_insensitive=query.case_insensitive
        )

    def _spans_in(
        self, pattern: SomTextPattern, text: str
    ) -> list[SpecMatchSpan]:
        return pattern.all_matches(text)

    # --- path liveness (cursor stability) -----------------------------------

    def _is_live_path(self, path: str) -> bool:
        """Whether *path* still exists in the live document: every ``-<seq>``
        list-item segment must still be present in its parent list. Model-fixed
        segments (root, complex/section, declared leaves) are always structurally
        live, so only list items can go stale (via
        :meth:`SpecDocument.remove_list_item`)."""
        segments = spec_path_segments(path)
        prefix = ""
        for i, segment in enumerate(segments):
            previous = prefix
            prefix = segment if i == 0 else spec_path_join(prefix, segment)
            split = split_list_item_segment(segment)
            if split is None:
                continue
            list_path = (
                split.base if i == 0 else spec_path_join(previous, split.base)
            )
            resolution = self._reflection.resolve(list_path)
            if (
                resolution is not None
                and resolution.kind == SpecNodeKind.LIST
                and prefix not in self.document.list_items(list_path)
            ):
                return False
        return True

    # --- node descriptors ----------------------------------------------------

    def _section_id_of(self, resolution: SpecResolution) -> Optional[str]:
        if resolution.field is not None and resolution.field.section_id is not None:
            return resolution.field.section_id
        if (
            resolution.target_class is not None
            and resolution.target_class.section_id is not None
        ):
            return resolution.target_class.section_id
        return resolution.root.section_id

    def _headline_of(self, resolution: SpecResolution) -> Optional[str]:
        """The headline a node actually shows: the document's **stored**
        headline when the author set one, otherwise the model's doc comment.

        The stored value comes first because it is the one a reader sees and the
        one an author would search for. Consulting only the doc comment made
        renamed sections unfindable — ``set_headline('DEMO/SUM', 'Executive
        Summary')`` stored text that no query could reach and that never entered
        the search index built from :meth:`project_nodes`.
        """
        stored = self.document.headline(resolution.path)
        if stored is not None:
            return stored
        if resolution.field is not None and resolution.field.doc is not None:
            return resolution.field.doc
        if (
            resolution.target_class is not None
            and resolution.target_class.doc is not None
        ):
            return resolution.target_class.doc
        if resolution.kind == SpecNodeKind.ROOT:
            return resolution.root.description
        return None


_K_ASTERISK = 0x2A  # *
_K_SLASH = 0x2F  # /


def _glob_matches(glob: str, path: str) -> bool:
    """Glob match over a whole path: ``**`` spans ``/``, a single ``*`` stays
    within one segment, every other character is literal.

    Matched directly rather than compiled to a regex, because two of the nine
    runtimes have no regex engine and because a wildcard walk is a smaller, more
    obviously identical thing to transcribe than an escaping rule plus somebody
    else's matcher (see :class:`SomTextPattern`).
    """
    return _glob_at([ord(c) for c in glob], 0, [ord(c) for c in path], 0)


def _glob_at(glob: list[int], g: int, path: list[int], p: int) -> bool:
    """Greedy wildcard walk with backtracking: at a ``*``/``**`` try the longest
    remaining span first and give characters back until the tail fits."""
    while g < len(glob):
        if glob[g] != _K_ASTERISK:
            if p >= len(path) or path[p] != glob[g]:
                return False
            g += 1
            p += 1
            continue
        crosses_segments = g + 1 < len(glob) and glob[g + 1] == _K_ASTERISK
        after_wildcard = g + (2 if crosses_segments else 1)
        # Longest first, so `*` behaves greedily exactly as the regex did.
        limit = len(path)
        if not crosses_segments:
            for i in range(p, len(path)):
                if path[i] == _K_SLASH:
                    limit = i
                    break
        for take in range(limit, p - 1, -1):
            if _glob_at(glob, after_wildcard, path, take):
                return True
        return False
    return p == len(path)


class SpecQueryCursor:
    """A lazy, forward-only cursor over the nodes matching a :class:`SpecQuery`
    (llm_and_d4rt_tools.md §6).

    The cursor holds the structural candidate paths captured when it was created;
    each step re-validates the path against the **live** document and re-applies
    the value-dependent filters, so concurrent edits never surface stale or
    newly-mismatching results. It is forward-only: :meth:`next` / :meth:`take`
    consume matches; :attr:`count` peeks the remaining matches without consuming.
    """

    def __init__(
        self,
        engine: SpecQueryEngine,
        query: SpecQuery,
        pattern: Optional[SomTextPattern],
        candidate_paths: list[str],
    ) -> None:
        self._engine = engine
        self._query = query
        #: The query's ``text`` dimension, compiled once when the cursor was
        #: built. ``None`` when the query has no text dimension at all.
        self._pattern = pattern
        self._candidate_paths = candidate_paths
        self._position = 0

    def next(self) -> Optional[SpecQueryMatch]:
        """The next matching node, or ``None`` when the cursor is exhausted.
        Skips candidates whose path went stale or no longer satisfies the live
        filters."""
        while self._position < len(self._candidate_paths):
            path = self._candidate_paths[self._position]
            self._position += 1
            match = self._engine._evaluate_live(self._query, self._pattern, path)
            if match is not None:
                return match
        return None

    def take(self, n: int) -> list[SpecQueryMatch]:
        """Up to *n* further matches (fewer when the cursor is exhausted
        first)."""
        out: list[SpecQueryMatch] = []
        for _ in range(n):
            match = self.next()
            if match is None:
                break
            out.append(match)
        return out

    def to_list(self) -> list[SpecQueryMatch]:
        """Every remaining match, draining the cursor."""
        out: list[SpecQueryMatch] = []
        while True:
            match = self.next()
            if match is None:
                return out
            out.append(match)

    @property
    def count(self) -> int:
        """How many matches remain from the current position, without consuming
        any. Re-validates each remaining candidate against the live document, so
        the count reflects the document as it is *now*."""
        remaining = 0
        for i in range(self._position, len(self._candidate_paths)):
            if (
                self._engine._evaluate_live(
                    self._query, self._pattern, self._candidate_paths[i]
                )
                is not None
            ):
                remaining += 1
        return remaining
