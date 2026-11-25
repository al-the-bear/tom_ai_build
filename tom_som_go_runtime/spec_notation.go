package somruntime

// spec_notation.go — the reading notation's scanner: one call per text value,
// returning the value's fenced divs, bracketed spans and citation shapes with
// their kind, attributes, source ranges and nesting, and the findings the
// DocSpecs specification lists for the notation (*Reading Notation*, RN-1 …
// RN-13).
//
// The Go port of `tom_som_typescript_runtime`'s `spec_notation.ts` (itself the
// port of `tom_som_dart_runtime`'s `spec_notation.dart`): the same grammar, the
// same elements and findings, the same offsets; all run
// `tom_som_conformance/corpus/notation_cases.json`.
//
//   - a **fenced div** is a line of at least three colons, indented up to three
//     spaces, then attribute braces (`::: {.provenance}`) or a bare kind word
//     (`::: aside`); it closes at a line of at least three colons and nothing
//     else, and a closing fence closes the innermost open div;
//   - a **bracketed span** is `[text]` followed immediately by attribute
//     braces, inside one paragraph;
//   - a **citation shape** is `(-> ids)` (kind `trace`), `(<- source)` or
//     `(<~ source)` (kind `provenance`);
//   - fenced code and code spans are literal, and so are `\:::` and `]\{.`.
//
// An unknown kind passes through as an element like any other.
//
// **Offsets are UTF-16 code units**, as in every other runtime: a Go string is
// UTF-8, so the scanner works on code points (runes) and converts each offset
// it reports (Start, End, ContentStart, ContentEnd, Offset) to UTF-16 code
// units. Whitespace, trim and the regular expressions' `.` follow JavaScript,
// as the TypeScript scanner does. NotationElement.Source / Content slice the
// text by those UTF-16 offsets.

import (
	"fmt"
	"sort"
	"strings"
	"unicode/utf16"
)

// RegisteredNotationKinds are the kinds the notation registers (RN-5); any
// other kind passes through.
var RegisteredNotationKinds = []string{
	"provenance",
	"trace",
	"editorial",
	"aside",
	"linked",
	"derived",
	"refs",
	"records",
	"rejected",
}

// NotationFindingCode is one of the notation's findings (RN-10); its String()
// is the rule's name in the DocSpecs validator.
type NotationFindingCode int

// The notation's finding codes, in declaration order (the order findings at
// one offset are sorted by).
const (
	NotationUnclosedDiv NotationFindingCode = iota
	NotationStrayClosingFence
	NotationUnclosedSpan
	NotationDivWithoutKind
	NotationUnknownKind
	NotationMarkAcrossNotation
	NotationAnnotationInsideDiv
	NotationDivInsideAnnotation
	NotationRejectedBlock
)

// NotationFindingCodes is every code, in declaration order.
var NotationFindingCodes = []NotationFindingCode{
	NotationUnclosedDiv,
	NotationStrayClosingFence,
	NotationUnclosedSpan,
	NotationDivWithoutKind,
	NotationUnknownKind,
	NotationMarkAcrossNotation,
	NotationAnnotationInsideDiv,
	NotationDivInsideAnnotation,
	NotationRejectedBlock,
}

var notationFindingCodeNames = []string{
	"unclosedDiv",
	"strayClosingFence",
	"unclosedSpan",
	"divWithoutKind",
	"unknownKind",
	"markAcrossNotation",
	"annotationInsideDiv",
	"divInsideAnnotation",
	"rejectedBlock",
}

// String is the code's name (`unclosedDiv`, …), the DocSpecs validator's rule.
func (c NotationFindingCode) String() string {
	if c < 0 || int(c) >= len(notationFindingCodeNames) {
		return ""
	}
	return notationFindingCodeNames[c]
}

// NotationFindingCodeFromName answers the code named name; false for any other
// name.
func NotationFindingCodeFromName(name string) (NotationFindingCode, bool) {
	for i, n := range notationFindingCodeNames {
		if n == name {
			return NotationFindingCode(i), true
		}
	}
	return 0, false
}

// The two notation severities.
const (
	NotationSeverityError   = "error"
	NotationSeverityWarning = "warning"
)

// NotationSeverity is the severity of code: an unknown kind is a `warning`,
// the rest `error`s.
func NotationSeverity(code NotationFindingCode) string {
	if code == NotationUnknownKind {
		return NotationSeverityWarning
	}
	return NotationSeverityError
}

// utf16Slice is text between the UTF-16 offsets start and end.
func utf16Slice(text string, start, end int) string {
	units := utf16.Encode([]rune(text))
	if end > len(units) {
		end = len(units)
	}
	if start > end {
		start = end
	}
	return string(utf16.Decode(units[start:end]))
}

// NotationAttribute is one `key="value"` pair of an element's attributes.
type NotationAttribute struct {
	Key   string
	Value string
}

// The element types.
const (
	NotationTypeDiv      = "div"
	NotationTypeSpan     = "span"
	NotationTypeCitation = "citation"
)

// NotationElement is one element of the notation: a div, a span or a citation.
type NotationElement struct {
	// Type is `div`, `span` or `citation`.
	Type string
	// Kind is the first class; `trace` / `provenance` for a citation; "" without
	// a class.
	Kind string
	// Classes holds every class, the kind first.
	Classes []string
	// ID is the `#id` of the attributes (not a section id), "" without one.
	ID string
	// Attributes holds the `key="value"` pairs, in their order.
	Attributes []NotationAttribute
	// Shape is a citation's arrow: `->`, `<-` or `<~`; "" otherwise.
	Shape string
	// Start is the UTF-16 offset of the first character.
	Start int
	// End is the UTF-16 offset after the last character.
	End int
	// ContentStart is the UTF-16 offset of the content.
	ContentStart int
	// ContentEnd is the UTF-16 offset after the content.
	ContentEnd int
	// Line is the 1-based line of Start.
	Line int
	// EndLine is the 1-based line of the last character.
	EndLine int
	// Closed is false for a div without a closing fence.
	Closed bool
	// Children holds the elements nested in this one, in source order.
	Children []*NotationElement
}

// IsRegistered reports whether the kind is registered.
func (e *NotationElement) IsRegistered() bool {
	if e.Kind == "" {
		return false
	}
	for _, k := range RegisteredNotationKinds {
		if k == e.Kind {
			return true
		}
	}
	return false
}

// Attribute answers the value of the attribute key and whether it is set.
func (e *NotationElement) Attribute(key string) (string, bool) {
	for _, a := range e.Attributes {
		if a.Key == key {
			return a.Value, true
		}
	}
	return "", false
}

// Source is the element's text in text (the scanned value).
func (e *NotationElement) Source(text string) string {
	return utf16Slice(text, e.Start, e.End)
}

// Content is the element's content in text (the scanned value).
func (e *NotationElement) Content(text string) string {
	return utf16Slice(text, e.ContentStart, e.ContentEnd)
}

// ToJSON is the element as the conformance corpus writes it (a JSON-ready
// value; json.Marshal writes its keys sorted).
func (e *NotationElement) ToJSON(text string) map[string]interface{} {
	opt := func(s string) interface{} {
		if s == "" {
			return nil
		}
		return s
	}
	classes := make([]interface{}, 0, len(e.Classes))
	for _, c := range e.Classes {
		classes = append(classes, c)
	}
	attributes := map[string]interface{}{}
	for _, a := range e.Attributes {
		attributes[a.Key] = a.Value
	}
	children := make([]interface{}, 0, len(e.Children))
	for _, c := range e.Children {
		children = append(children, c.ToJSON(text))
	}
	return map[string]interface{}{
		"type":       e.Type,
		"kind":       opt(e.Kind),
		"classes":    classes,
		"id":         opt(e.ID),
		"attributes": attributes,
		"shape":      opt(e.Shape),
		"start":      e.Start,
		"end":        e.End,
		"line":       e.Line,
		"endLine":    e.EndLine,
		"closed":     e.Closed,
		"source":     e.Source(text),
		"content":    e.Content(text),
		"children":   children,
	}
}

// NotationFinding is one finding of the scan.
type NotationFinding struct {
	Code NotationFindingCode
	// Offset is the UTF-16 offset it stands at.
	Offset int
	// Line is its 1-based line.
	Line    int
	Message string
}

// Severity is the severity of the code.
func (f *NotationFinding) Severity() string {
	return NotationSeverity(f.Code)
}

// ToJSON is the finding as the conformance corpus writes it.
func (f *NotationFinding) ToJSON() map[string]interface{} {
	return map[string]interface{}{
		"code":     f.Code.String(),
		"severity": f.Severity(),
		"line":     f.Line,
	}
}

func (f *NotationFinding) String() string {
	return fmt.Sprintf("line %d: %s \u2014 %s", f.Line, f.Code, f.Message)
}

// NotationScan is the result of ScanNotation.
type NotationScan struct {
	Text string
	// Elements holds the elements not nested in another, in source order.
	Elements []*NotationElement
	// Findings holds the findings, by offset.
	Findings []*NotationFinding
}

// All answers every element, depth-first in source order.
func (s *NotationScan) All() []*NotationElement {
	var out []*NotationElement
	var walk func([]*NotationElement)
	walk = func(list []*NotationElement) {
		for _, e := range list {
			out = append(out, e)
			walk(e.Children)
		}
	}
	walk(s.Elements)
	return out
}

// HasErrors reports whether a finding of severity `error` is present.
func (s *NotationScan) HasErrors() bool {
	for _, f := range s.Findings {
		if f.Severity() == NotationSeverityError {
			return true
		}
	}
	return false
}

// ScanNotation scans one text value for the reading notation. tomSpecs says
// the value belongs to a TomSpecs rendition: only then are a div without a
// class and an unregistered kind reported (RN-10).
func ScanNotation(text string, tomSpecs bool) *NotationScan {
	return newNotationScanner(text, tomSpecs).scan()
}

// --- JavaScript character classes -------------------------------------------

// nsIsJSWs is JavaScript's whitespace (`\s`, `String.prototype.trim`).
func nsIsJSWs(c rune) bool {
	switch c {
	case '\t', '\n', '\u000B', '\u000C', '\r', ' ', '\u00A0', '\u1680',
		'\u2028', '\u2029', '\u202F', '\u205F', '\u3000', '\uFEFF':
		return true
	}
	return c >= '\u2000' && c <= '\u200A'
}

// nsIsLineTerminator is a JavaScript line terminator: what the regular
// expressions' `.` excludes.
func nsIsLineTerminator(c rune) bool {
	return c == '\n' || c == '\r' || c == '\u2028' || c == '\u2029'
}

func nsIsASCIIAlpha(c rune) bool {
	return (c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z')
}

func nsIsASCIIAlnum(c rune) bool {
	return nsIsASCIIAlpha(c) || (c >= '0' && c <= '9')
}

func nsTrim(s []rune) []rune {
	start, end := 0, len(s)
	for start < end && nsIsJSWs(s[start]) {
		start++
	}
	for end > start && nsIsJSWs(s[end-1]) {
		end--
	}
	return s[start:end]
}

func nsTrimLeft(s []rune) []rune {
	start := 0
	for start < len(s) && nsIsJSWs(s[start]) {
		start++
	}
	return s[start:]
}

func nsStartsWithAt(text []rune, at int, pat string) bool {
	p := []rune(pat)
	if at < 0 || at+len(p) > len(text) {
		return false
	}
	for i, c := range p {
		if text[at+i] != c {
			return false
		}
	}
	return true
}

// nsFindFrom is the first index >= from where pat stands in text, -1 when
// none.
func nsFindFrom(text []rune, from int, pat string) int {
	n := len([]rune(pat))
	for i := from; i+n <= len(text); i++ {
		if nsStartsWithAt(text, i, pat) {
			return i
		}
	}
	return -1
}

func nsContainsRune(s []rune, c rune) bool {
	for _, x := range s {
		if x == c {
			return true
		}
	}
	return false
}

const nsASCIIPunctuation = "!\"#$%&'()*+,-./:;<=>?@[\\]^_`{|}~"

var nsMarkOpeners = []string{"{++", "{--", "{~~", "{==", "{>>"}

func nsMarkCloser(opener string) string {
	switch opener {
	case "{++":
		return "++}"
	case "{--":
		return "--}"
	case "{~~":
		return "~~}"
	case "{==":
		return "==}"
	}
	return "<<}"
}

func nsMarkOpenerAt(text []rune, at int) string {
	for _, o := range nsMarkOpeners {
		if nsStartsWithAt(text, at, o) {
			return o
		}
	}
	return ""
}

// nsCitationKind answers the arrow and the kind of a citation's two arrow
// characters.
func nsCitationKind(a, b rune) (string, string, bool) {
	switch {
	case a == '-' && b == '>':
		return "->", "trace", true
	case a == '<' && b == '-':
		return "<-", "provenance", true
	case a == '<' && b == '~':
		return "<~", "provenance", true
	}
	return "", "", false
}

// --- The line grammar (the TypeScript scanner's regular expressions) --------

// nsIndentEnd is ` {0,3}`: the index after up to three leading spaces, or -1
// when a fourth space follows.
func nsIndentEnd(line []rune) int {
	i := 0
	for i < len(line) && line[i] == ' ' {
		i++
		if i > 3 {
			return -1
		}
	}
	return i
}

// nsDivOpen is a div's fence opening: attribute braces (inner) or a bare kind
// (word).
type nsDivOpen struct {
	braces bool
	inner  string
	word   string
}

// nsDivOpenFrom is the fence opening of a div from at on
// (`:{3,}[ \t]*(?:\{(.*)\}|(word))[ \t]*$`).
func nsDivOpenFrom(line []rune, at int) *nsDivOpen {
	i := at
	for i < len(line) && line[i] == ':' {
		i++
	}
	if i-at < 3 {
		return nil
	}
	for i < len(line) && (line[i] == ' ' || line[i] == '\t') {
		i++
	}
	end := len(line)
	for end > i && (line[end-1] == ' ' || line[end-1] == '\t') {
		end--
	}
	if i >= end {
		return nil
	}
	if line[i] == '{' {
		if end-i < 2 || line[end-1] != '}' {
			return nil
		}
		inner := line[i+1 : end-1]
		for _, c := range inner {
			if nsIsLineTerminator(c) {
				return nil
			}
		}
		return &nsDivOpen{braces: true, inner: string(inner)}
	}
	if !nsIsASCIIAlpha(line[i]) {
		return nil
	}
	word := line[i:end]
	for _, c := range word {
		if !(nsIsASCIIAlnum(c) || c == '_' || c == '-') {
			return nil
		}
	}
	return &nsDivOpen{word: string(word)}
}

// nsMatchDivOpen is
// `^ {0,3}:{3,}[ \t]*(?:\{(.*)\}|([A-Za-z][A-Za-z0-9_-]*))[ \t]*$`.
func nsMatchDivOpen(line []rune) *nsDivOpen {
	at := nsIndentEnd(line)
	if at < 0 {
		return nil
	}
	return nsDivOpenFrom(line, at)
}

// nsMatchDivClose is `^ {0,3}:{3,}[ \t]*$`.
func nsMatchDivClose(line []rune) bool {
	i := nsIndentEnd(line)
	if i < 0 {
		return false
	}
	at := i
	for i < len(line) && line[i] == ':' {
		i++
	}
	if i-at < 3 {
		return false
	}
	for _, c := range line[i:] {
		if c != ' ' && c != '\t' {
			return false
		}
	}
	return true
}

// nsMatchCodeFenceOpen is `^ {0,3}(`{3,}|~{3,})(.*)$`: the fence run and the
// rest of the line.
func nsMatchCodeFenceOpen(line []rune) ([]rune, []rune, bool) {
	at := nsIndentEnd(line)
	if at < 0 || at >= len(line) {
		return nil, nil, false
	}
	c := line[at]
	if c != '`' && c != '~' {
		return nil, nil, false
	}
	i := at
	for i < len(line) && line[i] == c {
		i++
	}
	if i-at < 3 {
		return nil, nil, false
	}
	rest := line[i:]
	for _, r := range rest {
		if nsIsLineTerminator(r) {
			return nil, nil, false
		}
	}
	return line[at:i], rest, true
}

// nsMatchQuoteLine is `^ {0,3}>`.
func nsMatchQuoteLine(line []rune) bool {
	i := nsIndentEnd(line)
	return i >= 0 && i < len(line) && line[i] == '>'
}

// nsMatchAnnotationStart is `^ {0,3}> ?(?:⬆|\*\*❓|⚖)`.
func nsMatchAnnotationStart(line []rune) bool {
	i := nsIndentEnd(line)
	if i < 0 || i >= len(line) || line[i] != '>' {
		return false
	}
	i++
	if i < len(line) && line[i] == ' ' {
		i++
	}
	if i >= len(line) {
		return false
	}
	switch line[i] {
	case '\u2B06', '\u2696':
		return true
	case '*':
		return nsStartsWithAt(line, i, "**\u2753")
	}
	return false
}

// nsMatchQuotedDivOpen is
// `^ {0,3}>[ \t]?( {0,3}:{3,}[ \t]*(?:\{.*\}|[A-Za-z][A-Za-z0-9_-]*)[ \t]*)$`.
func nsMatchQuotedDivOpen(line []rune) bool {
	i := nsIndentEnd(line)
	if i < 0 || i >= len(line) || line[i] != '>' {
		return false
	}
	i++
	if i < len(line) && (line[i] == ' ' || line[i] == '\t') {
		i++
	}
	rest := line[i:]
	j := nsIndentEnd(rest)
	return j >= 0 && nsDivOpenFrom(rest, j) != nil
}

// --- Attributes -------------------------------------------------------------

type nsAttributes struct {
	classes []string
	id      string
	pairs   []NotationAttribute
}

// nsAttributeWordEnd is `[^\s.#}="']+` from at: the index after the run (at
// when empty).
func nsAttributeWordEnd(s []rune, at int) int {
	i := at
	for i < len(s) {
		c := s[i]
		if nsIsJSWs(c) || c == '.' || c == '#' || c == '}' || c == '=' || c == '"' || c == '\'' {
			break
		}
		i++
	}
	return i
}

// nsAttributePairAt is
// `([A-Za-z_][A-Za-z0-9_:.-]*)=("[^"]*"|'[^']*'|[^\s}]+)` at at: the key, the
// raw value and the index after the match.
func nsAttributePairAt(s []rune, at int) (string, string, int, bool) {
	if at >= len(s) {
		return "", "", 0, false
	}
	c := s[at]
	if !(nsIsASCIIAlpha(c) || c == '_') {
		return "", "", 0, false
	}
	i := at + 1
	for i < len(s) && (nsIsASCIIAlnum(s[i]) || s[i] == '_' || s[i] == ':' || s[i] == '.' || s[i] == '-') {
		i++
	}
	if i >= len(s) || s[i] != '=' {
		return "", "", 0, false
	}
	key := string(s[at:i])
	v := i + 1
	if v < len(s) && (s[v] == '"' || s[v] == '\'') {
		q := s[v]
		for k := v + 1; k < len(s); k++ {
			if s[k] == q {
				return key, string(s[v : k+1]), k + 1, true
			}
		}
	}
	j := v
	for j < len(s) && !nsIsJSWs(s[j]) && s[j] != '}' {
		j++
	}
	if j == v {
		return "", "", 0, false
	}
	return key, string(s[v:j]), j, true
}

func nsParseAttributes(inner []rune) nsAttributes {
	var a nsAttributes
	haveID := false
	i := 0
	for i < len(inner) {
		c := inner[i]
		if c == '.' || c == '#' {
			end := nsAttributeWordEnd(inner, i+1)
			if end > i+1 {
				word := string(inner[i+1 : end])
				if c == '.' {
					a.classes = append(a.classes, word)
				} else if !haveID {
					a.id = word
					haveID = true
				}
				i = end
				continue
			}
		}
		if key, raw, end, ok := nsAttributePairAt(inner, i); ok {
			r := []rune(raw)
			value := raw
			if len(r) >= 2 && ((r[0] == '"' && r[len(r)-1] == '"') ||
				(r[0] == '\'' && r[len(r)-1] == '\'')) {
				value = string(r[1 : len(r)-1])
			}
			set := false
			for k := range a.pairs {
				if a.pairs[k].Key == key {
					a.pairs[k].Value = value
					set = true
					break
				}
			}
			if !set {
				a.pairs = append(a.pairs, NotationAttribute{Key: key, Value: value})
			}
			i = end
			continue
		}
		i++
	}
	return a
}

// --- The scanner ------------------------------------------------------------

type nsOpenDiv struct {
	start        int
	contentStart int
	line         int
	attributes   nsAttributes
}

// nsFound is an element found, with the code-point offset of its start (the
// kind findings stand there).
type nsFound struct {
	element *NotationElement
	cpStart int
}

type nsSpanRange struct {
	start, end int
	typ        string
}

// notationScanner works on code-point offsets; every offset it reports is
// converted to UTF-16 code units.
type notationScanner struct {
	text       []rune
	tomSpecs   bool
	lineStarts []int
	lines      [][2]int
	elements   []nsFound
	findings   []*NotationFinding
	// u16 is the UTF-16 offset of every code-point offset 0 … len(text).
	u16 []int
}

func nsTypeIndex(t string) int {
	switch t {
	case NotationTypeSpan:
		return 1
	case NotationTypeCitation:
		return 2
	}
	return 0
}

func newNotationScanner(text string, tomSpecs bool) *notationScanner {
	chars := []rune(text)
	u16 := make([]int, 0, len(chars)+1)
	unit := 0
	for _, c := range chars {
		u16 = append(u16, unit)
		if c >= 0x10000 && c <= 0x10FFFF {
			unit += 2
		} else {
			unit++
		}
	}
	u16 = append(u16, unit)
	var lineStarts []int
	var lines [][2]int
	start := 0
	for i, c := range chars {
		if c == '\n' {
			lineStarts = append(lineStarts, start)
			lines = append(lines, [2]int{start, i})
			start = i + 1
		}
	}
	lineStarts = append(lineStarts, start)
	lines = append(lines, [2]int{start, len(chars)})
	return &notationScanner{
		text:       chars,
		tomSpecs:   tomSpecs,
		lineStarts: lineStarts,
		lines:      lines,
		u16:        u16,
	}
}

func (s *notationScanner) lineOf(offset int) int {
	lo, hi := 0, len(s.lineStarts)-1
	for lo < hi {
		mid := (lo + hi + 1) >> 1
		if s.lineStarts[mid] <= offset {
			lo = mid
		} else {
			hi = mid - 1
		}
	}
	return lo + 1
}

func (s *notationScanner) find(code NotationFindingCode, offset int, message string) {
	s.findings = append(s.findings, &NotationFinding{
		Code:    code,
		Offset:  s.u16[offset],
		Line:    s.lineOf(offset),
		Message: message,
	})
}

func (s *notationScanner) pushElement(
	typ string, a nsAttributes, shape string,
	start, end, contentStart, contentEnd, line, endLine int, closed bool,
) {
	kind := ""
	if len(a.classes) > 0 {
		kind = a.classes[0]
	}
	classes := a.classes
	if classes == nil {
		classes = []string{}
	}
	s.elements = append(s.elements, nsFound{
		element: &NotationElement{
			Type:         typ,
			Kind:         kind,
			Classes:      classes,
			ID:           a.id,
			Attributes:   a.pairs,
			Shape:        shape,
			Start:        s.u16[start],
			End:          s.u16[end],
			ContentStart: s.u16[contentStart],
			ContentEnd:   s.u16[contentEnd],
			Line:         line,
			EndLine:      endLine,
			Closed:       closed,
		},
		cpStart: start,
	})
}

func (s *notationScanner) scan() *NotationScan {
	s.blocks()
	s.kindFindings()
	ordered := make([]*NotationElement, 0, len(s.elements))
	for _, f := range s.elements {
		ordered = append(ordered, f.element)
	}
	sort.SliceStable(ordered, func(i, j int) bool {
		a, b := ordered[i], ordered[j]
		if a.Start != b.Start {
			return a.Start < b.Start
		}
		if a.End != b.End {
			return a.End > b.End
		}
		return nsTypeIndex(a.Type) < nsTypeIndex(b.Type)
	})
	// Nest by containment: a stack of open ancestors, folded into their
	// parents as they close.
	var roots, stack []*NotationElement
	popInto := func() {
		done := stack[len(stack)-1]
		stack = stack[:len(stack)-1]
		if len(stack) > 0 {
			parent := stack[len(stack)-1]
			parent.Children = append(parent.Children, done)
		} else {
			roots = append(roots, done)
		}
	}
	for _, e := range ordered {
		for len(stack) > 0 {
			top := stack[len(stack)-1]
			if e.Start >= top.Start && e.End <= top.End {
				break
			}
			popInto()
		}
		stack = append(stack, e)
	}
	for len(stack) > 0 {
		popInto()
	}
	findings := s.findings
	sort.SliceStable(findings, func(i, j int) bool {
		a, b := findings[i], findings[j]
		if a.Offset != b.Offset {
			return a.Offset < b.Offset
		}
		return a.Code < b.Code
	})
	return &NotationScan{Text: string(s.text), Elements: roots, Findings: findings}
}

// --- Blocks -----------------------------------------------------------------

func (s *notationScanner) blocks() {
	total := len(s.text)
	var openDivs []nsOpenDiv
	var codeFence []rune
	inAnnotation := false
	regionStart := -1
	regionEnd := 0
	flush := func() {
		if regionStart >= 0 {
			s.inline(regionStart, regionEnd)
			regionStart = -1
		}
	}

	for i := range s.lines {
		start, lineEnd := s.lines[i][0], s.lines[i][1]
		line := s.text[start:lineEnd]
		next := total
		if i+1 < len(s.lines) {
			next = s.lineStarts[i+1]
		}

		if codeFence != nil {
			t := nsTrimLeft(line)
			if len(line)-len(t) <= 3 && len(t) >= len(codeFence) &&
				string(t[:len(codeFence)]) == string(codeFence) {
				var rest []rune
				for _, c := range t[len(codeFence):] {
					if c != codeFence[0] {
						rest = append(rest, c)
					}
				}
				if len(nsTrim(rest)) == 0 {
					codeFence = nil
				}
			}
			continue
		}

		if nsMatchAnnotationStart(line) {
			if !inAnnotation && len(openDivs) > 0 {
				s.find(NotationAnnotationInsideDiv, start,
					"a comment or question block stands inside a div")
			}
			inAnnotation = true
		} else if !nsMatchQuoteLine(line) {
			inAnnotation = false
		}
		if inAnnotation {
			if nsMatchQuotedDivOpen(line) {
				s.find(NotationDivInsideAnnotation, start,
					"a div stands inside a comment or question block")
			}
			if regionStart < 0 {
				regionStart = start
			}
			regionEnd = lineEnd
			continue
		}

		if run, rest, ok := nsMatchCodeFenceOpen(line); ok {
			if !(run[0] == '`' && nsContainsRune(rest, '`')) {
				flush()
				codeFence = append([]rune(nil), run...)
				continue
			}
		}

		if open := nsMatchDivOpen(line); open != nil {
			flush()
			var a nsAttributes
			if open.braces {
				a = nsParseAttributes([]rune(open.inner))
			} else {
				a = nsAttributes{classes: []string{open.word}}
			}
			openDivs = append(openDivs, nsOpenDiv{
				start: start, contentStart: next, line: i + 1, attributes: a,
			})
			continue
		}

		if nsMatchDivClose(line) {
			flush()
			if len(openDivs) == 0 {
				s.find(NotationStrayClosingFence, start, "a closing fence has no open div")
			} else {
				d := openDivs[len(openDivs)-1]
				openDivs = openDivs[:len(openDivs)-1]
				s.addDiv(d, lineEnd, start, true)
			}
			continue
		}

		if len(nsTrim(line)) == 0 {
			flush()
			continue
		}
		if regionStart < 0 {
			regionStart = start
		}
		regionEnd = lineEnd
	}
	flush()
	for len(openDivs) > 0 {
		d := openDivs[len(openDivs)-1]
		openDivs = openDivs[:len(openDivs)-1]
		s.find(NotationUnclosedDiv, d.start, "an opening fence has no closing fence")
		s.addDiv(d, total, total, false)
	}
}

func (s *notationScanner) addDiv(d nsOpenDiv, end, contentEnd int, closed bool) {
	contentStart := d.contentStart
	if contentStart > contentEnd {
		contentStart = contentEnd
	}
	last := d.start
	if end > d.start {
		last = end - 1
	}
	s.pushElement(NotationTypeDiv, d.attributes, "", d.start, end,
		contentStart, contentEnd, d.line, s.lineOf(last), closed)
}

// --- Inline -----------------------------------------------------------------

func (s *notationScanner) inline(start, end int) {
	literal := map[int]int{}
	escaped := map[int]bool{}
	i := start
	for i < end {
		c := s.text[i]
		if c == '\\' && i+1 < end && strings.ContainsRune(nsASCIIPunctuation, s.text[i+1]) {
			escaped[i+1] = true
			i += 2
			continue
		}
		if c == '`' {
			n := 0
			for i+n < end && s.text[i+n] == '`' {
				n++
			}
			if close := s.closingBackticks(i+n, end, n); close >= 0 {
				literal[i] = close + n
				i = close + n
			} else {
				i += n
			}
			continue
		}
		i++
	}

	// Every span and citation, in code points.
	var spans []nsSpanRange
	var marks [][2]int
	var brackets []int
	i = start
	for i < end {
		if skip, ok := literal[i]; ok {
			i = skip
			continue
		}
		c := s.text[i]
		if escaped[i] || (c == '\\' && escaped[i+1]) {
			i++
			continue
		}
		if c == '{' {
			if opener := nsMarkOpenerAt(s.text, i); opener != "" {
				closer := nsMarkCloser(opener)
				if close := nsFindFrom(s.text, i+3, closer); close >= 0 {
					if close+len(closer) <= end {
						marks = append(marks, [2]int{i, close + len(closer)})
					}
				}
				i += 3
				continue
			}
		}
		if c == '[' {
			brackets = append(brackets, i)
		} else if c == ']' && len(brackets) > 0 {
			openAt := brackets[len(brackets)-1]
			brackets = brackets[:len(brackets)-1]
			if i+1 < end && s.text[i+1] == '{' && !escaped[i+1] &&
				nsMarkOpenerAt(s.text, i+1) == "" {
				close := s.closingBrace(i+2, end)
				if close < 0 {
					s.find(NotationUnclosedSpan, i+1,
						"a span's attribute braces do not close on the paragraph")
				} else {
					a := nsParseAttributes(s.text[i+2 : close])
					s.pushElement(NotationTypeSpan, a, "", openAt, close+1,
						openAt+1, i, s.lineOf(openAt), s.lineOf(close), true)
					spans = append(spans, nsSpanRange{openAt, close + 1, NotationTypeSpan})
					i = close + 1
					continue
				}
			}
		} else if c == '(' && i+3 < end && s.text[i+3] == ' ' {
			if arrow, kind, ok := nsCitationKind(s.text[i+1], s.text[i+2]); ok {
				if close := s.closingParenthesis(i+4, end, literal); close >= 0 {
					if close > i+4 && len(nsTrim(s.text[i+4:close])) > 0 {
						s.pushElement(NotationTypeCitation,
							nsAttributes{classes: []string{kind}}, arrow,
							i, close+1, i+4, close, s.lineOf(i), s.lineOf(close), true)
						spans = append(spans, nsSpanRange{i, close + 1, NotationTypeCitation})
						i += 4
						continue
					}
				}
			}
		}
		i++
	}

	for _, m := range marks {
		ms, me := m[0], m[1]
		for _, e := range spans {
			if (ms < e.start && e.start < me && me < e.end) ||
				(e.start < ms && ms < e.end && e.end < me) {
				s.find(NotationMarkAcrossNotation, ms,
					"an inline review mark crosses the boundary of a "+e.typ)
				break
			}
		}
	}
}

func (s *notationScanner) closingBackticks(from, end, n int) int {
	i := from
	for i < end {
		if s.text[i] == '`' {
			m := 0
			for i+m < end && s.text[i+m] == '`' {
				m++
			}
			if m == n {
				return i
			}
			i += m
		} else {
			i++
		}
	}
	return -1
}

func (s *notationScanner) closingBrace(from, end int) int {
	var quote rune
	for i := from; i < end; i++ {
		c := s.text[i]
		switch {
		case quote != 0:
			if c == quote {
				quote = 0
			}
		case c == '"' || c == '\'':
			quote = c
		case c == '}':
			return i
		case c == '{':
			return -1
		}
	}
	return -1
}

func (s *notationScanner) closingParenthesis(from, end int, literal map[int]int) int {
	depth := 0
	i := from
	for i < end {
		if skip, ok := literal[i]; ok {
			i = skip
			continue
		}
		switch s.text[i] {
		case '(':
			depth++
		case ')':
			if depth == 0 {
				return i
			}
			depth--
		}
		i++
	}
	return -1
}

// --- Kinds ------------------------------------------------------------------

func (s *notationScanner) kindFindings() {
	type pending struct {
		code    NotationFindingCode
		offset  int
		message string
	}
	var found []pending
	for _, f := range s.elements {
		e := f.element
		if e.Type == NotationTypeCitation {
			continue
		}
		if e.Type == NotationTypeDiv && e.Kind == "rejected" {
			found = append(found, pending{NotationRejectedBlock, f.cpStart,
				"a rejected block waits for its resolution"})
		}
		if !s.tomSpecs {
			continue
		}
		if e.Kind == "" {
			if e.Type == NotationTypeDiv {
				found = append(found, pending{NotationDivWithoutKind, f.cpStart,
					"a div's attributes hold no class"})
			}
		} else if !e.IsRegistered() {
			found = append(found, pending{NotationUnknownKind, f.cpStart,
				"the kind \"" + e.Kind + "\" is not registered"})
		}
	}
	for _, p := range found {
		s.find(p.code, p.offset, p.message)
	}
}
