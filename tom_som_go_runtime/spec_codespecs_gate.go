// The Phase-4 mechanical gate — Stage A of `codespecs_prompt.md` §4, all five
// checks run as one, over (model, document, catalogue, schema) — a port of
// `tom_som_dart_runtime/lib/src/spec_codespecs_gate.dart`, together with the
// catalogue's gate tables (`CodeSpecsFieldRef`, `CodeSpecsRequiredArgument`,
// `CodeSpecsCarrier`) read from its optional `gate` key.
//
// Every check runs; none stops the others. A project fixing one wants to see the
// rest, and a gate that stopped at the first failure would report a different
// set of problems on every run (`codespecs_prompt.md` §4).
//
// A check that could not run is reported as **not run**, with its reason, and
// the gate does not pass: a skipped check must never read as a passed one.

package somruntime

import (
	"bytes"
	"encoding/json"
	"fmt"
	"strconv"
	"strings"
)

// --- the catalogue's gate tables ---------------------------------------------

// CodeSpecsFieldRef is a SOM field a gate table names: a class, one of its
// members, and the form field when the value is one field of a `@Form` section.
type CodeSpecsFieldRef struct {
	// ClassName is the model class.
	ClassName string
	// Member is the member of ClassName.
	Member string
	// FormField is the form field of Member; "" (this port's stand-in for the
	// reference's null) for a whole-member value.
	FormField string
}

// Source is `Class.member` or `Class.member.formField` — how findings name it.
func (r *CodeSpecsFieldRef) Source() string {
	if r.FormField == "" {
		return r.ClassName + "." + r.Member
	}
	return r.ClassName + "." + r.Member + "." + r.FormField
}

// CodeSpecsRequiredArgument is one A4 obligation (`codespecs_prompt.md` §4.4):
// a required `Cs*` marker argument and the stored SOM field it derives from.
type CodeSpecsRequiredArgument struct {
	// Area is the area whose extract makes the obligation apply.
	Area string
	// Marker is the marker, `@CsTable`.
	Marker string
	// Argument is the required argument, `table`.
	Argument string
	// Field is the SOM field the argument derives from.
	Field CodeSpecsFieldRef
	// ResolvesTo, when set, is where the value must also equal a value the run
	// carries — the `domainEnum` → `DMENE` case of §4.4.
	ResolvesTo *CodeSpecsFieldRef
	// When, when set, holds an instance to the row only if it carries this
	// field with the value WhenEquals — the obligation sits on a `@Case`.
	When *CodeSpecsFieldRef
	// WhenEquals is the value When must hold; meaningful only when When is set.
	WhenEquals string
}

// ClassName is the source field's class.
func (o *CodeSpecsRequiredArgument) ClassName() string { return o.Field.ClassName }

// Member is the source field's member.
func (o *CodeSpecsRequiredArgument) Member() string { return o.Field.Member }

// FormField is the source field's form field ("" for none).
func (o *CodeSpecsRequiredArgument) FormField() string { return o.Field.FormField }

// Source is the source field, as findings name it.
func (o *CodeSpecsRequiredArgument) Source() string { return o.Field.Source() }

// CodeSpecsCarrier is one A5 carrier (`codespecs_prompt.md` §4.5): a structured
// field the model must keep offering.
type CodeSpecsCarrier struct {
	// Field is the field.
	Field CodeSpecsFieldRef
	// IntroducedBy is the document section that introduced it, for the finding.
	IntroducedBy string
}

// ClassName is the carrier's class.
func (c *CodeSpecsCarrier) ClassName() string { return c.Field.ClassName }

// Member is the carrier's member.
func (c *CodeSpecsCarrier) Member() string { return c.Field.Member }

// FormField is the carrier's form field ("" for none).
func (c *CodeSpecsCarrier) FormField() string { return c.Field.FormField }

// Source is the carrier, as findings name it.
func (c *CodeSpecsCarrier) Source() string { return c.Field.Source() }

// codeSpecsGateJSON is the catalogue's `gate` block. Rows are kept as
// key-ordered objects so a malformed row can be named the way the reference
// names it.
type codeSpecsGateJSON struct {
	RequiredArguments []*codeSpecsRow `json:"requiredArguments"`
	Carriers          []*codeSpecsRow `json:"carriers"`
}

// codeSpecsRow is one JSON object with its keys in document order — the
// reference's row label lists the keys a row carries in that order, which a Go
// map cannot recall.
type codeSpecsRow struct {
	keys []string
	vals map[string]json.RawMessage
}

func (r *codeSpecsRow) UnmarshalJSON(data []byte) error {
	dec := json.NewDecoder(bytes.NewReader(data))
	tok, err := dec.Token()
	if err != nil {
		return err
	}
	if d, ok := tok.(json.Delim); !ok || d != '{' {
		return fmt.Errorf("CodeSpecs area catalogue: a gate row is not an object")
	}
	r.vals = map[string]json.RawMessage{}
	for dec.More() {
		kt, err := dec.Token()
		if err != nil {
			return err
		}
		key, _ := kt.(string)
		var v json.RawMessage
		if err := dec.Decode(&v); err != nil {
			return err
		}
		if _, seen := r.vals[key]; !seen {
			r.keys = append(r.keys, key)
		}
		r.vals[key] = v
	}
	_, err = dec.Token()
	return err
}

// raw returns the value at key, or nil when the key is absent or null.
func (r *codeSpecsRow) raw(key string) json.RawMessage {
	v, ok := r.vals[key]
	if !ok || string(bytes.TrimSpace(v)) == "null" {
		return nil
	}
	return v
}

// str returns the string at key; ok is false when the key is absent, null or
// not a string.
func (r *codeSpecsRow) str(key string) (string, bool) {
	v := r.raw(key)
	if v == nil {
		return "", false
	}
	var s string
	if err := json.Unmarshal(v, &s); err != nil {
		return "", false
	}
	return s, true
}

// object returns the nested object at key, or nil when absent or null.
func (r *codeSpecsRow) object(key string) (*codeSpecsRow, error) {
	v := r.raw(key)
	if v == nil {
		return nil, nil
	}
	out := &codeSpecsRow{}
	if err := json.Unmarshal(v, out); err != nil {
		return nil, err
	}
	return out, nil
}

// codeSpecsRowLabel names a row for an error message: the first non-empty
// preferred key, else the keys the row carries.
func codeSpecsRowLabel(r *codeSpecsRow, preferred []string) string {
	for _, key := range preferred {
		if v, ok := r.str(key); ok && v != "" {
			return key + ` "` + v + `"`
		}
	}
	if len(r.keys) == 0 {
		return "an empty row"
	}
	return "the row with keys [" + strings.Join(r.keys, ", ") + "]"
}

// codeSpecsRequiredString is a required non-empty string key of a row.
func codeSpecsRequiredString(r *codeSpecsRow, key, owner string) (string, error) {
	if v, ok := r.str(key); ok && v != "" {
		return v, nil
	}
	got := "absent"
	if v := r.raw(key); v != nil {
		got = string(bytes.TrimSpace(v))
	}
	return "", fmt.Errorf(
		"CodeSpecs area catalogue: %s is missing a non-empty %q (got %s)",
		owner, key, got)
}

// codeSpecsRequiredInt is a required numeric key of a row — the reference's
// `_requiredInt`. Any JSON number is accepted and truncated to an int (the
// reference's `num.toInt()`); anything else, a numeric string included, fails
// naming the row.
func codeSpecsRequiredInt(r *codeSpecsRow, key, owner string) (int, error) {
	if v := r.raw(key); v != nil {
		var n float64
		if err := json.Unmarshal(v, &n); err == nil {
			return int(n), nil
		}
	}
	return 0, fmt.Errorf(
		"CodeSpecs area catalogue: %s is missing a numeric %q (got %s)",
		owner, key, codeSpecsDescribe(r.raw(key)))
}

// codeSpecsDescribe renders a rejected value for an error message, after the
// reference's `_describe`: `absent` for a missing or null key, else the value
// prefixed with its JSON type — `String "2"`, `int 2`, `double 2.5`, `bool
// true`, `List [...]`, `Map {...}` — so "3" and 3 are distinguishable.
func codeSpecsDescribe(v json.RawMessage) string {
	if v == nil {
		return "absent"
	}
	t := bytes.TrimSpace(v)
	if len(t) == 0 {
		return "absent"
	}
	switch t[0] {
	case '"':
		return "String " + string(t)
	case 't', 'f':
		return "bool " + strconv.Quote(string(t))
	case '[':
		return "List " + strconv.Quote(string(t))
	case '{':
		return "Map " + strconv.Quote(string(t))
	}
	if bytes.ContainsAny(t, ".eE") {
		return "double " + strconv.Quote(string(t))
	}
	return "int " + strconv.Quote(string(t))
}

// codeSpecsFieldRefFromRow reads one reference; `className` and `member` are
// required, `formField` is optional.
func codeSpecsFieldRefFromRow(r *codeSpecsRow) (CodeSpecsFieldRef, error) {
	label := codeSpecsRowLabel(r, []string{"className", "member"})
	cls, err := codeSpecsRequiredString(r, "className", label)
	if err != nil {
		return CodeSpecsFieldRef{}, err
	}
	member, err := codeSpecsRequiredString(r, "member", label)
	if err != nil {
		return CodeSpecsFieldRef{}, err
	}
	ff := ""
	if v := r.raw("formField"); v != nil {
		s, ok := r.str("formField")
		if !ok {
			return CodeSpecsFieldRef{}, fmt.Errorf(
				"CodeSpecs area catalogue: %s has a non-string \"formField\"", label)
		}
		ff = s
	}
	return CodeSpecsFieldRef{ClassName: cls, Member: member, FormField: ff}, nil
}

// codeSpecsRequiredArgumentFromRow reads one row of `gate.requiredArguments`.
func codeSpecsRequiredArgumentFromRow(r *codeSpecsRow) (*CodeSpecsRequiredArgument, error) {
	label := codeSpecsRowLabel(r, []string{"marker", "argument", "area"})
	o := &CodeSpecsRequiredArgument{}
	var err error
	if o.Area, err = codeSpecsRequiredString(r, "area", label); err != nil {
		return nil, err
	}
	if o.Marker, err = codeSpecsRequiredString(r, "marker", label); err != nil {
		return nil, err
	}
	if o.Argument, err = codeSpecsRequiredString(r, "argument", label); err != nil {
		return nil, err
	}
	if o.Field, err = codeSpecsFieldRefFromRow(r); err != nil {
		return nil, err
	}
	resolves, err := r.object("resolvesTo")
	if err != nil {
		return nil, err
	}
	if resolves != nil {
		ref, err := codeSpecsFieldRefFromRow(resolves)
		if err != nil {
			return nil, err
		}
		o.ResolvesTo = &ref
	}
	when, err := r.object("when")
	if err != nil {
		return nil, err
	}
	if when != nil {
		ref, err := codeSpecsFieldRefFromRow(when)
		if err != nil {
			return nil, err
		}
		o.When = &ref
		if o.WhenEquals, err = codeSpecsRequiredString(when, "equals", label); err != nil {
			return nil, err
		}
	}
	return o, nil
}

// readGateTables fills the gate tables from the catalogue's `gate` block; a nil
// block (absent or null) leaves the catalogue without them.
func (c *CodeSpecsAreaCatalog) readGateTables(gate *codeSpecsGateJSON) error {
	c.RequiredArguments = []*CodeSpecsRequiredArgument{}
	c.Carriers = []*CodeSpecsCarrier{}
	c.HasGateTables = gate != nil
	if gate == nil {
		return nil
	}
	for _, row := range gate.RequiredArguments {
		o, err := codeSpecsRequiredArgumentFromRow(row)
		if err != nil {
			return err
		}
		c.RequiredArguments = append(c.RequiredArguments, o)
	}
	for _, row := range gate.Carriers {
		ref, err := codeSpecsFieldRefFromRow(row)
		if err != nil {
			return err
		}
		introducedBy, _ := row.str("introducedBy")
		c.Carriers = append(c.Carriers, &CodeSpecsCarrier{Field: ref, IntroducedBy: introducedBy})
	}
	return nil
}

// --- the gate ------------------------------------------------------------------

// CodeSpecsGateCheck is one of the five Stage-A checks. Its value is the
// reference's enum name, `a1` … `a5`.
type CodeSpecsGateCheck string

const (
	// CodeSpecsGateA1 — the document is complete against its DocSpecs schema.
	CodeSpecsGateA1 CodeSpecsGateCheck = "a1"
	// CodeSpecsGateA2 — the document's values are valid (ValidateDocument).
	CodeSpecsGateA2 CodeSpecsGateCheck = "a2"
	// CodeSpecsGateA3 — every section the walk reaches carries a routing
	// verdict (ROUTE-TOTAL).
	CodeSpecsGateA3 CodeSpecsGateCheck = "a3"
	// CodeSpecsGateA4 — every required marker argument of a used area has a
	// populated source.
	CodeSpecsGateA4 CodeSpecsGateCheck = "a4"
	// CodeSpecsGateA5 — the model still offers every structured carrier.
	CodeSpecsGateA5 CodeSpecsGateCheck = "a5"
)

// Label is `A1` … `A5`, as `codespecs_prompt.md` §4 names them.
func (c CodeSpecsGateCheck) Label() string { return strings.ToUpper(string(c)) }

// CodeSpecsGateFinding is one thing a check found wrong.
type CodeSpecsGateFinding struct {
	// Check is the check that found it.
	Check CodeSpecsGateCheck
	// Code is what kind of finding — the DocSpecs rule (A1), the validation
	// code (A2), `unrouted` / `root` (A3), `missingSource` /
	// `unresolvedReference` (A4), `missingCarrier` (A5).
	Code string
	// Location is where: a section id or document path (A1–A4), or the carrier
	// `Class.member[.formField]` (A5).
	Location string
	// Message is one sentence a user acts on.
	Message string
}

func (f CodeSpecsGateFinding) String() string {
	return f.Check.Label() + " " + f.Code + " " + f.Location + ": " + f.Message
}

// CodeSpecsGateCheckResult is one check's outcome.
type CodeSpecsGateCheckResult struct {
	// Check is which check.
	Check CodeSpecsGateCheck
	// Ran reports whether it ran. A check that did not run never passes.
	Ran bool
	// NotRunReason is why it did not run; "" when it ran.
	NotRunReason string
	// Findings is what it found, in the order found.
	Findings []CodeSpecsGateFinding
}

// Passed reports that the check ran and found nothing.
func (r *CodeSpecsGateCheckResult) Passed() bool { return r.Ran && len(r.Findings) == 0 }

// CodeSpecsGateReport is the gate's report: one result per check, A1 to A5.
type CodeSpecsGateReport struct {
	// Results are the five results, in check order.
	Results []*CodeSpecsGateCheckResult
	// Extracts are the extraction run's extracts, when A3 passed (A4 reads
	// them; Stage B is handed them). nil when the walk could not complete.
	Extracts []*CodeSpecsExtract
}

// Result returns the result of check, or nil.
func (r *CodeSpecsGateReport) Result(check CodeSpecsGateCheck) *CodeSpecsGateCheckResult {
	for _, res := range r.Results {
		if res.Check == check {
			return res
		}
	}
	return nil
}

// Passed reports that every check ran and found nothing — the run may begin.
func (r *CodeSpecsGateReport) Passed() bool {
	for _, res := range r.Results {
		if !res.Passed() {
			return false
		}
	}
	return true
}

// Findings returns every finding, in check order.
func (r *CodeSpecsGateReport) Findings() []CodeSpecsGateFinding {
	out := []CodeSpecsGateFinding{}
	for _, res := range r.Results {
		out = append(out, res.Findings...)
	}
	return out
}

// CodeSpecsGate is Stage A of `codespecs_prompt.md` §4.
type CodeSpecsGate struct {
	// Model is the resolved object model.
	Model *SpecModel
	// Document is the document under Phase 4.
	Document *SpecDocument
	// Catalog is the area catalogue — its gate tables drive A4 and A5.
	Catalog *CodeSpecsAreaCatalog
	// Schema is the DocSpecs schema of the document's root; A1 does not run
	// without it (nil).
	Schema *DocSpecsSchema
	// RootType is the document root to walk — type name or section id; ""
	// defaults to the document's single populated root, as the extractor does.
	RootType string
}

// NewCodeSpecsGate holds the inputs; Run does the work. schema may be nil and
// rootType "" (omitted).
func NewCodeSpecsGate(
	model *SpecModel,
	document *SpecDocument,
	catalog *CodeSpecsAreaCatalog,
	schema *DocSpecsSchema,
	rootType string,
) *CodeSpecsGate {
	return &CodeSpecsGate{
		Model:    model,
		Document: document,
		Catalog:  catalog,
		Schema:   schema,
		RootType: rootType,
	}
}

const (
	codeSpecsGateNoTablesReason = "the catalogue carries no gate tables (written before " +
		"`codespecs_prompt.md` §4.4/§4.5 were transcribed)"
	codeSpecsGateNoExtractsReason = "A3 did not complete, so there is no extraction run to read " +
		"the used areas from"
)

// Run runs all five checks.
//
// The error is what the reference raises out of `run()` rather than reporting
// as a finding: A1's Markdown render failing (an ambiguous or unknown root), or
// the extraction itself failing after A3 found nothing unrouted.
func (g *CodeSpecsGate) Run() (*CodeSpecsGateReport, error) {
	a1, err := g.a1()
	if err != nil {
		return nil, err
	}
	a2 := g.a2()
	a3, extracts, err := g.a3()
	if err != nil {
		return nil, err
	}
	var a4 *CodeSpecsGateCheckResult
	switch {
	case !g.Catalog.HasGateTables:
		a4 = codeSpecsGateNotRun(CodeSpecsGateA4, codeSpecsGateNoTablesReason)
	case extracts == nil:
		a4 = codeSpecsGateNotRun(CodeSpecsGateA4, codeSpecsGateNoExtractsReason)
	default:
		a4 = g.a4(extracts)
	}
	var a5 *CodeSpecsGateCheckResult
	if g.Catalog.HasGateTables {
		a5 = g.a5()
	} else {
		a5 = codeSpecsGateNotRun(CodeSpecsGateA5, codeSpecsGateNoTablesReason)
	}
	return &CodeSpecsGateReport{
		Results:  []*CodeSpecsGateCheckResult{a1, a2, a3, a4, a5},
		Extracts: extracts,
	}, nil
}

func codeSpecsGateNotRun(check CodeSpecsGateCheck, reason string) *CodeSpecsGateCheckResult {
	return &CodeSpecsGateCheckResult{
		Check:        check,
		Ran:          false,
		NotRunReason: reason,
		Findings:     []CodeSpecsGateFinding{},
	}
}

func codeSpecsGateRan(check CodeSpecsGateCheck, findings []CodeSpecsGateFinding) *CodeSpecsGateCheckResult {
	if findings == nil {
		findings = []CodeSpecsGateFinding{}
	}
	return &CodeSpecsGateCheckResult{Check: check, Ran: true, Findings: findings}
}

func (g *CodeSpecsGate) a1() (*CodeSpecsGateCheckResult, error) {
	if g.Schema == nil {
		return codeSpecsGateNotRun(CodeSpecsGateA1, "no DocSpecs schema was supplied"), nil
	}
	markdown, err := g.Document.ToMarkdown(g.Model, g.RootType)
	if err != nil {
		return nil, err
	}
	findings := []CodeSpecsGateFinding{}
	for _, v := range NewDocSpecsValidator(g.Schema).ValidateMarkdown(markdown) {
		location := v.SectionID
		if location == "" {
			location = v.Path
		}
		if location == "" {
			location = "line " + itoa(v.Line)
		}
		findings = append(findings, CodeSpecsGateFinding{
			Check:    CodeSpecsGateA1,
			Code:     v.Rule,
			Location: location,
			Message:  "line " + itoa(v.Line) + ": " + v.Message,
		})
	}
	return codeSpecsGateRan(CodeSpecsGateA1, findings), nil
}

func (g *CodeSpecsGate) a2() *CodeSpecsGateCheckResult {
	findings := []CodeSpecsGateFinding{}
	for _, e := range ValidateDocument(g.Model, g.Document) {
		findings = append(findings, CodeSpecsGateFinding{
			Check:    CodeSpecsGateA2,
			Code:     e.Code,
			Location: e.Path,
			Message:  e.Message,
		})
	}
	return codeSpecsGateRan(CodeSpecsGateA2, findings)
}

// a3 collects **every** unrouted class over the non-strict walk, rather than
// the first one the strict walk fails on; only when there is none does it run
// the extraction itself.
func (g *CodeSpecsGate) a3() (*CodeSpecsGateCheckResult, []*CodeSpecsExtract, error) {
	extractor, err := NewCodeSpecsExtractor(g.Model, g.Document, g.Catalog, g.RootType)
	if err != nil {
		path, message := "", err.Error()
		if xe, ok := err.(*CodeSpecsExtractError); ok {
			path, message = xe.Path, xe.Message
		}
		return codeSpecsGateRan(CodeSpecsGateA3, []CodeSpecsGateFinding{{
			Check:    CodeSpecsGateA3,
			Code:     "root",
			Location: path,
			Message:  message,
		}}), nil, nil
	}
	unrouted := []CodeSpecsGateFinding{}
	for _, r := range extractor.Routings() {
		if r.Verdict != CodeSpecsVerdictUnrouted {
			continue
		}
		unrouted = append(unrouted, CodeSpecsGateFinding{
			Check:    CodeSpecsGateA3,
			Code:     "unrouted",
			Location: r.Path,
			Message: r.ClassName + " carries no @CodeSpecKind, @FollowUpKind or " +
				"@NoArtifact — its content would reach no extract",
		})
	}
	if len(unrouted) > 0 {
		return codeSpecsGateRan(CodeSpecsGateA3, unrouted), nil, nil
	}
	extracts, err := extractor.ExtractAll()
	if err != nil {
		// The strict walk is the same walk the non-strict one just found
		// nothing unrouted in; the reference lets a failure here escape `run()`.
		return nil, nil, err
	}
	return codeSpecsGateRan(CodeSpecsGateA3, nil), extracts, nil
}

// a4 runs over the extraction run: for each obligation whose area's extract is
// non-empty, every instance of the obligation's class that the extract carries
// must carry the source value, populated (non-blank); a ResolvesTo obligation's
// value must also equal a value the run carries at the target.
func (g *CodeSpecsGate) a4(extracts []*CodeSpecsExtract) *CodeSpecsGateCheckResult {
	findings := []CodeSpecsGateFinding{}
	all := []CodeSpecsExtractEntry{}
	for _, x := range extracts {
		all = append(all, x.Entries...)
	}
	for _, o := range g.Catalog.RequiredArguments {
		var extract *CodeSpecsExtract
		for _, x := range extracts {
			if x.Area.Code == o.Area {
				extract = x
				break
			}
		}
		if extract == nil || len(extract.Entries) == 0 {
			continue
		}
		// The instances the extract carries of the obligation's class, in
		// document order, each with the populated source value it holds
		// (nil = none yet).
		order := []string{}
		instances := map[string]*string{}
		applies := map[string]bool{}
		when := o.When
		for _, e := range extract.Entries {
			if e.ClassName != o.Field.ClassName {
				continue
			}
			instance := codeSpecsParentPath(e.Path)
			if _, seen := instances[instance]; !seen {
				instances[instance] = nil
				order = append(order, instance)
			}
			if when != nil &&
				e.FieldName == when.Member &&
				e.FormField == when.FormField &&
				e.Value == o.WhenEquals {
				applies[instance] = true
			}
			if e.FieldName == o.Field.Member &&
				e.FormField == o.Field.FormField &&
				strings.TrimSpace(e.Value) != "" {
				v := e.Value
				instances[instance] = &v
			}
		}
		for _, instance := range order {
			value := instances[instance]
			if when != nil && !applies[instance] {
				continue
			}
			if value == nil {
				findings = append(findings, CodeSpecsGateFinding{
					Check:    CodeSpecsGateA4,
					Code:     "missingSource",
					Location: instance,
					Message: o.Marker + "." + o.Argument + " (" + o.Area + ") is required, and " +
						"its source " + o.Source() + " is empty here",
				})
				continue
			}
			target := o.ResolvesTo
			if target == nil {
				continue
			}
			known := false
			for _, e := range all {
				if e.ClassName == target.ClassName &&
					e.FieldName == target.Member &&
					e.FormField == target.FormField &&
					e.Value == *value {
					known = true
					break
				}
			}
			if !known {
				findings = append(findings, CodeSpecsGateFinding{
					Check:    CodeSpecsGateA4,
					Code:     "unresolvedReference",
					Location: instance,
					Message: o.Source() + " names `" + *value + "`, which no " + target.Source() +
						" in this document carries — " + o.Marker + "." + o.Argument +
						" (" + o.Area + ") has nothing to resolve against",
				})
			}
		}
	}
	return codeSpecsGateRan(CodeSpecsGateA4, findings)
}

// a5 runs against the model, not the document: each carrier's class, member
// and form field must still exist.
func (g *CodeSpecsGate) a5() *CodeSpecsGateCheckResult {
	findings := []CodeSpecsGateFinding{}
	for _, c := range g.Catalog.Carriers {
		present := false
		if cls := g.Model.ClassNamed(c.Field.ClassName); cls != nil {
			if field := cls.FieldNamed(c.Field.Member); field != nil {
				if c.Field.FormField == "" {
					present = true
				} else {
					for _, ff := range field.FormFields {
						if ff.Name == c.Field.FormField {
							present = true
							break
						}
					}
				}
			}
		}
		if !present {
			findings = append(findings, CodeSpecsGateFinding{
				Check:    CodeSpecsGateA5,
				Code:     "missingCarrier",
				Location: c.Source(),
				Message: "the model no longer offers " + c.Source() + " (" + c.IntroducedBy +
					") — a project with that structured fact would have to write prose again",
			})
		}
	}
	return codeSpecsGateRan(CodeSpecsGateA5, findings)
}

func codeSpecsParentPath(path string) string {
	i := strings.LastIndex(path, "/")
	if i < 0 {
		return ""
	}
	return path[:i]
}
