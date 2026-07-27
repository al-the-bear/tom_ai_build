/// The script-facing `spec` document API and its D4rt bridge (§5).
///
/// [SpecApi] is the single object a sandboxed script reaches under the `spec`
/// scope: a thin facade that delegates every read and mutation to a
/// [SpecController]. Because all document access in the scope goes through this
/// one controller-bound object — never the raw `SpecDocument` bridge — a script
/// edit is mediated exactly like a tool edit and lands in the same change log
/// and undo stack (§5 "one change log").
///
/// [specApiBridgedClass] exposes [SpecApi]'s methods to the interpreter; the
/// `spec` scope (`spec_scope.dart`) registers it and injects a single instance
/// as the [specApiGlobalName] global under [specApiLibrary].
library;

import 'package:tom_d4rt/tom_d4rt.dart';

import 'spec_controller.dart';

/// The library URI a script imports to bring the injected `spec` global (and the
/// `SpecApi` type) into scope.
const String specApiLibrary = 'package:tom_spec_engine/spec_api.dart';

/// The name of the injected document-API global (`spec`).
const String specApiGlobalName = 'spec';

/// The de-duplication name of the `spec_api` bridged-library building block.
const String specApiLibraryName = 'spec_api';

/// The script-facing document API: every call delegates to the bound
/// [SpecController], so a script mutation is mediated identically to a tool
/// mutation (same change log + undo).
final class SpecApi {
  /// The live controller every read/mutation routes through.
  final SpecController controller;

  /// Binds the facade to [controller].
  const SpecApi(this.controller);

  /// The content value at [path], or `null`.
  String? content(String path) => controller.content(path);

  /// The form [field] value at [path], or `null`.
  String? formField(String path, String field) =>
      controller.formField(path, field);

  /// The ordered item paths of the list at [listPath].
  List<String> listItems(String listPath) => controller.listItems(listPath);

  /// Sets the content at [path] (empty clears).
  void setContent(String path, String value) =>
      controller.setContent(path, value);

  /// Sets the form [field] at [path] (empty clears).
  void setFormField(String path, String field, String value) =>
      controller.setFormField(path, field, value);

  /// Appends an item to the list at [listPath]; returns its new path.
  String addListItem(String listPath) => controller.addListItem(listPath);

  /// Removes the list item at [itemPath]; returns whether one was removed.
  bool removeListItem(String itemPath) => controller.removeListItem(itemPath);

  /// Adds the model-permitted child [childSegment] under [parentPath];
  /// returns the new node's path (throws on an illegal add).
  String addChild(String parentPath, String childSegment, {String? itemId}) =>
      controller.addChild(parentPath, childSegment, itemId: itemId);
}

/// The [BridgedClass] that exposes [SpecApi]'s methods to a D4rt script.
///
/// `SpecApi` is never constructed from a script — the `spec` scope injects a
/// single controller-bound instance as a global — so the bridge declares no
/// constructors, only the instance methods.
BridgedClass specApiBridgedClass() => BridgedClass(
      nativeType: SpecApi,
      name: 'SpecApi',
      isAssignable: (v) => v is SpecApi,
      methods: {
        'content': (visitor, target, positionalArgs, namedArgs, _) =>
            (target as SpecApi).content(positionalArgs[0] as String),
        'formField': (visitor, target, positionalArgs, namedArgs, _) =>
            (target as SpecApi).formField(
                positionalArgs[0] as String, positionalArgs[1] as String),
        'listItems': (visitor, target, positionalArgs, namedArgs, _) =>
            (target as SpecApi).listItems(positionalArgs[0] as String),
        'setContent': (visitor, target, positionalArgs, namedArgs, _) {
          (target as SpecApi).setContent(
              positionalArgs[0] as String, positionalArgs[1] as String);
          return null;
        },
        'setFormField': (visitor, target, positionalArgs, namedArgs, _) {
          (target as SpecApi).setFormField(positionalArgs[0] as String,
              positionalArgs[1] as String, positionalArgs[2] as String);
          return null;
        },
        'addListItem': (visitor, target, positionalArgs, namedArgs, _) =>
            (target as SpecApi).addListItem(positionalArgs[0] as String),
        'removeListItem': (visitor, target, positionalArgs, namedArgs, _) =>
            (target as SpecApi).removeListItem(positionalArgs[0] as String),
        'addChild': (visitor, target, positionalArgs, namedArgs, _) =>
            (target as SpecApi).addChild(
                positionalArgs[0] as String, positionalArgs[1] as String,
                itemId: namedArgs['itemId'] as String?),
      },
    );
