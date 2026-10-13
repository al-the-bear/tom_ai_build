"""The DocSpecs schema tier over a SOM document, with each finding bound to
the document path it is about (SOM §14).

:class:`DocSpecsValidator` judges Markdown and knows nothing of the document
it came from, so its findings name a section id and a rendition line. A
section id repeats across a document — every functional requirement has a
``FRED`` form — so the id alone does not say which node to fix. The renderer
is the one place that knows which node each heading came from
(:meth:`SpecDocumentMarkdown.export_root_with_map`); this entry point renders,
validates, and fills :attr:`DocSpecsViolation.path` from that map.
"""

from __future__ import annotations

from typing import Optional

from .docspecs_validator import DocSpecsSchema, DocSpecsValidator, DocSpecsViolation
from .spec_document import SpecDocument
from .spec_model import SpecModel


def validate_spec_document(
    model: SpecModel,
    document: SpecDocument,
    schema: DocSpecsSchema,
    root_type: Optional[str] = None,
) -> list[DocSpecsViolation]:
    """Renders *document* (root *root_type*, else its single populated root),
    validates the rendition against *schema*, and returns every finding with
    :attr:`DocSpecsViolation.path` set to the document path of the section its
    line belongs to (an already-set path is kept).

    A finding about a missing child names the **parent** — the section whose
    heading its line points at — exactly as its ``section_id`` does."""
    rendition = document.to_markdown_with_map(model, root_type)
    return [
        DocSpecsViolation(
            rule=v.rule,
            line=v.line,
            message=v.message,
            section_id=v.section_id,
            path=v.path if v.path is not None else rendition.path_at_line(v.line),
        )
        for v in DocSpecsValidator(schema).validate_markdown(rendition.markdown)
    ]
