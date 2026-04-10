
import 'enums.dart';

/// Risk entry shared across documents.
class Risk {
  String? content;
  String? riskId;
  String? name;
  String? description;
  Probability? probability;
  Impact? impact;
  String? mitigation;
  String? riskOwner;
  String? reviewFrequency;
}
