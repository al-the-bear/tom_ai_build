import 'dart:io';

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:path/path.dart' as p;

/// Annotation data extracted from the analyzer element model.
class AnnotationData {
  final String name;
  final Map<String, Object?> arguments;

  AnnotationData(this.name, [this.arguments = const {}]);

  @override
  String toString() => '@$name${arguments.isEmpty ? '' : '($arguments)'}';
}

/// A resolved field from a model class.
class ModelField {
  final String name;
  final String typeName;
  final bool isList;
  final bool isNullable;
  final bool isEnum;
  final List<String> enumValues;
  final List<AnnotationData> annotations;

  /// For list fields, the inner type name.
  final String? listElementTypeName;

  /// Whether the inner type of a list is a complex (class) type.
  final bool listElementIsComplex;

  ModelField({
    required this.name,
    required this.typeName,
    this.isList = false,
    this.isNullable = false,
    this.isEnum = false,
    this.enumValues = const [],
    this.annotations = const [],
    this.listElementTypeName,
    this.listElementIsComplex = false,
  });

  bool get isComplex =>
      !isLeaf && !isList;

  bool get isLeaf =>
      !isList &&
      !_isComplexType(typeName) &&
      (typeName == 'String' ||
       typeName == 'String?' ||
       isEnum);

  /// Whether this is a String or String? field (not enum).
  bool get isString =>
      (typeName == 'String' || typeName == 'String?') && !isEnum;

  AnnotationData? getAnnotation(String name) {
    for (final a in annotations) {
      if (a.name == name) return a;
    }
    return null;
  }

  static bool _isComplexType(String name) {
    final base = name.endsWith('?') ? name.substring(0, name.length - 1) : name;
    return base != 'String' &&
        base != 'int' &&
        base != 'double' &&
        base != 'bool' &&
        base != 'num' &&
        base != 'DateTime';
  }
}

/// A resolved model class.
class ModelClass {
  final String name;
  final List<ModelField> fields;
  final List<AnnotationData> annotations;

  ModelClass({
    required this.name,
    this.fields = const [],
    this.annotations = const [],
  });

  AnnotationData? getAnnotation(String name) {
    for (final a in annotations) {
      if (a.name == name) return a;
    }
    return null;
  }
}

/// A resolved enum type.
class ModelEnum {
  final String name;
  final List<String> values;

  ModelEnum({required this.name, required this.values});
}

/// Reads model classes from Dart source files using the analyzer.
class ModelReader {
  final AnalysisDriver _driver;
  final Map<String, ModelClass> classes = {};
  final Map<String, ModelEnum> enums = {};

  ModelReader(this._driver);

  /// Analyzes all .dart files under [packageLibPath] and collects
  /// model classes and enums.
  Future<void> analyzePackage(String packageLibPath) async {
    final srcDir = Directory(p.join(packageLibPath, 'src'));
    if (!srcDir.existsSync()) {
      throw StateError('Source directory not found: ${srcDir.path}');
    }

    final dartFiles = srcDir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .toList();

    for (final file in dartFiles) {
      _driver.addFile(file.path);
    }

    for (final file in dartFiles) {
      final result = await _driver.getResolvedUnit(file.path);
      if (result is ResolvedUnitResult) {
        _processResolvedUnit(result);
      }
    }
  }

  void _processResolvedUnit(ResolvedUnitResult result) {
    final unit = result.unit;
    for (final declaration in unit.declarations) {
      if (declaration is ClassDeclaration) {
        _processClass(declaration);
      } else if (declaration is EnumDeclaration) {
        _processEnum(declaration);
      }
    }
  }

  void _processClass(ClassDeclaration node) {
    final fragment = node.declaredFragment;
    if (fragment == null) return;
    final element = fragment.element;

    final className = element.name ?? '';
    if (className.isEmpty) return;

    final classAnnotations = _readAnnotations(element.metadata);
    final fields = <ModelField>[];

    for (final field in element.fields) {
      if (field.isStatic) continue;
      if (field.isEnumConstant) continue;

      final fieldName = field.name ?? '';
      if (fieldName.isEmpty) continue;

      final fieldType = field.type;
      final fieldAnnotations = _readAnnotations(field.metadata);

      fields.add(_buildModelField(fieldName, fieldType, fieldAnnotations));
    }

    classes[className] = ModelClass(
      name: className,
      fields: fields,
      annotations: classAnnotations,
    );
  }

  void _processEnum(EnumDeclaration node) {
    final fragment = node.declaredFragment;
    if (fragment == null) return;
    final element = fragment.element;

    final enumName = element.name ?? '';
    if (enumName.isEmpty) return;

    final values = <String>[];
    for (final constant in element.constants) {
      final name = constant.name;
      if (name != null) values.add(name);
    }

    enums[enumName] = ModelEnum(name: enumName, values: values);
  }

  ModelField _buildModelField(
    String name,
    DartType type,
    List<AnnotationData> annotations,
  ) {
    final isNullable = type.nullabilitySuffix == NullabilitySuffix.question;

    // Check for List<T>
    if (type is InterfaceType && type.element.name == 'List') {
      final typeArgs = type.typeArguments;
      if (typeArgs.isNotEmpty) {
        final innerType = typeArgs.first;
        final innerTypeName = _typeDisplayName(innerType);
        final innerIsEnum = _isEnumType(innerType);
        final innerIsComplex = !innerIsEnum &&
            innerTypeName != 'String' &&
            innerType is InterfaceType &&
            innerType.element is ClassElement;

        return ModelField(
          name: name,
          typeName: 'List<$innerTypeName>',
          isList: true,
          isNullable: isNullable,
          listElementTypeName: innerTypeName,
          listElementIsComplex: innerIsComplex,
          annotations: annotations,
        );
      }
    }

    // Check for enum
    if (_isEnumType(type)) {
      final enumValues = _getEnumValues(type);
      return ModelField(
        name: name,
        typeName: _typeDisplayName(type),
        isNullable: isNullable,
        isEnum: true,
        enumValues: enumValues,
        annotations: annotations,
      );
    }

    // Scalar or complex
    return ModelField(
      name: name,
      typeName: _typeDisplayName(type),
      isNullable: isNullable,
      annotations: annotations,
    );
  }

  String _typeDisplayName(DartType type) {
    if (type is InterfaceType) {
      final name = type.element.name ?? 'Unknown';
      return type.nullabilitySuffix == NullabilitySuffix.question
          ? '$name?'
          : name;
    }
    return type.getDisplayString();
  }

  bool _isEnumType(DartType type) {
    if (type is InterfaceType) {
      return type.element is EnumElement;
    }
    return false;
  }

  List<String> _getEnumValues(DartType type) {
    if (type is InterfaceType) {
      final element = type.element;
      if (element is EnumElement) {
        return element.constants
            .map((c) => c.name)
            .whereType<String>()
            .toList();
      }
    }
    return [];
  }

  List<AnnotationData> _readAnnotations(Metadata metadata) {
    final result = <AnnotationData>[];
    for (final annotation in metadata.annotations) {
      final element = annotation.element;
      if (element == null) continue;

      String? name;
      if (element is ConstructorElement) {
        name = element.enclosingElement.name;
      }

      if (name == null) continue;

      final arguments = <String, Object?>{};
      final value = annotation.computeConstantValue();
      if (value != null) {
        // Use the DartObject's type element to iterate fields
        final typeElement = value.type?.element;
        if (typeElement is InterfaceElement) {
          for (final field in typeElement.fields) {
            final fieldName = field.name;
            if (fieldName == null || field.isStatic || field.isEnumConstant) {
              continue;
            }
            final fieldValue = value.getField(fieldName);
            if (fieldValue != null && !fieldValue.isNull) {
              final dartValue = _extractDartValue(fieldValue);
              if (dartValue != null) {
                arguments[fieldName] = dartValue;
              }
            }
          }
        }
      }

      result.add(AnnotationData(name, arguments));
    }
    return result;
  }

  Object? _extractDartValue(dynamic obj) {
    // DartObject
    if (obj.hasKnownValue != true) return null;

    final stringVal = obj.toStringValue();
    if (stringVal != null) return stringVal;

    final intVal = obj.toIntValue();
    if (intVal != null) return intVal;

    final boolVal = obj.toBoolValue();
    if (boolVal != null) return boolVal;

    final doubleVal = obj.toDoubleValue();
    if (doubleVal != null) return doubleVal;

    // Try list
    final listVal = obj.toListValue();
    if (listVal != null) {
      return listVal
          .map((e) => _extractDartValue(e))
          .where((e) => e != null)
          .toList();
    }

    return null;
  }
}
