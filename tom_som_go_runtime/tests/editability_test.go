// Unit tests for the SOM §4.2 version-check classifier SomEditabilityFor and
// its error-returning companion CheckSomModelVersion (SOM §21).
//
// These mirror the Dart reference cases in
// tom_som_dart_runtime/lib/src/som_facade.dart (somEditabilityFor /
// checkSomModelVersion) under the Go empty-string sentinel convention (CS4-D2):
// an absent document stamp is "" (not a pointer), and "" → editable.
package tests

import (
	"testing"

	som "github.com/al-the-bear/tom_ai_build/tom_som_go_runtime"
)

func TestSomEditabilityFor(t *testing.T) {
	cases := []struct {
		name      string
		generated string
		document  string
		want      som.SomEditability
	}{
		// Empty-string sentinel → editable (brand-new, never-stamped document).
		{"empty stamp is editable", "1.2", "", som.SomEditabilityEditable},

		// Same major, older/equal minor → editable.
		{"same major older minor", "1.5", "1.2", som.SomEditabilityEditable},
		{"same major equal minor", "1.2", "1.2", som.SomEditabilityEditable},

		// Same major, newer minor → rejected.
		{"same major newer minor", "1.2", "1.5", som.SomEditabilityRejectedNewerMinor},

		// Different major → cross-major read-only.
		{"different major lower", "2.0", "1.9", som.SomEditabilityReadOnlyCrossMajor},
		{"different major higher", "1.0", "2.0", som.SomEditabilityReadOnlyCrossMajor},

		// Unparseable document stamp → invalid.
		{"unparseable document stamp", "1.2", "not-a-version", som.SomEditabilityInvalidVersion},
		{"document too many parts", "1.2", "1.2.3", som.SomEditabilityInvalidVersion},
		{"document non-numeric", "1.2", "a.b", som.SomEditabilityInvalidVersion},

		// Unparseable generated version → invalid (parity with the Dart parse throw).
		{"unparseable generated version", "bad", "1.0", som.SomEditabilityInvalidVersion},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			got := som.SomEditabilityFor(tc.generated, tc.document)
			if got != tc.want {
				t.Fatalf("SomEditabilityFor(%q, %q) = %d, want %d",
					tc.generated, tc.document, got, tc.want)
			}
		})
	}
}

// CheckSomModelVersion must return an error exactly where the classifier is
// non-editable, and nil exactly where it is editable — the two never diverge.
func TestCheckSomModelVersionDelegates(t *testing.T) {
	cases := []struct {
		name      string
		generated string
		document  string
	}{
		{"empty stamp", "1.2", ""},
		{"same major older minor", "1.5", "1.2"},
		{"same major equal minor", "1.2", "1.2"},
		{"same major newer minor", "1.2", "1.5"},
		{"different major", "2.0", "1.9"},
		{"unparseable document stamp", "1.2", "not-a-version"},
		{"unparseable generated version", "bad", "1.0"},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			wantEditable := som.SomEditabilityFor(tc.generated, tc.document) == som.SomEditabilityEditable
			err := som.CheckSomModelVersion(tc.generated, tc.document)
			if wantEditable && err != nil {
				t.Fatalf("CheckSomModelVersion(%q, %q) = %v, want nil (editable)",
					tc.generated, tc.document, err)
			}
			if !wantEditable && err == nil {
				t.Fatalf("CheckSomModelVersion(%q, %q) = nil, want error (non-editable)",
					tc.generated, tc.document)
			}
		})
	}
}

// The error messages CheckSomModelVersion produces must match the original
// per-case wording (they are the caller-facing contract).
func TestCheckSomModelVersionMessages(t *testing.T) {
	cases := []struct {
		name      string
		generated string
		document  string
		wantMsg   string
	}{
		{
			"cross-major",
			"1.2", "2.0",
			"SomVersionError: document major version 2 differs from the object model major version 1; cross-major documents are read-only",
		},
		{
			"newer minor",
			"1.2", "1.5",
			"SomVersionError: document model version 1.5 is newer than the object model version 1.2; an older object model cannot edit a newer document",
		},
		{
			"invalid document stamp",
			"1.2", "nope",
			"SomVersionError: document model version \"nope\" is not a valid major.minor",
		},
		{
			"invalid generated version",
			"bad", "1.0",
			"SomVersionError: \"bad\" is not a valid major.minor version",
		},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			err := som.CheckSomModelVersion(tc.generated, tc.document)
			if err == nil {
				t.Fatalf("CheckSomModelVersion(%q, %q) = nil, want error",
					tc.generated, tc.document)
			}
			if err.Error() != tc.wantMsg {
				t.Fatalf("CheckSomModelVersion(%q, %q) message =\n  %q\nwant\n  %q",
					tc.generated, tc.document, err.Error(), tc.wantMsg)
			}
		})
	}
}
