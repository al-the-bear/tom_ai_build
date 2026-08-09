package somruntime

// spec_node_creation.go — meta-model-validated node creation for a live
// SpecDocument (llm_and_d4rt_tools.md §5 "constrained node creation"), a
// faithful port of `tom_som_dart_runtime/lib/src/spec_node_creation.dart`.
//
// Every node a script or tool adds passes through this single gate, so the
// document can only grow in ways the SpecModel permits for the parent. The rules
// are the `tom_specs_model_rules.md` §10.2 *structural* rules, read from the
// model meta-data the runtime already carries (SpecField.Kind,
// SpecField.SectionIDPattern) — not from the analyzer-backed authoring
// validator. The clitool validates the *authored model graph*; this validates a
// *document mutation against that model*.
//
// CheckAddNode is the single, value-aware rule-check entry point (exported for
// reuse by editors and the engine); SpecNodeCreator.Add applies it and performs
// the mutation only when it reports no error, so an illegal add never touches
// the tree.
//
// # Go's stand-ins for the reference's optionals
//
// The reference's `String? itemId` (no caller-proposed id) becomes an ordinary
// `itemID string` where "" means *absent* — the same convention
// SpecEditor.AddListItem already uses, and safe here because an empty section id
// is never a legal id. The reference's `DateTime? date` becomes `month, day int`
// with 0 meaning "today", again mirroring SpecEditor.AddListItem.
//
// CheckAddNode returns the concrete *SpecCreationError rather than the `error`
// interface on purpose: a nil *SpecCreationError stored in an `error` interface
// is a non-nil interface value, so `err != nil` at the call site would be true
// for a legal add. Callers compare the pointer against nil; SpecNodeCreator.Add
// widens it to `error` only after checking.

import "time"

// Why an attempted node creation is illegal against the model.
const (
	// SpecCreationCodeNotAContainer: the parent path does not resolve to a node
	// that can own named children (it is dangling, a leaf, or a list — lists
	// grow through their own field, not by adding children to the list node).
	SpecCreationCodeNotAContainer = "notAContainer"

	// SpecCreationCodeUnknownChild: the requested child segment names no field
	// on the parent's class.
	SpecCreationCodeUnknownChild = "unknownChild"

	// SpecCreationCodePatternMismatch: a caller-proposed list-item id does not
	// keep the prefix mandated by the list's @SectionIdPattern (AA1 criterion
	// 3/5: an override replaces the suffix, the pattern prefix stays).
	SpecCreationCodePatternMismatch = "patternMismatch"

	// SpecCreationCodeDuplicateSectionID: a caller-proposed list-item id
	// collides with another item's section id in the same list (AA1 criterion
	// 5: section ids within a list must be unique).
	SpecCreationCodeDuplicateSectionID = "duplicateSectionId"

	// SpecCreationCodeCardinalityExceeded: a single-valued (non-list) child
	// already holds a value — only one is allowed.
	SpecCreationCodeCardinalityExceeded = "cardinalityExceeded"
)

// SpecCreationCode is the reason code carried by a SpecCreationError. Go has no
// enum type; the codes are the string constants above, whose values are the
// reference enum's `name`s (so they cross the conformance corpus unchanged).
type SpecCreationCode = string

// SpecCreationAllCodes lists every creation-rejection code, in declaration
// order — the Go stand-in for the reference enum's `values`.
var SpecCreationAllCodes = []string{
	SpecCreationCodeNotAContainer,
	SpecCreationCodeUnknownChild,
	SpecCreationCodePatternMismatch,
	SpecCreationCodeDuplicateSectionID,
	SpecCreationCodeCardinalityExceeded,
}

// SpecCreationError is a rejected node-creation attempt. Returned by
// CheckAddNode and (as an `error`) by SpecNodeCreator.Add.
type SpecCreationError struct {
	// ParentPath is the parent path the add was attempted under.
	ParentPath string
	// ChildSegment is the child section segment that was requested.
	ChildSegment string
	// Code is why the add is illegal.
	Code SpecCreationCode
	// Message is a human-readable explanation.
	Message string
}

// Error renders the rejection, matching the reference's toString().
func (e *SpecCreationError) Error() string {
	return "SpecCreationError(" + e.Code + ") under \"" + e.ParentPath +
		"\" → \"" + e.ChildSegment + "\": " + e.Message
}

// CheckAddNode validates adding child childSegment under parentPath against
// model, consulting document for cardinality. It returns nil when the add is
// legal, otherwise the SpecCreationError describing the first rule it breaks.
//
// An itemID of "" means the caller proposed no list-item id (one is generated at
// add time); a non-empty itemID is checked against the list's
// @SectionIdPattern prefix and the ids already in the list.
//
// This performs **no mutation**; it is the shared rule-check that
// SpecNodeCreator.Add (and any editor) calls before touching the tree.
func CheckAddNode(
	model *SpecModel,
	document *SpecDocument,
	parentPath string,
	childSegment string,
	itemID string,
) *SpecCreationError {
	refl := NewSpecReflection(model)

	err := func(code SpecCreationCode, message string) *SpecCreationError {
		return &SpecCreationError{
			ParentPath:   parentPath,
			ChildSegment: childSegment,
			Code:         code,
			Message:      message,
		}
	}

	// 1. The parent must resolve to a class-bearing node (root / complex /
	//    section / complex list item). Leaves, lists and dangling paths cannot
	//    own named children.
	parent := refl.Resolve(parentPath)
	if parent == nil || parent.TargetClass == nil {
		what := "does not resolve"
		if parent != nil {
			what = "is a " + parent.Kind
		}
		return err(SpecCreationCodeNotAContainer,
			"parent path "+what+" and cannot own child nodes")
	}
	parentClass := parent.TargetClass

	// 2. The child segment must name a declared field of the parent's class.
	field := fieldForSegment(parentClass, childSegment)
	if field == nil {
		return err(SpecCreationCodeUnknownChild,
			"\""+childSegment+"\" is not a child of "+parentClass.Name)
	}

	childPath := SpecPathJoin(parentPath, childSegment)

	if field.Kind == SpecFieldKindList {
		// 3. List item: validate a caller-proposed id. Lists have no upper
		//    bound, so there is no cardinality check. A missing id is generated
		//    later (criterion 3); an explicit override must keep the pattern
		//    prefix (criterion 3) and stay unique within the list (criterion 5).
		pattern := field.SectionIDPattern
		if itemID != "" && pattern != "" {
			prefix := SectionIDPatternPrefix(pattern)
			if !hasStringPrefix(itemID, prefix) {
				return err(SpecCreationCodePatternMismatch,
					"item id \""+itemID+"\" does not keep the pattern prefix \""+
						prefix+"\"")
			}
			if containsString(document.ListItemSectionIDs(childPath), itemID) {
				return err(SpecCreationCodeDuplicateSectionID,
					"item id \""+itemID+"\" is already used in list \""+
						childPath+"\"")
			}
		}
		return nil
	}

	// 4. Single-valued child (complex / section / form / content / enum /
	//    scalar): cardinality is exactly one, so reject if a value already
	//    exists at or beneath the child path.
	if document.HasValuesUnder(childPath) {
		return err(SpecCreationCodeCardinalityExceeded,
			"a "+field.Kind+" child already exists at \""+childPath+"\"")
	}
	return nil
}

// SpecNodeCreator applies CheckAddNode and performs the constrained mutation.
//
// It holds the model/document pair so callers add children by parent path and
// child segment without re-supplying the context each time.
type SpecNodeCreator struct {
	// Model is the meta-model the mutation is validated against.
	Model *SpecModel
	// Document is the document being grown.
	Document *SpecDocument
}

// NewSpecNodeCreator binds a creator to a model/document pair.
func NewSpecNodeCreator(model *SpecModel, document *SpecDocument) *SpecNodeCreator {
	return &SpecNodeCreator{Model: model, Document: document}
}

// Add adds child childSegment under parentPath and returns the new node's path.
//
// For a list field this appends a fresh item (`…/<segment>-<seq>`), assigning
// its **section id** (AA1 criteria 3–5): itemID if given (override), otherwise
// one generated from the field's @SectionIdPattern using month/day — either of
// which defaults to today when passed as 0 — for the two-letter-date component.
// Lists with no pattern (scalar lists) get no section id. For a single-valued
// field it returns the child path without mutating the sparse store (the caller
// then sets its value).
//
// It returns a *SpecCreationError — leaving the document untouched — when the
// add violates a structural rule (see the SpecCreationCode constants).
func (c *SpecNodeCreator) Add(
	parentPath string,
	childSegment string,
	itemID string,
	month, day int,
) (string, error) {
	if bad := CheckAddNode(
		c.Model, c.Document, parentPath, childSegment, itemID); bad != nil {
		return "", bad
	}

	childPath := SpecPathJoin(parentPath, childSegment)
	parent := NewSpecReflection(c.Model).Resolve(parentPath)
	field := fieldForSegment(parent.TargetClass, childSegment)
	if field.Kind == SpecFieldKindList {
		pattern := field.SectionIDPattern
		if pattern == "" {
			return c.Document.AddListItem(childPath), nil
		}
		id := itemID
		if id == "" {
			today := time.Now()
			if month == 0 {
				month = int(today.Month())
			}
			if day == 0 {
				day = today.Day()
			}
			id = GenerateListItemSectionID(
				pattern, month, day, c.Document.ListItemSectionIDs(childPath))
		}
		return c.Document.AddListItemWithSectionID(childPath, id)
	}
	return childPath, nil
}

// fieldForSegment returns the field of cls whose section segment
// (@SectionId ?? name) is segment, or nil when the class declares no such child.
func fieldForSegment(cls *SpecClass, segment string) *SpecField {
	for _, f := range cls.Fields {
		name := f.SectionID
		if name == "" {
			name = f.Name
		}
		if name == segment {
			return f
		}
	}
	return nil
}

// hasStringPrefix reports whether s starts with prefix (strings.HasPrefix,
// spelled out so this file keeps the reference's dependency-free shape).
func hasStringPrefix(s, prefix string) bool {
	return len(s) >= len(prefix) && s[:len(prefix)] == prefix
}
