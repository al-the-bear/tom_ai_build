package somruntime

// spec_backfill.go — Backfill: the accepted end state of the Phase 3
// documents, carried into the Blueprint (DP-part-operations-2). A port of
// `tom_som_dart_runtime/lib/src/spec_backfill.dart` (a `part of`
// `spec_document_set.dart` there; and the TypeScript, JavaScript and Python
// `spec_backfill` modules); it reads the comparison internals of SpecSetCheck.

import (
	"sort"
	"strconv"
	"strings"
	"time"
)

// Why Backfill refuses a set.
const (
	// SpecBackfillSetHasMarks: a document holds an inline mark or an
	// annotation block.
	SpecBackfillSetHasMarks = "setHasMarks"
	// SpecBackfillNoBlueprint: the set has no Blueprint.
	SpecBackfillNoBlueprint = "noBlueprint"
)

// The kinds of SpecBackfillChange.
const (
	// SpecBackfillChangeValue: a value written or cleared.
	SpecBackfillChangeValue = "value"
	// SpecBackfillChangeElementAdded: an element added.
	SpecBackfillChangeElementAdded = "elementAdded"
	// SpecBackfillChangeElementRemoved: an element removed.
	SpecBackfillChangeElementRemoved = "elementRemoved"
	// SpecBackfillChangeRevision: the history entry.
	SpecBackfillChangeRevision = "revision"
	// SpecBackfillChangeDerived: a derived place rewritten.
	SpecBackfillChangeDerived = "derived"
)

// The reasons of SpecBackfillLeft besides a finding's resolution.
const (
	// SpecBackfillLeftHeldHere: the Blueprint holds the value: the agent
	// corrects the Phase 3 document.
	SpecBackfillLeftHeldHere = "heldHere"
	// SpecBackfillLeftMayBeAdded: under `subset`, not carried in.
	SpecBackfillLeftMayBeAdded = "mayBeAdded"
)

// SpecBackfillError is why Backfill refuses a set.
type SpecBackfillError struct {
	// Code is SpecBackfillSetHasMarks or SpecBackfillNoBlueprint.
	Code string
	// Places are the places holding marks, in document order.
	Places []SpecSyncPlace
	// Message is the prose for the reader.
	Message string
}

// Error implements the error interface.
func (e *SpecBackfillError) Error() string {
	return "SpecBackfillError(" + e.Code + "): " + e.Message
}

// ToJSON is the canonical JSON form (no message).
func (e *SpecBackfillError) ToJSON() map[string]any {
	places := []any{}
	for _, p := range e.Places {
		places = append(places, p.ToJSON())
	}
	return map[string]any{"code": e.Code, "places": places}
}

// SpecBackfillChange is one place Backfill wrote in the Blueprint.
type SpecBackfillChange struct {
	// Pair is the pair the change belongs to; empty for the revision entry
	// and the derived places written after it.
	Pair string
	// Kind is a SpecBackfillChange kind constant.
	Kind string
	// Path is the value's path, or the element's.
	Path string
	// Field is the form field (KSpecHeadlineField for a headline), "" for
	// content and elements.
	Field string
	// OldValue is the value before (for an element, its id before).
	OldValue string
	// NewValue is the value after (for an element, its id after).
	NewValue string
}

// ToJSON is the canonical JSON form.
func (c SpecBackfillChange) ToJSON() map[string]any {
	out := map[string]any{"pair": c.Pair, "kind": c.Kind, "path": c.Path, "old": c.OldValue, "new": c.NewValue}
	if c.Field != "" {
		out["field"] = c.Field
	}
	return out
}

// SpecBackfillLeft is a finding Backfill left, with the reason.
type SpecBackfillLeft struct {
	// Finding is the finding.
	Finding SpecSyncFinding
	// Reason is SpecBackfillLeftHeldHere, SpecBackfillLeftMayBeAdded, or the
	// finding's resolution (`agent`, `info`).
	Reason string
}

// ToJSON is the canonical JSON form.
func (l SpecBackfillLeft) ToJSON() map[string]any {
	return map[string]any{"finding": l.Finding.ToJSON(), "reason": l.Reason}
}

// SpecBackfillResult is what Backfill did.
type SpecBackfillResult struct {
	// Blueprint is the Blueprint written: the set's own, or its copy on a dry
	// run.
	Blueprint *SpecDocument
	// Changes are every place written, in the order written.
	Changes []SpecBackfillChange
	// Left are every finding in scope it did not resolve, with the reason.
	Left []SpecBackfillLeft
}

// ToJSON is the canonical JSON form (the Blueprint as its stores).
func (r *SpecBackfillResult) ToJSON() map[string]any {
	changes := []any{}
	for _, c := range r.Changes {
		changes = append(changes, c.ToJSON())
	}
	left := []any{}
	for _, l := range r.Left {
		left = append(left, l.ToJSON())
	}
	return map[string]any{"changes": changes, "left": left, "blueprint": r.Blueprint.ToJSON()}
}

// SpecBackfillOptions are the options of Backfill.
type SpecBackfillOptions struct {
	// Pairs (non-nil) keeps those pairs (by section id) only.
	Pairs []string
	// Path (non-empty) keeps the findings at or below this Blueprint path.
	Path string
	// DryRun writes a copy of the Blueprint.
	DryRun bool
	// Author is the revision entry's author, "" for `backfill`.
	Author string
	// Date is the revision entry's date, "" for today.
	Date string
}

// Backfill carries the end state of the Phase 3 documents into the
// Blueprint, as plain values (DP-part-operations-2): for every shared place
// whose holder is the Phase 3 document, the holder's value — a differing or
// missing value written, a value the Phase 3 document emptied cleared, an
// element only in the Phase 3 document added (with its stored section id,
// after its nearest preceding neighbour the Blueprint holds, or first), an
// element only in the Blueprint removed (DP-part-operations-3).
//
// It leaves `detailOnly` places, a `heldHere` place the documents disagree on,
// an element that under `subset` may be added, and every finding across two
// documents: each is listed in SpecBackfillResult.Left with the reason.
//
// It refuses a set holding any inline mark or annotation block
// (*SpecBackfillError, `setHasMarks`, the places named). It writes only the
// Blueprint; when it changed anything it adds one entry to the Blueprint's
// revision history (the `RVENT` list) naming the pairs, and rewrites the
// Blueprint's derived places (DeriveFields, plain). A second run right after
// the first writes nothing.
func Backfill(set *SpecDocumentSet, options SpecBackfillOptions) (*SpecBackfillResult, error) {
	scope := pairScope(options.Pairs)
	bpName, ok := set.NameOf(set.BlueprintRoot)
	if !ok {
		return nil, &SpecBackfillError{Code: SpecBackfillNoBlueprint, Places: []SpecSyncPlace{},
			Message: "the set holds no Blueprint"}
	}
	refl := set.Refl

	// No review in progress.
	marked := []SpecSyncPlace{}
	for _, name := range set.Names() {
		doc := set.Get(name)
		rootType := set.RootOf(name)
		root := ""
		for _, r := range refl.Model.Roots {
			if r.Type == rootType {
				root = refl.RootSegment(r)
				break
			}
		}
		seen := map[string]bool{}
		for _, a := range NewSpecReviewAnnotations(doc, "").List() {
			field := ""
			if a.Field != nil {
				field = *a.Field
			}
			k := a.Path + "#" + field
			if seen[k] {
				continue
			}
			seen[k] = true
			marked = append(marked, SpecSyncPlace{Document: name, Root: root, Path: a.Path, Field: field})
		}
	}
	if len(marked) > 0 {
		return nil, &SpecBackfillError{
			Code:   SpecBackfillSetHasMarks,
			Places: marked,
			Message: "the set holds " + strconv.Itoa(len(marked)) + " value(s) with inline marks or " +
				"annotation blocks; backfill carries the end state of an accepted " +
				"review, so decide them first",
		}
	}

	bpDoc := set.Get(bpName)
	target := bpDoc
	if options.DryRun {
		target = NewSpecDocument()
		target.LoadJSON(bpDoc.ToJSON())
	}
	c := NewSpecSetCheck(set)
	index := 0
	for _, p := range set.Pairs() {
		if scope == nil || scope[p.SectionID] {
			c.ComparePair(p, index)
		}
		index++
	}
	// The links across two documents are the agent's; they are listed as
	// left.
	c.CrossChecks(scope, index)
	sort.SliceStable(c.Out, func(i, j int) bool {
		a, b := c.Out[i], c.Out[j]
		if a.Order != b.Order {
			return a.Order < b.Order
		}
		if a.Key != b.Key {
			return a.Key < b.Key
		}
		return SpecSyncCodeIndex(a.Finding.Code) < SpecSyncCodeIndex(b.Finding.Code)
	})

	inScope := func(f SpecSyncFinding) bool {
		return options.Path == "" || f.Blueprint.Path == options.Path ||
			strings.HasPrefix(f.Blueprint.Path, options.Path+"/")
	}

	w := &specBackfill{set: set, doc: target, name: bpName, changes: []SpecBackfillChange{}, pairs: map[string]bool{}}
	left := []SpecBackfillLeft{}
	var apply []SpecSetFound
	for _, o := range c.Out {
		f := o.Finding
		if !inScope(f) {
			continue
		}
		if f.Resolution == SpecSyncResolutionBackfill {
			apply = append(apply, o)
			continue
		}
		reason := f.Resolution
		switch {
		case f.Holder == SpecSyncHolderBlueprint:
			reason = SpecBackfillLeftHeldHere
		case f.Code == SpecSyncCodeSharedElementMayBeAdded:
			reason = SpecBackfillLeftMayBeAdded
		}
		left = append(left, SpecBackfillLeft{Finding: f, Reason: reason})
	}
	w.apply(apply)
	if len(w.changes) > 0 {
		author := options.Author
		if author == "" {
			author = "backfill"
		}
		date := options.Date
		if date == "" {
			date = time.Now().Format("2006-01-02")
		}
		w.revisionEntry(author, date)
		for _, d := range DeriveFields(set.Model, target, SpecDeriveOptions{}).Changes {
			w.changes = append(w.changes, SpecBackfillChange{
				Kind: SpecBackfillChangeDerived, Path: d.Path, Field: d.Field,
				OldValue: d.OldValue, NewValue: d.NewValue,
			})
		}
	}
	return &SpecBackfillResult{Blueprint: target, Changes: w.changes, Left: left}, nil
}

type specBackfill struct {
	set     *SpecDocumentSet
	doc     *SpecDocument
	name    string
	changes []SpecBackfillChange
	pairs   map[string]bool
}

func (w *specBackfill) write(pair, path, field, value string) {
	old := specGetValue(w.doc, path, field)
	if strings.TrimSpace(old) == strings.TrimSpace(value) {
		return
	}
	specSetValue(w.doc, path, field, value)
	w.pairs[pair] = true
	w.changes = append(w.changes, SpecBackfillChange{
		Pair: pair, Kind: SpecBackfillChangeValue, Path: path, Field: field, OldValue: old, NewValue: value,
	})
}

func (w *specBackfill) idOf(item string) string { return setEffectiveItemID(w.set.Refl, w.doc, item) }

// backfillIDs are the ids to add to and drop from one reference field.
type backfillIDs struct {
	pair string
	add  []string
	drop []string
}

func backfillRel(key string) string {
	body := key[2:]
	if hash := strings.Index(body, "#"); hash >= 0 {
		return body[:hash]
	}
	return body
}

func (w *specBackfill) apply(found []SpecSetFound) {
	doc := w.doc
	// 1. Elements only in the Blueprint go, first.
	for _, o := range found {
		if o.Finding.Code != SpecSyncCodeSharedElementOnlyInBlueprint || !strings.HasPrefix(o.Key, "i:") {
			continue
		}
		item, ok := o.B.Items[o.Key[2:]]
		if !ok || !doc.RemoveListItem(item) {
			continue
		}
		w.pairs[o.Finding.Pair] = true
		w.changes = append(w.changes, SpecBackfillChange{
			Pair: o.Finding.Pair, Kind: SpecBackfillChangeElementRemoved, Path: item,
			OldValue: o.Finding.Blueprint.valueOr(),
		})
	}

	// 2. Values, and the ids of reference fields.
	ids := map[string]*backfillIDs{}
	var idKeys []string
	idsOf := func(key, pair string) *backfillIDs {
		e, ok := ids[key]
		if !ok {
			e = &backfillIDs{pair: pair}
			ids[key] = e
			idKeys = append(idKeys, key)
		}
		return e
	}
	addOnce := func(list []string, x string) []string {
		if containsString(list, x) {
			return list
		}
		return append(list, x)
	}
	for _, o := range found {
		f := o.Finding
		if strings.HasPrefix(o.Key, "i:") {
			continue
		}
		field := f.Blueprint.Field
		switch f.Code {
		case SpecSyncCodeSharedValueDiffers, SpecSyncCodeSharedValueMissing:
			w.write(f.Pair, f.Blueprint.Path, field, o.D.Values[o.Key].Value)
		case SpecSyncCodeSharedValueOnlyInBlueprint:
			w.write(f.Pair, f.Blueprint.Path, field, "")
		case SpecSyncCodeSharedElementMissing:
			e := idsOf(f.Blueprint.Path+"#"+field, f.Pair)
			e.add = addOnce(e.add, f.Detail.valueOr())
		case SpecSyncCodeSharedElementOnlyInBlueprint:
			e := idsOf(f.Blueprint.Path+"#"+field, f.Pair)
			e.drop = addOnce(e.drop, f.Blueprint.valueOr())
		}
	}
	for _, key := range idKeys {
		e := ids[key]
		hash := strings.LastIndex(key, "#")
		p, field := key[:hash], key[hash+1:]
		now := []string{}
		for _, s := range strings.Split(specGetValue(doc, p, field), ",") {
			if t := strings.TrimSpace(s); t != "" && !containsString(e.drop, t) {
				now = append(now, t)
			}
		}
		for _, x := range e.add {
			if !containsString(now, x) {
				now = append(now, x)
			}
		}
		w.write(e.pair, p, field, strings.Join(now, ", "))
	}

	// 3. Elements only in the Phase 3 document come in, each with every value
	// the pair shares beneath it, then take their place.
	type added struct {
		list  string
		id    string
		order []string
	}
	var additions []added
	for _, o := range found {
		if o.Finding.Code != SpecSyncCodeSharedElementMissing || !strings.HasPrefix(o.Key, "i:") {
			continue
		}
		d := o.D
		rel := o.Key[2:]
		id := rel[strings.LastIndex(rel, "[")+1 : len(rel)-1]
		lst := o.Finding.Blueprint.Path
		detailItem := d.Items[rel]
		item := specAddItem(doc, lst, &id)
		w.pairs[o.Finding.Pair] = true
		w.changes = append(w.changes, SpecBackfillChange{
			Pair: o.Finding.Pair, Kind: SpecBackfillChangeElementAdded, Path: item, NewValue: id,
		})
		// Nested elements first (shortest key first), then the values.
		mapped := map[string]string{detailItem: item}
		var nested []string
		for _, k := range d.ItemKeys {
			if strings.HasPrefix(k, rel+"/") {
				nested = append(nested, k)
			}
		}
		sort.SliceStable(nested, func(i, j int) bool { return len(nested[i]) < len(nested[j]) })
		for _, k := range nested {
			dPath := d.Items[k]
			parentFrom, parentTo, found := "", "", false
			for from, to := range mapped {
				if strings.HasPrefix(dPath, from+"/") && (!found || len(from) > len(parentFrom)) {
					parentFrom, parentTo, found = from, to, true
				}
			}
			if !found {
				continue
			}
			seg := dPath[len(parentFrom)+1:]
			nestedID := k[strings.LastIndex(k, "[")+1 : len(k)-1]
			mapped[dPath] = specAddItem(doc, parentTo+"/"+seg[:strings.LastIndex(seg, "-")], &nestedID)
		}
		into := func(dPath string) (string, bool) {
			bestFrom, bestTo, found := "", "", false
			for from, to := range mapped {
				if (dPath == from || strings.HasPrefix(dPath, from+"/")) && (!found || len(from) > len(bestFrom)) {
					bestFrom, bestTo, found = from, to, true
				}
			}
			if !found {
				return "", false
			}
			return bestTo + dPath[len(bestFrom):], true
		}
		for k, v := range d.Values {
			r := backfillRel(k)
			if r != rel && !strings.HasPrefix(r, rel+"/") {
				continue
			}
			target, ok := into(v.Path)
			if !ok || v.Value == "" {
				continue
			}
			specSetValue(doc, target, v.Field, v.Value)
		}
		// The detail list's order, by id.
		detailDoc := w.set.Get(o.Finding.Detail.Document)
		detailList := detailItem[:strings.LastIndex(detailItem, "-")]
		var order []string
		for _, it := range detailDoc.ListItems(detailList) {
			order = append(order, setEffectiveItemID(w.set.Refl, detailDoc, it))
		}
		additions = append(additions, added{lst, id, order})
	}
	// Each list takes its new elements in one reorder: an element goes after
	// its nearest preceding neighbour (in the Phase 3 order) the Blueprint
	// holds, or first.
	type entry struct {
		id    string
		order []string
	}
	byList := map[string][]entry{}
	var listOrder []string
	for _, a := range additions {
		if _, ok := byList[a.list]; !ok {
			listOrder = append(listOrder, a.list)
		}
		byList[a.list] = append(byList[a.list], entry{a.id, a.order})
	}
	orders := map[string][]string{}
	for _, lst := range listOrder {
		entries := byList[lst]
		newIDs := map[string]bool{}
		for _, a := range entries {
			newIDs[a.id] = true
		}
		items := doc.ListItems(lst)
		var orderNow []string
		for _, i := range items {
			if !newIDs[w.idOf(i)] {
				orderNow = append(orderNow, i)
			}
		}
		for _, a := range entries {
			item := ""
			for _, i := range items {
				if w.idOf(i) == a.id {
					item = i
					break
				}
			}
			var before []string
			if at := indexOf(a.order, a.id); at >= 0 {
				before = a.order[:at]
			} else if len(a.order) > 0 {
				before = a.order[:len(a.order)-1]
			}
			at := 0
			for j := len(before) - 1; j >= 0; j-- {
				k := -1
				for n, x := range orderNow {
					if w.idOf(x) == before[j] {
						k = n
						break
					}
				}
				if k >= 0 {
					at = k + 1
					break
				}
			}
			orderNow = append(orderNow[:at], append([]string{item}, orderNow[at:]...)...)
		}
		orders[lst] = orderNow
	}
	w.reorder(listOrder, orders)
	// Each added element is reported at the place it took.
	for i, ch := range w.changes {
		if ch.Kind != SpecBackfillChangeElementAdded {
			continue
		}
		lst := ch.Path[:strings.LastIndex(ch.Path, "-")]
		nowPath := ""
		for _, x := range doc.ListItems(lst) {
			if w.idOf(x) == ch.NewValue {
				nowPath = x
				break
			}
		}
		if nowPath == "" || nowPath == ch.Path {
			continue
		}
		w.changes[i] = SpecBackfillChange{Pair: ch.Pair, Kind: ch.Kind, Path: nowPath, NewValue: ch.NewValue}
	}
}

func indexOf(list []string, x string) int {
	for i, y := range list {
		if y == x {
			return i
		}
	}
	return -1
}

// reorder puts the items of each list in orders in the order given, in one
// pass over the document's stores: the lists renumbered `<list>-1 …
// <list>-n`, every value beneath an item travelling with it, an anonymous
// item whose positional id would change keeping its old id (as MoveListItem
// does). Inner lists go first, so an outer rename carries their new paths.
func (w *specBackfill) reorder(listOrder []string, orders map[string][]string) {
	if len(listOrder) == 0 {
		return
	}
	doc := w.doc
	lists := append([]string{}, listOrder...)
	sort.SliceStable(lists, func(i, j int) bool {
		return len(strings.Split(lists[i], "/")) > len(strings.Split(lists[j], "/"))
	})
	ids := map[string]string{}
	for _, lst := range lists {
		for _, i := range doc.ListItems(lst) {
			ids[i] = w.idOf(i)
		}
	}
	j := doc.ToJSON()

	type mapping struct{ from, to string }
	rename := func(key string, m []mapping) string {
		for _, e := range m {
			if key == e.from {
				return e.to
			}
			if strings.HasPrefix(key, e.from+"/") {
				return e.to + key[len(e.from):]
			}
		}
		return key
	}
	renameStore := func(store map[string]string, m []mapping) map[string]string {
		if store == nil {
			return nil
		}
		out := map[string]string{}
		for k, v := range store {
			out[rename(k, m)] = v
		}
		return out
	}

	for _, lst := range lists {
		order := orders[lst]
		listJSON := j.Lists[lst]
		var m []mapping
		for i, it := range order {
			to := lst + "-" + strconv.Itoa(i+1)
			if it != to {
				m = append(m, mapping{it, to})
			}
		}
		if len(m) == 0 {
			continue
		}
		storedIDs := map[string]string{}
		for k, v := range listJSON.Ids {
			storedIDs[k] = v
		}
		original := doc.ListItems(lst)
		for i, it := range order {
			pos := indexOf(original, it)
			if _, has := storedIDs[it]; pos != i && !has {
				if id, ok := ids[it]; ok {
					storedIDs[it] = id
				}
			}
		}
		j.Content = renameStore(j.Content, m)
		j.Headlines = renameStore(j.Headlines, m)
		j.CodeSpecs = renameStore(j.CodeSpecs, m)
		j.Units = renameStore(j.Units, m)
		if j.Forms != nil {
			forms := map[string]map[string]string{}
			for k, v := range j.Forms {
				forms[rename(k, m)] = v
			}
			j.Forms = forms
		}
		newLists := map[string]ListJson{}
		for key, value := range j.Lists {
			spec := ListJson{Seq: value.Seq}
			if key == lst {
				spec.Items = make([]string, 0, len(order))
				spec.Ids = map[string]string{}
				for _, i := range order {
					spec.Items = append(spec.Items, rename(i, m))
					if id, ok := storedIDs[i]; ok {
						spec.Ids[rename(i, m)] = id
					}
				}
			} else {
				spec.Items = make([]string, 0, len(value.Items))
				for _, i := range value.Items {
					spec.Items = append(spec.Items, rename(i, m))
				}
				if value.Ids != nil {
					spec.Ids = map[string]string{}
					for k, v := range value.Ids {
						spec.Ids[rename(k, m)] = v
					}
				}
			}
			newLists[rename(key, m)] = spec
		}
		j.Lists = newLists
	}
	doc.LoadJSON(j)
}

// revisionEntry adds one entry to the Blueprint's revision history naming the
// pairs.
func (w *specBackfill) revisionEntry(author, date string) {
	doc := w.doc
	refl := w.set.Refl
	lst := ""
	for _, p := range SpecSectionPositions(refl, w.set.BlueprintRoot) {
		if !p.IsMember || p.Member == nil || p.Member.Kind != SpecFieldKindList {
			continue
		}
		if strings.Contains(p.Path, "-*") {
			continue
		}
		el := refl.ClassNamed(p.Member.ElementType)
		if el == nil || el.SectionID != "RVENT" {
			continue
		}
		lst = p.Path
		break
	}
	if lst == "" {
		return
	}
	items := doc.ListItems(lst)
	last := ""
	if len(items) > 0 {
		last = doc.FormFieldOr(items[len(items)-1]+"/content", "version")
	}
	version := SpecBackfillBump(last)
	item := doc.AddListItem(lst)
	var names []string
	for _, p := range w.set.Pairs() {
		if w.pairs[p.SectionID] && !containsString(names, p.SectionID) {
			names = append(names, p.SectionID)
		}
	}
	var others []string
	for _, n := range w.set.Names() {
		if n != w.name {
			others = append(others, n)
		}
	}
	summary := "Backfilled from " + strings.Join(others, ", ") + ": " + strings.Join(names, ", ")
	for _, fv := range [][2]string{{"version", version}, {"date", date}, {"author", author}, {"summary", summary}} {
		doc.SetFormField(item+"/content", fv[0], fv[1])
	}
	w.changes = append(w.changes, SpecBackfillChange{Kind: SpecBackfillChangeRevision, Path: item, NewValue: version})
}

// SpecBackfillBump is the version after v: its last number raised by one (`1.2`
// → `1.3`), `1` when it is empty, `<v>.1` when it holds no number.
func SpecBackfillBump(v string) string {
	end := -1
	for i := len(v) - 1; i >= 0; i-- {
		if v[i] >= '0' && v[i] <= '9' {
			end = i + 1
			break
		}
	}
	if end < 0 {
		if v == "" {
			return "1"
		}
		return v + ".1"
	}
	start := end
	for start > 0 && v[start-1] >= '0' && v[start-1] <= '9' {
		start--
	}
	n, err := strconv.Atoi(v[start:end])
	if err != nil {
		return v + ".1"
	}
	return v[:start] + strconv.Itoa(n+1) + v[end:]
}
