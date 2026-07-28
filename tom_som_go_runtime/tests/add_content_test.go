// Behavioural tests for the SomList content conveniences AddContent / Contents
// (SOM §21) — the Go port of the Dart SomList.addContent /
// SomList.contents.
//
// AddContent appends a content-only item and writes its nested "<itemPath>/content"
// leaf in one call; Contents yields every item's content leaf in order, reading
// "" for a missing leaf (the Go empty-string sentinel). Both target the nested
// <item>/content leaf — scalar/string lists (value at the item path itself) are
// out of scope.
package tests

import (
	"testing"

	som "github.com/al-the-bear/tom_ai_build/tom_som_go_runtime"
)

// contentItem is a content-only element facade fixture: it embeds SomNode and
// exposes its nested "<itemPath>/content" leaf, mirroring what the emitter emits
// for a complex list item with a single content leaf.
type contentItem struct {
	som.SomNode
}

// Content reads this item's nested content leaf ("" when unset).
func (c contentItem) Content() string { return c.Doc().ContentOr(c.Path() + "/content") }

// newContentItem is the factory the SomList wraps each item path with.
func newContentItem(doc *som.SpecDocument, path string) contentItem {
	return contentItem{SomNode: som.NewSomNode(doc, path)}
}

// TestAddContentAppendsAndSetsLeaf: a pattern-less AddContent appends an item and
// sets its nested content leaf, visible both via the handle and the generic doc.
func TestAddContentAppendsAndSetsLeaf(t *testing.T) {
	doc := som.NewSpecDocument()
	list := newList(doc, "")

	item := list.AddContent("hello")

	if list.Length() != 1 {
		t.Fatalf("Length() = %d, want 1", list.Length())
	}
	// Visible via the element handle.
	if item.Content() != "hello" {
		t.Fatalf("item.Content() = %q, want %q", item.Content(), "hello")
	}
	// Visible via the generic document path (the two access paths share one doc).
	if got := doc.ContentOr(item.Path() + "/content"); got != "hello" {
		t.Fatalf("doc.ContentOr(%q) = %q, want %q", item.Path()+"/content", got, "hello")
	}
}

// wire the list to the same doc the test inspects — NewSomList takes the doc.
func newList(doc *som.SpecDocument, pattern string) *som.SomList[contentItem] {
	return som.NewSomList(doc, "root/items", newContentItem, pattern)
}

// TestAddContentHonoursSectionIDPattern: with a pattern, AddContent assigns a
// generated section id derived from that pattern.
func TestAddContentHonoursSectionIDPattern(t *testing.T) {
	doc := som.NewSpecDocument()
	list := newList(doc, "ITEM-xxx")

	item := list.AddContentOn("first", 3, 14)

	if item.SectionID() == "" {
		t.Fatalf("AddContentOn assigned no section id for a patterned list")
	}
	if item.Content() != "first" {
		t.Fatalf("item.Content() = %q, want %q", item.Content(), "first")
	}
	if got := list.SectionIDs(); len(got) != 1 || got[0] != item.SectionID() {
		t.Fatalf("SectionIDs() = %v, want [%q]", got, item.SectionID())
	}
}

// TestAddContentSequentialIDsIncrement: two AddContentOn calls on the same day
// yield distinct, sequential section ids (the override/derivation path is shared
// with Add).
func TestAddContentSequentialIDsIncrement(t *testing.T) {
	doc := som.NewSpecDocument()
	list := newList(doc, "ITEM-xxx")

	a := list.AddContentOn("a", 3, 14)
	b := list.AddContentOn("b", 3, 14)

	if a.SectionID() == b.SectionID() {
		t.Fatalf("expected distinct section ids, both = %q", a.SectionID())
	}
	if a.Content() != "a" || b.Content() != "b" {
		t.Fatalf("contents = %q,%q want a,b", a.Content(), b.Content())
	}
}

// TestContentsYieldsOrderedContent: Contents returns each item's content leaf in
// item order.
func TestContentsYieldsOrderedContent(t *testing.T) {
	doc := som.NewSpecDocument()
	list := newList(doc, "")

	list.AddContent("one")
	list.AddContent("two")
	list.AddContent("three")

	got := list.Contents()
	want := []string{"one", "two", "three"}
	if len(got) != len(want) {
		t.Fatalf("Contents() = %v, want %v", got, want)
	}
	for i := range want {
		if got[i] != want[i] {
			t.Fatalf("Contents()[%d] = %q, want %q", i, got[i], want[i])
		}
	}
}

// TestContentsReadsEmptyForMissingLeaf: an item added without a content leaf
// (plain Add) reads "" in Contents, interleaved with content-bearing items.
func TestContentsReadsEmptyForMissingLeaf(t *testing.T) {
	doc := som.NewSpecDocument()
	list := newList(doc, "")

	list.AddContent("first")
	list.Add() // no content leaf set → reads as ""
	list.AddContent("third")

	got := list.Contents()
	want := []string{"first", "", "third"}
	if len(got) != len(want) {
		t.Fatalf("Contents() = %v, want %v", got, want)
	}
	for i := range want {
		if got[i] != want[i] {
			t.Fatalf("Contents()[%d] = %q, want %q", i, got[i], want[i])
		}
	}
}
