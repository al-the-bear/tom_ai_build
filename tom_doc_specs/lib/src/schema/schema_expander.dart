/// Expands `[[...]]` generator and placeholder syntax in schema YAML.
///
/// Called by [SchemaLoader] after YAML parsing, before model construction.
/// Recursively walks all string values in the parsed YAML map and expands
/// `[[selector;separator]]` patterns using custom tags as data sources.
///
/// ## Syntax
///
/// - **Generator** (with separator): `[[key;sep]]` or `[[key:field;sep]]`
/// - **Placeholder** (without separator): `[[key.field]]`
///
/// See the specification for full syntax reference.
class SchemaExpander {
  /// The custom tags (top-level keys) that serve as data sources.
  final Map<String, dynamic> _data;

  /// Well-known keys that are not custom tags.
  static const _reservedKeys = {
    'section-types',
    'document',
    'form-types',
    'subsections',
  };

  /// Creates a new SchemaExpander with the given YAML data.
  ///
  /// The [yamlMap] is the full parsed schema YAML. Custom tags are all
  /// top-level keys that are not reserved schema keys.
  SchemaExpander(Map<String, dynamic> yamlMap)
      : _data = Map<String, dynamic>.fromEntries(
          yamlMap.entries.where((e) => !_reservedKeys.contains(e.key)),
        );

  /// Regex for matching `[[...]]` patterns.
  static final _expansionPattern = RegExp(r'(?<!\\)\[\[(.+?)\]\]');

  /// Expands all `[[...]]` patterns in the given YAML map, in place.
  ///
  /// Returns the same map with all string values expanded.
  Map<String, dynamic> expand(Map<String, dynamic> yamlMap) {
    return _expandMap(yamlMap);
  }

  Map<String, dynamic> _expandMap(Map<String, dynamic> map) {
    final result = <String, dynamic>{};
    for (final entry in map.entries) {
      result[entry.key] = _expandValue(entry.value);
    }
    return result;
  }

  dynamic _expandValue(dynamic value) {
    if (value is String) {
      return _expandString(value);
    } else if (value is Map<String, dynamic>) {
      return _expandMap(value);
    } else if (value is Map) {
      final converted = Map<String, dynamic>.from(value);
      return _expandMap(converted);
    } else if (value is List) {
      return value.map(_expandValue).toList();
    }
    return value;
  }

  /// Expands all `[[...]]` patterns in a string.
  String _expandString(String input) {
    return input.replaceAllMapped(_expansionPattern, (match) {
      final content = match.group(1)!;
      return _resolve(content);
    }).replaceAll(r'\[\[', '[[');
  }

  /// Resolves a single `[[content]]` expression.
  String _resolve(String content) {
    // Check if it's a generator (has separator)
    final sepIndex = content.lastIndexOf(';');
    if (sepIndex != -1) {
      return _resolveGenerator(
        content.substring(0, sepIndex),
        content.substring(sepIndex + 1),
      );
    }
    return _resolvePlaceholder(content);
  }

  /// Resolves a generator expression: `selector;separator`.
  String _resolveGenerator(String selector, String separator) {
    // Parse selector: key, key:field, key:field?filter=val, key:field|transform
    String? filterField;
    String? filterValue;
    String? transform;

    var fieldSelector = selector;

    // Check for filter: key:field?filter=val
    final filterMatch = RegExp(r'(.+)\?(\w+)=(\w+)$').firstMatch(fieldSelector);
    if (filterMatch != null) {
      fieldSelector = filterMatch.group(1)!;
      filterField = filterMatch.group(2)!;
      filterValue = filterMatch.group(3)!;
    }

    // Check for transform: key:field|transform or key|transform
    final transformMatch = RegExp(r'(.+)\|(\w+)$').firstMatch(fieldSelector);
    if (transformMatch != null) {
      fieldSelector = transformMatch.group(1)!;
      transform = transformMatch.group(2)!;
    }

    // Split key:field
    final colonIndex = fieldSelector.indexOf(':');
    final key = colonIndex >= 0 ? fieldSelector.substring(0, colonIndex) : fieldSelector;
    final field = colonIndex >= 0 ? fieldSelector.substring(colonIndex + 1) : null;

    final data = _data[key];
    if (data == null) return '[[$selector;$separator]]';

    if (data is! List) return '[[$selector;$separator]]';

    var values = <String>[];

    for (final item in data) {
      // Apply filter
      if (filterField != null && filterValue != null) {
        if (item is Map) {
          final fv = item[filterField]?.toString();
          if (fv != filterValue) continue;
        }
      }

      String? value;
      if (field != null) {
        // Extract nested field
        value = _extractField(item, field);
      } else if (item is Map) {
        value = item.values.firstOrNull?.toString();
      } else {
        value = item.toString();
      }

      if (value != null) {
        if (transform != null) {
          value = _applyTransform(value, transform);
        }
        values.add(value);
      }
    }

    return values.join(separator);
  }

  /// Resolves a placeholder expression: `key.field`, `key.index.field`, `key.length`.
  String _resolvePlaceholder(String selector) {
    // Check for transform or default: key.field|default
    String? defaultValue;
    var effectiveSelector = selector;

    final pipeIndex = selector.lastIndexOf('|');
    if (pipeIndex >= 0) {
      effectiveSelector = selector.substring(0, pipeIndex);
      defaultValue = selector.substring(pipeIndex + 1);
    }

    final parts = effectiveSelector.split('.');
    if (parts.isEmpty) return defaultValue ?? '[[$selector]]';

    final key = parts[0];
    final data = _data[key];
    if (data == null) return defaultValue ?? '[[$selector]]';

    // key.length
    if (parts.length == 2 && parts[1] == 'length') {
      if (data is List) return data.length.toString();
      if (data is Map) return data.length.toString();
      return defaultValue ?? '[[$selector]]';
    }

    // Navigate the path
    dynamic current = data;
    for (var i = 1; i < parts.length; i++) {
      if (current == null) return defaultValue ?? '[[$selector]]';

      final part = parts[i];

      // Try as index
      final index = int.tryParse(part);
      if (index != null && current is List && index < current.length) {
        current = current[index];
      } else if (current is Map) {
        current = current[part];
      } else {
        return defaultValue ?? '[[$selector]]';
      }
    }

    if (current == null) return defaultValue ?? '[[$selector]]';
    return current.toString();
  }

  /// Extracts a (possibly nested) field from a map item.
  String? _extractField(dynamic item, String field) {
    if (item is! Map) return null;

    // Support nested fields: a.b.c
    final parts = field.split('.');
    dynamic current = item;

    for (final part in parts) {
      if (current is Map) {
        current = current[part];
      } else {
        return null;
      }
    }

    return current?.toString();
  }

  /// Applies a transform to a value.
  String _applyTransform(String value, String transform) {
    switch (transform) {
      case 'uppercase':
        return value.toUpperCase();
      case 'lowercase':
        return value.toLowerCase();
      default:
        return value;
    }
  }
}
