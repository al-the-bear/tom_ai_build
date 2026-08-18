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
// text** under their heading (no fences, no anchors); `@Form` sections use the
// DocSpecs plain-text `FieldName: value` format; a list emits its `-LST`
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
// SpecMarkdownResult.Rejections rather than dropped (SOM §11.7).
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
// SpecDocument to the DocSpecs Markdown import/export format (SOM §11).
type SpecDocumentMarkdown struct {
	Model    *SpecModel
	Document *SpecDocument
	// Metadata trees per root type, built lazily (the generated facades
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

// mdCodeSpecOf extracts the `codeSpec="…"` value from a heading-comment
// key=value region (codespecs_mapping.md §9.2). Returns the empty string when
// the region carries no `codeSpec` key (first non-empty submatch, trimmed).
func mdCodeSpecOf(region string) string {
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
	if node.Kind == SomMetaKindSection || node.Kind == SomMetaKindComplex {
		if cls := c.Model.ClassNamed(node.ClassName); cls != nil && cls.SectionID != "" {
			return cls.SectionID
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
	tree, err := c.treeFor(root.Type)
	if err != nil {
		return "", err
	}
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
	mdWriteHeading(b, 1, rootSeg, rootTitle, c.Document.CodeSpecOr(rootSeg))
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
			mdWriteHeading(b, depth, c.headingIdOf(child), c.headingTitle(path, child), c.Document.CodeSpecOr(path))
			if err := c.writeBody(b, value, path); err != nil {
				return err
			}
		case SomMetaKindForm:
			if !c.formHasValues(child, path) {
				continue
			}
			mdWriteHeading(b, depth, c.headingIdOf(child), c.headingTitle(path, child), c.Document.CodeSpecOr(path))
			if err := c.writeForm(b, child, path); err != nil {
				return err
			}
		case SomMetaKindSection, SomMetaKindComplex:
			mdWriteHeading(b, depth, c.headingIdOf(child), c.headingTitle(path, child), c.Document.CodeSpecOr(path))
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
	mdWriteHeading(b, depth, c.headingIdOf(node), c.headingTitle(listPath, node), c.Document.CodeSpecOr(listPath))
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
		mdWriteHeading(b, depth+1, itemID, itemTitle, c.Document.CodeSpecOr(itemPath))
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

// writeForm writes a `@Form` section body: the preamble content (when set)
// followed by one `FieldName: value` group per populated field (SOM §11.4).
// Returns an error when the form holds a field the model does not declare.
func (c *SpecDocumentMarkdown) writeForm(b *mdBuffer, node *SomMetaNode, path string) error {
	if err := c.checkFormDeclared(node, path); err != nil {
		return err
	}
	var fields []*SomFormFieldMeta
	if node.Form != nil {
		fields = node.Form.Fields
	}
	fieldBuf := &mdBuffer{}
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
		fieldBuf.writeln(SpecMarkdownFormLabel(f.Name) + ": " + lines[0])
		for _, line := range lines[1:] {
			// SOM §11.4 generalised: any continuation line that could be mistaken
			// for a field-label line gains one leading space; parse strips it.
			if mdLabelShapedRE.MatchString(line) {
				fieldBuf.writeln(" " + line)
			} else {
				fieldBuf.writeln(line)
			}
		}
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
			if fieldBuf.String() != "" {
				b.writeln("")
			}
		}
	}
	b.write(fieldBuf.String())
	b.writeln("")
	return nil
}

// mdWriteHeading writes `## <!--[ID]--> Title` at depth. SOM §11.2 is
// normative — heading level = 1 + section depth, **uncapped**: deep models
// (the Solution Blueprint nests past markdown's native 6 levels) keep their
// structure; the parse grammar accepts `#{7,}` accordingly. Capping would
// silently flatten distinct nesting positions into siblings and break schema
// validation.
//
// When codeSpec is non-empty it is emitted as a `codeSpec="…"` key inside the
// same headline comment (codespecs_mapping.md §9.2): `## <!--[ID]
// codeSpec="A,B"--> Title`. Byte-identical to before when empty.
func mdWriteHeading(b *mdBuffer, depth int, id, title, codeSpec string) {
	code := ""
	if codeSpec != "" {
		code = ` codeSpec="` + codeSpec + `"`
	}
	b.writeln(strings.Repeat("#", depth) + " <!--[" + id + "]" + code + "--> " + title)
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

// prepareValue is the emit-side value normalisation (SOM §11.3): collapse 2+
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
			out = append(out, line) // SOM §11.3: fences shield their lines.
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
		Headlines:    p.headlines,
		CodeSpecs:    p.codeSpecs,
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
	codeSpecs    map[string]string
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
		headlines:    map[string]string{},
		codeSpecs:    map[string]string{},
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
	codeSpec := mdCodeSpecOf(m[2])
	title := strings.TrimSpace(m[3])

	if len(p.stack) == 0 {
		p.openRoot(level, id, title, codeSpec, lineNo)
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
		p.openItemHeading(level, parent, pNode, id, title, codeSpec, lineNo)
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
			p.stack = append(p.stack, &mdFrame{
				level: level,
				node:  entry.node,
				path:  path,
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

// openItemHeading opens a list-item frame under a `-LST` container frame (SOM
// §11.2). The heading id is matched positionally against the container's list:
// the `<member>-<n>` fallback id, the `@SectionIdPattern` resolved with a
// number (`GOAL-ITEM-3`, parses back as item `<n>`), a pattern-shaped stored
// id, or — for any other id — an anonymous next item carrying the stored id.
func (p *mdParser) openItemHeading(
	level int, container *mdFrame, listNode *SomMetaNode, id, title, codeSpec string, lineNo int,
) {
	listPath := container.path
	member := listNode.MemberName
	if member == "" {
		member = listNode.Segment()
	}
	anonRE, err := regexp.Compile("^" + regexp.QuoteMeta(member) + "-([0-9]+)$")
	if err == nil {
		if anon := anonRE.FindStringSubmatch(id); anon != nil {
			p.openItem(level, listPath, listNode, atoi(anon[1]), "", true, title, codeSpec, lineNo)
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
		// back as item <n>, NOT as a stored id (SOM §11.2 round-trip).
		parts := strings.Split(pattern, "xxx")
		if len(parts) == 2 {
			numberedRE, err := regexp.Compile("^" + regexp.QuoteMeta(parts[0]) +
				"([0-9]+)" + regexp.QuoteMeta(parts[1]) + "$")
			if err == nil {
				if numbered := numberedRE.FindStringSubmatch(id); numbered != nil {
					p.openItem(level, listPath, listNode, atoi(numbered[1]), "", true, title, codeSpec, lineNo)
					return
				}
			}
		}
		if mdPatternMatches(pattern, id) {
			p.openItem(level, listPath, listNode, 0, id, false, title, codeSpec, lineNo)
			return
		}
	}
	// Any other id under the container is an anonymous next item carrying the
	// stored id — stored ids round-trip through Markdown too (YRD3).
	p.openItem(level, listPath, listNode, 0, id, false, title, codeSpec, lineNo)
}

func (p *mdParser) openRoot(level int, id, title, codeSpec string, lineNo int) {
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
	n int, storedID string, hasN bool, title, codeSpec string, lineNo int,
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
// transparent body slots (SOM §11.2 transparency): `FieldName:` lines matching
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
				if idx, f, ok := findField(m[1]); ok {
					flush()
					p.currentFormIdx = idx
					haveField = true
					currentField = f.Name
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

// finalizeForm parses an id-bearing `@Form` section's body: the preamble text
// before the first field label binds to the form's own content (SOM §11.4
// rule 7); everything from the first label on binds to the named fields.
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
		value := mdRestoreValue(currentLines)
		if haveField {
			if value != "" {
				if p.forms[path] == nil {
					p.forms[path] = map[string]string{}
				}
				p.forms[path][currentField] = value
			}
		} else if value != "" {
			p.content[path] = value
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

// mdRestoreValue is the parse-side value restoration (SOM §11.3): trim
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
