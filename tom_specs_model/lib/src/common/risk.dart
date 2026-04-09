import 'package:tom_core_kernel/tom_core_kernel.dart';

import 'enums.dart';

/// Risk entry shared across documents.
@tomReflector
class Risk {
  String? riskId;
  String? name;
  String? description;
  Probability? probability;
  Impact? impact;
  String? mitigation;
  String? riskOwner;
  String? reviewFrequency;
}
