#!/usr/bin/env dart

/// Report a capability the shared contract names that some language plane does
/// not carry — the nine-plane parity check.
///
/// The conformance corpus proves the nine ports agree about what they SHARE, so
/// by construction it cannot see a capability only one of them has. This asks
/// the complementary question, and `lib/src/som_parity.dart` states what it can
/// and cannot see.
///
/// Usage:
///   dart run bin/check_som_parity.dart [--manifest FILE] [--container-root DIR]
///                                      [--verbose]
///
/// Exits 1 when a plane is missing a capability no committed exception
/// accounts for, or when an exception has outlived the gap it acknowledged.
library;

import 'dart:io';

import 'package:args/args.dart';

import 'package:tom_specs_clitool/src/som_parity.dart';

void main(List<String> arguments) {
  final parser = ArgParser()
    ..addOption('manifest', help: 'The acknowledged-asymmetry manifest.')
    ..addOption('container-root', help: 'The workspace root to scan.')
    ..addFlag(
      'verbose',
      abbr: 'v',
      negatable: false,
      help: 'List every contract token checked.',
    )
    ..addFlag('help', abbr: 'h', negatable: false);
  final args = parser.parse(arguments);
  if (args['help'] as bool) {
    stdout.writeln('check_som_parity — nine-plane capability parity\n');
    stdout.writeln(parser.usage);
    return;
  }

  final here = File.fromUri(Platform.script).parent.parent.path;
  final containerRoot =
      (args['container-root'] as String?) ??
      Directory(here).parent.parent.parent.path;
  final aiBuild = '$containerRoot/tom_ai/ai_build';
  final manifestPath =
      (args['manifest'] as String?) ?? '$here/tool/som_parity_exceptions.yaml';

  final vocabulary = contractVocabulary('$aiBuild/tom_som_conformance');
  if (vocabulary.isEmpty) {
    stderr.writeln(
      'check_som_parity: no conformance corpus at $aiBuild — '
      'nothing to check against',
    );
    exit(2);
  }

  final planeTokenSets = <String, Set<String>>{
    for (final plane in somPlanes)
      plane: planeTokens('$aiBuild/tom_som_${plane}_runtime', plane),
  };
  final empty = somPlanes.where((p) => planeTokenSets[p]!.isEmpty).toList();
  if (empty.isNotEmpty) {
    stderr.writeln(
      'check_som_parity: no sources read for ${empty.join(", ")} '
      '— a plane that reads as empty would report every capability missing',
    );
    exit(2);
  }

  final findings = checkParity(vocabulary, planeTokenSets);
  final exceptions = readParityExceptions(manifestPath);
  final live = unacknowledged(findings, exceptions);
  final stale = staleExceptions(findings, exceptions);

  stdout.writeln(
    'check_som_parity: ${vocabulary.length} contract token(s), '
    '${somPlanes.length} planes',
  );
  if (args['verbose'] as bool) {
    for (final finding in findings) {
      stdout.writeln('  acknowledged or live: $finding');
    }
  }

  for (final finding in live) {
    stdout.writeln('  MISSING  ${finding.token}');
    stdout.writeln('           absent from: ${finding.absentFrom.join(", ")}');
  }
  for (final exception in stale) {
    stdout.writeln(
      '  STALE EXCEPTION  ${exception.token} — no plane is '
      'missing it any more; delete the entry',
    );
  }

  if (live.isEmpty && stale.isEmpty) {
    stdout.writeln(
      'check_som_parity: every contract capability reaches all '
      'nine planes, or is acknowledged',
    );
    return;
  }
  stdout.writeln(
    'check_som_parity: ${live.length} unacknowledged, '
    '${stale.length} stale exception(s)',
  );
  exit(1);
}
