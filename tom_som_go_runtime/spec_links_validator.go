package somruntime

// spec_links_validator.go — the link checks of one document
// (`tom_specs_model_rules.md` §9.7): ValidateLinks holds a document's values to
// the link annotations of the model — derived values to their sources,
// summaries to their detail lists, each end of a link to the other, the ids
// named in a text to the link rows, and a `@SameAs` copy to its holder. A port
// of `tom_som_dart_runtime/lib/src/spec_links_validator.dart` (and the
// TypeScript, JavaScript and Python `spec_links_validator` modules).
//
// Values are read in their reviewed state: a value holding pending change
// marks is read with every mark rejected, and listed as `linkValuePending`. A
// `@SummaryOf` naming another document is skipped here; the document set
// checks it.

import (
	"math"
	"regexp"
	"sort"
	"strconv"
	"strings"
	"unicode"
)

// ValidateLinks runs the link checks of doc against model; the findings sorted
// by path, then by code (declaration order), then by message.
func ValidateLinks(model *SpecModel, doc *SpecDocument) []SpecValidationError {
	v := NewSpecLinkValidator(model, doc, false)
	v.Run()
	errors := append([]SpecValidationError{}, v.Errors...)
	sort.SliceStable(errors, func(i, j int) bool {
		a, b := errors[i], errors[j]
		if a.Path != b.Path {
			return a.Path < b.Path
		}
		if ai, bi := SpecValidationCodeIndex(a.Code), SpecValidationCodeIndex(b.Code); ai != bi {
			return ai < bi
		}
		return a.Message < b.Message
	})
	return errors
}

// SpecExpandPattern returns every concrete path of pattern in doc: each
// `<list>-*` segment expanded over the document's items.
func SpecExpandPattern(doc *SpecDocument, pattern string) []string {
	paths := []string{""}
	for _, seg := range strings.Split(pattern, "/") {
		var next []string
		for _, p := range paths {
			base := seg
			if p != "" {
				base = p + "/" + seg
			}
			if strings.HasSuffix(seg, "-*") {
				next = append(next, doc.ListItems(base[:len(base)-2])...)
			} else {
				next = append(next, base)
			}
		}
		paths = next
	}
	return paths
}

// SpecResolvePlaceAt returns place resolved under anchor, or nil when it does
// not resolve.
func SpecResolvePlaceAt(refl *SpecReflection, place, anchor string) *SpecPlaceResolution {
	p, err := ParseSpecPlace(place)
	if err != nil {
		return nil
	}
	r, err := p.Resolve(refl, anchor)
	if err != nil {
		return nil
	}
	return r
}

// SpecResolveLinkPlace returns place resolved for a link annotated at anchor,
// as the link checks and the rendition's `linked` marker (SOM §11.11) read it:
// a `./` place beneath the nearest list element of anchor; any other place
// inside anchor's subtree when it is there, else anywhere beneath the document
// root root — a bare id wherever it is reached once, a `/` path from the
// section its first segment names, through the first item doc holds of a list
// there (doc nil: such a path does not resolve). nil when it does not resolve.
func SpecResolveLinkPlace(refl *SpecReflection, doc *SpecDocument, place, root, anchor string) *SpecPlaceResolution {
	if strings.HasPrefix(place, "./") {
		return SpecResolvePlaceAt(refl, place, anchor)
	}
	// The grammar's own scope first: the subtree of the annotated section.
	if anchor != root {
		if local := SpecResolvePlaceAt(refl, place, anchor); local != nil {
			return local
		}
	}
	slash := strings.Index(place, "/")
	if slash < 0 {
		return SpecResolvePlaceAt(refl, place, root)
	}
	head := SpecResolvePlaceAt(refl, place[:slash], root)
	if head == nil {
		return nil
	}
	scope := head.Path
	if head.Kind == SpecPlaceKindList {
		scope = head.Path + "-*"
	}
	// A pattern anchor resolves through its first concrete instance; the rest
	// of the place is relative, so the pattern is rebuilt below.
	var concrete []string
	switch {
	case doc != nil:
		concrete = SpecExpandPattern(doc, scope)
	case !strings.Contains(scope, "-*"):
		concrete = []string{scope}
	}
	if len(concrete) == 0 {
		return nil
	}
	rest := SpecResolvePlaceAt(refl, place[slash+1:], concrete[0])
	if rest == nil {
		return nil
	}
	return &SpecPlaceResolution{
		Place:      rest.Place,
		Kind:       rest.Kind,
		Path:       scope + tailFrom(rest.Path, len(concrete[0])),
		ClassName:  rest.ClassName,
		SectionIDs: rest.SectionIDs,
		FormField:  rest.FormField,
	}
}

// The kinds of SpecLinkFix.
const (
	SpecLinkFixSet       = "set"
	SpecLinkFixAppend    = "append"
	SpecLinkFixAddRow    = "addRow"
	SpecLinkFixRemoveRow = "removeRow"
	SpecLinkFixList      = "list"
	SpecLinkFixCopy      = "copy"
)

// SpecLinkFix is what `deriveFields` would write for one link finding
// (collected by SpecLinkValidator beside the finding).
//
// Kinds: `set` (the value at Path / Field, Field "": content), `append` (add
// Value to the ids of the reference field), `addRow` (add a row to the list at
// Path: `<member>#<field>` → value in Values), `removeRow` (the row at Path;
// Empty: it holds no value already), `list` (make the list at Path hold one
// element per tuple of Tuples), `copy` (write the copy at Path from Holder).
type SpecLinkFix struct {
	Step   int
	Kind   string
	Path   string
	Field  string
	Value  string
	Values map[string]string
	Tuples []map[string]string
	Holder string
	Empty  bool
	// ValueKeys are the keys of Values in the order they were written (an
	// `addRow` writes its values in this order); empty: sorted.
	ValueKeys []string
	// TupleKeys are the target places of each tuple of Tuples, in the
	// derivation's order; empty: sorted.
	TupleKeys []string
}

// OrderedValueKeys returns the keys of Values in their written order (sorted
// when the order was not recorded).
func (f SpecLinkFix) OrderedValueKeys() []string {
	if len(f.ValueKeys) > 0 {
		return f.ValueKeys
	}
	keys := make([]string, 0, len(f.Values))
	for k := range f.Values {
		keys = append(keys, k)
	}
	sort.Strings(keys)
	return keys
}

// OrderedTupleKeys returns the target places of the tuples in the
// derivation's order (sorted when the order was not recorded).
func (f SpecLinkFix) OrderedTupleKeys() []string {
	if len(f.TupleKeys) > 0 || len(f.Tuples) == 0 {
		return f.TupleKeys
	}
	keys := make([]string, 0, len(f.Tuples[0]))
	for k := range f.Tuples[0] {
		keys = append(keys, k)
	}
	sort.Strings(keys)
	return keys
}

// linkPutOrdered sets values[key] = value, recording a new key in keys.
func linkPutOrdered(values map[string]string, keys *[]string, key, value string) {
	if _, ok := values[key]; !ok {
		*keys = append(*keys, key)
	}
	values[key] = value
}

// SpecLinkFixOfSet sets the value at path / field ("" content) to value.
func SpecLinkFixOfSet(step int, path, field, value string) SpecLinkFix {
	return SpecLinkFix{Step: step, Kind: SpecLinkFixSet, Path: path, Field: field, Value: value}
}

// SpecLinkFixOfAppend adds value to the ids of the reference field at path /
// field.
func SpecLinkFixOfAppend(path, field, value string) SpecLinkFix {
	return SpecLinkFix{Step: 1, Kind: SpecLinkFixAppend, Path: path, Field: field, Value: value}
}

// SpecLinkFixOfAddRow adds a row to the list at path: `<member>#<field>` (or
// `<member>`, a content value) → value.
func SpecLinkFixOfAddRow(step int, path string, values map[string]string) SpecLinkFix {
	return SpecLinkFix{Step: step, Kind: SpecLinkFixAddRow, Path: path, Values: values}
}

// SpecLinkFixOfRemoveRow removes the row at path; empty: it holds no value
// already.
func SpecLinkFixOfRemoveRow(path string, empty bool) SpecLinkFix {
	return SpecLinkFix{Step: 1, Kind: SpecLinkFixRemoveRow, Path: path, Empty: empty}
}

// SpecLinkFixOfList makes the list at path hold one element per tuple (target
// place → value).
func SpecLinkFixOfList(path string, tuples []map[string]string) SpecLinkFix {
	return SpecLinkFix{Step: 2, Kind: SpecLinkFixList, Path: path, Tuples: tuples}
}

// SpecLinkFixOfCopy writes the copy at path from the holder.
func SpecLinkFixOfCopy(path, holder string) SpecLinkFix {
	return SpecLinkFix{Step: 2, Kind: SpecLinkFixCopy, Path: path, Holder: holder}
}

// ToJSON is the fix as JSON, unset parts left out (for comparing runtimes).
func (f SpecLinkFix) ToJSON() map[string]any {
	out := map[string]any{"step": f.Step, "kind": f.Kind, "path": f.Path}
	switch f.Kind {
	case SpecLinkFixSet, SpecLinkFixAppend:
		if f.Field != "" {
			out["field"] = f.Field
		} else {
			out["field"] = nil
		}
		out["value"] = f.Value
	case SpecLinkFixAddRow:
		values := map[string]any{}
		for k, v := range f.Values {
			values[k] = v
		}
		out["values"] = values
	case SpecLinkFixRemoveRow:
		out["empty"] = f.Empty
	case SpecLinkFixList:
		tuples := []any{}
		for _, t := range f.Tuples {
			m := map[string]any{}
			for k, v := range t {
				m[k] = v
			}
			tuples = append(tuples, m)
		}
		out["tuples"] = tuples
	case SpecLinkFixCopy:
		out["holder"] = f.Holder
	}
	return out
}

var (
	linkFloatText = regexp.MustCompile(`^[+-]?(\d+\.?\d*|\.\d+)([eE][+-]?\d+)?$`)
	linkHexText   = regexp.MustCompile(`^0[xX][0-9a-fA-F]+$`)
	// linkIDToken is an id as text names it: letters, digits and inner
	// hyphens.
	linkIDToken = regexp.MustCompile(`[A-Za-z0-9][A-Za-z0-9-]*[A-Za-z0-9]|[A-Za-z0-9]`)
)

// linkNumTryParse is Dart's `num.tryParse` (decimal forms; surrounding
// whitespace allowed).
func linkNumTryParse(text string) (float64, bool) {
	t := strings.TrimSpace(text)
	switch {
	case intText.MatchString(t), linkFloatText.MatchString(t):
		f, err := strconv.ParseFloat(t, 64)
		return f, err == nil
	case linkHexText.MatchString(t):
		n, err := strconv.ParseInt(t[2:], 16, 64)
		return float64(n), err == nil
	case t == "NaN":
		return math.NaN(), true
	case t == "Infinity":
		return math.Inf(1), true
	case t == "-Infinity":
		return math.Inf(-1), true
	}
	return 0, false
}

// linkInstance is one section instance of the document.
type linkInstance struct {
	path string
	cls  *SpecClass
	root string
}

// linkScalar is one scalar derivation: a content member or a form field.
type linkScalar struct {
	path   string
	field  string // "" for content
	d      *SpecDerivation
	anchor string
	root   string
	spec   *FormFieldSpec
}

// SpecLinkValidator is the link checker of one document: ValidateLinks runs
// it, `deriveFields` reads its Fixes and value readers.
type SpecLinkValidator struct {
	// Fixes is what `deriveFields` would write for each finding, collected
	// beside it.
	Fixes []SpecLinkFix
	// Errors are the findings, in the order they were found.
	Errors []SpecValidationError
	// ItemIDs is the effective section id per list item path (writable by
	// `deriveFields`).
	ItemIDs map[string]string
	// ReadProposed reads values with their pending marks accepted (the
	// proposal), as `deriveFields` does in a document under review, instead
	// of the reviewed state; no value is then listed as pending.
	ReadProposed bool

	Model *SpecModel
	Doc   *SpecDocument
	Refl  *SpecReflection

	reported map[string]bool
	pending  map[string]bool
	// derived holds the derived values computed so far (`path#field` →
	// value), read before the stored value so a derivation from a derived
	// place sees its derived value.
	derived      map[string]string
	items        map[string]bool
	formsByOwner map[string][]string
	entriesCache map[string]map[string]string
	valued       map[string]bool
}

// NewSpecLinkValidator returns the link checker of doc against model.
func NewSpecLinkValidator(model *SpecModel, doc *SpecDocument, readProposed bool) *SpecLinkValidator {
	return &SpecLinkValidator{
		Fixes:        []SpecLinkFix{},
		Errors:       []SpecValidationError{},
		ItemIDs:      map[string]string{},
		ReadProposed: readProposed,
		Model:        model,
		Doc:          doc,
		Refl:         NewSpecReflection(model),
		reported:     map[string]bool{},
		pending:      map[string]bool{},
		derived:      map[string]string{},
		items:        map[string]bool{},
		entriesCache: map[string]map[string]string{},
	}
}

// Report records one finding, once.
func (v *SpecLinkValidator) Report(code, path, message string) {
	key := code + " " + path + " " + message
	if v.reported[key] {
		return
	}
	v.reported[key] = true
	v.Errors = append(v.Errors, SpecValidationError{Path: path, Code: code, Message: message})
}

// --- the document's instances -------------------------------------------------

// Run runs every link check and returns v.
func (v *SpecLinkValidator) Run() *SpecLinkValidator {
	var instances []linkInstance
	for _, root := range v.Model.Roots {
		seg := v.Refl.RootSegment(root)
		if !v.populated(seg) {
			continue
		}
		cls := v.Refl.ClassNamed(root.Type)
		if cls == nil {
			continue
		}
		v.walk(cls, seg, seg, &instances, map[string]bool{})
	}
	v.checkDerivations(instances)
	for _, i := range instances {
		for _, f := range i.cls.Fields {
			v.checkSummary(i, f)
			v.checkExtracts(i, f)
			for _, ff := range f.FormFields {
				form := v.formPath(i, f)
				if ff.InverseOf != nil {
					v.checkInverse(form, ff)
				}
				if ff.SummaryOf != nil {
					v.checkFieldSummary(i, form, ff)
				}
			}
		}
	}
	for _, root := range v.Model.Roots {
		if v.populated(v.Refl.RootSegment(root)) {
			v.checkSameAs(root.Type)
		}
	}
	return v
}

func (v *SpecLinkValidator) populated(seg string) bool {
	under := func(paths []string) bool {
		for _, p := range paths {
			if p == seg || strings.HasPrefix(p, seg+"/") {
				return true
			}
		}
		return false
	}
	return under(v.Doc.ContentPaths()) || under(v.Doc.FormPaths()) ||
		under(v.Doc.ListPaths()) || under(v.Doc.HeadlinePaths())
}

func (v *SpecLinkValidator) walk(cls *SpecClass, path, root string, out *[]linkInstance, onPath map[string]bool) {
	*out = append(*out, linkInstance{path: path, cls: cls, root: root})
	for _, f := range cls.Fields {
		memberPath := path + "/" + v.Refl.FieldSegment(f)
		if f.HasAnnotation("Reference") {
			continue
		}
		if f.Kind == SpecFieldKindList && f.ElementIsComplex {
			el := v.Refl.ClassNamed(f.ElementType)
			if el == nil {
				continue
			}
			for _, item := range v.Doc.ListItems(memberPath) {
				v.walk(el, item, root, out, map[string]bool{})
			}
		} else if f.Kind == SpecFieldKindComplex || f.Kind == SpecFieldKindSection {
			child := placeClassOf(v.Refl, f)
			if child == nil || onPath[child.Name] {
				continue
			}
			next := map[string]bool{cls.Name: true}
			for k := range onPath {
				next[k] = true
			}
			v.walk(child, memberPath, root, out, next)
		}
	}
}

func (v *SpecLinkValidator) formPath(i linkInstance, f *SpecField) string {
	return i.path + "/" + v.Refl.FieldSegment(f)
}

// --- reading values -------------------------------------------------------------

// reviewed is the reviewed reading of a raw value; a value with pending marks
// is listed once.
func (v *SpecLinkValidator) reviewed(raw string, ok bool, path, what string) string {
	if !ok {
		return ""
	}
	if v.ReadProposed {
		return strings.TrimSpace(ApplyInlineMarksText(raw, true))
	}
	rejected := ApplyInlineMarksText(raw, false)
	key := path + " " + what
	if ApplyInlineMarksText(raw, true) != rejected && !v.pending[key] {
		v.pending[key] = true
		v.Report(SpecValidationCodeLinkValuePending, path,
			what+" holds pending change marks; it is read with every mark rejected")
	}
	return strings.TrimSpace(rejected)
}

// FormValue returns the value of form field field at path (derived first, then
// reviewed).
func (v *SpecLinkValidator) FormValue(path, field string) string {
	if d, ok := v.derived[path+"#"+field]; ok {
		return d
	}
	raw, ok := v.Doc.FormField(path, field)
	return v.reviewed(raw, ok, path, "form field \""+field+"\"")
}

// ContentValue returns the content value at path (derived first, then
// reviewed).
func (v *SpecLinkValidator) ContentValue(path string) string {
	if d, ok := v.derived[path+"#"]; ok {
		return d
	}
	raw, ok := v.Doc.Content(path)
	return v.reviewed(raw, ok, path, "the content")
}

// HeadlineValue returns the headline at path, reviewed.
func (v *SpecLinkValidator) HeadlineValue(path string) string {
	raw, ok := v.Doc.Headline(path)
	return v.reviewed(raw, ok, path, "the headline")
}

// ItemID returns the effective section id of the list item at itemPath.
func (v *SpecLinkValidator) ItemID(itemPath string) string {
	if id, ok := v.ItemIDs[itemPath]; ok {
		return id
	}
	id := v.computeItemID(itemPath)
	v.ItemIDs[itemPath] = id
	return id
}

func (v *SpecLinkValidator) computeItemID(itemPath string) string {
	if stored, ok := v.Doc.ItemSectionID(itemPath); ok {
		return stored
	}
	lst := itemPath[:strings.LastIndex(itemPath, "-")]
	items := v.Doc.ListItems(lst)
	position := 0
	for k, it := range items {
		if it == itemPath {
			position = k + 1
			break
		}
	}
	pattern := ""
	stem := lst[strings.LastIndex(lst, "/")+1:]
	if res := v.Refl.Resolve(lst); res != nil && res.Field != nil {
		pattern = res.Field.SectionIDPattern
		stem = res.Field.Name
	}
	return EffectiveListItemSectionID("", false, pattern, position, stem)
}

// IsItem reports whether path is a complex list item.
func (v *SpecLinkValidator) IsItem(path string) bool {
	if hit, ok := v.items[path]; ok {
		return hit
	}
	r := v.Refl.Resolve(path)
	hit := r != nil && r.Kind == SpecNodeKindListItemComplex
	v.items[path] = hit
	return hit
}

// Value returns the value a resolved place holds at its concrete path.
func (v *SpecLinkValidator) Value(r *SpecPlaceResolution, path string) string {
	switch r.Kind {
	case SpecPlaceKindFormField:
		return v.FormValue(path, r.Field())
	case SpecPlaceKindContent:
		return v.ContentValue(path)
	case SpecPlaceKindHeadline:
		return v.HeadlineValue(path)
	case SpecPlaceKindSectionID:
		if v.IsItem(path) {
			return v.ItemID(path)
		}
	}
	return ""
}

// Expand returns every concrete path of a resolved pattern.
func (v *SpecLinkValidator) Expand(pattern string) []string {
	return SpecExpandPattern(v.Doc, pattern)
}

// At returns place resolved under anchor, or nil when it does not resolve.
func (v *SpecLinkValidator) At(place, anchor string) *SpecPlaceResolution {
	return SpecResolvePlaceAt(v.Refl, place, anchor)
}

// global is place resolved for a link annotated at anchor
// (SpecResolveLinkPlace).
func (v *SpecLinkValidator) global(place, root, anchor string) *SpecPlaceResolution {
	return SpecResolveLinkPlace(v.Refl, v.Doc, place, root, anchor)
}

// OwnValues returns the values a row's own forms (`<row>/<member>`) hold in
// field.
func (v *SpecLinkValidator) OwnValues(row, field string) []string {
	if v.formsByOwner == nil {
		v.formsByOwner = map[string][]string{}
		for _, p := range sortedCopy(v.Doc.FormPaths()) {
			if slash := strings.LastIndex(p, "/"); slash > 0 {
				v.formsByOwner[p[:slash]] = append(v.formsByOwner[p[:slash]], p)
			}
		}
	}
	out := []string{}
	for _, p := range v.formsByOwner[row] {
		if _, ok := v.Doc.FormField(p, field); ok {
			out = append(out, v.FormValue(p, field))
		}
	}
	return out
}

func (v *SpecLinkValidator) passes(where, row string) bool {
	if where == "" {
		return true
	}
	f := TryParseSpecPlaceFilter(where)
	if f == nil || f.Field == "" {
		return true
	}
	return f.Matches(v.OwnValues(row, f.Field))
}

// NearestItem returns the nearest list item at or above path (itself
// included), ok=false when there is none.
func (v *SpecLinkValidator) NearestItem(path string) (string, bool) {
	p := path
	for {
		if v.IsItem(p) {
			return p, true
		}
		slash := strings.LastIndex(p, "/")
		if slash < 0 {
			return "", false
		}
		p = p[:slash]
	}
}

// SpecLinkIDs returns the comma-separated ids of value, trimmed, empty ones
// dropped.
func SpecLinkIDs(value string) []string {
	out := []string{}
	for _, s := range strings.Split(value, ",") {
		if t := strings.TrimSpace(s); t != "" {
			out = append(out, t)
		}
	}
	return out
}

// --- @DerivedFrom and derivedFrom: ------------------------------------------------

func (v *SpecLinkValidator) checkDerivations(instances []linkInstance) {
	var scalar []linkScalar
	for _, i := range instances {
		for _, f := range i.cls.Fields {
			d := f.DerivedFrom()
			memberPath := v.formPath(i, f)
			if d != nil {
				if f.Kind == SpecFieldKindList {
					v.checkDerivedList(i, memberPath, d)
				} else if f.Kind == SpecFieldKindContent {
					scalar = append(scalar, linkScalar{memberPath, "", d, i.path, i.root, nil})
				}
			}
			for _, ff := range f.FormFields {
				if ff.DerivedFrom == nil {
					continue
				}
				scalar = append(scalar, linkScalar{memberPath, ff.Name, ff.DerivedFrom, i.path, i.root, ff})
			}
		}
	}
	// Dependency order: every derivation is recomputed from the values the
	// ones before it gave, until nothing moves. DERIVE-ACYCLIC bounds the
	// rounds by the number of derivations.
	type maybe struct {
		value string
		ok    bool
	}
	expected := map[int]maybe{}
	for round := 0; round <= len(scalar); round++ {
		moved := false
		for k, t := range scalar {
			value, ok := v.derive(t.d, t.anchor, t.root, t.spec, t.path)
			// Dart's `expected[k] != value`: an absent key reads as null.
			if prev := expected[k]; prev.ok != ok || prev.value != value {
				expected[k] = maybe{value, ok}
				moved = true
				if ok {
					v.derived[t.path+"#"+t.field] = value
				}
			}
		}
		if !moved {
			break
		}
	}
	v.derived = map[string]string{}
	for k, t := range scalar {
		want := expected[k]
		if !want.ok {
			continue
		}
		var have string
		if t.field == "" {
			have = v.ContentValue(t.path)
		} else {
			have = v.FormValue(t.path, t.field)
		}
		same := linkSameValue(have, want.value, t.spec)
		if !same {
			v.Fixes = append(v.Fixes, SpecLinkFixOfSet(2, t.path, t.field, want.value))
		}
		if have == "" {
			continue // not derived yet: deriveFields writes it
		}
		if !same {
			what := "the content"
			if t.field != "" {
				what = "form field \"" + t.field + "\""
			}
			v.Report(SpecValidationCodeDerivedValueMismatch, t.path,
				what+" is derived ("+t.d.Kind+" of "+t.d.Source+") as \""+want.value+
					"\", but holds \""+have+"\"")
		}
	}
}

// linkSameValue reports whether two values agree: as id sets for a
// multi-valued reference, as numbers for a numeric field, else as text with
// trailing whitespace ignored.
func linkSameValue(a, b string, spec *FormFieldSpec) bool {
	if spec != nil && spec.Multiple && len(spec.RefersTo) > 0 {
		x, y := map[string]bool{}, map[string]bool{}
		for _, id := range SpecLinkIDs(a) {
			x[id] = true
		}
		for _, id := range SpecLinkIDs(b) {
			y[id] = true
		}
		if len(x) != len(y) {
			return false
		}
		for id := range x {
			if !y[id] {
				return false
			}
		}
		return true
	}
	if spec != nil && (spec.Type == "int" || spec.Type == "double" || spec.Type == "num") {
		x, okX := linkNumTryParse(a)
		y, okY := linkNumTryParse(b)
		if okX && okY {
			return x == y
		}
	}
	norm := func(s string) string {
		lines := strings.Split(s, "\n")
		for i, ln := range lines {
			lines[i] = strings.TrimRightFunc(ln, unicode.IsSpace)
		}
		return strings.TrimSpace(strings.Join(lines, "\n"))
	}
	return norm(a) == norm(b)
}

// rows returns the rows a `rows` / `lookup` derivation reads, in document
// order; ok=false when the document's root does not reach the source
// (undecidable here).
func (v *SpecLinkValidator) rows(d *SpecDerivation, anchor, root string) ([]string, bool) {
	src := v.global(d.Source, root, anchor)
	if src == nil {
		return nil, false
	}
	keyBy := d.Key != "" && d.By != ""
	byValue := ""
	if keyBy {
		byValue = v.PlaceValue(d.By, anchor)
	}
	out := []string{}
	for _, row := range v.Expand(src.Path) {
		if !v.passes(d.Where, row) {
			continue
		}
		if keyBy && v.PlaceValue(d.Key, row) != byValue {
			continue
		}
		out = append(out, row)
	}
	return out, true
}

// PlaceValue returns the value of place resolved under the concrete anchor.
func (v *SpecLinkValidator) PlaceValue(place, anchor string) string {
	r := v.At(place, anchor)
	if r == nil {
		return ""
	}
	paths := v.Expand(r.Path)
	if len(paths) != 1 {
		return ""
	}
	return v.Value(r, paths[0])
}

// joinNonEmpty joins the non-empty values with sep.
func joinNonEmpty(values []string, sep string) string {
	var kept []string
	for _, s := range values {
		if s != "" {
			kept = append(kept, s)
		}
	}
	return strings.Join(kept, sep)
}

// derive returns the value a scalar derivation gives, ok=false when
// undecidable.
func (v *SpecLinkValidator) derive(d *SpecDerivation, anchor, root string, spec *FormFieldSpec, targetPath string) (string, bool) {
	switch d.Kind {
	case "copy":
		src := v.global(d.Source, root, anchor)
		if src == nil {
			return "", false
		}
		paths := v.Expand(src.Path)
		if len(paths) != 1 {
			return "", false
		}
		return v.Value(src, paths[0]), true
	case "rows":
		rows, ok := v.rows(d, anchor, root)
		if !ok {
			return "", false
		}
		if spec != nil && spec.Multiple {
			var out []string
			for _, row := range rows {
				for _, t := range d.Take {
					out = append(out, SpecLinkIDs(v.PlaceValue(t, row))...)
				}
			}
			return strings.Join(out, ", "), true
		}
		var lines []string
		for _, row := range rows {
			var vals []string
			for _, t := range d.Take {
				vals = append(vals, v.PlaceValue(t, row))
			}
			if line := joinNonEmpty(vals, " — "); line != "" {
				lines = append(lines, line)
			}
		}
		return strings.Join(lines, "\n"), true
	case "lookup":
		rows, ok := v.rows(d, anchor, root)
		if !ok {
			return "", false
		}
		keyBy := d.Key != "" && d.By != ""
		if keyBy && len(rows) != 1 {
			v.Report(SpecValidationCodeDerivedLookupMiss, targetPath,
				"the lookup in "+d.Source+" by "+d.Key+" = \""+v.PlaceValue(d.By, anchor)+
					"\" finds "+strconv.Itoa(len(rows))+" rows, not one")
			return "", false
		}
		if len(rows) == 0 {
			return "", true
		}
		row := rows[len(rows)-1]
		var vals []string
		for _, t := range d.Take {
			vals = append(vals, v.PlaceValue(t, row))
		}
		return joinNonEmpty(vals, " — "), true
	}
	return "", false
}

// checkDerivedList checks a `@DerivedFrom.rows` with `map` on a list: one
// element per row.
func (v *SpecLinkValidator) checkDerivedList(i linkInstance, listPath string, d *SpecDerivation) {
	if d.Kind != "rows" || len(d.Map) == 0 {
		return
	}
	elements := v.Doc.ListItems(listPath)
	rows, ok := v.rows(d, i.path, i.root)
	if !ok {
		return // the source is not in this document
	}
	wanted := []map[string]string{}
	for _, row := range rows {
		t := map[string]string{}
		for _, e := range d.Map {
			t[e.Key] = v.PlaceValue(e.Value, row)
		}
		wanted = append(wanted, t)
	}
	current := []map[string]string{}
	for _, el := range elements {
		t := map[string]string{}
		for _, e := range d.Map {
			t[e.Key] = v.PlaceValue(e.Key, el)
		}
		current = append(current, t)
	}
	key := func(t map[string]string) string {
		parts := make([]string, 0, len(d.Map))
		for _, e := range d.Map {
			if val, ok := t[e.Key]; ok {
				parts = append(parts, val)
			} else {
				parts = append(parts, "null")
			}
		}
		return strings.Join(parts, " | ")
	}
	sortedKeys := func(ts []map[string]string) []string {
		out := make([]string, 0, len(ts))
		for _, t := range ts {
			out = append(out, key(t))
		}
		sort.Strings(out)
		return out
	}
	if !sliceEqual(sortedKeys(wanted), sortedKeys(current)) {
		fix := SpecLinkFixOfList(listPath, wanted)
		for _, e := range d.Map {
			if !containsString(fix.TupleKeys, e.Key) {
				fix.TupleKeys = append(fix.TupleKeys, e.Key)
			}
		}
		v.Fixes = append(v.Fixes, fix)
	}
	if len(elements) == 0 {
		return // not derived yet
	}
	var want, have []string
	for _, row := range rows {
		parts := make([]string, 0, len(d.Map))
		for _, e := range d.Map {
			parts = append(parts, v.PlaceValue(e.Value, row))
		}
		want = append(want, strings.Join(parts, " | "))
	}
	for _, el := range elements {
		parts := make([]string, 0, len(d.Map))
		for _, e := range d.Map {
			parts = append(parts, v.PlaceValue(e.Key, el))
		}
		have = append(have, strings.Join(parts, " | "))
	}
	sort.Strings(want)
	sort.Strings(have)
	if !sliceEqual(want, have) {
		v.Report(SpecValidationCodeDerivedValueMismatch, listPath,
			"the list is derived (rows of "+d.Source+") as ["+strings.Join(want, "; ")+
				"], but holds ["+strings.Join(have, "; ")+"]")
	}
}

// tailFrom is s from byte n on, "" when s is shorter (a slice that cannot
// fail).
func tailFrom(s string, n int) string {
	if n >= len(s) {
		return ""
	}
	return s[n:]
}

func sliceEqual(a, b []string) bool {
	if len(a) != len(b) {
		return false
	}
	for i := range a {
		if a[i] != b[i] {
			return false
		}
	}
	return true
}

// --- @SummaryOf and summaryOf: ----------------------------------------------------

// linkDetail is one detail element: its item path and id.
type linkDetail struct{ item, id string }

// detailElements returns the detail elements of a summary, in document order;
// ok=false when the detail list does not resolve.
func (v *SpecLinkValidator) detailElements(s *SpecSummaryOf, root string) ([]linkDetail, bool) {
	r := v.global(s.Detail, root, root)
	if r == nil || r.Kind != SpecPlaceKindList {
		return nil, false
	}
	var out []linkDetail
	seen := map[string]bool{}
	for _, lst := range v.Expand(r.Path) {
		for _, item := range v.Doc.ListItems(lst) {
			if seen[item] {
				continue
			}
			seen[item] = true
			out = append(out, linkDetail{item, v.ItemID(item)})
		}
	}
	return out, true
}

func (v *SpecLinkValidator) checkSummary(i linkInstance, f *SpecField) {
	s := f.SummaryOf()
	if s == nil || s.Document != "" || f.Kind != SpecFieldKindList {
		return
	}
	detail, ok := v.detailElements(s, i.root)
	if !ok {
		return
	}
	byID := map[string]string{}
	for _, d := range detail {
		byID[d.id] = d.item
	}
	named := map[string]string{}
	for _, el := range v.Doc.ListItems(v.formPath(i, f)) {
		var ids []string
		if s.Match == "" {
			ids = []string{v.ItemID(el)}
		} else {
			ids = SpecLinkIDs(v.PlaceValue(s.Match, el))
		}
		for _, id := range ids {
			target, ok := byID[id]
			if !ok {
				v.Report(SpecValidationCodeSummaryNotInDetail, el,
					"the summary row names "+id+", which is no element of "+s.Detail)
				continue
			}
			if first, dup := named[id]; dup {
				v.Report(SpecValidationCodeSummaryDuplicate, el,
					"the summary row names "+id+", which "+first+" names already")
				continue
			}
			named[id] = el
			v.checkRepeats(s, el, target)
		}
	}
	if s.Relation == "equal" {
		for _, d := range detail {
			if _, ok := named[d.id]; !ok {
				v.Report(SpecValidationCodeDetailNotInSummary, d.item,
					"the detail element "+d.id+" is named by no row of the summary "+
						v.formPath(i, f)+" (relation: equal)")
			}
		}
	}
}

// checkRepeats checks that the values a summary row repeats agree with its
// detail element's.
func (v *SpecLinkValidator) checkRepeats(s *SpecSummaryOf, row, detail string) {
	for _, rep := range s.Repeats {
		mineAt, theirsAt := rep.Key, rep.Value
		mine := v.At(mineAt, row)
		theirs := v.At(theirsAt, detail)
		if mine == nil || theirs == nil {
			continue
		}
		mp := v.Expand(mine.Path)
		tp := v.Expand(theirs.Path)
		if len(mp) != 1 || len(tp) != 1 {
			continue
		}
		have := v.Value(mine, mp[0])
		want := v.Value(theirs, tp[0])
		if have != want {
			v.Fixes = append(v.Fixes, SpecLinkFixOfSet(2, mp[0], SpecLinkFieldOf(mine), want))
		}
		if have == "" {
			continue // not repeated yet: deriveFields writes it
		}
		if have != want {
			v.Report(SpecValidationCodeDerivedValueMismatch, mp[0],
				mineAt+" repeats "+theirsAt+" of "+detail+" as \""+have+
					"\", but the detail element holds \""+want+"\"")
		}
	}
}

func (v *SpecLinkValidator) checkFieldSummary(i linkInstance, form string, ff *FormFieldSpec) {
	s := ff.SummaryOf
	if s == nil || s.Document != "" {
		return
	}
	if _, ok := v.Doc.FormField(form, ff.Name); !ok {
		return
	}
	detail, ok := v.detailElements(s, i.root)
	if !ok {
		return
	}
	known := map[string]bool{}
	for _, d := range detail {
		known[d.id] = true
	}
	seen := map[string]bool{}
	for _, id := range SpecLinkIDs(v.FormValue(form, ff.Name)) {
		switch {
		case !known[id]:
			v.Report(SpecValidationCodeSummaryNotInDetail, form,
				"form field \""+ff.Name+"\" names "+id+", which is no element of "+s.Detail)
		case seen[id]:
			v.Report(SpecValidationCodeSummaryDuplicate, form,
				"form field \""+ff.Name+"\" names "+id+" twice")
		default:
			seen[id] = true
		}
	}
	if s.Relation == "equal" {
		for _, d := range detail {
			if !seen[d.id] {
				v.Report(SpecValidationCodeDetailNotInSummary, d.item,
					"the detail element "+d.id+" is not named in \""+ff.Name+"\" of "+
						form+" (relation: equal)")
			}
		}
	}
}

// --- inverseOf: --------------------------------------------------------------------

// Entries returns the entries a reference field names, by its `refersTo`
// registries: id → item path. An entry of `<X>.@sectionId` is named by its
// section id, one of `<X>.<field>` by the value its own forms hold in that
// field.
func (v *SpecLinkValidator) Entries(refersTo []string) map[string]string {
	key := strings.Join(refersTo, ",")
	if hit, ok := v.entriesCache[key]; ok {
		return hit
	}
	out := map[string]string{}
	for _, lst := range sortedCopy(v.Doc.ListPaths()) {
		for _, item := range v.Doc.ListItems(lst) {
			r := v.Refl.Resolve(item)
			if r == nil || r.TargetClass == nil {
				continue
			}
			id := r.TargetClass.SectionID
			for _, t := range refersTo {
				if strings.Split(t, ".")[0] != id {
					continue
				}
				name, ok := v.Identity(item, t)
				if !ok || name == "" {
					continue
				}
				if _, taken := out[name]; !taken {
					out[name] = item
				}
			}
		}
	}
	v.entriesCache[key] = out
	return out
}

// Identity returns how the registry key target (`<X>.@sectionId` or
// `<X>.<field>`) names the entry at item; ok=false when it does not.
func (v *SpecLinkValidator) Identity(item, target string) (string, bool) {
	name := target[strings.Index(target, ".")+1:]
	if name == KSectionIDSlot {
		return v.ItemID(item), true
	}
	values := v.OwnValues(item, name)
	if len(values) == 0 {
		return "", false
	}
	return values[0], true
}

// owner returns the nearest item at or above path whose class is one of
// classes.
func (v *SpecLinkValidator) owner(path string, classes map[string]bool) (string, bool) {
	p, ok := v.NearestItem(path)
	for ok {
		if r := v.Refl.Resolve(p); r != nil && r.TargetClass != nil && classes[r.TargetClass.SectionID] {
			return p, true
		}
		slash := strings.LastIndex(p, "/")
		if slash < 0 {
			return "", false
		}
		p, ok = v.NearestItem(p[:slash])
	}
	return "", false
}

func linkRegistryClasses(refersTo []string) map[string]bool {
	out := map[string]bool{}
	for _, t := range refersTo {
		out[strings.Split(t, ".")[0]] = true
	}
	return out
}

func (v *SpecLinkValidator) firstIdentity(owner string, refersTo []string) (string, bool) {
	for _, t := range refersTo {
		if id, ok := v.Identity(owner, t); ok {
			return id, true
		}
	}
	return "", false
}

func (v *SpecLinkValidator) checkInverse(form string, ff *FormFieldSpec) {
	if _, ok := v.Doc.FormField(form, ff.Name); !ok {
		return
	}
	value := v.FormValue(form, ff.Name)
	if value == "" {
		return
	}
	inv := ff.InverseOf
	entries := v.Entries(ff.RefersTo)
	if inv.Symmetric() {
		v.checkSymmetric(form, ff, inv, value, entries)
		return
	}
	// The entry this field belongs to, as the other ends name it.
	for _, b := range SpecLinkIDs(value) {
		bPath, ok := entries[b]
		if !ok {
			continue // a registry this document does not hold
		}
		resolved, namesBack := false, false
		aID := ""
		hasAID := false
		writablePath, writableField := "", ""
		hasWritable := false
		for _, end := range inv.Fields {
			r := v.At(end, bPath)
			if r == nil || r.FormField == nil {
				continue
			}
			owner, ok := v.owner(form, linkRegistryClasses(r.FormField.RefersTo))
			if !ok {
				continue
			}
			if inv.Where != "" && !v.passes(inv.Where, owner) {
				return
			}
			aID, hasAID = v.firstIdentity(owner, r.FormField.RefersTo)
			if !hasAID {
				continue
			}
			resolved = true
			ends := v.Expand(r.Path)
			if len(ends) > 0 && !hasWritable {
				writablePath, writableField, hasWritable = ends[0], r.Field(), true
			}
			for _, p := range ends {
				if containsString(SpecLinkIDs(v.FormValue(p, r.Field())), aID) {
					namesBack = true
				}
			}
		}
		if resolved && !namesBack && hasWritable && hasAID {
			v.Fixes = append(v.Fixes, SpecLinkFixOfAppend(writablePath, writableField, aID))
		}
		if resolved && !namesBack {
			v.Report(SpecValidationCodeInverseMissing, form,
				"form field \""+ff.Name+"\" names "+b+", but "+b+" does not name "+
					aID+" back ("+strings.Join(inv.Fields, ", ")+")")
		}
	}
}

func (v *SpecLinkValidator) checkSymmetric(form string, ff *FormFieldSpec, inv *SpecInverseOf, value string, entries map[string]string) {
	row, ok := v.NearestItem(form)
	if !ok || !v.passes(inv.Where, row) {
		return
	}
	a, ok := v.owner(row[:strings.LastIndex(row, "/")], linkRegistryClasses(ff.RefersTo))
	if !ok {
		return
	}
	aID, ok := v.firstIdentity(a, ff.RefersTo)
	if !ok {
		return
	}
	filterField := ""
	if inv.Where != "" {
		if filt := TryParseSpecPlaceFilter(inv.Where); filt != nil {
			filterField = filt.Field
		}
	}
	whereValues := map[string]bool{}
	if filterField != "" {
		for _, x := range v.OwnValues(row, filterField) {
			whereValues[x] = true
		}
	}

	// The same place beneath the named entry, every row of it.
	generalise := func(s string) string {
		if dash := strings.LastIndex(s, "-"); dash > 0 && intText.MatchString(strings.TrimSpace(s[dash+1:])) {
			return s[:dash] + "-*"
		}
		return s
	}
	segs := strings.Split(form[len(a):], "/")
	for k, s := range segs {
		segs[k] = generalise(s)
	}
	rel := strings.Join(segs, "/")
	for _, b := range SpecLinkIDs(value) {
		bPath, ok := entries[b]
		if !ok || bPath == a {
			continue
		}
		isCounterpart := func(p string) bool {
			r, ok := v.NearestItem(p)
			if !ok || !v.passes(inv.Where, r) {
				return false
			}
			if filterField != "" {
				own := map[string]bool{}
				for _, x := range v.OwnValues(r, filterField) {
					own[x] = true
				}
				for x := range whereValues {
					if !own[x] {
						return false
					}
				}
			}
			return containsString(SpecLinkIDs(v.FormValue(p, ff.Name)), aID)
		}
		counterpart := false
		for _, p := range v.Expand(bPath + rel) {
			if isCounterpart(p) {
				counterpart = true
				break
			}
		}
		if counterpart {
			continue
		}
		if star := strings.Index(rel, "-*"); star > 0 {
			lst := bPath + rel[:star]
			below := ""
			if star+3 <= len(rel) {
				below = rel[star+3:]
			}
			values := map[string]string{}
			var keys []string
			linkPutOrdered(values, &keys, below+"#"+ff.Name, aID)
			if filterField != "" {
				for _, p := range v.ownForms(row) {
					if _, ok := v.Doc.FormField(p, filterField); ok {
						linkPutOrdered(values, &keys, p[len(row)+1:]+"#"+filterField, v.FormValue(p, filterField))
					}
				}
			}
			fix := SpecLinkFixOfAddRow(1, lst, values)
			fix.ValueKeys = keys
			v.Fixes = append(v.Fixes, fix)
		}
		suffix := ""
		if inv.Where != "" {
			suffix = " (" + inv.Where + ")"
		}
		v.Report(SpecValidationCodeInverseMissing, form,
			"the row names "+b+", but "+b+" holds no row naming "+aID+" back"+suffix)
	}
}

// --- @ExtractsLinks and the link rows ------------------------------------------------

func (v *SpecLinkValidator) checkExtracts(i linkInstance, f *SpecField) {
	all := f.ExtractsLinks()
	if len(all) == 0 || f.Kind != SpecFieldKindList {
		return
	}
	listPath := v.formPath(i, f)
	rows := v.Doc.ListItems(listPath)
	own := ""
	hasOwn := false
	if element, ok := v.NearestItem(i.path); ok {
		own, hasOwn = v.ItemID(element), true
	}

	// A link row holding no value at all (what accepting the marked removal of
	// a row leaves) is removed.
	for _, row := range rows {
		if !v.HoldsValue(row) {
			v.Fixes = append(v.Fixes, SpecLinkFixOfRemoveRow(row, true))
		}
	}

	// The ids each row names, and its type (the values `set` writes).
	setKeySet := map[string]bool{}
	for _, e := range all {
		for _, p := range e.Set {
			setKeySet[p.Key] = true
		}
	}
	setKeys := make([]string, 0, len(setKeySet))
	for k := range setKeySet {
		setKeys = append(setKeys, k)
	}
	sort.Strings(setKeys)
	named := map[string][]string{}
	seen := map[string]string{}
	rowed := map[string]bool{}
	for _, row := range rows {
		var unique []string
		for _, e := range all {
			r := v.At(e.Ref, row)
			if r == nil {
				continue
			}
			for _, p := range v.Expand(r.Path) {
				for _, id := range SpecLinkIDs(v.Value(r, p)) {
					if !containsString(unique, id) {
						unique = append(unique, id)
					}
				}
			}
		}
		named[row] = unique
		types := make([]string, 0, len(setKeys))
		for _, k := range setKeys {
			types = append(types, v.PlaceValue(k, row))
		}
		typ := strings.Join(types, " | ")
		for _, id := range unique {
			rowed[id] = true
			key := id + " // " + typ
			if first, ok := seen[key]; ok {
				v.Report(SpecValidationCodeDuplicateLinkRow, row,
					"the row names "+id+" with the type \""+typ+"\", as "+first+" does")
			} else {
				seen[key] = row
			}
		}
	}

	excluded := func(id string) bool { return hasOwn && id == own }
	for _, e := range all {
		var refSpec *FormFieldSpec
		if len(rows) == 0 {
			refSpec = v.refSpecFromModel(f, e.Ref)
		} else if r := v.At(e.Ref, rows[0]); r != nil {
			refSpec = r.FormField
		}
		if refSpec == nil {
			continue
		}
		registry := map[string]bool{}
		for id := range v.Entries(refSpec.RefersTo) {
			registry[id] = true
		}
		var found []string
		for _, place := range e.From {
			p := place
			if !strings.HasPrefix(p, "./") {
				p = "./" + place
			}
			r := v.At(p, i.path)
			if r == nil {
				continue
			}
			for _, path := range v.Expand(r.Path) {
				for _, id := range linkIDsIn(v.Value(r, path), registry) {
					if !excluded(id) && !containsString(found, id) {
						found = append(found, id)
					}
				}
			}
		}
		for _, id := range found {
			if rowed[id] {
				continue
			}
			if e.Mode == "generate" {
				values := map[string]string{}
				var keys []string
				writes := append([]SpecStringPair{{Key: e.Ref, Value: id}}, e.Set...)
				for _, w := range writes {
					r := v.At(w.Key, listPath+"-0")
					if r == nil || r.FormField == nil {
						continue
					}
					rel := r.Path[len(listPath+"-0")+1:]
					linkPutOrdered(values, &keys, rel+"#"+r.Field(), w.Value)
				}
				fix := SpecLinkFixOfAddRow(1, listPath, values)
				fix.ValueKeys = keys
				v.Fixes = append(v.Fixes, fix)
			}
			warn := ""
			if e.Mode == "warn" {
				warn = " (warn: the agent adds it)"
			}
			v.Report(SpecValidationCodeExtractedLinkMissing, listPath,
				id+" is named in "+strings.Join(e.From, " / ")+" but has no row"+warn)
		}
	}
	// A generated row: every `set` value of a generate-mode use matches.
	for _, e := range all {
		if e.Mode != "generate" {
			continue
		}
		mine := map[string]bool{}
		for _, place := range e.From {
			p := place
			if !strings.HasPrefix(p, "./") {
				p = "./" + place
			}
			r := v.At(p, i.path)
			if r == nil {
				continue
			}
			registry := map[string]bool{}
			if len(rows) > 0 {
				if refR := v.At(e.Ref, rows[0]); refR != nil && refR.FormField != nil {
					for id := range v.Entries(refR.FormField.RefersTo) {
						registry[id] = true
					}
				}
			}
			for _, path := range v.Expand(r.Path) {
				for _, id := range linkIDsIn(v.Value(r, path), registry) {
					mine[id] = true
				}
			}
		}
		for _, row := range rows {
			generated := true
			for _, s := range e.Set {
				if v.PlaceValue(s.Key, row) != s.Value {
					generated = false
					break
				}
			}
			if !generated {
				continue
			}
			for _, id := range named[row] {
				if !mine[id] {
					v.Fixes = append(v.Fixes, SpecLinkFixOfRemoveRow(row, false))
					v.Report(SpecValidationCodeExtractedLinkStale, row,
						"the generated row names "+id+", which "+strings.Join(e.From, " / ")+
							" no longer names")
				}
			}
		}
	}
}

func (v *SpecLinkValidator) refSpecFromModel(lst *SpecField, ref string) *FormFieldSpec {
	el := v.Refl.ClassNamed(lst.ElementType)
	if el == nil {
		return nil
	}
	dot := strings.Index(ref, ".")
	if dot < 0 {
		return nil
	}
	id, name := ref[:dot], ref[dot+1:]
	for _, f := range el.Fields {
		fid := f.SectionID
		if f.Name == "content" {
			fid = el.SectionID
		}
		if fid != id {
			continue
		}
		for _, ff := range f.FormFields {
			if ff.Name == name {
				return ff
			}
		}
	}
	return nil
}

// linkIDsIn returns the ids of registry named in text, each matched exactly
// (not as a part of a longer id), in order of first appearance.
func linkIDsIn(text string, registry map[string]bool) []string {
	var out []string
	for _, id := range linkIDToken.FindAllString(text, -1) {
		if registry[id] && !containsString(out, id) {
			out = append(out, id)
		}
	}
	return out
}

// --- @SameAs ---------------------------------------------------------------------

func (v *SpecLinkValidator) checkSameAs(rootType string) {
	for _, b := range SpecSameAsBindings(v.Refl, rootType) {
		if b.HolderPath == "" {
			continue
		}
		copies := v.Expand(b.CopyPath)
		holders := v.Expand(b.HolderPath)
		if len(copies) != len(holders) {
			continue
		}
		for k := range copies {
			if v.compareSubtrees(copies[k], holders[k]) {
				v.Fixes = append(v.Fixes, SpecLinkFixOfCopy(copies[k], holders[k]))
			}
		}
	}
}

// SpecSubtreeValue is one value of a subtree: its path and its value.
type SpecSubtreeValue struct {
	Path  string
	Value string
}

// Subtree returns every value beneath root (itself included), keyed by its
// path relative to root with list items written by their section id, so two
// subtrees compare element by element.
func (v *SpecLinkValidator) Subtree(root string) map[string]SpecSubtreeValue {
	key := func(path string) string {
		rel := ""
		if path != root {
			rel = path[len(root)+1:]
		}
		if rel == "" {
			return ""
		}
		var out []string
		at := root
		for _, seg := range strings.Split(rel, "/") {
			at = at + "/" + seg
			if v.IsItem(at) {
				out = append(out, seg[:strings.LastIndex(seg, "-")]+"["+v.ItemID(at)+"]")
			} else {
				out = append(out, seg)
			}
		}
		return strings.Join(out, "/")
	}
	under := func(p string) bool { return p == root || strings.HasPrefix(p, root+"/") }
	out := map[string]SpecSubtreeValue{}
	put := func(k, path, value string) {
		if value != "" {
			out[k] = SpecSubtreeValue{path, value}
		} else {
			delete(out, k)
		}
	}
	for _, p := range sortedCopy(v.Doc.ContentPaths()) {
		if under(p) {
			put("c:"+key(p), p, v.ContentValue(p))
		}
	}
	for _, p := range sortedCopy(v.Doc.FormPaths()) {
		if !under(p) {
			continue
		}
		for _, name := range sortedCopy(v.Doc.FormFieldNames(p)) {
			put("f:"+key(p)+"#"+name, p, v.FormValue(p, name))
		}
	}
	for _, p := range sortedCopy(v.Doc.HeadlinePaths()) {
		if under(p) {
			put("h:"+key(p), p, v.HeadlineValue(p))
		}
	}
	for _, lst := range sortedCopy(v.Doc.ListPaths()) {
		if !under(lst) {
			continue
		}
		for _, item := range v.Doc.ListItems(lst) {
			put("i:"+key(item), item, v.ItemID(item))
		}
	}
	return out
}

// compareSubtrees reports every difference of copy from holder; whether there
// is one.
func (v *SpecLinkValidator) compareSubtrees(copyPath, holder string) bool {
	mine := v.Subtree(copyPath)
	theirs := v.Subtree(holder)
	keySet := map[string]bool{}
	for k := range mine {
		keySet[k] = true
	}
	for k := range theirs {
		keySet[k] = true
	}
	keys := make([]string, 0, len(keySet))
	for k := range keySet {
		keys = append(keys, k)
	}
	sort.Strings(keys)
	// An element on one side only is one finding; its values are not
	// compared.
	var oneSided []string
	for _, k := range keys {
		_, inMine := mine[k]
		_, inTheirs := theirs[k]
		if strings.HasPrefix(k, "i:") && inMine != inTheirs {
			oneSided = append(oneSided, k[2:])
		}
	}
	beneath := func(k string) bool {
		if strings.HasPrefix(k, "i:") {
			return false
		}
		rel := strings.SplitN(k[2:], "#", 2)[0]
		for _, o := range oneSided {
			if rel == o || strings.HasPrefix(rel, o+"/") {
				return true
			}
		}
		return false
	}
	differs := false
	for _, k := range keys {
		a, hasA := mine[k]
		b, hasB := theirs[k]
		if (hasA == hasB && a.Value == b.Value) || beneath(k) {
			continue
		}
		differs = true
		var what string
		switch {
		case strings.HasPrefix(k, "i:"):
			if hasA {
				what = "element " + a.Value
			} else {
				what = "element " + b.Value
			}
		case strings.HasPrefix(k, "h:"):
			what = "the headline"
		case strings.HasPrefix(k, "c:"):
			what = "the content"
		default:
			what = "form field \"" + k[strings.Index(k, "#")+1:] + "\""
		}
		at := copyPath
		if hasA {
			at = a.Path
		}
		v.Report(SpecValidationCodeSameAsMismatch, at,
			"the copy of "+holder+" differs in "+what+": the copy holds \""+a.Value+
				"\", the holder \""+b.Value+"\"")
	}
	return differs
}

// --- helpers of the fixes -----------------------------------------------------------

// SpecLinkFieldOf returns the field a resolved value place names for a write:
// the form field, the headline's reserved field (KSpecHeadlineField), or ""
// for content.
func SpecLinkFieldOf(r *SpecPlaceResolution) string {
	switch r.Kind {
	case SpecPlaceKindFormField:
		return r.Field()
	case SpecPlaceKindHeadline:
		return KSpecHeadlineField
	}
	return ""
}

// ownForms returns the forms directly beneath row (`<row>/<member>`).
func (v *SpecLinkValidator) ownForms(row string) []string {
	var out []string
	for _, p := range sortedCopy(v.Doc.FormPaths()) {
		if strings.HasPrefix(p, row+"/") && !strings.Contains(p[len(row)+1:], "/") {
			out = append(out, p)
		}
	}
	return out
}

// HoldsValue reports whether anything beneath path holds a value (marks
// included).
func (v *SpecLinkValidator) HoldsValue(path string) bool {
	if v.valued == nil {
		valued := map[string]bool{}
		up := func(p string, self bool) {
			cur := p
			if !self {
				cur = ""
				if slash := strings.LastIndex(p, "/"); slash >= 0 {
					cur = p[:slash]
				}
			}
			for cur != "" && !valued[cur] {
				valued[cur] = true
				slash := strings.LastIndex(cur, "/")
				if slash < 0 {
					cur = ""
				} else {
					cur = cur[:slash]
				}
			}
		}
		doc := v.Doc
		for _, p := range doc.ContentPaths() {
			if strings.TrimSpace(doc.ContentOr(p)) != "" {
				up(p, true)
			}
		}
		for _, p := range doc.FormPaths() {
			for _, name := range doc.FormFieldNames(p) {
				if strings.TrimSpace(doc.FormFieldOr(p, name)) != "" {
					up(p, true)
					break
				}
			}
		}
		for _, p := range doc.HeadlinePaths() {
			if doc.HeadlineOr(p) != "" {
				up(p, false)
			}
		}
		for _, lst := range doc.ListPaths() {
			if len(doc.ListItems(lst)) > 0 {
				up(lst, true)
			}
		}
		v.valued = valued
	}
	return v.valued[path]
}
