"""Shared typed-value conversion at the store boundary (YRD7) — a faithful port
of ``tom_som_dart_runtime/lib/src/spec_typed_values.dart``.

A :class:`SpecDocument`'s stores hold **plain strings** — that is what the
md/yaml serialization writes (``FieldName: value``) and what keeps every
language runtime's persistence identical. Typed access therefore converts *at
the boundary*: parse on read, format on write. These helpers are that single
boundary, so a typed facade is provably a thin layer over the generic API (they
cannot disagree on a conversion).

Conventions (the typed contract, mirrored by all nine runtimes):
  * absent / empty string ⇒ ``None`` on read; ``None`` on write ⇒ clear (D4);
  * ``int`` — decimal integer, :func:`som_parse_int` returns ``None`` for
    non-numeric text;
  * ``float`` — accepts any parsable floating literal (also plain integers);
    formatting always carries a decimal point, so an integral value round-trips
    as ``2.0`` rather than ``2`` (Dart's ``double.toString``);
  * ``bool`` — stored as ``true`` / ``false`` (lower case, language-neutral);
    parsing accepts exactly those, anything else reads as ``None``;
  * enums — stored as the constant **name** (e.g. ``high``); the generic layer
    validates against the field's ``enum_values`` domain.
"""

from __future__ import annotations

from typing import Iterable, Optional, Union


def som_parse_int(raw: Optional[str]) -> Optional[int]:
    """Parses a stored string as ``int``, or ``None`` when absent/unparsable."""
    if raw is None or raw == "":
        return None
    try:
        return int(raw, 10)
    except ValueError:
        return None


def som_format_int(value: Optional[int]) -> str:
    """Formats an ``int`` for the store; ``None`` becomes ``''`` (clear, D4)."""
    return "" if value is None else str(value)


def som_parse_double(raw: Optional[str]) -> Optional[float]:
    """Parses a stored string as ``float``, or ``None`` when unparsable."""
    if raw is None or raw == "":
        return None
    try:
        return float(raw)
    except ValueError:
        return None


def som_format_double(value: Optional[float]) -> str:
    """Formats a ``float`` for the store; ``None`` becomes ``''`` (clear, D4).

    A ``float`` always renders with a decimal point (``2.0``), matching Dart's
    ``double.toString`` — the store is language-neutral, so the same value must
    serialize identically everywhere.
    """
    if value is None:
        return ""
    text = repr(float(value))
    return text if ("." in text or "e" in text or "n" in text) else text + ".0"


def som_parse_num(raw: Optional[str]) -> Optional[Union[int, float]]:
    """Parses a stored string as ``int`` when integral, else ``float``.

    Mirrors Dart's ``num.tryParse``: an integral literal yields an ``int``, so
    ``num`` fields keep the narrower type when the text carries no fraction.
    """
    if raw is None or raw == "":
        return None
    try:
        return int(raw, 10)
    except ValueError:
        pass
    try:
        return float(raw)
    except ValueError:
        return None


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
