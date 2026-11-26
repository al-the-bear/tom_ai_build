package somruntime

// spec_document_markdown.go — DocSpecs-conform Markdown codec for a TomSpecs
// document (SOM §11), a faithful port of
// `tom_som_dart_runtime/lib/src/spec_document_markdown.dart` (and the
// TypeScript `spec_document_markdown.ts`).
//
// The generated/authored `*.md` **is a genuine DocSpecs document**: line 1 is
// the `<!-- docspec: <schema-id>/<version> -->` declaration, every populated
// section is one markdown heading whose machine-readable identity is the
// DocSpecs headline comment `<!--[SECTION-ID]-->` and whose text is the
// human-readable Title-Case member name. Content values are **normal markdown
// text** under their heading (no fences); `@Form` sections are written as the
// reading view's tables (see below); a list emits its `-LST`
// container heading (id = the list's `@SectionId`, else the member segment)
// at the owner's child level, wrapping the numbered item headings one level
// deeper — each item carrying the `@SectionIdPattern` resolved with the 1-based
// position (`GOAL-ITEM-xxx` → `GOAL-ITEM-1`, else `<member>-<pos>`). The
// container itself carries no body. Id-less members are **transparent** (mirroring
// the schema generator , SOM §13): a transparent value member's text or form block
// is the owner's body region, emitted without a heading and bound at its own
// path; a transparent section/complex member never heads — its id-bearing
// descendants hoist to the owner's child level (paths keep the transparent
// segments). Section/complex headings without a field-level `@SectionId`
// carry the target class's `@SectionId`.
//
// Escaping (SOM §11.3): a content line starting with `#` at column 0 is
// emitted as `\#` (and a leading `\#`… run gains one more backslash), except
// inside fenced code blocks, which shield their lines verbatim. Blank lines
// inside a value are kept as written; parse trims each value of
// leading/trailing blank lines only.
//
// The codec is free of any UI: it reads from / resolves against a SpecModel
// (through the BuildSomMetaTree metadata tree) and a SpecDocument. Parse does
// **not** mutate the document — it returns staged values keyed exactly like
// SpecDocument.ToJSON plus a rejection report; SpecDocument.ApplyMarkdownResult applies them.
// Anything that cannot be mapped — an unknown section id, a child heading
// under a value leaf, orphaned text — is collected into
// SpecMarkdownResult.Rejections rather than dropped (SOM §11.7).
//
// Reading view (SOM §11.2, §11.4, §11.5): the emitter writes form tables
// `| TomSpecField | Value |` between `Field:` paragraphs, record tables in a
// `::: {.records}` div, reference lines in a `::: {.refs}` div, section tables
// `| Section | TomSpecField | Value |` and an HTML anchor `<a id="ID"></a>` in
// every heading (qualified below a list item and in a `@SameAs` copy). A value
// that cannot be one table cell (a `multiParagraph` field, several paragraphs,
// a block, a line shaped like a layout header) stays a `Field:` paragraph; a
// wrapped one-paragraph value is one cell (SpecMarkdownWrappedParagraphJoined,
// SOM §11.4 rule 13). A value line shaped like a layout table header is
// escaped with one space. The parser reads this layout and the older `Field:`
// layout alike.
//
// Go conventions: where the other ports throw, ExportRoot returns an
// error (the unterminated-fence case); the empty string stands in for a null
// Anchor.

import (
	"regexp"
	"sort"
	"strings"
	"unicode"
)

// Why an imported Markdown block was rejected (SOM §11.7 rejection protocol).
const (
	// SpecMarkdownRejectUnknownSection — the heading's section id does not
	// resolve against the schema tree at its nesting position.
	SpecMarkdownRejectUnknownSection = "unknownSection"
	// SpecMarkdownRejectKindMismatch — a structurally impossible combination,
	// e.g. a child heading nested under a value-leaf (content/scalar/enum)
	// section.
	SpecMarkdownRejectKindMismatch = "kindMismatch"
	// SpecMarkdownRejectOrphanContent — body text with no owning value slot:
	// text before the document root heading.
	SpecMarkdownRejectOrphanContent = "orphanContent"
	// SpecMarkdownRejectMissingValue — a value-leaf section heading with an
	// empty body.
	SpecMarkdownRejectMissingValue = "missingValue"
	// SpecMarkdownRejectMalformedHeading — a heading line without a parseable
	// `<!--[id]-->` headline comment.
	SpecMarkdownRejectMalformedHeading = "malformedHeading"
	// SpecMarkdownRejectUnknownField — a form-table row, a section-table row
	// or a records column names no field the form declares (SOM §11.4, §11.5).
	SpecMarkdownRejectUnknownField = "unknownField"
	// SpecMarkdownRejectMalformedBlock — a block that breaks the layout
	// grammar: a table without its delimiter row or with a row of another cell
	// count, a field given twice, a `refs` / `records` div beside other text or
	// item headings or not holding what it should, an unclosed `refs` /
	// `records` fence. The message says which.
	SpecMarkdownRejectMalformedBlock = "malformedBlock"
)

// SpecMarkdownRejection is one rejected block in a Markdown import (SOM §11.7).
// Reported, never silently dropped: each carries the source Line, the
// offending Anchor (section path or id, "" when none), the Reason, and a
// human-readable Message.
type SpecMarkdownRejection struct {
	Line    int
	Reason  string
	Message string
	Anchor  string
}

func (r *SpecMarkdownRejection) String() string {
	anchor := ""
	if r.Anchor != "" {
		anchor = " (" + r.Anchor + ")"
	}
	return "line " + itoa(r.Line) + ": " + r.Reason + anchor + " — " + r.Message
}

// SpecMarkdownResult is the outcome of parsing a Markdown document (SOM §11.7):
// the staged values plus every rejected block. The values are keyed exactly
// like SpecDocument.ToJSON so a caller can merge them into a live document as
// a full overwrite of the covered scope.
type SpecMarkdownResult struct {
	// Content holds content/scalar/enum leaf values (and section body text):
	// path → value.
	Content map[string]string
	// Forms holds form values: form path → (field name → value).
	Forms map[string]map[string]string
	// Lists holds list membership: list path → {seq, items, ids?} (the
	// SpecDocument.ToJSON shape), recovered from the item headings.
	Lists map[string]ListJson
	// Rejections holds every rejected block, in source order.
	Rejections []*SpecMarkdownRejection
	// RootPrefixes holds the root segment(s) the import covers (the first
	// segment of each accepted path) — the scope a full-overwrite apply
	// purges first.
	RootPrefixes map[string]bool
	// Headlines holds stored headlines staged from heading titles (YRD3
	// SOM §11.7): path → headline, populated ONLY when the parsed heading text
	// differs from the effective default derivation (byte-stability — a
	// default title stages nothing).
	Headlines map[string]string
	// CodeSpecs holds stored codeSpec mappings (codespecs_mapping.md §9.2): path →
	// the comma-joined list of CodeSpecs code locations parsed from the
	// `codeSpec="…"` key in the heading comment. Staged whenever present (codeSpec
	// has no effective default).
	CodeSpecs map[string]string
	// Units holds stored generation units (SOM §11.2): path → the comma-joined
	// list of generation-unit ids parsed from the `units="…"` key in the
	// heading comment. Staged whenever present (absent means the default).
	Units map[string]string
}

// SpecMarkdownImport is a Markdown document loaded by SpecDocumentFromMarkdown:
// the document built from every accepted block, and the parse report it came
// from.
type SpecMarkdownImport struct {
	// Document holds every value the parse accepted.
	Document *SpecDocument
	// Result is the parse report, rejections included.
	Result *SpecMarkdownResult
}

// Rejections returns the blocks the parse rejected, in source order; they are
// not in Document.
func (i *SpecMarkdownImport) Rejections() []*SpecMarkdownRejection {
	return i.Result.Rejections
}

// IsClean reports whether the parse was clean (no rejections).
func (r *SpecMarkdownResult) IsClean() bool {
	return len(r.Rejections) == 0
}

// AppliedCount returns the number of leaf values successfully parsed
// (content + form fields).
func (r *SpecMarkdownResult) AppliedCount() int {
	n := len(r.Content)
	for _, m := range r.Forms {
		n += len(m)
	}
	return n
}

// MarkdownFenceTracker is a fence state machine (CommonMark-ish): a line whose
// first non-space run (up to 3 spaces indent) is 3+ backticks or tildes opens
// a fence; a matching same-character run at least as long closes it.
//
// Public so other markdown-processing modules (the DocSpecs validator's
// generic parser) share exactly the same fence semantics as this codec.
type MarkdownFenceTracker struct {
	char byte
	size int
}

// InFence reports whether the tracker is currently inside a fence.
func (t *MarkdownFenceTracker) InFence() bool {
	return t.char != 0
}

// Feed advances the state machine by one line.
func (t *MarkdownFenceTracker) Feed(line string) {
	m := mdFenceOpenRE.FindStringSubmatch(line)
	if m == nil {
		return
	}
	run := m[1]
	if t.char == 0 {
		t.char = run[0]
		t.size = len(run)
		return
	}
	trimmed := strings.TrimSpace(line)
	if run[0] == t.char && len(run) >= t.size &&
		trimmed == strings.Repeat(string(t.char), len(trimmed)) {
		t.char = 0
		t.size = 0
	}
}

// mdBuffer is a tiny StringBuffer with Dart-style writeln semantics.
type mdBuffer struct {
	parts []string
}

func (b *mdBuffer) writeln(text string) {
	b.parts = append(b.parts, text, "\n")
}

// write appends text verbatim — no trailing newline. Used to splice an
// already-terminated buffer (a form's field block) into its owner.
func (b *mdBuffer) write(text string) {
	b.parts = append(b.parts, text)
}

func (b *mdBuffer) String() string {
	return strings.Join(b.parts, "")
}

// Shared with the parser and the DocSpecs validator.
var (
	mdHeadingLineRE = regexp.MustCompile(`^(#+)\s+(.*)$`)
	// The heading HTML comment: `<!--[ID]--> Title` with an optional key=value
	// region between the id bracket and the closing `-->` (codespecs_mapping.md
	// §9.2 codeSpec). Group 1 = the section id, group 2 = the raw key=value region
	// (possibly empty), group 3 = the heading title. The middle group is `[^>]*` —
	// safe because the region's only values are quoted code locations /
	// identifiers, never a raw `>`.
	mdHeadlineCommentRE = regexp.MustCompile(`^<!--\[([^\]]+)\]([^>]*)-->\s*(.*)$`)
	mdDocspecCommentRE  = regexp.MustCompile(`^<!--\s*docspec:.*-->\s*$`)
	// Extracts the `codeSpec="…"` value from a heading-comment key=value region
	// (codespecs_mapping.md §9.2), mirroring the tom_doc_scanner key=value
	// grammar.
	mdCodeSpecRE = regexp.MustCompile(`codeSpec=(?:"([^"]*)"|'([^']*)'|([^,\s>]+))`)
	// Extracts the `units="…"` value from a heading-comment key=value region
	// (SOM §11.2): the same quoting rules as mdCodeSpecRE. The key must start
	// the region or follow whitespace, so a `units=` inside a quoted codeSpec
	// value is not read as the key.
	mdUnitsRE = regexp.MustCompile(`(?:^|\s)units=(?:"([^"]*)"|'([^']*)'|([^,\s>]+))`)
)

var (
	mdFenceOpenRE = regexp.MustCompile("^ {0,3}(`{3,}|~{3,})")

	// A line the emitter must escape: an optional run of backslashes followed
	// by `#` at column 0 (the escape itself must survive the round-trip).
	mdEscapableRE = regexp.MustCompile(`^\\*#`)

	// A line that would parse as a form-field label: `Word:` at column 0
	// (optionally already space-prefixed — each emit pass adds one more
	// space).
	mdLabelShapedRE = regexp.MustCompile(`^ *[A-Za-z][A-Za-z0-9_]*:`)

	mdFieldLabelRE        = regexp.MustCompile(`^([A-Za-z][A-Za-z0-9_]*): ?(.*)$`)
	mdContinuationLabelRE = regexp.MustCompile(`^ +[A-Za-z][A-Za-z0-9_]*:`)
	mdEscapedHeadingRE    = regexp.MustCompile(`^\\+#`)

	mdTrailingWSRE = regexp.MustCompile(`\s+$`)
	mdLeadingNLRE  = regexp.MustCompile(`^\n+`)
	mdTrailingNLRE = regexp.MustCompile(`\n+$`)
	// A slot marker line (SOM §11.6): `<!-- slot: <rel> -->`, `<rel>` a body
	// slot's path relative to its owner, or `.` for the owner itself.
	mdSlotMarkerRE      = regexp.MustCompile(`^<!-- slot: (\S+) -->$`)
	mdLeadingBlankLnRE  = regexp.MustCompile(`^([ \t]*\n)+`)
	mdTrailingBlankLnRE = regexp.MustCompile(`(\n[ \t]*)+$`)

	// Reading view (SOM §11.4, §11.5): a value line shaped like a layout table
	// header is escaped with one space on emit, and loses it on parse.
	mdTableHeaderShapedRE = regexp.MustCompile(
		`(?i)^ *\|\s*(?:Section\s*\|\s*)?TomSpecField\s*\|\s*Value\s*\|?\s*$`)
	mdEscapedTableHeaderRE = regexp.MustCompile(
		`(?i)^ +\|\s*(?:Section\s*\|\s*)?TomSpecField\s*\|\s*Value\s*\|?\s*$`)
	// A line that reads as the header of a form table or a section table (SOM
	// §11.4, §11.5): `| TomSpecField | Value |` or
	// `| Section | TomSpecField | Value |` at column 0, any case; group 1 is
	// `Section` for a section table. The header alone makes a table layout.
	mdLayoutTableHeaderRE = regexp.MustCompile(
		`(?i)^\|\s*(?:(Section)\s*\|\s*)?TomSpecField\s*\|\s*Value\s*\|?\s*$`)
	// A line that starts a table row: `|` after up to three spaces.
	mdTableLineRE     = regexp.MustCompile(`^ {0,3}\|`)
	mdDelimiterCellRE = regexp.MustCompile(`^:?-+:?$`)
	mdLinkCellRE      = regexp.MustCompile(`^\[[^\]]+\]\([^)]*\)(, \[[^\]]+\]\([^)]*\))*$`)
	mdLinkTextRE      = regexp.MustCompile(`\[([^\]]+)\]\([^)]*\)`)
	mdListDivOpenRE   = regexp.MustCompile(`^:{3,}\s*(?:\{\.(refs|records)\}|(refs|records))\s*$`)
	mdDivCloseRE      = regexp.MustCompile(`^:{3,}\s*$`)
	mdCellAnchorRE    = regexp.MustCompile(`^<a id="[^"]*"></a>\s*`)
	mdCellLinkRE      = regexp.MustCompile(`^\[([^\]]+)\]\([^)\s]*\)$`)
	mdSectionSplitRE  = regexp.MustCompile(`\s*/\s*`)
	mdRefsSplitRE     = regexp.MustCompile(`[,\s]+`)
)

// mdQualifyAnchor returns the qualified anchor of a heading id (SOM §11.2) and
// the scope its descendants' anchors are qualified with: below a list item, or
// in a `@SameAs` copy, an anchor is the ids from the scope's start joined by
// `/`; elsewhere it is the id itself. section is the id of the nearest heading
// above that is no list container. A nil scope is "no scope".
func mdQualifyAnchor(scope []string, section, id string, container, item, copyNode bool) (string, []string) {
	joined := func(sc []string) string {
		if sc == nil {
			return id
		}
		return strings.Join(append(append([]string{}, sc...), id), "/")
	}
	switch {
	case container:
		return joined(scope), scope
	case item:
		return joined(scope), append(append([]string{}, scope...), id)
	case copyNode:
		var sc []string
		if scope != nil {
			sc = append([]string{}, scope...)
		} else if section != "" {
			sc = []string{section}
		} else {
			sc = []string{}
		}
		sc = append(sc, id)
		return strings.Join(sc, "/"), sc
	}
	if scope == nil {
		return joined(scope), nil
	}
	return joined(scope), append(append([]string{}, scope...), id)
}

// mdNodeRel is a body slot / effective child: the node plus its relative path.
type mdNodeRel struct {
	node *SomMetaNode
	rel  string
}

// SpecDocumentMarkdown is the codec binding a SpecModel and a concrete
// SpecDocument to the DocSpecs Markdown import/export format (SOM §11).
type SpecDocumentMarkdown struct {
	Model    *SpecModel
	Document *SpecDocument
	// Metadata trees per root type, built lazily (the generated facades
	// will hand these in directly; until then the bridge derives them).
	trees map[string]*SomMetaTree
	// The paths of the headings written by the current export, in emission
	// order (ExportRootWithMap).
	headingPaths []string

	// FileStem and DocumentFiles name the files a reference to another
	// document root links to: `<FileStem>.<root id in lower case>.tomspecs.md`
	// (without the stem when FileStem is empty) unless DocumentFiles names the
	// root's file, keyed by its section id or type.
	FileStem      string
	DocumentFiles map[string]string

	// The document's keys of one kind, sorted once per export for mdUnder.
	sortedKeys map[string][]string
	// The root the current export renders (the target of same-document links).
	currentRoot *SpecRoot
	// The anchors of the root the current export renders (SOM §11.2).
	nav *mdNavigation
	// The class names each root reaches, for reference links.
	reach map[string]map[string]bool
}

// NewSpecDocumentMarkdown binds model and document to the codec.
func NewSpecDocumentMarkdown(model *SpecModel, document *SpecDocument) *SpecDocumentMarkdown {
	return &SpecDocumentMarkdown{
		Model:      model,
		Document:   document,
		trees:      map[string]*SomMetaTree{},
		sortedKeys: map[string][]string{},
		reach:      map[string]map[string]bool{},
	}
}

func (c *SpecDocumentMarkdown) treeFor(rootType string) (*SomMetaTree, error) {
	if tree, ok := c.trees[rootType]; ok {
		return tree, nil
	}
	tree, err := BuildSomMetaTree(c.Model, rootType)
	if err != nil {
		return nil, err
	}
	c.trees[rootType] = tree
	return tree, nil
}

// --- Naming helpers (SOM §11.2 / §11.5) --------------------------------------

// SpecMarkdownTitleCase expands a camel/Pascal-case identifier into Title
// Case: `introductionAndScope` / `DemoItem` → `Introduction And Scope` /
// `Demo Item`.
func SpecMarkdownTitleCase(name string) string {
	var words []string
	buf := ""
	for _, r := range name {
		if unicode.IsUpper(r) && buf != "" {
			words = append(words, buf)
			buf = ""
		}
		buf += string(r)
	}
	if buf != "" {
		words = append(words, buf)
	}
	out := make([]string, len(words))
	for i, w := range words {
		if w == "" {
			out[i] = w
			continue
		}
		rs := []rune(w)
		out[i] = strings.ToUpper(string(rs[0])) + string(rs[1:])
	}
	return strings.Join(out, " ")
}

var (
	mdKebabSpaceRE = regexp.MustCompile(`[\s_]+`)
	mdKebabDropRE  = regexp.MustCompile(`[^A-Za-z0-9-]`)
)

// SpecMarkdownKebabCase derives the DocSpecs schema id of a `@Document` name
// (SOM §11.1): `Demo Document` → `demo-document`.
func SpecMarkdownKebabCase(title string) string {
	s := strings.TrimSpace(title)
	s = mdKebabSpaceRE.ReplaceAllString(s, "-")
	s = mdKebabDropRE.ReplaceAllString(s, "")
	return strings.ToLower(s)
}

// SpecMarkdownItemTitleStem is the item heading title stem: Title-Case element
// class name with a trailing `Entry` dropped (SOM §11.5, normative).
func SpecMarkdownItemTitleStem(elementClassName string) string {
	stem := elementClassName
	if len(stem) > 5 && strings.HasSuffix(stem, "Entry") {
		stem = stem[:len(stem)-5]
	}
	return SpecMarkdownTitleCase(stem)
}

// SpecDocumentMarkdownCodeSpecOf extracts the `codeSpec="…"` value from a heading-comment
// key=value region (codespecs_mapping.md §9.2). Returns the empty string when
// the region carries no `codeSpec` key (first non-empty submatch, trimmed).
func SpecDocumentMarkdownCodeSpecOf(region string) string {
	m := mdCodeSpecRE.FindStringSubmatch(region)
	if m == nil {
		return ""
	}
	for _, g := range m[1:] {
		if g != "" {
			return strings.TrimSpace(g)
		}
	}
	return ""
}

// SpecDocumentMarkdownUnitsOf extracts the `units="…"` value from a heading-comment key=value
// region (SOM §11.2): the same quoting rules as the codeSpec key —
// double-quoted, single-quoted or bare. Returns the empty string when the
// region carries no `units` key (first non-empty submatch, trimmed).
func SpecDocumentMarkdownUnitsOf(region string) string {
	m := mdUnitsRE.FindStringSubmatch(region)
	if m == nil {
		return ""
	}
	for _, g := range m[1:] {
		if g != "" {
			return strings.TrimSpace(g)
		}
	}
	return ""
}

// SpecMarkdownFormLabel is the `FieldName` label written for a form field:
// the model field name with the first letter upper-cased (SOM §11.4).
func SpecMarkdownFormLabel(fieldName string) string {
	if fieldName == "" {
		return fieldName
	}
	rs := []rune(fieldName)
	return strings.ToUpper(string(rs[0])) + string(rs[1:])
}

// --- Export (SOM §11.1–§11.8) ------------------------------------------------

// headingIdOf is the section id written into (and matched from) a heading for
// node (SOM §11.2/§11.8): the field-level `@SectionId` when present; for
// section/complex nodes whose field carries none, the target **class**'s
// `@SectionId` (the id the generated schema types are keyed by); else the path
// segment (the member name).
func (c *SpecDocumentMarkdown) headingIdOf(node *SomMetaNode) string {
	if node.SectionID != "" {
		return node.SectionID
	}
	// The class id is the node's ClassSectionID, as the YAML key uses — never
	// ClassNamed(node.ClassName): a wrapper section (TextSection, ...) carries
	// its OWNER's class name, and that lookup returned the owner's id.
	if node.Kind == SomMetaKindSection || node.Kind == SomMetaKindComplex {
		if node.ClassSectionID != "" {
			return node.ClassSectionID
		}
	}
	return node.Segment()
}

// --- Transparency (SOM §11.2, mirroring the schema generator , SOM §13) ------
//
// The `docspecs-schema` generator (SOM §13) is normative: only **section-bearing**
// nodes (those with a real `@SectionId`, field- or class-level) become
// section types; id-less members are *transparent* — they are not sections
// of their own. The markdown format mirrors that exactly:
//
//   - a transparent value member (content/scalar/enum/form without an id)
//     is emitted headinglessly into its owner's *body region* (text, or a
//     `FieldName: value` form block);
//   - a transparent section/complex member gets no heading; its id-bearing
//     descendants surface as the owner's direct child headings (the
//     schema's "nearest section-bearing descendant" hoisting), with document
//     paths still running through the transparent segments;
//   - lists are never transparent — the `-LST` container always heads (SOM
//     §11.2) at the owner's child level and the items sit one level below it
//     (`@SectionIdPattern` / `<member>-<pos>`).
//
// Principled canonicalisation losses (documented, accepted): multiple
// transparent content members of one owner merge into the first on parse,
// and a form-field label colliding across an owner's transparent forms
// binds to the nearest form in slot order.

// isTransparentSection reports a section/complex member with no field- or
// class-level `@SectionId`: heading-less, its children hoist to the owner.
func (c *SpecDocumentMarkdown) isTransparentSection(n *SomMetaNode) bool {
	if n.Kind != SomMetaKindSection && n.Kind != SomMetaKindComplex {
		return false
	}
	if n.SectionID != "" {
		return false
	}
	// ClassSectionID, not ClassNamed(n.ClassName): see headingIdOf. A wrapper
	// section (TextSection, ...) has neither id, so it is transparent (SOM §11.6).
	return n.ClassSectionID == ""
}

// mdIsTransparentValue reports a value member (content/scalar/enum/form) with
// no `@SectionId`: emitted into the owner's body region instead of under an
// own heading.
func mdIsTransparentValue(n *SomMetaNode) bool {
	return n.SectionID == "" &&
		(n.Kind == SomMetaKindContent ||
			n.Kind == SomMetaKindScalar ||
			n.Kind == SomMetaKindEnumValue ||
			n.Kind == SomMetaKindForm)
}

// bodySlots returns the ordered *body slots* of node: every transparent value
// member and every transparent section (whose own path may carry body text),
// collected depth-first through transparent sections. These are the value
// positions that share the owner's heading body.
func (c *SpecDocumentMarkdown) bodySlots(node *SomMetaNode) []mdNodeRel {
	var out []mdNodeRel
	var collect func(n *SomMetaNode, prefix string)
	collect = func(n *SomMetaNode, prefix string) {
		for _, child := range n.Children {
			if child.Recursive {
				continue
			}
			rel := child.Segment()
			if prefix != "" {
				rel = prefix + "/" + rel
			}
			if mdIsTransparentValue(child) {
				out = append(out, mdNodeRel{child, rel})
			} else if c.isTransparentSection(child) {
				out = append(out, mdNodeRel{child, rel})
				collect(child, rel)
			}
		}
	}
	collect(node, "")
	return out
}

// effectiveChildren returns the ordered *effective children* of node: every
// section-bearing child and every list, hoisted through transparent sections
// — exactly the headings (and item-heading owners) the generated schema knows at
// this position. Each entry carries the relative path from node (which runs
// through the transparent segments).
func (c *SpecDocumentMarkdown) effectiveChildren(node *SomMetaNode) []mdNodeRel {
	var out []mdNodeRel
	var collect func(n *SomMetaNode, prefix string)
	collect = func(n *SomMetaNode, prefix string) {
		for _, child := range n.Children {
			if child.Recursive {
				continue
			}
			rel := child.Segment()
			if prefix != "" {
				rel = prefix + "/" + rel
			}
			if mdIsTransparentValue(child) {
				continue // body region
			}
			if c.isTransparentSection(child) {
				collect(child, rel)
			} else {
				out = append(out, mdNodeRel{child, rel})
			}
		}
	}
	collect(node, "")
	return out
}

// ExportRoot renders the populated subtree of root as a DocSpecs-conform
// Markdown document. Returns an error — the Go analogue of the other ports'
// throw — on the two conditions this format cannot represent without losing
// the round-trip: a content value containing an unterminated fenced code block
// (which would shield the remainder of the document from heading detection),
// and a form holding a field the model does not declare (SOM §9,
// "Form-field order").
func (c *SpecDocumentMarkdown) ExportRoot(root *SpecRoot) (string, error) {
	rendition, err := c.ExportRootWithMap(root)
	if err != nil {
		return "", err
	}
	return rendition.Markdown, nil
}

// ExportRootWithMap is ExportRoot plus the document path behind every heading
// it wrote — the one place that knows which node a heading came from.
//
// A caller holding a rendition line (a DocSpecs schema finding, an editor
// cursor) resolves it through SpecMarkdownRendition.PathAtLine instead of
// re-deriving the renderer's layout. Section ids repeat across a document, so
// the id alone does not say which node a line belongs to. Errors are
// ExportRoot's.
func (c *SpecDocumentMarkdown) ExportRootWithMap(root *SpecRoot) (*SpecMarkdownRendition, error) {
	c.headingPaths = c.headingPaths[:0]
	markdown, err := c.exportRoot(root)
	if err != nil {
		return nil, err
	}
	headingPaths := map[int]string{}
	fence := &MarkdownFenceTracker{}
	next := 0
	for i, line := range strings.Split(markdown, "\n") {
		if next >= len(c.headingPaths) {
			break
		}
		if !fence.InFence() && mdEmittedHeading.MatchString(line) {
			headingPaths[i+1] = c.headingPaths[next]
			next++
		}
		fence.Feed(line)
	}
	return &SpecMarkdownRendition{Markdown: markdown, HeadingPaths: headingPaths}, nil
}

// mdEmittedHeading matches a heading line as writeHeading writes it. Body text
// never matches: heading-like body lines are escaped (SOM §11.3) and fenced
// ones skipped.
var mdEmittedHeading = regexp.MustCompile(`^#+ <!--\[`)

// SpecMarkdownRendition is a Markdown rendition of a document and the
// document path behind each of its headings (ExportRootWithMap).
type SpecMarkdownRendition struct {
	// Markdown is the rendered text, identical to ExportRoot.
	Markdown string
	// HeadingPaths maps every heading line (1-based) to the document path it
	// renders.
	HeadingPaths map[int]string
}

// PathAtLine returns the document path of the section line belongs to: the
// path of the heading on that line, else of the nearest heading above it. ok
// is false for a line before the first heading.
func (r *SpecMarkdownRendition) PathAtLine(line int) (string, bool) {
	for l := line; l >= 1; l-- {
		if p, ok := r.HeadingPaths[l]; ok {
			return p, true
		}
	}
	return "", false
}

func (c *SpecDocumentMarkdown) exportRoot(root *SpecRoot) (string, error) {
	tree, err := c.treeFor(root.Type)
	if err != nil {
		return "", err
	}
	c.currentRoot = root
	c.nav = &mdNavigation{codec: c, tree: tree, anchors: map[string]string{}}
	c.sortedKeys = map[string][]string{}
	defer func() { c.nav = nil }()
	node := tree.Root
	b := &mdBuffer{}
	b.writeln("<!-- docspec: " + SpecMarkdownKebabCase(root.Title) + "/" +
		c.Model.ModelVersionString() + " -->")
	rootSeg := node.Segment()
	// YRD3: a stored headline overrides the derived title at every heading.
	// YRD4: the @Headline default wins over the @Document title.
	rootTitle := c.Document.HeadlineOr(rootSeg)
	if rootTitle == "" {
		rootTitle = node.Headline
	}
	if rootTitle == "" {
		rootTitle = root.Title
	}
	c.writeHeading(b, 1, rootSeg, rootTitle, rootSeg, c.Document.CodeSpecOr(rootSeg), c.Document.UnitsOr(rootSeg))
	if err := c.writeSectionBody(b, node, rootSeg); err != nil {
		return "", err
	}
	if err := c.writeChildren(b, node, rootSeg, 2); err != nil {
		return "", err
	}
	return b.String(), nil
}

// writeSectionBody writes the body region of a section heading: the section
// path's own content value plus every transparent body slot (id-less content
// text and form blocks, hoisted through transparent sections) in model order.
//
// A slot whose text the parser would otherwise bind elsewhere is preceded by a
// slot marker (SOM §11.6): text after anything already written, a form
// preamble that is not the region's default target, and a form whose labels
// another form of the region shares. A body the parser reads correctly without
// markers gets none, so such documents render as before.
func (c *SpecDocumentMarkdown) writeSectionBody(b *mdBuffer, node *SomMetaNode, path string) error {
	slots := c.bodySlots(node)
	if len(slots) == 0 {
		if value, ok := c.Document.Content(path); ok {
			return c.writeBody(b, value, path)
		}
		return nil
	}
	var formSlots []mdNodeRel
	for _, s := range slots {
		if s.node.Kind == SomMetaKindForm {
			formSlots = append(formSlots, s)
		}
	}
	hasForms := len(formSlots) > 0
	defaultRel := mdDefaultBodyRel(slots)
	written := false

	marker := func(rel string) {
		b.writeln("<!-- slot: " + rel + " -->")
		b.writeln("")
	}
	text := func(rel, valuePath string) error {
		value, ok := c.Document.Content(valuePath)
		if !ok {
			return nil
		}
		prepared, err := c.prepareValue(value, valuePath)
		if err != nil {
			return err
		}
		if prepared == "" {
			return nil
		}
		if written || rel != defaultRel {
			marker(rel)
		}
		for _, line := range strings.Split(prepared, "\n") {
			if hasForms && mdLabelShapedRE.MatchString(line) {
				b.writeln(" " + line)
			} else {
				b.writeln(line)
			}
		}
		b.writeln("")
		written = true
		return nil
	}
	formFieldNames := func(n *SomMetaNode) []string {
		var out []string
		if n.Form != nil {
			for _, f := range n.Form.Fields {
				out = append(out, strings.ToLower(f.Name))
			}
		}
		return out
	}

	if err := text(".", path); err != nil {
		return err
	}
	for _, slot := range slots {
		slotPath := path + "/" + slot.rel
		if slot.node.Kind != SomMetaKindForm {
			if err := text(slot.rel, slotPath); err != nil {
				return err
			}
			continue
		}
		if !c.formHasValues(slot.node, slotPath) {
			continue
		}
		hasPreamble := false
		if preamble, ok := c.Document.Content(slotPath); ok {
			prepared, err := c.prepareValue(preamble, slotPath)
			if err != nil {
				return err
			}
			hasPreamble = prepared != ""
		}
		labels := map[string]bool{}
		for _, name := range formFieldNames(slot.node) {
			labels[name] = true
		}
		collides := false
		for _, o := range formSlots {
			if o.rel == slot.rel {
				continue
			}
			for _, name := range formFieldNames(o.node) {
				if labels[name] {
					collides = true
				}
			}
		}
		var needsMarker bool
		if hasPreamble {
			needsMarker = written || slot.rel != defaultRel
		} else {
			needsMarker = collides && (written || formSlots[0].rel != slot.rel)
		}
		if needsMarker {
			marker(slot.rel)
		}
		if err := c.writeForm(b, slot.node, slotPath); err != nil {
			return err
		}
		written = true
	}
	return nil
}

// isCopyNode reports whether n is a `@SameAs` copy (SOM §11.2): its anchor and
// its descendants' are qualified with the section above it.
func (c *SpecDocumentMarkdown) isCopyNode(n *SomMetaNode) bool {
	if n.MemberName == "" || n.parent == nil {
		return false
	}
	cls := c.Model.ClassNamed(n.parent.ClassName)
	if cls == nil {
		return false
	}
	f := cls.FieldNamed(n.MemberName)
	return f != nil && f.HasAnnotation("SameAs")
}

// itemForm returns the item class's own form (its class-level `@Form`, a
// transparent body slot), or ok false when the class carries none or more
// than one.
func (c *SpecDocumentMarkdown) itemForm(element *SomMetaNode) (mdNodeRel, bool) {
	var forms []mdNodeRel
	for _, s := range c.bodySlots(element) {
		if s.node.Kind == SomMetaKindForm {
			forms = append(forms, s)
		}
	}
	if len(forms) != 1 {
		return mdNodeRel{}, false
	}
	return forms[0], true
}

// mdDefaultBodyRel returns the body slot unmarked body text binds to on import
// (SOM §11.6): the first non-form slot; with none, the form on the `content`
// member, else the first form; with no slot at all the owner itself (`.`).
func mdDefaultBodyRel(slots []mdNodeRel) string {
	for _, s := range slots {
		if s.node.Kind != SomMetaKindForm {
			return s.rel
		}
	}
	for _, s := range slots {
		if s.rel == "content" {
			return s.rel
		}
	}
	if len(slots) == 0 {
		return "."
	}
	return slots[0].rel
}

func (c *SpecDocumentMarkdown) writeChildren(
	b *mdBuffer, node *SomMetaNode, basePath string, depth int,
) error {
	for _, entry := range c.effectiveChildren(node) {
		child := entry.node
		path := basePath + "/" + entry.rel
		if !c.Document.HasValuesUnder(path) {
			continue
		}
		switch child.Kind {
		case SomMetaKindContent, SomMetaKindScalar, SomMetaKindEnumValue:
			value, ok := c.Document.Content(path)
			if !ok {
				continue
			}
			c.writeHeading(b, depth, c.headingIdOf(child), c.headingTitle(path, child), path, c.Document.CodeSpecOr(path), c.Document.UnitsOr(path))
			if err := c.writeBody(b, value, path); err != nil {
				return err
			}
		case SomMetaKindForm:
			if !c.formHasValues(child, path) {
				continue
			}
			c.writeHeading(b, depth, c.headingIdOf(child), c.headingTitle(path, child), path, c.Document.CodeSpecOr(path), c.Document.UnitsOr(path))
			if err := c.writeForm(b, child, path); err != nil {
				return err
			}
		case SomMetaKindSection, SomMetaKindComplex:
			c.writeHeading(b, depth, c.headingIdOf(child), c.headingTitle(path, child), path, c.Document.CodeSpecOr(path), c.Document.UnitsOr(path))
			if err := c.writeSectionBody(b, child, path); err != nil {
				return err
			}
			if !c.writeSectionTable(b, child, path) {
				if err := c.writeChildren(b, child, path, depth+1); err != nil {
					return err
				}
			}
		case SomMetaKindList:
			if err := c.writeListItems(b, child, path, depth); err != nil {
				return err
			}
		}
	}
	return nil
}

// writeListItems emits list node as its `-LST` container heading (SOM
// §11.2/§11.5) at depth, wrapping the numbered item headings one level deeper.
// The container is a real section — the id the generated schema keys its container
// type by — but carries **no content of its own** (schema content
// min/max-text-length 0). Item identity is purely positional.
func (c *SpecDocumentMarkdown) writeListItems(
	b *mdBuffer, node *SomMetaNode, listPath string, depth int,
) error {
	items := c.Document.ListItems(listPath)
	if len(items) == 0 {
		return nil
	}
	// The container heading: its id is the list's `-LST` `@SectionId` (else the
	// member segment for a pattern-less list); its title is the member name.
	c.writeHeading(b, depth, c.headingIdOf(node), c.headingTitle(listPath, node), listPath, c.Document.CodeSpecOr(listPath), c.Document.UnitsOr(listPath))
	// Item heading stem. Complex lists derive it from the element class name
	// (SOM §11.5, `Entry` dropped). A scalar list (`[]string`, shape 6) has no
	// element class — its element type name is literally `String`, which would
	// render "String 1", "String 2". Derive the stem from the list FIELD
	// instead (its member name, Title-Cased like the container heading) so a
	// populated scalar list gets meaningful per-item headings (YRC5).
	element := node.ElementNode
	stem := mdItemStemOf(node)
	pattern := node.SectionIDPattern
	if pattern == "" && element != nil {
		pattern = element.SectionIDPattern
	}
	memberStem := node.MemberName
	if memberStem == "" {
		memberStem = node.Segment()
	}
	if c.writeReferenceLine(b, node, items, pattern) || c.writeRecordTable(b, node, items, pattern) {
		return nil
	}
	for i, itemPath := range items {
		pos := i + 1
		// YRD3: an item's STORED section id IS its md heading
		// id — stored ids round-trip through Markdown too. Only anonymous items
		// fall back to the positional derivation: the `@SectionIdPattern`
		// resolved with the 1-based position (`GOAL-ITEM-xxx` → `GOAL-ITEM-1`),
		// else `<member>-<pos>` for a pattern-less list.
		storedID, hasStored := c.Document.ItemSectionID(itemPath)
		itemID := EffectiveListItemSectionID(storedID, hasStored, pattern, pos, memberStem)
		// Items sit one level below the container. A stored headline overrides
		// the derived `<stem> <pos>` title (YRD3).
		itemTitle := c.Document.HeadlineOr(itemPath)
		if itemTitle == "" {
			itemTitle = stem + " " + itoa(pos)
		}
		c.writeHeading(b, depth+1, itemID, itemTitle, itemPath, c.Document.CodeSpecOr(itemPath), c.Document.UnitsOr(itemPath))
		if element == nil {
			// Scalar list: the item's value is its body.
			value, _ := c.Document.Content(itemPath)
			if err := c.writeBody(b, value, itemPath); err != nil {
				return err
			}
		} else {
			if err := c.writeSectionBody(b, element, itemPath); err != nil {
				return err
			}
			if !element.Recursive && !c.writeSectionTable(b, element, itemPath) {
				if err := c.writeChildren(b, element, itemPath, depth+2); err != nil {
					return err
				}
			}
		}
	}
	return nil
}

// --- Reading view: anchors, reference lines, record and section tables -------

var (
	// A section id as a reference holds it: upper-case segments joined by `-`.
	mdIDShapeRE = regexp.MustCompile(`^[A-Z][A-Z0-9]*(-[A-Z0-9]+)*$`)
	// A one-line value that Markdown reads as a block: a list item, a block
	// quote (review comment and question blocks among them), a fence or a
	// fenced div. A table needs two lines, so it is caught by the line break.
	mdBlockStartRE = regexp.MustCompile("^\\s*([-*+]\\s|\\d+[.)]\\s|>|```|~~~|:::)")
	// A line that is a block of its own, or would make the line above one,
	// beyond mdBlockStartRE: a table row, an ATX heading, a setext underline
	// or a thematic break, an HTML block.
	mdWrappedLineBlockRE = regexp.MustCompile(`^(?:\||#{1,6}(?:\s|$)|=+$|(?:[-*_]\s*){3,}$|<)`)
)

// mdUnder returns the keys of sorted at or below prefix: a binary search to
// the first key not before it, then the run sharing it as a prefix, so a large
// document is not scanned once per list item.
func mdUnder(sorted []string, prefix string) []string {
	var out []string
	for i := sort.SearchStrings(sorted, prefix); i < len(sorted) && strings.HasPrefix(sorted[i], prefix); i++ {
		k := sorted[i]
		if len(k) == len(prefix) || k[len(prefix)] == '/' {
			out = append(out, k)
		}
	}
	return out
}

// sorted returns the document's keys of one kind, sorted once per export.
func (c *SpecDocumentMarkdown) sorted(kind string) []string {
	if keys, ok := c.sortedKeys[kind]; ok {
		return keys
	}
	var keys []string
	switch kind {
	case "content":
		keys = c.Document.ContentPaths()
	case "lists":
		keys = c.Document.ListPaths()
	case "units":
		keys = c.Document.UnitsPaths()
	case "forms":
		keys = c.Document.FormPaths()
	case "headlines":
		keys = c.Document.HeadlinePaths()
	}
	sort.Strings(keys)
	c.sortedKeys[kind] = keys
	return keys
}

// mdNavigation holds one root's anchors (SOM §11.2): the anchor of the heading
// a path names, qualified below a list item and in a `@SameAs` copy. The port
// of the anchor walk of the TypeScript runtime's `_Navigation`; the `linked`
// marker and the summary links it also writes there are later ports.
type mdNavigation struct {
	codec   *SpecDocumentMarkdown
	tree    *SomMetaTree
	anchors map[string]string
}

// itemID returns the heading id of the item at itemPath of listNode, as the
// emitter writes it.
func (n *mdNavigation) itemID(listNode *SomMetaNode, itemPath string) string {
	d := n.codec.Document
	slash := strings.LastIndex(itemPath, "/")
	split, _ := SplitListItemSegment(itemPath[slash+1:])
	listPath := itemPath[:slash+1] + split.Base
	pos := 0
	for i, p := range d.ListItems(listPath) {
		if p == itemPath {
			pos = i + 1
			break
		}
	}
	if pos == 0 {
		pos = split.Seq
	}
	pattern := listNode.SectionIDPattern
	if pattern == "" && listNode.ElementNode != nil {
		pattern = listNode.ElementNode.SectionIDPattern
	}
	stem := listNode.MemberName
	if stem == "" {
		stem = listNode.Segment()
	}
	stored, has := d.ItemSectionID(itemPath)
	return EffectiveListItemSectionID(stored, has, pattern, pos, stem)
}

// anchorOf returns the anchor of the heading path names in this document.
func (n *mdNavigation) anchorOf(path string) string {
	if hit, ok := n.anchors[path]; ok {
		return hit
	}
	segs := strings.Split(path, "/")
	node := n.tree.Root
	cur := segs[0]
	anchor := node.Segment()
	var scope []string
	section := node.Segment()
	for i := 1; i < len(segs); i++ {
		seg := segs[i]
		if child := node.ChildBySegment(seg); child != nil {
			cur += "/" + seg
			node = child
			if n.codec.isTransparentSection(child) || mdIsTransparentValue(child) {
				continue
			}
			id := n.codec.headingIdOf(child)
			container := child.Kind == SomMetaKindList
			anchor, scope = mdQualifyAnchor(scope, section, id, container, false,
				!container && n.codec.isCopyNode(child))
			if !container {
				section = id
			}
			continue
		}
		split, ok := SplitListItemSegment(seg)
		if !ok {
			break
		}
		listNode := node.ChildBySegment(split.Base)
		if listNode == nil || listNode.Kind != SomMetaKindList {
			break
		}
		itemPath := cur + "/" + seg
		id := n.itemID(listNode, itemPath)
		anchor, scope = mdQualifyAnchor(scope, section, id, false, true, false)
		section = id
		cur = itemPath
		element := listNode.ElementNode
		if element == nil {
			node = listNode
			if i < len(segs)-1 {
				break
			}
		} else {
			node = element
		}
	}
	n.anchors[path] = anchor
	return anchor
}

// anchorOf is the qualified anchor of the heading path names in the current
// export, path's last segment as id outside an export.
func (c *SpecDocumentMarkdown) anchorOf(path, id string) string {
	if c.nav == nil {
		return id
	}
	return c.nav.anchorOf(path)
}

// hasKeys reports whether path stores a codeSpec or units.
func (c *SpecDocumentMarkdown) hasKeys(path string) bool {
	return c.Document.CodeSpecOr(path) != "" || c.Document.UnitsOr(path) != ""
}

// itemID returns the id of item pos (1-based) of node at itemPath, as its
// heading carries it.
func (c *SpecDocumentMarkdown) itemID(node *SomMetaNode, itemPath string, pos int, pattern string) string {
	stem := node.MemberName
	if stem == "" {
		stem = node.Segment()
	}
	stored, has := c.Document.ItemSectionID(itemPath)
	return EffectiveListItemSectionID(stored, has, pattern, pos, stem)
}

// isFormOnlyItem reports whether the item at itemPath holds values only in its
// form at formPath, all of them table cells: no preamble, no other content,
// form or list, no codeSpec / units, no headline other than the item's own
// when allowHeadline.
func (c *SpecDocumentMarkdown) isFormOnlyItem(form *SomMetaNode, itemPath, formPath string, allowHeadline bool) bool {
	if len(mdUnder(c.sorted("content"), itemPath)) > 0 ||
		len(mdUnder(c.sorted("lists"), itemPath)) > 0 ||
		len(mdUnder(c.sorted("units"), itemPath)) > 0 {
		return false
	}
	for _, k := range mdUnder(c.sorted("forms"), itemPath) {
		if k != formPath {
			return false
		}
	}
	for _, h := range mdUnder(c.sorted("headlines"), itemPath) {
		if !allowHeadline || h != itemPath {
			return false
		}
	}
	if c.hasKeys(itemPath) || c.hasKeys(formPath) {
		return false
	}
	if len(c.undeclaredFormFields(form, formPath)) > 0 {
		return false
	}
	any := false
	for _, f := range mdFormFields(form) {
		value, ok := c.Document.FormField(formPath, f.Name)
		if !ok {
			continue
		}
		if !mdIsCellValue(f, value) {
			return false
		}
		any = true
	}
	return any
}

// writeReferenceLine writes a list whose every item holds only one reference
// id as one `refs` div of links in list order (BP-11). All or nothing; reports
// whether it was written.
func (c *SpecDocumentMarkdown) writeReferenceLine(b *mdBuffer, node *SomMetaNode, items []string, pattern string) bool {
	element := node.ElementNode
	if element == nil || element.Recursive {
		return false
	}
	var ref *mdNodeRel
	for _, entry := range c.effectiveChildren(element) {
		fields := mdFormFields(entry.node)
		if entry.node.Kind != SomMetaKindForm || len(fields) != 1 || len(fields[0].RefersTo) == 0 {
			continue
		}
		isRef := false
		for _, e := range entry.node.Extra {
			if e.Annotation == "Reference" {
				isRef = true
			}
		}
		if isRef {
			e := entry
			ref = &e
			break
		}
	}
	if ref == nil {
		return false
	}
	field := ref.node.Form.Fields[0]
	d := c.Document
	stem := node.MemberName
	if stem == "" {
		stem = node.Segment()
	}
	var links []string
	for i, itemPath := range items {
		refPath := itemPath + "/" + ref.rel
		if stored, has := d.ItemSectionID(itemPath); has &&
			stored != EffectiveListItemSectionID("", false, pattern, i+1, stem) {
			return false
		}
		if len(mdUnder(c.sorted("content"), itemPath)) > 0 ||
			len(mdUnder(c.sorted("lists"), itemPath)) > 0 ||
			len(mdUnder(c.sorted("units"), itemPath)) > 0 ||
			len(mdUnder(c.sorted("headlines"), itemPath)) > 0 ||
			c.hasKeys(itemPath) || c.hasKeys(refPath) {
			return false
		}
		for _, k := range mdUnder(c.sorted("forms"), itemPath) {
			if k != refPath {
				return false
			}
		}
		names := d.FormFieldNames(refPath)
		if len(names) != 1 || names[0] != field.Name {
			return false
		}
		id := strings.TrimSpace(d.FormFieldOr(refPath, field.Name))
		if !mdIDShapeRE.MatchString(id) {
			return false
		}
		if link, ok := c.link(field, id); ok {
			links = append(links, link)
		} else {
			links = append(links, id)
		}
	}
	b.writeln("::: {.refs}")
	b.writeln(strings.Join(links, ", "))
	b.writeln(":::")
	b.writeln("")
	return true
}

// writeRecordTable writes a list whose every item is one form of table cells
// as a `records` div with one table: `Id` (with its anchor), `Title` when any
// item has a stored headline, one column per declared field any item
// populates (BP-11). All or nothing; reports whether it was written.
func (c *SpecDocumentMarkdown) writeRecordTable(b *mdBuffer, node *SomMetaNode, items []string, pattern string) bool {
	element := node.ElementNode
	if element == nil || element.Recursive {
		return false
	}
	slot, ok := c.itemForm(element)
	if !ok {
		return false
	}
	form, rel := slot.node, slot.rel
	for _, itemPath := range items {
		if !c.isFormOnlyItem(form, itemPath, itemPath+"/"+rel, true) {
			return false
		}
	}
	d := c.Document
	var columns []*SomFormFieldMeta
	for _, f := range mdFormFields(form) {
		for _, item := range items {
			if _, ok := d.FormField(item+"/"+rel, f.Name); ok {
				columns = append(columns, f)
				break
			}
		}
	}
	withTitle := false
	for _, item := range items {
		if _, ok := d.Headline(item); ok {
			withTitle = true
			break
		}
	}
	header := []string{"Id"}
	if withTitle {
		header = append(header, "Title")
	}
	for _, f := range columns {
		header = append(header, SpecMarkdownFormLabel(f.Name))
	}
	delimiter := make([]string, len(header))
	for i := range delimiter {
		delimiter[i] = "---"
	}
	b.writeln("::: {.records}")
	b.writeln("| " + strings.Join(header, " | ") + " |")
	b.writeln("| " + strings.Join(delimiter, " | ") + " |")
	for i, itemPath := range items {
		id := c.itemID(node, itemPath, i+1, pattern)
		// A summary naming its detail element by its own id would link it
		// from the Id cell (SOM §11.5, §11.11); the summary links are a later
		// port.
		cells := []string{`<a id="` + c.anchorOf(itemPath, id) + `"></a>` + id}
		if withTitle {
			title := strings.ReplaceAll(d.HeadlineOr(itemPath), "\n", "<br>")
			cells = append(cells, strings.ReplaceAll(title, "|", `\|`))
		}
		for _, f := range columns {
			if v, ok := d.FormField(itemPath+"/"+rel, f.Name); ok {
				cells = append(cells, c.linkedCellText(f, v))
			} else {
				cells = append(cells, "")
			}
		}
		b.writeln("| " + strings.Join(cells, " | ") + " |")
	}
	b.writeln(":::")
	b.writeln("")
	return true
}

// writeSectionTable writes a section whose populated children are all single
// forms of table cells with default headlines (or lists of such single-form
// items) as one `| Section | TomSpecField | Value |` table after its own body;
// the children's headings are not written (DP-part-renditions-4). All or
// nothing; reports whether it was written.
func (c *SpecDocumentMarkdown) writeSectionTable(b *mdBuffer, node *SomMetaNode, path string) bool {
	d := c.Document
	var rows []string
	children := 0
	addRows := func(sectionCell string, form *SomMetaNode, formPath string) {
		first := true
		for _, f := range mdFormFields(form) {
			value, ok := d.FormField(formPath, f.Name)
			if !ok {
				continue
			}
			cell := ""
			if first {
				cell = sectionCell
			}
			rows = append(rows, "| "+cell+" | "+SpecMarkdownFormLabel(f.Name)+" | "+
				c.linkedCellText(f, value)+" |")
			first = false
		}
	}
	for _, entry := range c.effectiveChildren(node) {
		child := entry.node
		childPath := path + "/" + entry.rel
		if !d.HasValuesUnder(childPath) {
			continue
		}
		children++
		childID := c.headingIdOf(child)
		switch child.Kind {
		case SomMetaKindForm:
			if !c.isFormOnlyItem(child, childPath, childPath, false) {
				return false
			}
			addRows(`<a id="`+c.anchorOf(childPath, childID)+`"></a>`+childID, child, childPath)
		case SomMetaKindList:
			element := child.ElementNode
			if element == nil || element.Recursive {
				return false
			}
			if _, ok := d.Headline(childPath); ok || c.hasKeys(childPath) {
				return false
			}
			slot, ok := c.itemForm(element)
			if !ok {
				return false
			}
			pattern := child.SectionIDPattern
			if pattern == "" {
				pattern = element.SectionIDPattern
			}
			for i, itemPath := range d.ListItems(childPath) {
				formPath := itemPath + "/" + slot.rel
				if !c.isFormOnlyItem(slot.node, itemPath, formPath, false) {
					return false
				}
				itemID := c.itemID(child, itemPath, i+1, pattern)
				addRows(`<a id="`+c.anchorOf(itemPath, itemID)+`"></a>`+childID+" / "+itemID,
					slot.node, formPath)
			}
		default:
			return false
		}
	}
	if children == 0 || len(rows) == 0 {
		return false
	}
	b.writeln("| Section | TomSpecField | Value |")
	b.writeln("| --- | --- | --- |")
	for _, row := range rows {
		b.writeln(row)
	}
	b.writeln("")
	return true
}

// linkedCellText returns value as a table cell, every reference id of a
// refersTo field written as a link to its section (reading view, DI-14).
func (c *SpecDocumentMarkdown) linkedCellText(f *SomFormFieldMeta, value string) string {
	if len(f.RefersTo) == 0 || f.Code {
		return mdCellText(f, value)
	}
	if joined, ok := SpecMarkdownWrappedParagraphJoined(value); ok {
		value = joined
	}
	ids := strings.Split(value, ",")
	links := make([]string, 0, len(ids))
	for _, raw := range ids {
		id := strings.TrimSpace(raw)
		if !mdIDShapeRE.MatchString(id) {
			return mdCellText(f, value)
		}
		link, ok := c.link(f, id)
		if !ok {
			return mdCellText(f, value)
		}
		links = append(links, link)
	}
	return strings.Join(links, ", ")
}

// link returns `[ID](<file>#ID)` for a reference id of form field f,
// `[ID](#ID)` when the target lives in the document being rendered; ok false
// when no target of f names a section id (`<SECTIONID>.@sectionId`), which has
// no anchor.
func (c *SpecDocumentMarkdown) link(f *SomFormFieldMeta, id string) (string, bool) {
	var classIDs []string
	for _, t := range f.RefersTo {
		if strings.HasSuffix(t, ".@sectionId") {
			classIDs = append(classIDs, strings.TrimSuffix(t, ".@sectionId"))
		}
	}
	if len(classIDs) == 0 {
		return "", false
	}
	for _, classID := range classIDs {
		if className := c.classBySectionID(classID); className != "" &&
			c.currentRoot != nil && c.reachedBy(c.currentRoot)[className] {
			return "[" + id + "](#" + id + ")", true
		}
	}
	if file := c.fileFor(c.classBySectionID(classIDs[0])); file != "" {
		return "[" + id + "](" + file + "#" + id + ")", true
	}
	return "[" + id + "](#" + id + ")", true
}

// classBySectionID returns the name of the class carrying sectionID, the
// first by name when several do; "" when none does.
func (c *SpecDocumentMarkdown) classBySectionID(sectionID string) string {
	found := ""
	for _, cls := range c.Model.Classes {
		if cls.SectionID == sectionID && (found == "" || cls.Name < found) {
			found = cls.Name
		}
	}
	return found
}

// reachedBy returns the class names the meta tree of root reaches.
func (c *SpecDocumentMarkdown) reachedBy(root *SpecRoot) map[string]bool {
	if names, ok := c.reach[root.Type]; ok {
		return names
	}
	names := map[string]bool{}
	if tree, err := c.treeFor(root.Type); err == nil {
		var walk func(n *SomMetaNode)
		walk = func(n *SomMetaNode) {
			names[n.ClassName] = true
			if n.Recursive {
				return
			}
			for _, child := range n.Children {
				walk(child)
			}
			if n.ElementNode != nil {
				walk(n.ElementNode)
			}
		}
		walk(tree.Root)
	}
	c.reach[root.Type] = names
	return names
}

// fileFor returns the rendition file of the root a reference to className
// points into: the root other than the current one that reaches the class,
// the most specific (fewest classes) first, so a detailed document wins over a
// projection such as the Solution Blueprint. The CodeSpecs projection is no
// document anyone renders, so it is never a target. "" when no root does.
func (c *SpecDocumentMarkdown) fileFor(className string) string {
	if className == "" {
		return ""
	}
	var best *SpecRoot
	bestSize := 0
	for _, r := range c.Model.Roots {
		if (c.currentRoot != nil && r.Type == c.currentRoot.Type) || c.Model.IsGenerationInput(r) {
			continue
		}
		reached := c.reachedBy(r)
		if !reached[className] {
			continue
		}
		if best == nil || len(reached) < bestSize {
			best, bestSize = r, len(reached)
		}
	}
	if best == nil {
		return ""
	}
	return c.fileOfRoot(best)
}

// fileOfRoot returns the rendition file of root:
// `<FileStem>.<root id>.tomspecs.md`, or the name DocumentFiles gives it.
func (c *SpecDocumentMarkdown) fileOfRoot(root *SpecRoot) string {
	id := root.SectionID
	if id == "" {
		id = root.Type
	}
	if mapped, ok := c.DocumentFiles[id]; ok {
		return mapped
	}
	if mapped, ok := c.DocumentFiles[root.Type]; ok {
		return mapped
	}
	name := strings.ToLower(id) + ".tomspecs.md"
	if c.FileStem == "" {
		return name
	}
	return c.FileStem + "." + name
}

// mdIsCellValue reports whether value of form field f is written as a table
// row (reading view, part *What the model says about reading*): not when the
// model flags the field multiParagraph, nor when the value holds a line break
// other than the soft breaks of one wrapped paragraph
// (SpecMarkdownWrappedParagraphJoined; a code value keeps every line break),
// is a block of Markdown, holds a backslash directly before `|`, or holds
// `<!--`. There is no length limit.
func mdIsCellValue(f *SomFormFieldMeta, value string) bool {
	if f.MultiParagraph {
		return false
	}
	if strings.Contains(value, `\|`) || strings.Contains(value, "<!--") {
		return false
	}
	if strings.Contains(value, "\n") {
		if f.Code {
			return false
		}
		if _, ok := SpecMarkdownWrappedParagraphJoined(value); !ok {
			return false
		}
	}
	return !mdBlockStartRE.MatchString(value)
}

// SpecMarkdownWrappedParagraphJoined returns value on one line when it is one
// paragraph wrapped over several lines — no blank line, and no line that
// Markdown reads as a block or a block's start (a list item, a quote, a fence,
// a fenced div, a table row, a heading, a setext underline or a thematic
// break), that ends in a hard break (a trailing backslash or spaces) or that
// starts with a space: its soft line breaks, which Markdown reads as spaces,
// become spaces (SOM §11.4 rule 13). ok is false for any other value, a
// one-line value among them.
func SpecMarkdownWrappedParagraphJoined(value string) (string, bool) {
	if !strings.Contains(value, "\n") {
		return "", false
	}
	lines := strings.Split(value, "\n")
	for _, l := range lines {
		if l == "" || l != strings.TrimSpace(l) || strings.HasSuffix(l, `\`) ||
			mdBlockStartRE.MatchString(l) || mdWrappedLineBlockRE.MatchString(l) {
			return "", false
		}
	}
	return strings.Join(lines, " "), true
}

// mdCellText returns the table cell for value: a code value as its inline
// code span, every `|` written `\|`.
func mdCellText(f *SomFormFieldMeta, value string) string {
	if joined, ok := SpecMarkdownWrappedParagraphJoined(value); ok {
		value = joined
	}
	text := value
	if f.Code && mdIsInlineCode(value) {
		text = mdEncodeCodeSpan(value)
	}
	return strings.ReplaceAll(text, "|", `\|`)
}

// undeclaredFormFields returns the stored field names at form path that node
// does not declare, sorted (SOM §9, "Form-field order").
//
// The emit walk is meta-driven — it iterates the model's declared fields — so a
// stored field the model does not know is invisible to it and cannot be dropped
// *loudly*. Seeing it at all needs this deliberate reverse check: store keys
// minus meta keys, which is the check the yaml codec already has (SOM §12.8).
func (c *SpecDocumentMarkdown) undeclaredFormFields(node *SomMetaNode, path string) []string {
	declared := map[string]bool{}
	if node.Form != nil {
		for _, f := range node.Form.Fields {
			declared[f.Name] = true
		}
	}
	var out []string
	for _, name := range c.Document.FormFieldNames(path) {
		if !declared[name] {
			out = append(out, name)
		}
	}
	sort.Strings(out)
	return out
}

// checkFormDeclared returns an error when the form at path holds a field the
// model does not declare (SOM §9, "Form-field order" — md refuses, matching
// yaml).
//
// Emitting it is impossible: the DocSpecs markdown grammar has no spelling for
// a field outside the model, and omitting it would lose a stored value in a
// file that looks complete. On import a partial document is normal and the
// codec reports-and-skips (SOM §11.7); on export the document is complete and a
// lossy rendering is a trap, so the codec refuses instead.
func (c *SpecDocumentMarkdown) checkFormDeclared(node *SomMetaNode, path string) error {
	undeclared := c.undeclaredFormFields(node, path)
	if len(undeclared) == 0 {
		return nil
	}
	return &undeclaredFormFieldError{path: path, field: undeclared[0]}
}

// formHasValues reports whether the `@Form` node at path has anything to emit:
// its preamble content (SOM §11.4 rule 7 — the DocSpecs `${text[]}` region), or
// any populated field.
//
// An undeclared stored field counts too — not because it can be emitted, but so
// the section is still *visited* and writeForm refuses. Without it a form
// holding nothing but undeclared fields would vanish unseen, which is the
// silent drop this check exists to prevent.
func (c *SpecDocumentMarkdown) formHasValues(node *SomMetaNode, path string) bool {
	if c.Document.HasContent(path) {
		return true
	}
	if node.Form != nil {
		for _, f := range node.Form.Fields {
			if _, ok := c.Document.FormField(path, f.Name); ok {
				return true
			}
		}
	}
	return len(c.undeclaredFormFields(node, path)) > 0
}

// writeForm writes a `@Form` section body (SOM §11.4): the preamble, then the
// declared fields in model order — each run of consecutive cell values one
// `| TomSpecField | Value |` table, each paragraph value a `Field:` group at its
// place (table – text – table). Groups are one blank line apart. A value line
// that would read as a table header is escaped by prepareValue. Returns an
// error when the form holds a field the model does not declare.
func (c *SpecDocumentMarkdown) writeForm(b *mdBuffer, node *SomMetaNode, path string) error {
	if err := c.checkFormDeclared(node, path); err != nil {
		return err
	}
	var groups [][]string
	table := -1 // index of the open table group, -1 for none
	for _, f := range mdFormFields(node) {
		value, ok := c.Document.FormField(path, f.Name)
		if !ok {
			continue
		}
		label := SpecMarkdownFormLabel(f.Name)
		if mdIsCellValue(f, value) {
			if table < 0 {
				groups = append(groups, []string{"| TomSpecField | Value |", "| --- | --- |"})
				table = len(groups) - 1
			}
			groups[table] = append(groups[table], "| "+label+" | "+c.linkedCellText(f, value)+" |")
			continue
		}
		table = -1
		// SOM §11.4 rule 8: a single-line code value is written as an inline
		// code span, so markdown leaves it literal (`](` is not a link).
		var lines []string
		if f.Code && mdIsInlineCode(value) {
			lines = []string{mdEncodeCodeSpan(value)}
		} else {
			prepared, err := c.prepareValue(value, path)
			if err != nil {
				return err
			}
			lines = strings.Split(prepared, "\n")
		}
		group := []string{label + ": " + lines[0]}
		for _, line := range lines[1:] {
			// Any continuation line that could be mistaken for a field-label
			// line gains one leading space; parse strips it.
			if mdLabelShapedRE.MatchString(line) {
				group = append(group, " "+line)
			} else {
				group = append(group, line)
			}
		}
		groups = append(groups, group)
	}

	if preamble, ok := c.Document.Content(path); ok {
		prepared, err := c.prepareValue(preamble, path)
		if err != nil {
			return err
		}
		if prepared != "" {
			// Every preamble line gets the same label-shaped escape a
			// continuation line gets: the parser reaches a field label before it
			// knows which text is preamble, so a `Word:` line at column 0 would
			// mis-split.
			for _, line := range strings.Split(prepared, "\n") {
				if mdLabelShapedRE.MatchString(line) {
					b.writeln(" " + line)
				} else {
					b.writeln(line)
				}
			}
			if len(groups) > 0 {
				b.writeln("")
			}
		}
	}
	for i, group := range groups {
		if i > 0 {
			b.writeln("")
		}
		for _, line := range group {
			b.writeln(line)
		}
	}
	b.writeln("")
	return nil
}

// writeHeading writes `## <!--[ID]--> Title` at depth and records path, the
// document path the heading renders, for ExportRootWithMap. SOM §11.2 is
// normative — heading level = 1 + section depth, **uncapped**: deep models
// (the Solution Blueprint nests past markdown's native 6 levels) keep their
// structure; the parse grammar accepts `#{7,}` accordingly. Capping would
// silently flatten distinct nesting positions into siblings and break schema
// validation.
//
// When codeSpec is non-empty it is emitted as a `codeSpec="…"` key inside the
// same headline comment (codespecs_mapping.md §9.2): `## <!--[ID]
// codeSpec="A,B"--> Title`. When units is non-empty it follows as a second
// key, `units="…"`, after `codeSpec` (SOM §11.2). Reading view: the section id
// follows the comment as an HTML anchor, `<a id="ID"></a>`, qualified below a
// list item and in a `@SameAs` copy (SOM §11.2), so `#<ID>` links jump in
// every viewer.
func (c *SpecDocumentMarkdown) writeHeading(b *mdBuffer, depth int, id, title, path, codeSpec, units string) {
	c.headingPaths = append(c.headingPaths, path)
	anchor := id
	if c.nav != nil {
		anchor = c.nav.anchorOf(path)
	}
	code := ""
	if codeSpec != "" {
		code = ` codeSpec="` + codeSpec + `"`
	}
	if units != "" {
		code += ` units="` + units + `"`
	}
	// A heading is one line: a stored headline's line breaks travel as `<br>`.
	b.writeln(strings.Repeat("#", depth) + " <!--[" + id + "]" + code + "--> <a id=\"" +
		anchor + "\"></a> " + strings.ReplaceAll(title, "\n", "<br>"))
	b.writeln("")
}

// writeBody writes value as a section body followed by a blank line; no-op
// for blank values.
func (c *SpecDocumentMarkdown) writeBody(b *mdBuffer, value, path string) error {
	prepared, err := c.prepareValue(value, path)
	if err != nil {
		return err
	}
	if prepared == "" {
		return nil
	}
	b.writeln(prepared)
	b.writeln("")
	return nil
}

// mdIsInlineCode reports whether a code field's value is written as an inline
// code span: it is non-empty and on one line. A multi-line value keeps the
// prose rendering — a code span cannot cross a line break without markdown
// joining the lines.
func mdIsInlineCode(value string) bool {
	return value != "" && !strings.Contains(value, "\n")
}

var mdBacktickRunRE = regexp.MustCompile("`+")

// mdEncodeCodeSpan returns value as a CommonMark inline code span: delimited
// by one backtick more than the longest backtick run inside it, and padded
// with one space on each side when it begins or ends with a backtick or a
// space — the padding CommonMark strips again, so the span's content is
// exactly value.
func mdEncodeCodeSpan(value string) string {
	longest := 0
	for _, run := range mdBacktickRunRE.FindAllString(value, -1) {
		if len(run) > longest {
			longest = len(run)
		}
	}
	fence := strings.Repeat("`", longest+1)
	pad := ""
	first, last := value[0], value[len(value)-1]
	if first == '`' || first == ' ' || last == '`' || last == ' ' {
		pad = " "
	}
	return fence + pad + value + pad + fence
}

var mdCodeSpanRE = regexp.MustCompile("^(`+)([\\s\\S]*[^`])(`+)$")

// mdDecodeCodeSpan is the inverse of the emitter's code span (SOM §11.4 rule
// 8): a single-line value delimited by equal backtick runs loses them, and one
// padding space on each side when both are present. Anything else — a value
// written by hand without a span — is kept as written.
func mdDecodeCodeSpan(value string) string {
	if strings.Contains(value, "\n") {
		return value
	}
	m := mdCodeSpanRE.FindStringSubmatch(value)
	if m == nil || len(m[1]) != len(m[3]) {
		return value
	}
	inner := m[2]
	if len(inner) >= 2 && strings.HasPrefix(inner, " ") &&
		strings.HasSuffix(inner, " ") && strings.TrimSpace(inner) != "" {
		return inner[1 : len(inner)-1]
	}
	return inner
}

// prepareValue is the emit-side value normalisation (SOM §11.3): trim
// leading/trailing blank lines, escape heading-like lines outside fences.
// Blank lines inside the value are kept. Returns an error for an unterminated
// fence.
func (c *SpecDocumentMarkdown) prepareValue(value, path string) (string, error) {
	collapsed := mdLeadingNLRE.ReplaceAllString(value, "")
	collapsed = mdTrailingNLRE.ReplaceAllString(collapsed, "")
	fence := &MarkdownFenceTracker{}
	var out []string
	for _, line := range strings.Split(collapsed, "\n") {
		if fence.InFence() {
			out = append(out, line) // SOM §11.3: fences shield their lines.
		} else if mdEscapableRE.MatchString(line) {
			out = append(out, "\\"+line)
		} else if mdTableHeaderShapedRE.MatchString(line) {
			out = append(out, " "+line) // A value line is never a layout table.
		} else {
			out = append(out, line)
		}
		fence.Feed(line)
	}
	if fence.InFence() {
		return "", &unterminatedFenceError{path: path}
	}
	return strings.Join(out, "\n"), nil
}

// unterminatedFenceError reports a content value whose fenced code block never
// closes — unrepresentable in the DocSpecs markdown format.
type unterminatedFenceError struct{ path string }

func (e *unterminatedFenceError) Error() string {
	return "content at \"" + e.path + "\" contains an unterminated fenced " +
		"code block; it cannot be represented in the DocSpecs markdown format"
}

// undeclaredFormFieldError reports a stored form field the model does not
// declare — unrepresentable in the DocSpecs markdown format (SOM §9,
// "Form-field order").
type undeclaredFormFieldError struct{ path, field string }

func (e *undeclaredFormFieldError) Error() string {
	return "form at \"" + e.path + "\" holds a field \"" + e.field +
		"\" unknown to the model; it cannot be represented in the DocSpecs " +
		"markdown format"
}

// mdTitleOf is the effective DEFAULT title of node (YRD4): the `@Headline`
// default when authored, else the name derivation. The stored headline
// (checked by callers first) always wins over this.
func mdTitleOf(node *SomMetaNode) string {
	if node.Headline != "" {
		return node.Headline
	}
	name := node.MemberName
	if name == "" {
		name = node.ClassName
	}
	return SpecMarkdownTitleCase(name)
}

// mdItemStemOf is the effective default item-title stem of list node (YRD4):
// the element class's `@Headline` default when authored, else the SOM §11.5
// derivation (element class name with `Entry` dropped; member name for scalar
// lists).
func mdItemStemOf(node *SomMetaNode) string {
	if element := node.ElementNode; element != nil {
		if element.Headline != "" {
			return element.Headline
		}
		return SpecMarkdownItemTitleStem(element.ClassName)
	}
	member := node.MemberName
	if member == "" {
		member = node.Segment()
	}
	return SpecMarkdownTitleCase(member)
}

// headingTitle resolves the heading title for a node at path: the document's
// STORED headline when present, else the derived title (YRD3).
func (c *SpecDocumentMarkdown) headingTitle(path string, node *SomMetaNode) string {
	if h := c.Document.HeadlineOr(path); h != "" {
		return h
	}
	return mdTitleOf(node)
}

// --- Import (SOM §11.7) -------------------------------------------------------

// Parse parses text into staged values + a rejection report, **without**
// mutating the document. SpecDocument.ApplyMarkdownResult applies the result as a full overwrite.
func (c *SpecDocumentMarkdown) Parse(text string) *SpecMarkdownResult {
	p := newMdParser(c)
	p.run(strings.Split(text, "\n"))
	return &SpecMarkdownResult{
		Content:      p.content,
		Forms:        p.forms,
		Lists:        p.listsJson(),
		Rejections:   p.rejections,
		RootPrefixes: p.rootPrefixes,
		Headlines:    p.headlines,
		CodeSpecs:    p.codeSpecs,
		Units:        p.units,
	}
}

// mdFrame is one open section during the parse: its heading level, resolved
// node (nil for an unresolvable/ignored section), path, and accumulated body
// lines.
type mdFrame struct {
	level   int
	node    *SomMetaNode
	path    string
	line    int
	ignored bool
	body    []string
	// anchorScope is the scope this heading's descendants' anchors are
	// qualified with (nil: none), anchorSection the id of the nearest heading
	// at or above it that is no list container (SOM §11.2, mdQualifyAnchor).
	anchorScope   []string
	anchorSection string
}

// mdListState is per-list bookkeeping while parsing: ordered item paths,
// stored ids, and the highest item number handed out (drives both fresh
// numbers for stored-id items and the resulting seq).
type mdListState struct {
	items []string
	ids   map[string]string
	maxN  int
}

type mdParser struct {
	codec   *SpecDocumentMarkdown
	content map[string]string
	forms   map[string]map[string]string
	lists   map[string]*mdListState
	// headlines stages stored headlines (SOM §11.7): a heading's title is
	// stored ONLY when it differs from the effective default derivation, so
	// default-titled documents stay byte-stable.
	headlines map[string]string
	// codeSpecs stages stored codeSpec mappings (codespecs_mapping.md §9.2): a
	// heading's `codeSpec="…"` key is staged whenever present (no effective
	// default).
	codeSpecs map[string]string
	// units stages stored generation units (SOM §11.2), exactly like codeSpecs.
	units        map[string]string
	listOrder    []string
	rejections   []*SpecMarkdownRejection
	rootPrefixes map[string]bool
	stack        []*mdFrame
	fence        *MarkdownFenceTracker
	// given holds the fields given so far per form path, for the given-twice
	// rule (SOM §11.4).
	given map[string]map[string]bool
	// Rolling pointer into a body region's transparent form slots — labels
	// bind to the nearest form at or after the last hit (wrapping), so
	// repeated field names across an owner's transparent forms follow emit
	// order.
	currentFormIdx int
}

func newMdParser(codec *SpecDocumentMarkdown) *mdParser {
	return &mdParser{
		codec:        codec,
		content:      map[string]string{},
		forms:        map[string]map[string]string{},
		lists:        map[string]*mdListState{},
		headlines:    map[string]string{},
		codeSpecs:    map[string]string{},
		units:        map[string]string{},
		rootPrefixes: map[string]bool{},
		fence:        &MarkdownFenceTracker{},
		given:        map[string]map[string]bool{},
	}
}

func (p *mdParser) run(lines []string) {
	for i, raw := range lines {
		lineNo := i + 1
		trimmed := mdTrailingWSRE.ReplaceAllString(raw, "")

		if !p.fence.InFence() {
			if len(p.stack) == 0 && mdDocspecCommentRE.MatchString(trimmed) {
				continue // SOM §11.1 header — informational.
			}
			if h := mdHeadingLineRE.FindStringSubmatch(trimmed); h != nil {
				p.closeTo(len(h[1]))
				p.openHeading(len(h[1]), h[2], lineNo)
				continue
			}
		}
		if len(p.stack) > 0 {
			top := p.stack[len(p.stack)-1]
			top.body = append(top.body, raw)
		} else if trimmed != "" {
			p.rejections = append(p.rejections, &SpecMarkdownRejection{
				Line:    lineNo,
				Reason:  SpecMarkdownRejectOrphanContent,
				Message: "text before the document root heading",
			})
		}
		p.fence.Feed(raw)
	}
	p.closeTo(1)
	if len(p.stack) > 0 {
		p.finalize(p.pop())
	}
}

func (p *mdParser) pop() *mdFrame {
	top := p.stack[len(p.stack)-1]
	p.stack = p.stack[:len(p.stack)-1]
	return top
}

// closeTo pops (and finalizes) every frame at level or deeper.
func (p *mdParser) closeTo(level int) {
	for len(p.stack) > 0 && p.stack[len(p.stack)-1].level >= level {
		p.finalize(p.pop())
	}
}

func (p *mdParser) openHeading(level int, rest string, lineNo int) {
	m := mdHeadlineCommentRE.FindStringSubmatch(strings.TrimSpace(rest))
	if m == nil {
		p.rejections = append(p.rejections, &SpecMarkdownRejection{
			Line:    lineNo,
			Reason:  SpecMarkdownRejectMalformedHeading,
			Message: "heading carries no <!--[SECTION-ID]--> headline comment",
			Anchor:  strings.TrimSpace(rest),
		})
		p.stack = append(p.stack, &mdFrame{level: level, line: lineNo, ignored: true})
		return
	}
	id := m[1]
	codeSpec := SpecDocumentMarkdownCodeSpecOf(m[2])
	unitIDs := SpecDocumentMarkdownUnitsOf(m[2])
	// Reading view: an anchor equal to the section id after the id comment, or
	// to its qualified form (SOM §11.2), is the renderer's, not part of the
	// title.
	rawTitle := strings.TrimSpace(m[3])
	titleWith := func(anchor string) string {
		re := regexp.MustCompile(`^<a id="(?:` + regexp.QuoteMeta(id) + `|` +
			regexp.QuoteMeta(anchor) + `)"></a>\s*`)
		return strings.ReplaceAll(re.ReplaceAllString(rawTitle, ""), "<br>", "\n")
	}

	if len(p.stack) == 0 {
		p.openRoot(level, id, titleWith(id), codeSpec, unitIDs, lineNo)
		return
	}

	parent := p.stack[len(p.stack)-1]
	if parent.ignored {
		p.rejections = append(p.rejections, &SpecMarkdownRejection{
			Line:    lineNo,
			Reason:  SpecMarkdownRejectUnknownSection,
			Message: "section nested under an unresolvable parent",
			Anchor:  id,
		})
		p.stack = append(p.stack, &mdFrame{level: level, line: lineNo, ignored: true})
		return
	}
	pNode := parent.node
	if pNode == nil || mdIsValueLeaf(pNode.Kind) {
		p.rejections = append(p.rejections, &SpecMarkdownRejection{
			Line:    lineNo,
			Reason:  SpecMarkdownRejectKindMismatch,
			Message: "child heading under a value-leaf or form section",
			Anchor:  id,
		})
		p.stack = append(p.stack, &mdFrame{level: level, line: lineNo, ignored: true})
		return
	}

	// 1. Under a `-LST` container frame (SOM §11.2), every child heading is one
	//    of that list's items — resolved positionally, not by the schema tree.
	if pNode.Kind == SomMetaKindList {
		anchor, scope := mdQualifyAnchor(parent.anchorScope, parent.anchorSection, id, false, true, false)
		p.openItemHeading(level, parent, pNode, id, titleWith(anchor), codeSpec, unitIDs, lineNo)
		last := p.stack[len(p.stack)-1]
		last.anchorScope = scope
		last.anchorSection = id
		return
	}

	// 2. A regular (non-list) or list-**container** *effective* child —
	//    section-bearing children hoisted through transparent sections — whose
	//    heading id matches. A list heads its `-LST` container here; its items
	//    are resolved above once the container frame is open. Transparent value
	//    members never head, so they never match; the bound path runs through
	//    the transparent segments.
	for _, entry := range p.codec.effectiveChildren(pNode) {
		if p.codec.headingIdOf(entry.node) == id {
			container := entry.node.Kind == SomMetaKindList
			anchor, scope := mdQualifyAnchor(parent.anchorScope, parent.anchorSection, id,
				container, false, !container && p.codec.isCopyNode(entry.node))
			title := titleWith(anchor)
			// SOM §11.7: stage the heading text as a stored headline ONLY when
			// it differs from the derived default (byte-stability).
			path := parent.path + "/" + entry.rel
			if title != "" && title != mdTitleOf(entry.node) {
				p.headlines[path] = title
			}
			// codespecs_mapping.md §9.2: stage the codeSpec mapping whenever present (no
			// default).
			if codeSpec != "" {
				p.codeSpecs[path] = codeSpec
			}
			// SOM §11.2: `units` is staged exactly like codeSpec.
			if unitIDs != "" {
				p.units[path] = unitIDs
			}
			section := id
			if container {
				section = parent.anchorSection
			}
			p.stack = append(p.stack, &mdFrame{
				level:         level,
				node:          entry.node,
				path:          path,
				line:          lineNo,
				anchorScope:   scope,
				anchorSection: section,
			})
			return
		}
	}

	p.rejections = append(p.rejections, &SpecMarkdownRejection{
		Line:   lineNo,
		Reason: SpecMarkdownRejectUnknownSection,
		Message: "section id does not resolve against the schema tree at this " +
			"position (under \"" + parent.path + "\")",
		Anchor: id,
	})
	p.stack = append(p.stack, &mdFrame{level: level, line: lineNo, ignored: true})
}

// openItemHeading opens a list-item frame under a `-LST` container frame (SOM
// §11.2), the heading id read by itemIdentity.
func (p *mdParser) openItemHeading(
	level int, container *mdFrame, listNode *SomMetaNode, id, title, codeSpec, unitIDs string, lineNo int,
) {
	n, hasN, storedID := p.itemIdentity(listNode, id)
	p.openItem(level, container.path, listNode, n, storedID, hasN, title, codeSpec, unitIDs, lineNo, true)
}

// itemIdentity reads an item id of listNode, as a heading's, a records row's
// or a section-table row's: the item number it names (hasN false: the next
// free one) and the id it stores ("" with hasN: none). The `<member>-<n>`
// fallback id is positional and stores nothing; the `@SectionIdPattern`
// resolved with a number names item `<n>` and is stored, the section id being
// the item's identity and the path only its position (SOM §11.6); any other id
// is the next item, carrying it (YRD3).
func (p *mdParser) itemIdentity(listNode *SomMetaNode, id string) (n int, hasN bool, storedID string) {
	member := listNode.MemberName
	if member == "" {
		member = listNode.Segment()
	}
	anonRE, err := regexp.Compile("^" + regexp.QuoteMeta(member) + "-([0-9]+)$")
	if err == nil {
		if anon := anonRE.FindStringSubmatch(id); anon != nil {
			return atoi(anon[1]), true, ""
		}
	}
	element := listNode.ElementNode
	pattern := listNode.SectionIDPattern
	if pattern == "" && element != nil {
		pattern = element.SectionIDPattern
	}
	if pattern != "" {
		parts := strings.Split(pattern, "xxx")
		if len(parts) == 2 {
			numberedRE, err := regexp.Compile("^" + regexp.QuoteMeta(parts[0]) +
				"([0-9]+)" + regexp.QuoteMeta(parts[1]) + "$")
			if err == nil {
				if numbered := numberedRE.FindStringSubmatch(id); numbered != nil {
					return atoi(numbered[1]), true, id
				}
			}
		}
	}
	return 0, false, id
}

func (p *mdParser) openRoot(level int, id, title, codeSpec, unitIDs string, lineNo int) {
	for _, root := range p.codec.Model.Roots {
		seg := root.SectionID
		if seg == "" {
			seg = root.Type
		}
		if seg == id {
			tree, err := p.codec.treeFor(root.Type)
			if err != nil {
				break
			}
			// SOM §11.7: stage a non-default root heading text — "non-default"
			// relative to the effective default (YRD4: `@Headline` default,
			// else the `@Document` title).
			defaultTitle := tree.Root.Headline
			if defaultTitle == "" {
				defaultTitle = root.Title
			}
			if title != "" && title != defaultTitle {
				p.headlines[seg] = title
			}
			// codespecs_mapping.md §9.2: stage the root codeSpec mapping whenever
			// present.
			if codeSpec != "" {
				p.codeSpecs[seg] = codeSpec
			}
			// SOM §11.2: `units` is staged exactly like codeSpec.
			if unitIDs != "" {
				p.units[seg] = unitIDs
			}
			p.rootPrefixes[seg] = true
			p.stack = append(p.stack, &mdFrame{
				level:         level,
				node:          tree.Root,
				path:          seg,
				line:          lineNo,
				anchorSection: seg,
			})
			return
		}
	}
	known := make([]string, 0, len(p.codec.Model.Roots))
	for _, r := range p.codec.Model.Roots {
		seg := r.SectionID
		if seg == "" {
			seg = r.Type
		}
		known = append(known, seg)
	}
	p.rejections = append(p.rejections, &SpecMarkdownRejection{
		Line:   lineNo,
		Reason: SpecMarkdownRejectUnknownSection,
		Message: "no document root with this section id (known: " +
			strings.Join(known, ", ") + ")",
		Anchor: id,
	})
	p.stack = append(p.stack, &mdFrame{level: level, line: lineNo, ignored: true})
}

// openItem registers a list item and, with push, opens its frame; it returns
// the item path. n (with hasN=true) is the anonymous heading number (also the
// path number); a stored-id item gets the next free number instead.
func (p *mdParser) openItem(
	level int, listPath string, listNode *SomMetaNode,
	n int, storedID string, hasN bool, title, codeSpec, unitIDs string, lineNo int, push bool,
) string {
	state, ok := p.lists[listPath]
	if !ok {
		state = &mdListState{ids: map[string]string{}}
		p.lists[listPath] = state
		p.listOrder = append(p.listOrder, listPath)
	}
	number := n
	if !hasN {
		number = state.maxN + 1
	}
	if number > state.maxN {
		state.maxN = number
	}
	itemPath := listPath + "-" + itoa(number)
	state.items = append(state.items, itemPath)
	// A positional item (`hasN`) stores an id only when one is given — the
	// numbered `@SectionIdPattern` form; the `<member>-<n>` fallback stores none.
	if !hasN || storedID != "" {
		state.ids[itemPath] = storedID
	}
	// SOM §11.7: stage a non-default item heading text against the derived
	// `<stem> <pos>` default.
	stem := mdItemStemOf(listNode)
	if title != "" && title != stem+" "+itoa(number) {
		p.headlines[itemPath] = title
	}
	// codespecs_mapping.md §9.2: stage the item codeSpec mapping whenever present.
	if codeSpec != "" {
		p.codeSpecs[itemPath] = codeSpec
	}
	// SOM §11.2: `units` is staged exactly like codeSpec.
	if unitIDs != "" {
		p.units[itemPath] = unitIDs
	}
	if push {
		p.stack = append(p.stack, &mdFrame{
			level: level,
			node:  listNode.ElementNode,
			path:  itemPath,
			line:  lineNo,
		})
	}
	return itemPath
}

func mdIsValueLeaf(kind string) bool {
	return kind == SomMetaKindContent ||
		kind == SomMetaKindScalar ||
		kind == SomMetaKindEnumValue
}

// --- Body finalisation --------------------------------------------------------

func (p *mdParser) finalize(frame *mdFrame) {
	if frame.ignored {
		return
	}
	node := frame.node
	if node != nil && node.Kind == SomMetaKindForm {
		p.finalizeForm(frame, node, frame.path)
		return
	}
	if node != nil && node.Kind == SomMetaKindList {
		p.finalizeListBody(frame, node)
	} else if node != nil && (node.Kind == SomMetaKindSection || node.Kind == SomMetaKindComplex) {
		p.extractSectionTables(frame, node)
	}
	var slots []mdNodeRel
	if node != nil {
		slots = p.codec.bodySlots(node)
	}
	if len(slots) == 0 {
		value := mdRestoreValue(frame.body)
		if value != "" {
			p.content[frame.path] = value
		} else if node != nil && mdIsValueLeaf(node.Kind) {
			p.rejections = append(p.rejections, &SpecMarkdownRejection{
				Line:    frame.line,
				Reason:  SpecMarkdownRejectMissingValue,
				Message: "no value text under this section heading",
				Anchor:  frame.path,
			})
		}
		return
	}
	p.finalizeBodySlots(frame, slots)
}

// --- Layout tables (SOM §11.4, §11.5) -----------------------------------------

// mdBodyLine is the 1-based source line of frame's body line i.
func mdBodyLine(frame *mdFrame, i int) int {
	return frame.line + 1 + i
}

// mdRowCells returns the cells of a table row: split on every `|` not preceded
// by a backslash, the outer pipes dropped, each cell trimmed; `\|` stays in the
// cell.
func mdRowCells(line string) []string {
	t := strings.TrimSpace(line)
	t = strings.TrimPrefix(t, "|")
	if strings.HasSuffix(t, "|") && !strings.HasSuffix(t, `\|`) {
		t = t[:len(t)-1]
	}
	var cells []string
	var b strings.Builder
	for i := 0; i < len(t); i++ {
		ch := t[i]
		if ch == '\\' && i+1 < len(t) && t[i+1] == '|' {
			b.WriteString(`\|`)
			i++
		} else if ch == '|' {
			cells = append(cells, strings.TrimSpace(b.String()))
			b.Reset()
		} else {
			b.WriteByte(ch)
		}
	}
	return append(cells, strings.TrimSpace(b.String()))
}

// mdTableRow is one body row of a layout table: its line index in the lines
// read and its cells.
type mdTableRow struct {
	index int
	cells []string
}

// readTable reads the table whose header is lines[start]: the header cells,
// the body rows, and the index after the table; a broken delimiter row or a
// row of another cell count is a malformedBlock.
func (p *mdParser) readTable(
	lines []string, start int, lineOf func(int) int, anchor string,
) (header []string, rows []mdTableRow, end int) {
	end = start + 1
	for end < len(lines) && mdTableLineRE.MatchString(lines[end]) {
		end++
	}
	header = mdRowCells(lines[start])
	isDelimiter := false
	var delimiter []string
	if start+1 < end {
		delimiter = mdRowCells(lines[start+1])
		isDelimiter = true
		for _, cell := range delimiter {
			if !mdDelimiterCellRE.MatchString(cell) {
				isDelimiter = false
			}
		}
	}
	if !isDelimiter || len(delimiter) != len(header) {
		message := "table whose delimiter row does not match its header"
		if !isDelimiter {
			message = "table without its delimiter row"
		}
		p.reject(lineOf(start), SpecMarkdownRejectMalformedBlock, message, anchor)
		return header, nil, end
	}
	for i := start + 2; i < end; i++ {
		cells := mdRowCells(lines[i])
		if len(cells) != len(header) {
			p.reject(lineOf(i), SpecMarkdownRejectMalformedBlock,
				"table row with "+itoa(len(cells))+" cells, the header has "+itoa(len(header)),
				anchor)
			continue
		}
		rows = append(rows, mdTableRow{index: i, cells: cells})
	}
	return header, rows, end
}

func (p *mdParser) reject(line int, reason, message, anchor string) {
	p.rejections = append(p.rejections, &SpecMarkdownRejection{
		Line:    line,
		Reason:  reason,
		Message: message,
		Anchor:  anchor,
	})
}

// mdCellValue is a cell's value for field f: `\|` unescaped, a reference
// field's links read as their link texts, a `code` field's code span decoded.
func mdCellValue(cell string, f *SomFormFieldMeta) string {
	text := strings.ReplaceAll(cell, `\|`, "|")
	if len(f.RefersTo) > 0 && !f.Code && mdLinkCellRE.MatchString(text) {
		var texts []string
		for _, m := range mdLinkTextRE.FindAllStringSubmatch(text, -1) {
			texts = append(texts, m[1])
		}
		return strings.Join(texts, ", ")
	}
	if f.Code {
		return mdDecodeCodeSpan(text)
	}
	return text
}

// mdCellID is a cell's id with the renderer's anchor (`<a id="X"></a>X`)
// removed, and a link the cell is read as its text (`[X](<file>#X)`, SOM
// §11.5).
func mdCellID(cell string) string {
	id := mdCellAnchorRE.ReplaceAllString(cell, "")
	if m := mdCellLinkRE.FindStringSubmatch(id); m != nil {
		return m[1]
	}
	return id
}

// givenTwice reports whether field of the form at formPath was given before,
// and reports the repeat (malformedBlock, the first occurrence kept) when it
// was.
func (p *mdParser) givenTwice(formPath, field string, line int) bool {
	given := p.given[formPath]
	if given == nil {
		given = map[string]bool{}
		p.given[formPath] = given
	}
	if !given[field] {
		given[field] = true
		return false
	}
	p.reject(line, SpecMarkdownRejectMalformedBlock, "field \""+field+"\" given twice", formPath)
	return true
}

func (p *mdParser) setField(formPath, field, value string) {
	if p.forms[formPath] == nil {
		p.forms[formPath] = map[string]string{}
	}
	p.forms[formPath][field] = value
}

// stageRow stages one row of a form table (or a section table).
func (p *mdParser) stageRow(formPath string, fields []*SomFormFieldMeta, label, cell string, line int) {
	lower := strings.ToLower(label)
	var f *SomFormFieldMeta
	for _, x := range fields {
		if strings.ToLower(x.Name) == lower {
			f = x
			break
		}
	}
	if f == nil {
		p.reject(line, SpecMarkdownRejectUnknownField,
			"row \""+label+"\" names no field of this form", formPath)
		return
	}
	value := mdCellValue(cell, f)
	if value == "" {
		return
	}
	if p.givenTwice(formPath, f.Name, line) {
		return
	}
	p.setField(formPath, f.Name, value)
}

func mdFormFields(n *SomMetaNode) []*SomFormFieldMeta {
	if n.Form == nil {
		return nil
	}
	return n.Form.Fields
}

// extractSectionTables reads and removes every section table of frame's body
// (SOM §11.5).
func (p *mdParser) extractSectionTables(frame *mdFrame, node *SomMetaNode) {
	body := frame.body
	lineOf := func(k int) int { return mdBodyLine(frame, k) }
	fence := &MarkdownFenceTracker{}
	for i := 0; i < len(body); i++ {
		line := body[i]
		var h []string
		if !fence.InFence() {
			h = mdLayoutTableHeaderRE.FindStringSubmatch(line)
		}
		if h == nil || h[1] == "" {
			fence.Feed(line)
			continue
		}
		_, rows, end := p.readTable(body, i, lineOf, frame.path)
		formPath := ""
		var fields []*SomFormFieldMeta
		haveTarget := false
		skip := false
		for _, row := range rows {
			k, cells := row.index, row.cells
			section := mdCellID(cells[0])
			if section == "" && skip {
				continue
			}
			if section != "" {
				fp, fs, ok := p.sectionTableTarget(frame, node, section)
				skip = !ok
				if !ok {
					p.reject(lineOf(k), SpecMarkdownRejectUnknownSection,
						"section-table row names no child section of \""+frame.path+"\"", section)
					continue
				}
				formPath, fields, haveTarget = fp, fs, true
			} else if !haveTarget {
				p.reject(lineOf(k), SpecMarkdownRejectUnknownSection,
					"section-table row names no section", frame.path)
				continue
			}
			if skip {
				continue
			}
			p.stageRow(formPath, fields, cells[1], cells[2], lineOf(k))
		}
		for k := i; k < end; k++ {
			body[k] = ""
		}
		i = end - 1
	}
}

// sectionTableTarget returns the form a section-table `Section` cell names
// under node: its path and fields.
func (p *mdParser) sectionTableTarget(
	frame *mdFrame, node *SomMetaNode, section string,
) (string, []*SomFormFieldMeta, bool) {
	parts := mdSectionSplitRE.Split(section, -1)
	for _, entry := range p.codec.effectiveChildren(node) {
		child := entry.node
		childID := p.codec.headingIdOf(child)
		if len(parts) == 1 && child.Kind == SomMetaKindForm && childID == section {
			return frame.path + "/" + entry.rel, mdFormFields(child), true
		}
		if len(parts) == 2 && child.Kind == SomMetaKindList && childID == parts[0] {
			element := child.ElementNode
			if element == nil {
				return "", nil, false
			}
			form, ok := p.codec.itemForm(element)
			if !ok {
				return "", nil, false
			}
			n, hasN, storedID := p.itemIdentity(child, parts[1])
			listPath := frame.path + "/" + entry.rel
			itemPath := ""
			if state := p.lists[listPath]; state != nil {
				for _, item := range state.items {
					key, stored := state.ids[item]
					if !stored {
						key = item[len(listPath)+1:]
					}
					if key == parts[1] {
						itemPath = item
						break
					}
				}
			}
			if itemPath == "" {
				itemPath = p.openItem(0, listPath, child, n, storedID, hasN, "", "", "", frame.line, false)
			}
			return itemPath + "/" + form.rel, mdFormFields(form.node), true
		}
	}
	return "", nil, false
}

// --- List bodies: `refs` and `records` (SOM §11.5) ----------------------------

// finalizeListBody reads a list container's body: one `refs` or `records` div
// stands for its items.
func (p *mdParser) finalizeListBody(frame *mdFrame, listNode *SomMetaNode) {
	body := frame.body
	fence := &MarkdownFenceTracker{}
	for i := 0; i < len(body); i++ {
		line := body[i]
		var open []string
		if !fence.InFence() {
			open = mdListDivOpenRE.FindStringSubmatch(line)
		}
		if open == nil {
			fence.Feed(line)
			continue
		}
		kind := open[1]
		if kind == "" {
			kind = open[2]
		}
		closeAt := -1
		for k := i + 1; k < len(body); k++ {
			if mdDivCloseRE.MatchString(body[k]) {
				closeAt = k
				break
			}
		}
		reject := func(message string) {
			p.reject(mdBodyLine(frame, i), SpecMarkdownRejectMalformedBlock, message, frame.path)
		}
		if closeAt < 0 {
			// The fence's lines read as text.
			reject("unclosed " + kind + " fence")
			return
		}
		besideText := false
		for k := 0; k < len(body); k++ {
			if (k < i || k > closeAt) && strings.TrimSpace(body[k]) != "" {
				besideText = true
			}
		}
		state := p.lists[frame.path]
		hasItems := state != nil && len(state.items) > 0
		if besideText || hasItems {
			beside := "other text"
			if hasItems {
				beside = "item headings"
			}
			reject("a " + kind + " div beside " + beside + " in a list container")
			for k := i; k <= closeAt; k++ {
				body[k] = ""
			}
			return
		}
		inner := append([]string{}, body[i+1:closeAt]...)
		if kind == "refs" {
			p.stageReferenceLine(frame, listNode, inner, i)
		} else {
			p.stageRecordTable(frame, listNode, inner, i)
		}
		for k := i; k <= closeAt; k++ {
			body[k] = ""
		}
		return
	}
}

// referenceField returns the reference field of element's items, with the
// rel of its form.
func (p *mdParser) referenceField(element *SomMetaNode) (string, *SomFormFieldMeta, bool) {
	isRef := func(n *SomMetaNode) bool {
		if n.Kind != SomMetaKindForm || n.Form == nil || len(n.Form.Fields) != 1 ||
			len(n.Form.Fields[0].RefersTo) == 0 {
			return false
		}
		for _, e := range n.Extra {
			if e.Annotation == "Reference" {
				return true
			}
		}
		return false
	}
	for _, s := range p.codec.bodySlots(element) {
		if isRef(s.node) {
			return s.rel, s.node.Form.Fields[0], true
		}
	}
	for _, s := range p.codec.effectiveChildren(element) {
		if isRef(s.node) {
			return s.rel, s.node.Form.Fields[0], true
		}
	}
	return "", nil, false
}

// stageReferenceLine stages a `refs` div: ids split on commas and whitespace,
// links read as their texts.
func (p *mdParser) stageReferenceLine(frame *mdFrame, listNode *SomMetaNode, inner []string, at int) {
	element := listNode.ElementNode
	var (
		refRel   string
		refField *SomFormFieldMeta
		ok       bool
	)
	if element != nil {
		refRel, refField, ok = p.referenceField(element)
	}
	if !ok {
		p.reject(mdBodyLine(frame, at), SpecMarkdownRejectMalformedBlock,
			"a refs div in a list whose items are not references", frame.path)
		return
	}
	var ids []string
	for _, t := range mdRefsSplitRE.Split(strings.Join(inner, " "), -1) {
		if t == "" {
			continue
		}
		if m := mdLinkTextRE.FindStringSubmatch(t); m != nil {
			t = m[1]
		}
		ids = append(ids, t)
	}
	if len(ids) == 0 {
		p.reject(mdBodyLine(frame, at), SpecMarkdownRejectMissingValue,
			"an empty refs div", frame.path)
		return
	}
	pattern := listNode.SectionIDPattern
	if pattern == "" && element != nil {
		pattern = element.SectionIDPattern
	}
	member := listNode.MemberName
	if member == "" {
		member = listNode.Segment()
	}
	for n := 1; n <= len(ids); n++ {
		positional := EffectiveListItemSectionID("", false, pattern, n, member)
		number, hasN, storedID := p.itemIdentity(listNode, positional)
		itemPath := p.openItem(0, frame.path, listNode, number, storedID, hasN, "", "", "", frame.line, false)
		formPath := itemPath + "/" + refRel
		if refRel == "." {
			formPath = itemPath
		}
		p.setField(formPath, refField.Name, ids[n-1])
	}
}

// stageRecordTable stages a `records` div: one table, `Id` first, `Title`
// optionally second.
func (p *mdParser) stageRecordTable(frame *mdFrame, listNode *SomMetaNode, inner []string, at int) {
	lineOf := func(k int) int { return mdBodyLine(frame, at+1+k) }
	reject := func(message string) {
		p.reject(mdBodyLine(frame, at), SpecMarkdownRejectMalformedBlock, message, frame.path)
	}
	start := -1
	for k, l := range inner {
		if strings.TrimSpace(l) != "" {
			start = k
			break
		}
	}
	if start < 0 || !mdTableLineRE.MatchString(inner[start]) {
		reject("a records div holding no table")
		return
	}
	header := mdRowCells(inner[start])
	if header[0] != "Id" {
		reject("a records table whose first column is not Id")
		return
	}
	element := listNode.ElementNode
	var form mdNodeRel
	ok := false
	if element != nil {
		form, ok = p.codec.itemForm(element)
	}
	if !ok {
		reject("a records div in a list whose items have no single form")
		return
	}
	fields := mdFormFields(form.node)
	withTitle := len(header) > 1 && header[1] == "Title"
	first := 1
	if withTitle {
		first = 2
	}
	var columns []*SomFormFieldMeta
	for _, label := range header[first:] {
		lower := strings.ToLower(label)
		var f *SomFormFieldMeta
		for _, x := range fields {
			if strings.ToLower(x.Name) == lower {
				f = x
				break
			}
		}
		if f == nil {
			// The table is skipped whole.
			p.reject(lineOf(start), SpecMarkdownRejectUnknownField,
				"records column \""+label+"\" names no field of the items", frame.path)
			return
		}
		columns = append(columns, f)
	}
	_, rows, _ := p.readTable(inner, start, lineOf, frame.path)
	stem := mdItemStemOf(listNode)
	for _, row := range rows {
		k, cells := row.index, row.cells
		id := mdCellID(cells[0])
		n, hasN, storedID := p.itemIdentity(listNode, id)
		itemPath := p.openItem(0, frame.path, listNode, n, storedID, hasN, "", "", "", lineOf(k), false)
		if withTitle {
			title := strings.ReplaceAll(strings.ReplaceAll(cells[1], `\|`, "|"), "<br>", "\n")
			number := itemPath[len(frame.path)+1:]
			if title != "" && title != stem+" "+number {
				p.headlines[itemPath] = title
			}
		}
		formPath := itemPath + "/" + form.rel
		for c, column := range columns {
			value := mdCellValue(cells[first+c], column)
			if value == "" {
				continue
			}
			p.setField(formPath, column.Name, value)
		}
	}
}

// finalizeBodySlots binds a heading's body region against the owner's
// transparent body slots (SOM §11.6): `FieldName:` lines and form-table rows
// matching a transparent form's fields route to that form (nearest form in
// slot order, wrapping); a slot marker (`<!-- slot: <rel> -->`) sends the text
// after it to the named slot — a content slot, a form's preamble, or the owner
// itself (`.`) — and ends any open field. Unmarked text binds to the first
// content slot; with no content slot it is a form's preamble (SOM §11.4 rule
// 7) — the class-level `@Form` on the `content` member, else the first form —
// which is where the YAML codec keeps it; only an owner with no slot at all
// takes it on its own path. In a region with forms every label-shaped text
// line carries the one escape space the emitter adds; it is stripped.
func (p *mdParser) finalizeBodySlots(frame *mdFrame, slots []mdNodeRel) {
	var formSlots []mdNodeRel
	for _, s := range slots {
		if s.node.Kind == SomMetaKindForm {
			formSlots = append(formSlots, s)
		}
	}
	defaultRel := mdDefaultBodyRel(slots)
	pathOf := func(rel string) string {
		if rel == "." {
			return frame.path
		}
		return frame.path + "/" + rel
	}
	lineOf := func(k int) int { return mdBodyLine(frame, k) }

	findField := func(label string) (int, *SomFormFieldMeta, bool) {
		lower := strings.ToLower(label)
		for k := 0; k < len(formSlots); k++ {
			idx := (p.currentFormIdx + k) % len(formSlots)
			form := formSlots[idx].node.Form
			if form == nil {
				continue
			}
			for _, f := range form.Fields {
				if strings.ToLower(f.Name) == lower {
					return idx, f, true
				}
			}
		}
		return 0, nil, false
	}

	fence := &MarkdownFenceTracker{}
	currentField := ""
	currentFormPath := ""
	currentCode := false
	haveField := false
	discard := false
	var currentLines []string
	// Unlabelled text per target path, in the order the targets were opened;
	// a target opened twice gets its parts joined by a blank line.
	var textOrder []string
	textParts := map[string][]*[]string{}
	openText := func(target string) *[]string {
		lines := &[]string{}
		if _, ok := textParts[target]; !ok {
			textOrder = append(textOrder, target)
		}
		textParts[target] = append(textParts[target], lines)
		return lines
	}
	contentLines := openText(pathOf(defaultRel))

	flush := func() {
		if haveField && !discard {
			value := mdRestoreValue(currentLines)
			if currentCode {
				value = mdDecodeCodeSpan(value)
			}
			if value != "" {
				p.setField(currentFormPath, currentField, value)
			}
		}
		currentLines = nil
		discard = false
	}

	p.currentFormIdx = 0
	for i := 0; i < len(frame.body); i++ {
		line := frame.body[i]
		if !fence.InFence() {
			if mm := mdSlotMarkerRE.FindStringSubmatch(line); mm != nil {
				rel := mm[1]
				slotIdx := -1
				if rel != "." {
					for k, s := range slots {
						if s.rel == rel {
							slotIdx = k
							break
						}
					}
				}
				if rel == "." || slotIdx >= 0 {
					flush()
					haveField = false
					currentField = ""
					currentFormPath = ""
					if slotIdx >= 0 && slots[slotIdx].node.Kind == SomMetaKindForm {
						for k, fs := range formSlots {
							if fs.rel == rel {
								p.currentFormIdx = k
								break
							}
						}
					}
					contentLines = openText(pathOf(rel))
					continue
				}
			}
			if h := mdLayoutTableHeaderRE.FindStringSubmatch(line); h != nil && h[1] == "" && len(formSlots) > 0 {
				// A form table ends the open field (SOM §11.4); its rows bind like
				// `Field:` labels, each to the nearest form declaring it.
				flush()
				haveField = false
				currentField = ""
				currentFormPath = ""
				_, rows, end := p.readTable(frame.body, i, lineOf, frame.path)
				for _, row := range rows {
					idx, f, ok := findField(row.cells[0])
					if !ok {
						p.reject(lineOf(row.index), SpecMarkdownRejectUnknownField,
							"row \""+row.cells[0]+"\" names no field of this form", frame.path)
						continue
					}
					p.currentFormIdx = idx
					p.stageRow(frame.path+"/"+formSlots[idx].rel, []*SomFormFieldMeta{f},
						row.cells[0], row.cells[1], lineOf(row.index))
				}
				i = end - 1
				continue
			}
			if m := mdFieldLabelRE.FindStringSubmatch(line); m != nil {
				if idx, f, ok := findField(m[1]); ok {
					flush()
					p.currentFormIdx = idx
					haveField = true
					currentField = f.Name
					currentCode = f.Code
					currentFormPath = frame.path + "/" + formSlots[idx].rel
					discard = p.givenTwice(currentFormPath, currentField, lineOf(i))
					currentLines = []string{m[2]}
					fence.Feed(line)
					continue
				}
			}
		}
		// In a region with forms every label-shaped text line carries the one
		// escape space the emitter adds (SOM §11.4 rule 3); strip it.
		text := line
		if !fence.InFence() && len(formSlots) > 0 && mdContinuationLabelRE.MatchString(line) {
			text = line[1:]
		}
		if haveField {
			currentLines = append(currentLines, text)
		} else {
			*contentLines = append(*contentLines, text)
		}
		fence.Feed(line)
	}
	flush()
	for _, target := range textOrder {
		var values []string
		for _, part := range textParts[target] {
			if v := mdRestoreValue(*part); v != "" {
				values = append(values, v)
			}
		}
		if value := strings.Join(values, "\n\n"); value != "" {
			p.content[target] = value
		}
	}
}

// finalizeForm parses an id-bearing `@Form` section's body: `FieldName:`
// paragraphs and form-table rows bind to the named fields wherever they stand
// (SOM §11.4); the text that belongs to no field — before the first field, or
// after a table — is the form's preamble, its own content (rule 7).
func (p *mdParser) finalizeForm(frame *mdFrame, node *SomMetaNode, path string) {
	declared := mdFormFields(node)
	fieldsByLower := map[string]*SomFormFieldMeta{}
	for _, f := range declared {
		fieldsByLower[strings.ToLower(f.Name)] = f
	}
	lineOf := func(k int) int { return mdBodyLine(frame, k) }
	fence := &MarkdownFenceTracker{}
	var currentField *SomFormFieldMeta
	discard := false
	var currentLines []string
	// The preamble's parts: the text before the first field, and text a table
	// interrupts; joined by one blank line.
	preambleParts := [][]string{nil}

	flush := func() {
		if f := currentField; f != nil && !discard {
			value := mdRestoreValue(currentLines)
			if f.Code {
				value = mdDecodeCodeSpan(value)
			}
			if value != "" {
				p.setField(path, f.Name, value)
			}
		}
		currentLines = nil
		discard = false
	}

	for i := 0; i < len(frame.body); i++ {
		line := frame.body[i]
		if !fence.InFence() {
			if h := mdLayoutTableHeaderRE.FindStringSubmatch(line); h != nil && h[1] == "" {
				flush()
				currentField = nil
				preambleParts = append(preambleParts, nil)
				_, rows, end := p.readTable(frame.body, i, lineOf, path)
				for _, row := range rows {
					p.stageRow(path, declared, row.cells[0], row.cells[1], lineOf(row.index))
				}
				i = end - 1
				continue
			}
			if m := mdFieldLabelRE.FindStringSubmatch(line); m != nil {
				if f, ok := fieldsByLower[strings.ToLower(m[1])]; ok {
					flush()
					currentField = f
					discard = p.givenTwice(path, f.Name, lineOf(i))
					currentLines = []string{m[2]}
					fence.Feed(line)
					continue
				}
			}
		}
		// Continuation: strip the one escape space of a label-shaped line.
		text := line
		if !fence.InFence() && mdContinuationLabelRE.MatchString(line) {
			text = line[1:]
		}
		if currentField == nil {
			last := len(preambleParts) - 1
			preambleParts[last] = append(preambleParts[last], text)
		} else {
			currentLines = append(currentLines, text)
		}
		fence.Feed(line)
	}
	flush()
	var values []string
	for _, part := range preambleParts {
		if v := mdRestoreValue(part); v != "" {
			values = append(values, v)
		}
	}
	if value := strings.Join(values, "\n\n"); value != "" {
		p.content[path] = value
	}
}

// mdRestoreValue is the parse-side value restoration (SOM §11.3): trim
// leading/trailing blank lines, unescape `\#`-escaped heading lines and strip
// the one escape space of a line shaped like a layout table header (SOM
// §11.4), outside fences.
func mdRestoreValue(body []string) string {
	fence := &MarkdownFenceTracker{}
	out := make([]string, 0, len(body))
	for _, line := range body {
		if !fence.InFence() && mdEscapedHeadingRE.MatchString(line) {
			out = append(out, line[1:])
		} else if !fence.InFence() && mdEscapedTableHeaderRE.MatchString(line) {
			out = append(out, line[1:]) // The emitter's one escape space.
		} else {
			out = append(out, line)
		}
		fence.Feed(line)
	}
	joined := strings.Join(out, "\n")
	joined = mdLeadingBlankLnRE.ReplaceAllString(joined, "")
	joined = mdTrailingBlankLnRE.ReplaceAllString(joined, "")
	return joined
}

func (p *mdParser) listsJson() map[string]ListJson {
	out := map[string]ListJson{}
	for _, key := range p.listOrder {
		state := p.lists[key]
		items := make([]string, len(state.items))
		copy(items, state.items)
		entry := ListJson{Seq: state.maxN, Items: items}
		if len(state.ids) > 0 {
			ids := map[string]string{}
			for k, v := range state.ids {
				ids[k] = v
			}
			entry.Ids = ids
		}
		out[key] = entry
	}
	return out
}
