package somruntime

// yaml.go — a minimal, dependency-free YAML reader for the constrained
// `*.docspecs.yaml` subset the SpecDocumentYaml codec emits, a faithful port of
// `tom_som_dart_runtime/lib/src/yaml.dart` (and the TypeScript `yaml.ts`).
//
// The runtime ships with no external libraries, so this hand-rolled indentation
// parser stands in for package:yaml / PyYAML. It supports exactly what the
// encoder produces (and what the self-verify round-trip probe needs): block
// mappings, block sequences ("- item"), literal block scalars (|, |-, |2, |2- …),
// JSON-quoted flow scalars, plain integers, and the empty flow collections
// {} / [].
//
// The dynamic value model is interface{}: mappings are *YamlMap (insertion
// ordered — Go's native maps are unordered, but the hierarchical codec walks
// keys in document order, exactly like the JS/TS objects and Python dicts of
// the other ports), sequences are []interface{}, scalars are string or int.
// JSON-quoted scalars are parsed with encoding/json.

import (
	"encoding/json"
	"strings"
)

// YamlMap is an insertion-ordered string-keyed mapping — the Go analogue of a
// JavaScript object / Python dict for the parsed YAML value model. Iterating
// Keys() yields keys in first-insertion order (a later Set of an existing key
// replaces the value but keeps the original position), which is what makes the
// hierarchical decode walk deterministic and byte-compatible with the other
// language ports.
type YamlMap struct {
	keys   []string
	values map[string]interface{}
}

// NewYamlMap returns an empty ordered mapping.
func NewYamlMap() *YamlMap {
	return &YamlMap{values: map[string]interface{}{}}
}

// Set stores value under key, preserving the key's first-insertion position.
func (m *YamlMap) Set(key string, value interface{}) {
	if _, ok := m.values[key]; !ok {
		m.keys = append(m.keys, key)
	}
	m.values[key] = value
}

// Get returns the value stored under key, and ok=false when absent.
func (m *YamlMap) Get(key string) (interface{}, bool) {
	v, ok := m.values[key]
	return v, ok
}

// GetOr returns the value stored under key, or nil when absent.
func (m *YamlMap) GetOr(key string) interface{} {
	return m.values[key]
}

// Has reports whether key is present.
func (m *YamlMap) Has(key string) bool {
	_, ok := m.values[key]
	return ok
}

// Keys returns the keys in insertion order (the backing slice; callers must
// not mutate it).
func (m *YamlMap) Keys() []string {
	return m.keys
}

// Len returns the number of entries.
func (m *YamlMap) Len() int {
	return len(m.keys)
}

func yamlNewMap() *YamlMap {
	return NewYamlMap()
}

func yamlLeading(line string) int {
	n := 0
	for n < len(line) && line[n] == ' ' {
		n++
	}
	return n
}

func yamlIsInteger(s string) bool {
	if len(s) == 0 {
		return false
	}
	i := 0
	if s[0] == '-' || s[0] == '+' {
		i = 1
		if len(s) == 1 {
			return false
		}
	}
	for ; i < len(s); i++ {
		if s[i] < '0' || s[i] > '9' {
			return false
		}
	}
	return true
}

func yamlFindColon(content string) int {
	if strings.HasPrefix(content, "\"") {
		i := 1
		for i < len(content) {
			c := content[i]
			if c == '\\' {
				i += 2
				continue
			}
			if c == '"' {
				i++
				break
			}
			i++
		}
		idx := strings.Index(content[i:], ":")
		if idx < 0 {
			return -1
		}
		return i + idx
	}
	return strings.Index(content, ":")
}

func yamlParseScalarKey(keyPart string) string {
	if strings.HasPrefix(keyPart, "\"") {
		var v string
		if err := json.Unmarshal([]byte(keyPart), &v); err != nil {
			return ""
		}
		return v
	}
	return keyPart
}

type yamlReader struct {
	lines []string
	idx   int
}

func (y *yamlReader) nextSignificant(from int) int {
	for i := from; i < len(y.lines); i++ {
		t := strings.TrimSpace(y.lines[i])
		if t == "" || strings.HasPrefix(t, "#") {
			continue
		}
		return i
	}
	return -1
}

func (y *yamlReader) parseNode(minIndent int) interface{} {
	i := y.nextSignificant(y.idx)
	if i == -1 {
		return yamlNewMap()
	}
	line := y.lines[i]
	indent := yamlLeading(line)
	if indent < minIndent {
		return yamlNewMap()
	}
	content := line[indent:]
	if content == "-" || strings.HasPrefix(content, "- ") {
		return y.parseSequence(indent)
	}
	return y.parseMapping(indent)
}

func (y *yamlReader) parseMapping(indent int) interface{} {
	m := yamlNewMap()
	for {
		i := y.nextSignificant(y.idx)
		if i == -1 {
			break
		}
		line := y.lines[i]
		curIndent := yamlLeading(line)
		if curIndent != indent {
			break // dedent → belongs to the parent; over-indent shouldn't occur.
		}
		y.idx = i + 1
		content := line[indent:]
		colon := yamlFindColon(content)
		if colon < 0 {
			continue // not a mapping entry — tolerate and skip.
		}
		key := yamlParseScalarKey(strings.TrimSpace(content[:colon]))
		rest := strings.TrimSpace(content[colon+1:])
		var value interface{}
		if rest == "" {
			value = y.parseNestedAfterKey(indent)
		} else if strings.HasPrefix(rest, "|") || strings.HasPrefix(rest, ">") {
			value = y.parseBlockScalar(rest, indent)
		} else {
			value = y.parseFlowScalar(rest)
		}
		m.Set(key, value)
	}
	return m
}

func (y *yamlReader) parseSequence(indent int) interface{} {
	list := []interface{}{}
	for {
		i := y.nextSignificant(y.idx)
		if i == -1 {
			break
		}
		line := y.lines[i]
		curIndent := yamlLeading(line)
		if curIndent != indent {
			break
		}
		content := line[indent:]
		if content != "-" && !strings.HasPrefix(content, "- ") {
			break
		}
		y.idx = i + 1
		itemText := ""
		if content != "-" {
			itemText = strings.TrimSpace(content[2:])
		}
		if itemText == "" {
			list = append(list, y.parseNestedAfterKey(indent))
		} else if strings.HasPrefix(itemText, "|") || strings.HasPrefix(itemText, ">") {
			list = append(list, y.parseBlockScalar(itemText, indent))
		} else {
			list = append(list, y.parseFlowScalar(itemText))
		}
	}
	return list
}

func (y *yamlReader) parseNestedAfterKey(parentIndent int) interface{} {
	i := y.nextSignificant(y.idx)
	if i == -1 {
		return yamlNewMap()
	}
	childIndent := yamlLeading(y.lines[i])
	if childIndent <= parentIndent {
		return yamlNewMap()
	}
	return y.parseNode(childIndent)
}

func (y *yamlReader) parseFlowScalar(s string) interface{} {
	t := strings.TrimSpace(s)
	if t == "{}" {
		return yamlNewMap()
	}
	if t == "[]" {
		return []interface{}{}
	}
	if strings.HasPrefix(t, "\"") {
		var v string
		if err := json.Unmarshal([]byte(t), &v); err == nil {
			return v
		}
		return t
	}
	if yamlIsInteger(t) {
		return atoi(t)
	}
	return t
}

// parseBlockScalar parses a literal block scalar starting at header (e.g. "|2-")
// whose body lines follow. keyIndent is the indentation of the owning
// key/sequence line.
func (y *yamlReader) parseBlockScalar(header string, keyIndent int) string {
	p := 1 // skip the leading '|' (or '>').
	explicitIndent := -1
	digitsStart := p
	for p < len(header) && header[p] >= '0' && header[p] <= '9' {
		p++
	}
	if p > digitsStart {
		explicitIndent = atoi(header[digitsStart:p])
	}
	chomp := byte(' ')
	for p < len(header) {
		c := header[p]
		if c == '-' || c == '+' {
			chomp = c
		}
		p++
	}

	// Collect the raw body: blank lines plus any line indented past the key.
	var rawBody []string
	for y.idx < len(y.lines) {
		l := y.lines[y.idx]
		if strings.TrimSpace(l) == "" {
			rawBody = append(rawBody, "")
			y.idx++
			continue
		}
		if yamlLeading(l) <= keyIndent {
			break
		}
		rawBody = append(rawBody, l)
		y.idx++
	}
	// Drop trailing blank lines that actually belong to the following node.
	for len(rawBody) > 0 && rawBody[len(rawBody)-1] == "" {
		rawBody = rawBody[:len(rawBody)-1]
	}

	var contentIndent int
	if explicitIndent >= 0 {
		contentIndent = keyIndent + explicitIndent
	} else {
		contentIndent = int(^uint(0) >> 1) // max int
		for _, l := range rawBody {
			if l != "" {
				if ld := yamlLeading(l); ld < contentIndent {
					contentIndent = ld
				}
			}
		}
		if contentIndent == int(^uint(0)>>1) {
			contentIndent = keyIndent + 1
		}
	}

	var body []string
	for _, l := range rawBody {
		if l == "" {
			body = append(body, "")
		} else {
			strip := contentIndent
			if strip > len(l) {
				strip = len(l)
			}
			body = append(body, l[strip:])
		}
	}

	joined := strings.Join(body, "\n")
	if chomp == '-' {
		return strings.TrimRight(joined, "\n")
	}
	if chomp == '+' {
		return joined
	}
	// Clip (default): exactly one trailing newline when non-empty.
	clipped := strings.TrimRight(joined, "\n")
	if clipped == "" {
		return ""
	}
	return clipped + "\n"
}

// YamlParse parses text into the value model (a *YamlMap or []interface{}).
func YamlParse(text string) interface{} {
	lines := strings.Split(text, "\n")
	y := &yamlReader{lines: lines, idx: 0}
	first := y.nextSignificant(0)
	if first == -1 {
		return yamlNewMap()
	}
	return y.parseNode(0)
}

// YamlParseMap parses text, returning a mapping (empty when not a mapping).
func YamlParseMap(text string) *YamlMap {
	v := YamlParse(text)
	if m, ok := v.(*YamlMap); ok {
		return m
	}
	return yamlNewMap()
}
