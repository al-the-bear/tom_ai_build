#!/usr/bin/env bash
# Regenerate every committed document outline in
# tom_specs_model/generated-doc/outlines/ from the live Dart model, using the
# current outliner. Run from the tom_specs_clitool package root:
#
#   ./tool/regenerate_outlines.sh
#
# Keeping this as a single script means the committed outlines cannot silently
# drift from the model (YRE1): re-run it after any model-shape change and commit
# the diff. The roots are the DocSpecsProject tree root plus the D00..D13
# @Document classes; the output file name drops the D<nn> code.
set -euo pipefail

PKG="../tom_specs_model"
OUT="../tom_specs_model/generated-doc/outlines"

# root class name -> output file stem (without the D<nn> document code)
ROOTS=(
  "DocSpecsProject:DocSpecsProject"
  "D00SolutionBlueprint:SolutionBlueprint"
  "D01CurrentLandscapeAssessment:CurrentLandscapeAssessment"
  "D02TargetOperatingModel:TargetOperatingModel"
  "D03InformationModel:InformationModel"
  "D04RequirementsSpecification:RequirementsSpecification"
  "D05InteractionScenarios:InteractionScenarios"
  "D06ArchitectureTechnologySpecification:ArchitectureTechnologySpecification"
  "D07IntegrationInterfaceSpecification:IntegrationInterfaceSpecification"
  "D08SecurityAccessSpecification:SecurityAccessSpecification"
  "D09ExperienceDesignSpecification:ExperienceDesignSpecification"
  "D10QualityAcceptancePlan:QualityAcceptancePlan"
  "D11DeliveryRoadmap:DeliveryRoadmap"
  "D12TransitionRolloutPlan:TransitionRolloutPlan"
  "D13CodeSpecsProjection:CodeSpecsProjection"
)

for entry in "${ROOTS[@]}"; do
  root="${entry%%:*}"
  stem="${entry##*:}"
  echo "→ ${stem}_outline.md"
  dart run bin/outliner.dart --package "$PKG" --root-type "$root" \
    -o "$OUT/${stem}_outline.md"
done

# Compact SolutionBlueprint outline (stops expansion at @DetailedIn boundaries).
echo "→ SolutionBlueprint_compact_outline.md"
dart run bin/outliner.dart --package "$PKG" --root-type D00SolutionBlueprint \
  --stop-at-detailed-in \
  -o "$OUT/SolutionBlueprint_compact_outline.md"

# The doc folder's inline quest-todo citations. Runs here rather than in a
# script of its own because this is the one entrypoint a documentation pass
# already invokes, and a citation goes stale from either side: a doc edit that
# names the wrong id, or a todo archive that closes an id a doc still cites.
# Non-zero exits abort under `set -e`, which is the point — the check is a gate.
echo "→ todo citations in the doc folder"
dart run bin/check_todo_citations.dart

# The same reasoning for `§` section citations, which decay from either side
# too: a citation written against the wrong number, or a restructure that moves
# the heading out from under a citation nobody re-read.
echo "→ section citations in the doc folder and its READMEs"
dart run bin/check_section_citations.dart

# And for `OE-` ids, whose citing side is shipped source rather than a document.
# The register was once a pair of quest files that a consolidation deleted
# without folding in, leaving 71 citations resolving to nothing; this makes the
# next such deletion fail here instead of decaying unseen.
echo "→ OE- citations in the editor, the doc folder and the quest files"
dart run bin/check_oe_citations.dart

echo "Done. Review the diff under $OUT/ and commit."
