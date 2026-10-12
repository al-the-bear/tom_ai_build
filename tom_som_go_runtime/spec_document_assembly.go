// Assembling one spec document from fragments written in parallel — a port of
// `tom_som_dart_runtime/lib/src/spec_document_assembly.dart`.
//
// A large document is often authored in parts — one group, or one agent, per
// set of sections — each part a document of its own holding a subset of the
// sections. References between parts can only be judged on the whole: the
// instance tier resolves a `refersTo` against the document it is given, so a
// part validated alone reports every reference into another part as dangling.
// AssembleSpecDocuments is the step that produces the whole.
//
// The merge is over the plain-data stores (SpecDocument.ToJSON), and it is
// **refusing**: a value two fragments both write — a content path, a form
// field, a list, a headline, a code-spec location — is an overlap, and an
// assembly with any overlap yields no document. Choosing a winner would make
// the result depend on fragment order, and two parts writing one place is an
// authoring conflict the parts' authors have to settle.

package somruntime

import (
	"sort"
	"strings"
)

// SpecAssemblyFragment is one named fragment of an assembly. Fragments are
// passed as an ordered slice; the order is the order overlaps name them in.
type SpecAssemblyFragment struct {
	Name     string
	Document *SpecDocument
}

// SpecAssemblyOverlap is one place two or more fragments both write.
type SpecAssemblyOverlap struct {
	// Store is `content`, `forms`, `lists`, `headlines` or `codeSpecs`.
	Store string
	// Path is the document path.
	Path string
	// Field is the form field, for the `forms` store; nil otherwise.
	Field *string
	// Fragments are the fragments that write it, in the order they were given.
	Fragments []string
}

// Message is one sentence naming the place and every fragment that writes it.
func (o SpecAssemblyOverlap) Message() string {
	place := o.Path
	if o.Field != nil {
		place = o.Path + " field `" + *o.Field + "`"
	}
	return place + " (" + o.Store + ") is written by " +
		strings.Join(o.Fragments, " and ") +
		" — a place two fragments both write is an authoring conflict, not " +
		"something the assembly may resolve"
}

// String returns Message.
func (o SpecAssemblyOverlap) String() string { return o.Message() }

// SpecDocumentAssembly is the result of AssembleSpecDocuments.
type SpecDocumentAssembly struct {
	// Document is the assembled document; nil when there is any overlap.
	Document *SpecDocument
	// Overlaps lists every overlap, in store order and then path order.
	Overlaps []SpecAssemblyOverlap
}

// Ok reports whether the fragments assembled.
func (a *SpecDocumentAssembly) Ok() bool { return len(a.Overlaps) == 0 }

// assemblyStoreOrder is the fixed order overlaps are reported in.
var assemblyStoreOrder = []string{"content", "forms", "lists", "headlines", "codeSpecs"}

// SpecDocumentAssemble is the Go spelling of the reference's static
// `SpecDocument.assemble`; it is AssembleSpecDocuments.
func SpecDocumentAssemble(fragments []SpecAssemblyFragment) *SpecDocumentAssembly {
	return AssembleSpecDocuments(fragments)
}

// AssembleSpecDocuments merges fragments — name → document, in order — into
// one document. Content, headlines and code-spec locations are one value per
// path, forms are merged field by field, lists are taken whole; a place two
// fragments both write is an overlap, and any overlap leaves Document nil.
func AssembleSpecDocuments(fragments []SpecAssemblyFragment) *SpecDocumentAssembly {
	// store → key → writer fragments; key is the path, or `path\x00field`.
	writers := map[string]map[string][]string{}
	for _, s := range assemblyStoreOrder {
		writers[s] = map[string][]string{}
	}
	merged := &DocumentJson{
		Content:   map[string]string{},
		Forms:     map[string]map[string]string{},
		Lists:     map[string]ListJson{},
		Headlines: map[string]string{},
		CodeSpecs: map[string]string{},
	}
	putPath := func(store string, src, dst map[string]string, name string) {
		for path, value := range src {
			writers[store][path] = append(writers[store][path], name)
			if _, has := dst[path]; !has {
				dst[path] = value
			}
		}
	}

	for _, f := range fragments {
		j := &DocumentJson{}
		if f.Document != nil {
			j = f.Document.ToJSON()
		}
		putPath("content", j.Content, merged.Content, f.Name)
		putPath("headlines", j.Headlines, merged.Headlines, f.Name)
		putPath("codeSpecs", j.CodeSpecs, merged.CodeSpecs, f.Name)
		for path, fields := range j.Forms {
			target, has := merged.Forms[path]
			if !has {
				target = map[string]string{}
				merged.Forms[path] = target
			}
			for field, value := range fields {
				key := path + "\x00" + field
				writers["forms"][key] = append(writers["forms"][key], f.Name)
				if _, has := target[field]; !has {
					target[field] = value
				}
			}
		}
		for path, spec := range j.Lists {
			writers["lists"][path] = append(writers["lists"][path], f.Name)
			if _, has := merged.Lists[path]; !has {
				merged.Lists[path] = spec
			}
		}
	}

	var overlaps []SpecAssemblyOverlap
	for _, store := range assemblyStoreOrder {
		keys := make([]string, 0, len(writers[store]))
		for k := range writers[store] {
			keys = append(keys, k)
		}
		// Dart sorts by UTF-16 code unit; Go's string order is by byte (code
		// point), which differs above the BMP.
		sort.Slice(keys, func(a, b int) bool { return lessUTF16(keys[a], keys[b]) })
		for _, key := range keys {
			who := writers[store][key]
			if len(who) < 2 {
				continue
			}
			o := SpecAssemblyOverlap{Store: store, Path: key, Fragments: append([]string(nil), who...)}
			if sep := strings.IndexByte(key, 0); sep >= 0 {
				field := key[sep+1:]
				o.Path = key[:sep]
				o.Field = &field
			}
			overlaps = append(overlaps, o)
		}
	}
	if len(overlaps) > 0 {
		return &SpecDocumentAssembly{Overlaps: overlaps}
	}
	doc := NewSpecDocument()
	doc.LoadJSON(merged)
	return &SpecDocumentAssembly{Document: doc, Overlaps: []SpecAssemblyOverlap{}}
}

// lessUTF16 orders strings by UTF-16 code unit, as Dart's String.compareTo.
func lessUTF16(a, b string) bool {
	ua, ub := utf16Units(a), utf16Units(b)
	for i := 0; i < len(ua) && i < len(ub); i++ {
		if ua[i] != ub[i] {
			return ua[i] < ub[i]
		}
	}
	return len(ua) < len(ub)
}
