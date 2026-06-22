"""A sparse, live instance of a TomSpecs document — a faithful port of
`tom_som_dart_runtime/lib/src/spec_document.dart`.

The structure is defined by the :class:`SpecModel` class graph; this holds only
the *values* the user/agent has actually set, keyed by the globally-unique
section-ID path. Nothing is materialised until written, so an untouched document
is empty (the "empty = no value" rule).

Three sparse stores cover the writable field kinds:

  * ``_content`` — ``content``/``scalar`` leaves: path → string value;
  * ``_form`` — ``@Form`` sections: path → (form-field name → value);
  * ``_list_items`` — lists: list path → ordered item paths.

List item paths are ``"<list_path>-<seq>"`` where ``seq`` is a per-list
monotonic counter that never reuses a number.
"""

from __future__ import annotations

from typing import Any, Iterable, Optional


class SpecDocument:
    def __init__(self) -> None:
        self._content: dict[str, str] = {}
        self._form: dict[str, dict[str, str]] = {}
        self._list_items: dict[str, list[str]] = {}
        self._list_seq: dict[str, int] = {}

    # --- content ------------------------------------------------------------

    def content(self, path: str) -> Optional[str]:
        return self._content.get(path)

    def set_content(self, path: str, value: str) -> None:
        """Sets the content string at *path*. An empty value clears it."""
        if value == "":
            self._content.pop(path, None)
        else:
            self._content[path] = value

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

    def add_list_item(self, list_path: str) -> str:
        """Appends a new item to the list at *list_path* and returns its stable
        path."""
        seq = self._list_seq.get(list_path, 0) + 1
        self._list_seq[list_path] = seq
        item_path = f"{list_path}-{seq}"
        self._list_items.setdefault(list_path, []).append(item_path)
        return item_path

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

        for store in (self._content, self._form, self._list_items, self._list_seq):
            for key in [k for k in store if is_under(k)]:
                store.pop(key, None)

    # --- queries ------------------------------------------------------------

    @property
    def is_empty(self) -> bool:
        return not self._content and not self._form and not self._list_items

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
            out["lists"] = {
                k: {
                    "seq": self._list_seq.get(k, len(self._list_items[k])),
                    "items": list(self._list_items[k]),
                }
                for k in sorted(self._list_items)
            }
        return out

    def load_json(self, json: dict[str, Any]) -> None:
        """Replaces every store from a :meth:`to_json`-shaped map. Coerces leaf
        values to strings and skips unknown/empty entries."""
        self._content.clear()
        self._form.clear()
        self._list_items.clear()
        self._list_seq.clear()

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
