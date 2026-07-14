package somruntime

// spec_document_markdown.go — DocSpecs-conform Markdown codec for a TomSpecs
// document (DR1 §1), a faithful port of
// `tom_som_dart_runtime/lib/src/spec_document_markdown.dart` (and the
// TypeScript `spec_document_markdown.ts`).
//
// The generated/authored `*.md` **is a genuine DocSpecs document**: line 1 is
// the `<!-- docspec: <schema-id>/<version> -->` declaration, every populated
// section is one markdown heading whose machine-readable identity is the
// DocSpecs headline comment `<!--[SECTION-ID]-->` and whose text is the
// human-readable Title-Case member name. Content values are **normal markdown
// text** under their heading (no fences, no anchors); `@Form` sections use the
// DocSpecs plain-text `FieldName: value` format; a list emits its `-LST`
// container heading (id = the list's `@SectionId`, else the member segment)
// at the owner's child level, wrapping the numbered item headings one level
// deeper — each item carrying the `@SectionIdPattern` resolved with the 1-based
// position (`GOAL-ITEM-xxx` → `GOAL-ITEM-1`, else `<member>-<pos>`). The
// container itself carries no body. Id-less members are **transparent** (mirroring
// the DR3 schema generator): a transparent value member's text or form block
// is the owner's body region, emitted without a heading and bound at its own
// path; a transparent section/complex member never heads — its id-bearing
// descendants hoist to the owner's child level (paths keep the transparent
// segments). Section/complex headings without a field-level `@SectionId`
// carry the target class's `@SectionId`.
//
// Escaping (DR1 §1.3): a content line starting with `#` at column 0 is
// emitted as `\#` (and a leading `\#`… run gains one more backslash), except
// inside fenced code blocks, which shield their lines verbatim. Consecutive
// blank lines are collapsed to one on emit; parse trims each value of
// leading/trailing blank lines and does not re-collapse.
//
// The codec is free of any UI: it reads from / resolves against a SpecModel
// (through the BuildSomMetaTree metadata tree) and a SpecDocument. Parse does
// **not** mutate the document — it returns staged values keyed exactly like
// SpecDocument.ToJSON plus a rejection report; the caller applies them.
// Anything that cannot be mapped — an unknown section id, a child heading
// under a value leaf, orphaned text — is collected into
// SpecMarkdownResult.Rejections rather than dropped (DR1 §1.7).
//
// Go conventions (DR19): where the other ports throw, ExportRoot returns an
// error (the unterminated-fence case); the empty string stands in for a null
// Anchor.

import (
	"regexp"
	"strings"
	"unicode"
)

// Why an imported Markdown block was rejected (DR1 §1.7 rejection protocol).
const (
	// SpecMarkdownRejectUnknownSection — the heading's section id does not
	// resolve against the schema tree at its nesting position.
	SpecMarkdownRejectUnknownSection = "unknownSection"
	// SpecMarkdownRejectKindMismatch — a structurally impossible combination,
	// e.g. a child heading nested under a value-leaf (content/scalar/enum)
	// section.
	SpecMarkdownRejectKindMismatch = "kindMismatch"
	// SpecMarkdownRejectOrphanContent — body text with no owning value slot,
	// e.g. prose inside a `@Form` section before the first `FieldName:` line.
	SpecMarkdownRejectOrphanContent = "orphanContent"
	// SpecMarkdownRejectMissingValue — a value-leaf section heading with an
	// empty body.
	SpecMarkdownRejectMissingValue = "missingValue"
	// SpecMarkdownRejectMalformedHeading — a heading line without a parseable
	// `<!--[id]-->` headline comment.
	SpecMarkdownRejectMalformedHeading = "malformedHeading"
)

// SpecMarkdownRejection is one rejected block in a Markdown import (DR1 §1.7).
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

// SpecMarkdownResult is the outcome of parsing a Markdown document (DR1 §1.7):
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

func (b *mdBuffer) String() string {
	return strings.Join(b.parts, "")
}

// Shared with the parser and the DocSpecs validator.
var (
	mdHeadingLineRE     = regexp.MustCompile(`^(#+)\s+(.*)$`)
	mdHeadlineCommentRE = regexp.MustCompile(`^<!--\[([^\]]+)\]-->\s*(.*)$`)
	mdDocspecCommentRE  = regexp.MustCompile(`^<!--\s*docspec:.*-->\s*$`)
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

	mdTrailingWSRE      = regexp.MustCompile(`\s+$`)
	mdBlankRunRE        = regexp.MustCompile(`\n{3,}`)
	mdLeadingNLRE       = regexp.MustCompile(`^\n+`)
	mdTrailingNLRE      = regexp.MustCompile(`\n+$`)
	mdLeadingBlankLnRE  = regexp.MustCompile(`^([ \t]*\n)+`)
	mdTrailingBlankLnRE = regexp.MustCompile(`(\n[ \t]*)+$`)
)

// mdNodeRel is a body slot / effective child: the node plus its relative path.
type mdNodeRel struct {
	node *SomMetaNode
	rel  string
}

// SpecDocumentMarkdown is the codec binding a SpecModel and a concrete
// SpecDocument to the DocSpecs Markdown import/export format (DR1 §1).
type SpecDocumentMarkdown struct {
	Model    *SpecModel
	Document *SpecDocument
	// Metadata trees per root type, built lazily (DR8's generated facades
	// will hand these in directly; until then the bridge derives them).
	trees map[string]*SomMetaTree
}

// NewSpecDocumentMarkdown binds model and document to the codec.
func NewSpecDocumentMarkdown(model *SpecModel, document *SpecDocument) *SpecDocumentMarkdown {
	return &SpecDocumentMarkdown{
		Model:    model,
		Document: document,
		trees:    map[string]*SomMetaTree{},
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

// --- Naming helpers (DR1 §1.2 / §1.5) ----------------------------------------

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
// (DR1 §1.1): `Demo Document` → `demo-document`.
func SpecMarkdownKebabCase(title string) string {
	s := strings.TrimSpace(title)
	s = mdKebabSpaceRE.ReplaceAllString(s, "-")
	s = mdKebabDropRE.ReplaceAllString(s, "")
	return strings.ToLower(s)
}

// SpecMarkdownItemTitleStem is the item heading title stem: Title-Case element
// class name with a trailing `Entry` dropped (DR1 §1.5, normative).
func SpecMarkdownItemTitleStem(elementClassName string) string {
	stem := elementClassName
	if len(stem) > 5 && strings.HasSuffix(stem, "Entry") {
		stem = stem[:len(stem)-5]
	}
	return SpecMarkdownTitleCase(stem)
}

// SpecMarkdownFormLabel is the `FieldName` label written for a form field:
// the model field name with the first letter upper-cased (DR1 §1.4.1).
func SpecMarkdownFormLabel(fieldName string) string {
	if fieldName == "" {
		return fieldName
	}
	rs := []rune(fieldName)
	return strings.ToUpper(string(rs[0])) + string(rs[1:])
}

// --- Export (DR1 §1.1–§1.6) --------------------------------------------------

// headingIdOf is the section id written into (and matched from) a heading for
// node (DR1 §1.2/§1.6): the field-level `@SectionId` when present; for
// section/complex nodes whose field carries none, the target **class**'s
// `@SectionId` (the id the DR3 schema types are keyed by); else the path
// segment (the member name).
func (c *SpecDocumentMarkdown) headingIdOf(node *SomMetaNode) string {
	if node.SectionID != "" {
		return node.SectionID
	}
	if node.Kind == SomMetaKindSection || node.Kind == SomMetaKindComplex {
		if cls := c.Model.ClassNamed(node.ClassName); cls != nil && cls.SectionID != "" {
			return cls.SectionID
		}
	}
	return node.Segment()
}

// --- Transparency (DR1 §1.2, mirroring the DR3 schema generator) -------------
//
// The DR3 `docspecs-schema` generator is normative: only **section-bearing**
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
//   - lists are never transparent — the `-LST` container always heads (DR1
//     §1.2) at the owner's child level and the items sit one level below it
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
	cls := c.Model.ClassNamed(n.ClassName)
	return cls == nil || cls.SectionID == ""
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
// — exactly the headings (and item-heading owners) the DR3 schema knows at
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
// Markdown document. Returns an error when a content value contains an
// unterminated fenced code block (which would shield the remainder of the
// document from heading detection and break the round-trip) — the Go
// analogue of the other ports' throw.
func (c *SpecDocumentMarkdown) ExportRoot(root *SpecRoot) (string, error) {
	tree, err := c.treeFor(root.Type)
	if err != nil {
		return "", err
	}
	node := tree.Root
	b := &mdBuffer{}
	b.writeln("<!-- docspec: " + SpecMarkdownKebabCase(root.Title) + "/" +
		c.Model.ModelVersionString() + " -->")
	rootSeg := node.Segment()
	mdWriteHeading(b, 1, rootSeg, root.Title)
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
func (c *SpecDocumentMarkdown) writeSectionBody(b *mdBuffer, node *SomMetaNode, path string) error {
	if value, ok := c.Document.Content(path); ok {
		if err := c.writeBody(b, value, path); err != nil {
			return err
		}
	}
	for _, slot := range c.bodySlots(node) {
		slotPath := path + "/" + slot.rel
		if slot.node.Kind == SomMetaKindForm {
			if c.formHasValues(slot.node, slotPath) {
				if err := c.writeForm(b, slot.node, slotPath); err != nil {
					return err
				}
			}
		} else if value, ok := c.Document.Content(slotPath); ok {
			if err := c.writeBody(b, value, slotPath); err != nil {
				return err
			}
		}
	}
	return nil
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
			mdWriteHeading(b, depth, c.headingIdOf(child), mdTitleOf(child))
			if err := c.writeBody(b, value, path); err != nil {
				return err
			}
		case SomMetaKindForm:
			if !c.formHasValues(child, path) {
				continue
			}
			mdWriteHeading(b, depth, c.headingIdOf(child), mdTitleOf(child))
			if err := c.writeForm(b, child, path); err != nil {
				return err
			}
		case SomMetaKindSection, SomMetaKindComplex:
			mdWriteHeading(b, depth, c.headingIdOf(child), mdTitleOf(child))
			if err := c.writeSectionBody(b, child, path); err != nil {
				return err
			}
			if err := c.writeChildren(b, child, path, depth+1); err != nil {
				return err
			}
		case SomMetaKindList:
			if err := c.writeListItems(b, child, path, depth); err != nil {
				return err
			}
		}
	}
	return nil
}

// writeListItems emits list node as its `-LST` container heading (DR1
// §1.2/§1.5) at depth, wrapping the numbered item headings one level deeper.
// The container is a real section — the id the DR3 schema keys its container
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
	mdWriteHeading(b, depth, c.headingIdOf(node), mdTitleOf(node))
	element := node.ElementNode
	stemSource := node.TypeName
	if element != nil {
		stemSource = element.ClassName
	}
	stem := SpecMarkdownItemTitleStem(stemSource)
	pattern := node.SectionIDPattern
	if pattern == "" && element != nil {
		pattern = element.SectionIDPattern
	}
	for i, itemPath := range items {
		pos := i + 1
		// DR1 §1.2: md list identity is purely positional. The heading id is the
		// `@SectionIdPattern` resolved with the 1-based position
		// (`GOAL-ITEM-xxx` → `GOAL-ITEM-1`); only pattern-less lists fall back to
		// `<member>-<pos>`. A stored `@SectionId` (AA1 generated or a
		// criterion-5 override) is NOT surfaced — it round-trips through the
		// `*.docspecs.yaml` format (§2), not md — so the exported md always
		// validates against the `[0-9]+` schema pattern (DRC5).
		var itemID string
		if pattern != "" {
			itemID = strings.Join(strings.Split(pattern, "xxx"), itoa(pos))
		} else {
			member := node.MemberName
			if member == "" {
				member = node.Segment()
			}
			itemID = member + "-" + itoa(pos)
		}
		// Items sit one level below the container.
		mdWriteHeading(b, depth+1, itemID, stem+" "+itoa(pos))
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
			if !element.Recursive {
				if err := c.writeChildren(b, element, itemPath, depth+2); err != nil {
					return err
				}
			}
		}
	}
	return nil
}

func (c *SpecDocumentMarkdown) formHasValues(node *SomMetaNode, path string) bool {
	if node.Form == nil {
		return false
	}
	for _, f := range node.Form.Fields {
		if _, ok := c.Document.FormField(path, f.Name); ok {
			return true
		}
	}
	return false
}

func (c *SpecDocumentMarkdown) writeForm(b *mdBuffer, node *SomMetaNode, path string) error {
	var fields []*SomFormFieldMeta
	if node.Form != nil {
		fields = node.Form.Fields
	}
	for _, f := range fields {
		value, ok := c.Document.FormField(path, f.Name)
		if !ok {
			continue
		}
		prepared, err := c.prepareValue(value, path)
		if err != nil {
			return err
		}
		lines := strings.Split(prepared, "\n")
		b.writeln(SpecMarkdownFormLabel(f.Name) + ": " + lines[0])
		for _, line := range lines[1:] {
			// §1.4.3 generalised: any continuation line that could be mistaken
			// for a field-label line gains one leading space; parse strips it.
			if mdLabelShapedRE.MatchString(line) {
				b.writeln(" " + line)
			} else {
				b.writeln(line)
			}
		}
	}
	b.writeln("")
	return nil
}

// mdWriteHeading writes `## <!--[ID]--> Title` at depth. DR1 §1.2 is
// normative — heading level = 1 + section depth, **uncapped**: deep models
// (the Solution Blueprint nests past markdown's native 6 levels) keep their
// structure; the parse grammar accepts `#{7,}` accordingly. Capping would
// silently flatten distinct nesting positions into siblings and break schema
// validation.
func mdWriteHeading(b *mdBuffer, depth int, id, title string) {
	b.writeln(strings.Repeat("#", depth) + " <!--[" + id + "]--> " + title)
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

// prepareValue is the emit-side value normalisation (DR1 §1.3): collapse 2+
// blank lines to one, trim leading/trailing blank lines, escape heading-like
// lines outside fences. Returns an error for an unterminated fence.
func (c *SpecDocumentMarkdown) prepareValue(value, path string) (string, error) {
	collapsed := mdBlankRunRE.ReplaceAllString(value, "\n\n")
	collapsed = mdLeadingNLRE.ReplaceAllString(collapsed, "")
	collapsed = mdTrailingNLRE.ReplaceAllString(collapsed, "")
	fence := &MarkdownFenceTracker{}
	var out []string
	for _, line := range strings.Split(collapsed, "\n") {
		if fence.InFence() {
			out = append(out, line) // §1.3.4: fences shield their lines.
		} else if mdEscapableRE.MatchString(line) {
			out = append(out, "\\"+line)
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

func mdTitleOf(node *SomMetaNode) string {
	name := node.MemberName
	if name == "" {
		name = node.ClassName
	}
	return SpecMarkdownTitleCase(name)
}

// --- Import (DR1 §1.7) --------------------------------------------------------

// Parse parses text into staged values + a rejection report, **without**
// mutating the document. The caller applies the result as a full overwrite.
func (c *SpecDocumentMarkdown) Parse(text string) *SpecMarkdownResult {
	p := newMdParser(c)
	p.run(strings.Split(text, "\n"))
	return &SpecMarkdownResult{
		Content:      p.content,
		Forms:        p.forms,
		Lists:        p.listsJson(),
		Rejections:   p.rejections,
		RootPrefixes: p.rootPrefixes,
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
	codec        *SpecDocumentMarkdown
	content      map[string]string
	forms        map[string]map[string]string
	lists        map[string]*mdListState
	listOrder    []string
	rejections   []*SpecMarkdownRejection
	rootPrefixes map[string]bool
	stack        []*mdFrame
	fence        *MarkdownFenceTracker
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
		rootPrefixes: map[string]bool{},
		fence:        &MarkdownFenceTracker{},
	}
}

func (p *mdParser) run(lines []string) {
	for i, raw := range lines {
		lineNo := i + 1
		trimmed := mdTrailingWSRE.ReplaceAllString(raw, "")

		if !p.fence.InFence() {
			if len(p.stack) == 0 && mdDocspecCommentRE.MatchString(trimmed) {
				continue // §1.1 header — informational.
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

	if len(p.stack) == 0 {
		p.openRoot(level, id, lineNo)
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

	// 1. Under a `-LST` container frame (DR1 §1.2), every child heading is one
	//    of that list's items — resolved positionally, not by the schema tree.
	if pNode.Kind == SomMetaKindList {
		p.openItemHeading(level, parent, pNode, id, lineNo)
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
			p.stack = append(p.stack, &mdFrame{
				level: level,
				node:  entry.node,
				path:  parent.path + "/" + entry.rel,
				line:  lineNo,
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

// openItemHeading opens a list-item frame under a `-LST` container frame (DR1
// §1.2). The heading id is matched positionally against the container's list:
// the `<member>-<n>` fallback id, the `@SectionIdPattern` resolved with a
// number (`GOAL-ITEM-3`, parses back as item `<n>`), a pattern-shaped stored
// id, or — for any other id — an anonymous next item carrying the stored id.
func (p *mdParser) openItemHeading(
	level int, container *mdFrame, listNode *SomMetaNode, id string, lineNo int,
) {
	listPath := container.path
	member := listNode.MemberName
	if member == "" {
		member = listNode.Segment()
	}
	anonRE, err := regexp.Compile("^" + regexp.QuoteMeta(member) + "-([0-9]+)$")
	if err == nil {
		if anon := anonRE.FindStringSubmatch(id); anon != nil {
			p.openItem(level, listPath, listNode, atoi(anon[1]), "", true, lineNo)
			return
		}
	}
	element := listNode.ElementNode
	pattern := listNode.SectionIDPattern
	if pattern == "" && element != nil {
		pattern = element.SectionIDPattern
	}
	if pattern != "" {
		// Canonical anonymous id: the pattern with `xxx` as a number — parses
		// back as item <n>, NOT as a stored id (DR1 §1.2 round-trip).
		parts := strings.Split(pattern, "xxx")
		if len(parts) == 2 {
			numberedRE, err := regexp.Compile("^" + regexp.QuoteMeta(parts[0]) +
				"([0-9]+)" + regexp.QuoteMeta(parts[1]) + "$")
			if err == nil {
				if numbered := numberedRE.FindStringSubmatch(id); numbered != nil {
					p.openItem(level, listPath, listNode, atoi(numbered[1]), "", true, lineNo)
					return
				}
			}
		}
		if mdPatternMatches(pattern, id) {
			p.openItem(level, listPath, listNode, 0, id, false, lineNo)
			return
		}
	}
	// Any other id under the container is an anonymous next item; a genuine
	// stored id is kept (it survives only through the yaml format, DR1 §2).
	p.openItem(level, listPath, listNode, 0, id, false, lineNo)
}

func (p *mdParser) openRoot(level int, id string, lineNo int) {
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
			p.rootPrefixes[seg] = true
			p.stack = append(p.stack, &mdFrame{
				level: level,
				node:  tree.Root,
				path:  seg,
				line:  lineNo,
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

// openItem opens a list-item frame. n (with hasN=true) is the anonymous
// heading number (also the path number); a stored-id item gets the next free
// number instead.
func (p *mdParser) openItem(
	level int, listPath string, listNode *SomMetaNode,
	n int, storedID string, hasN bool, lineNo int,
) {
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
	if !hasN {
		state.ids[itemPath] = storedID
	}
	p.stack = append(p.stack, &mdFrame{
		level: level,
		node:  listNode.ElementNode,
		path:  itemPath,
		line:  lineNo,
	})
}

// mdPatternMatches: `GOAL-ITEM-xxx` → `^GOAL-ITEM-.+$` — the
// `@SectionIdPattern` wildcard.
func mdPatternMatches(pattern, id string) bool {
	parts := strings.Split(pattern, "xxx")
	quoted := make([]string, len(parts))
	for i, part := range parts {
		quoted[i] = regexp.QuoteMeta(part)
	}
	re, err := regexp.Compile("^" + strings.Join(quoted, ".+") + "$")
	if err != nil {
		return false
	}
	return re.MatchString(id)
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

// finalizeBodySlots binds a heading's body region against the owner's
// transparent body slots (DR1 §1.2 transparency): `FieldName:` lines matching
// a transparent form's fields route to that form (nearest form in slot order,
// wrapping); all other text binds to the first non-form slot — or to the
// owner's own path when no such slot exists.
func (p *mdParser) finalizeBodySlots(frame *mdFrame, slots []mdNodeRel) {
	var formSlots []mdNodeRel
	var contentSlots []mdNodeRel
	for _, s := range slots {
		if s.node.Kind == SomMetaKindForm {
			formSlots = append(formSlots, s)
		} else {
			contentSlots = append(contentSlots, s)
		}
	}
	contentPath := frame.path
	if len(contentSlots) > 0 {
		contentPath = frame.path + "/" + contentSlots[0].rel
	}

	if len(formSlots) == 0 {
		value := mdRestoreValue(frame.body)
		if value != "" {
			p.content[contentPath] = value
		}
		return
	}

	findField := func(label string) (int, string, bool) {
		lower := strings.ToLower(label)
		for k := 0; k < len(formSlots); k++ {
			idx := (p.currentFormIdx + k) % len(formSlots)
			form := formSlots[idx].node.Form
			if form == nil {
				continue
			}
			for _, f := range form.Fields {
				if strings.ToLower(f.Name) == lower {
					return idx, f.Name, true
				}
			}
		}
		return 0, "", false
	}

	fence := &MarkdownFenceTracker{}
	currentField := ""
	currentFormPath := ""
	haveField := false
	var currentLines []string
	var contentLines []string

	flush := func() {
		if haveField {
			value := mdRestoreValue(currentLines)
			if value != "" {
				if p.forms[currentFormPath] == nil {
					p.forms[currentFormPath] = map[string]string{}
				}
				p.forms[currentFormPath][currentField] = value
			}
		}
		currentLines = nil
	}

	p.currentFormIdx = 0
	for _, line := range frame.body {
		if !fence.InFence() {
			if m := mdFieldLabelRE.FindStringSubmatch(line); m != nil {
				if idx, name, ok := findField(m[1]); ok {
					flush()
					p.currentFormIdx = idx
					haveField = true
					currentField = name
					currentFormPath = frame.path + "/" + formSlots[idx].rel
					currentLines = []string{m[2]}
					fence.Feed(line)
					continue
				}
			}
		}
		// Continuation: strip the one escape space of a label-shaped line.
		text := line
		if !fence.InFence() && haveField && mdContinuationLabelRE.MatchString(line) {
			text = line[1:]
		}
		if haveField {
			currentLines = append(currentLines, text)
		} else {
			contentLines = append(contentLines, text)
		}
		fence.Feed(line)
	}
	flush()
	if value := mdRestoreValue(contentLines); value != "" {
		p.content[contentPath] = value
	}
}

func (p *mdParser) finalizeForm(frame *mdFrame, node *SomMetaNode, path string) {
	var fields []*SomFormFieldMeta
	if node.Form != nil {
		fields = node.Form.Fields
	}
	fieldsByLower := map[string]string{}
	for _, f := range fields {
		fieldsByLower[strings.ToLower(f.Name)] = f.Name
	}
	fence := &MarkdownFenceTracker{}
	currentField := ""
	haveField := false
	var currentLines []string

	flush := func(lineNo int) {
		if haveField {
			value := mdRestoreValue(currentLines)
			if value != "" {
				if p.forms[path] == nil {
					p.forms[path] = map[string]string{}
				}
				p.forms[path][currentField] = value
			}
		} else {
			for _, l := range currentLines {
				if strings.TrimSpace(l) != "" {
					p.rejections = append(p.rejections, &SpecMarkdownRejection{
						Line:    lineNo,
						Reason:  SpecMarkdownRejectOrphanContent,
						Message: "text in a @Form section before the first field label",
						Anchor:  path,
					})
					break
				}
			}
		}
		currentLines = nil
	}

	for i, line := range frame.body {
		if !fence.InFence() {
			if m := mdFieldLabelRE.FindStringSubmatch(line); m != nil {
				if fieldName, ok := fieldsByLower[strings.ToLower(m[1])]; ok {
					flush(frame.line + i)
					haveField = true
					currentField = fieldName
					currentLines = []string{m[2]}
					fence.Feed(line)
					continue
				}
			}
		}
		// Continuation: strip the one escape space of a label-shaped line.
		if !fence.InFence() && mdContinuationLabelRE.MatchString(line) {
			currentLines = append(currentLines, line[1:])
		} else {
			currentLines = append(currentLines, line)
		}
		fence.Feed(line)
	}
	flush(frame.line + len(frame.body))
}

// mdRestoreValue is the parse-side value restoration (DR1 §1.3): trim
// leading/trailing blank lines and unescape `\#`-escaped heading lines
// outside fences.
func mdRestoreValue(body []string) string {
	fence := &MarkdownFenceTracker{}
	out := make([]string, 0, len(body))
	for _, line := range body {
		if !fence.InFence() && mdEscapedHeadingRE.MatchString(line) {
			out = append(out, line[1:])
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
