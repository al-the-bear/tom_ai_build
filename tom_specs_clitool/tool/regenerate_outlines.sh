#!/usr/bin/env bash
# Regenerate every committed document outline in
# tom_specs_model/doc/outlines/ from the live Dart model, using the current
# outliner. Run from the tom_specs_clitool package root:
#
#   ./tool/regenerate_outlines.sh
#
# Keeping this as a single script means the committed outlines cannot silently
# drift from the model (YRE1): re-run it after any model-shape change and commit
# the diff. Each root is one of the D00..D13 @Document classes; the output file
# name drops the D<nn> code (matching the established doc/outlines/ convention).
set -euo pipefail

PKG="../tom_specs_model"
OUT="../tom_specs_model/doc/outlines"

# root class name -> output file stem (without the D<nn> document code)
ROOTS=(
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

echo "Done. Review the diff under $OUT/ and commit."
