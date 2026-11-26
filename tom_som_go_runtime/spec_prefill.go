package somruntime

// spec_prefill.go — Prefill: a Phase 3 document started from the Blueprint
// (BP-8). A port of `tom_som_dart_runtime/lib/src/spec_prefill.dart` (a `part
// of` `spec_document_set.dart` there; and the TypeScript, JavaScript and
// Python `spec_prefill` modules); it reads the comparison internals of
// SpecSetCheck and SpecSetSide.

import (
	"sort"
	"strings"
)

// Why Prefill refuses.
const (
	// SpecPrefillNoBlueprint: the set holds no Blueprint.
	SpecPrefillNoBlueprint = "noBlueprint"
	// SpecPrefillUnknownRoot: the root names no root of the model, or the
	// Blueprint's own.
	SpecPrefillUnknownRoot = "unknownRoot"
)

// SpecPrefillError is why Prefill refuses.
type SpecPrefillError struct {
	// Code is SpecPrefillNoBlueprint or SpecPrefillUnknownRoot.
	Code string
	// Message is the prose for the reader.
	Message string
}

// Error implements the error interface.
func (e *SpecPrefillError) Error() string {
	return "SpecPrefillError(" + e.Code + "): " + e.Message
}

// SpecPrefillResult is what Prefill did.
type SpecPrefillResult struct {
	// Document is the document filled: the set's own, or the one created.
	Document *SpecDocument
	// Name is its name in the set.
	Name string
	// Created is whether it was created by this call.
	Created bool
	// FilledPairs are the pairs it filled, by section id, in the Blueprint's
	// order.
	FilledPairs []string
	// SkippedPairs are the pairs it left because their anchor already holds a
	// value.
	SkippedPairs []string
	// Derived is the DeriveFields run (plain) on the document after the copy.
	Derived *SpecDeriveResult
	// Findings are the document's findings after it (ValidateDocument, then
	// ValidateLinks): the agent's work list.
	Findings []SpecValidationError
}

// ToJSON is the canonical JSON form.
func (r *SpecPrefillResult) ToJSON() map[string]any {
	changes := []any{}
	for _, c := range r.Derived.Changes {
		changes = append(changes, c.ToJSON())
	}
	return map[string]any{
		"name":         r.Name,
		"created":      r.Created,
		"filledPairs":  stringsJSON(r.FilledPairs),
		"skippedPairs": stringsJSON(r.SkippedPairs),
		"derived": map[string]any{
			"changes":    changes,
			"unresolved": specValidationErrorsJSON(r.Derived.Unresolved),
		},
		"findings": specValidationErrorsJSON(r.Findings),
		"document": r.Document.ToJSON(),
	}
}

// SpecPrefillOptions are the options of Prefill.
type SpecPrefillOptions struct {
	// Name is the name a document created is given, "" for the root's type
	// name.
	Name string
	// Pairs (non-nil) keeps those pairs (by section id) only.
	Pairs []string
}

// Prefill fills the pairs of rootType (a root's type name or section id) that
// hold nothing yet from the Blueprint, once, at the start of a Phase 3
// document (BP-8): every value, element (with its stored section id) and
// headline beneath each pair's Blueprint anchor, outside `detailOnly`, copied
// as plain values. Derived places are not copied; they are derived in the
// document (DeriveFields, plain) after the copy.
//
// A pair whose anchor already holds any value is skipped, not merged, so a
// second run writes nothing. The document's front matter is left empty for the
// agent. When the set has no document of the root, it is created as
// options.Name (default: the root's type name) and added to the set once it
// holds a value.
func Prefill(set *SpecDocumentSet, rootType string, options SpecPrefillOptions) (*SpecPrefillResult, error) {
	scope := pairScope(options.Pairs)
	bpRoot := set.BlueprintRoot
	bpName, ok := set.NameOf(bpRoot)
	if bpRoot == "" || !ok {
		return nil, &SpecPrefillError{Code: SpecPrefillNoBlueprint, Message: "the set holds no Blueprint"}
	}
	var root *SpecRoot
	for _, r := range set.Model.Roots {
		if r.Type == rootType || r.SectionID == rootType {
			root = r
			break
		}
	}
	if root == nil || root.Type == bpRoot {
		return nil, &SpecPrefillError{Code: SpecPrefillUnknownRoot, Message: rootType + " names no Phase 3 root of the model"}
	}
	existing, hasExisting := set.NameOf(root.Type)
	docName := existing
	if !hasExisting {
		docName = options.Name
		if docName == "" {
			docName = root.Type
		}
	}
	var doc *SpecDocument
	if hasExisting {
		doc = set.Get(existing)
	}
	if doc == nil {
		doc = NewSpecDocument()
	}
	bp := set.Get(bpName)
	c := NewSpecSetCheck(set)

	filled := []string{}
	skipped := []string{}
	for _, pair := range set.Pairs() {
		if pair.DetailRoot != root.Type {
			continue
		}
		if scope != nil && !scope[pair.SectionID] {
			continue
		}
		// Nested pairs are filled on their own (when they are this root's).
		var nested []string
		for _, other := range set.Pairs() {
			if other != pair {
				nested = append(nested, c.Expand(bp, other.BlueprintAnchor)...)
			}
		}
		wrote, held := false, false
		for _, ba := range c.Expand(bp, pair.BlueprintAnchor) {
			ids := c.AnchorKey(bp, ba)
			var createdItems []string
			da := prefillAnchorIn(c, doc, pair.DetailAnchor, ids, &createdItems)
			if doc.HasValuesUnder(da) && len(createdItems) == 0 {
				held = true
				continue
			}
			var beneath []string
			for _, p := range nested {
				if strings.HasPrefix(p, ba+"/") {
					beneath = append(beneath, p)
				}
			}
			side := c.Collect(bpName, bp, bpRoot, ba, pair, beneath)
			if prefillCopy(c, bp, side, doc, da) {
				wrote = true
			} else {
				// Nothing to copy: the anchor items made for it go again.
				for i := len(createdItems) - 1; i >= 0; i-- {
					doc.RemoveListItem(createdItems[i])
				}
			}
		}
		if wrote {
			filled = append(filled, pair.SectionID)
		}
		if held && !wrote {
			skipped = append(skipped, pair.SectionID)
		}
	}

	created := !hasExisting && doc.HasValuesUnder(set.Refl.RootSegment(root))
	if created {
		if err := set.Put(docName, doc); err != nil {
			return nil, err
		}
	}
	derived := DeriveFields(set.Model, doc, SpecDeriveOptions{})
	return &SpecPrefillResult{
		Document:     doc,
		Name:         docName,
		Created:      created,
		FilledPairs:  filled,
		SkippedPairs: skipped,
		Derived:      derived,
		Findings:     append(ValidateDocument(set.Model, doc), ValidateLinks(set.Model, doc)...),
	}, nil
}

// prefillAnchorIn is the concrete detail anchor of pattern in doc for a
// Blueprint anchor whose list items carry ids (`a/b`, in order): each
// `<list>-*` taken as the item of that id, created with it when missing.
func prefillAnchorIn(c *SpecSetCheck, doc *SpecDocument, pattern, ids string, created *[]string) string {
	var want []string
	if ids != "" {
		want = strings.Split(ids, "/")
	}
	k := 0
	cur := ""
	for _, seg := range strings.Split(pattern, "/") {
		if !strings.HasSuffix(seg, "-*") {
			if cur == "" {
				cur = seg
			} else {
				cur = cur + "/" + seg
			}
			continue
		}
		lst := cur + "/" + seg[:len(seg)-2]
		id := ""
		if k < len(want) {
			id = want[k]
			k++
		}
		hit := ""
		for _, i := range doc.ListItems(lst) {
			if c.ItemID(doc, i) == id {
				hit = i
				break
			}
		}
		if hit != "" {
			cur = hit
		} else {
			cur = specAddItem(doc, lst, &id)
			*created = append(*created, cur)
		}
	}
	return cur
}

// prefillCopy copies the Blueprint values of side beneath anchor of doc: list
// items first, in the Blueprint's order and with their section ids, then every
// value. Whether anything was written.
func prefillCopy(c *SpecSetCheck, bp *SpecDocument, side *SpecSetSide, doc *SpecDocument, anchor string) bool {
	wrote := false
	mapped := map[string]string{side.Anchor: anchor}
	into := func(bpPath string) (string, bool) {
		best, found := "", false
		for k := range mapped {
			if (bpPath == k || strings.HasPrefix(bpPath, k+"/")) && (!found || len(k) > len(best)) {
				best, found = k, true
			}
		}
		if !found {
			return "", false
		}
		return mapped[best] + bpPath[len(best):], true
	}

	// Items, outer lists first, each list in the Blueprint's order.
	var lists []string
	itemPaths := map[string]bool{}
	for _, k := range side.ItemKeys {
		item := side.Items[k]
		itemPaths[item] = true
		if item != side.Anchor {
			if lst := item[:strings.LastIndex(item, "-")]; !containsString(lists, lst) {
				lists = append(lists, lst)
			}
		}
	}
	sort.SliceStable(lists, func(i, j int) bool { return len(lists[i]) < len(lists[j]) })
	for _, lst := range lists {
		target, ok := into(lst)
		if !ok {
			continue
		}
		for _, item := range bp.ListItems(lst) {
			if !itemPaths[item] {
				continue
			}
			id := c.ItemID(bp, item)
			mapped[item] = specAddItem(doc, target, &id)
			wrote = true
		}
	}
	keys := make([]string, 0, len(side.Values))
	for k := range side.Values {
		keys = append(keys, k)
	}
	sort.Strings(keys)
	for _, k := range keys {
		v := side.Values[k]
		if v.Value == "" {
			continue
		}
		p, ok := into(v.Path)
		if !ok {
			continue
		}
		specSetValue(doc, p, v.Field, v.Value)
		wrote = true
	}
	return wrote
}
