"""The section-path grammar shared by the in-memory document and the meta-model
traversal — a faithful port of `tom_som_dart_runtime/lib/src/spec_paths.dart`.

A path is the globally-unique address of a node in a concrete document:

  * the **root** is the document root's section segment (its ``@SectionId`` when
    present, otherwise the root class name);
  * a **child field** appends ``/<segment>``;
  * a **complex / section** field collapses into its target class (no extra
    segment — the class's children hang directly off the field's path);
  * a **list item** appends ``-<seq>`` to the list field's path (no ``/``).

Form-field values are *not* path segments: a ``@Form`` section is one path whose
individual fields are sub-keys inside the document's form store.
"""

from __future__ import annotations

from typing import NamedTuple, Optional

#: The path separator between section segments.
SPEC_PATH_SEPARATOR = "/"


def spec_path_join(parent: str, segment: str) -> str:
    """Joins *parent* with a child *segment* using the path separator."""
    return f"{parent}{SPEC_PATH_SEPARATOR}{segment}"


def spec_path_segments(path: str) -> list[str]:
    """Splits *path* into its ``/``-separated segments. A list-item sequence
    suffix (``<segment>-3``) stays attached to its segment."""
    return path.split(SPEC_PATH_SEPARATOR)


def list_item_path(list_path: str, seq: int) -> str:
    """The path of the *seq*-th item appended to the list at *list_path*."""
    return f"{list_path}-{seq}"


class ListItemSegment(NamedTuple):
    base: str
    seq: int


def split_list_item_segment(segment: str) -> Optional[ListItemSegment]:
    """Splits a list-item *segment* into its base segment and sequence number
    when it ends in ``-<digits>``, or returns ``None`` otherwise.

    Only an all-digit tail counts, so a hyphenated ``@SectionId`` such as
    ``PD00-ROL`` is never mis-read as a list item.
    """
    dash = segment.rfind("-")
    if dash <= 0 or dash == len(segment) - 1:
        return None
    tail = segment[dash + 1:]
    if not tail.isdigit():
        return None
    return ListItemSegment(base=segment[:dash], seq=int(tail))
