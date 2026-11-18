r"""Shared typed-value conversion at the store boundary (YRD7) — a faithful port
of ``tom_som_dart_runtime/lib/src/spec_typed_values.dart``.

A :class:`SpecDocument`'s stores hold **plain strings** — that is what the
md/yaml serialization writes (``FieldName: value``) and what keeps every
language runtime's persistence identical. Typed access therefore converts *at
the boundary*: parse on read, format on write. These helpers are that single
boundary, so a typed facade is provably a thin layer over the generic API (they
cannot disagree on a conversion).

Conventions (the typed contract, mirrored by all nine runtimes):
  * absent / empty string ⇒ ``None`` on read; ``None`` on write ⇒ clear (D4);
  * numbers are read the way the TypeScript runtime reads them (the canonical
    reading, decision tspubnondart20 (a)): the text is trimmed of surrounding
    whitespace, an ``int`` is an optional sign and ASCII digits
    (``^[+-]?[0-9]+$``), a ``double`` / ``num`` a decimal or exponent literal
    (``^[+-]?(?:[0-9]+(?:\.[0-9]*)?|\.[0-9]+)(?:[eE][+-]?[0-9]+)?$``);
    everything else — ``nan``, ``inf``, hexadecimal, digit separators such as
    ``1_000``, non-ASCII digits — reads as ``None``, although Python's
    ``int()`` / ``float()`` would take some of it, because a spec value is
    finite;
  * ``float`` — formatting always carries a fraction or an exponent, so an
    integral value round-trips as ``2.0`` rather than ``2`` (Dart's
    ``double.toString``);
  * ``bool`` — stored as ``true`` / ``false`` (lower case, language-neutral);
    parsing accepts exactly those, anything else reads as ``None``;
  * enums — stored as the constant **name** (e.g. ``high``); the generic layer
    validates against the field's ``enum_values`` domain.
"""

from __future__ import annotations

import math
import re
from typing import Iterable, Optional, Union

#: A decimal integer literal with an optional sign.
_INT_TEXT = re.compile(r"[+-]?[0-9]+")

#: A floating literal with an optional exponent (also a plain integer).
_FLOAT_TEXT = re.compile(
    r"[+-]?(?:[0-9]+(?:\.[0-9]*)?|\.[0-9]+)(?:[eE][+-]?[0-9]+)?"
)

#: The characters JavaScript's ``String.prototype.trim`` removes (its
#: WhiteSpace and LineTerminator sets), so every runtime trims the same text.
_TRIM_CHARS = (
    "\t\n\v\f\r \u00a0\u1680\u2000\u2001\u2002\u2003\u2004\u2005"
    "\u2006\u2007\u2008\u2009\u200a\u2028\u2029\u202f\u205f\u3000\ufeff"
)


def _finite(value: float) -> Optional[float]:
    """*value* when it is finite, else ``None``: a literal that overflows
    (``1e400``) is no value, as ``nan`` and ``inf`` are not."""
    return value if math.isfinite(value) else None


def _trimmed(raw: str) -> str:
    return raw.strip(_TRIM_CHARS)


def som_parse_int(raw: Optional[str]) -> Optional[int]:
    """Parses a stored string as ``int``, or ``None`` when absent/unparsable."""
    if raw is None or raw == "":
        return None
    text = _trimmed(raw)
    return int(text, 10) if _INT_TEXT.fullmatch(text) else None


def som_format_int(value: Optional[int]) -> str:
    """Formats an ``int`` for the store; ``None`` becomes ``''`` (clear, D4)."""
    return "" if value is None else str(value)


def som_parse_double(raw: Optional[str]) -> Optional[float]:
    """Parses a stored string as ``float``, or ``None`` when absent/unparsable
    (the text is trimmed; ``nan``, ``inf``, ``1_000`` and the like are refused)."""
    if raw is None or raw == "":
        return None
    text = _trimmed(raw)
    return _finite(float(text)) if _FLOAT_TEXT.fullmatch(text) else None


def som_format_double(value: Optional[float]) -> str:
    """Formats a ``float`` for the store; ``None`` becomes ``''`` (clear, D4).

    A ``float`` always renders with a fraction or an exponent (``2.0``), matching Dart's
    ``double.toString`` — the store is language-neutral, so the same value must
    serialize identically everywhere.
    """
    if value is None:
        return ""
    x = float(value)
    if math.isfinite(x):
        # One layout in every runtime (decision tspubnondart29 (a)): the
        # shortest digits in JavaScript's Number toString layout, ``.0`` on a
        # whole value (``10000000.0``, ``1e-7``, ``1e+21``) — the review
        # pass's float form. ``repr`` alone writes ``1e+16`` and ``1e-07``.
        from .spec_document_yaml import review_scalar
        return review_scalar(x)
    text = repr(x)
    return text if ("." in text or "e" in text or "n" in text) else text + ".0"


def som_parse_num(raw: Optional[str]) -> Optional[Union[int, float]]:
    """Parses a stored string as ``int`` when integral, else ``float``.

    Mirrors Dart's ``num.tryParse``: an integral literal yields an ``int``, so
    ``num`` fields keep the narrower type when the text carries no fraction.
    """
    if raw is None or raw == "":
        return None
    text = _trimmed(raw)
    if _INT_TEXT.fullmatch(text):
        return int(text, 10)
    return _finite(float(text)) if _FLOAT_TEXT.fullmatch(text) else None


def som_format_num(value: Optional[Union[int, float]]) -> str:
    """Formats a ``num`` for the store; ``None`` becomes ``''`` (clear, D4)."""
    if value is None:
        return ""
    if isinstance(value, bool):  # bool is an int subclass in Python
        return som_format_bool(value)
    if isinstance(value, int):
        return som_format_int(value)
    return som_format_double(value)


def som_parse_bool(raw: Optional[str]) -> Optional[bool]:
    """Parses a stored string as ``bool`` — exactly ``true``/``false``."""
    if raw == "true":
        return True
    if raw == "false":
        return False
    return None


def som_format_bool(value: Optional[bool]) -> str:
    """Formats a ``bool`` for the store; ``None`` becomes ``''`` (clear, D4)."""
    if value is None:
        return ""
    return "true" if value else "false"


def som_parse_enum_name(
    raw: Optional[str], values: Iterable[str]
) -> Optional[str]:
    """Parses a stored string as an enum constant name against *values* (the
    field's ``enum_values`` domain). Returns ``None`` when absent or not in the
    domain — a stale/foreign name reads as unset rather than raising, the same
    forgiveness the other parsers extend to malformed numbers."""
    return raw if (raw is not None and raw in list(values)) else None


def som_format_enum_name(name: Optional[str], values: Iterable[str]) -> str:
    """Validates an enum constant *name* against *values* before storing.

    ``None``/empty clears (returns ``''``); a name outside the domain raises
    :class:`ValueError` — writes are strict where reads are forgiving, so a typo
    cannot enter the store.
    """
    if name is None or name == "":
        return ""
    domain = list(values)
    if name not in domain:
        raise ValueError(
            f"{name!r} is not one of the enum values {', '.join(domain)}"
        )
    return name


def som_scalar_base(type_name: Optional[str]) -> Optional[str]:
    """The scalar base of a declared field type: ``int?`` → ``int``; ``None``
    stays ``None``."""
    if type_name is None:
        return None
    return type_name[:-1] if type_name.endswith("?") else type_name


def som_typed_text_readable(type_name: Optional[str], raw: Optional[str]) -> bool:
    """Whether *raw*, stored in a field declared as *type_name*, is text that
    type's parser can read.

    Only ``int``, ``double``, ``num`` and ``bool`` constrain their text; every
    other type (strings, and enums, whose domain ``enumValueUnknown`` checks)
    accepts any text. Empty or absent text is readable: it is how a field is
    unset. The validator reports a stored value this rejects as
    ``valueTypeMismatch``, the setters refuse to store one, and the typed reads
    raise on one — so text a typed field cannot read is never silently read as
    unset.
    """
    if raw is None or raw == "":
        return True
    base = som_scalar_base(type_name)
    if base == "int":
        return som_parse_int(raw) is not None
    if base == "double":
        return som_parse_double(raw) is not None
    if base == "num":
        return som_parse_num(raw) is not None
    if base == "bool":
        return som_parse_bool(raw) is not None
    return True
