package somruntime

// spec_generation_units.go — the generation-unit register of a document (SOM
// §11.2): the units Phase 4 writes code into, each with the mapper of every
// area it holds. A faithful port of
// `tom_som_dart_runtime/lib/src/spec_generation_units.dart`.
//
// The register is recognised by its annotations, never by class name, exactly
// as validation phase 8 (validateGenerationUnits) recognises it: a **unit** is
// a list item whose class carries `@NoArtifact(generation)` and declares the
// form field `unitId`; a **mapping** is such a list item declaring the form
// field `area`, and belongs to the nearest unit whose path is a prefix of its
// own; an **emitter** is such a list item declaring the form field `emitter`,
// and belongs to its unit the same way.

import (
	"strings"
)

// SpecStandardEmitters are the standard emitters a unit's `emitters` may name
// (`irspecs_ir.md` §10), in the order `irspecs emit` lists them. Validation
// phase 8 reports any other id as `unitEmitterUnknown`.
var SpecStandardEmitters = []string{
	"openapi",
	"jsonschema",
	"icu",
	"asyncapi",
	"markdown",
}

// specIsStandardEmitter reports whether id is one of SpecStandardEmitters
// (case-sensitive).
func specIsStandardEmitter(id string) bool {
	for _, e := range SpecStandardEmitters {
		if e == id {
			return true
		}
	}
	return false
}

// SpecGenerationUnitMapping is one mapping of a generation unit: the area it
// holds and the mapper that writes that area's code for it.
type SpecGenerationUnitMapping struct {
	// Area is the area code, `CE-…`, as stored (trimmed).
	Area string
	// Mapping is the mapper id, e.g. `dart-tom`, as stored (trimmed); "" when
	// unset.
	Mapping string
}

// SpecGenerationUnit is one generation unit the document declares.
type SpecGenerationUnit struct {
	// UnitID is the unit's id — what a section's `units` names, usually the
	// package name.
	UnitID string
	// Kind is `client`, `server`, `shared` or `other`, as stored; "" when unset.
	Kind string
	// Path is the unit's list-item path in the document.
	Path string
	// Mappings are the unit's mappings, in stored order.
	Mappings []SpecGenerationUnitMapping
	// Emitters are the standard emitters the unit ships (`irspecs_ir.md` §10),
	// as stored (trimmed), in stored order; an emitter with no id is left out.
	// Nil in a unit built by hand counts as none; SpecGenerationUnits always
	// sets a non-nil slice.
	Emitters []string
}

// Maps reports whether one of the unit's mappings holds areaCode.
func (u SpecGenerationUnit) Maps(areaCode string) bool {
	for _, m := range u.Mappings {
		if m.Area == areaCode {
			return true
		}
	}
	return false
}

// MappingFor returns the mapper of areaCode — the first mapping that holds it
// — and whether one does (the reference's `null` is `ok == false`).
func (u SpecGenerationUnit) MappingFor(areaCode string) (string, bool) {
	for _, m := range u.Mappings {
		if m.Area == areaCode {
			return m.Mapping, true
		}
	}
	return "", false
}

// specUnitDecl is a unit as the register walk finds it, before duplicates are
// dropped.
type specUnitDecl struct {
	id, kind, path string
}

// specMappingDecl is a mapping as the register walk finds it.
type specMappingDecl struct {
	path, area, mapping string
}

// specEmitterDecl is an emitter as the register walk finds it.
type specEmitterDecl struct {
	path, emitter string
}

// SpecGenerationUnits returns the generation units doc declares, in register
// order: sorted list-path order, each list's items in their stored order — the
// order validation phase 8 visits them in. A unit without a `unitId` is left
// out; a second unit with an id already seen is left out too (phase 8 reports
// it as `duplicateUnitId`). A document without a register declares none (an
// empty, non-nil slice).
func SpecGenerationUnits(model *SpecModel, doc *SpecDocument) []SpecGenerationUnit {
	refl := NewSpecReflection(model)
	var units []specUnitDecl
	var mappings []specMappingDecl
	var emitters []specEmitterDecl
	for _, listPath := range sortedCopy(doc.ListPaths()) {
		for _, item := range doc.ListItems(listPath) {
			res := refl.Resolve(item)
			if res == nil || res.TargetClass == nil {
				continue
			}
			cls := res.TargetClass
			if na := cls.NoArtifact(); na == nil || na.Reason != "generation" {
				continue
			}
			if unitForm := formDeclaring(cls, "unitId"); unitForm != nil {
				formPath := SpecPathJoin(item, refl.FieldSegment(unitForm))
				id := strings.TrimSpace(doc.FormFieldOr(formPath, "unitId"))
				if id != "" {
					units = append(units, specUnitDecl{
						id:   id,
						kind: strings.TrimSpace(doc.FormFieldOr(formPath, "kind")),
						path: item,
					})
				}
			}
			if areaForm := formDeclaring(cls, "area"); areaForm != nil {
				formPath := SpecPathJoin(item, refl.FieldSegment(areaForm))
				area := strings.TrimSpace(doc.FormFieldOr(formPath, "area"))
				if area != "" {
					mappings = append(mappings, specMappingDecl{
						path:    item,
						area:    area,
						mapping: strings.TrimSpace(doc.FormFieldOr(formPath, "mapping")),
					})
				}
			}
			if emitterForm := formDeclaring(cls, "emitter"); emitterForm != nil {
				formPath := SpecPathJoin(item, refl.FieldSegment(emitterForm))
				emitter := strings.TrimSpace(doc.FormFieldOr(formPath, "emitter"))
				if emitter != "" {
					emitters = append(emitters, specEmitterDecl{path: item, emitter: emitter})
				}
			}
		}
	}

	seen := map[string]bool{}
	out := []SpecGenerationUnit{}
	for _, u := range units {
		if seen[u.id] {
			continue
		}
		seen[u.id] = true
		ms := []SpecGenerationUnitMapping{}
		for _, m := range mappings {
			if specUnitOwner(m.path, units) == u.path {
				ms = append(ms, SpecGenerationUnitMapping{Area: m.area, Mapping: m.mapping})
			}
		}
		es := []string{}
		for _, e := range emitters {
			if specUnitOwner(e.path, units) == u.path {
				es = append(es, e.emitter)
			}
		}
		out = append(out, SpecGenerationUnit{
			UnitID: u.id, Kind: u.kind, Path: u.path, Mappings: ms, Emitters: es,
		})
	}
	return out
}

// SpecDefaultUnits returns the ids of the units whose mappings hold areaCode,
// in register order — the default destination of a section routed to that
// area (SOM §11.2). Always a non-nil slice.
func SpecDefaultUnits(units []SpecGenerationUnit, areaCode string) []string {
	out := []string{}
	for _, u := range units {
		if u.Maps(areaCode) {
			out = append(out, u.UnitID)
		}
	}
	return out
}

// specUnitOwner returns the path of the unit a mapping or emitter at
// mappingPath belongs to: the longest unit path that is a proper prefix of it,
// or "".
func specUnitOwner(mappingPath string, units []specUnitDecl) string {
	best := ""
	found := false
	for _, u := range units {
		if strings.HasPrefix(mappingPath, u.path+"/") && (!found || len(u.path) > len(best)) {
			best = u.path
			found = true
		}
	}
	return best
}
