"""The generic, meta-model-driven modification API (YRD7) — a faithful port of
``tom_som_dart_runtime/lib/src/spec_editor.dart``.

:class:`SpecEditor` lets a consumer walk any document's meta tree and
create/modify/delete sections, list items, headlines, ids, content and
**typed** form fields *without a generated facade*: every operation resolves
its path against the :class:`SpecModel` first (:meth:`SpecReflection.resolve`)
and converts values at the store boundary through the same
``spec_typed_values`` helpers the generated accessors call — so a typed facade
is provably a thin layer over exactly this API.

Typed contract (mirrored by all nine runtimes):
  * ``int`` / ``float`` / ``num`` / ``bool`` values are native on both sides;
  * enum values travel as validated **constant-name strings** at this generic
    layer (``'high'``), because the generic API has no generated enum types —
    only the facade layer converts to native constants;
  * ``None`` (or ``''``) clears a value (D4);
  * reads are forgiving (unparsable stored text reads as ``None``), writes are
    strict (:class:`ValueError` for a wrong type or an out-of-domain enum
    name).
"""

from __future__ import annotations

import datetime as _dt
from typing import Any, Optional

from .spec_document import SpecDocument
from .spec_model import FormFieldSpec, SpecField, SpecModel
from .spec_reflection import SpecNodeKind, SpecReflection, SpecResolution
from .spec_section_id import generate_list_item_section_id
from .spec_typed_values import (
    som_format_bool,
    som_format_double,
    som_format_enum_name,
    som_format_int,
    som_format_num,
    som_parse_bool,
    som_parse_double,
    som_parse_enum_name,
    som_parse_int,
    som_parse_num,
)


def _scalar_base(type_name: Optional[str]) -> Optional[str]:
    """Strips a trailing ``?`` from a declared type name."""
    if type_name is None:
        return None
    return type_name[:-1] if type_name.endswith("?") else type_name


class SpecEditor:
    """Generic, typed, meta-validated editing over a :class:`SpecDocument`."""

    def __init__(self, document: SpecDocument, reflection: SpecReflection) -> None:
        #: The document being edited (the sparse value stores).
        self.document = document
        #: The value-free meta-model queries the editor validates against.
        self.reflection = reflection

    @classmethod
    def for_model(cls, document: SpecDocument, model: SpecModel) -> "SpecEditor":
        """Convenience: builds the editor for *document* over *model*."""
        return cls(document, SpecReflection(model))

    # --- resolution ---------------------------------------------------------

    def resolve(self, path: str) -> SpecResolution:
        """Resolves *path* against the meta-model, raising :class:`ValueError`
        for a dangling path — the strict companion to
        :meth:`SpecReflection.resolve`."""
        r = self.reflection.resolve(path)
        if r is None:
            raise ValueError(f"path {path!r} does not resolve against the model")
        return r

    # --- value leaves (content / scalar / enum / scalar list item) ----------

    def value(self, path: str) -> Any:
        """The typed value at the value leaf *path*, or ``None`` when unset.

        The returned type follows the model: ``int``/``float``/``num``/``bool``
        scalars return the parsed native value, enum leaves the validated
        constant name, everything else the raw string. Raises
        :class:`ValueError` when *path* is not a value leaf.
        """
        r = self._value_leaf(path)
        raw = self.document.content(path)
        if raw is None or raw == "":
            return None
        if r.kind == SpecNodeKind.ENUM_VALUE:
            return som_parse_enum_name(raw, r.field.enum_values if r.field else [])
        return _parse_scalar(raw, _scalar_base(r.field.type if r.field else None))

    def set_value(self, path: str, v: Any) -> None:
        """Sets the value leaf at *path* to *v*, converting at the store
        boundary.

        ``None`` clears. For typed scalars *v* must be the native type (or a
        string, taken verbatim); for enum leaves *v* must be one of the field's
        constant names. Raises :class:`ValueError` for a non-leaf path, a wrong
        value type, or an out-of-domain enum name.
        """
        r = self._value_leaf(path)
        self.document.set_content(path, self._format(v, r.kind, r.field, path))

    def _value_leaf(self, path: str) -> SpecResolution:
        r = self.resolve(path)
        if not r.is_value_leaf:
            raise ValueError(
                f"path {path!r} is a {r.kind.value} node, not a value leaf"
            )
        return r

    # --- headlines (YRD3) ---------------------------------------------------

    def headline(self, path: str) -> Optional[str]:
        """The stored headline at *path*, or ``None`` when the section renders
        its effective default title."""
        self.resolve(path)
        return self.document.headline(path)

    def set_headline(self, path: str, value: Optional[str]) -> None:
        """Sets the stored headline at *path*; empty/``None`` returns the
        section to its default title."""
        self.resolve(path)
        self.document.set_headline(path, value or "")

    # --- typed form fields --------------------------------------------------

    def form_value(self, path: str, field: str) -> Any:
        """The typed value of form *field* at the ``@Form`` section *path*, or
        ``None`` when unset.

        Raises :class:`ValueError` for a non-form path or an unknown field.
        """
        ff = self._form_field(path, field)
        raw = self.document.form_field(path, field)
        if raw is None or raw == "":
            return None
        if ff.enum_values:
            return som_parse_enum_name(raw, ff.enum_values)
        return _parse_scalar(raw, _scalar_base(ff.type))

    def set_form_value(self, path: str, field: str, v: Any) -> None:
        """Sets form *field* at the ``@Form`` section *path* to the typed value
        *v* (``None`` clears), converting through the shared boundary helpers.

        Raises :class:`ValueError` for a wrong value type or an out-of-domain
        enum name.
        """
        ff = self._form_field(path, field)
        if ff.enum_values:
            stored = som_format_enum_name(
                self._string_or_none(v, path, field), ff.enum_values
            )
        else:
            stored = self._format(
                v, SpecNodeKind.SCALAR, None, path, type_name=ff.type, where=field
            )
        self.document.set_form_field(path, field, stored)

    def form_fields(self, path: str) -> list[FormFieldSpec]:
        """The form-field specs of the ``@Form`` section at *path*, in
        declaration order — the meta a generic editor UI renders from."""
        r = self.resolve(path)
        if r.kind != SpecNodeKind.FORM:
            raise ValueError(
                f"path {path!r} is a {r.kind.value} node, not a @Form section"
            )
        return r.field.form_fields if r.field else []

    def _form_field(self, path: str, field: str) -> FormFieldSpec:
        r = self.resolve(path)
        if r.kind != SpecNodeKind.FORM:
            raise ValueError(
                f"path {path!r} is a {r.kind.value} node, not a @Form section"
            )
        for ff in (r.field.form_fields if r.field else []):
            if ff.name == field:
                return ff
        raise ValueError(f"{field!r} is not a form field of {path}")

    # --- structural operations ----------------------------------------------

    def add_list_item(
        self,
        list_path: str,
        section_id: Optional[str] = None,
        month: Optional[int] = None,
        day: Optional[int] = None,
    ) -> str:
        """Appends a new item to the list at *list_path* and returns its stable
        item path.

        When the list field carries a ``@SectionIdPattern`` and no explicit
        *section_id* is given, a fresh id is generated from the pattern
        (:func:`generate_list_item_section_id`, dated *month*/*day* — defaulting
        to today). Raises :class:`ValueError` when *list_path* is not a list.
        """
        r = self.resolve(list_path)
        if r.kind != SpecNodeKind.LIST:
            raise ValueError(
                f"path {list_path!r} is a {r.kind.value} node, not a list"
            )
        id_ = section_id
        pattern = r.field.section_id_pattern if r.field else None
        if id_ is None and pattern is not None:
            today = _dt.date.today()
            id_ = generate_list_item_section_id(
                pattern,
                today.month if month is None else month,
                today.day if day is None else day,
                self.document.list_item_section_ids(list_path),
            )
        return self.document.add_list_item(list_path, id_)

    def remove_list_item(self, item_path: str) -> bool:
        """Removes the list item at *item_path* with every value beneath it.
        Returns ``True`` when an item was found and removed."""
        return self.document.remove_list_item(item_path)

    def clear_section(self, path: str) -> None:
        """Clears every value at *path* and beneath it — content, form entries,
        nested list items, stored headlines and ids — returning the subtree to
        the untouched "empty = no value" state (D4). The node itself remains
        addressable (structure lives in the model, not the document)."""
        self.resolve(path)
        self.document.remove_values_under(path)

    # --- conversion ----------------------------------------------------------

    def _format(
        self,
        v: Any,
        kind: SpecNodeKind,
        field: Optional[SpecField],
        path: str,
        type_name: Optional[str] = None,
        where: Optional[str] = None,
    ) -> str:
        """Formats *v* for the store per the leaf's declared type; strings pass
        through verbatim (the plain-text serialization is authoritative)."""
        if v is None:
            return ""
        if kind == SpecNodeKind.ENUM_VALUE:
            return som_format_enum_name(
                self._string_or_none(v, path, where or path),
                field.enum_values if field else [],
            )
        base = _scalar_base(type_name if type_name is not None else
                            (field.type if field else None))
        is_bool = isinstance(v, bool)
        is_int = isinstance(v, int) and not is_bool
        is_float = isinstance(v, float)
        if base == "int":
            if is_int:
                return som_format_int(v)
        elif base == "double":
            if is_float:
                return som_format_double(v)
            if is_int:
                return som_format_double(float(v))
        elif base == "num":
            if is_int or is_float:
                return som_format_num(v)
        elif base == "bool":
            if is_bool:
                return som_format_bool(v)
        if isinstance(v, str):
            return v
        raise ValueError(
            f"{v!r} at {where or path}: wrong value type for a "
            f"{base or 'String'} field"
        )

    def _string_or_none(self, v: Any, path: str, field: str) -> Optional[str]:
        if v is None:
            return None
        if isinstance(v, str):
            return v
        raise ValueError(f"{field}: expected a str for this field of {path}")


def _parse_scalar(raw: str, base: Optional[str]) -> Any:
    """Parses stored text per the declared scalar base type."""
    if base == "int":
        return som_parse_int(raw)
    if base == "double":
        return som_parse_double(raw)
    if base == "num":
        return som_parse_num(raw)
    if base == "bool":
        return som_parse_bool(raw)
    return raw
