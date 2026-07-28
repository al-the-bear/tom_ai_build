/// The script-facing **read-only** `model` reflection facade and its D4rt
/// bridge (`llm_and_d4rt_tools.md` §4, §5).
///
/// Where the `spec` global ([SpecApi]) is the controller-mediated *editing*
/// surface (read values + record-logged mutations), [SpecModelApi] is the
/// companion **reflection / typed-read** layer the `spec` scope injects as the
/// `model` global. It answers the meta-model questions a script asks *before*
/// editing — "what kind of node is this path? what class is it? which children
/// may I add here? what does `@MapsTo` / `@DetailedIn` say?" — without ever
/// touching a value, so it carries **no mutation path** by construction
/// (`llm_and_d4rt_tools.md` §4: the reflection layer is read-only).
///
/// It reads the same meta-model the `doc_reflect` MCP tool reads, through the one
/// shared reflection builder ([DocReflection.resolve]). Binding it to the live
/// document is binding it to the live controller's [SpecModel] — the read-only
/// schema the editor loads once — so a script's reflection and a tool's
/// reflection agree by construction. Reflection is pure object-model traversal:
/// no document state, no LLM calls.
///
/// `SpecModelApi` is never constructed from a script — the `spec` scope injects a
/// single model-bound instance as the `model` global — so the bridge declares no
/// constructors, only the read accessors. Every accessor returns a compact,
/// JSON-friendly value (`Map` / `List` / `String?` / `bool`) a script reads
/// directly.
library;

import 'package:tom_d4rt/tom_d4rt.dart';
import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart' show SpecModel;

import '../tools/doc_tools.dart';

/// The library URI a script imports to bring the injected `model` global (and
/// the `SpecModelApi` type) into scope.
const String specModelApiLibrary = 'package:tom_spec_engine/spec_model_api.dart';

/// The name of the injected reflection global (`model`).
const String specModelApiGlobalName = 'model';

/// The de-duplication name of the `spec_model_api` bridged-library block.
const String specModelApiLibraryName = 'spec_model_api';

/// The script-facing read-only reflection facade over a live [SpecModel]: every
/// accessor reflects a section-id path against the meta-model. No mutation
/// surface is exposed here.
final class SpecModelApi {
  /// The read-only meta-model every reflection routes through.
  final SpecModel model;

  /// Binds the facade to [model].
  const SpecModelApi(this.model);

  /// The full reflection of the node at [path] as a JSON-friendly map:
  /// `path`, `resolved`, and (when resolved) `kind`, `classId`, `sectionId`,
  /// `mapsTo`, `detailedIn`, `headline`, `annotations`, and `allowedChildren`.
  Map<String, Object?> reflect(String path) =>
      DocReflection.resolve(model, path).toJson();

  /// Whether [path] resolves to a model node.
  bool resolves(String path) => DocReflection.resolve(model, path).resolved;

  /// The node's render kind name (`root`/`complex`/`section`/`list`/`form`/
  /// `content`/`scalar`/…), or `null` when [path] does not resolve.
  String? kindOf(String path) => DocReflection.resolve(model, path).kind?.name;

  /// The model class the node *is* (`null` for value leaves / list containers /
  /// unresolved paths).
  String? classOf(String path) => DocReflection.resolve(model, path).classId;

  /// The node's `@SectionId` (field, class, or root), or `null`.
  String? sectionId(String path) => DocReflection.resolve(model, path).sectionId;

  /// The `@MapsTo` target on the node's class, or `null`.
  String? mapsTo(String path) => DocReflection.resolve(model, path).mapsTo;

  /// The `@DetailedIn` target on the node's class, or `null`.
  String? detailedIn(String path) =>
      DocReflection.resolve(model, path).detailedIn;

  /// The node's doc-comment / label headline, or `null`.
  String? headline(String path) => DocReflection.resolve(model, path).headline;

  /// The model-permitted children of the node at [path] — the segments a
  /// `spec.addChild` / `doc_add_node` accepts, each a JSON-friendly map
  /// (`segment`, `field`, `kind`, `type`/`elementType`, `sectionIdPattern`,
  /// `enumValues`, `annotations`). Empty for leaves / unresolved paths.
  List<Map<String, Object?>> allowedChildren(String path) => [
        for (final c in DocReflection.resolve(model, path).allowedChildren)
          c.toJson(),
      ];

  /// The class-level annotations on the node at [path], each a JSON-friendly
  /// map (`name`, `arguments`). Empty for leaves / unresolved paths.
  List<Map<String, Object?>> annotations(String path) => [
        for (final a in DocReflection.resolve(model, path).annotations)
          a.toJson(),
      ];
}

/// The [BridgedClass] that exposes [SpecModelApi]'s read-only reflection methods
/// to a D4rt script.
///
/// `SpecModelApi` is injected as the `model` global by the `spec` scope, so the
/// bridge declares no constructors — only the read accessors. No setter or
/// mutating method is exposed: reflection is strictly read-only.
BridgedClass specModelApiBridgedClass() => BridgedClass(
      nativeType: SpecModelApi,
      name: 'SpecModelApi',
      isAssignable: (v) => v is SpecModelApi,
      methods: {
        'reflect': (visitor, target, positionalArgs, namedArgs, _) =>
            (target as SpecModelApi).reflect(positionalArgs[0] as String),
        'resolves': (visitor, target, positionalArgs, namedArgs, _) =>
            (target as SpecModelApi).resolves(positionalArgs[0] as String),
        'kindOf': (visitor, target, positionalArgs, namedArgs, _) =>
            (target as SpecModelApi).kindOf(positionalArgs[0] as String),
        'classOf': (visitor, target, positionalArgs, namedArgs, _) =>
            (target as SpecModelApi).classOf(positionalArgs[0] as String),
        'sectionId': (visitor, target, positionalArgs, namedArgs, _) =>
            (target as SpecModelApi).sectionId(positionalArgs[0] as String),
        'mapsTo': (visitor, target, positionalArgs, namedArgs, _) =>
            (target as SpecModelApi).mapsTo(positionalArgs[0] as String),
        'detailedIn': (visitor, target, positionalArgs, namedArgs, _) =>
            (target as SpecModelApi).detailedIn(positionalArgs[0] as String),
        'headline': (visitor, target, positionalArgs, namedArgs, _) =>
            (target as SpecModelApi).headline(positionalArgs[0] as String),
        'allowedChildren': (visitor, target, positionalArgs, namedArgs, _) =>
            (target as SpecModelApi)
                .allowedChildren(positionalArgs[0] as String),
        'annotations': (visitor, target, positionalArgs, namedArgs, _) =>
            (target as SpecModelApi).annotations(positionalArgs[0] as String),
      },
    );
