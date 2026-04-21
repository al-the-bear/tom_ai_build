import 'model_reader.dart';

/// Generates the outline text from the model class tree.
class OutlineWriter {
  final Map<String, ModelClass> classes;
  final Map<String, ModelEnum> enums;
  final int maxLineLength;
  final bool showSchemaAnnotations;
  final StringBuffer _buffer = StringBuffer();

  /// Schema-only annotation names (§4.13 — visible=No).
  static const _schemaOnlyAnnotations = {
    'Prefix',
    'PatternCheckId',
    'PatternCheck',
    'MaxDepth',
    'AllowedTags',
    'ValidationPrompt',
    'AccessKey',
    'MinLength',
    'MaxLength',
  };

  /// When true, tree traversal stops at classes annotated with `@DetailedIn`.
  /// The section heading is still emitted with a `→ <DocId>` suffix so the
  /// reader knows where to find the full expansion.
  final bool stopAtDetailedIn;

  OutlineWriter({
    required this.classes,
    this.enums = const {},
    this.maxLineLength = 120,
    this.showSchemaAnnotations = false,
    this.stopAtDetailedIn = false,
  });

  String generate(String rootTypeName) {
    _buffer.clear();
    _buffer.writeln('# ${_splitPascalCase(rootTypeName)} Outline');
    _buffer.writeln();

    final rootClass = classes[rootTypeName];
    if (rootClass == null) {
      throw StateError('Root type "$rootTypeName" not found in model classes');
    }

    _writeClass(rootTypeName, rootClass, 0, {});
    return _buffer.toString();
  }

  void _writeClass(
    String typeName,
    ModelClass cls,
    int depth,
    Set<String> ancestors,
  ) {
    // Class-level schema annotations (§4.14)
    if (showSchemaAnnotations) {
      final indent = _indent(depth);
      _writeSchemaAnnotations(cls.annotations, indent, null);
    }

    // Separate leaf fields from complex/list fields
    final leafFields = <ModelField>[];
    final complexFields = <ModelField>[];

    for (final field in cls.fields) {
      if (field.isList) {
        complexFields.add(field);
      } else if (field.isSectionType) {
        leafFields.add(field);
      } else if (field.isLeaf || field.isEnum) {
        leafFields.add(field);
      } else if (field.isComplex) {
        complexFields.add(field);
      } else {
        // String, String? without being recognized as complex
        leafFields.add(field);
      }
    }

    // Write leaf fields as a single comma-separated -> line
    if (leafFields.isNotEmpty) {
      _writeLeafLine(leafFields, depth, cls);
    }

    // Write complex/list children
    for (final field in complexFields) {
      _writeComplexField(field, depth, ancestors);
    }
  }

  void _writeLeafLine(
    List<ModelField> fields,
    int depth,
    ModelClass cls,
  ) {
    final indent = _indent(depth + 1);

    // Field-level schema annotations (§4.14)
    if (showSchemaAnnotations) {
      for (final field in fields) {
        _writeSchemaAnnotations(field.annotations, indent, field.name);
      }
    }

    final parts = <String>[];
    for (final field in fields) {
      parts.add(_formatLeafField(field, cls));
    }

    final prefix = '$indent- ';
    final joined = parts.join(', ');
    final fullLine = '$prefix$joined';

    if (fullLine.length <= maxLineLength || parts.length <= 1) {
      // Single field: never wrap (even if long); short lines: no wrap needed
      _buffer.writeln(fullLine);
    } else {
      _writeWrappedLeafLine(prefix, parts, depth);
    }
  }

  String _formatLeafField(ModelField field, ModelClass cls) {
    final buf = StringBuffer();

    // Content field with @TextRequired → content!
    if (field.name == 'content') {
      final textRequired = cls.getAnnotation('TextRequired');
      buf.write('content');
      if (textRequired != null) buf.write('!');
    } else {
      buf.write(field.name);
    }

    // Section type field — show @contentType marker (§4.6 section types)
    if (field.isSectionType && field.sectionContentType != null) {
      buf.write(' @${field.sectionContentType}');
    }
    // Enum inline (§4.5)
    else if (field.isEnum && field.enumValues.isNotEmpty) {
      buf.write(': ${field.typeName} (${field.enumValues.join(', ')})');
    }

    // @Form or @ContentType hint on content field (§7.6)
    if (field.name == 'content') {
      if (field.formFields.isNotEmpty) {
        final names = field.formFields.map((f) => f.name).join(', ');
        buf.write(' @Form($names)');
      } else {
        final contentType = field.getAnnotation('ContentType');
        if (contentType != null) {
          final type = contentType.arguments['type'];
          if (type != null) buf.write(' @$type');
        }
      }
    }

    return buf.toString();
  }

  void _writeWrappedLeafLine(
    String prefix,
    List<String> parts,
    int depth,
  ) {
    final continuationIndent = _indent(depth + 2);
    final lines = <String>[];
    var currentLine = StringBuffer(prefix);

    for (var i = 0; i < parts.length; i++) {
      final part = parts[i];
      final separator = i < parts.length - 1 ? ', ' : '';
      final candidate = '$part$separator';

      if (currentLine.isEmpty) {
        currentLine.write(continuationIndent);
        currentLine.write(candidate);
      } else if (currentLine.length + candidate.length <= maxLineLength) {
        currentLine.write(candidate);
      } else if (currentLine.toString().trimRight() == prefix.trimRight()) {
        // First part doesn't fit with prefix — keep on same line anyway
        currentLine.write(candidate);
      } else {
        // Current line is full, start wrap
        lines.add(currentLine.toString().trimRight());
        currentLine = StringBuffer(continuationIndent);
        currentLine.write(candidate);
      }
    }

    if (currentLine.isNotEmpty) {
      lines.add(currentLine.toString().trimRight());
    }

    // Fix: first line should not have trailing comma if it wraps
    for (var i = 0; i < lines.length; i++) {
      if (i < lines.length - 1 && !lines[i].endsWith(',')) {
        lines[i] = '${lines[i]},';
      }
    }

    for (final line in lines) {
      _buffer.writeln(line);
    }
  }

  void _writeComplexField(
    ModelField field,
    int depth,
    Set<String> ancestors,
  ) {
    if (field.isList) {
      _writeListField(field, depth, ancestors);
    } else {
      // Singular complex field (§4.2)
      _writeSingularComplexField(field, depth, ancestors);
    }
  }

  void _writeSingularComplexField(
    ModelField field,
    int depth,
    Set<String> ancestors,
  ) {
    final indent = _indent(depth + 1);
    final typeName = field.typeName.replaceAll('?', '');
    final childClass = classes[typeName];

    // Field-level schema annotations (§4.14)
    if (showSchemaAnnotations) {
      _writeSchemaAnnotations(field.annotations, indent, field.name);
    }

    // Name-match rule (§4.2) — if field name matches type (lowercase first char)
    final isReference = field.getAnnotation('Reference') != null;
    final nameMatches = _fieldNameMatchesType(field.name, typeName);
    final showBothNames = !nameMatches || isReference;

    final line = StringBuffer('$indent- ');
    if (showBothNames) {
      line.write('${field.name}: `$typeName`');
    } else {
      line.write('`$typeName`');
    }

    // Reference path (§4.9)
    if (isReference) {
      final ref = field.getAnnotation('Reference')!;
      final desc = (ref.arguments['description'] ?? '') as String;
      if (desc.isNotEmpty) line.write(' (ref: $desc)');
    }

    // Trailing annotations
    _appendTrailingAnnotations(line, field, indent.length);

    // Compact mode: stop at @DetailedIn boundaries — append → DocId suffix
    var skipRecursion = false;
    if (stopAtDetailedIn && childClass != null && !isReference) {
      final docId = _detailedInDocId(childClass);
      if (docId != null) {
        line.write(' → $docId');
        skipRecursion = true;
      }
    }

    _buffer.writeln(line);

    // Recurse into child class — skip @Reference fields (§5.2)
    if (!skipRecursion && childClass != null && !isReference && !ancestors.contains(typeName)) {
      final newAncestors = {...ancestors, typeName};
      _writeClass(typeName, childClass, depth + 1, newAncestors);
    }
  }

  void _writeListField(
    ModelField field,
    int depth,
    Set<String> ancestors,
  ) {
    final indent = _indent(depth + 1);
    final innerType = field.listElementTypeName ?? 'Unknown';

    // Field-level schema annotations (§4.14)
    if (showSchemaAnnotations) {
      _writeSchemaAnnotations(field.annotations, indent, field.name);
    }

    // Min/Max prefix (§4.3)
    final minAnno = field.getAnnotation('Min');
    final maxAnno = field.getAnnotation('Max');
    final minVal = minAnno?.arguments['count'] as int?;
    final maxVal = maxAnno?.arguments['count'] as int?;

    // Build cardinality tag, e.g. [1,] or [,5] or [1,5]; omit when unconstrained
    final String cardinalityTag;
    if (minVal != null || maxVal != null) {
      final minStr = minVal?.toString() ?? '';
      final maxStr = maxVal?.toString() ?? '';
      cardinalityTag = ' [$minStr,$maxStr]';
    } else {
      cardinalityTag = '';
    }

    final line = StringBuffer('$indent-$cardinalityTag ${field.name}: `$innerType`');

    // Trailing annotations
    _appendTrailingAnnotations(line, field, indent.length);

    // Compact mode: stop at @DetailedIn boundaries — append → DocId suffix
    var skipRecursion = false;
    if (stopAtDetailedIn && field.listElementIsComplex) {
      final childClass = classes[innerType];
      if (childClass != null) {
        final docId = _detailedInDocId(childClass);
        if (docId != null) {
          line.write(' → $docId');
          skipRecursion = true;
        }
      }
    }

    _buffer.writeln(line);

    // Recurse into inner type if complex
    if (!skipRecursion && field.listElementIsComplex) {
      final childClass = classes[innerType];
      if (childClass != null) {
        final newAncestors = {...ancestors, innerType};
        _writeClass(innerType, childClass, depth + 1, newAncestors);
      }
    }
  }

  /// Returns the `@SectionId` of the document class named in the first
  /// `@DetailedIn` annotation on [cls], or `null` if the class has no
  /// `@DetailedIn`.  Falls back to the raw class name if the target document
  /// class has no `@SectionId`.
  String? _detailedInDocId(ModelClass cls) {
    final anno = cls.getAnnotation('DetailedIn');
    if (anno == null) return null;
    final docClassName = anno.arguments['documentClass'] as String? ?? '';
    if (docClassName.isEmpty) return null;
    final docClass = classes[docClassName];
    final sectionId = docClass?.getAnnotation('SectionId')?.arguments['id'] as String?;
    return sectionId ?? docClassName;
  }

  void _appendTrailingAnnotations(
    StringBuffer line,
    ModelField field,
    int indentLength,
  ) {
    // @Comment (§4.10)
    final comment = field.getAnnotation('Comment');
    if (comment != null) {
      final text = comment.arguments['text'] ?? '';
      line.write(' ← ($text)');
    }

    // @Position (§4.11) — non-default only
    final position = field.getAnnotation('Position');
    if (position != null) {
      final pos = position.arguments['position'] as String? ?? '';
      if (pos.isNotEmpty && pos != 'relative') {
        line.write(' [$pos]');
      }
    }

    // @ForEach (§4.12)
    final forEach = field.getAnnotation('ForEach');
    if (forEach != null) {
      final registry = forEach.arguments['registryType'] ?? '';
      final key = forEach.arguments['key'] ?? '';
      line.write(' ⟷ $registry.$key');
    }
  }

  void _writeSchemaAnnotations(
    List<AnnotationData> annotations,
    String indent,
    String? fieldName,
  ) {
    for (final anno in annotations) {
      if (!_schemaOnlyAnnotations.contains(anno.name)) continue;

      final buf = StringBuffer('$indent<!-- @${anno.name}');
      if (anno.arguments.isNotEmpty) {
        final args = anno.arguments.entries
            .map((e) => _formatArgValue(e.value))
            .join(', ');
        buf.write('($args)');
      } else {
        buf.write('()');
      }
      if (fieldName != null) {
        buf.write(' $fieldName');
      }
      buf.write(' -->');
      _buffer.writeln(buf);
    }
  }

  String _formatArgValue(Object? value) {
    if (value is String) return "'$value'";
    if (value is List) return '[${value.map(_formatArgValue).join(', ')}]';
    return value.toString();
  }

  String _indent(int depth) => '  ' * depth;

  bool _fieldNameMatchesType(String fieldName, String typeName) {
    if (typeName.isEmpty) return false;
    final expected = typeName[0].toLowerCase() + typeName.substring(1);
    return fieldName == expected;
  }

  String _splitPascalCase(String name) {
    return name.replaceAllMapped(
      RegExp(r'(?<=[a-z])(?=[A-Z])'),
      (m) => ' ',
    );
  }
}
