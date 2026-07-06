package somruntime

// spec_document_yaml.go — generic YAML codec for the native `*.docspecs.yaml`
// document format, a faithful port of
// `tom_som_dart_runtime/lib/src/spec_document_yaml.dart` (and the TypeScript
// `spec_document_yaml.ts`).
//
// A header comment, `version:` (the on-disk format version), an optional
// `modelVersion:` stamp (the authoring object-model major.minor), then the
// `document:` pass — the live object-model values, sorted by full section path.
//
// All text values are written as literal block scalars (|2-) so multi-line
// content round-trips verbatim. The emitter is self-verifying: it re-parses each
// block it produces (via the hand-rolled yaml reader) and falls back to a
// JSON-quoted scalar (always valid YAML) for any value a clean block can't
// represent. The JSON quoting is byte-for-byte identical to JavaScript's
// JSON.stringify (see jsJSONString) so output is stable across every language
// port — NOT Go's encoding/json, which HTML-escapes < > & and U+2028/U+2029.

import (
	"sort"
	"strings"
)

// FormatVersion is the on-disk format version (independent of the model-version
// stamp).
const FormatVersion = 1

// SpecYamlContents is the decoded passes of a `*.docspecs.yaml` file: the
// `document:` pass as a SpecDocument.LoadJSON-shaped value, the `review:` pass as
// a raw map (the runtime is review-agnostic), and the optional authoring
// model-version stamp.
type SpecYamlContents struct {
	Document     *DocumentJson
	Review       map[string]interface{}
	ModelVersion string
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

// roundTrips reports whether re-parsing "_v: <block>" yields exactly value.
func roundTrips(block, value string) bool {
	parsed := YamlParse("_v: " + block + "\n")
	m, ok := parsed.(map[string]interface{})
	if !ok {
		return false
	}
	v, ok := m["_v"].(string)
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

type yamlBuffer struct {
	parts []string
}

func (b *yamlBuffer) writeln(text string) {
	b.parts = append(b.parts, text, "\n")
}

func (b *yamlBuffer) String() string {
	return strings.Join(b.parts, "")
}

// writeScalar writes "<indent><key>: <scalar>" where the scalar is a
// self-verified block scalar (or a JSON-quoted fallback). Body lines, emitted at
// a relative indent of 2, are re-indented to keyIndent + 2.
func writeScalar(b *yamlBuffer, keyIndent int, key, value string) {
	pad := strings.Repeat(" ", keyIndent)
	repr := scalarRepr(value)
	lines := strings.Split(repr, "\n")
	b.writeln(pad + yamlKey(key) + ": " + lines[0])
	for i := 1; i < len(lines); i++ {
		if lines[i] == "" {
			b.writeln("")
		} else {
			b.writeln(pad + lines[i])
		}
	}
}

func sortedKeys(m map[string]string) []string {
	out := make([]string, 0, len(m))
	for k := range m {
		out = append(out, k)
	}
	sort.Strings(out)
	return out
}

func sortedFormKeys(m map[string]map[string]string) []string {
	out := make([]string, 0, len(m))
	for k := range m {
		out = append(out, k)
	}
	sort.Strings(out)
	return out
}

func sortedListKeys(m map[string]ListJson) []string {
	out := make([]string, 0, len(m))
	for k := range m {
		out = append(out, k)
	}
	sort.Strings(out)
	return out
}

func writeHeader(b *yamlBuffer, modelVersion string) {
	b.writeln("# TomSpecs document (*.docspecs.yaml).")
	b.writeln("# `document:` holds the object-model values, sorted by section id; text")
	b.writeln("# values use block scalars so multi-line content round-trips verbatim (\u00A715.1).")
	b.writeln("version: " + itoa(FormatVersion))
	if modelVersion != "" {
		b.writeln("modelVersion: " + jsJSONString(modelVersion))
	}
}

// orderContentKeys / orderFormKeys / orderListKeys order the map keys of the
// document passes: by SerializationOrder when order != nil (AA1 criterion 7),
// else alphabetically (the diff-stable default the editor relies on).
func orderContentKeys(m map[string]string, order *SpecSerializationOrder) []string {
	if order == nil {
		return sortedKeys(m)
	}
	return order.OrderPaths(mapKeys(m))
}

func mapKeys(m map[string]string) []string {
	out := make([]string, 0, len(m))
	for k := range m {
		out = append(out, k)
	}
	return out
}

func writeDocumentPass(b *yamlBuffer, doc *DocumentJson, order *SpecSerializationOrder) {
	if len(doc.Content) == 0 && len(doc.Forms) == 0 && len(doc.Lists) == 0 {
		b.writeln("document: {}")
		return
	}
	b.writeln("document:")

	if len(doc.Content) > 0 {
		b.writeln("  content:")
		for _, k := range orderContentKeys(doc.Content, order) {
			writeScalar(b, 4, k, doc.Content[k])
		}
	}

	if len(doc.Forms) > 0 {
		b.writeln("  forms:")
		formKeys := sortedFormKeys(doc.Forms)
		if order != nil {
			keys := make([]string, 0, len(doc.Forms))
			for k := range doc.Forms {
				keys = append(keys, k)
			}
			formKeys = order.OrderPaths(keys)
		}
		for _, k := range formKeys {
			fields := doc.Forms[k]
			if len(fields) == 0 {
				continue
			}
			b.writeln("    " + yamlKey(k) + ":")
			fieldKeys := sortedKeys(fields)
			if order != nil {
				fieldKeys = order.OrderFormFields(k, mapKeys(fields))
			}
			for _, f := range fieldKeys {
				writeScalar(b, 6, f, fields[f])
			}
		}
	}

	if len(doc.Lists) > 0 {
		b.writeln("  lists:")
		listKeys := sortedListKeys(doc.Lists)
		if order != nil {
			keys := make([]string, 0, len(doc.Lists))
			for k := range doc.Lists {
				keys = append(keys, k)
			}
			listKeys = order.OrderPaths(keys)
		}
		for _, k := range listKeys {
			spec := doc.Lists[k]
			b.writeln("    " + yamlKey(k) + ":")
			b.writeln("      seq: " + itoa(spec.Seq))
			if len(spec.Items) > 0 {
				b.writeln("      items:")
				for _, it := range spec.Items {
					b.writeln("        - " + yamlKey(it))
				}
			} else {
				b.writeln("      items: []")
			}
		}
	}
}

// EncodeYaml serializes document to a header + `version:` (+ `modelVersion:`) +
// `document:` pass, with alphabetical member ordering (the diff-stable default).
func EncodeYaml(document *SpecDocument, modelVersion string) string {
	return EncodeYamlOrdered(document, modelVersion, nil)
}

// EncodeYamlOrdered is EncodeYaml with an optional SpecSerializationOrder: when
// non-nil, each class's members are emitted in @SerializationOrder order (AA1
// criterion 7) instead of alphabetically.
func EncodeYamlOrdered(document *SpecDocument, modelVersion string, order *SpecSerializationOrder) string {
	b := &yamlBuffer{}
	writeHeader(b, modelVersion)
	writeDocumentPass(b, document.ToJSON(), order)
	return b.String()
}

// DecodeYaml parses a `*.docspecs.yaml` document into its passes. A missing pass
// decodes as empty rather than failing, so a partial/hand-written file still
// loads what it has.
func DecodeYaml(yamlText string) *SpecYamlContents {
	var root interface{}
	if strings.TrimSpace(yamlText) != "" {
		root = YamlParse(yamlText)
	}
	rootMap, _ := root.(map[string]interface{})

	doc := docJSONFromYaml(rootMap["document"])
	rev, _ := rootMap["review"].(map[string]interface{})
	if rev == nil {
		rev = map[string]interface{}{}
	}
	stamp := ""
	if s, ok := rootMap["modelVersion"].(string); ok && s != "" {
		stamp = s
	}
	return &SpecYamlContents{Document: doc, Review: rev, ModelVersion: stamp}
}

// docJSONFromYaml converts the parsed `document:` mapping into a DocumentJson.
func docJSONFromYaml(v interface{}) *DocumentJson {
	out := &DocumentJson{}
	m, ok := v.(map[string]interface{})
	if !ok {
		return out
	}
	if content, ok := m["content"].(map[string]interface{}); ok && len(content) > 0 {
		out.Content = map[string]string{}
		for k, val := range content {
			out.Content[k] = yamlScalarString(val)
		}
	}
	if forms, ok := m["forms"].(map[string]interface{}); ok && len(forms) > 0 {
		out.Forms = map[string]map[string]string{}
		for k, val := range forms {
			fields, ok := val.(map[string]interface{})
			if !ok {
				continue
			}
			entry := map[string]string{}
			for f, fv := range fields {
				entry[f] = yamlScalarString(fv)
			}
			out.Forms[k] = entry
		}
	}
	if lists, ok := m["lists"].(map[string]interface{}); ok && len(lists) > 0 {
		out.Lists = map[string]ListJson{}
		for k, val := range lists {
			spec, ok := val.(map[string]interface{})
			if !ok {
				continue
			}
			seq := 0
			if s, ok := spec["seq"].(int); ok {
				seq = s
			}
			var items []string
			if rawItems, ok := spec["items"].([]interface{}); ok {
				for _, it := range rawItems {
					items = append(items, yamlScalarString(it))
				}
			}
			out.Lists[k] = ListJson{Seq: seq, Items: items}
		}
	}
	return out
}

func yamlScalarString(v interface{}) string {
	switch t := v.(type) {
	case string:
		return t
	case int:
		return itoa(t)
	default:
		return ""
	}
}
