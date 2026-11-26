package somruntime

// spec_derive_fields.go — DeriveFields: the derived places of one document,
// written (`tom_specs_model_rules.md` §9.7). A port of
// `tom_som_dart_runtime/lib/src/spec_derive_fields.dart` (and the TypeScript,
// JavaScript and Python `spec_derive_fields` modules); it applies the
// SpecLinkFix entries SpecLinkValidator collects.

import (
	"sort"
	"strings"
)

// The kinds of SpecDeriveChange.
const (
	// SpecDeriveChangeValue: a value written.
	SpecDeriveChangeValue = "value"
	// SpecDeriveChangeRowAdded: a row added.
	SpecDeriveChangeRowAdded = "rowAdded"
	// SpecDeriveChangeRowRemoved: a row removed (under review: every value of
	// it proposed for deletion).
	SpecDeriveChangeRowRemoved = "rowRemoved"
)

// SpecDeriveChange is one place DeriveFields wrote.
type SpecDeriveChange struct {
	// Step is the step that wrote it: 1 (link ends and rows), 2 (derived
	// values, repeats, `@SameAs` copies), 3 (counts, products, ranks).
	Step int
	// Kind is SpecDeriveChangeValue, SpecDeriveChangeRowAdded or
	// SpecDeriveChangeRowRemoved.
	Kind string
	// Path is the value's path, or the row's.
	Path string
	// Field is the form field (KSpecHeadlineField for a headline), "" for
	// content and rows.
	Field string
	// OldValue is the value before (for a row, empty).
	OldValue string
	// NewValue is the value after (for a row, empty).
	NewValue string
}

// ToJSON is the canonical JSON form.
func (c SpecDeriveChange) ToJSON() map[string]any {
	out := map[string]any{"step": c.Step, "kind": c.Kind, "path": c.Path, "old": c.OldValue, "new": c.NewValue}
	if c.Field != "" {
		out["field"] = c.Field
	}
	return out
}

// SpecDeriveResult is what DeriveFields did.
type SpecDeriveResult struct {
	// Document is the document written: the one given, or its copy on a dry
	// run.
	Document *SpecDocument
	// Changes are every place written, in the order written.
	Changes []SpecDeriveChange
	// Unresolved is what it could not write, with the code: `unmarkable` (a
	// change it cannot mark exactly in a document under review, left as it
	// was), `derivedLookupMiss` (a lookup without exactly one row).
	Unresolved []SpecValidationError
}

// ToJSON is the canonical JSON form (the document as its stores).
func (r *SpecDeriveResult) ToJSON() map[string]any {
	changes := []any{}
	for _, c := range r.Changes {
		changes = append(changes, c.ToJSON())
	}
	return map[string]any{
		"changes":    changes,
		"unresolved": specValidationErrorsJSON(r.Unresolved),
		"document":   r.Document.ToJSON(),
	}
}

// SpecDeriveOptions are the options of DeriveFields.
type SpecDeriveOptions struct {
	// Marked writes every change as inline marks (SOM §11.9.3), for a
	// document under review, and reads values as proposed (pending marks
	// accepted); false writes plain values. The reference runtimes default it
	// to true.
	Marked bool
	// Author is the review member the marks are attributed to, "" for none.
	Author string
	// At is the change time the marks record, "" for now.
	At string
	// DryRun works on a copy of the document.
	DryRun bool
}

// DeriveFields recomputes the derived places of doc (`tom_specs_model_rules.md`
// §9.7) in three steps, each reading the result of the one before:
//
//  1. the missing `inverseOf` ends inside the document, the missing
//     `@ExtractsLinks` rows in `generate` mode, and the stale generated rows
//     removed (a link row left with no value at all goes too);
//  2. `@DerivedFrom` values and lists, `@SummaryOf` `repeats`, and every
//     `@SameAs` copy from its holder;
//  3. `countOf`, `productOf` and `rankOf`.
//
// With options.Marked (a document under review) every change is written as
// inline marks attributed to options.Author at options.At, and values are read
// as proposed (pending marks accepted); without it values are written plain.
// A change it cannot mark exactly is left as it was and listed as
// `unmarkable`. It never writes another document. A second run right after the
// first writes nothing. options.DryRun works on a copy.
func DeriveFields(model *SpecModel, doc *SpecDocument, options SpecDeriveOptions) *SpecDeriveResult {
	target := doc
	if options.DryRun {
		target = NewSpecDocument()
		target.LoadJSON(doc.ToJSON())
	}
	d := &specDeriver{
		model:          model,
		doc:            target,
		marked:         options.Marked,
		author:         options.Author,
		at:             options.At,
		changes:        []SpecDeriveChange{},
		unresolved:     []SpecValidationError{},
		unresolvedKeys: map[string]bool{},
	}
	var clock func() string
	if options.At != "" {
		at := options.At
		clock = func() string { return at }
	}
	d.api = NewSpecReviewAnnotationsWithClock(target, "", clock)
	d.run()
	return &SpecDeriveResult{Document: target, Changes: d.changes, Unresolved: d.unresolved}
}

type specDeriver struct {
	model          *SpecModel
	doc            *SpecDocument
	marked         bool
	author         string
	at             string
	api            *SpecReviewAnnotations
	changes        []SpecDeriveChange
	unresolved     []SpecValidationError
	unresolvedKeys map[string]bool
}

func (d *specDeriver) check() *SpecLinkValidator {
	return NewSpecLinkValidator(d.model, d.doc, d.marked).Run()
}

func (d *specDeriver) run() {
	// Step 1: link ends and rows. Removals first, so a row removed and a row
	// added for the same id do not cancel out.
	v := d.check()
	var step1 []SpecLinkFix
	for _, f := range v.Fixes {
		if f.Step == 1 {
			step1 = append(step1, f)
		}
	}
	for _, f := range step1 {
		if f.Kind == SpecLinkFixRemoveRow {
			d.removeRow(1, f.Path, f.Empty)
		}
	}
	for _, f := range step1 {
		if f.Kind != SpecLinkFixRemoveRow {
			d.apply(f, v)
		}
	}

	// Step 2: derived values and lists, then (reading them) the repeats and
	// the copies; again until nothing moves, which DERIVE-ACYCLIC bounds.
	for i := 0; i < 4; i++ {
		v = d.check()
		before := len(d.changes)
		for _, f := range v.Fixes {
			if f.Step == 2 && f.Kind != SpecLinkFixCopy {
				d.apply(f, v)
			}
		}
		v = d.check()
		for _, f := range v.Fixes {
			if f.Kind == SpecLinkFixCopy {
				d.apply(f, v)
			}
		}
		if len(d.changes) == before {
			break
		}
	}
	for _, e := range v.Errors {
		if e.Code == SpecValidationCodeDerivedLookupMiss {
			d.addUnresolved(e)
		}
	}

	// Step 3: counts, products, ranks.
	for _, n := range SpecDerivedNumbers(d.model, d.doc, d.marked) {
		d.write(3, n.Path, n.Field, n.Value)
	}
}

func (d *specDeriver) addUnresolved(e SpecValidationError) {
	key := e.Code + " " + e.Path + " " + e.Message
	if !d.unresolvedKeys[key] {
		d.unresolvedKeys[key] = true
		d.unresolved = append(d.unresolved, e)
	}
}

// --- the writes ---------------------------------------------------------------

// specGetValue is the value at path / field of doc ("" content,
// KSpecHeadlineField a headline), "" when unset.
func specGetValue(doc *SpecDocument, path, field string) string {
	switch field {
	case KSpecHeadlineField:
		return doc.HeadlineOr(path)
	case "":
		return doc.ContentOr(path)
	}
	return doc.FormFieldOr(path, field)
}

// specSetValue writes value at path / field of doc ("" clears it).
func specSetValue(doc *SpecDocument, path, field, value string) {
	switch field {
	case KSpecHeadlineField:
		doc.SetHeadline(path, value)
	case "":
		doc.SetContent(path, value)
	default:
		doc.SetFormField(path, field, value)
	}
}

// write writes value at path / field: plainly, or marked against the value
// there (compared from its original, so a change already proposed is not
// proposed again).
func (d *specDeriver) write(step int, path, field, value string) {
	current := specGetValue(d.doc, path, field)
	if !d.marked {
		if strings.TrimSpace(current) == strings.TrimSpace(value) {
			return
		}
		specSetValue(d.doc, path, field, value)
	} else {
		if strings.TrimSpace(ApplyInlineMarksText(current, true)) == strings.TrimSpace(value) {
			return
		}
		original := ApplyInlineMarksText(current, false)
		if !MarkChangeText(original, value).Exact {
			what := "the content"
			if field != "" {
				what = "form field \"" + field + "\""
			}
			d.addUnresolved(SpecValidationError{
				Path: path,
				Code: SpecValidationCodeUnmarkable,
				Message: what + " would become \"" + value + "\", a change that cannot " +
					"be marked exactly; it is left for the agent",
			})
			return
		}
		if _, err := d.api.SetMarked(path, field, value, d.author, d.at); err != nil {
			panic(err)
		}
	}
	if now := specGetValue(d.doc, path, field); now != current {
		d.changes = append(d.changes, SpecDeriveChange{
			Step: step, Kind: SpecDeriveChangeValue, Path: path, Field: field,
			OldValue: current, NewValue: now,
		})
	}
}

// specAddItem appends an item to lst, with the section id id unless it is
// nil; a colliding id panics (the reference runtimes raise).
func specAddItem(doc *SpecDocument, lst string, id *string) string {
	if id == nil {
		return doc.AddListItem(lst)
	}
	item, err := doc.AddListItemWithSectionID(lst, *id)
	if err != nil {
		panic(err)
	}
	return item
}

func (d *specDeriver) addRow(step int, lst string, keys []string, values map[string]string) {
	item := d.doc.AddListItem(lst)
	d.changes = append(d.changes, SpecDeriveChange{Step: step, Kind: SpecDeriveChangeRowAdded, Path: item})
	for _, k := range keys {
		rel, field := k, ""
		if hash := strings.Index(k, "#"); hash >= 0 {
			rel, field = k[:hash], k[hash+1:]
		}
		d.write(step, item+"/"+rel, field, values[k])
	}
}

func (d *specDeriver) removeRow(step int, row string, empty bool) {
	if !d.marked || empty {
		if !d.doc.RemoveListItem(row) {
			return
		}
		d.changes = append(d.changes, SpecDeriveChange{Step: step, Kind: SpecDeriveChangeRowRemoved, Path: row})
		return
	}
	// Under review: every value of the row is proposed for deletion; once
	// accepted, the empty row goes with the next run.
	before := len(d.changes)
	under := func(p string) bool { return p == row || strings.HasPrefix(p, row+"/") }
	for _, p := range sortedCopy(d.doc.ContentPaths()) {
		if under(p) {
			d.write(step, p, "", "")
		}
	}
	for _, p := range sortedCopy(d.doc.FormPaths()) {
		if !under(p) {
			continue
		}
		for _, f := range sortedCopy(d.doc.FormFieldNames(p)) {
			d.write(step, p, f, "")
		}
	}
	if len(d.changes) > before {
		removed := SpecDeriveChange{Step: step, Kind: SpecDeriveChangeRowRemoved, Path: row}
		d.changes = append(d.changes[:before], append([]SpecDeriveChange{removed}, d.changes[before:]...)...)
	}
}

func (d *specDeriver) apply(f SpecLinkFix, v *SpecLinkValidator) {
	switch f.Kind {
	case SpecLinkFixSet:
		d.write(f.Step, f.Path, f.Field, f.Value)
	case SpecLinkFixAppend:
		ids := SpecLinkIDs(v.FormValue(f.Path, f.Field))
		if containsString(ids, f.Value) {
			return
		}
		d.write(f.Step, f.Path, f.Field, strings.Join(append(ids, f.Value), ", "))
	case SpecLinkFixAddRow:
		d.addRow(f.Step, f.Path, f.OrderedValueKeys(), f.Values)
	case SpecLinkFixRemoveRow:
		d.removeRow(f.Step, f.Path, f.Empty)
	case SpecLinkFixList:
		d.applyList(f, v)
	case SpecLinkFixCopy:
		d.applyCopy(f.Path, f.Holder, v)
	}
}

// applyList makes the list hold one element per wanted tuple: elements
// matching no tuple removed, tuples matching no element added.
func (d *specDeriver) applyList(f SpecLinkFix, v *SpecLinkValidator) {
	places := f.OrderedTupleKeys()
	key := func(t map[string]string) string {
		parts := make([]string, 0, len(places))
		for _, p := range places {
			parts = append(parts, t[p])
		}
		return strings.Join(parts, " | ")
	}
	var wanted []string
	for _, t := range f.Tuples {
		wanted = append(wanted, key(t))
	}
	var keep []string
	removeFirst := func(list []string, k string) ([]string, bool) {
		for i, x := range list {
			if x == k {
				return append(list[:i:i], list[i+1:]...), true
			}
		}
		return list, false
	}
	for _, el := range d.doc.ListItems(f.Path) {
		t := map[string]string{}
		for _, p := range places {
			t[p] = v.PlaceValue(p, el)
		}
		k := key(t)
		var found bool
		if wanted, found = removeFirst(wanted, k); found {
			keep = append(keep, k)
		} else {
			d.removeRow(2, el, false)
		}
	}
	for _, t := range f.Tuples {
		k := key(t)
		var found bool
		if keep, found = removeFirst(keep, k); found {
			continue
		}
		values := map[string]string{}
		var keys []string
		probe := f.Path + "-0"
		for _, p := range places {
			r := v.At(p, probe)
			if r == nil {
				continue
			}
			rel := tailFrom(r.Path, len(probe)+1)
			if r.Field() != "" {
				rel = rel + "#" + r.Field()
			}
			linkPutOrdered(values, &keys, rel, t[p])
		}
		d.addRow(2, f.Path, keys, values)
	}
}

// applyCopy writes the copy at copyPath from its holder: every value and
// element the holder has, in the copy, and nothing else.
func (d *specDeriver) applyCopy(copyPath, holder string, v *SpecLinkValidator) {
	theirs := v.Subtree(holder)
	mine := v.Subtree(copyPath)
	doc := d.doc

	pathIn := func(rel string, create bool) (string, bool) {
		cur := copyPath
		if rel == "" {
			return cur, true
		}
		for _, seg := range strings.Split(rel, "/") {
			bracket := strings.Index(seg, "[")
			if bracket < 0 {
				cur = cur + "/" + seg
				continue
			}
			lst := cur + "/" + seg[:bracket]
			id := seg[bracket+1 : len(seg)-1]
			found := ""
			for _, i := range doc.ListItems(lst) {
				if v.ItemID(i) == id {
					found = i
					break
				}
			}
			switch {
			case found != "":
				cur = found
			case !create:
				return "", false
			default:
				cur = specAddItem(doc, lst, &id)
				v.ItemIDs[cur] = id
				d.changes = append(d.changes, SpecDeriveChange{Step: 2, Kind: SpecDeriveChangeRowAdded, Path: cur})
			}
		}
		return cur, true
	}

	split := func(key string) (string, string, bool) {
		body := key[2:]
		switch key[0] {
		case 'f':
			hash := strings.Index(body, "#")
			return body[:hash], body[hash+1:], true
		case 'c':
			return body, "", true
		case 'h':
			return body, KSpecHeadlineField, true
		}
		return "", "", false
	}

	sortedKeys := func(m map[string]SpecSubtreeValue) []string {
		out := make([]string, 0, len(m))
		for k := range m {
			out = append(out, k)
		}
		sort.Strings(out)
		return out
	}

	// Elements the holder lacks go first, and nothing beneath them is
	// written.
	var gone []string
	for _, k := range sortedKeys(mine) {
		if _, ok := theirs[k]; !strings.HasPrefix(k, "i:") || ok {
			continue
		}
		rel := k[2:]
		beneath := false
		for _, g := range gone {
			if strings.HasPrefix(rel, g+"/") {
				beneath = true
				break
			}
		}
		if beneath {
			continue
		}
		gone = append(gone, rel)
		d.removeRow(2, mine[k].Path, false)
	}
	beneathGone := func(rel string) bool {
		for _, g := range gone {
			if rel == g || strings.HasPrefix(rel, g+"/") {
				return true
			}
		}
		return false
	}

	for _, k := range sortedKeys(theirs) {
		if strings.HasPrefix(k, "i:") {
			pathIn(k[2:], true)
			continue
		}
		rel, field, ok := split(k)
		if !ok {
			continue
		}
		path, ok := pathIn(rel, true)
		if !ok {
			continue
		}
		d.write(2, path, field, theirs[k].Value)
	}
	for _, k := range sortedKeys(mine) {
		if _, ok := theirs[k]; ok || strings.HasPrefix(k, "i:") {
			continue
		}
		rel, field, ok := split(k)
		if !ok || beneathGone(rel) {
			continue
		}
		if path, ok := pathIn(rel, false); ok {
			d.write(2, path, field, "")
		}
	}
}
