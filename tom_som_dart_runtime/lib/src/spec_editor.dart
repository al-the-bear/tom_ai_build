/// The generic, meta-model-driven modification API (YRD7).
///
/// [SpecEditor] lets a consumer walk any document's meta tree and
/// create/modify/delete sections, list items, headlines, ids, content and
/// **typed** form fields *without a generated facade*: every operation
/// resolves its path against the [SpecModel] first ([SpecReflection.resolve])
/// and converts values at the store boundary through the same
/// `spec_typed_values.dart` helpers the generated accessors call — so a typed
/// facade is provably a thin layer over exactly this API.
///
/// Typed contract (mirrored by all nine runtimes):
///   * `int` / `double` / `num` / `bool` values are native on both sides;
///   * enum values travel as validated **constant-name strings** at this
///     generic layer (`'high'`), because the generic API has no generated enum
///     types — only the facade layer converts to native constants;
///   * `null` (or `''`) clears a value (D4);
///   * reads are forgiving (unparsable stored text reads as `null`), writes
///     are strict ([ArgumentError] for a wrong type or an out-of-domain enum
///     name).
///
/// Role fields (YRD6) are honoured: reading/writing a `title`-role form field
/// routes to the owning section's stored headline, an `id`-role field to the
/// owning list item's stored section id — exactly the routing the generated
/// facades emit (owner = the form's own path when the form member carries its
/// own `@SectionId`, else the parent path).
library;

import 'spec_document.dart';
import 'spec_model.dart';
import 'spec_paths.dart';
import 'spec_reflection.dart';
import 'spec_section_id.dart';
import 'spec_typed_values.dart';

/// Generic, typed, meta-validated editing over a [SpecDocument].
class SpecEditor {
  /// The document being edited (the sparse value stores).
  final SpecDocument document;

  /// The value-free meta-model queries the editor validates against.
  final SpecReflection reflection;

  SpecEditor(this.document, this.reflection);

  /// Convenience: builds the editor for [document] over [model].
  SpecEditor.forModel(this.document, SpecModel model)
      : reflection = SpecReflection(model);

  // --- resolution ----------------------------------------------------------

  /// Resolves [path] against the meta-model, throwing [ArgumentError] for a
  /// dangling path — the strict companion to [SpecReflection.resolve].
  SpecResolution resolve(String path) {
    final r = reflection.resolve(path);
    if (r == null) {
      throw ArgumentError.value(
          path, 'path', 'does not resolve against the model');
    }
    return r;
  }

  // --- value leaves (content / scalar / enum / scalar list item) -----------

  /// The typed value at the value leaf [path], or `null` when unset.
  ///
  /// The static type follows the model: `int`/`double`/`num`/`bool` scalars
  /// return the parsed native value, enum leaves return the validated constant
  /// name, everything else the raw string. Throws [ArgumentError] when [path]
  /// is not a value leaf.
  Object? value(String path) {
    final r = _valueLeaf(path);
    final raw = document.content(path);
    if (raw == null || raw.isEmpty) return null;
    if (r.kind == SpecNodeKind.enumValue) {
      return somParseEnumName(raw, r.field?.enumValues ?? const []);
    }
    switch (_scalarBase(r.field?.type)) {
      case 'int':
        return somParseInt(raw);
      case 'double':
        return somParseDouble(raw);
      case 'num':
        return somParseNum(raw);
      case 'bool':
        return somParseBool(raw);
      default:
        return raw;
    }
  }

  /// Sets the value leaf at [path] to [v], converting at the store boundary.
  ///
  /// `null` clears. For typed scalars [v] must be the native type (or a
  /// string, taken verbatim); for enum leaves [v] must be one of the field's
  /// constant names. Throws [ArgumentError] for a non-leaf path, a wrong
  /// value type, or an out-of-domain enum name.
  void setValue(String path, Object? v) {
    final r = _valueLeaf(path);
    document.setContent(path, _format(v, r.kind, r.field, path));
  }

  SpecResolution _valueLeaf(String path) {
    final r = resolve(path);
    if (!r.isValueLeaf) {
      throw ArgumentError.value(
          path, 'path', 'is a ${r.kind.name} node, not a value leaf');
    }
    return r;
  }

  // --- headlines (YRD3) ----------------------------------------------------

  /// The stored headline at [path], or `null` when the section renders its
  /// effective default title.
  String? headline(String path) {
    resolve(path);
    return document.headline(path);
  }

  /// Sets the stored headline at [path]; empty/`null` returns the section to
  /// its default title.
  void setHeadline(String path, String? value) {
    resolve(path);
    document.setHeadline(path, value ?? '');
  }

  // --- typed form fields ---------------------------------------------------

  /// The typed value of form [field] at the `@Form` section [path], or `null`
  /// when unset.
  ///
  /// Role fields route per YRD6: `title` reads the owning section's headline,
  /// `id` the owning list item's stored section id. Ordinary fields read the
  /// form store and parse per the declared field type (enum fields return the
  /// validated constant name). Throws [ArgumentError] for a non-form path or
  /// an unknown field name.
  Object? formValue(String path, String field) {
    final (r, ff) = _formField(path, field);
    if (ff.role == 'title') return document.headline(_roleOwner(r, path));
    if (ff.role == 'id') return document.itemSectionId(_roleOwner(r, path));
    final raw = document.formField(path, field);
    if (raw == null || raw.isEmpty) return null;
    if (ff.enumValues.isNotEmpty) return somParseEnumName(raw, ff.enumValues);
    switch (_scalarBase(ff.type)) {
      case 'int':
        return somParseInt(raw);
      case 'double':
        return somParseDouble(raw);
      case 'num':
        return somParseNum(raw);
      case 'bool':
        return somParseBool(raw);
      default:
        return raw;
    }
  }

  /// Sets form [field] at the `@Form` section [path] to the typed value [v]
  /// (`null` clears), converting through the shared boundary helpers.
  ///
  /// Role fields route per YRD6 (see [formValue]); an empty write to an
  /// `id`-role field is ignored, matching the generated setters. Throws
  /// [ArgumentError] for a wrong value type or an out-of-domain enum name.
  void setFormValue(String path, String field, Object? v) {
    final (r, ff) = _formField(path, field);
    if (ff.role == 'title') {
      document.setHeadline(_roleOwner(r, path), _string(v, path, field));
      return;
    }
    if (ff.role == 'id') {
      final id = _string(v, path, field);
      if (id.isEmpty) return; // empty id writes are ignored (YRD6)
      document.setItemSectionId(_roleOwner(r, path), id);
      return;
    }
    final String stored;
    if (ff.enumValues.isNotEmpty) {
      stored = somFormatEnumName(_stringOrNull(v, path, field), ff.enumValues);
    } else {
      stored = _format(v, SpecNodeKind.scalar, null, path,
          typeName: ff.type, where: field);
    }
    document.setFormField(path, field, stored);
  }

  /// The form-field specs of the `@Form` section at [path], in declaration
  /// order — the meta a generic editor UI renders from.
  List<FormFieldSpec> formFields(String path) {
    final r = resolve(path);
    if (r.kind != SpecNodeKind.form) {
      throw ArgumentError.value(
          path, 'path', 'is a ${r.kind.name} node, not a @Form section');
    }
    return r.field?.formFields ?? const [];
  }

  (SpecResolution, FormFieldSpec) _formField(String path, String field) {
    final r = resolve(path);
    if (r.kind != SpecNodeKind.form) {
      throw ArgumentError.value(
          path, 'path', 'is a ${r.kind.name} node, not a @Form section');
    }
    for (final ff in r.field?.formFields ?? const <FormFieldSpec>[]) {
      if (ff.name == field) return (r, ff);
    }
    throw ArgumentError.value(
        field, 'field', 'not a form field of $path');
  }

  /// The owner path a role field binds to (YRD6): the form's own path when
  /// the form member heads its own `@SectionId` section, else the parent.
  String _roleOwner(SpecResolution r, String path) =>
      r.field?.sectionId != null ? path : specParentPath(path);

  // --- structural operations -----------------------------------------------

  /// Appends a new item to the list at [listPath] and returns its stable
  /// item path.
  ///
  /// When the list field carries a `@SectionIdPattern` and no explicit
  /// [sectionId] is given, a fresh id is generated from the pattern
  /// ([generateListItemSectionId], dated [now] — defaulting to today). An
  /// explicit [sectionId] is uniqueness-checked against the list's other
  /// items. Throws [ArgumentError] when [listPath] is not a list.
  String addListItem(String listPath, {String? sectionId, DateTime? now}) {
    final r = resolve(listPath);
    if (r.kind != SpecNodeKind.list) {
      throw ArgumentError.value(
          listPath, 'listPath', 'is a ${r.kind.name} node, not a list');
    }
    var id = sectionId;
    final pattern = r.field?.sectionIdPattern;
    if (id == null && pattern != null) {
      id = generateListItemSectionId(pattern, now ?? DateTime.now(),
          document.listItemSectionIds(listPath));
    }
    return document.addListItem(listPath, sectionId: id);
  }

  /// Removes the list item at [itemPath] with every value beneath it.
  /// Returns `true` when an item was found and removed.
  bool removeListItem(String itemPath) => document.removeListItem(itemPath);

  /// Clears every value at [path] and beneath it — content, form entries,
  /// nested list items, stored headlines and ids — returning the subtree to
  /// the untouched "empty = no value" state (D4). The node itself remains
  /// addressable (structure lives in the model, not the document).
  void clearSection(String path) {
    resolve(path);
    document.removeValuesUnder(path);
  }

  // --- conversion ----------------------------------------------------------

  static String? _scalarBase(String? typeName) {
    if (typeName == null) return null;
    return typeName.endsWith('?')
        ? typeName.substring(0, typeName.length - 1)
        : typeName;
  }

  /// Formats [v] for the store per the leaf's declared type; strings pass
  /// through verbatim (the plain-text serialization is authoritative).
  String _format(Object? v, SpecNodeKind kind, SpecField? field, String path,
      {String? typeName, String? where}) {
    if (v == null) return '';
    if (kind == SpecNodeKind.enumValue) {
      return somFormatEnumName(
          _stringOrNull(v, path, where ?? path), field?.enumValues ?? const []);
    }
    final base = _scalarBase(typeName ?? field?.type);
    switch (base) {
      case 'int':
        if (v is int) return somFormatInt(v);
        if (v is String) return v;
        break;
      case 'double':
        if (v is double) return somFormatDouble(v);
        if (v is int) return somFormatDouble(v.toDouble());
        if (v is String) return v;
        break;
      case 'num':
        if (v is num) return somFormatNum(v);
        if (v is String) return v;
        break;
      case 'bool':
        if (v is bool) return somFormatBool(v);
        if (v is String) return v;
        break;
      default:
        if (v is String) return v;
        break;
    }
    throw ArgumentError.value(
        v, where ?? path, 'wrong value type for a ${base ?? 'String'} field');
  }

  String _string(Object? v, String path, String field) =>
      _stringOrNull(v, path, field) ?? '';

  String? _stringOrNull(Object? v, String path, String field) {
    if (v == null) return null;
    if (v is String) return v;
    throw ArgumentError.value(
        v, field, 'expected a String for this field of $path');
  }
}
