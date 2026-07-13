package somruntime

// docspecs_validator.go — DocSpecs markdown validation, a faithful port of
// `tom_som_typescript_runtime/src/docspecs_validator.ts` (itself a port of the
// JavaScript/Python/Dart chain, DR7/DR14/DR17 parity).
//
// Three cooperating pieces:
//
//  1. DocSpecsDocument — a schema-free structural parse of a DocSpecs markdown
//     document into a heading tree (fence-aware, never fails).
//  2. DocSpecsSchema — loader for `*.docspecs-schema.yaml` files with §7-style
//     warnings for unsupported keys (never fails on extra keys).
//  3. DocSpecsValidator — never-fail-fast validation of a parsed document
//     against a schema, emitting DocSpecsViolations whose messages are
//     golden-identical to the Dart implementation.
//
// Plus BindDocspecsMarkdown, which lands a DocSpecs markdown text in a typed
// SpecDocument via the SOM markdown codec.
//
// Go conventions (DR19): "" stands in for the other ports' null strings
// (DocSpecsViolation.SectionID/Path, DocSpecsSection.ID, …); optional ints are
// *int; the one throwing entry point (fromYamlText's "must be a YAML map")
// returns an error instead.

import (
	"regexp"
	"strings"
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
)

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
			if m := mdHeadingLineRE.FindStringSubmatch(line); m != nil {
				level := len(m[1])
				rest := m[2]
				var section *DocSpecsSection
				if c := mdHeadlineCommentRE.FindStringSubmatch(rest); c != nil {
					title := strings.TrimSpace(c[2])
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
	// Warnings holds §7 warnings for unsupported keys.
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
			schema.loadDocument(v)
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

func (s *DocSpecsSchema) loadDocument(node interface{}) {
	m, ok := node.(*YamlMap)
	if !ok {
		return
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
				if sRaw, ok := sections.GetOr(sKey).(*YamlMap); ok {
					if sRaw.Has("section-type") {
						sectionType = dvStr(sRaw.GetOr("section-type"))
					}
					optional = dvIsTrue(sRaw.GetOr("optional"))
				}
				s.DocumentSections[sKey] = &DocSpecsDocumentSection{
					SectionType: sectionType,
					Optional:    optional,
				}
				s.documentSectionOrder = append(s.documentSectionOrder, sKey)
			}
		} else if k != "name" && k != "description" {
			s.Warnings = append(s.Warnings, "unsupported document key \""+k+"\" ignored")
		}
	}
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
}

// NewDocSpecsValidator binds a schema to the validator.
func NewDocSpecsValidator(schema *DocSpecsSchema) *DocSpecsValidator {
	return &DocSpecsValidator{Schema: schema}
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
	v = val.validateDocumentSections(root, v)
	return v
}

func (val *DocSpecsValidator) resolveChild(
	section *DocSpecsSection, v []*DocSpecsViolation,
) (*DocSpecsSectionType, []*DocSpecsViolation) {
	if section.ID == "" {
		return nil, v // already reported as MALFORMED_HEADING by the parse.
	}
	t := val.Schema.ResolveSectionType(section.ID)
	if t == nil {
		v = append(v, &DocSpecsViolation{
			Rule: DocSpecsRuleUnknownSection,
			Line: section.Line,
			Message: "section id \"" + section.ID + "\" resolves to no " +
				"section-type of the schema",
			SectionID: section.ID,
		})
	}
	return t, v
}

func (val *DocSpecsValidator) validateDocumentSections(
	root *DocSpecsSection, v []*DocSpecsViolation,
) []*DocSpecsViolation {
	// Occurrences per section-type name.
	counts := map[string]int{}
	slotTypes := map[string]bool{}
	for _, slot := range val.Schema.DocumentSections {
		slotTypes[slot.SectionType] = true
	}
	for _, child := range root.Children {
		var t *DocSpecsSectionType
		t, v = val.resolveChild(child, v)
		if t == nil {
			continue
		}
		if !slotTypes[t.Name] {
			v = append(v, &DocSpecsViolation{
				Rule: DocSpecsRuleUnknownSection,
				Line: child.Line,
				Message: "section-type \"" + t.Name + "\" is not a top-level " +
					"document section",
				SectionID: child.ID,
			})
			continue
		}
		counts[t.Name]++
		v = val.validateSection(child, t, v)
	}
	for _, slotKey := range val.Schema.documentSectionOrder {
		slot := val.Schema.DocumentSections[slotKey]
		if !slot.Optional && counts[slot.SectionType] == 0 {
			v = append(v, &DocSpecsViolation{
				Rule: DocSpecsRuleMissingRequiredSection,
				Line: root.Line,
				Message: "required document section \"" + slotKey + "\" (type \"" +
					slot.SectionType + "\") is missing",
				SectionID: slotKey,
			})
		}
	}
	return v
}

func (val *DocSpecsValidator) validateSection(
	section *DocSpecsSection, t *DocSpecsSectionType, v []*DocSpecsViolation,
) []*DocSpecsViolation {
	if pc := t.PatternCheck; pc != nil && section.ID != "" && !pc.Matches(section.ID) {
		message := pc.ErrorMessage
		if message == "" {
			message = "section id \"" + section.ID + "\" does not match pattern \"" +
				pc.Pattern + "\""
		}
		v = append(v, &DocSpecsViolation{
			Rule:      DocSpecsRuleIDPatternMismatch,
			Line:      section.Line,
			Message:   message,
			SectionID: section.ID,
		})
	}
	v = val.validateText(section, t, v)
	v = val.validateFormat(section, t, v)
	// Occurrences per subsection type name.
	counts := map[string]int{}
	for _, child := range section.Children {
		var childType *DocSpecsSectionType
		childType, v = val.resolveChild(child, v)
		if childType == nil {
			continue
		}
		if _, ok := t.SubsectionTypes[childType.Name]; !ok {
			v = append(v, &DocSpecsViolation{
				Rule: DocSpecsRuleUnknownSection,
				Line: child.Line,
				Message: "section-type \"" + childType.Name + "\" is not an " +
					"allowed subsection of \"" + t.Name + "\"",
				SectionID: child.ID,
			})
			continue
		}
		counts[childType.Name]++
		v = val.validateSection(child, childType, v)
	}
	for _, subKey := range t.subsectionOrder {
		rule := t.SubsectionTypes[subKey]
		count := counts[subKey]
		if count < rule.MinCount {
			if count == 0 {
				v = append(v, &DocSpecsViolation{
					Rule: DocSpecsRuleMissingRequiredSection,
					Line: section.Line,
					Message: "required subsection \"" + subKey + "\" of \"" +
						t.Name + "\" is missing",
					SectionID: subKey,
				})
			} else {
				v = append(v, &DocSpecsViolation{
					Rule: DocSpecsRuleTooFewItems,
					Line: section.Line,
					Message: "subsection \"" + subKey + "\" occurs " + itoa(count) +
						" time(s), minimum is " + itoa(rule.MinCount),
					SectionID: subKey,
				})
			}
		}
		if rule.MaxCount != nil && count > *rule.MaxCount {
			v = append(v, &DocSpecsViolation{
				Rule: DocSpecsRuleTooManyItems,
				Line: section.Line,
				Message: "subsection \"" + subKey + "\" occurs " + itoa(count) +
					" time(s), maximum is " + itoa(*rule.MaxCount),
				SectionID: subKey,
			})
		}
	}
	return v
}

func (val *DocSpecsValidator) validateText(
	section *DocSpecsSection, t *DocSpecsSectionType, v []*DocSpecsViolation,
) []*DocSpecsViolation {
	if t.Format != "" {
		if _, ok := val.Schema.FormTypes[t.Format]; ok {
			return v // form sections carry fields, not body text.
		}
	}
	text := section.Text()
	if t.TextRequired && len(text) == 0 {
		v = append(v, &DocSpecsViolation{
			Rule:      DocSpecsRuleTextRequired,
			Line:      section.Line,
			Message:   "section requires body text but has none",
			SectionID: section.ID,
		})
		return v
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
			Line: section.Line,
			Message: "body text length " + itoa(length) + " is outside [" +
				minStr + ", " + maxStr + "]",
			SectionID: section.ID,
		})
	}
	return v
}

func (val *DocSpecsValidator) validateFormat(
	section *DocSpecsSection, t *DocSpecsSectionType, v []*DocSpecsViolation,
) []*DocSpecsViolation {
	format := t.Format
	if format == "" {
		return v
	}
	if form, ok := val.Schema.FormTypes[format]; ok {
		return val.validateForm(section, form, v)
	}
	fence := &MarkdownFenceTracker{}
	sawFence := false
	for _, raw := range section.BodyLines {
		fence.Feed(raw)
		if fence.InFence() {
			sawFence = true
		}
	}
	if !sawFence {
		v = append(v, &DocSpecsViolation{
			Rule: DocSpecsRuleFormatMismatch,
			Line: section.Line,
			Message: "section format \"" + format + "\" demands a fenced code " +
				"block, but the body contains none",
			SectionID: section.ID,
		})
	}
	return v
}

func (val *DocSpecsValidator) validateForm(
	section *DocSpecsSection, form *DocSpecsFormType, v []*DocSpecsViolation,
) []*DocSpecsViolation {
	// Lowered name → field.
	byLower := map[string]*DocSpecsFormField{}
	for _, f := range form.Fields {
		byLower[strings.ToLower(f.Name)] = f
	}
	// Field name → collected value lines.
	values := map[string][]string{}
	// Field name → 1-based label line.
	fieldLines := map[string]int{}
	fence := &MarkdownFenceTracker{}
	current := ""
	haveCurrent := false
	for i, raw := range section.BodyLines {
		if !fence.InFence() {
			if m := mdFieldLabelRE.FindStringSubmatch(raw); m != nil {
				if field, ok := byLower[strings.ToLower(m[1])]; ok {
					current = field.Name
					haveCurrent = true
					values[current] = []string{m[2]}
					fieldLines[current] = section.BodyStartLine() + i
					fence.Feed(raw)
					continue
				}
			}
		}
		if haveCurrent {
			values[current] = append(values[current], raw)
		}
		fence.Feed(raw)
	}
	for _, field := range form.Fields {
		value := ""
		if collected, ok := values[field.Name]; ok {
			value = strings.TrimSpace(strings.Join(collected, "\n"))
		}
		if field.Required && value == "" {
			v = append(v, &DocSpecsViolation{
				Rule: DocSpecsRuleMissingRequiredField,
				Line: section.Line,
				Message: "required form field \"" + field.Name + "\" of \"" +
					form.Name + "\" is missing",
				SectionID: section.ID,
			})
			continue
		}
		if pc := field.PatternCheck; pc != nil && value != "" && !pc.Matches(value) {
			line := section.Line
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
				SectionID: section.ID,
			})
		}
	}
	return v
}

// BindDocspecsMarkdown lands a DocSpecs markdown text in a typed SpecDocument
// via the SOM markdown codec — the DR7 "bind" entry point.
func BindDocspecsMarkdown(
	model *SpecModel, document *SpecDocument, text string,
) *SpecMarkdownResult {
	return NewSpecDocumentMarkdown(model, document).Parse(text)
}
