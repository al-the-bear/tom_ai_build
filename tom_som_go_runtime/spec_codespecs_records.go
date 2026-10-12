package somruntime

// spec_codespecs_records.go — reading back what a Phase-4 run wrote: the
// per-area **extract** files and the Stage-B **gate record**
// (`codespecs_mapping.md` §1.1.1, `codespecs_prompt.md` §6.3), a faithful port
// of `tom_som_dart_runtime/lib/src/spec_codespecs_records.dart`.
//
// The extractor (CodeSpecsExtractor) writes `<CE-CODE>.extract.yaml`; this file
// is the other half, so a consumer that did not run the extractor — a
// validator, an editor tool, an agent asking which areas are in scope — reads
// the files with the same rules everywhere instead of re-deriving the shape.
// The gate record has a writer here too, because it is otherwise written by
// hand and only checked when something reads it.
//
// Both readers **refuse** an unknown `formatVersion`: a later format that moved
// a key would otherwise read as an extract with no entries, or a scope with no
// verdicts, and a check with no input passes.
//
// # Go's stand-ins for the reference's optionals, throw and Map
//
//   - The reference throws CodeSpecsRecordError; this port returns it as the
//     `error` result, the package's error convention.
//   - The reference's nullable strings (an entry's headline, a gate entry's
//     resolution and note) are plain strings whose "" means *absent*, as in
//     CodeSpecsExtractEntry. So `note: ""` reads as no note and is not written
//     back. A present-but-empty `resolution: ""` is still refused, as the
//     reference refuses it.
//   - The reference's `fromFiles(Map<String, String>)` relies on Dart's
//     insertion-ordered map; Go maps are unordered, so the files are an ordered
//     []CodeSpecsFile.
//   - The YAML is read with the package's own reader (YamlParseTyped, the
//     reader the docspecs YAML load path uses). It does not report syntax
//     errors or duplicate keys, so the reference's "is not valid YAML" error has
//     no counterpart here, and an empty `key:` reads as an empty mapping — which
//     the helpers below treat as the reference's null.

import (
	"os"
	"path/filepath"
	"regexp"
	"sort"
	"strconv"
	"strings"
)

// CodeSpecsGateRecordFile is the file name of the gate record, written beside
// the extracts. Fixed so a partial pass cannot hide its record under a name no
// reader looks for.
const CodeSpecsGateRecordFile = "gate.verdicts.yaml"

// CodeSpecsGateRecordFormatVersion is the gate record `formatVersion` this
// runtime reads and writes.
const CodeSpecsGateRecordFormatVersion = 1

// CodeSpecsExtractFileSuffix is the suffix every extract artifact of record
// carries.
const CodeSpecsExtractFileSuffix = ".extract.yaml"

// CodeSpecsGateDescoped is the one resolution a gate record may carry: an
// insufficient area the user decided to leave out.
const CodeSpecsGateDescoped = "descoped"

var codeSpecsAreaCodePattern = regexp.MustCompile(`^CE-[A-Z]+$`)

// CodeSpecsRecordError is a malformed or unreadable extract file or gate record.
type CodeSpecsRecordError struct {
	// Message is what is wrong, naming the file it was read from.
	Message string
}

// Error renders the failure, matching the reference's toString().
func (e *CodeSpecsRecordError) Error() string {
	return "CodeSpecsRecordError: " + e.Message
}

func csrErr(message string) error { return &CodeSpecsRecordError{Message: message} }

// ---------------------------------------------------------------------------
// Extract files
// ---------------------------------------------------------------------------

// ParseCodeSpecsExtractYaml parses one `<CE-CODE>.extract.yaml`. source names
// the file in errors.
//
// Only `extract.formatVersion` and `extract.area.code` are required; any other
// absent key reads as empty (a string as "", a list as empty), so a
// hand-written fixture stays readable. A key that is present with the wrong
// type is an error, and so is a `document.entryCount` that disagrees with the
// entries — a truncated file would otherwise read as a complete one.
//
// The inverse of CodeSpecsExtract.ToYaml: for any extract the extractor wrote,
// parsing x.ToYaml() and writing it again gives the same bytes.
func ParseCodeSpecsExtractYaml(text, source string) (*CodeSpecsExtract, error) {
	name := source
	if name == "" {
		name = "the extract"
	}
	root, err := csrRootMapping(text, name, "extract")
	if err != nil {
		return nil, err
	}
	version := csrGet(root, "formatVersion")
	if !csrNumEquals(version, CodeSpecsExtractFormatVersion) {
		return nil, csrErr(name + " declares extract format " + csrShow(version) +
			"; this reader understands " + itoa(CodeSpecsExtractFormatVersion) +
			" only — reading it would silently drop entries")
	}
	area, ok := csrGet(root, "area").(*YamlMap)
	if !ok {
		return nil, csrErr(name + " has no `area:` mapping")
	}
	code, err := csrStr(csrGet(area, "code"), name, "area.code")
	if err != nil {
		return nil, err
	}
	if code == "" {
		return nil, csrErr(name + " names no area code")
	}
	part, err := csrStr(csrGet(area, "part"), name, "area.part")
	if err != nil {
		return nil, err
	}
	part = strings.TrimPrefix(part, "CodeSpecPart.")
	documentNode := csrGet(root, "document")
	document, isMap := documentNode.(*YamlMap)
	if documentNode != nil && !isMap {
		return nil, csrErr(name + ": `document` must be a mapping")
	}
	entriesNode := csrGet(root, "entries")
	rawEntries, isList := entriesNode.([]interface{})
	if entriesNode != nil && !isList {
		return nil, csrErr(name + ": `entries` must be a list")
	}
	entries := []CodeSpecsExtractEntry{}
	for _, raw := range rawEntries {
		m, ok := raw.(*YamlMap)
		if !ok {
			return nil, csrErr(name + " has an entry that is not a mapping")
		}
		var firstErr error
		req := func(key string) string {
			v, err := csrStr(csrGet(m, key), name, "entries[]."+key)
			if err != nil && firstErr == nil {
				firstErr = err
			}
			return v
		}
		opt := func(key string) string {
			v, err := csrOptStr(csrGet(m, key), name, "entries[]."+key)
			if err != nil && firstErr == nil {
				firstErr = err
			}
			return v
		}
		e := CodeSpecsExtractEntry{AreaCode: code}
		e.SectionID = req("sectionId")
		e.Headline = opt("headline")
		e.InstanceID = opt("instanceId")
		e.Path = req("path")
		e.ClassName = req("className")
		e.FieldName = req("fieldName")
		e.FormField = opt("formField")
		e.RoutedBy = req("routedBy")
		e.RoutedAt = req("routedAt")
		e.RoutingNote = opt("routingNote")
		e.Value = req("value")
		if firstErr != nil {
			return nil, firstErr
		}
		entries = append(entries, e)
	}
	if document != nil {
		if declared := csrGet(document, "entryCount"); declared != nil &&
			!csrNumEquals(declared, len(entries)) {
			return nil, csrErr(name + " declares entryCount " + csrShow(declared) +
				" but carries " + itoa(len(entries)) +
				" entries — a truncated extract must not read as a complete one")
		}
	}

	x := &CodeSpecsExtract{Area: &CodeSpecsArea{Code: code, Part: part, Active: true}}
	var firstErr error
	keep := func(err error) {
		if err != nil && firstErr == nil {
			firstErr = err
		}
	}
	var e error
	x.Area.CanonicalID, e = csrStr(csrGet(area, "canonicalId"), name, "area.canonicalId")
	keep(e)
	x.Area.Annotations, e = csrStrList(csrGet(area, "annotations"), name, "area.annotations")
	keep(e)
	x.Area.BuiltOn, e = csrStr(csrGet(area, "builtOn"), name, "area.builtOn")
	keep(e)
	x.Area.AttributeSurface, e = csrStr(csrGet(area, "attributeSurface"), name, "area.attributeSurface")
	keep(e)
	x.Area.Slices, e = csrIntList(csrGet(area, "slices"), name, "area.slices")
	keep(e)
	x.Area.AuthoringSteps, e = csrIntList(csrGet(area, "authoringSteps"), name, "area.authoringSteps")
	keep(e)
	var docRoot interface{}
	if document != nil {
		docRoot = csrGet(document, "root")
	}
	x.DocumentRoot, e = csrStr(docRoot, name, "document.root")
	keep(e)
	x.CatalogSource, e = csrStr(csrGet(root, "catalogSource"), name, "catalogSource")
	keep(e)
	x.Projects, e = csrStrList(csrGet(area, "projects"), name, "area.projects")
	keep(e)
	x.CitableParts, e = csrStrList(csrGet(area, "citableParts"), name, "area.citableParts")
	keep(e)
	if firstErr != nil {
		return nil, firstErr
	}
	x.Entries = entries
	return x, nil
}

// CodeSpecsExtractFromYaml is ParseCodeSpecsExtractYaml under the name the
// reference exposes it by (`CodeSpecsExtract.fromYaml`).
func CodeSpecsExtractFromYaml(text, source string) (*CodeSpecsExtract, error) {
	return ParseCodeSpecsExtractYaml(text, source)
}

// ---------------------------------------------------------------------------
// The gate record
// ---------------------------------------------------------------------------

// The three per-area verdicts of `codespecs_prompt.md` §6.2. The values are the
// verdict words exactly as §6.2 states them.
const (
	// CodeSpecsGateSufficient: the extract carries every input the derivation
	// contract requires.
	CodeSpecsGateSufficient = "sufficient"
	// CodeSpecsGateNotApplicable: the area does not apply — nothing was routed,
	// with positive evidence of absence (`codespecs_prompt.md` §6.4).
	CodeSpecsGateNotApplicable = "not applicable"
	// CodeSpecsGateInsufficient: the extract is missing required inputs; only a
	// recorded descope lets a run continue without the area.
	CodeSpecsGateInsufficient = "insufficient"
)

// CodeSpecsGateVerdict is one of the CodeSpecsGate* verdict constants. A string
// alias, like CodeSpecsRoutingVerdict, whose value is the reference's `word`.
type CodeSpecsGateVerdict = string

// ParseCodeSpecsGateVerdict returns the verdict for word, and false for a word
// §6.2 does not know.
func ParseCodeSpecsGateVerdict(word string) (CodeSpecsGateVerdict, bool) {
	switch word {
	case CodeSpecsGateSufficient, CodeSpecsGateNotApplicable, CodeSpecsGateInsufficient:
		return word, true
	}
	return "", false
}

// CodeSpecsGateEntry is one area's recorded verdict. Shape is checked by
// CodeSpecsGateRecord, which is the only thing that reads or writes entries.
type CodeSpecsGateEntry struct {
	// Area is the area's `CE-*` code.
	Area string
	// Verdict is the verdict word.
	Verdict CodeSpecsGateVerdict
	// Resolution is `descoped`, on an insufficient area only; "" otherwise.
	Resolution string
	// Note is a free-text note — why the verdict was taken; "" for none. Never
	// read as data.
	Note string
}

// Descoped reports whether this is an insufficient area resolved by descoping.
func (e CodeSpecsGateEntry) Descoped() bool { return e.Resolution == CodeSpecsGateDescoped }

// CodeSpecsGateRecord is the Stage-B gate record, `gate.verdicts.yaml`
// (`codespecs_prompt.md` §6.3).
//
// Constructing one checks it: every area is a `CE-*` code named once, and a
// `resolution:` appears only as `descoped` on an insufficient area. So a
// record that exists is a record of the checked shape, whether it was read or
// built to be written.
type CodeSpecsGateRecord struct {
	// Verdicts are the verdicts, in the order they were recorded.
	Verdicts []CodeSpecsGateEntry
}

// NewCodeSpecsGateRecord creates and checks a record; it fails with a
// CodeSpecsRecordError on a shape `codespecs_prompt.md` §6.3 does not allow.
// source names it in errors ("" means CodeSpecsGateRecordFile).
func NewCodeSpecsGateRecord(verdicts []CodeSpecsGateEntry, source string) (*CodeSpecsGateRecord, error) {
	if source == "" {
		source = CodeSpecsGateRecordFile
	}
	r := &CodeSpecsGateRecord{Verdicts: append([]CodeSpecsGateEntry{}, verdicts...)}
	if err := r.check(source); err != nil {
		return nil, err
	}
	return r, nil
}

var codeSpecsGateEntryKeys = map[string]bool{
	"area": true, "verdict": true, "resolution": true, "note": true,
}

// CodeSpecsGateRecordFromYaml parses `gate.verdicts.yaml`. source names the
// file in errors ("" means CodeSpecsGateRecordFile).
func CodeSpecsGateRecordFromYaml(text, source string) (*CodeSpecsGateRecord, error) {
	if source == "" {
		source = CodeSpecsGateRecordFile
	}
	root, err := csrRootMapping(text, source, "gate")
	if err != nil {
		return nil, err
	}
	for _, key := range root.Keys() {
		if key != "formatVersion" && key != "verdicts" {
			return nil, csrErr(source + " has an unknown key `gate." + key +
				"` — the record knows `formatVersion` and `verdicts` only")
		}
	}
	version := csrGet(root, "formatVersion")
	if !csrNumEquals(version, CodeSpecsGateRecordFormatVersion) {
		return nil, csrErr(source + " declares gate record format " + csrShow(version) +
			"; this reader understands " + itoa(CodeSpecsGateRecordFormatVersion) +
			" only — reading it would silently change the scope")
	}
	list, ok := csrGet(root, "verdicts").([]interface{})
	if !ok {
		return nil, csrErr(source + " has no `verdicts:` list")
	}
	entries := []CodeSpecsGateEntry{}
	for _, raw := range list {
		m, ok := raw.(*YamlMap)
		if !ok {
			return nil, csrErr(source + " has a verdict that is not a mapping")
		}
		for _, key := range m.Keys() {
			if !codeSpecsGateEntryKeys[key] {
				return nil, csrErr(source + " has an unknown key `" + key +
					"` in a verdict — an entry knows `area`, `verdict`, " +
					"`resolution` and `note` only")
			}
		}
		area, err := csrStr(csrGet(m, "area"), source, "verdicts[].area")
		if err != nil {
			return nil, err
		}
		word, err := csrStr(csrGet(m, "verdict"), source, "verdicts[].verdict")
		if err != nil {
			return nil, err
		}
		verdict, ok := ParseCodeSpecsGateVerdict(word)
		if !ok {
			return nil, csrErr(source + " gives " + area + " the verdict `" + word +
				"` — codespecs_prompt.md §6.2 knows `sufficient`, " +
				"`not applicable` and `insufficient` only")
		}
		rawResolution := csrGet(m, "resolution")
		resolution, err := csrOptStr(rawResolution, source, "verdicts[].resolution")
		if err != nil {
			return nil, err
		}
		if rawResolution != nil && resolution == "" {
			// Present but empty: the reference checks it as the resolution ``;
			// "" is this port's absent, so refuse it here with the same words.
			return nil, csrErr(source + " gives " + area + " the resolution `` — " +
				"`descoped` is the one resolution that admits a partial pass; " +
				"any other resolution means the area was completed and its " +
				"verdict re-taken")
		}
		note, err := csrOptStr(csrGet(m, "note"), source, "verdicts[].note")
		if err != nil {
			return nil, err
		}
		entries = append(entries, CodeSpecsGateEntry{
			Area: area, Verdict: verdict, Resolution: resolution, Note: note,
		})
	}
	return NewCodeSpecsGateRecord(entries, source)
}

func (r *CodeSpecsGateRecord) check(source string) error {
	seen := map[string]bool{}
	for _, e := range r.Verdicts {
		if e.Area == "" {
			return csrErr(source + " has a verdict that names no area")
		}
		if !codeSpecsAreaCodePattern.MatchString(e.Area) {
			return csrErr(source + " names the area `" + e.Area +
				"`, which is not a CE-* code")
		}
		if seen[e.Area] {
			return csrErr(source + " carries two verdicts for " + e.Area +
				" — a scope with two answers for one area is no scope")
		}
		seen[e.Area] = true
		if _, ok := ParseCodeSpecsGateVerdict(e.Verdict); !ok {
			return csrErr(source + " gives " + e.Area + " the verdict `" + e.Verdict +
				"` — codespecs_prompt.md §6.2 knows `sufficient`, " +
				"`not applicable` and `insufficient` only")
		}
		if e.Resolution == "" {
			continue
		}
		if e.Verdict != CodeSpecsGateInsufficient {
			return csrErr(source + " gives " + e.Area + " a `resolution:` on verdict `" +
				e.Verdict + "` — only an insufficient area has an L0 decision to resolve")
		}
		if e.Resolution != CodeSpecsGateDescoped {
			return csrErr(source + " gives " + e.Area + " the resolution `" +
				e.Resolution + "` — `descoped` is the one resolution that admits a " +
				"partial pass; any other resolution means the area was completed " +
				"and its verdict re-taken")
		}
	}
	return nil
}

// VerdictFor returns the entry for area, or nil when the record says nothing
// about it.
func (r *CodeSpecsGateRecord) VerdictFor(area string) *CodeSpecsGateEntry {
	for i := range r.Verdicts {
		if r.Verdicts[i].Area == area {
			return &r.Verdicts[i]
		}
	}
	return nil
}

// CheckAgainst fails with a CodeSpecsRecordError when an area is not an active
// area of catalog — a verdict for an area that does not exist scopes nothing.
// source names the record in errors ("" means CodeSpecsGateRecordFile).
func (r *CodeSpecsGateRecord) CheckAgainst(catalog *CodeSpecsAreaCatalog, source string) error {
	if source == "" {
		source = CodeSpecsGateRecordFile
	}
	for _, e := range r.Verdicts {
		area := catalog.ByCode(e.Area)
		if area == nil || !area.Active {
			return csrErr(source + " gives a verdict for " + e.Area +
				", which is not an active area of the catalogue")
		}
	}
	return nil
}

// WithVerdict returns a copy with entry recorded — replacing the area's earlier
// verdict in place, or appended when the area had none.
func (r *CodeSpecsGateRecord) WithVerdict(entry CodeSpecsGateEntry) (*CodeSpecsGateRecord, error) {
	out := make([]CodeSpecsGateEntry, 0, len(r.Verdicts)+1)
	replaced := false
	for _, e := range r.Verdicts {
		if e.Area == entry.Area {
			out = append(out, entry)
			replaced = true
		} else {
			out = append(out, e)
		}
	}
	if !replaced {
		out = append(out, entry)
	}
	return NewCodeSpecsGateRecord(out, "")
}

// ToYaml writes the record as `gate.verdicts.yaml`. Byte-stable: the same
// record always writes the same text, and reading it back writes it again
// unchanged.
//
// `area` and `verdict` are written plain, as `codespecs_prompt.md` §6.3 shows
// them — both are from a closed vocabulary the constructor checked — and a note
// as a double-quoted scalar, the extract's one escaping rule.
func (r *CodeSpecsGateRecord) ToYaml() string {
	var b strings.Builder
	b.WriteString("gate:\n")
	b.WriteString("  formatVersion: " + itoa(CodeSpecsGateRecordFormatVersion) + "\n")
	if len(r.Verdicts) == 0 {
		b.WriteString("  verdicts: []\n")
		return b.String()
	}
	b.WriteString("  verdicts:\n")
	for _, e := range r.Verdicts {
		b.WriteString("    - area: " + e.Area + "\n")
		b.WriteString("      verdict: " + e.Verdict + "\n")
		if e.Resolution != "" {
			b.WriteString("      resolution: " + e.Resolution + "\n")
		}
		if e.Note != "" {
			b.WriteString("      note: " + cseYamlString(e.Note) + "\n")
		}
	}
	return b.String()
}

// ---------------------------------------------------------------------------
// A tree of extracts, scoped by its gate record
// ---------------------------------------------------------------------------

// CodeSpecsExcludedArea is one area the gate record left out of scope.
//
// Kept visible rather than dropped, so a consumer can say so: a scoped-out
// area must never read as a covered one.
type CodeSpecsExcludedArea struct {
	// Area is the `CE-*` code.
	Area string
	// Verdict is CodeSpecsGateNotApplicable, or CodeSpecsGateInsufficient with a
	// recorded descope.
	Verdict CodeSpecsGateVerdict
	// Descoped reports whether an insufficient verdict was resolved by
	// descoping.
	Descoped bool
	// EntryCount is how many routed entries the excluded extract carried (0
	// with no file).
	EntryCount int
	// Source is the file the excluded extract was read from, or "" when there
	// was none.
	Source string
}

// CodeSpecsFile is one named file of a CodeSpecsExtractSetFromFiles input.
type CodeSpecsFile struct {
	// Name is the file name (a path; its basename decides the role).
	Name string
	// Text is the file's content.
	Text string
}

// CodeSpecsExtractSet is every extract one run produced, read back and scoped
// by its gate record.
type CodeSpecsExtractSet struct {
	// Extracts are the in-scope extracts, in source order. With a gate record:
	// the areas it marks `sufficient`, in the record's order. Without: every
	// extract.
	Extracts []*CodeSpecsExtract
	// Sources are the files each in-scope extract was read from, parallel to
	// Extracts.
	Sources []string
	// Excluded are the areas the gate record excluded — empty without a
	// record.
	Excluded []CodeSpecsExcludedArea
	// Gate is the gate record, when one was among the sources; nil otherwise.
	Gate *CodeSpecsGateRecord
}

// CodeSpecsExtractSetFromFiles reads files — in order — into a scoped set.
//
// The file whose basename is CodeSpecsGateRecordFile is the gate record; every
// other file is an extract. The area code comes from the file's content, never
// its name. With a record, an area is in scope **iff** its verdict is
// `sufficient`, and:
//
//   - the record must carry a verdict for every extract supplied — a scope
//     silent about an area would let a skipped area read as a passed one;
//   - a `not applicable` area whose extract has entries is an error — a routed
//     value is evidence the area applies (`codespecs_prompt.md` §6.4);
//   - an `insufficient` area without `resolution: descoped` is an error — the
//     run may not have continued past it (`codespecs_prompt.md` §6.2).
//
// Two extracts for one area, or two gate records, are errors.
func CodeSpecsExtractSetFromFiles(files []CodeSpecsFile) (*CodeSpecsExtractSet, error) {
	gateName, gateText, haveGate := "", "", false
	extracts := []*CodeSpecsExtract{}
	sources := []string{}
	indexOf := func(code string) int {
		for i, x := range extracts {
			if x.Area.Code == code {
				return i
			}
		}
		return -1
	}
	for _, f := range files {
		basename := f.Name[strings.LastIndex(f.Name, "/")+1:]
		if basename == CodeSpecsGateRecordFile {
			if haveGate {
				return nil, csrErr("both " + gateName + " and " + f.Name +
					" are gate records — the scope must have one author")
			}
			gateName, gateText, haveGate = f.Name, f.Text, true
			continue
		}
		x, err := ParseCodeSpecsExtractYaml(f.Text, f.Name)
		if err != nil {
			return nil, err
		}
		if earlier := indexOf(x.Area.Code); earlier >= 0 {
			return nil, csrErr(sources[earlier] + " and " + f.Name +
				" are both extracts for " + x.Area.Code)
		}
		extracts = append(extracts, x)
		sources = append(sources, f.Name)
	}
	if !haveGate {
		return &CodeSpecsExtractSet{
			Extracts: extracts, Sources: sources, Excluded: []CodeSpecsExcludedArea{},
		}, nil
	}
	gate, err := CodeSpecsGateRecordFromYaml(gateText, gateName)
	if err != nil {
		return nil, err
	}
	for i, x := range extracts {
		if gate.VerdictFor(x.Area.Code) == nil {
			return nil, csrErr(gateName + " carries no verdict for " + x.Area.Code +
				" (" + sources[i] + ") — the gate record must be total over the " +
				"supplied extracts")
		}
	}
	set := &CodeSpecsExtractSet{
		Extracts: []*CodeSpecsExtract{},
		Sources:  []string{},
		Excluded: []CodeSpecsExcludedArea{},
		Gate:     gate,
	}
	for _, v := range gate.Verdicts {
		i := indexOf(v.Area)
		var x *CodeSpecsExtract
		src, count := "", 0
		if i >= 0 {
			x, src, count = extracts[i], sources[i], len(extracts[i].Entries)
		}
		switch v.Verdict {
		case CodeSpecsGateSufficient:
			if x != nil {
				set.Extracts = append(set.Extracts, x)
				set.Sources = append(set.Sources, src)
			}
		case CodeSpecsGateNotApplicable:
			if count > 0 {
				noun := "entries"
				if count == 1 {
					noun = "entry"
				}
				return nil, csrErr(gateName + " marks " + v.Area +
					" `not applicable`, but " + src + " carries " + itoa(count) +
					" routed " + noun + " — a routed value is evidence the area " +
					"applies (codespecs_prompt.md §6.4)")
			}
			set.Excluded = append(set.Excluded, CodeSpecsExcludedArea{
				Area: v.Area, Verdict: v.Verdict, EntryCount: count, Source: src,
			})
		case CodeSpecsGateInsufficient:
			if !v.Descoped() {
				return nil, csrErr(gateName + " marks " + v.Area +
					" `insufficient` without `resolution: descoped` — " +
					"codespecs_prompt.md §6.2 says the run does not continue past " +
					"an unresolved insufficient area; recording the descope is " +
					"what legitimizes a partial pass")
			}
			set.Excluded = append(set.Excluded, CodeSpecsExcludedArea{
				Area: v.Area, Verdict: v.Verdict, Descoped: true,
				EntryCount: count, Source: src,
			})
		}
	}
	return set, nil
}

// CodeSpecsExtractSetFromDirectory reads a directory of extracts —
// `<CE-CODE>.extract.yaml` plus an optional `gate.verdicts.yaml`; other files
// (the `.extract.md` views) are ignored. Files are read in name order, so the
// set is the same on every file system.
func CodeSpecsExtractSetFromDirectory(path string) (*CodeSpecsExtractSet, error) {
	if st, err := os.Stat(path); err != nil || !st.IsDir() {
		return nil, csrErr("extract directory not found: " + path)
	}
	dirEntries, err := os.ReadDir(path)
	if err != nil {
		return nil, csrErr("extract directory not found: " + path)
	}
	names := []string{}
	for _, d := range dirEntries {
		n := d.Name()
		if !d.Type().IsRegular() {
			continue
		}
		if strings.HasSuffix(n, CodeSpecsExtractFileSuffix) || n == CodeSpecsGateRecordFile {
			names = append(names, n)
		}
	}
	sort.Strings(names)
	files := make([]CodeSpecsFile, 0, len(names))
	for _, n := range names {
		b, err := os.ReadFile(filepath.Join(path, n))
		if err != nil {
			return nil, csrErr("cannot read " + n + ": " + err.Error())
		}
		files = append(files, CodeSpecsFile{Name: n, Text: string(b)})
	}
	return CodeSpecsExtractSetFromFiles(files)
}

// ByArea returns the in-scope extract for area, or nil.
func (s *CodeSpecsExtractSet) ByArea(area string) *CodeSpecsExtract {
	for _, x := range s.Extracts {
		if x.Area.Code == area {
			return x
		}
	}
	return nil
}

// EntriesForSection returns every in-scope entry routed from sectionID — the
// back-link token a `DocRef` names — across every area, in extract order.
func (s *CodeSpecsExtractSet) EntriesForSection(sectionID string) []CodeSpecsExtractEntry {
	out := []CodeSpecsExtractEntry{}
	for _, x := range s.Extracts {
		for _, e := range x.Entries {
			if e.SectionID == sectionID {
				out = append(out, e)
			}
		}
	}
	return out
}

// EntriesAtPath returns every in-scope entry read from document path, in
// extract order.
func (s *CodeSpecsExtractSet) EntriesAtPath(path string) []CodeSpecsExtractEntry {
	out := []CodeSpecsExtractEntry{}
	for _, x := range s.Extracts {
		for _, e := range x.Entries {
			if e.Path == path {
				out = append(out, e)
			}
		}
	}
	return out
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

func csrRootMapping(text, name, key string) (*YamlMap, error) {
	document, ok := YamlParseTyped(text).(*YamlMap)
	if !ok {
		return nil, csrErr(name + " does not hold a YAML mapping")
	}
	root, ok := csrGet(document, key).(*YamlMap)
	if !ok {
		return nil, csrErr(name + " has no top-level `" + key + ":` mapping")
	}
	return root, nil
}

// csrGet reads key from m, with the reference's null for an absent key — and
// for an empty `key:`, which the package reader returns as an empty mapping
// where package:yaml returns null.
func csrGet(m *YamlMap, key string) interface{} {
	v, ok := m.Get(key)
	if !ok {
		return nil
	}
	if vm, isMap := v.(*YamlMap); isMap && vm.Len() == 0 {
		return nil
	}
	return v
}

// csrNumEquals is Dart's `==` between a YAML scalar and an int: numbers compare
// by value (`3.0 == 3`), anything else never equals a number.
func csrNumEquals(v interface{}, want int) bool {
	switch n := v.(type) {
	case int:
		return n == want
	case float64:
		return n == float64(want)
	}
	return false
}

// csrShow renders a scalar as Dart's string interpolation shows it.
func csrShow(v interface{}) string {
	switch t := v.(type) {
	case nil:
		return "null"
	case string:
		return t
	case int:
		return itoa(t)
	case bool:
		if t {
			return "true"
		}
		return "false"
	case float64:
		s := strconv.FormatFloat(t, 'f', -1, 64)
		if !strings.ContainsAny(s, ".eEnN") {
			s += ".0"
		}
		return s
	case []interface{}:
		return "[...]"
	}
	return "{...}"
}

func csrStr(v interface{}, name, key string) (string, error) {
	if v == nil {
		return "", nil
	}
	if s, ok := v.(string); ok {
		return s, nil
	}
	return "", csrErr(name + ": `" + key + "` must be a string")
}

func csrOptStr(v interface{}, name, key string) (string, error) {
	if v == nil {
		return "", nil
	}
	if s, ok := v.(string); ok {
		return s, nil
	}
	return "", csrErr(name + ": `" + key + "` must be a string or null")
}

func csrStrList(v interface{}, name, key string) ([]string, error) {
	if v == nil {
		return []string{}, nil
	}
	list, ok := v.([]interface{})
	if !ok {
		return nil, csrErr(name + ": `" + key + "` must be a list")
	}
	out := make([]string, 0, len(list))
	for _, e := range list {
		s, err := csrStr(e, name, key)
		if err != nil {
			return nil, err
		}
		out = append(out, s)
	}
	return out, nil
}

func csrIntList(v interface{}, name, key string) ([]int, error) {
	if v == nil {
		return []int{}, nil
	}
	list, ok := v.([]interface{})
	if !ok {
		return nil, csrErr(name + ": `" + key + "` must be a list")
	}
	out := make([]int, 0, len(list))
	for _, e := range list {
		n, ok := e.(int)
		if !ok {
			return nil, csrErr(name + ": `" + key + "` must hold integers")
		}
		out = append(out, n)
	}
	return out, nil
}
