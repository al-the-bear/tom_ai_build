// Package somruntime is the generic Go runtime for TomSpecs object models.
//
// It provides the language-agnostic, path-keyed document representation that the
// generated typed facade (`tom_som_go_v0`, package `somv0`) edits through:
//
//   - SpecDocument — a sparse, live instance of a TomSpecs document, keyed by the
//     globally-unique section-ID path (content / form / list stores);
//   - SpecModel / SpecReflection — the class graph and reflection helpers;
//   - the version editability rules (CheckSomModelVersion / CanEditSomModel);
//   - markdown & YAML (de)serialisation of a document.
//
// It is a faithful port of `tom_som_dart_runtime` (Dart) and the TypeScript
// `tom_som_typescript_runtime`: the same sparse "empty = no value" model, the
// same deterministic section-ID ordering, and byte-identical serialised output.
//
// # Module path and versioning
//
// The module is published under its domain-qualified path
// `github.com/al-the-bear/tom_ai_build/tom_som_go_runtime`. Go has no central
// package registry — a version is a VCS tag on this module. Each release is
// tagged `vMAJOR.MINOR.PATCH`, matching the TomSpecs object-model version the
// runtime targets, and that same value is mirrored in the in-source [Version]
// constant so a build can report the version it was compiled from without VCS
// access.
//
// To pin a specific version from a consumer:
//
//	go get github.com/al-the-bear/tom_ai_build/tom_som_go_runtime@v1.0.0
package somruntime

// Version is the semantic version of this runtime module (vMAJOR.MINOR.PATCH),
// matching the TomSpecs object-model version it targets. It is the in-source
// counterpart of the VCS tag used to pin the module.
const Version = "v1.0.0"
