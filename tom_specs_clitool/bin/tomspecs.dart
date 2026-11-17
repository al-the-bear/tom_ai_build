/// `tomspecs` — every tool of this package as a command of one binary, on
/// `tom_build_base` (stand-alone commands: `strictCommandOptions`).
///
/// ```text
/// dart run tom_specs_clitool:tomspecs --help
/// dart run tom_specs_clitool:tomspecs :gate-format :gate-section-citations
/// dart run tom_specs_clitool:tomspecs :codespecs-validate --ir <dir> --json
/// ```
///
/// The commands are named by subject (`decisions/tsimp1a_clitool_on_tom_build_base.md`
/// of the tom_specs quest, TSB-4 and the TSB-7 table). Several commands run
/// in one call, in order; the first that fails ends the run with its own exit
/// code (0 clean, 1 findings, 2 bad usage, 3 a refused spec check). Each
/// command's options are those of the tool it replaces — read from that
/// tool's `ArgParser`, so the help and the accepted options stay the tool's —
/// and the command runs that tool's run function in this process. The tools'
/// own `bin/` entrypoints remain until the commands are their only form.
library;

import 'dart:io';

import 'package:args/args.dart' hide OptionType;
import 'package:tom_build_base/tom_build_base_v2.dart';
import 'package:tom_specs_clitool/src/spec_checks_cli.dart';
import 'package:tom_specs_clitool/src/version.versioner.dart';
import 'package:tom_specs_clitool/tom_specs_clitool.dart'
    show
        extractAnswersParser,
        generateRegistryTestsParser,
        irspecsParser,
        runExtractAnswers,
        runGenerateRegistryTests,
        runIrspecs,
        runValidateCodespecs,
        runValidateSpec,
        validateCodespecsParser,
        validateSpecParser;

import 'build.dart' as build;
import 'check_api_signatures.dart' as check_api_signatures;
import 'check_dartdoc_build.dart' as check_dartdoc_build;
import 'check_doc_coverage.dart' as check_doc_coverage;
import 'check_format.dart' as check_format;
import 'check_oe_citations.dart' as check_oe_citations;
import 'check_release_closure.dart' as check_release_closure;
import 'check_release_drift.dart' as check_release_drift;
import 'check_section_citations.dart' as check_section_citations;
import 'check_shipped_paths.dart' as check_shipped_paths;
import 'check_som_parity.dart' as check_som_parity;
import 'check_spec_tree_duplication.dart' as check_spec_tree_duplication;
import 'check_todo_citations.dart' as check_todo_citations;
import 'codespecs_areas.dart' as codespecs_areas;
import 'docspecs_schema.dart' as docspecs_schema;
import 'docspecs_yaml_schema.dart' as docspecs_yaml_schema;
import 'generate_som.dart' as generate_som;
import 'model_json.dart' as model_json;
import 'outliner.dart' as outliner;
import 'spec_ops.dart' as spec_ops;
import 'stamp_serialization_order.dart' as stamp_serialization_order;
import 'summaries.dart' as summaries;

/// One `tomspecs` command: its name, what it does, the tool it replaces, its
/// options and how it runs.
class TomspecsCommand {
  /// The command name, without `:`.
  final String name;

  /// One line for the help.
  final String description;

  /// The tool (and subcommand) this command replaces, e.g. `irspecs map`.
  final String replaces;

  /// The command's options.
  final List<OptionDefinition> options;

  /// The arguments the replaced tool is run with, for the options and
  /// positionals given to the command.
  final List<String> Function(Map<String, dynamic> options, List<String> rest)
  arguments;

  /// Runs the replaced tool with [arguments]; returns its exit code.
  final Future<int> Function(List<String> arguments) run;

  const TomspecsCommand({
    required this.name,
    required this.description,
    required this.replaces,
    required this.options,
    required this.arguments,
    required this.run,
  });

  /// The command as tom_build_base declares it.
  CommandDefinition get definition => CommandDefinition(
    name: name,
    description: '$description (was `$replaces`)',
    options: options,
    supportsProjectTraversal: false,
    requiresTraversal: false,
    needsEnvironment: false,
  );
}

/// [parser]'s options as tom_build_base options: `help` left out (the run
/// gives every command its help), [only] (when given) keeping just those.
List<OptionDefinition> optionsOf(ArgParser parser, {Set<String>? only}) => [
  for (final o in parser.options.values)
    if (o.name != 'help' && (only == null || only.contains(o.name)))
      _optionOf(o),
];

OptionDefinition _optionOf(Option o) {
  final help = o.help ?? '';
  if (o.isFlag) {
    return OptionDefinition.flag(
      name: o.name,
      abbr: o.abbr,
      description: help,
      defaultValue: o.defaultsTo == true ? 'true' : null,
      negatable: o.negatable ?? true,
      hidden: o.hide,
    );
  }
  if (o.isMultiple) {
    return OptionDefinition.multi(
      name: o.name,
      abbr: o.abbr,
      description: help,
      allowedValues: o.allowed,
      mandatory: o.mandatory,
      valueName: o.valueHelp,
      hidden: o.hide,
      splitCommas: o.splitCommas,
    );
  }
  return OptionDefinition.option(
    name: o.name,
    abbr: o.abbr,
    description: help,
    defaultValue: o.defaultsTo?.toString(),
    allowedValues: o.allowed,
    mandatory: o.mandatory,
    valueName: o.valueHelp,
    hidden: o.hide,
  );
}

/// The command line for [parser]'s tool from a command's [options] and
/// positionals [rest]: each option the command was given, as `--name value`
/// (a flag as `--name` / `--no-name`), a value equal to the tool's own
/// default left out so the tool applies it itself; then [rest].
List<String> argumentsFor(
  ArgParser parser,
  Map<String, dynamic> options,
  List<String> rest, {
  List<String> before = const [],
}) {
  final out = <String>[...before];
  for (final o in parser.options.values) {
    final value = options[o.name];
    if (value == null || o.name == 'help') continue;
    if (o.isFlag) {
      final def = o.defaultsTo == true;
      if (value == def) continue;
      if (value == true) {
        out.add('--${o.name}');
      } else if (o.negatable ?? true) {
        out.add('--no-${o.name}');
      }
    } else if (o.isMultiple) {
      for (final v in value is List ? value : [value]) {
        out
          ..add('--${o.name}')
          ..add('$v');
      }
    } else {
      if (o.defaultsTo != null && '$value' == '${o.defaultsTo}') continue;
      out
        ..add('--${o.name}')
        ..add('$value');
    }
  }
  return [...out, ...rest];
}

TomspecsCommand _tool(
  String name,
  String description,
  String replaces,
  ArgParser Function() parser,
  Future<int> Function(List<String>) run, {
  List<String> before = const [],
  Set<String>? only,
}) => TomspecsCommand(
  name: name,
  description: description,
  replaces: replaces,
  options: optionsOf(parser(), only: only),
  arguments: (options, rest) =>
      argumentsFor(parser(), options, rest, before: before),
  run: run,
);

// The spec_checks checks read their own options from their arguments.

const _specRoot = OptionDefinition.option(
  name: 'spec-root',
  description:
      "The spec root whose checks/ folder holds the project's data; default "
      'found from the document.',
  valueName: 'dir',
);

TomspecsCommand _check(
  String name,
  String check,
  String description, {
  List<OptionDefinition> options = const [],
  bool specRoot = false,
}) => TomspecsCommand(
  name: name,
  description: description,
  replaces: 'spec_checks $check',
  options: [...options, if (specRoot) _specRoot],
  arguments: (given, rest) => [
    if (given['spec-root'] != null) ...['--spec-root', '${given['spec-root']}'],
    check,
    for (final o in options)
      if (o.type == OptionType.flag && given[o.name] == true)
        '--${o.name}'
      else if (o.type != OptionType.flag && given[o.name] != null) ...[
        '--${o.name}',
        '${given[o.name]}',
      ],
    ...rest,
  ],
  run: (arguments) async => runSpecChecks(arguments),
);

/// The commands, in the order of the TSB-7 table.
final List<TomspecsCommand> tomspecsCommands = [
  _tool(
    'spec-validate',
    'Validate a specification document on its three tiers',
    'validate_spec',
    validateSpecParser,
    runValidateSpec,
  ),
  _check(
    'spec-render',
    'validate',
    'Validate a document and write its Markdown rendition',
  ),
  _check(
    'spec-import-answers',
    'import-answers',
    "Import the answers typed into a rendition into the document's YAML",
    options: const [
      OptionDefinition.flag(
        name: 'dry-run',
        description: 'Show the change, write nothing.',
      ),
      OptionDefinition.flag(
        name: 'allow-other-edits',
        description:
            'Also take other narrative values changed in the rendition.',
      ),
    ],
  ),
  _check(
    'spec-accept-marks',
    'accept-marks',
    'Accept every inline change mark of a document in place',
    options: const [
      OptionDefinition.option(
        name: 'under',
        description: 'Only the marks under this path (<ID>/<ID>).',
        valueName: 'path',
      ),
      OptionDefinition.flag(name: 'write', description: 'Write the document.'),
    ],
  ),
  _check(
    'spec-required-fields',
    'required-fields',
    'Check required form fields and typed values',
  ),
  _check(
    'spec-question-register',
    'question-register',
    "Check a question index against the document's question blocks",
    options: const [
      OptionDefinition.flag(
        name: 'write',
        description: "Rewrite the index's counts.",
      ),
    ],
    specRoot: true,
  ),
  _check(
    'spec-feature-register',
    'feature-register',
    'Check that every functional requirement is linked by one feature',
  ),
  _check(
    'spec-idea-coverage',
    'project-idea-coverage',
    "Check the requirements' coverage of the Project Idea",
    options: const [
      OptionDefinition.option(
        name: 'exclusions',
        description:
            'An exclusions YAML instead of checks/project_idea_coverage.yaml.',
        valueName: 'yaml',
      ),
      OptionDefinition.flag(
        name: 'all',
        description: 'List the covered ids too.',
      ),
    ],
    specRoot: true,
  ),
  _check(
    'spec-authorization',
    'authorization',
    'Check that operations, role matrix, screens and use cases agree',
    specRoot: true,
  ),
  _check(
    'spec-coverage',
    'coverage',
    'Report how much of the model a document fills',
    options: const [
      OptionDefinition.option(
        name: 'tsv',
        description: 'Write the empty sections as TSV to this file.',
        valueName: 'out.tsv',
      ),
    ],
    specRoot: true,
  ),
  _tool(
    'spec-answers',
    "Extract a review round's answers, comments and marks (answers.md)",
    'extract_answers',
    extractAnswersParser,
    runExtractAnswers,
  ),
  _tool(
    'codespecs-validate',
    'Run the derivation-contract checks over a CodeSpecs trio or its IR',
    'validate_codespecs',
    validateCodespecsParser,
    runValidateCodespecs,
  ),
  _tool(
    'codespecs-areas',
    'Regenerate the CodeSpecs area catalogue',
    'codespecs_areas',
    codespecs_areas.codespecsAreasParser,
    codespecs_areas.runCodespecsAreas,
  ),
  _tool(
    'ir-from-codespecs',
    'Write the IR of a CodeSpecs trio',
    'irspecs from-codespecs',
    irspecsParser,
    runIrspecs,
    before: const ['from-codespecs'],
    only: const {'shared', 'client', 'server', 'areas', 'out'},
  ),
  _tool(
    'ir-map',
    'Write code from the IR through a mapper',
    'irspecs map',
    irspecsParser,
    runIrspecs,
    before: const ['map'],
    only: const {'ir', 'out', 'mapper', 'spec', 'unit'},
  ),
  _tool(
    'ir-emit',
    'Write what a standard can express of the IR',
    'irspecs emit',
    irspecsParser,
    runIrspecs,
    before: const ['emit'],
    only: const {'standard', 'ir', 'out', 'areas', 'spec', 'unit'},
  ),
  _tool(
    'ir-export',
    'Write the IR as JSON',
    'irspecs export',
    irspecsParser,
    runIrspecs,
    before: const ['export'],
    only: const {'format', 'ir', 'out'},
  ),
  _tool(
    'som-generate',
    'Generate the nine SOM language packages from the model',
    'generate_som',
    generate_som.generateSomParser,
    generate_som.runGenerateSom,
  ),
  _tool(
    'som-parity',
    'Report capabilities some language plane does not carry',
    'check_som_parity',
    check_som_parity.checkSomParityParser,
    check_som_parity.runCheckSomParity,
  ),
  _tool(
    'model-outline',
    'Write the class-tree outline of a model root',
    'outliner',
    outliner.outlinerParser,
    outliner.runOutliner,
  ),
  _tool(
    'model-json',
    'Export the model class graph as JSON',
    'model_json',
    model_json.modelJsonParser,
    model_json.runModelJson,
  ),
  _tool(
    'model-spec-ops',
    'Generate the spec_ops.g.dart registry',
    'spec_ops',
    spec_ops.specOpsParser,
    spec_ops.runSpecOps,
  ),
  _tool(
    'model-stamp-order',
    'Stamp @SerializationOrder on every model member',
    'stamp_serialization_order',
    stamp_serialization_order.stampSerializationOrderParser,
    stamp_serialization_order.runStampSerializationOrder,
  ),
  _tool(
    'schema-docspecs',
    'Generate the DocSpecs schemas of the model roots',
    'docspecs_schema',
    docspecs_schema.docspecsSchemaParser,
    docspecs_schema.runDocspecsSchema,
  ),
  _tool(
    'schema-docspecs-yaml',
    'Generate the JSON Schema of the on-disk DocSpecs YAML',
    'docspecs_yaml_schema',
    docspecs_yaml_schema.docspecsYamlSchemaParser,
    docspecs_yaml_schema.runDocspecsYamlSchema,
  ),
  _tool(
    'app-registry-tests',
    "Derive the registry part of an application's test suite",
    'generate_registry_tests',
    generateRegistryTestsParser,
    runGenerateRegistryTests,
  ),
  _tool(
    'editor-summaries',
    'Generate the analyzer summaries for one consumer',
    'summaries',
    summaries.summariesParser,
    summaries.runSummaries,
  ),
  _tool(
    'editor-build',
    'Build and package the TomSpecs editor',
    'build',
    build.buildParser,
    build.runBuild,
  ),
  _tool(
    'gate-format',
    'Report every governed Dart file dart format would rewrite',
    'check_format',
    check_format.checkFormatParser,
    check_format.runCheckFormat,
  ),
  _tool(
    'gate-api-signatures',
    'Report API-summary signatures that disagree with the code',
    'check_api_signatures',
    check_api_signatures.checkApiSignaturesParser,
    check_api_signatures.runCheckApiSignatures,
  ),
  _tool(
    'gate-dartdoc',
    "Build the governed packages' API docs and report their warnings",
    'check_dartdoc_build',
    check_dartdoc_build.checkDartdocBuildParser,
    check_dartdoc_build.runCheckDartdocBuild,
  ),
  _tool(
    'gate-doc-coverage',
    'Check public-API dartdoc coverage against the manifest',
    'check_doc_coverage',
    check_doc_coverage.checkDocCoverageParser,
    check_doc_coverage.runCheckDocCoverage,
  ),
  _tool(
    'gate-oe-citations',
    'Check that every cited OE- id is defined',
    'check_oe_citations',
    check_oe_citations.checkOeCitationsParser,
    check_oe_citations.runCheckOeCitations,
  ),
  _tool(
    'gate-section-citations',
    'Resolve every § citation of the TomSpecs documents',
    'check_section_citations',
    check_section_citations.checkSectionCitationsParser,
    check_section_citations.runCheckSectionCitations,
  ),
  _tool(
    'gate-todo-citations',
    'Check that every cited quest-todo id still resolves',
    'check_todo_citations',
    check_todo_citations.checkTodoCitationsParser,
    check_todo_citations.runCheckTodoCitations,
  ),
  _tool(
    'gate-release-closure',
    'Check that the release set is dependency-closed',
    'check_release_closure',
    check_release_closure.checkReleaseClosureParser,
    check_release_closure.runCheckReleaseClosure,
  ),
  _tool(
    'gate-release-drift',
    'Report release packages changed since their version was set',
    'check_release_drift',
    check_release_drift.checkReleaseDriftParser,
    check_release_drift.runCheckReleaseDrift,
  ),
  _tool(
    'gate-shipped-paths',
    'Report shipped-script path literals that resolve nowhere',
    'check_shipped_paths',
    check_shipped_paths.checkShippedPathsParser,
    check_shipped_paths.runCheckShippedPaths,
  ),
  _tool(
    'gate-spec-tree-duplication',
    'Report doc lines newly stated in both spec-tree surfaces',
    'check_spec_tree_duplication',
    check_spec_tree_duplication.checkSpecTreeDuplicationParser,
    check_spec_tree_duplication.runCheckSpecTreeDuplication,
  ),
];

/// The `tomspecs` tool definition.
final ToolDefinition tomspecsTool = ToolDefinition(
  name: 'tomspecs',
  description:
      'The TomSpecs tools as commands of one binary: specifications, '
      'CodeSpecs and IR Specs, the SOM, the model, schemas, the editor build '
      'and the gates. Several commands run in one call; the first that fails '
      'ends the run with its exit code.',
  version: TomSpecsClitoolVersionInfo.version,
  versionString: 'tomspecs ${TomSpecsClitoolVersionInfo.versionMedium}',
  mode: ToolMode.multiCommand,
  features: NavigationFeatures.minimal,
  strictCommandOptions: true,
  usageErrorExitCode: 2,
  builtInHelpTopics: false,
  commands: [for (final c in tomspecsCommands) c.definition],
);

class _CommandExecutor extends CommandExecutor {
  final TomspecsCommand command;
  _CommandExecutor(this.command);

  @override
  Future<ItemResult> execute(CommandContext context, CliArgs args) async =>
      throw StateError('`:${command.name}` runs without a traversal');

  @override
  Future<ToolResult> executeWithoutTraversal(CliArgs args) async {
    // The command as written may be an unambiguous prefix of its name.
    final given = args.commandArgs.entries
        .where((e) => tomspecsTool.findCommand(e.key)?.name == command.name)
        .map((e) => e.value)
        .firstOrNull;
    final code = await command.run(
      command.arguments(
        given?.options ?? const {},
        given?.positionalArgs ?? const [],
      ),
    );
    if (code == 0) return const ToolResult.success();
    return ToolResult.fromItems([
      ItemResult.failure(
        path: '.',
        name: command.name,
        error: '`:${command.name}` exited $code',
        exitCode: code,
      ),
    ]);
  }
}

/// Runs `tomspecs` with [arguments]; returns the exit code. Help and version
/// go to [out], usage errors to [err] (stdout and stderr by default); each
/// command writes its own output where its tool always did.
Future<int> runTomspecs(
  List<String> arguments, {
  StringSink? out,
  StringSink? err,
  Map<String, Future<int> Function(List<String>)>? runOverrides,
}) async {
  final runner = ToolRunner(
    tool: tomspecsTool,
    executors: {
      for (final c in tomspecsCommands)
        c.name: _CommandExecutor(
          runOverrides?[c.name] == null
              ? c
              : TomspecsCommand(
                  name: c.name,
                  description: c.description,
                  replaces: c.replaces,
                  options: c.options,
                  arguments: c.arguments,
                  run: runOverrides![c.name]!,
                ),
        ),
    },
    output: out ?? ConsoleMarkdownSink(stdout),
    errorOutput: err ?? stderr,
  );
  final result = await runner.run(arguments);
  return result.exitCode;
}

Future<void> main(List<String> arguments) async {
  final code = await runTomspecs(arguments);
  await stdout.flush();
  await stderr.flush();
  exit(code);
}
