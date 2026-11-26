package somruntime

// docspecs_validator.go — DocSpecs markdown validation, a faithful port of
// `tom_som_typescript_runtime/src/docspecs_validator.ts` (itself a port of the
// JavaScript / Python / Dart parity chain).
//
// Three cooperating pieces:
//
//  1. DocSpecsDocument — a schema-free structural parse of a DocSpecs markdown
//     document into a heading tree (fence-aware, never fails).
//  2. DocSpecsSchema — loader for `*.docspecs-schema.yaml` files with SOM §14-style
//     warnings for unsupported keys (never fails on extra keys).
//  3. DocSpecsValidator — never-fail-fast validation of a parsed document
//     against a schema, emitting DocSpecsViolations whose messages are
//     golden-identical to the Dart implementation.
//
// Plus BindDocspecsMarkdown, which lands a DocSpecs markdown text in a typed
// SpecDocument via the SOM markdown codec.
//
// Go conventions: "" stands in for the other ports' null strings
// (DocSpecsViolation.SectionID/Path, DocSpecsSection.ID, …); optional ints are
// *int; the one throwing entry point (fromYamlText's "must be a YAML map")
// returns an error instead.

import (
	"errors"
	"regexp"
	"sort"
	"strings"
	"unicode"
)

// The vocabulary of validation violation rules (Dart-parity names).
const (
	DocSpecsRuleUnknownSection         = "unknownSection"
	DocSpecsRuleMissingRequiredSection = "missingRequiredSection"
	DocSpecsRuleIDPatternMismatch      = "idPatternMismatch"
	DocSpecsRuleTooFewItems            = "tooFewItems"
	DocSpecsRuleTooManyItems           = "tooManyItems"
	DocSpecsRuleMissingRequiredField   = "missingRequiredField"
	DocSpecsRuleFieldPatternMismatch   = "fieldPatternMismatch"
	DocSpecsRuleTextRequired           = "textRequired"
	DocSpecsRuleTextLengthOut          = "textLengthOut"
	DocSpecsRuleFormatMismatch         = "formatMismatch"
	DocSpecsRuleMalformedHeading       = "malformedHeading"
	// DocSpecsRuleSectionOutOfOrder: a root child stands before a
	// `document: sections:` slot taken earlier (the slots' order; a
	// `position: any` slot's type stands anywhere).
	DocSpecsRuleSectionOutOfOrder = "sectionOutOfOrder"
	// DocSpecsRuleDuplicateIDPath: a section's id repeats an earlier
	// sibling's, so its id path (the ids from the root down to it) is not
	// unique.
	DocSpecsRuleDuplicateIDPath = "duplicateIdPath"

	// The reading notation's findings (DocSpecs specification, RN-10),
	// reported by ScanNotation per value: a section's own body, and in a
	// TomSpecs rendition each form field's value apart. Each is the
	// NotationFindingCode.String() of its code.

	// DocSpecsRuleUnclosedDiv: an opening fence without its closing fence.
	DocSpecsRuleUnclosedDiv = "unclosedDiv"
	// DocSpecsRuleStrayClosingFence: a closing fence without an open div.
	DocSpecsRuleStrayClosingFence = "strayClosingFence"
	// DocSpecsRuleUnclosedSpan: a span's attribute braces do not close on the
	// paragraph.
	DocSpecsRuleUnclosedSpan = "unclosedSpan"
	// DocSpecsRuleDivWithoutKind: a div whose attributes hold no class
	// (TomSpecs renditions only).
	DocSpecsRuleDivWithoutKind = "divWithoutKind"
	// DocSpecsRuleUnknownKind: an unregistered kind (TomSpecs renditions only;
	// a warning).
	DocSpecsRuleUnknownKind = "unknownKind"
	// DocSpecsRuleMarkAcrossNotation: an inline review mark crosses the
	// boundary of a span or citation.
	DocSpecsRuleMarkAcrossNotation = "markAcrossNotation"
	// DocSpecsRuleAnnotationInsideDiv: a comment or question block stands
	// inside a div.
	DocSpecsRuleAnnotationInsideDiv = "annotationInsideDiv"
	// DocSpecsRuleDivInsideAnnotation: a div stands inside a comment or
	// question block.
	DocSpecsRuleDivInsideAnnotation = "divInsideAnnotation"
	// DocSpecsRuleRejectedBlock: a `rejected` block waits for its resolution.
	DocSpecsRuleRejectedBlock = "rejectedBlock"

	// The reading view's list bodies and tables (DocSpecs specification,
	// Findings in list bodies and tables).

	// DocSpecsRuleMalformedBlock: a form, section or record table without a
	// matching delimiter row, a row of another cell count, a field given twice
	// (the first kept), a refs / records div beside other text or item
	// headings, a records div holding no table or one whose first column is
	// not Id, an unclosed refs / records fence.
	DocSpecsRuleMalformedBlock = "malformedBlock"
	// DocSpecsRuleUnknownField: a form-table row or a record-table column
	// naming no field of its form.
	DocSpecsRuleUnknownField = "unknownField"
)

// DocSpecsAllRules is the complete §14 vocabulary, in declaration order — the
// enumerable form of what Dart gets for free from its enum. The conformance
// runner diffs it against the rules the shared corpus exercises, so a rule
// added here without a corpus case fails the suite instead of going unnoticed.
var DocSpecsAllRules = []string{
	DocSpecsRuleUnknownSection,
	DocSpecsRuleMissingRequiredSection,
	DocSpecsRuleIDPatternMismatch,
	DocSpecsRuleTooFewItems,
	DocSpecsRuleTooManyItems,
	DocSpecsRuleMissingRequiredField,
	DocSpecsRuleFieldPatternMismatch,
	DocSpecsRuleTextRequired,
	DocSpecsRuleTextLengthOut,
	DocSpecsRuleFormatMismatch,
	DocSpecsRuleMalformedHeading,
	DocSpecsRuleSectionOutOfOrder,
	DocSpecsRuleDuplicateIDPath,
	DocSpecsRuleUnclosedDiv,
	DocSpecsRuleStrayClosingFence,
	DocSpecsRuleUnclosedSpan,
	DocSpecsRuleDivWithoutKind,
	DocSpecsRuleUnknownKind,
	DocSpecsRuleMarkAcrossNotation,
	DocSpecsRuleAnnotationInsideDiv,
	DocSpecsRuleDivInsideAnnotation,
	DocSpecsRuleRejectedBlock,
	DocSpecsRuleMalformedBlock,
	DocSpecsRuleUnknownField,
}

// DocSpecsViolation is one validation finding.
type DocSpecsViolation struct {
	Rule      string
	Line      int
	Message   string
	SectionID string
	Path      string
}

func (v *DocSpecsViolation) String() string {
	sid := ""
	if v.SectionID != "" {
		sid = " [" + v.SectionID + "]"
	}
	p := ""
	if v.Path != "" {
		p = " (" + v.Path + ")"
	}
	return "line " + itoa(v.Line) + ": " + v.Rule + sid + p + " — " + v.Message
}

// DocSpecsSection is one heading-delimited section of a schema-free document
// parse.
type DocSpecsSection struct {
	// ID is the headline-comment section id, "" for a malformed heading.
	ID    string
	Title string
	Level int
	Line  int
	// BodyLines holds the raw body lines between this heading and the next.
	BodyLines []string
	Children  []*DocSpecsSection
}

// BodyStartLine is the 1-based line number of the first body line.
func (s *DocSpecsSection) BodyStartLine() int {
	return s.Line + 1
}

// Text is the body text with leading/trailing blank lines trimmed.
func (s *DocSpecsSection) Text() string {
	lines := s.BodyLines
	start := 0
	end := len(lines)
	for start < end && strings.TrimSpace(lines[start]) == "" {
		start++
	}
	for end > start && strings.TrimSpace(lines[end-1]) == "" {
		end--
	}
	return strings.Join(lines[start:end], "\n")
}

var docspecHeaderRE = regexp.MustCompile(`^<!--\s*docspec:\s*(\S+)\s*-->\s*$`)

// DocSpecsDocument is a schema-free structural parse of a DocSpecs markdown
// document.
type DocSpecsDocument struct {
	// DeclaredSchema is the `<!-- docspec: … -->` declaration, "" when absent.
	DeclaredSchema string
	// Sections holds the top-level (root) sections.
	Sections []*DocSpecsSection
	// Violations holds structural findings from the parse.
	Violations []*DocSpecsViolation
}

// ParseDocSpecsDocument parses text into a heading tree. It never fails —
// structural problems are recorded as violations.
func ParseDocSpecsDocument(text string) *DocSpecsDocument {
	doc := &DocSpecsDocument{}
	fence := &MarkdownFenceTracker{}
	var stack []*DocSpecsSection
	lines := strings.Split(text, "\n")
	readable := false
	for idx, raw := range lines {
		lineNo := idx + 1
		line := mdTrailingWSRE.ReplaceAllString(raw, "")
		if !fence.InFence() {
			if len(stack) == 0 && doc.DeclaredSchema == "" {
				if h := docspecHeaderRE.FindStringSubmatch(line); h != nil {
					doc.DeclaredSchema = h[1]
					fence.Feed(raw)
					continue
				}
			}
			// A stripped rendition (SOM §11.1): its readable header stands
			// before the root heading, and its appendix after the marker is
			// not part of the document.
			if len(stack) == 0 && SpecMarkdownIsReadableComment(line) {
				readable = true
				fence.Feed(raw)
				continue
			}
			if readable && line == SpecMarkdownAppendixMarker {
				break
			}
			m := mdHeadingLineRE.FindStringSubmatch(line)
			divLevel, divText, isDiv := 0, "", false
			if m == nil {
				divLevel, divText, isDiv = docspecsStyledDivHeading(line)
			}
			if m != nil || isDiv {
				var level int
				var rest string
				if m != nil {
					level = len(m[1])
					rest = m[2]
				} else {
					level = divLevel
					rest = strings.TrimSpace(divText)
				}
				var section *DocSpecsSection
				if c := mdHeadlineCommentRE.FindStringSubmatch(rest); c != nil {
					// c[2] is the optional key=value region (codespecs_mapping.md §9.2
					// codeSpec); the title is c[3] without the section's own anchor
					// (Section Anchors). For a bare heading comment with no title,
					// fall back to the whole heading text.
					title := StripOwnAnchor(strings.TrimSpace(c[3]), c[1])
					if title == "" {
						title = rest
					}
					section = &DocSpecsSection{
						ID: c[1], Title: title, Level: level, Line: lineNo,
					}
				} else {
					doc.Violations = append(doc.Violations, &DocSpecsViolation{
						Rule: DocSpecsRuleMalformedHeading,
						Line: lineNo,
						Message: "heading \"" + rest + "\" carries no " +
							"<!--[SECTION-ID]--> headline comment",
					})
					section = &DocSpecsSection{Title: rest, Level: level, Line: lineNo}
				}
				for len(stack) > 0 && stack[len(stack)-1].Level >= level {
					stack = stack[:len(stack)-1]
				}
				if len(stack) > 0 {
					parent := stack[len(stack)-1]
					parent.Children = append(parent.Children, section)
				} else {
					doc.Sections = append(doc.Sections, section)
				}
				stack = append(stack, section)
				fence.Feed(raw)
				continue
			}
		}
		if len(stack) > 0 {
			top := stack[len(stack)-1]
			top.BodyLines = append(top.BodyLines, raw)
		}
		fence.Feed(raw)
	}
	return doc
}

// AllSections returns every section of the document, depth-first: each
// section followed by its subsections, at all levels.
func (d *DocSpecsDocument) AllSections() []*DocSpecsSection {
	var out []*DocSpecsSection
	var walk func(list []*DocSpecsSection)
	walk = func(list []*DocSpecsSection) {
		for _, s := range list {
			out = append(out, s)
			walk(s.Children)
		}
	}
	walk(d.Sections)
	return out
}

// DocSpecsReplaceSectionBody returns text with the body of the section whose
// id is sectionID replaced by body; every other byte is kept.
//
// The body is the section's own region: the lines after its heading up to its
// first child heading, or the next heading of any level. The heading line
// (with its `<!--[ID]-->` comment) and the subsections are untouched. The
// region is found by the same fence-aware ParseDocSpecsDocument, so a `#` line
// inside a fenced block is never taken for a heading.
//
// The new region is a blank line, body with its leading and trailing blank
// lines removed, and a blank line; an empty body leaves a single blank line.
// It returns an error when sectionID names no section or more than one, and
// when body would change the document's structure: a heading outside a fenced
// block, or a fence it opens and never closes.
func DocSpecsReplaceSectionBody(text, sectionID, body string) (string, error) {
	var matches []*DocSpecsSection
	for _, s := range ParseDocSpecsDocument(text).AllSections() {
		if s.ID == sectionID {
			matches = append(matches, s)
		}
	}
	if len(matches) == 0 {
		return "", errors.New("sectionId \"" + sectionID + "\" names no section")
	}
	if len(matches) > 1 {
		lineNos := make([]string, len(matches))
		for i, s := range matches {
			lineNos[i] = itoa(s.Line)
		}
		return "", errors.New("sectionId \"" + sectionID + "\" names " +
			itoa(len(matches)) + " sections (lines " +
			strings.Join(lineNos, ", ") + ")")
	}

	bodyLines := strings.Split(body, "\n")
	for len(bodyLines) > 0 && strings.TrimSpace(bodyLines[0]) == "" {
		bodyLines = bodyLines[1:]
	}
	for len(bodyLines) > 0 && strings.TrimSpace(bodyLines[len(bodyLines)-1]) == "" {
		bodyLines = bodyLines[:len(bodyLines)-1]
	}
	fence := &MarkdownFenceTracker{}
	for _, line := range bodyLines {
		if !fence.InFence() &&
			mdHeadingLineRE.MatchString(strings.TrimRightFunc(line, unicode.IsSpace)) {
			return "", errors.New("body contains a heading outside a fenced " +
				"block: \"" + line + "\"")
		}
		fence.Feed(line)
	}
	if fence.InFence() {
		return "", errors.New("body leaves a fenced block open")
	}

	section := matches[0]
	lines := strings.Split(text, "\n")
	start := section.Line // 0-based index of the first body line
	end := start + len(section.BodyLines)
	region := []string{""}
	if len(bodyLines) > 0 {
		region = append(append([]string{""}, bodyLines...), "")
	}
	out := make([]string, 0, len(lines)-(end-start)+len(region))
	out = append(out, lines[:start]...)
	out = append(out, region...)
	out = append(out, lines[end:]...)
	return strings.Join(out, "\n"), nil
}

var docSpecsIDTransformRE = regexp.MustCompile(`[^a-zA-Z0-9_]+`)

// DocSpecsIDTransform is the DocSpecs id transform: every run of
// non-alphanumeric/underscore characters becomes a single `_`.
func DocSpecsIDTransform(id string) string {
	return docSpecsIDTransformRE.ReplaceAllString(id, "_")
}

// DocSpecsPatternCheck is a regex pattern check with an optional custom error
// message ("" when none).
type DocSpecsPatternCheck struct {
	Pattern      string
	ErrorMessage string
}

// Matches reports whether value matches the check's pattern (false when the
// pattern does not compile).
func (c *DocSpecsPatternCheck) Matches(value string) bool {
	re, err := regexp.Compile(c.Pattern)
	if err != nil {
		return false
	}
	return re.MatchString(value)
}

// DocSpecsSubsectionRule holds occurrence bounds for one subsection type.
// MaxCount == nil means infinite.
type DocSpecsSubsectionRule struct {
	MinCount int
	MaxCount *int
}

// DocSpecsSectionType is one `section-types` entry of a schema.
type DocSpecsSectionType struct {
	Name            string
	Prefix          string
	PatternCheck    *DocSpecsPatternCheck
	SubsectionTypes map[string]*DocSpecsSubsectionRule
	// subsectionOrder keeps the file order of SubsectionTypes keys (Go maps
	// are unordered; the other ports iterate insertion order).
	subsectionOrder  []string
	Format           string
	TextRequired     bool
	MinTextLength    *int
	MaxTextLength    *int
	Description      string
	ValidationPrompt string
}

// DocSpecsFormField is one field of a `form-types` entry.
type DocSpecsFormField struct {
	Name         string
	Required     bool
	Description  string
	PatternCheck *DocSpecsPatternCheck
}

// DocSpecsFormType is one `form-types` entry of a schema.
type DocSpecsFormType struct {
	Name   string
	Fields []*DocSpecsFormField
}

// DocSpecsDocumentSection is one `document.sections` slot of a schema.
type DocSpecsDocumentSection struct {
	SectionType string
	Optional    bool
	// Position is `relative` (the default: in the order of
	// `document: sections:`) or `any` (anywhere among the root's children;
	// the order check leaves it out).
	Position string
}

// DocSpecsDocumentSectionPositions are the Position values a document
// section may take.
var DocSpecsDocumentSectionPositions = []string{"relative", "any"}

// AnyPosition reports whether the section may stand anywhere among the
// root's children.
func (d *DocSpecsDocumentSection) AnyPosition() bool {
	return d.Position == "any"
}

// dvIsTrue accepts a plain-scalar "true" string — the bundled yaml parser
// keeps plain booleans as strings, matching the other ports' behaviour.
func dvIsTrue(v interface{}) bool {
	s, ok := v.(string)
	return ok && s == "true"
}

// dvStr coerces a parsed yaml scalar to its string form ("" for nil).
func dvStr(v interface{}) string {
	switch t := v.(type) {
	case string:
		return t
	case int:
		return itoa(t)
	default:
		return ""
	}
}

// dvInt returns the value as an int when it is one.
func dvInt(v interface{}) (int, bool) {
	n, ok := v.(int)
	return n, ok
}

var docSpecsSectionTypeKeys = map[string]bool{
	"prefix":            true,
	"pattern-check-id":  true,
	"subsection-types":  true,
	"format":            true,
	"text-required":     true,
	"min-text-length":   true,
	"max-text-length":   true,
	"description":       true,
	"validation-prompt": true,
}

// DocSpecsSchema is a loaded `*.docspecs-schema.yaml` schema.
type DocSpecsSchema struct {
	// TitleFormat is the schema's `title-format`, "" when absent.
	TitleFormat string
	// SectionTypes holds the section types in file order.
	SectionTypes       []*DocSpecsSectionType
	SectionTypesByName map[string]*DocSpecsSectionType
	FormTypes          map[string]*DocSpecsFormType
	DocumentSections   map[string]*DocSpecsDocumentSection
	// documentSectionOrder keeps the file order of DocumentSections keys.
	documentSectionOrder []string
	// Warnings holds SOM §14 warnings for unsupported keys.
	Warnings []string
}

var docspecsRootIDRE = regexp.MustCompile(`<!--\[([^\]]+)\]-->`)

// RootSectionID is the section id embedded in TitleFormat, "" when none.
func (s *DocSpecsSchema) RootSectionID() string {
	if s.TitleFormat == "" {
		return ""
	}
	if m := docspecsRootIDRE.FindStringSubmatch(s.TitleFormat); m != nil {
		return m[1]
	}
	return ""
}

// docspecsSchemaError reports a schema source that is not a YAML map.
type docspecsSchemaError struct{}

func (e *docspecsSchemaError) Error() string {
	return "docspecs schema must be a YAML map"
}

// DocSpecsSchemaFromYamlText loads a schema from YAML text. Unknown keys warn;
// a non-map root returns an error (the other ports' throw).
func DocSpecsSchemaFromYamlText(text string) (*DocSpecsSchema, error) {
	data, ok := YamlParse(text).(*YamlMap)
	if !ok || data.Len() == 0 && strings.TrimSpace(text) != "" &&
		!strings.Contains(text, ":") {
		return nil, &docspecsSchemaError{}
	}
	schema := &DocSpecsSchema{
		SectionTypesByName: map[string]*DocSpecsSectionType{},
		FormTypes:          map[string]*DocSpecsFormType{},
		DocumentSections:   map[string]*DocSpecsDocumentSection{},
	}
	for _, k := range data.Keys() {
		v := data.GetOr(k)
		switch k {
		case "title-format":
			schema.TitleFormat = dvStr(v)
		case "section-types":
			schema.loadSectionTypes(v)
		case "form-types":
			schema.loadFormTypes(v)
		case "document":
			if err := schema.loadDocument(v); err != nil {
				return nil, err
			}
		case "schema", "version", "name", "description":
			// informational keys — accepted, unused
		default:
			schema.Warnings = append(schema.Warnings,
				"unsupported top-level schema key \""+k+"\" ignored")
		}
	}
	return schema, nil
}

func docspecsPatternCheck(node interface{}) *DocSpecsPatternCheck {
	if node == nil {
		return nil
	}
	if m, ok := node.(*YamlMap); ok {
		return &DocSpecsPatternCheck{
			Pattern:      dvStr(m.GetOr("pattern")),
			ErrorMessage: dvStr(m.GetOr("error-message")),
		}
	}
	return &DocSpecsPatternCheck{Pattern: dvStr(node)}
}

func (s *DocSpecsSchema) loadSectionTypes(node interface{}) {
	m, ok := node.(*YamlMap)
	if !ok {
		return
	}
	for _, name := range m.Keys() {
		raw, ok := m.GetOr(name).(*YamlMap)
		if !ok {
			continue
		}
		subs := map[string]*DocSpecsSubsectionRule{}
		var subOrder []string
		if subNode, ok := raw.GetOr("subsection-types").(*YamlMap); ok {
			for _, subName := range subNode.Keys() {
				minCount := 0
				var maxCount *int
				if subRaw, ok := subNode.GetOr(subName).(*YamlMap); ok {
					if n, ok := dvInt(subRaw.GetOr("min-count")); ok {
						minCount = n
					}
					if n, ok := dvInt(subRaw.GetOr("max-count")); ok {
						v := n
						maxCount = &v
					}
				}
				subs[subName] = &DocSpecsSubsectionRule{MinCount: minCount, MaxCount: maxCount}
				subOrder = append(subOrder, subName)
			}
		}
		for _, key := range raw.Keys() {
			if !docSpecsSectionTypeKeys[key] {
				s.Warnings = append(s.Warnings,
					"unsupported key \""+key+"\" on section-type \""+name+"\" ignored")
			}
		}
		prefix := DocSpecsIDTransform(strings.ToUpper(name))
		if raw.Has("prefix") {
			prefix = dvStr(raw.GetOr("prefix"))
		}
		var minText, maxText *int
		if n, ok := dvInt(raw.GetOr("min-text-length")); ok {
			v := n
			minText = &v
		}
		if n, ok := dvInt(raw.GetOr("max-text-length")); ok {
			v := n
			maxText = &v
		}
		t := &DocSpecsSectionType{
			Name:             name,
			Prefix:           prefix,
			PatternCheck:     docspecsPatternCheck(raw.GetOr("pattern-check-id")),
			SubsectionTypes:  subs,
			subsectionOrder:  subOrder,
			Format:           dvStr(raw.GetOr("format")),
			TextRequired:     dvIsTrue(raw.GetOr("text-required")),
			MinTextLength:    minText,
			MaxTextLength:    maxText,
			Description:      dvStr(raw.GetOr("description")),
			ValidationPrompt: dvStr(raw.GetOr("validation-prompt")),
		}
		s.SectionTypes = append(s.SectionTypes, t)
		s.SectionTypesByName[name] = t
	}
}

func (s *DocSpecsSchema) loadFormTypes(node interface{}) {
	m, ok := node.(*YamlMap)
	if !ok {
		return
	}
	for _, name := range m.Keys() {
		raw, ok := m.GetOr(name).(*YamlMap)
		if !ok {
			continue
		}
		for _, key := range raw.Keys() {
			if key != "fields" {
				s.Warnings = append(s.Warnings,
					"unsupported key \""+key+"\" on form-type \""+name+"\" ignored")
			}
		}
		var fields []*DocSpecsFormField
		if fieldsNode, ok := raw.GetOr("fields").([]interface{}); ok {
			for _, f := range fieldsNode {
				fm, ok := f.(*YamlMap)
				if !ok {
					continue
				}
				fields = append(fields, &DocSpecsFormField{
					Name:         dvStr(fm.GetOr("fieldname")),
					Required:     dvIsTrue(fm.GetOr("required")),
					Description:  dvStr(fm.GetOr("description")),
					PatternCheck: docspecsPatternCheck(fm.GetOr("pattern-check")),
				})
			}
		}
		s.FormTypes[name] = &DocSpecsFormType{Name: name, Fields: fields}
	}
}

func (s *DocSpecsSchema) loadDocument(node interface{}) error {
	m, ok := node.(*YamlMap)
	if !ok {
		return nil
	}
	for _, k := range m.Keys() {
		v := m.GetOr(k)
		if k == "sections" {
			sections, ok := v.(*YamlMap)
			if !ok {
				continue
			}
			for _, sKey := range sections.Keys() {
				sectionType := sKey
				optional := false
				position := "relative"
				if sRaw, ok := sections.GetOr(sKey).(*YamlMap); ok {
					if sRaw.Has("section-type") {
						sectionType = dvStr(sRaw.GetOr("section-type"))
					}
					optional = dvIsTrue(sRaw.GetOr("optional"))
					if p := sRaw.GetOr("position"); p != nil {
						position = dvStr(p)
						if position != "relative" && position != "any" {
							return errors.New("document section \"" + sKey +
								"\": position \"" + position +
								"\" is not one of relative, any")
						}
					}
				}
				s.DocumentSections[sKey] = &DocSpecsDocumentSection{
					SectionType: sectionType,
					Optional:    optional,
					Position:    position,
				}
				s.documentSectionOrder = append(s.documentSectionOrder, sKey)
			}
		} else if k != "name" && k != "description" {
			s.Warnings = append(s.Warnings, "unsupported document key \""+k+"\" ignored")
		}
	}
	return nil
}

// ResolveSectionType resolves a section id to its section-type by
// first-startsWith prefix match over DocSpecsIDTransform'd ids.
func (s *DocSpecsSchema) ResolveSectionType(id string) *DocSpecsSectionType {
	transformed := DocSpecsIDTransform(id)
	for _, t := range s.SectionTypes {
		if strings.HasPrefix(transformed, t.Prefix) {
			return t
		}
	}
	return nil
}

// DocSpecsValidator is a never-fail-fast validator of a parsed document
// against a schema.
type DocSpecsValidator struct {
	Schema *DocSpecsSchema
	// TomSpecs says the documents are TomSpecs renditions: the reading
	// notation is then scanned value by value (a form field's value apart from
	// the next), and a div without a class and an unregistered kind are
	// reported too.
	TomSpecs bool
}

// NewDocSpecsValidator binds a schema to the validator of plain DocSpecs
// documents.
func NewDocSpecsValidator(schema *DocSpecsSchema) *DocSpecsValidator {
	return &DocSpecsValidator{Schema: schema}
}

// NewDocSpecsValidatorWithTomSpecs binds a schema to a validator of TomSpecs
// renditions (tomSpecs true) or of plain DocSpecs documents (false, as
// NewDocSpecsValidator).
func NewDocSpecsValidatorWithTomSpecs(schema *DocSpecsSchema, tomSpecs bool) *DocSpecsValidator {
	return &DocSpecsValidator{Schema: schema, TomSpecs: tomSpecs}
}

// ValidateMarkdown parses + validates in one step.
func (val *DocSpecsValidator) ValidateMarkdown(markdown string) []*DocSpecsViolation {
	return val.Validate(ParseDocSpecsDocument(markdown))
}

// Validate validates a parsed document, returning ALL findings (never
// fail-fast).
func (val *DocSpecsValidator) Validate(doc *DocSpecsDocument) []*DocSpecsViolation {
	v := make([]*DocSpecsViolation, len(doc.Violations))
	copy(v, doc.Violations)
	if len(doc.Sections) == 0 {
		v = append(v, &DocSpecsViolation{
			Rule:    DocSpecsRuleFormatMismatch,
			Line:    1,
			Message: "document has no root heading",
		})
		return v
	}
	root := doc.Sections[0]
	rootID := val.Schema.RootSectionID()
	if rootID != "" && root.ID != rootID {
		v = append(v, &DocSpecsViolation{
			Rule: DocSpecsRuleFormatMismatch,
			Line: root.Line,
			Message: "root heading id \"" + root.ID + "\" does not match the " +
				"schema title-format id \"" + rootID + "\"",
			SectionID: root.ID,
		})
	}
	for _, extra := range doc.Sections[1:] {
		v = append(v, &DocSpecsViolation{
			Rule:      DocSpecsRuleUnknownSection,
			Line:      extra.Line,
			Message:   "unexpected additional top-level section",
			SectionID: extra.ID,
		})
	}
	v = val.validateDocumentSections(docspecsNodeOf(root), v)
	v = val.validateNotation(doc, v)
	v = validateIDPaths(doc.Sections, v)
	return v
}

// validateNotation checks the reading notation of every section's own body:
// one value per section, and in a TomSpecs rendition one per form field of a
// form-formatted section (its preamble included).
func (val *DocSpecsValidator) validateNotation(
	doc *DocSpecsDocument, v []*DocSpecsViolation,
) []*DocSpecsViolation {
	for _, section := range doc.AllSections() {
		for _, value := range val.notationValues(section) {
			scan := ScanNotation(strings.Join(value.lines, "\n"), val.TomSpecs)
			for _, f := range scan.Findings {
				v = append(v, &DocSpecsViolation{
					Rule:      f.Code.String(),
					Line:      section.BodyStartLine() + value.first + f.Line - 1,
					Message:   f.Message,
					SectionID: section.ID,
				})
			}
		}
	}
	return v
}

// docspecsNotationValue is one value of a section's own body: the index of its
// first line and its lines.
type docspecsNotationValue struct {
	first int
	lines []string
}

// notationValues splits section's own body into the values the reading
// notation is scanned in.
func (val *DocSpecsValidator) notationValues(section *DocSpecsSection) []docspecsNotationValue {
	body := section.BodyLines
	var form *DocSpecsFormType
	if val.TomSpecs && section.ID != "" {
		if t := val.Schema.ResolveSectionType(section.ID); t != nil && t.Format != "" {
			form = val.Schema.FormTypes[t.Format]
		}
	}
	if form == nil {
		return []docspecsNotationValue{{0, body}}
	}
	labels := map[string]bool{}
	for _, f := range form.Fields {
		labels[strings.ToLower(f.Name)] = true
	}
	var values []docspecsNotationValue
	fence := &MarkdownFenceTracker{}
	first := 0
	for i, line := range body {
		if !fence.InFence() && i > first {
			if m := mdFieldLabelRE.FindStringSubmatch(line); m != nil &&
				labels[strings.ToLower(m[1])] {
				values = append(values, docspecsNotationValue{first, body[first:i]})
				first = i
			}
		}
		fence.Feed(line)
	}
	return append(values, docspecsNotationValue{first, body[first:]})
}

// validateIDPaths checks every section's id path (the ids from the root down
// to it) is unique: a section whose id repeats an earlier sibling's is a
// DocSpecsRuleDuplicateIDPath. Its descendants repeat paths only through it
// and are not reported again. Sections without an id are skipped (already
// malformedHeading). Depth-first, source order.
func validateIDPaths(
	sections []*DocSpecsSection, v []*DocSpecsViolation,
) []*DocSpecsViolation {
	seen := map[string]bool{}
	for _, s := range sections {
		if s.ID != "" {
			if seen[s.ID] {
				v = append(v, &DocSpecsViolation{
					Rule: DocSpecsRuleDuplicateIDPath,
					Line: s.Line,
					Message: "section id \"" + s.ID + "\" repeats a sibling's id, " +
						"so its id path is not unique",
					SectionID: s.ID,
				})
				continue
			}
			seen[s.ID] = true
		}
		v = validateIDPaths(s.Children, v)
	}
	return v
}

// resolveChild resolves a walked section's type: a virtual list item's is the
// schema's; a section id resolving to none is DocSpecsRuleUnknownSection.
func (val *DocSpecsValidator) resolveChild(
	section *docspecsNode, v []*DocSpecsViolation,
) (*DocSpecsSectionType, []*DocSpecsViolation) {
	if section.typ != nil {
		return section.typ, v // a virtual list item: the schema's type.
	}
	if section.id == "" {
		return nil, v // already reported as MALFORMED_HEADING by the parse.
	}
	t := val.Schema.ResolveSectionType(section.id)
	if t == nil {
		v = append(v, &DocSpecsViolation{
			Rule: DocSpecsRuleUnknownSection,
			Line: section.line,
			Message: "section id \"" + section.id + "\" resolves to no " +
				"section-type of the schema",
			SectionID: section.id,
		})
	}
	return t, v
}

// validateDocumentSections: root children must occupy `document: sections:`
// slots, in their order (a `position: any` slot's type stands anywhere);
// required slots must be present. A section table in the root's body rebuilds
// root children as virtual sections first.
func (val *DocSpecsValidator) validateDocumentSections(
	root *docspecsNode, v []*DocSpecsViolation,
) []*DocSpecsViolation {
	// Occurrences per section-type name.
	counts := map[string]int{}
	slotTypes := map[string]bool{}
	for _, slot := range val.Schema.DocumentSections {
		slotTypes[slot.SectionType] = true
	}
	v = val.expandSectionTables(root,
		func(t *DocSpecsSectionType) bool { return slotTypes[t.Name] }, v)
	// The slots in the order of `document: sections:`; "" marks a
	// `position: any` slot, which the order check leaves out.
	anywhere := map[string]bool{}
	order := make([]string, 0, len(val.Schema.documentSectionOrder))
	for _, slotKey := range val.Schema.documentSectionOrder {
		slot := val.Schema.DocumentSections[slotKey]
		if slot.AnyPosition() {
			anywhere[slot.SectionType] = true
			order = append(order, "")
		} else {
			order = append(order, slot.SectionType)
		}
	}
	lastIndex := -1
	for _, child := range root.children {
		var t *DocSpecsSectionType
		t, v = val.resolveChild(child, v)
		if t == nil {
			continue
		}
		if !slotTypes[t.Name] {
			v = append(v, &DocSpecsViolation{
				Rule: DocSpecsRuleUnknownSection,
				Line: child.line,
				Message: "section-type \"" + t.Name + "\" is not a top-level " +
					"document section",
				SectionID: child.id,
			})
			continue
		}
		if !anywhere[t.Name] {
			lastIndex, v = docspecsCheckOrder(child, t.Name, order, lastIndex, v)
		}
		counts[t.Name]++
		v = val.validateSection(child, t, v)
	}
	for _, slotKey := range val.Schema.documentSectionOrder {
		slot := val.Schema.DocumentSections[slotKey]
		if !slot.Optional && counts[slot.SectionType] == 0 {
			v = append(v, &DocSpecsViolation{
				Rule: DocSpecsRuleMissingRequiredSection,
				Line: root.line,
				Message: "required document section \"" + slotKey + "\" (type \"" +
					slot.SectionType + "\") is missing",
				SectionID: slotKey,
			})
		}
	}
	return v
}

// docspecsCheckOrder is the order check of one root child: its slot is the
// first of its type at or after the last slot taken, else the first of its
// type anywhere; a slot before the last one taken is
// DocSpecsRuleSectionOutOfOrder. Answers the last slot taken afterwards.
func docspecsCheckOrder(
	child *docspecsNode, typeName string, order []string, lastIndex int,
	v []*DocSpecsViolation,
) (int, []*DocSpecsViolation) {
	index := -1
	start := lastIndex
	if start < 0 {
		start = 0
	}
	for i := start; i < len(order); i++ {
		if order[i] == typeName {
			index = i
			break
		}
	}
	if index == -1 {
		for i, o := range order {
			if o == typeName {
				index = i
				break
			}
		}
	}
	if index == -1 {
		return lastIndex, v
	}
	if index < lastIndex {
		v = append(v, &DocSpecsViolation{
			Rule: DocSpecsRuleSectionOutOfOrder,
			Line: child.line,
			Message: "section \"" + child.id + "\" (type \"" + typeName +
				"\") stands out of the order of the document sections",
			SectionID: child.id,
		})
		return lastIndex, v
	}
	return index, v
}

func (val *DocSpecsValidator) validateSection(
	section *docspecsNode, t *DocSpecsSectionType, v []*DocSpecsViolation,
) []*DocSpecsViolation {
	if pc := t.PatternCheck; pc != nil && section.id != "" && !pc.Matches(section.id) {
		message := pc.ErrorMessage
		if message == "" {
			message = "section id \"" + section.id + "\" does not match pattern \"" +
				pc.Pattern + "\""
		}
		v = append(v, &DocSpecsViolation{
			Rule:      DocSpecsRuleIDPatternMismatch,
			Line:      section.line,
			Message:   message,
			SectionID: section.id,
		})
	}
	// List bodies and section tables become virtual sections before anything
	// is counted or checked (DocSpecs specification, List Bodies).
	v = val.expandSectionTables(section, func(st *DocSpecsSectionType) bool {
		_, ok := t.SubsectionTypes[st.Name]
		return ok
	}, v)
	v = val.expandListBody(section, t, v)
	v = val.validateText(section, t, v)
	v = val.validateFormat(section, t, v)
	// Occurrences per subsection type name.
	counts := map[string]int{}
	for _, child := range section.children {
		var childType *DocSpecsSectionType
		childType, v = val.resolveChild(child, v)
		if childType == nil {
			continue
		}
		if _, ok := t.SubsectionTypes[childType.Name]; !ok {
			v = append(v, &DocSpecsViolation{
				Rule: DocSpecsRuleUnknownSection,
				Line: child.line,
				Message: "section-type \"" + childType.Name + "\" is not an " +
					"allowed subsection of \"" + t.Name + "\"",
				SectionID: child.id,
			})
			continue
		}
		counts[childType.Name]++
		v = val.validateSection(child, childType, v)
	}
	// The offending section is the CONTAINER, not the absent child: a
	// cardinality breach has no child occurrence to point at, and `subKey` is a
	// schema type name, not a section id. Dart is the golden reference here.
	for _, subKey := range t.subsectionOrder {
		rule := t.SubsectionTypes[subKey]
		count := counts[subKey]
		if count < rule.MinCount {
			if count == 0 {
				v = append(v, &DocSpecsViolation{
					Rule: DocSpecsRuleMissingRequiredSection,
					Line: section.line,
					Message: "required subsection \"" + subKey + "\" of \"" +
						t.Name + "\" is missing",
					SectionID: section.id,
				})
			} else {
				v = append(v, &DocSpecsViolation{
					Rule: DocSpecsRuleTooFewItems,
					Line: section.line,
					Message: "subsection \"" + subKey + "\" occurs " + itoa(count) +
						" time(s), minimum is " + itoa(rule.MinCount),
					SectionID: section.id,
				})
			}
		}
		if rule.MaxCount != nil && count > *rule.MaxCount {
			v = append(v, &DocSpecsViolation{
				Rule: DocSpecsRuleTooManyItems,
				Line: section.line,
				Message: "subsection \"" + subKey + "\" occurs " + itoa(count) +
					" time(s), maximum is " + itoa(*rule.MaxCount),
				SectionID: section.id,
			})
		}
	}
	return v
}

func (val *DocSpecsValidator) validateText(
	section *docspecsNode, t *DocSpecsSectionType, v []*DocSpecsViolation,
) []*DocSpecsViolation {
	if t.Format != "" {
		if _, ok := val.Schema.FormTypes[t.Format]; ok {
			return v // form sections carry fields, not body text.
		}
	}
	// A list body or section table already read is blanked in the body, so a
	// container written with one counts as empty (`max-text-length: 0`); the
	// rendition's marker and generated block are no text either.
	text := docspecsWithoutGeneratedText(section.text())
	if t.TextRequired && len(text) == 0 {
		v = append(v, &DocSpecsViolation{
			Rule:      DocSpecsRuleTextRequired,
			Line:      section.line,
			Message:   "section requires body text but has none",
			SectionID: section.id,
		})
		return v
	}
	if len(text) == 0 {
		return v // an empty body passes the text-length bounds.
	}
	length := len([]rune(text))
	minLen := t.MinTextLength
	maxLen := t.MaxTextLength
	if (minLen != nil && length < *minLen) || (maxLen != nil && length > *maxLen) {
		minStr := "0"
		if minLen != nil {
			minStr = itoa(*minLen)
		}
		maxStr := "∞"
		if maxLen != nil {
			maxStr = itoa(*maxLen)
		}
		v = append(v, &DocSpecsViolation{
			Rule: DocSpecsRuleTextLengthOut,
			Line: section.line,
			Message: "body text length " + itoa(length) + " is outside [" +
				minStr + ", " + maxStr + "]",
			SectionID: section.id,
		})
	}
	return v
}

func (val *DocSpecsValidator) validateFormat(
	section *docspecsNode, t *DocSpecsSectionType, v []*DocSpecsViolation,
) []*DocSpecsViolation {
	format := t.Format
	// Values a section table or list body gave a section the schema declares
	// no form for are virtual body lines, counted in its text (docspecsNode.text).
	if format == "" {
		return v
	}
	if form, ok := val.Schema.FormTypes[format]; ok {
		return val.validateForm(section, form, v)
	}
	fence := &MarkdownFenceTracker{}
	sawFence := false
	for _, raw := range section.body {
		fence.Feed(raw)
		if fence.InFence() {
			sawFence = true
		}
	}
	if !sawFence {
		v = append(v, &DocSpecsViolation{
			Rule: DocSpecsRuleFormatMismatch,
			Line: section.line,
			Message: "section format \"" + format + "\" demands a fenced code " +
				"block, but the body contains none",
			SectionID: section.id,
		})
	}
	return v
}

// docspecsOccurrence is one occurrence of a form field: its label, value and
// line, and whether a `Field:` label gave it.
type docspecsOccurrence struct {
	label     string
	value     string
	line      int
	fromLabel bool
}

// validateForm parses the section body in the DocSpecs plain-text form format
// (`FieldName: value`, case-insensitive labels, continuation lines) and its
// form tables (`TomSpecField | Value`), takes the values a section table or
// list body gave the section, and checks required fields + field
// pattern-checks. A field given twice keeps its first occurrence and reports
// the second (DocSpecsRuleMalformedBlock): a `Field:` label counts as given
// even with an empty value, a row only with a value. A row naming no field is
// DocSpecsRuleUnknownField.
func (val *DocSpecsValidator) validateForm(
	section *docspecsNode, form *DocSpecsFormType, v []*DocSpecsViolation,
) []*DocSpecsViolation {
	// Lowered name → field.
	byLower := map[string]*DocSpecsFormField{}
	for _, f := range form.Fields {
		byLower[strings.ToLower(f.Name)] = f
	}
	var occurrences []docspecsOccurrence
	fence := &MarkdownFenceTracker{}
	body := section.body
	lineOf := func(k int) int { return section.bodyStartLine() + k }
	current := ""
	haveCurrent := false
	currentLine := 0
	var currentLines []string
	flush := func() {
		if !haveCurrent {
			return
		}
		occurrences = append(occurrences, docspecsOccurrence{
			current, strings.TrimSpace(strings.Join(currentLines, "\n")), currentLine, true,
		})
		haveCurrent = false
		currentLines = nil
	}
	for i := 0; i < len(body); i++ {
		raw := body[i]
		if !fence.InFence() {
			if h := mdLayoutTableHeaderRE.FindStringSubmatch(raw); h != nil && h[1] == "" {
				// A form table ends the open field; its rows are fields.
				flush()
				var table docspecsTable
				table, v = docspecsReadTable(body, i, lineOf, section.id, v)
				for _, row := range table.rows {
					occurrences = append(occurrences, docspecsOccurrence{
						row.cells[0], docspecsCellValue(row.cells[1]), lineOf(row.index), false,
					})
				}
				i = table.end - 1
				continue
			}
			if m := mdFieldLabelRE.FindStringSubmatch(raw); m != nil {
				if field, ok := byLower[strings.ToLower(m[1])]; ok {
					flush()
					current = field.Name
					haveCurrent = true
					currentLine = lineOf(i)
					currentLines = []string{m[2]}
					fence.Feed(raw)
					continue
				}
			}
		}
		if haveCurrent {
			currentLines = append(currentLines, raw)
		}
		fence.Feed(raw)
	}
	flush()
	for _, value := range section.values {
		occurrences = append(occurrences, docspecsOccurrence{
			value.label, value.value, value.line, false,
		})
	}
	// Source order decides which occurrence is the first; values from a
	// parent's section table stand above the section's own body.
	sort.SliceStable(occurrences, func(a, b int) bool {
		return occurrences[a].line < occurrences[b].line
	})

	// Field name → value.
	values := map[string]string{}
	// Field name → 1-based line of the occurrence kept.
	fieldLines := map[string]int{}
	given := map[string]bool{}
	for _, o := range occurrences {
		field, ok := byLower[strings.ToLower(o.label)]
		if !ok {
			v = append(v, &DocSpecsViolation{
				Rule:      DocSpecsRuleUnknownField,
				Line:      o.line,
				Message:   "row \"" + o.label + "\" names no field of \"" + form.Name + "\"",
				SectionID: section.id,
			})
			continue
		}
		if !o.fromLabel && o.value == "" {
			continue
		}
		if given[field.Name] {
			v = append(v, &DocSpecsViolation{
				Rule:      DocSpecsRuleMalformedBlock,
				Line:      o.line,
				Message:   "field \"" + field.Name + "\" given twice",
				SectionID: section.id,
			})
			continue
		}
		given[field.Name] = true
		fieldLines[field.Name] = o.line
		if o.value != "" {
			values[field.Name] = o.value
		}
	}
	for _, field := range form.Fields {
		value := values[field.Name]
		if field.Required && value == "" {
			v = append(v, &DocSpecsViolation{
				Rule: DocSpecsRuleMissingRequiredField,
				Line: section.line,
				Message: "required form field \"" + field.Name + "\" of \"" +
					form.Name + "\" is missing",
				SectionID: section.id,
			})
			continue
		}
		if pc := field.PatternCheck; pc != nil && value != "" && !pc.Matches(value) {
			line := section.line
			if l, ok := fieldLines[field.Name]; ok {
				line = l
			}
			message := pc.ErrorMessage
			if message == "" {
				message = "form field \"" + field.Name + "\" does not match " +
					"pattern \"" + pc.Pattern + "\""
			}
			v = append(v, &DocSpecsViolation{
				Rule:      DocSpecsRuleFieldPatternMismatch,
				Line:      line,
				Message:   message,
				SectionID: section.id,
			})
		}
	}
	return v
}

// BindDocspecsMarkdown lands a DocSpecs markdown text in a typed SpecDocument
// via the SOM markdown codec — the "bind" entry point (SOM §14).
func BindDocspecsMarkdown(
	model *SpecModel, document *SpecDocument, text string,
) *SpecMarkdownResult {
	return NewSpecDocumentMarkdown(model, document).Parse(text)
}
