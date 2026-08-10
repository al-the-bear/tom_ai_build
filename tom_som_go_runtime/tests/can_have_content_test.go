// Unit tests for the structural content-slot predicate CanHaveContent (SOM
// SOM §21) — the Go port of the Dart SomNode.canHaveContent.
//
// CanHaveContent is a per-type / schema predicate: it answers "*can* this
// section type hold body text?" (does it declare the standard `content` leaf?)
// without probing Content() and without looking at the document. The embedded
// som.SomNode defaults it to false; a content-bearing section shadows that
// promoted method with a CanHaveContent() returning true — mirroring what the
// Go emitter emits per content-bearing type.
//
// These mirror the Dart reference cases in
// tom_som_dart_runtime/test/som_facade_test.dart (the canHaveContent group).
package tests

import (
	"testing"

	som "github.com/al-the-bear/tom_ai_build/tom_som_go_runtime"
)

// metricNode is a content-bearing element facade fixture: its only field is the
// standard `content` leaf, so it shadows the embedded SomNode default with a
// CanHaveContent() returning true (matching what the emitter emits for a
// content-bearing class such as a generated Goals / Metric).
type metricNode struct {
	som.SomNode
}

// Content reads this section's `content` leaf ("" when unset).
func (m metricNode) Content() string { return m.Doc().ContentOr(m.Path() + "/content") }

// SetContent writes this section's `content` leaf.
func (m metricNode) SetContent(v string) { m.Doc().SetContent(m.Path()+"/content", v) }

// CanHaveContent shadows the promoted SomNode false default — this type
// declares the `content` leaf (SOM §21).
func (m metricNode) CanHaveContent() bool { return true }

// leaflessNode is a facade fixture declaring no `content` leaf, so it does NOT
// shadow CanHaveContent and inherits the promoted SomNode false default. In the
// generated facades this shape is a non-section node (a scalar list item):
// every *section* type carries `content` per tom_specs_model_rules.md §10.2.
type leaflessNode struct {
	som.SomNode
}

// TestCanHaveContentBaseDefaultsFalse: the embedded SomNode default (promoted to
// a type that declares no `content` leaf) is false.
func TestCanHaveContentBaseDefaultsFalse(t *testing.T) {
	doc := som.NewSpecDocument()
	c := leaflessNode{SomNode: som.NewSomNode(doc, "PD00")}
	if c.CanHaveContent() {
		t.Fatalf("leaflessNode.CanHaveContent() = true, want false (no `content` leaf)")
	}
}

// TestCanHaveContentBareNodeDefaultsFalse: the base SomNode itself returns false.
func TestCanHaveContentBareNodeDefaultsFalse(t *testing.T) {
	doc := som.NewSpecDocument()
	n := som.NewSomNode(doc, "PD00")
	if n.CanHaveContent() {
		t.Fatalf("SomNode.CanHaveContent() = true, want false (base default)")
	}
}

// TestCanHaveContentBearingTrue: a content-bearing section shadows the default
// and returns true.
func TestCanHaveContentBearingTrue(t *testing.T) {
	doc := som.NewSpecDocument()
	m := metricNode{SomNode: som.NewSomNode(doc, "PD00/METR-ITEM-AB1")}
	if !m.CanHaveContent() {
		t.Fatalf("metricNode.CanHaveContent() = false, want true (content-bearing)")
	}
}

// TestCanHaveContentScalarInheritsFalse: a scalar list item inherits the base
// false default (SomScalar embeds SomNode, adds no override).
func TestCanHaveContentScalarInheritsFalse(t *testing.T) {
	doc := som.NewSpecDocument()
	s := som.NewSomScalar(doc, "PD00/tags-1")
	if s.CanHaveContent() {
		t.Fatalf("SomScalar.CanHaveContent() = true, want false (scalar inherits default)")
	}
}

// TestCanHaveContentIsStructuralNotState: CanHaveContent is a schema predicate,
// independent of any stored value — filling or clearing the content leaf never
// changes the answer, and it is distinct from the state predicates
// HasContent / IsEmpty.
func TestCanHaveContentIsStructuralNotState(t *testing.T) {
	doc := som.NewSpecDocument()
	// Disjoint paths so the leafless node's subtree stays genuinely empty even
	// after the metric's content leaf is filled (IsEmpty checks
	// HasValuesUnder(path)).
	leafless := leaflessNode{SomNode: som.NewSomNode(doc, "CTR00")}
	metric := metricNode{SomNode: som.NewSomNode(doc, "PD00/METR-ITEM-AB1")}

	// Empty vs filled makes no difference to the schema-level answer.
	if leafless.CanHaveContent() {
		t.Fatalf("empty leafless.CanHaveContent() = true, want false")
	}
	if !metric.CanHaveContent() {
		t.Fatalf("empty metric.CanHaveContent() = false, want true")
	}

	metric.SetContent("filled")

	if !metric.CanHaveContent() {
		t.Fatalf("filled metric.CanHaveContent() = false, want true (structural, not state)")
	}
	if leafless.CanHaveContent() {
		t.Fatalf("leafless.CanHaveContent() = true, want false (structural, not state)")
	}

	// Independence from the state predicates: the metric now HAS content (a
	// value is present *now*) and is not empty, yet CanHaveContent (the schema
	// answer) is the same true it was when empty. The leafless node CAN never
	// hold content though it is currently empty.
	if !doc.HasContent(metric.Path() + "/content") {
		t.Fatalf("expected HasContent(metric/content) = true after SetContent")
	}
	if metric.IsEmpty() {
		t.Fatalf("expected metric.IsEmpty() = false after SetContent")
	}
	if !leafless.IsEmpty() {
		t.Fatalf("expected empty leafless.IsEmpty() = true")
	}
	if leafless.CanHaveContent() {
		t.Fatalf("leafless CanHaveContent() must stay false regardless of IsEmpty state")
	}
}
