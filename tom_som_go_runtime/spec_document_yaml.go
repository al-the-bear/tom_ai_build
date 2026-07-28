package somruntime

// spec_document_yaml.go — generic YAML codec for the native `*.docspecs.yaml`
// document format — **hierarchical format v2** (SOM §12); a faithful port of
// `tom_som_dart_runtime/lib/src/spec_document_yaml.dart` (and the TypeScript
// `spec_document_yaml.ts`).
//
// One nested YAML tree whose indentation mirrors the document structure: every
// model node becomes a mapping key (`<section-id> <member-name>`, SOM §12.2),
// sections nest their children, list items appear under their container keyed
// by their stored section id (or an anonymous positional `<member>-<n>` key), a
// node's own body text uses the literal key `content`, a node's own stored
// headline (YRD3) uses the literal key `headline`, and form fields use their
// bare field names. A scalar-valued node (content/scalar/enum leaf or scalar
// list item) that carries a stored headline is emitted as a
// `{headline: …, content: …}` mapping. The former flat two-level path-map format
// (`document: {content: {"A/b": …}}`) is **retired**; readers reject
// `version: 1` files with a clear error (no compatibility path).
//
// Text values are written as literal block scalars (`|2-`), with the SOM §12.4
// escaping rules: the emitter is **self-verifying** (it re-parses each scalar
// it produces via the hand-rolled yaml.go reader — the runtime ships no
// external YAML library — and falls back to a double-quoted JSON-escaped flow
// scalar when the parse differs), and **runs of 2+ consecutive empty lines are
// collapsed to one** before serialization (a deliberate, documented lossy
// normalization — round-trip guarantees are stated "modulo empty-line dedup").
// Non-text values (`int`/`double`/`bool`, enum member names) are plain scalars
// when they self-verify (SOM §12.5). The JSON quoting is byte-for-byte identical to
// JavaScript's JSON.stringify (see jsJSONString) so output is stable across
// every language port — NOT Go's encoding/json, which HTML-escapes < > & and
// U+2028/U+2029.
//
// Both EncodeYaml and DecodeYaml walk the SomMetaTree of the document root:
// the file carries **no paths** — the runtime reconstructs them by matching
// keys against the metadata tree, and a key that matches nothing at its
// position is a structured load error (*SpecYamlFormatException; no silent
// skips). Symmetrically, EncodeYaml errors when the document holds values the
// tree cannot place (nothing is silently dropped).
//
// The optional `review:` pass stays opaque to the runtime (DecodeYaml returns
// it as a raw mapping for the editor to interpret).
//
// Divergences shared with the hand-rolled parser (documented in the JS/TS
// ports too): a bare `key:` parses as an empty mapping (which counts as an
// empty scalar at scalar positions), and the parser never yields booleans, so
// plain-scalar self-verification needs no bool canonicalisation.

import (
	"regexp"
	"strings"
)

// FormatVersion is the on-disk format version (independent of the model-version
// stamp). Version 2 is the hierarchical tree format; version-1 flat files are
// rejected on read.
const FormatVersion = 2

// SpecYamlFormatException is a structural error in a `*.docspecs.yaml` file:
// wrong/unsupported format version, a key that does not match the metadata
// tree at its position, a malformed value shape, or (on encode) document
// values the tree cannot place.
type SpecYamlFormatException struct {
	// Message says what went wrong, naming the offending path/key where
	// applicable.
	Message string
}

func (e *SpecYamlFormatException) Error() string {
	return "SpecYamlFormatException: " + e.Message
}

func yamlFormatErr(message string) error {
	return &SpecYamlFormatException{Message: message}
}

// SpecYamlContents is the decoded passes of a `*.docspecs.yaml` file: the
// `document:` pass as a populated SpecDocument, the `review:` pass as a raw
// mapping (the runtime is review-agnostic), and the optional authoring
// model-version stamp.
type SpecYamlContents struct {
	// Document is the `document:` pass, loaded into a live document (its
	// SpecDocument.ModelVersion is already set from the file stamp).
	Document *SpecDocument
	// Review is the `review:` pass exactly as parsed (empty when absent). The
	// runtime does not interpret it; the editor maps it onto its own review
	// entries.
	Review *YamlMap
	// ModelVersion is the authoring object-model version (major.minor) this
	// document was last written against, or "" for an unstamped/hand-written
	// file. Distinct from FormatVersion (the on-disk format version).
	ModelVersion string
}

// --- Shared scalar machinery (public for the editor's review writer) ---------

// NodeKey returns the mapping key a metadata node writes (SOM §12.2): its
// effective section id, one space, then the exact member name (class name on
// the document root); just the name when the node carries no id.
//
// The id is the field-level SectionID when present; for a section/complex node
// whose field carries none, the target class's id (ClassSectionID) — the id
// its generated schema type is keyed by. This mirrors the markdown codec's heading
// rule exactly. Content, scalar, enum, form and list keys keep only their
// field-level id (no class fallback), and the path Segment is unaffected in
// every case.
func NodeKey(node *SomMetaNode) string {
	name := node.MemberName
	if name == "" {
		name = node.ClassName
	}
	id := node.SectionID
	if id == "" &&
		(node.Kind == SomMetaKindSection || node.Kind == SomMetaKindComplex) {
		id = node.ClassSectionID
	}
	if id == "" {
		return name
	}
	return id + " " + name
}

const jsHexDigits = "0123456789abcdef"

// jsJSONString renders s exactly as JavaScript's JSON.stringify would: wrapped in
// double quotes, with the short escapes for " \ \b \f \n \r \t, control
// characters below 0x20 as lowercase \u00xx, and every other rune (including all
// non-ASCII and the HTML-sensitive < > & /) emitted verbatim.
func jsJSONString(s string) string {
	var b strings.Builder
	b.WriteByte('"')
	for _, r := range s {
		switch r {
		case '"':
			b.WriteString("\\\"")
		case '\\':
			b.WriteString("\\\\")
		case '\b':
			b.WriteString("\\b")
		case '\f':
			b.WriteString("\\f")
		case '\n':
			b.WriteString("\\n")
		case '\r':
			b.WriteString("\\r")
		case '\t':
			b.WriteString("\\t")
		default:
			if r < 0x20 {
				b.WriteString("\\u00")
				b.WriteByte(jsHexDigits[(r>>4)&0xf])
				b.WriteByte(jsHexDigits[r&0xf])
			} else {
				b.WriteRune(r)
			}
		}
	}
	b.WriteByte('"')
	return b.String()
}

// yamlKey returns a safely-quoted mapping key. JSON strings are valid YAML flow
// scalars, so this both quotes and escapes any path/field name unambiguously.
func yamlKey(key string) string {
	return jsJSONString(key)
}

var plainKeyPattern = regexp.MustCompile(
	`^[A-Za-z0-9_][A-Za-z0-9_. -]*[A-Za-z0-9_.\-]$|^[A-Za-z0-9_]$`)

// PlainKey returns key as a plain key when it is YAML-safe by construction
// (section ids, member names, `<id> <name>` pairs), else a JSON-quoted one.
func PlainKey(key string) string {
	if plainKeyPattern.MatchString(key) {
		return key
	}
	return yamlKey(key)
}

var blankRuns = regexp.MustCompile(`\n{3,}`)

// DedupEmptyLines collapses runs of two or more consecutive empty lines to a
// single empty line (SOM §12.4 — the deliberate lossy normalization applied
// to every text value before serialization).
func DedupEmptyLines(value string) string {
	return blankRuns.ReplaceAllString(value, "\n\n")
}

// parsedScalarStr is the Dart-toString-compatible string of a parsed YAML
// scalar (the hand-rolled parser yields string or int only, so no bool
// canonicalisation is needed).
func parsedScalarStr(v interface{}) string {
	switch t := v.(type) {
	case string:
		return t
	case int:
		return itoa(t)
	case bool:
		if t {
			return "true"
		}
		return "false"
	default:
		return ""
	}
}

func trailingNewlines(value string) int {
	n := 0
	i := len(value)
	for i > 0 && value[i-1] == '\n' {
		n++
		i--
	}
	return n
}

// literalBlock builds a literal block scalar (|2<chomp>) with body at relative
// indent 2, or ok=false when chomping can't reproduce the value's trailing
// newlines (two or more) — those fall back to JSON quoting.
func literalBlock(value string) (string, bool) {
	trailing := trailingNewlines(value)
	var chomp, core string
	if trailing == 0 {
		chomp = "-"
		core = value
	} else if trailing == 1 {
		chomp = ""
		core = value[:len(value)-1]
	} else {
		return "", false
	}
	var parts []string
	parts = append(parts, "|2"+chomp)
	for _, line := range strings.Split(core, "\n") {
		parts = append(parts, "\n")
		if line != "" {
			parts = append(parts, "  "+line)
		}
	}
	return strings.Join(parts, ""), true
}

// roundTrips reports whether re-parsing "_v: <block>" yields exactly value
// (the emitter's correctness guard).
func roundTrips(block, value string) bool {
	parsed := YamlParse("_v: " + block + "\n")
	m, ok := parsed.(*YamlMap)
	if !ok {
		return false
	}
	v, ok := m.GetOr("_v").(string)
	return ok && v == value
}

// scalarRepr returns the scalar representation of value: a literal block at
// relative indent 2 when that round-trips, else a JSON-quoted scalar.
func scalarRepr(value string) string {
	if block, ok := literalBlock(value); ok && roundTrips(block, value) {
		return block
	}
	return jsJSONString(value)
}

var yaml11Bool = regexp.MustCompile(
	`^(y|Y|yes|Yes|YES|n|N|no|No|NO|on|On|ON|off|Off|OFF)$`)
var yaml11SexagesimalInt = regexp.MustCompile(`^[-+]?[1-9][0-9_]*(:[0-5]?[0-9])+$`)
var yaml11SexagesimalFloat = regexp.MustCompile(
	`^[-+]?[0-9][0-9_]*(:[0-5]?[0-9])+\.[0-9_]*$`)

// isYaml11Special reports whether value's text is a YAML 1.1 special that a
// 1.1 parser would resolve to a non-string, so it must never be emitted as a
// plain scalar (SOM §12.5). Covers the 1.1-only boolean words and sexagesimal
// int/float literals. Mirrors the Dart reference rule so every emitter's
// plain-scalar decision is identical regardless of the local YAML library.
func isYaml11Special(value string) bool {
	return yaml11Bool.MatchString(value) ||
		yaml11SexagesimalInt.MatchString(value) ||
		yaml11SexagesimalFloat.MatchString(value)
}

// plainScalar returns a plain one-line scalar for a non-text value
// (int/double/bool/enum member name, SOM §12.5) when writing it plainly re-parses
// to exactly value (string compare, matching the document's string-typed
// stores); ok=false otherwise. Values whose text is a YAML 1.1 special are
// forced to the quoted/block path so cross-language round-trips stay identical.
func plainScalar(value string) (string, bool) {
	if value == "" || strings.Contains(value, "\n") {
		return "", false
	}
	if isYaml11Special(value) {
		return "", false
	}
	parsed := YamlParse("_v: " + value + "\n")
	m, ok := parsed.(*YamlMap)
	if !ok {
		return "", false
	}
	v, has := m.Get("_v")
	if !has || v == nil {
		return "", false
	}
	switch v.(type) {
	case *YamlMap, []interface{}:
		return "", false
	}
	if parsedScalarStr(v) != value {
		return "", false
	}
	return value, true
}

type yamlBuffer struct {
	parts []string
}

func (b *yamlBuffer) writeln(text string) {
	b.parts = append(b.parts, text, "\n")
}

func (b *yamlBuffer) write(text string) {
	b.parts = append(b.parts, text)
}

func (b *yamlBuffer) String() string {
	return strings.Join(b.parts, "")
}

func writeRendered(b *yamlBuffer, keyIndent int, renderedKey, repr string) {
	pad := strings.Repeat(" ", keyIndent)
	lines := strings.Split(repr, "\n")
	b.writeln(pad + renderedKey + ": " + lines[0])
	for i := 1; i < len(lines); i++ {
		if lines[i] == "" {
			b.writeln("")
		} else {
			b.writeln(pad + lines[i])
		}
	}
}

// writeScalar writes "<indent><key>: <scalar>" where the scalar is a
// self-verified block scalar (or a JSON-quoted fallback). Block body lines,
// which the builder emits at a relative indent of 2, are re-indented past
// keyIndent. (Kept as the shared helper the editor's review writer uses in the
// other ports.)
func writeScalar(b *yamlBuffer, keyIndent int, key, value string) {
	writeRendered(b, keyIndent, yamlKey(key), scalarRepr(value))
}

// writeHeader writes the file header comment + `version:` line, and the
// optional `modelVersion:` stamp when modelVersion is non-empty.
func writeHeader(b *yamlBuffer, modelVersion string) {
	b.writeln("# TomSpecs document (*.docspecs.yaml). Hierarchical format v2.")
	b.writeln("version: " + itoa(FormatVersion))
	if modelVersion != "" {
		b.writeln("modelVersion: " + jsJSONString(modelVersion))
	}
}

// --- Encode -------------------------------------------------------------------

func isNumericOrBool(typeName string) bool {
	return typeName == "int" || typeName == "double" || typeName == "num" ||
		typeName == "bool"
}

// EncodeYaml serializes document to a header + `version:` (+ `modelVersion:`)
// + hierarchical `document:` pass, walking tree (the metadata tree of the
// document's root).
//
// Sibling order is the tree's child order (@SerializationOrder), list items
// follow their stored sequence; emission is sparse (only populated subtrees
// appear). Returns a *SpecYamlFormatException when the document holds values
// tree cannot place — nothing is silently dropped.
func EncodeYaml(document *SpecDocument, tree *SomMetaTree, modelVersion string) (string, error) {
	b := &yamlBuffer{}
	writeHeader(b, modelVersion)
	if err := newYamlEncoder(document).writeDocumentPass(b, tree); err != nil {
		return "", err
	}
	return b.String(), nil
}

// yamlEncoder is one encode run: it walks the metadata tree, consuming values
// from snapshots of the document's stores so anything left unconsumed at the
// end is a structured error (nothing is silently dropped).
type yamlEncoder struct {
	doc       *SpecDocument
	content   map[string]string
	forms     map[string]map[string]string
	lists     map[string]bool
	headlines map[string]string
	codeSpecs map[string]string
}

func newYamlEncoder(doc *SpecDocument) *yamlEncoder {
	e := &yamlEncoder{
		doc:       doc,
		content:   map[string]string{},
		forms:     map[string]map[string]string{},
		lists:     map[string]bool{},
		headlines: map[string]string{},
		codeSpecs: map[string]string{},
	}
	for _, p := range doc.ContentPaths() {
		e.content[p] = doc.ContentOr(p)
	}
	for _, p := range doc.FormPaths() {
		fields := map[string]string{}
		for _, f := range doc.FormFieldNames(p) {
			fields[f] = doc.FormFieldOr(p, f)
		}
		e.forms[p] = fields
	}
	for _, p := range doc.ListPaths() {
		e.lists[p] = true
	}
	for _, p := range doc.HeadlinePaths() {
		e.headlines[p] = doc.HeadlineOr(p)
	}
	for _, p := range doc.CodeSpecPaths() {
		e.codeSpecs[p] = doc.CodeSpecOr(p)
	}
	return e
}

func (e *yamlEncoder) writeDocumentPass(b *yamlBuffer, tree *SomMetaTree) error {
	root := tree.Root
	body, err := e.mappingBody(root, root.Segment(), 4)
	if err != nil {
		return err
	}
	if err := e.assertNothingLeft(); err != nil {
		return err
	}
	if body == "" {
		b.writeln("document: {}")
		return nil
	}
	b.writeln("document:")
	b.writeln("  " + PlainKey(NodeKey(root)) + ":")
	b.write(body)
	return nil
}

// mappingBody renders the mapping body of node at path (root, a collapsed
// section/complex field, or a list item's element), one line per populated
// entry at indent. Empty when nothing under the node is populated.
func (e *yamlEncoder) mappingBody(node *SomMetaNode, path string, indent int) (string, error) {
	b := &yamlBuffer{}

	// The node's own stored headline — the literal `headline` key (YRD3).
	if ownHeadline, ok := e.headlines[path]; ok {
		delete(e.headlines, path)
		for _, c := range node.Children {
			if NodeKey(c) == "headline" {
				return "", yamlFormatErr(
					"cannot emit the stored headline at `" + path + "`: a child of " +
						node.DebugName() + " also serializes as key `headline`")
			}
		}
		e.writeText(b, indent, "headline", ownHeadline)
	}

	// The node's own codeSpec mapping — the literal `codeSpec` key
	// (codespecs_mapping.md §9.2).
	if ownCodeSpec, ok := e.codeSpecs[path]; ok {
		delete(e.codeSpecs, path)
		for _, c := range node.Children {
			if NodeKey(c) == "codeSpec" {
				return "", yamlFormatErr(
					"cannot emit the stored codeSpec at `" + path + "`: a child of " +
						node.DebugName() + " also serializes as key `codeSpec`")
			}
		}
		e.writeText(b, indent, "codeSpec", ownCodeSpec)
	}

	// The node's own body text — the literal `content` key (SOM §12.2).
	if own, ok := e.content[path]; ok {
		delete(e.content, path)
		for _, c := range node.Children {
			if NodeKey(c) == "content" {
				return "", yamlFormatErr(
					"cannot emit body text at `" + path + "`: a child of " +
						node.DebugName() + " also serializes as key `content`")
			}
		}
		e.writeText(b, indent, "content", own)
	}

	for _, child := range node.Children {
		childPath := SpecPathJoin(path, child.Segment())
		key := NodeKey(child)
		switch child.Kind {
		case SomMetaKindContent:
			v, hasV := e.content[childPath]
			delete(e.content, childPath)
			h, hasH := e.headlines[childPath]
			delete(e.headlines, childPath)
			cs, hasCs := e.codeSpecs[childPath]
			delete(e.codeSpecs, childPath)
			if hasH || hasCs {
				e.writeScalarWithMeta(b, indent, key, h, hasH, cs, hasCs, v, hasV, true)
			} else if hasV {
				e.writeText(b, indent, key, v)
			}
		case SomMetaKindScalar, SomMetaKindEnumValue:
			v, hasV := e.content[childPath]
			delete(e.content, childPath)
			h, hasH := e.headlines[childPath]
			delete(e.headlines, childPath)
			cs, hasCs := e.codeSpecs[childPath]
			delete(e.codeSpecs, childPath)
			if hasH || hasCs {
				e.writeScalarWithMeta(b, indent, key, h, hasH, cs, hasCs, v, hasV, false)
			} else if hasV {
				e.writeValue(b, indent, key, v)
			}
		case SomMetaKindForm:
			if err := e.writeForm(b, indent, key, child, childPath); err != nil {
				return "", err
			}
		case SomMetaKindSection, SomMetaKindComplex:
			sub, err := e.mappingBody(child, childPath, indent+2)
			if err != nil {
				return "", err
			}
			if sub != "" {
				b.writeln(strings.Repeat(" ", indent) + PlainKey(key) + ":")
				b.write(sub)
			}
		case SomMetaKindList:
			if err := e.writeList(b, indent, key, child, childPath); err != nil {
				return "", err
			}
		}
	}
	return b.String(), nil
}

// writeScalarWithMeta emits a scalar-valued node (content/scalar/enum leaf or
// scalar list item) that carries a stored headline and/or a codeSpec mapping as
// a `{headline?: …, codeSpec?: …, content?: …}` mapping (YRD3 +
// codespecs_mapping.md §9.2). Each entry is emitted only when present
// (hasHeadline/hasCodeSpec/hasValue); at least one of headline/codeSpec is
// present at every call site.
func (e *yamlEncoder) writeScalarWithMeta(
	b *yamlBuffer, indent int, key, headline string, hasHeadline bool,
	codeSpec string, hasCodeSpec bool, value string, hasValue, text bool,
) {
	b.writeln(strings.Repeat(" ", indent) + PlainKey(key) + ":")
	if hasHeadline {
		e.writeText(b, indent+2, "headline", headline)
	}
	if hasCodeSpec {
		e.writeText(b, indent+2, "codeSpec", codeSpec)
	}
	if hasValue {
		if text {
			e.writeText(b, indent+2, "content", value)
		} else {
			e.writeValue(b, indent+2, "content", value)
		}
	}
}

func (e *yamlEncoder) writeForm(
	b *yamlBuffer, indent int, key string, node *SomMetaNode, path string,
) error {
	fields, ok := e.forms[path]
	delete(e.forms, path)
	headline, hasHeadline := e.headlines[path]
	delete(e.headlines, path)
	codeSpec, hasCodeSpec := e.codeSpecs[path]
	delete(e.codeSpecs, path)
	if (!ok || len(fields) == 0) && !hasHeadline && !hasCodeSpec {
		return nil
	}
	meta := node.Form
	if meta == nil {
		meta = &SomFormMeta{}
	}
	for name := range fields {
		field := meta.FieldNamed(name)
		if field == nil {
			return yamlFormatErr(
				"form `" + path + "` holds a field `" + name + "` unknown to the model")
		}
	}
	if hasHeadline && meta.FieldNamed("headline") != nil {
		return yamlFormatErr(
			"cannot emit the stored headline at `" + path + "`: the form declares a " +
				"field literally named `headline`")
	}
	if hasCodeSpec && meta.FieldNamed("codeSpec") != nil {
		return yamlFormatErr(
			"cannot emit the stored codeSpec at `" + path + "`: the form declares a " +
				"field literally named `codeSpec`")
	}
	b.writeln(strings.Repeat(" ", indent) + PlainKey(key) + ":")
	if hasHeadline {
		e.writeText(b, indent+2, "headline", headline)
	}
	if hasCodeSpec {
		e.writeText(b, indent+2, "codeSpec", codeSpec)
	}
	for _, f := range meta.Fields {
		v, ok := fields[f.Name]
		if !ok {
			continue
		}
		if isNumericOrBool(f.TypeName) {
			e.writeValue(b, indent+2, f.Name, v)
		} else {
			e.writeText(b, indent+2, f.Name, v)
		}
	}
	return nil
}

func (e *yamlEncoder) writeList(
	b *yamlBuffer, indent int, key string, node *SomMetaNode, path string,
) error {
	delete(e.lists, path)
	headline, hasHeadline := e.headlines[path]
	delete(e.headlines, path)
	codeSpec, hasCodeSpec := e.codeSpecs[path]
	delete(e.codeSpecs, path)
	items := e.doc.ListItems(path)
	if len(items) == 0 && !hasHeadline && !hasCodeSpec {
		return nil
	}
	b.writeln(strings.Repeat(" ", indent) + PlainKey(key) + ":")
	if hasHeadline {
		e.writeText(b, indent+2, "headline", headline)
	}
	if hasCodeSpec {
		e.writeText(b, indent+2, "codeSpec", codeSpec)
	}
	used := map[string]bool{"headline": true, "codeSpec": true}
	pos := 0
	for _, itemPath := range items {
		pos++
		storedID, hasStored := e.doc.ItemSectionID(itemPath)
		itemKey := storedID
		if !hasStored {
			itemKey = node.MemberName + "-" + itoa(pos)
		}
		if hasStored {
			if used[itemKey] {
				return yamlFormatErr(
					"duplicate list item key `" + itemKey + "` at `" + path + "`")
			}
			used[itemKey] = true
		} else {
			bump := pos
			for used[itemKey] {
				bump++
				itemKey = node.MemberName + "-" + itoa(bump)
			}
			used[itemKey] = true
		}
		element := node.ElementNode
		if element == nil {
			// Scalar list: the item is a direct value — unless it carries a stored
			// headline and/or codeSpec, in which case it becomes a `{headline?: …,
			// codeSpec?: …, content: …}` mapping (YRD3 + codespecs_mapping.md §9.2).
			v, hasV := e.content[itemPath]
			delete(e.content, itemPath)
			ih, hasIh := e.headlines[itemPath]
			delete(e.headlines, itemPath)
			ics, hasIcs := e.codeSpecs[itemPath]
			delete(e.codeSpecs, itemPath)
			if hasIh || hasIcs {
				e.writeScalarWithMeta(b, indent+2, itemKey, ih, hasIh, ics, hasIcs, v, hasV, false)
			} else {
				e.writeValue(b, indent+2, itemKey, v)
			}
		} else {
			sub, err := e.mappingBody(element, itemPath, indent+4)
			if err != nil {
				return err
			}
			if sub == "" {
				b.writeln(strings.Repeat(" ", indent+2) + PlainKey(itemKey) + ": {}")
			} else {
				b.writeln(strings.Repeat(" ", indent+2) + PlainKey(itemKey) + ":")
				b.write(sub)
			}
		}
	}
	return nil
}

// writeText writes a text value: empty-line dedup, then a self-verified block
// scalar (or the JSON-quoted fallback).
func (e *yamlEncoder) writeText(b *yamlBuffer, indent int, key, value string) {
	writeRendered(b, indent, PlainKey(key), scalarRepr(DedupEmptyLines(value)))
}

// writeValue writes a non-text value (SOM §12.5): plain when it self-verifies, else
// the text path.
func (e *yamlEncoder) writeValue(b *yamlBuffer, indent int, key, value string) {
	if plain, ok := plainScalar(value); ok {
		b.writeln(strings.Repeat(" ", indent) + PlainKey(key) + ": " + plain)
	} else {
		e.writeText(b, indent, key, value)
	}
}

func (e *yamlEncoder) assertNothingLeft() error {
	var leftovers []string
	for p := range e.content {
		leftovers = append(leftovers, "content at `"+p+"`")
	}
	for p := range e.forms {
		leftovers = append(leftovers, "form values at `"+p+"`")
	}
	for p := range e.lists {
		leftovers = append(leftovers, "list items at `"+p+"`")
	}
	for p := range e.headlines {
		leftovers = append(leftovers, "headline at `"+p+"`")
	}
	for p := range e.codeSpecs {
		leftovers = append(leftovers, "codeSpec at `"+p+"`")
	}
	if len(leftovers) == 0 {
		return nil
	}
	sortStrings(leftovers)
	return yamlFormatErr(
		"document holds values the metadata tree cannot place: " +
			strings.Join(leftovers, "; "))
}

// sortStrings sorts s ascending (a tiny insertion sort keeps the file free of
// a sort import dependency at this call site's hot path — leftover lists are
// error paths and tiny).
func sortStrings(s []string) {
	for i := 1; i < len(s); i++ {
		for j := i; j > 0 && s[j] < s[j-1]; j-- {
			s[j], s[j-1] = s[j-1], s[j]
		}
	}
}

// --- Decode -------------------------------------------------------------------

// DecodeYaml parses a `*.docspecs.yaml` file into its passes, matching every
// `document:` key against tree.
//
// Returns a *SpecYamlFormatException for a missing/unsupported `version:`
// (version 1 is rejected explicitly — the flat format has no compatibility
// path), for any key the metadata tree cannot place, and for malformed value
// shapes. A missing/empty `document:` pass decodes as an empty document.
func DecodeYaml(yamlText string, tree *SomMetaTree) (*SpecYamlContents, error) {
	var root interface{}
	if strings.TrimSpace(yamlText) != "" {
		root = YamlParse(yamlText)
	}
	rootMap, ok := root.(*YamlMap)
	if !ok {
		return nil, yamlFormatErr(
			"not a *.docspecs.yaml mapping (expected version/document keys)")
	}
	version, hasVersion := rootMap.Get("version")
	if !hasVersion || parsedScalarStr(version) != itoa(FormatVersion) {
		if !hasVersion {
			return nil, yamlFormatErr(
				"missing `version:` (expected version: " + itoa(FormatVersion) + ")")
		}
		if parsedScalarStr(version) == "1" {
			return nil, yamlFormatErr(
				"format version 1 (flat path-map) is no longer supported; " +
					"re-save the document in the hierarchical v2 format")
		}
		return nil, yamlFormatErr(
			"unsupported format version `" + versionRepr(version) + "` (expected " +
				itoa(FormatVersion) + ")")
	}

	stamp := ""
	if raw, ok := rootMap.Get("modelVersion"); ok {
		stamp = parsedScalarStr(raw)
	}

	rev, _ := rootMap.GetOr("review").(*YamlMap)
	if rev == nil {
		rev = NewYamlMap()
	}

	document := NewSpecDocument()
	document.ModelVersion = stamp
	docPass, hasDoc := rootMap.Get("document")
	docMap, docIsMap := docPass.(*YamlMap)
	if hasDoc && docPass != nil && !docIsMap {
		return nil, yamlFormatErr("`document:` must be a mapping")
	}
	if docIsMap && docMap.Len() > 0 {
		rootKey := NodeKey(tree.Root)
		keys := docMap.Keys()
		if len(keys) != 1 || keys[0] != rootKey {
			found := make([]string, 0, len(keys))
			for _, k := range keys {
				found = append(found, "`"+k+"`")
			}
			return nil, yamlFormatErr(
				"expected the single document root key `" + rootKey + "`, found: " +
					strings.Join(found, ", "))
		}
		body := docMap.GetOr(keys[0])
		if body != nil {
			bodyMap, ok := body.(*YamlMap)
			if !ok {
				return nil, yamlFormatErr(
					"root `" + rootKey + "` must hold a mapping, not a scalar")
			}
			d := &yamlDecoder{doc: document, tree: tree}
			if err := d.loadMapping(tree.Root, tree.Root.Segment(), bodyMap); err != nil {
				return nil, err
			}
		}
	}

	return &SpecYamlContents{Document: document, Review: rev, ModelVersion: stamp}, nil
}

// versionRepr renders the raw parsed `version:` value for the unsupported-
// version error message (mirroring JS/TS string interpolation, where a
// non-scalar mapping renders as "[object Object]").
func versionRepr(v interface{}) string {
	switch v.(type) {
	case *YamlMap:
		return "[object Object]"
	default:
		return parsedScalarStr(v)
	}
}

// yamlDecoder is one decode run: it walks a parsed YAML mapping alongside the
// metadata tree and populates doc. Any key that matches nothing at its
// position is an error.
type yamlDecoder struct {
	doc  *SpecDocument
	tree *SomMetaTree
}

func (d *yamlDecoder) loadMapping(node *SomMetaNode, path string, body *YamlMap) error {
	for _, key := range body.Keys() {
		value := body.GetOr(key)
		if child := decoderChildByKey(node, key); child != nil {
			if err := d.loadChild(child, SpecPathJoin(path, child.Segment()), key, value); err != nil {
				return err
			}
			continue
		}
		if key == "content" {
			v, err := decoderScalarOf(value, path+"/content")
			if err != nil {
				return err
			}
			d.doc.SetContent(path, v)
			continue
		}
		if key == "headline" {
			v, err := decoderScalarOf(value, path+" (headline)")
			if err != nil {
				return err
			}
			d.doc.SetHeadline(path, v)
			continue
		}
		if key == "codeSpec" {
			v, err := decoderScalarOf(value, path+" (codeSpec)")
			if err != nil {
				return err
			}
			d.doc.SetCodeSpec(path, v)
			continue
		}
		return yamlFormatErr(
			"key `" + key + "` under `" + path + "` matches no member of " +
				node.DebugName() + " (expected one of: " +
				strings.Join(decoderExpectedKeys(node), ", ") + ")")
	}
	return nil
}

func decoderChildByKey(node *SomMetaNode, key string) *SomMetaNode {
	for _, c := range node.Children {
		if NodeKey(c) == key {
			return c
		}
	}
	return nil
}

func decoderExpectedKeys(node *SomMetaNode) []string {
	out := make([]string, 0, len(node.Children)+1)
	for _, c := range node.Children {
		out = append(out, "`"+NodeKey(c)+"`")
	}
	return append(out, "`content`", "`headline`", "`codeSpec`")
}

func (d *yamlDecoder) loadChild(
	child *SomMetaNode, path, key string, value interface{},
) error {
	switch child.Kind {
	case SomMetaKindContent, SomMetaKindScalar, SomMetaKindEnumValue:
		// A populated mapping is a headline-/codeSpec-extended scalar node (YRD3 +
		// codespecs_mapping.md §9.2): `{headline?: …, codeSpec?: …, content: …}`. An
		// empty mapping is the hand-rolled parser's spelling of a bare `key:` and
		// stays the empty scalar.
		if m, isMap := value.(*YamlMap); isMap && m.Len() > 0 {
			return d.loadScalarWithMeta(path, key, m)
		}
		v, err := decoderScalarOf(value, path)
		if err != nil {
			return err
		}
		d.doc.SetContent(path, v)
		return nil
	case SomMetaKindForm:
		fields, ok := value.(*YamlMap)
		if !ok {
			return yamlFormatErr(
				"form `" + key + "` at `" + path + "` must hold a field mapping")
		}
		meta := child.Form
		if meta == nil {
			meta = &SomFormMeta{}
		}
		for _, name := range fields.Keys() {
			field := meta.FieldNamed(name)
			if field == nil {
				if name == "headline" {
					v, err := decoderScalarOf(fields.GetOr(name), path+" (headline)")
					if err != nil {
						return err
					}
					d.doc.SetHeadline(path, v)
					continue
				}
				if name == "codeSpec" {
					v, err := decoderScalarOf(fields.GetOr(name), path+" (codeSpec)")
					if err != nil {
						return err
					}
					d.doc.SetCodeSpec(path, v)
					continue
				}
				return yamlFormatErr(
					"form `" + path + "` has no field `" + name + "` in the model")
			}
			v, err := decoderScalarOf(fields.GetOr(name), path+"."+name)
			if err != nil {
				return err
			}
			d.doc.SetFormField(path, name, v)
		}
		return nil
	case SomMetaKindSection, SomMetaKindComplex:
		if value == nil {
			return nil
		}
		mapping, ok := value.(*YamlMap)
		if !ok {
			return yamlFormatErr(
				"section `" + key + "` at `" + path + "` must hold a mapping, " +
					"not a scalar")
		}
		return d.loadMapping(child, path, mapping)
	case SomMetaKindList:
		if value == nil {
			return nil
		}
		items, ok := value.(*YamlMap)
		if !ok {
			return yamlFormatErr(
				"list `" + key + "` at `" + path + "` must hold an item mapping")
		}
		return d.loadList(child, path, items)
	}
	return nil
}

func (d *yamlDecoder) loadList(node *SomMetaNode, path string, items *YamlMap) error {
	anonymous := regexp.MustCompile(
		"^" + regexp.QuoteMeta(node.MemberName) + "-[0-9]+$")
	for _, key := range items.Keys() {
		value := items.GetOr(key)
		if key == "headline" {
			// The list container's own stored headline (YRD3), not an item.
			v, err := decoderScalarOf(value, path+" (headline)")
			if err != nil {
				return err
			}
			d.doc.SetHeadline(path, v)
			continue
		}
		if key == "codeSpec" {
			// The list container's own codeSpec mapping (codespecs_mapping.md §9.2), not
			// an item.
			v, err := decoderScalarOf(value, path+" (codeSpec)")
			if err != nil {
				return err
			}
			d.doc.SetCodeSpec(path, v)
			continue
		}
		var itemPath string
		if anonymous.MatchString(key) {
			itemPath = d.doc.AddListItem(path)
		} else {
			p, err := d.doc.AddListItemWithSectionID(path, key)
			if err != nil {
				return err
			}
			itemPath = p
		}
		element := node.ElementNode
		if element == nil {
			// Scalar list item: the value is the item itself — or a `{headline?: …,
			// codeSpec?: …, content: …}` mapping when it carries a stored headline
			// and/or codeSpec (YRD3 + codespecs_mapping.md §9.2). The hand-rolled parser
			// cannot distinguish a bare `key:` (null) from `key: {}`, so an empty
			// mapping counts as "no value" here (Python raises on an explicit `{}`).
			if seq, isSeq := value.([]interface{}); isSeq {
				_ = seq
				return yamlFormatErr(
					"scalar list item `" + key + "` at `" + path + "` must hold a scalar")
			}
			if m, isMap := value.(*YamlMap); isMap {
				if m.Len() > 0 {
					if err := d.loadScalarWithMeta(itemPath, key, m); err != nil {
						return err
					}
				}
				continue
			}
			if value != nil {
				d.doc.SetContent(itemPath, parsedScalarStr(value))
			}
			continue
		}
		if value == nil {
			continue
		}
		mapping, ok := value.(*YamlMap)
		if !ok {
			return yamlFormatErr(
				"list item `" + key + "` at `" + path + "` must hold a mapping " +
					"(use `{}` for an empty item)")
		}
		if err := d.loadMapping(element, itemPath, mapping); err != nil {
			return err
		}
	}
	return nil
}

// loadScalarWithMeta loads a headline-/codeSpec-extended scalar node (YRD3 +
// codespecs_mapping.md §9.2): a mapping holding only the literal keys
// `headline`, `codeSpec` and `content`.
func (d *yamlDecoder) loadScalarWithMeta(path, key string, value *YamlMap) error {
	for _, name := range value.Keys() {
		v := value.GetOr(name)
		switch name {
		case "headline":
			s, err := decoderScalarOf(v, path+" (headline)")
			if err != nil {
				return err
			}
			d.doc.SetHeadline(path, s)
		case "codeSpec":
			s, err := decoderScalarOf(v, path+" (codeSpec)")
			if err != nil {
				return err
			}
			d.doc.SetCodeSpec(path, s)
		case "content":
			s, err := decoderScalarOf(v, path+"/content")
			if err != nil {
				return err
			}
			d.doc.SetContent(path, s)
		default:
			return yamlFormatErr(
				"scalar node `" + key + "` at `" + path + "` may only hold " +
					"`headline`/`codeSpec`/`content` keys when written as a mapping, " +
					"found `" + name + "`")
		}
	}
	return nil
}

// decoderScalarOf coerces a parsed leaf value to the document's string store.
// The hand-rolled parser yields an empty mapping for a bare `key:` (where a
// real YAML parser yields null), so an *empty* mapping counts as the empty
// string; a populated mapping or a sequence is still a structural error.
func decoderScalarOf(value interface{}, where string) (string, error) {
	if value == nil {
		return "", nil
	}
	if _, isSeq := value.([]interface{}); isSeq {
		return "", yamlFormatErr("expected a scalar value at `" + where + "`")
	}
	if m, isMap := value.(*YamlMap); isMap {
		if m.Len() == 0 {
			return "", nil
		}
		return "", yamlFormatErr("expected a scalar value at `" + where + "`")
	}
	return parsedScalarStr(value), nil
}
