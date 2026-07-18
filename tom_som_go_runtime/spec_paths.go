// Package somruntime is the Go port of the generic TomSpecs object-model runtime
// (`tom_som_dart_runtime`).
//
// It is the value-free, generated-code-free half of the multi-platform spec
// model: a meta-data loader (SpecModel), a reflection/resolution surface
// (SpecReflection), a sparse in-memory document (SpecDocument), a validator, and
// the YAML/Markdown codecs. It has zero external dependencies (Go standard
// library only) and is validated against the shared language-agnostic
// conformance corpus in `tom_som_conformance/corpus`.
package somruntime

import "strings"

// spec_paths.go — the section-path grammar shared by the in-memory document and
// the meta-model traversal, a faithful port of
// `tom_som_dart_runtime/lib/src/spec_paths.dart` (and the TypeScript
// `spec_paths.ts`).
//
// A path is the globally-unique address of a node in a concrete document:
//
//   - the root is the document root's section segment (its @SectionId when
//     present, otherwise the root class name);
//   - a child field appends "/<segment>";
//   - a complex / section field collapses into its target class (no extra
//     segment — the class's children hang directly off the field's path);
//   - a list item appends "-<seq>" to the list field's path (no "/").
//
// Form-field values are not path segments: a @Form section is one path whose
// individual fields are sub-keys inside the document's form store.

// SpecPathSeparator is the path separator between section segments.
const SpecPathSeparator = "/"

// SpecPathJoin joins parent with a child segment using the path separator.
func SpecPathJoin(parent, segment string) string {
	return parent + SpecPathSeparator + segment
}

// SpecPathSegments splits path into its "/"-separated segments. A list-item
// sequence suffix ("<segment>-3") stays attached to its segment.
func SpecPathSegments(path string) []string {
	return strings.Split(path, SpecPathSeparator)
}

// SpecParentPath returns the parent path of path — everything before the
// final "/"-separated segment — or path itself when it has no separator (a
// root path).
func SpecParentPath(path string) string {
	i := strings.LastIndex(path, SpecPathSeparator)
	if i < 0 {
		return path
	}
	return path[:i]
}

// ListItemPath returns the path of the seq-th item appended to the list at
// listPath.
func ListItemPath(listPath string, seq int) string {
	return listPath + "-" + itoa(seq)
}

// ListItemSegment is a list-item segment split into its base segment and
// sequence number.
type ListItemSegment struct {
	Base string
	Seq  int
}

// SplitListItemSegment splits a list-item segment into its base segment and
// sequence number when it ends in "-<digits>", returning ok=false otherwise.
//
// Only an all-digit tail counts, so a hyphenated @SectionId such as CUOPME-OPER-LST is
// never mis-read as a list item.
func SplitListItemSegment(segment string) (ListItemSegment, bool) {
	dash := strings.LastIndex(segment, "-")
	if dash <= 0 || dash == len(segment)-1 {
		return ListItemSegment{}, false
	}
	tail := segment[dash+1:]
	if !isAllDigits(tail) {
		return ListItemSegment{}, false
	}
	return ListItemSegment{Base: segment[:dash], Seq: atoi(tail)}, true
}

// isAllDigits reports whether s is non-empty and composed solely of ASCII
// digits.
func isAllDigits(s string) bool {
	if len(s) == 0 {
		return false
	}
	for i := 0; i < len(s); i++ {
		if s[i] < '0' || s[i] > '9' {
			return false
		}
	}
	return true
}

// itoa renders a non-negative integer without importing strconv at call sites.
func itoa(n int) string {
	if n == 0 {
		return "0"
	}
	neg := n < 0
	if neg {
		n = -n
	}
	var buf [20]byte
	i := len(buf)
	for n > 0 {
		i--
		buf[i] = byte('0' + n%10)
		n /= 10
	}
	if neg {
		i--
		buf[i] = '-'
	}
	return string(buf[i:])
}

// atoi parses an all-digit (optionally leading-'-') string to an int. Callers
// guarantee the format via isAllDigits / a digit regexp first.
func atoi(s string) int {
	n := 0
	i := 0
	neg := false
	if len(s) > 0 && (s[0] == '-' || s[0] == '+') {
		neg = s[0] == '-'
		i = 1
	}
	for ; i < len(s); i++ {
		n = n*10 + int(s[i]-'0')
	}
	if neg {
		return -n
	}
	return n
}
