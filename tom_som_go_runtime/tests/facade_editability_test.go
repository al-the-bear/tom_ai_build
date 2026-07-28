// Behavioural test for the root facade's generated EditabilityFor method
// (SOM §21).
//
// The generated facade (tom_som_go_v0) cannot be regenerated here (that must run
// centrally, once, for all nine languages), so this test hand-writes a minimal
// root facade that mirrors exactly what SomGoEmitter now emits per root:
//
//	const fakeRootModelVersion = "1.2"
//	func (x *fakeRoot) EditabilityFor(documentVersion string) som.SomEditability {
//	    return som.SomEditabilityFor(fakeRootModelVersion, documentVersion)
//	}
//
// It asserts the delegating method returns the same classification as the
// underlying SomEditabilityFor for every SOM §4.2 case.
package tests

import (
	"testing"

	som "github.com/al-the-bear/tom_ai_build/tom_som_go_runtime"
)

// fakeRootModelVersion stands in for the per-root <Root>ModelVersion const the
// emitter allocates.
const fakeRootModelVersion = "1.2"

// fakeRoot is a stand-in for a generated root facade struct (embeds SomNode,
// carries the generated EditabilityFor method delegating to the runtime).
type fakeRoot struct {
	som.SomNode
}

// EditabilityFor mirrors the emitted root method: it delegates to the runtime
// classifier with the root's own model-version const.
func (x *fakeRoot) EditabilityFor(documentVersion string) som.SomEditability {
	return som.SomEditabilityFor(fakeRootModelVersion, documentVersion)
}

func TestRootEditabilityFor(t *testing.T) {
	root := &fakeRoot{SomNode: som.NewSomNode(som.NewSpecDocument(), "root")}

	cases := []struct {
		name     string
		document string
		want     som.SomEditability
	}{
		{"empty stamp editable", "", som.SomEditabilityEditable},
		{"same major older minor editable", "1.0", som.SomEditabilityEditable},
		{"same major equal minor editable", "1.2", som.SomEditabilityEditable},
		{"same major newer minor rejected", "1.5", som.SomEditabilityRejectedNewerMinor},
		{"cross major read-only", "2.0", som.SomEditabilityReadOnlyCrossMajor},
		{"invalid stamp", "bogus", som.SomEditabilityInvalidVersion},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			got := root.EditabilityFor(tc.document)
			if got != tc.want {
				t.Fatalf("root.EditabilityFor(%q) = %d, want %d", tc.document, got, tc.want)
			}
			// The delegating method must agree with the underlying classifier.
			if got != som.SomEditabilityFor(fakeRootModelVersion, tc.document) {
				t.Fatalf("root.EditabilityFor(%q) diverged from SomEditabilityFor", tc.document)
			}
		})
	}
}
