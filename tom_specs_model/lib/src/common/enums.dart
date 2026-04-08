/// Enums shared across TomSpecs document models.
library;

import 'package:tom_core_kernel/tom_core_kernel.dart';

/// Section type in DocSpecs annotations.
@tomReflector
enum SectionType { description, form, code }

/// Priority level for requirements.
@tomReflector
enum Priority { must, should, could, wontThisTime }

/// Status of a requirement or deliverable.
@tomReflector
enum Status { draft, proposed, approved, implemented, verified, deferred, rejected }

/// Probability level for risks.
@tomReflector
enum Probability { veryLow, low, medium, high, veryHigh }

/// Impact level for risks.
@tomReflector
enum Impact { negligible, minor, moderate, major, critical }
