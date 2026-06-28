package somruntime

// spec_document_markdown.go — generic, meta-data-driven Markdown codec for a
// TomSpecs document, a faithful port of
// `tom_som_dart_runtime/lib/src/spec_document_markdown.dart` (and the TypeScript
// `spec_document_markdown.ts`).
//
// A `<!-- docspec: -->` header, then one heading per populated section (sparse,
// in schema order), with each section's machine-readable section path as the
// first token of its heading so import maps back unambiguously. Leaf values live
// in fenced code blocks whose fence is widened past any backtick run in the
// value, so embedded code bodies round-trip verbatim. Form fields are introduced
// by a `<!-- field: name -->` anchor; list items appear as nested `…-N` sections,
// so list membership is recovered from the paths alone on import.
//
// Parse does not mutate the document — it returns staged values keyed exactly
// like SpecDocument.ToJSON plus a rejection report; the caller applies them.

import (
	"regexp"
	"sort"
	"strings"
)

var (
	headingRE     = regexp.MustCompile(`^(#{1,6})\s+(\S+)`)
	fieldAnchorRE = regexp.MustCompile("^<!--\\s*field:\\s*(\\S+)\\s*-->$")
	fenceOpenRE   = regexp.MustCompile("^(`{3,})")
	itemSegRE     = regexp.MustCompile(`^(.+)-(\d+)$`)
)

// Why an imported Markdown block was rejected.
const (
	SpecMarkdownRejectUnknownSection   = "unknownSection"
	SpecMarkdownRejectKindMismatch     = "kindMismatch"
	SpecMarkdownRejectOrphanBlock      = "orphanBlock"
	SpecMarkdownRejectMissingValue     = "missingValue"
	SpecMarkdownRejectMalformedHeading = "malformedHeading"
)

// SpecMarkdownRejection is one rejected block in a Markdown import. Reported,
// never silently dropped.
type SpecMarkdownRejection struct {
	Line    int
	Reason  string
	Message string
	Anchor  string
}

// String renders the rejection as "line N: reason (anchor) — message".
func (r SpecMarkdownRejection) String() string {
	anchor := ""
	if r.Anchor != "" {
		anchor = " (" + r.Anchor + ")"
	}
	return "line " + itoa(r.Line) + ": " + r.Reason + anchor + " — " + r.Message
}

// SpecMarkdownResult is the outcome of parsing a Markdown document: the staged
// values plus every rejected block. The values are keyed exactly like
// SpecDocument.ToJSON.
type SpecMarkdownResult struct {
	Content      map[string]string
	Forms        map[string]map[string]string
	Lists        map[string]ListJson
	Rejections   []SpecMarkdownRejection
	RootPrefixes map[string]bool
}

// IsClean reports whether no block was rejected.
func (r *SpecMarkdownResult) IsClean() bool {
	return len(r.Rejections) == 0
}

// AppliedCount returns the number of content + form-field values staged.
func (r *SpecMarkdownResult) AppliedCount() int {
	n := len(r.Content)
	for _, m := range r.Forms {
		n += len(m)
	}
	return n
}

// pending is a value target between a section/field anchor and its fenced block.
type pending struct {
	line   int
	path   string
	field  string
	hasFld bool
	filled bool
}

func (p *pending) anchor() string {
	if p.hasFld {
		return p.path + " :: " + p.field
	}
	return p.path
}

// fence renders a fenced code block holding value verbatim. The fence is one
// backtick longer than the longest backtick run in value (min 3).
func fence(value, info string) string {
	maxRun := 0
	run := 0
	for _, ch := range value {
		if ch == '`' {
			run++
			if run > maxRun {
				maxRun = run
			}
		} else {
			run = 0
		}
	}
	n := 3
	if maxRun+1 > n {
		n = maxRun + 1
	}
	f := strings.Repeat("`", n)
	var parts []string
	parts = append(parts, f+info+"\n")
	for _, line := range strings.Split(value, "\n") {
		parts = append(parts, line+"\n")
	}
	parts = append(parts, f)
	return strings.Join(parts, "")
}

type mdBuffer struct {
	parts []string
}

func (b *mdBuffer) writeln(text string) {
	b.parts = append(b.parts, text, "\n")
}

func (b *mdBuffer) String() string {
	return strings.Join(b.parts, "")
}

func mdHeading(b *mdBuffer, depth int, path, name string) {
	d := depth
	if d > 6 {
		d = 6
	}
	b.writeln(strings.Repeat("#", d) + " " + path + " — " + name)
}

// SpecDocumentMarkdown is a codec binding a SpecModel and a concrete
// SpecDocument to the Markdown import/export format.
type SpecDocumentMarkdown struct {
	Model      *SpecModel
	Document   *SpecDocument
	reflection *SpecReflection
}

// NewSpecDocumentMarkdown binds a model and document to the Markdown codec.
func NewSpecDocumentMarkdown(model *SpecModel, document *SpecDocument) *SpecDocumentMarkdown {
	return &SpecDocumentMarkdown{
		Model:      model,
		Document:   document,
		reflection: NewSpecReflection(model),
	}
}

func (m *SpecDocumentMarkdown) rootSeg(r *SpecRoot) string {
	return m.reflection.RootSegment(r)
}

func (m *SpecDocumentMarkdown) fieldSeg(f *SpecField) string {
	return m.reflection.FieldSegment(f)
}

// --- Export ----------------------------------------------------------------

// ExportRoot renders the populated subtree of root as a schema-conformant
// Markdown document with a `<!-- docspec: -->` header.
func (m *SpecDocumentMarkdown) ExportRoot(root *SpecRoot) string {
	b := &mdBuffer{}
	seg := m.rootSeg(root)
	b.writeln("<!-- docspec: " + strings.ToLower(seg) + "/1 -->")
	b.writeln("# " + seg + " — " + root.Title)
	cls := m.Model.ClassNamed(root.Type)
	if strings.TrimSpace(root.Description) != "" {
		b.writeln("")
		b.writeln(strings.TrimSpace(root.Description))
	}
	if cls != nil {
		m.exportClass(b, cls, seg, 2, map[string]bool{root.Type: true})
	}
	return b.String()
}

func (m *SpecDocumentMarkdown) exportClass(b *mdBuffer, cls *SpecClass, basePath string, depth int, seenTypes map[string]bool) {
	for _, field := range cls.Fields {
		path := basePath + "/" + m.fieldSeg(field)
		if !m.Document.HasValuesUnder(path) {
			continue
		}
		kind := field.Kind
		switch kind {
		case SpecFieldKindContent, SpecFieldKindScalar, SpecFieldKindEnum:
			value, ok := m.Document.Content(path)
			if !ok {
				continue
			}
			mdHeading(b, depth, path, field.Name)
			b.writeln(fence(value, field.ContentType))
			b.writeln("")
		case SpecFieldKindForm:
			mdHeading(b, depth, path, field.Name)
			for _, ff := range field.FormFields {
				value, ok := m.Document.FormField(path, ff.Name)
				if !ok {
					continue
				}
				b.writeln("<!-- field: " + ff.Name + " -->")
				b.writeln(fence(value, ""))
				b.writeln("")
			}
		case SpecFieldKindList:
			elem := m.Model.ClassNamed(field.ElementType)
			recursive := field.ElementType != "" && seenTypes[field.ElementType]
			mdHeading(b, depth, path, field.Name)
			b.writeln("")
			if elem == nil || recursive {
				continue
			}
			nextSeen := copySeen(seenTypes)
			nextSeen[field.ElementType] = true
			for _, itemPath := range m.Document.ListItems(path) {
				label := field.ElementType
				if label == "" {
					label = "item"
				}
				mdHeading(b, depth+1, itemPath, label)
				b.writeln("")
				m.exportClass(b, elem, itemPath, depth+2, nextSeen)
			}
		case SpecFieldKindComplex, SpecFieldKindSection:
			nested := m.Model.ClassNamed(field.Type)
			recursive := field.Type != "" && seenTypes[field.Type]
			if nested == nil || recursive {
				continue
			}
			mdHeading(b, depth, path, field.Name)
			b.writeln("")
			nextSeen := copySeen(seenTypes)
			nextSeen[field.Type] = true
			m.exportClass(b, nested, path, depth+1, nextSeen)
		}
	}
}

func copySeen(in map[string]bool) map[string]bool {
	out := make(map[string]bool, len(in))
	for k, v := range in {
		out[k] = v
	}
	return out
}

// --- Import ----------------------------------------------------------------

// Parse parses text into staged values + a rejection report, without mutating
// the document.
func (m *SpecDocumentMarkdown) Parse(text string) *SpecMarkdownResult {
	lines := strings.Split(text, "\n")
	result := &SpecMarkdownResult{
		Content:      map[string]string{},
		Forms:        map[string]map[string]string{},
		Lists:        map[string]ListJson{},
		RootPrefixes: map[string]bool{},
	}

	var pend *pending

	flushMissing := func() {
		if pend != nil && !pend.filled {
			result.Rejections = append(result.Rejections, SpecMarkdownRejection{
				Line:    pend.line,
				Reason:  SpecMarkdownRejectMissingValue,
				Message: "no fenced value followed this anchor",
				Anchor:  pend.anchor(),
			})
		}
		pend = nil
	}

	i := 0
	currentKind := ""
	currentPath := ""
	for i < len(lines) {
		raw := lines[i]
		lineNo := i + 1
		trimmed := strings.TrimRight(raw, " \t\r\n\f\v")

		// Heading.
		if heading, ok := headingPath(trimmed); ok {
			flushMissing()
			path := heading
			node := m.reflection.Resolve(path)
			if node == nil {
				result.Rejections = append(result.Rejections, SpecMarkdownRejection{
					Line:    lineNo,
					Reason:  SpecMarkdownRejectUnknownSection,
					Message: "section path does not resolve against the model",
					Anchor:  path,
				})
				currentKind = ""
				currentPath = ""
				i++
				continue
			}
			currentKind = node.Kind
			currentPath = path
			result.RootPrefixes[strings.Split(path, "/")[0]] = true
			if node.IsValueLeaf() {
				pend = &pending{line: lineNo, path: path}
			}
			i++
			continue
		}

		// Form-field anchor.
		if fieldName, ok := fieldAnchor(trimmed); ok {
			flushMissing()
			if currentPath == "" || currentKind != SpecNodeKindForm {
				result.Rejections = append(result.Rejections, SpecMarkdownRejection{
					Line:    lineNo,
					Reason:  SpecMarkdownRejectKindMismatch,
					Message: "form-field anchor outside a `@Form` section",
					Anchor:  fieldName,
				})
				i++
				continue
			}
			pend = &pending{line: lineNo, path: currentPath, field: fieldName, hasFld: true}
			i++
			continue
		}

		// Fence opener.
		if fenceLen, ok := fenceOpen(trimmed); ok {
			var body []string
			j := i + 1
			closer := strings.Repeat("`", fenceLen)
			for j < len(lines) && strings.TrimRight(lines[j], " \t\r\n\f\v") != closer {
				body = append(body, lines[j])
				j++
			}
			value := strings.Join(body, "\n")
			if pend == nil {
				result.Rejections = append(result.Rejections, SpecMarkdownRejection{
					Line:    lineNo,
					Reason:  SpecMarkdownRejectOrphanBlock,
					Message: "fenced value with no owning section or field",
				})
			} else if pend.hasFld {
				if result.Forms[pend.path] == nil {
					result.Forms[pend.path] = map[string]string{}
				}
				result.Forms[pend.path][pend.field] = value
				pend.filled = true
			} else {
				result.Content[pend.path] = value
				pend.filled = true
			}
			pend = nil
			if j < len(lines) {
				i = j + 1
			} else {
				i = j
			}
			continue
		}

		i++
	}
	flushMissing()

	result.Lists = m.reconstructLists(result.Content, result.Forms)
	return result
}

// reconstructLists recovers list membership from the leaf paths: any
// `<base>-<n>` segment whose `<base>` ancestor resolves to a list field denotes
// item `<n>` of that list.
func (m *SpecDocumentMarkdown) reconstructLists(content map[string]string, forms map[string]map[string]string) map[string]ListJson {
	items := map[string][]string{}
	seq := map[string]int{}

	scan := func(path string) {
		segs := strings.Split(path, "/")
		prefix := segs[0]
		for k := 1; k < len(segs); k++ {
			seg := segs[k]
			if mt := itemSegRE.FindStringSubmatch(seg); mt != nil {
				listPath := prefix + "/" + mt[1]
				itemPath := prefix + "/" + seg
				node := m.reflection.Resolve(listPath)
				if node != nil && node.Kind == SpecNodeKindList {
					bucket := items[listPath]
					found := false
					for _, it := range bucket {
						if it == itemPath {
							found = true
							break
						}
					}
					if !found {
						items[listPath] = append(bucket, itemPath)
					}
					n := atoi(mt[2])
					if n > seq[listPath] {
						seq[listPath] = n
					}
				}
			}
			prefix = prefix + "/" + seg
		}
	}

	for _, p := range sortedMapKeys(content) {
		scan(p)
	}
	for _, p := range sortedFormMapKeys(forms) {
		scan(p)
	}

	out := map[string]ListJson{}
	for key, value := range items {
		s, ok := seq[key]
		if !ok {
			s = len(value)
		}
		out[key] = ListJson{Seq: s, Items: value}
	}
	return out
}

func sortedMapKeys(m map[string]string) []string {
	out := make([]string, 0, len(m))
	for k := range m {
		out = append(out, k)
	}
	sort.Strings(out)
	return out
}

func sortedFormMapKeys(m map[string]map[string]string) []string {
	out := make([]string, 0, len(m))
	for k := range m {
		out = append(out, k)
	}
	sort.Strings(out)
	return out
}

// headingPath returns the section path of a heading line (`#{1,6} <path> …`).
func headingPath(line string) (string, bool) {
	if mt := headingRE.FindStringSubmatch(line); mt != nil {
		return mt[2], true
	}
	return "", false
}

// fieldAnchor returns the field name of a `<!-- field: name -->` anchor line.
func fieldAnchor(line string) (string, bool) {
	if mt := fieldAnchorRE.FindStringSubmatch(strings.TrimSpace(line)); mt != nil {
		return mt[1], true
	}
	return "", false
}

// fenceOpen returns the fence length of a fence-opener line (3+ backticks).
func fenceOpen(line string) (int, bool) {
	if mt := fenceOpenRE.FindStringSubmatch(line); mt != nil {
		return len(mt[1]), true
	}
	return 0, false
}
