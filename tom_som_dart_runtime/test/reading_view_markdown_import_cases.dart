// The reading view's Markdown import cases (04a_rdv1, SOM §11.4, §11.5,
// §11.7): form tables, section tables, `refs` and `records` list bodies,
// heading anchors, the field-given-twice rule and the `unknownField` /
// `malformedBlock` rejections; the readable header and appendix marker of a
// stripped rendition and its styled-div headings (04a_rdv5, SOM §11.1,
// §11.2). `_markdownImportCases` in conformance_test.dart appends them to `markdown_import_cases.json`; each carries
// `"readingView": true`, which the runtimes that do not read the table forms
// yet skip (the reading view's parity audit, 05a_rdv4, ports them).
//
// Expected values were computed by the Dart parser and checked by hand
// against the grammar of the reading view's part *Parser and DocSpecs*.

/// The cases, in the shape of `markdown_import_cases.json`.
const List<Map<String, Object?>> readingViewMarkdownImportCases = [
  {
    "name": "form table: every scalar kind, a code span holding \\|",
    "readingView": true,
    "markdown":
        "# <!--[DEMO]--> Demo Document\n\n## <!--[DET]--> Details & Contacts\n\n| TomSpecField | Value |\n| --- | --- |\n| Owner | Bob |\n| Estimate | 8 |\n| Weight | 2.5 |\n| Active | true |\n| Priority | high |\n| Pattern | `^(a\\|b)\$` |\n",
    "rejections": [],
    "document": {
      "forms": {
        "DEMO/DET": {
          "active": "true",
          "estimate": "8",
          "owner": "Bob",
          "pattern": "^(a|b)\$",
          "priority": "high",
          "weight": "2.5",
        },
      },
      "headlines": {"DEMO/DET": "Details & Contacts"},
    },
  },
  {
    "name":
        "form table: reference links in a cell are read as their link texts",
    "readingView": true,
    "markdown":
        "# <!--[DEMO]--> Demo Document\n\n## <!--[REG]--> Registry\n\n### <!--[RGL-LST]--> Links\n\n#### <!--[RGL-1]--> Link 1\n\n| Section | TomSpecField | Value |\n| --- | --- | --- |\n| RGL-DET | EntryId | [RGE-ALPHA](#RGE-ALPHA) |\n|  | AnyRefs | [RGE-A](#RGE-A), [RGE-B](other.tomspecs.md#RGE-B) |\n|  | EntryCode | [not a link] text |\n",
    "rejections": [],
    "document": {
      "forms": {
        "DEMO/REG/RGL-LST-1/RGL-DET": {
          "anyRefs": "RGE-A, RGE-B",
          "entryCode": "[not a link] text",
          "entryId": "RGE-ALPHA",
        },
      },
      "lists": {
        "DEMO/REG/RGL-LST": {
          "seq": 1,
          "items": ["DEMO/REG/RGL-LST-1"],
          "ids": {"DEMO/REG/RGL-LST-1": "RGL-1"},
        },
      },
      "headlines": {"DEMO/REG/RGL-LST-1": "Link 1"},
    },
  },
  {
    "name": "form table: prose before and after the table is the preamble",
    "readingView": true,
    "markdown":
        "# <!--[DEMO]--> Demo Document\n\n## <!--[DET]--> Details & Contacts\n\nCaptured during the November review.\n\n| TomSpecField | Value |\n| --- | --- |\n| Owner | Bob |\n\nA closing remark.\n",
    "rejections": [],
    "document": {
      "content": {
        "DEMO/DET": "Captured during the November review.\n\nA closing remark.",
      },
      "forms": {
        "DEMO/DET": {"owner": "Bob"},
      },
      "headlines": {"DEMO/DET": "Details & Contacts"},
    },
  },
  {
    "name":
        "form table: table – text – table, fields reordered and one left out",
    "readingView": true,
    "markdown":
        "# <!--[DEMO]--> Demo Document\n\n## <!--[DET]--> Details & Contacts\n\n| TomSpecField | Value |\n| --- | --- |\n| Priority | high |\n| Owner | Bob |\n\nContact: bob@example.com\n- on call: weekdays\n\n| TomSpecField | Value |\n| --- | --- |\n| Active | true |\n",
    "rejections": [],
    "document": {
      "forms": {
        "DEMO/DET": {
          "active": "true",
          "contact": "bob@example.com\n- on call: weekdays",
          "owner": "Bob",
          "priority": "high",
        },
      },
      "headlines": {"DEMO/DET": "Details & Contacts"},
    },
  },
  {
    "name":
        "form table: a slot marker before a form table in a region with two forms",
    "readingView": true,
    "markdown":
        "# <!--[DEMO]--> Demo Document\n\n## <!--[MIX]--> Mixed\n\n| TomSpecField | Value |\n| --- | --- |\n| Lead | Ada |\n| Risk | low |\n\n<!-- slot: alt -->\n\n| TomSpecField | Value |\n| --- | --- |\n| Lead | Bob |\n",
    "rejections": [],
    "document": {
      "forms": {
        "DEMO/MIX/alt": {"lead": "Bob"},
        "DEMO/MIX/content": {"lead": "Ada", "risk": "low"},
      },
    },
  },
  {
    "name": "a preamble holding a table of its own is content",
    "readingView": true,
    "markdown":
        "# <!--[DEMO]--> Demo Document\n\n## <!--[DET]--> Details & Contacts\n\n| Field | Value |\n| --- | --- |\n| Owner | Finance |\n\nOwner: Bob\n",
    "rejections": [],
    "document": {
      "content": {
        "DEMO/DET": "| Field | Value |\n| --- | --- |\n| Owner | Finance |",
      },
      "forms": {
        "DEMO/DET": {"owner": "Bob"},
      },
      "headlines": {"DEMO/DET": "Details & Contacts"},
    },
  },
  {
    "name": "a table after a Field: line without a layout header is that value",
    "readingView": true,
    "markdown":
        "# <!--[DEMO]--> Demo Document\n\n## <!--[DET]--> Details & Contacts\n\nContact: the desks\n| Desk | Phone |\n| --- | --- |\n| North | 100 |\n",
    "rejections": [],
    "document": {
      "forms": {
        "DEMO/DET": {
          "contact":
              "the desks\n| Desk | Phone |\n| --- | --- |\n| North | 100 |",
        },
      },
      "headlines": {"DEMO/DET": "Details & Contacts"},
    },
  },
  {
    "name":
        "a content line shaped like a layout header carries one escape space",
    "readingView": true,
    "markdown":
        "# <!--[DEMO]--> Demo Document\n\n## <!--[DET]--> Details & Contacts\n\nThe fields at a glance:\n\n | TomSpecField | Value |\n| --- | --- |\n| Colour | red |\n\n| TomSpecField | Value |\n| --- | --- |\n| Owner | Bob |\n",
    "rejections": [],
    "document": {
      "content": {
        "DEMO/DET":
            "The fields at a glance:\n\n| TomSpecField | Value |\n| --- | --- |\n| Colour | red |",
      },
      "forms": {
        "DEMO/DET": {"owner": "Bob"},
      },
      "headlines": {"DEMO/DET": "Details & Contacts"},
    },
  },
  {
    "name":
        "notation inside a preamble and a field value is kept byte for byte",
    "readingView": true,
    "markdown":
        "# <!--[DEMO]--> Demo Document\n\n## <!--[DET]--> Details & Contacts\n\n::: {.provenance}\n_Extrapolated — see iterations/notes.md._\n:::\n\nContact: bob@example.com [weekdays only]{.aside} (-> C2.1)\n::: aside\nA note.\n:::\n",
    "rejections": [],
    "document": {
      "content": {
        "DEMO/DET":
            "::: {.provenance}\n_Extrapolated — see iterations/notes.md._\n:::",
      },
      "forms": {
        "DEMO/DET": {
          "contact":
              "bob@example.com [weekdays only]{.aside} (-> C2.1)\n::: aside\nA note.\n:::",
        },
      },
      "headlines": {"DEMO/DET": "Details & Contacts"},
    },
  },
  {
    "name":
        "heading anchors equal to the id are removed, another anchor is title",
    "readingView": true,
    "markdown":
        "# <!--[DEMO]--> Demo Document\n\n## <!--[TTL]--> <a id=\"TTL\"></a> Document Title\n\nHello\n\n## <!--[SUM]--> <a id=\"OTHER\"></a> Summary\n\nText\n",
    "rejections": [],
    "document": {
      "content": {"DEMO/SUM": "Text", "DEMO/TTL": "Hello"},
      "headlines": {"DEMO/SUM": "<a id=\"OTHER\"></a> Summary"},
    },
  },
  {
    "name":
        "records table: Title column, an empty cell, a stored id, a <br> title",
    "readingView": true,
    "markdown":
        "# <!--[DEMO]--> Demo Document\n\n## <!--[CARD-LST]--> Cards\n\n::: {.records}\n| Id | Title | Note | Selector |\n| --- | --- | --- | --- |\n| <a id=\"CARD-1\"></a>CARD-1 |  | first card | `a.b` |\n| <a id=\"CARD-ALPHA\"></a>CARD-ALPHA | Alpha<br>Card | second card |  |\n:::\n",
    "rejections": [],
    "document": {
      "forms": {
        "DEMO/CARD-LST-1/content": {"note": "first card", "selector": "a.b"},
        "DEMO/CARD-LST-2/content": {"note": "second card"},
      },
      "lists": {
        "DEMO/CARD-LST": {
          "seq": 2,
          "items": ["DEMO/CARD-LST-1", "DEMO/CARD-LST-2"],
          "ids": {"DEMO/CARD-LST-1": "CARD-1", "DEMO/CARD-LST-2": "CARD-ALPHA"},
        },
      },
      "headlines": {"DEMO/CARD-LST-2": "Alpha\nCard"},
    },
  },
  {
    "name": "records table without a Title column, a bare kind",
    "readingView": true,
    "markdown":
        "# <!--[DEMO]--> Demo Document\n\n## <!--[CARD-LST]--> Cards\n\n::: records\n| Id | Note |\n| --- | --- |\n| CARD-1 | one |\n| CARD-2 | two |\n:::\n",
    "rejections": [],
    "document": {
      "forms": {
        "DEMO/CARD-LST-1/content": {"note": "one"},
        "DEMO/CARD-LST-2/content": {"note": "two"},
      },
      "lists": {
        "DEMO/CARD-LST": {
          "seq": 2,
          "items": ["DEMO/CARD-LST-1", "DEMO/CARD-LST-2"],
          "ids": {"DEMO/CARD-LST-1": "CARD-1", "DEMO/CARD-LST-2": "CARD-2"},
        },
      },
    },
  },
  {
    "name": "reference line: links and a bare id become reference items",
    "readingView": true,
    "markdown":
        "# <!--[DEMO]--> Demo Document\n\n## <!--[REG]--> Registry\n\n### <!--[RGR-LST]--> Refs\n\n::: {.refs}\n[RGE-ALPHA](#RGE-ALPHA), [RGE-BETA](other.tomspecs.md#RGE-BETA),\nRGE-GAMMA\n:::\n",
    "rejections": [],
    "document": {
      "forms": {
        "DEMO/REG/RGR-LST-1/RGR-REF": {"ref": "RGE-ALPHA"},
        "DEMO/REG/RGR-LST-2/RGR-REF": {"ref": "RGE-BETA"},
        "DEMO/REG/RGR-LST-3/RGR-REF": {"ref": "RGE-GAMMA"},
      },
      "lists": {
        "DEMO/REG/RGR-LST": {
          "seq": 3,
          "items": [
            "DEMO/REG/RGR-LST-1",
            "DEMO/REG/RGR-LST-2",
            "DEMO/REG/RGR-LST-3",
          ],
          "ids": {
            "DEMO/REG/RGR-LST-1": "RGR-1",
            "DEMO/REG/RGR-LST-2": "RGR-2",
            "DEMO/REG/RGR-LST-3": "RGR-3",
          },
        },
      },
    },
  },
  {
    "name": "section table: a form child and list items rebuild the children",
    "readingView": true,
    "markdown":
        "# <!--[DEMO]--> Demo Document\n\n## <!--[DLV-LST]--> Deliverables\n\n### <!--[DLV-1]--> Deliverable 1\n\n| TomSpecField | Value |\n| --- | --- |\n| UnitId | demo_client |\n\n| Section | TomSpecField | Value |\n| --- | --- | --- |\n| <a id=\"DLR-1\"></a>DLR-LST / DLR-1 | Area | CE-NV |\n|  | Mapping | dart-tom |\n| <a id=\"DLR-2\"></a>DLR-LST / DLR-2 | Area | CE-DB |\n",
    "rejections": [],
    "document": {
      "forms": {
        "DEMO/DLV-LST-1/DLR-LST-1/content": {
          "area": "CE-NV",
          "mapping": "dart-tom",
        },
        "DEMO/DLV-LST-1/DLR-LST-2/content": {"area": "CE-DB"},
        "DEMO/DLV-LST-1/content": {"unitId": "demo_client"},
      },
      "lists": {
        "DEMO/DLV-LST": {
          "seq": 1,
          "items": ["DEMO/DLV-LST-1"],
          "ids": {"DEMO/DLV-LST-1": "DLV-1"},
        },
        "DEMO/DLV-LST-1/DLR-LST": {
          "seq": 2,
          "items": ["DEMO/DLV-LST-1/DLR-LST-1", "DEMO/DLV-LST-1/DLR-LST-2"],
          "ids": {
            "DEMO/DLV-LST-1/DLR-LST-1": "DLR-1",
            "DEMO/DLV-LST-1/DLR-LST-2": "DLR-2",
          },
        },
      },
    },
  },
  {
    "name":
        "section table: a Section cell naming no child section is rejected, the others land",
    "readingView": true,
    "markdown":
        "# <!--[DEMO]--> Demo Document\n\n## <!--[DLV-LST]--> Deliverables\n\n### <!--[DLV-1]--> Deliverable 1\n\n| Section | TomSpecField | Value |\n| --- | --- | --- |\n| NOPE | Area | x |\n|  | Mapping | y |\n| DLR-LST / DLR-1 | Area | CE-NV |\n",
    "rejections": [
      {
        "line": 9,
        "reason": "unknownSection",
        "anchor": "NOPE",
        "message":
            "section-table row names no child section of \"DEMO/DLV-LST-1\"",
      },
    ],
    "document": {
      "forms": {
        "DEMO/DLV-LST-1/DLR-LST-1/content": {"area": "CE-NV"},
      },
      "lists": {
        "DEMO/DLV-LST": {
          "seq": 1,
          "items": ["DEMO/DLV-LST-1"],
          "ids": {"DEMO/DLV-LST-1": "DLV-1"},
        },
        "DEMO/DLV-LST-1/DLR-LST": {
          "seq": 1,
          "items": ["DEMO/DLV-LST-1/DLR-LST-1"],
          "ids": {"DEMO/DLV-LST-1/DLR-LST-1": "DLR-1"},
        },
      },
    },
  },
  {
    "name": "rejection: a layout table without its delimiter row",
    "readingView": true,
    "markdown":
        "# <!--[DEMO]--> Demo Document\n\n## <!--[DET]--> Details & Contacts\n\n| TomSpecField | Value |\n| Owner | Bob |\n\nContact: c\n",
    "rejections": [
      {
        "line": 5,
        "reason": "malformedBlock",
        "anchor": "DEMO/DET",
        "message": "table without its delimiter row",
      },
    ],
    "document": {
      "forms": {
        "DEMO/DET": {"contact": "c"},
      },
      "headlines": {"DEMO/DET": "Details & Contacts"},
    },
  },
  {
    "name": "rejection: a row with another cell count, the other rows land",
    "readingView": true,
    "markdown":
        "# <!--[DEMO]--> Demo Document\n\n## <!--[DET]--> Details & Contacts\n\n| TomSpecField | Value |\n| --- | --- |\n| Owner | Bob | extra |\n| Contact | c |\n",
    "rejections": [
      {
        "line": 7,
        "reason": "malformedBlock",
        "anchor": "DEMO/DET",
        "message": "table row with 3 cells, the header has 2",
      },
    ],
    "document": {
      "forms": {
        "DEMO/DET": {"contact": "c"},
      },
      "headlines": {"DEMO/DET": "Details & Contacts"},
    },
  },
  {
    "name": "rejection: a form row naming no field, the other rows land",
    "readingView": true,
    "markdown":
        "# <!--[DEMO]--> Demo Document\n\n## <!--[DET]--> Details & Contacts\n\n| TomSpecField | Value |\n| --- | --- |\n| Ownr | Bob |\n| Contact | c |\n",
    "rejections": [
      {
        "line": 7,
        "reason": "unknownField",
        "anchor": "DEMO/DET",
        "message": "row \"Ownr\" names no field of this form",
      },
    ],
    "document": {
      "forms": {
        "DEMO/DET": {"contact": "c"},
      },
      "headlines": {"DEMO/DET": "Details & Contacts"},
    },
  },
  {
    "name": "rejection: a records column naming no field skips the table",
    "readingView": true,
    "markdown":
        "# <!--[DEMO]--> Demo Document\n\n## <!--[CARD-LST]--> Cards\n\n::: {.records}\n| Id | Note | Colour |\n| --- | --- | --- |\n| CARD-1 | one | red |\n:::\n",
    "rejections": [
      {
        "line": 6,
        "reason": "unknownField",
        "anchor": "DEMO/CARD-LST",
        "message": "records column \"Colour\" names no field of the items",
      },
    ],
    "document": {},
  },
  {
    "name": "rejection: a field given twice as two rows",
    "readingView": true,
    "markdown":
        "# <!--[DEMO]--> Demo Document\n\n## <!--[DET]--> Details & Contacts\n\n| TomSpecField | Value |\n| --- | --- |\n| Owner | Bob |\n| Owner | Ada |\n",
    "rejections": [
      {
        "line": 8,
        "reason": "malformedBlock",
        "anchor": "DEMO/DET",
        "message": "field \"owner\" given twice",
      },
    ],
    "document": {
      "forms": {
        "DEMO/DET": {"owner": "Bob"},
      },
      "headlines": {"DEMO/DET": "Details & Contacts"},
    },
  },
  {
    "name": "rejection: a field given twice as a row and a paragraph",
    "readingView": true,
    "markdown":
        "# <!--[DEMO]--> Demo Document\n\n## <!--[DET]--> Details & Contacts\n\n| TomSpecField | Value |\n| --- | --- |\n| Owner | Bob |\n\nOwner: Ada\nmore of Ada\n",
    "rejections": [
      {
        "line": 9,
        "reason": "malformedBlock",
        "anchor": "DEMO/DET",
        "message": "field \"owner\" given twice",
      },
    ],
    "document": {
      "forms": {
        "DEMO/DET": {"owner": "Bob"},
      },
      "headlines": {"DEMO/DET": "Details & Contacts"},
    },
  },
  {
    "name":
        "rejection: a field given twice as two paragraphs (the Field: form)",
    "readingView": true,
    "markdown":
        "# <!--[DEMO]--> Demo Document\n\n## <!--[DET]--> Details & Contacts\n\nOwner: Bob\n\nContact: c\n\nOwner: Ada\n",
    "rejections": [
      {
        "line": 9,
        "reason": "malformedBlock",
        "anchor": "DEMO/DET",
        "message": "field \"owner\" given twice",
      },
    ],
    "document": {
      "forms": {
        "DEMO/DET": {"contact": "c", "owner": "Bob"},
      },
      "headlines": {"DEMO/DET": "Details & Contacts"},
    },
  },
  {
    "name": "rejection: a refs div beside other text in a list container",
    "readingView": true,
    "markdown":
        "# <!--[DEMO]--> Demo Document\n\n## <!--[REG]--> Registry\n\n### <!--[RGR-LST]--> Refs\n\nSome text.\n\n::: {.refs}\nRGE-ALPHA\n:::\n",
    "rejections": [
      {
        "line": 9,
        "reason": "malformedBlock",
        "anchor": "DEMO/REG/RGR-LST",
        "message": "a refs div beside other text in a list container",
      },
    ],
    "document": {
      "content": {"DEMO/REG/RGR-LST": "Some text."},
    },
  },
  {
    "name": "rejection: a records div beside item headings",
    "readingView": true,
    "markdown":
        "# <!--[DEMO]--> Demo Document\n\n## <!--[CARD-LST]--> Cards\n\n::: {.records}\n| Id | Note |\n| --- | --- |\n| CARD-1 | one |\n:::\n\n### <!--[CARD-2]--> Card 2\n\nNote: two\n",
    "rejections": [
      {
        "line": 5,
        "reason": "malformedBlock",
        "anchor": "DEMO/CARD-LST",
        "message": "a records div beside item headings in a list container",
      },
    ],
    "document": {
      "forms": {
        "DEMO/CARD-LST-2/content": {"note": "two"},
      },
      "lists": {
        "DEMO/CARD-LST": {
          "seq": 2,
          "items": ["DEMO/CARD-LST-2"],
          "ids": {"DEMO/CARD-LST-2": "CARD-2"},
        },
      },
    },
  },
  {
    "name": "rejection: a records div holding no table",
    "readingView": true,
    "markdown":
        "# <!--[DEMO]--> Demo Document\n\n## <!--[CARD-LST]--> Cards\n\n::: {.records}\njust text\n:::\n",
    "rejections": [
      {
        "line": 5,
        "reason": "malformedBlock",
        "anchor": "DEMO/CARD-LST",
        "message": "a records div holding no table",
      },
    ],
    "document": {},
  },
  {
    "name": "rejection: a records table whose first column is not Id",
    "readingView": true,
    "markdown":
        "# <!--[DEMO]--> Demo Document\n\n## <!--[CARD-LST]--> Cards\n\n::: {.records}\n| Note | Selector |\n| --- | --- |\n| one | a |\n:::\n",
    "rejections": [
      {
        "line": 5,
        "reason": "malformedBlock",
        "anchor": "DEMO/CARD-LST",
        "message": "a records table whose first column is not Id",
      },
    ],
    "document": {},
  },
  {
    "name": "rejection: an empty refs div",
    "readingView": true,
    "markdown":
        "# <!--[DEMO]--> Demo Document\n\n## <!--[REG]--> Registry\n\n### <!--[RGR-LST]--> Refs\n\n::: {.refs}\n:::\n",
    "rejections": [
      {
        "line": 7,
        "reason": "missingValue",
        "anchor": "DEMO/REG/RGR-LST",
        "message": "an empty refs div",
      },
    ],
    "document": {},
  },
  {
    "name": "rejection: an unclosed refs fence reads as text",
    "readingView": true,
    "markdown":
        "# <!--[DEMO]--> Demo Document\n\n## <!--[REG]--> Registry\n\n### <!--[RGR-LST]--> Refs\n\n::: {.refs}\nRGE-ALPHA\n",
    "rejections": [
      {
        "line": 7,
        "reason": "malformedBlock",
        "anchor": "DEMO/REG/RGR-LST",
        "message": "unclosed refs fence",
      },
    ],
    "document": {
      "content": {"DEMO/REG/RGR-LST": "::: {.refs}\nRGE-ALPHA"},
    },
  },
  {
    "name":
        "readable header: skipped before the root heading, and the appendix after its marker is not read",
    "readingView": true,
    "markdown":
        "<!-- docspec: demo-document/1.0 -->\n<!-- readable: drop=provenance,trace,comments; unmark=editorial; headings=divs; of=demo.tomspecs.yaml@r7; commit=8e1d2a7+dirty -->\n# <!--[DEMO]--> <a id=\"DEMO\"></a> Demo Document\n\n## <!--[SUM]--> <a id=\"SUM\"></a> Summary\n\nText.\n\n<!-- readable-appendix -->\n\n## Notes\n\n### Summary\n\n**[1]** A note.\n",
    "readableHeader":
        "<!-- readable: drop=provenance,trace,comments; unmark=editorial; headings=divs; of=demo.tomspecs.yaml@r7; commit=8e1d2a7+dirty -->",
    "rejections": [],
    "document": {
      "content": {"DEMO/SUM": "Text."},
    },
  },
  {
    "name":
        "readable header: elsewhere it is text, and so is the appendix marker without one",
    "readingView": true,
    "markdown":
        "# <!--[DEMO]--> Demo Document\n\n## <!--[SUM]--> Summary\n\n<!-- readable: drop=aside -->\nText.\n\n<!-- readable-appendix -->\n",
    "readableHeader": null,
    "rejections": [],
    "document": {
      "content": {
        "DEMO/SUM":
            "<!-- readable: drop=aside -->\nText.\n\n<!-- readable-appendix -->",
      },
    },
  },
  {
    "name":
        "styled-div headings at levels 7, 12 and 13; a heading6 div and an escaped div are content",
    "readingView": true,
    "markdown":
        "# <!--[DEMO]--> Demo Document\n\n<div class=\"heading7\" style=\"margin:1em 0 0.5em;padding-left:0.75em;font-weight:bold\"><!--[SUM]--> <a id=\"SUM\"></a> Summary &amp; &lt;More&gt;<br>Second</div>\n\nText.\n\n<div class=\"heading6\" style=\"x\">Six</div>\n\n\\<div class=\"heading8\" style=\"x\">Eight</div>\n\n## <!--[REG]--> Registry\n\n<div class=\"heading12\" style=\"margin:1em 0 0.5em;padding-left:4.5em;font-weight:bold\"><!--[RGL-LST]--> <a id=\"RGL-LST\"></a> Links</div>\n\n<div class=\"heading13\" style=\"margin:1em 0 0.5em;padding-left:5.25em;font-weight:bold\"><!--[RGL-1]--> Link 1</div>\n\n| Section | TomSpecField | Value |\n| --- | --- | --- |\n| RGL-DET | EntryId | RGE-ALPHA |\n",
    "rejections": [],
    "document": {
      "content": {
        "DEMO/SUM":
            "Text.\n\n<div class=\"heading6\" style=\"x\">Six</div>\n\n<div class=\"heading8\" style=\"x\">Eight</div>",
      },
      "forms": {
        "DEMO/REG/RGL-LST-1/RGL-DET": {"entryId": "RGE-ALPHA"},
      },
      "lists": {
        "DEMO/REG/RGL-LST": {
          "seq": 1,
          "items": ["DEMO/REG/RGL-LST-1"],
          "ids": {"DEMO/REG/RGL-LST-1": "RGL-1"},
        },
      },
      "headlines": {
        "DEMO/REG/RGL-LST-1": "Link 1",
        "DEMO/SUM": "Summary & <More>\nSecond",
      },
    },
  },
];
