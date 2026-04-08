import 'enums.dart';

/// Risk entry shared across documents.
class Risk {
  final String riskId;
  final String name;
  final String description;
  final Probability probability;
  final Impact impact;
  final String mitigation;
  final String? riskOwner;
  final String? reviewFrequency;

  const Risk({
    required this.riskId,
    required this.name,
    required this.description,
    required this.probability,
    required this.impact,
    required this.mitigation,
    this.riskOwner,
    this.reviewFrequency,
  });
}
