package somruntime

// spec_model_links.go — the typed readers of the link vocabulary
// (`tom_specs_model_rules.md` §9.7), a port of the link readers of
// `tom_som_dart_runtime/lib/src/spec_model.dart` (and the TypeScript, JavaScript
// and Python `spec_model` modules).
//
// They are read from the lossless `annotations` block (member and class
// annotations: `@SyncedWith`, `@SummaryOf`, `@DerivedFrom`, `@ExtractsLinks`,
// `@SameAs`) or from the curated `formFields[]` keys (the `Field` qualifiers
// `derivedFrom:`, `inverseOf:`, `summaryOf:`). They follow KindLink: an enum
// constant is read with its type prefix stripped (`LinkRelation.subset` →
// `subset`), a key the reader does not know is ignored, and an absent key takes
// the annotation's default — so a meta written before a key existed loads
// unchanged.
//
// An optional string argument that is absent reads as "" (this package's usual
// absent-string convention); the canonical JSON forms leave it out. A string →
// string argument (`repeats`, `map`, `set`) keeps the order the meta writes it
// in, as the reference's maps do: it is a []SpecStringPair, not a Go map.

import (
	"bytes"
	"encoding/json"
	"sort"
	"strconv"
)

// SpecStringPair is one entry of an ordered string → string argument
// (`SummaryOf.repeats`, `DerivedFrom.map`, `ExtractsLinks.set`).
type SpecStringPair struct {
	Key   string
	Value string
}

// specStringPairsJSON is the JSON object of pairs.
func specStringPairsJSON(pairs []SpecStringPair) map[string]any {
	out := map[string]any{}
	for _, p := range pairs {
		out[p.Key] = p.Value
	}
	return out
}

// SpecStringPairsMap returns pairs as a Go map (the last value of a repeated
// key wins).
func SpecStringPairsMap(pairs []SpecStringPair) map[string]string {
	out := make(map[string]string, len(pairs))
	for _, p := range pairs {
		out[p.Key] = p.Value
	}
	return out
}

// --- reading the arguments --------------------------------------------------

// linkArguments is an argument object as the readers see it: its decoded
// values and, when it came from JSON, the raw text the key order of a nested
// object is read from.
type linkArguments struct {
	values map[string]any
	raw    json.RawMessage
}

func (a linkArguments) get(key string) any {
	if a.values == nil {
		return nil
	}
	return a.values[key]
}

// str is a string argument with a default when absent.
func (a linkArguments) str(key, fallback string) string {
	v := a.get(key)
	if v == nil {
		return fallback
	}
	return linkJSONText(v)
}

// optString is an optional string argument: the string, or "" for anything
// else.
func (a linkArguments) optString(key string) string {
	if s, ok := a.get(key).(string); ok {
		return s
	}
	return ""
}

// hasString reports whether the argument key is a string.
func (a linkArguments) hasString(key string) bool {
	_, ok := a.get(key).(string)
	return ok
}

// stringList is a JSON list read as strings, nulls dropped; anything else as
// empty.
func (a linkArguments) stringList(key string) []string {
	out := []string{}
	if raw, ok := a.get(key).([]any); ok {
		for _, e := range raw {
			if e == nil {
				continue
			}
			out = append(out, linkJSONText(e))
		}
	}
	return out
}

// stringPairs is a JSON object read as string → string, in the order the meta
// writes it; anything else as empty.
func (a linkArguments) stringPairs(key string) []SpecStringPair {
	out := []SpecStringPair{}
	obj, ok := a.get(key).(map[string]any)
	if !ok {
		return out
	}
	for _, k := range jsonKeyOrder(jsonMember(a.raw, key), obj) {
		out = append(out, SpecStringPair{Key: k, Value: linkJSONText(obj[k])})
	}
	return out
}

// object is a nested argument object, with its raw text.
func (a linkArguments) object(key string) (linkArguments, bool) {
	obj, ok := a.get(key).(map[string]any)
	if !ok {
		return linkArguments{}, false
	}
	return linkArguments{values: obj, raw: jsonMember(a.raw, key)}, true
}

// objects is a list argument's object entries (anything else skipped), each
// with its raw text.
func (a linkArguments) objects(key string) []linkArguments {
	list, ok := a.get(key).([]any)
	if !ok {
		return nil
	}
	rawItems := jsonElements(jsonMember(a.raw, key))
	var out []linkArguments
	for i, e := range list {
		obj, ok := e.(map[string]any)
		if !ok {
			continue
		}
		var raw json.RawMessage
		if i < len(rawItems) {
			raw = rawItems[i]
		}
		out = append(out, linkArguments{values: obj, raw: raw})
	}
	return out
}

// linkJSONText is a JSON scalar as text, the way the reference writes it
// (`true`, not `True`; `null`; a whole number without a fraction).
func linkJSONText(v any) string {
	switch t := v.(type) {
	case nil:
		return "null"
	case string:
		return t
	case bool:
		if t {
			return "true"
		}
		return "false"
	case float64:
		if isIntegral(t) && t > -1e15 && t < 1e15 {
			return strconv.FormatInt(int64(t), 10)
		}
		return strconv.FormatFloat(t, 'g', -1, 64)
	case int:
		return itoa(t)
	case json.Number:
		return t.String()
	}
	b, err := json.Marshal(v)
	if err != nil {
		return ""
	}
	return string(b)
}

// jsonMember is the raw text of member key of the raw JSON object raw, or nil.
func jsonMember(raw json.RawMessage, key string) json.RawMessage {
	if len(raw) == 0 {
		return nil
	}
	var m map[string]json.RawMessage
	if json.Unmarshal(raw, &m) != nil {
		return nil
	}
	return m[key]
}

// jsonElements is the raw text of every element of the raw JSON list raw.
func jsonElements(raw json.RawMessage) []json.RawMessage {
	if len(raw) == 0 {
		return nil
	}
	var l []json.RawMessage
	if json.Unmarshal(raw, &l) != nil {
		return nil
	}
	return l
}

// jsonKeyOrder is the keys of obj in the order the raw JSON object raw writes
// them; sorted when there is no raw text (an argument map built in code).
func jsonKeyOrder(raw json.RawMessage, obj map[string]any) []string {
	if keys := jsonObjectKeys(raw); keys != nil {
		seen := map[string]bool{}
		out := []string{}
		for _, k := range keys {
			if _, ok := obj[k]; ok && !seen[k] {
				seen[k] = true
				out = append(out, k)
			}
		}
		if len(out) == len(obj) {
			return out
		}
	}
	out := make([]string, 0, len(obj))
	for k := range obj {
		out = append(out, k)
	}
	sort.Strings(out)
	return out
}

// jsonObjectKeys reads the keys of a raw JSON object in source order, or nil
// when raw is no object.
func jsonObjectKeys(raw json.RawMessage) []string {
	if len(raw) == 0 {
		return nil
	}
	dec := json.NewDecoder(bytes.NewReader(raw))
	tok, err := dec.Token()
	if err != nil {
		return nil
	}
	if d, ok := tok.(json.Delim); !ok || d != '{' {
		return nil
	}
	keys := []string{}
	for dec.More() {
		tok, err := dec.Token()
		if err != nil {
			return nil
		}
		key, ok := tok.(string)
		if !ok {
			return nil
		}
		var skip json.RawMessage
		if dec.Decode(&skip) != nil {
			return nil
		}
		keys = append(keys, key)
	}
	return keys
}

// annotationArguments are the arguments of a, with the raw text they were
// decoded from.
func annotationArguments(a *SpecAnnotation) linkArguments {
	return linkArguments{values: a.Arguments, raw: a.rawArguments}
}

// UnmarshalJSON decodes an annotation and keeps the raw text of its arguments,
// so the order of a string → string argument (`repeats`, `map`, `set`) is the
// meta's.
func (a *SpecAnnotation) UnmarshalJSON(data []byte) error {
	var aux struct {
		Name      string          `json:"name"`
		Arguments json.RawMessage `json:"arguments"`
	}
	if err := json.Unmarshal(data, &aux); err != nil {
		return err
	}
	a.Name = aux.Name
	a.Arguments = nil
	a.rawArguments = nil
	if len(aux.Arguments) > 0 && string(aux.Arguments) != "null" {
		var args map[string]interface{}
		if err := json.Unmarshal(aux.Arguments, &args); err != nil {
			return err
		}
		a.Arguments = args
		a.rawArguments = aux.Arguments
	}
	return nil
}

// UnmarshalJSON decodes a form field, reading the link qualifiers
// (`derivedFrom`, `inverseOf`, `summaryOf`) through their typed readers; a
// qualifier that is no object reads as absent.
func (f *FormFieldSpec) UnmarshalJSON(data []byte) error {
	type plainFormField FormFieldSpec
	var aux struct {
		*plainFormField
		DerivedFrom json.RawMessage `json:"derivedFrom"`
		InverseOf   json.RawMessage `json:"inverseOf"`
		SummaryOf   json.RawMessage `json:"summaryOf"`
	}
	aux.plainFormField = (*plainFormField)(f)
	if err := json.Unmarshal(data, &aux); err != nil {
		return err
	}
	if a, ok := rawLinkArguments(aux.DerivedFrom); ok {
		f.DerivedFrom = specDerivationFrom(a)
	}
	if a, ok := rawLinkArguments(aux.InverseOf); ok {
		f.InverseOf = specInverseOfFrom(a)
	}
	if a, ok := rawLinkArguments(aux.SummaryOf); ok {
		f.SummaryOf = specSummaryOfFrom(a)
	}
	return nil
}

// rawLinkArguments decodes raw as an argument object; ok=false when it is
// absent or no object.
func rawLinkArguments(raw json.RawMessage) (linkArguments, bool) {
	if len(raw) == 0 {
		return linkArguments{}, false
	}
	var obj map[string]any
	if json.Unmarshal(raw, &obj) != nil || obj == nil {
		return linkArguments{}, false
	}
	return linkArguments{values: obj, raw: raw}, true
}

// --- the readers ------------------------------------------------------------

// SpecListRelation is the relation of the elements of a list on two sides of a
// link, as the annotated side reads it (`ListRelation`,
// `tom_specs_model_rules.md` §9.7).
type SpecListRelation struct {
	// Place is the list or multi-valued reference field the relation is about.
	Place string
	// Relation is `equal`, `subset` or `superset` (the `LinkRelation` constant
	// name).
	Relation string
	// Where is the filter selecting the elements the relation applies to, ""
	// for all of them (the SpecPlaceFilter grammar).
	Where string
}

func specListRelationFrom(a linkArguments) SpecListRelation {
	return SpecListRelation{
		Place:    a.str("place", ""),
		Relation: StripEnumPrefix(a.str("relation", "equal")),
		Where:    a.optString("where"),
	}
}

// ToJSON is the canonical JSON form, "" left out.
func (r SpecListRelation) ToJSON() map[string]any {
	out := map[string]any{"place": r.Place, "relation": r.Relation}
	if r.Where != "" {
		out["where"] = r.Where
	}
	return out
}

// SpecSync is `@SyncedWith(document, {detailOnly, heldHere, relations,
// note})`: the annotated section is kept in sync with the section of the same
// id in Document (`tom_specs_model_rules.md` §9.7).
type SpecSync struct {
	// Document is the other document's root class name.
	Document string
	// DetailOnly are the places only Document carries.
	DetailOnly []string
	// HeldHere are the places whose value this document holds.
	HeldHere []string
	// Relations are the lists whose relation is not `equal`.
	Relations []SpecListRelation
	// Note is the annotation's free-text note, "" when it carries none.
	Note string
}

// SpecSyncFromAnnotation reads the sync out of a `@SyncedWith` annotation.
func SpecSyncFromAnnotation(annotation *SpecAnnotation) *SpecSync {
	a := annotationArguments(annotation)
	relations := []SpecListRelation{}
	for _, r := range a.objects("relations") {
		relations = append(relations, specListRelationFrom(r))
	}
	return &SpecSync{
		Document:   a.str("document", ""),
		DetailOnly: a.stringList("detailOnly"),
		HeldHere:   a.stringList("heldHere"),
		Relations:  relations,
		Note:       a.optString("note"),
	}
}

// ToJSON is the canonical JSON form, "" left out.
func (s *SpecSync) ToJSON() map[string]any {
	relations := []any{}
	for _, r := range s.Relations {
		relations = append(relations, r.ToJSON())
	}
	out := map[string]any{
		"document":   s.Document,
		"detailOnly": stringsJSON(s.DetailOnly),
		"heldHere":   stringsJSON(s.HeldHere),
		"relations":  relations,
	}
	if s.Note != "" {
		out["note"] = s.Note
	}
	return out
}

// SpecSummaryOf is `@SummaryOf` on a member, or the `summaryOf:` qualifier of
// a form field: the annotated list or reference field summarises a detailed
// list (`tom_specs_model_rules.md` §9.7).
type SpecSummaryOf struct {
	// Detail is the detailed list, `<LIST-ID>` (a `/` path where needed).
	Detail string
	// Document is the root class name of the document holding Detail; "": this
	// one.
	Document string
	// Match is the summary element's field naming its detail element; "": the
	// summary element carries the detail element's own section id.
	Match string
	// Relation is `equal`, `subset` (the default) or `superset`.
	Relation string
	// Repeats maps a summary place to a detail place for every value the
	// summary repeats, in the meta's order.
	Repeats []SpecStringPair
	// Note is the annotation's free-text note, "" when it carries none.
	Note string
}

func specSummaryOfFrom(a linkArguments) *SpecSummaryOf {
	return &SpecSummaryOf{
		Detail:   a.str("detail", ""),
		Document: a.optString("document"),
		Match:    a.optString("match"),
		Relation: StripEnumPrefix(a.str("relation", "subset")),
		Repeats:  a.stringPairs("repeats"),
		Note:     a.optString("note"),
	}
}

// SpecSummaryOfFromArguments reads the arguments of a `SummaryOf` (annotation
// or qualifier).
func SpecSummaryOfFromArguments(arguments map[string]any) *SpecSummaryOf {
	return specSummaryOfFrom(linkArguments{values: arguments})
}

// ToJSON is the canonical JSON form, "" left out.
func (s *SpecSummaryOf) ToJSON() map[string]any {
	out := map[string]any{"detail": s.Detail}
	if s.Document != "" {
		out["document"] = s.Document
	}
	if s.Match != "" {
		out["match"] = s.Match
	}
	out["relation"] = s.Relation
	out["repeats"] = specStringPairsJSON(s.Repeats)
	if s.Note != "" {
		out["note"] = s.Note
	}
	return out
}

// SpecDerivation is `@DerivedFrom` on a member, or the `derivedFrom:`
// qualifier of a form field: the value is derived from other places
// (`tom_specs_model_rules.md` §9.7).
type SpecDerivation struct {
	// Kind is `copy`, `rows` or `lookup` (the `DerivationKind` constant name).
	Kind string
	// Source is, for copy, the place copied; for rows / lookup, the rows read.
	Source string
	// Where is, for rows, which rows count (the SpecPlaceFilter grammar); ""
	// for all.
	Where string
	// Take are, for rows / lookup, the row places collected.
	Take []string
	// Key is, for rows / lookup, the row field compared with this element's
	// By; "" for none.
	Key string
	// By is, for rows / lookup, this element's field holding the key; "" for
	// none.
	By string
	// Map is, for a list member, target element place ← row place, in the
	// meta's order.
	Map []SpecStringPair
	// Note is the annotation's free-text note, "" when it carries none.
	Note string
}

func specDerivationFrom(a linkArguments) *SpecDerivation {
	return &SpecDerivation{
		Kind:   StripEnumPrefix(a.str("kind", "copy")),
		Source: a.str("source", ""),
		Where:  a.optString("where"),
		Take:   a.stringList("take"),
		Key:    a.optString("key"),
		By:     a.optString("by"),
		Map:    a.stringPairs("map"),
		Note:   a.optString("note"),
	}
}

// SpecDerivationFromArguments reads the arguments of a `DerivedFrom`
// (annotation or qualifier).
func SpecDerivationFromArguments(arguments map[string]any) *SpecDerivation {
	return specDerivationFrom(linkArguments{values: arguments})
}

// ToJSON is the canonical JSON form, "" left out.
func (d *SpecDerivation) ToJSON() map[string]any {
	out := map[string]any{"kind": d.Kind, "source": d.Source}
	if d.Where != "" {
		out["where"] = d.Where
	}
	out["take"] = stringsJSON(d.Take)
	if d.Key != "" {
		out["key"] = d.Key
	}
	if d.By != "" {
		out["by"] = d.By
	}
	out["map"] = specStringPairsJSON(d.Map)
	if d.Note != "" {
		out["note"] = d.Note
	}
	return out
}

// SpecInverseOf is the `inverseOf:` qualifier of a reference form field: the
// other ends of the link (`tom_specs_model_rules.md` §9.7).
type SpecInverseOf struct {
	// Fields are the other ends, `<FORMSECTIONID>.<field>`; `["@self"]` for
	// the symmetric form.
	Fields []string
	// Where: only values (or rows) matching this filter have an inverse; ""
	// for all.
	Where string
}

func specInverseOfFrom(a linkArguments) *SpecInverseOf {
	return &SpecInverseOf{Fields: a.stringList("fields"), Where: a.optString("where")}
}

// SpecInverseOfFromArguments reads the `inverseOf` key of a `formFields[]`
// entry.
func SpecInverseOfFromArguments(arguments map[string]any) *SpecInverseOf {
	return specInverseOfFrom(linkArguments{values: arguments})
}

// Symmetric reports whether the link is stored on both entries in the same
// field (`InverseOf.symmetric`).
func (i *SpecInverseOf) Symmetric() bool {
	return len(i.Fields) == 1 && i.Fields[0] == "@self"
}

// ToJSON is the canonical JSON form, "" left out.
func (i *SpecInverseOf) ToJSON() map[string]any {
	out := map[string]any{"fields": stringsJSON(i.Fields)}
	if i.Where != "" {
		out["where"] = i.Where
	}
	return out
}

// SpecExtractsLinks is `@ExtractsLinks` on a list of link rows: ids named in
// text get rows (`tom_specs_model_rules.md` §9.7). A member may carry it more
// than once.
type SpecExtractsLinks struct {
	// Ref is the row's `refersTo` field receiving a found id.
	Ref string
	// From are the text places searched for ids.
	From []string
	// Set are the values every generated row gets, in the meta's order.
	Set []SpecStringPair
	// Mode is `generate` (the default) or `warn` (the `ExtractMode` constant
	// name).
	Mode string
	// Note is the annotation's free-text note, "" when it carries none.
	Note string
}

// SpecExtractsLinksFromAnnotation reads one `ExtractsLinks` annotation.
func SpecExtractsLinksFromAnnotation(annotation *SpecAnnotation) *SpecExtractsLinks {
	a := annotationArguments(annotation)
	return &SpecExtractsLinks{
		From: a.stringList("from"),
		Ref:  a.str("ref", ""),
		Set:  a.stringPairs("set"),
		Mode: StripEnumPrefix(a.str("mode", "generate")),
		Note: a.optString("note"),
	}
}

// ToJSON is the canonical JSON form, "" left out.
func (e *SpecExtractsLinks) ToJSON() map[string]any {
	out := map[string]any{
		"from": stringsJSON(e.From),
		"ref":  e.Ref,
		"set":  specStringPairsJSON(e.Set),
		"mode": e.Mode,
	}
	if e.Note != "" {
		out["note"] = e.Note
	}
	return out
}

// SpecSameAs is `@SameAs({holder, note})` on a section member: the member
// holds a copy of the section the same document holds at another position,
// the holder (`tom_specs_model_rules.md` §9.7). SpecSameAsBindings finds the
// holder per document.
type SpecSameAs struct {
	// Holder is the holder's section-id path, its last ids as far as needed
	// (`ACPLN/ACRITL`); "": the one other position of the class.
	Holder string
	// Note is the annotation's free-text note, "" when it carries none.
	Note string
}

// SpecSameAsFromAnnotation reads the copy out of a `@SameAs` annotation.
func SpecSameAsFromAnnotation(annotation *SpecAnnotation) *SpecSameAs {
	a := annotationArguments(annotation)
	return &SpecSameAs{Holder: a.optString("holder"), Note: a.optString("note")}
}

// ToJSON is the canonical JSON form, "" left out.
func (s *SpecSameAs) ToJSON() map[string]any {
	out := map[string]any{}
	if s.Holder != "" {
		out["holder"] = s.Holder
	}
	if s.Note != "" {
		out["note"] = s.Note
	}
	return out
}

// stringsJSON is a string list as a JSON list (never null).
func stringsJSON(ss []string) []any {
	out := make([]any, 0, len(ss))
	for _, s := range ss {
		out = append(out, s)
	}
	return out
}

// --- the accessors on classes and fields ------------------------------------

// annotationsNamed returns every annotation named name, in source order.
func annotationsNamed(annotations []*SpecAnnotation, name string) []*SpecAnnotation {
	var out []*SpecAnnotation
	for _, a := range annotations {
		if a.Name == name {
			out = append(out, a)
		}
	}
	return out
}

func syncedWithFrom(annotations []*SpecAnnotation) *SpecSync {
	a := annotationNamed(annotations, "SyncedWith")
	if a == nil {
		return nil
	}
	return SpecSyncFromAnnotation(a)
}

func summaryOfFrom(annotations []*SpecAnnotation) *SpecSummaryOf {
	a := annotationNamed(annotations, "SummaryOf")
	if a == nil {
		return nil
	}
	return specSummaryOfFrom(annotationArguments(a))
}

func derivedFromFrom(annotations []*SpecAnnotation) *SpecDerivation {
	a := annotationNamed(annotations, "DerivedFrom")
	if a == nil {
		return nil
	}
	return specDerivationFrom(annotationArguments(a))
}

func extractsLinksFrom(annotations []*SpecAnnotation) []*SpecExtractsLinks {
	out := []*SpecExtractsLinks{}
	for _, a := range annotationsNamed(annotations, "ExtractsLinks") {
		out = append(out, SpecExtractsLinksFromAnnotation(a))
	}
	return out
}

func sameAsFrom(annotations []*SpecAnnotation) *SpecSameAs {
	a := annotationNamed(annotations, "SameAs")
	if a == nil {
		return nil
	}
	return SpecSameAsFromAnnotation(a)
}

// AnnotationsNamed returns every annotation named name on this field, in
// source order — empty when absent. Some annotations are repeatable
// (`@ExtractsLinks`, `@Case`); reading only the first would drop the rest.
func (f *SpecField) AnnotationsNamed(name string) []*SpecAnnotation {
	return annotationsNamed(f.Annotations, name)
}

// SyncedWith returns the `@SyncedWith` sync, or nil when this field carries
// none.
func (f *SpecField) SyncedWith() *SpecSync { return syncedWithFrom(f.Annotations) }

// SummaryOf returns the `@SummaryOf` link of this member, or nil when it
// carries none.
func (f *SpecField) SummaryOf() *SpecSummaryOf { return summaryOfFrom(f.Annotations) }

// DerivedFrom returns the `@DerivedFrom` derivation of this member, or nil
// when it carries none.
func (f *SpecField) DerivedFrom() *SpecDerivation { return derivedFromFrom(f.Annotations) }

// ExtractsLinks returns every `@ExtractsLinks` of this member, in source
// order; empty when it carries none.
func (f *SpecField) ExtractsLinks() []*SpecExtractsLinks { return extractsLinksFrom(f.Annotations) }

// SameAs returns the `@SameAs` copy of this member, or nil when it carries
// none.
func (f *SpecField) SameAs() *SpecSameAs { return sameAsFrom(f.Annotations) }

// AnnotationsNamed returns every annotation named name on this class, in
// source order — empty when absent.
func (c *SpecClass) AnnotationsNamed(name string) []*SpecAnnotation {
	return annotationsNamed(c.Annotations, name)
}

// SyncedWith returns the `@SyncedWith` sync, or nil when this class carries
// none — a `@DetailedIn` without one is "not declared yet", not "nothing
// shared".
func (c *SpecClass) SyncedWith() *SpecSync { return syncedWithFrom(c.Annotations) }

// SummaryOf returns the `@SummaryOf` link of this class, or nil.
func (c *SpecClass) SummaryOf() *SpecSummaryOf { return summaryOfFrom(c.Annotations) }

// DerivedFrom returns the `@DerivedFrom` derivation of this class, or nil.
func (c *SpecClass) DerivedFrom() *SpecDerivation { return derivedFromFrom(c.Annotations) }

// ExtractsLinks returns every `@ExtractsLinks` of this class, in source order.
func (c *SpecClass) ExtractsLinks() []*SpecExtractsLinks { return extractsLinksFrom(c.Annotations) }

// SameAs returns the `@SameAs` copy of this class, or nil.
func (c *SpecClass) SameAs() *SpecSameAs { return sameAsFrom(c.Annotations) }

// IsCodeSpecsProjection reports whether this class is the CodeSpecs projection
// root (`@CodeSpecsProjection`).
func (c *SpecClass) IsCodeSpecsProjection() bool {
	return c.HasAnnotation("CodeSpecsProjection")
}
