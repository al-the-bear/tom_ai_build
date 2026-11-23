module github.com/al-the-bear/tom_ai_build/tom_specs_samples/phase4_codespecs_run/go

go 1.21

require (
	github.com/al-the-bear/tom_ai_build/tom_som_go_runtime v1.12.2
	github.com/al-the-bear/tom_ai_build/tom_som_go_v0 v1.12.0
)

// The non-Dart runtimes are not published: the module proxy holds v1.0.0 and is
// not updated. The sample runs on the checkout's modules.
replace (
	github.com/al-the-bear/tom_ai_build/tom_som_go_runtime => ../../../tom_som_go_runtime
	github.com/al-the-bear/tom_ai_build/tom_som_go_v0 => ../../../tom_som_go_v0
)
