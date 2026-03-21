import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

import '../models/schema/doc_spec_schema.dart';
import '../models/schema/schema_info.dart';
import 'schema_expander.dart';

/// Parses schema filenames to extract id and version.
///
/// Schema files must have the extension `.docspecs-schema.yaml` or
/// `.docspecs-schema.yml`. The name part before the extension is parsed
/// to extract an optional version (e.g., `name-1.0.docspecs-schema.yaml`).
class SchemaFilenameParser {
  /// Extension pattern for schema files.
  static final _extensionPattern = RegExp(
    r'\.docspecs-schema\.ya?ml$',
  );

  /// Optional version suffix in the name part.
  /// Matches both dash and dot separators:
  ///   `name-1.0`, `name.1.0`, `name-1.0.0`, `name.1.0.0`
  static final _versionPattern = RegExp(
    r'^(.+?)[.-](\d+\.\d+(?:\.\d+)?)$',
  );

  /// Checks whether a filename has a valid schema extension.
  static bool isSchemaFile(String filename) {
    return _extensionPattern.hasMatch(filename);
  }

  /// Parses a schema filename and returns the id and version.
  ///
  /// Returns null if the filename doesn't have the `.docspecs-schema.yaml`
  /// or `.docspecs-schema.yml` extension.
  ///
  /// If the filename includes a version (e.g., `spec-1.0.docspecs-schema.yaml`),
  /// it is extracted. Otherwise, version defaults to `'1.0'`.
  static ({String id, String version})? parse(String filename) {
    if (!isSchemaFile(filename)) return null;

    // Strip the extension to get the name part.
    final namePart = filename.replaceFirst(_extensionPattern, '');

    // Try to extract version from the name part.
    final versionMatch = _versionPattern.firstMatch(namePart);
    if (versionMatch != null) {
      return (
        id: versionMatch.group(1)!,
        version: versionMatch.group(2)!,
      );
    }

    return (id: namePart, version: '1.0');
  }
}

/// Loads DocSpec schemas from YAML files.
class SchemaLoader {
  /// Loads a schema from a file path.
  ///
  /// The schema id and version are extracted from the filename.
  static Future<DocSpecSchema> load(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw ArgumentError('Schema file not found: $filePath');
    }

    final content = await file.readAsString();
    return _parseSchema(content, filePath);
  }

  /// Loads a schema from a file path synchronously.
  static DocSpecSchema loadSync(String filePath) {
    final file = File(filePath);
    if (!file.existsSync()) {
      throw ArgumentError('Schema file not found: $filePath');
    }

    final content = file.readAsStringSync();
    return _parseSchema(content, filePath);
  }

  /// Parses schema content and extracts metadata from filename.
  static DocSpecSchema _parseSchema(String content, String filePath) {
    final filename = path.basename(filePath);
    final parsed = SchemaFilenameParser.parse(filename);

    if (parsed == null) {
      throw ArgumentError(
        'Invalid schema filename: $filename. '
        'Expected extension: .docspecs-schema.yaml or .docspecs-schema.yml',
      );
    }

    final yaml = loadYaml(content);
    final yamlMap = _deepConvertYaml(yaml) as Map<String, dynamic>;

    // Expand [[...]] placeholders/generators before model construction
    final expander = SchemaExpander(yamlMap);
    final expandedMap = expander.expand(yamlMap);

    return DocSpecSchema.fromYaml(
      expandedMap,
      id: parsed.id,
      version: parsed.version,
    );
  }

  /// Recursively converts YamlMap/YamlList to standard Dart Map/List.
  static dynamic _deepConvertYaml(dynamic value) {
    if (value is Map) {
      return Map<String, dynamic>.fromEntries(
        value.entries.map((e) => MapEntry(e.key.toString(), _deepConvertYaml(e.value))),
      );
    }
    if (value is List) {
      return value.map(_deepConvertYaml).toList();
    }
    return value;
  }
}

/// Resolves schemas from multiple locations.
class SchemaResolver {
  /// Standard schema file extension patterns.
  static const schemaExtensions = [
    '.docspecs-schema.yaml',
    '.docspecs-schema.yml',
  ];

  /// Resolves a schema by ID.
  ///
  /// Search order:
  /// 1. Local `.tom/docspecs-schema/` folders (walk up from [documentPath])
  /// 2. User schemas in `~/.tom/docspecs-schema/`
  /// 3. Built-in schemas (placeholder)
  ///
  /// The [schemaId] can be:
  /// - Full ID with version: `quest-overview-1.0`
  /// - ID with version separator: `quest-overview/1.0`
  static Future<DocSpecSchema?> resolve({
    required String schemaId,
    String? documentPath,
    String? workspaceRoot,
  }) async {
    final normalized = _normalizeSchemaId(schemaId);

    // Search local folders
    if (documentPath != null) {
      final localSchema = await _searchLocalFolders(
        normalized,
        documentPath,
        workspaceRoot,
      );
      if (localSchema != null) return localSchema;
    }

    // Search user folder
    final userSchema = await _searchUserFolder(normalized);
    if (userSchema != null) return userSchema;

    // Built-in schemas (placeholder)
    return null;
  }

  /// Resolves a schema synchronously.
  static DocSpecSchema? resolveSync({
    required String schemaId,
    String? documentPath,
    String? workspaceRoot,
  }) {
    final normalized = _normalizeSchemaId(schemaId);

    // Search local folders
    if (documentPath != null) {
      final localSchema = _searchLocalFoldersSync(
        normalized,
        documentPath,
        workspaceRoot,
      );
      if (localSchema != null) return localSchema;
    }

    // Search user folder
    final userSchema = _searchUserFolderSync(normalized);
    if (userSchema != null) return userSchema;

    // Built-in schemas (placeholder)
    return null;
  }

  /// Normalizes schema ID to filename format (e.g., "quest-overview-1.0").
  static String _normalizeSchemaId(String schemaId) {
    // Convert "id/version" to "id-version"
    return schemaId.replaceAll('/', '-');
  }

  /// Pattern to detect `*.ds.md` document filenames.
  ///
  /// Captures `<type>` from `<title>.<type>.ds.md`.
  static final _dsFilenamePattern = RegExp(r'^.+\.([^.]+)\.ds\.md$');

  /// Pattern to detect `<!-- docspec: id/version -->` in document text.
  static final _docspecCommentPattern = RegExp(
    r'<!--\s*docspec:\s*(\S+)\s*-->',
  );

  /// Resolves a schema by document filename convention.
  ///
  /// For a document named `<title>.<type>.ds.md`, searches for a schema
  /// folder matching `*.<type>/` in `.tom/docspecs-schema/` and loads the
  /// most recent schema version found (or the version specified in
  /// the document's `<!-- docspec: id/version -->` comment).
  ///
  /// Returns `null` if the filename doesn't match the convention or no
  /// matching schema folder is found.
  static Future<DocSpecSchema?> resolveByDocumentFilename({
    required String documentFilename,
    String? documentText,
    String? documentPath,
    String? workspaceRoot,
  }) async {
    final typeMatch = _dsFilenamePattern.firstMatch(documentFilename);
    if (typeMatch == null) return null;
    final type = typeMatch.group(1)!;

    // Extract version from document text if present.
    String? requestedVersion;
    if (documentText != null) {
      final commentMatch = _docspecCommentPattern.firstMatch(documentText);
      if (commentMatch != null) {
        final schemaRef = commentMatch.group(1)!;
        final parts = schemaRef.split('/');
        if (parts.length == 2) {
          requestedVersion = parts[1];
        }
      }
    }

    // Search local folders walking up from document path.
    if (documentPath != null) {
      final result = await _findSchemaByType(
        type,
        documentPath,
        workspaceRoot,
        requestedVersion,
      );
      if (result != null) return result;
    }

    // Search user folder.
    final home =
        Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
    if (home != null) {
      final userSchemaDir = path.join(home, '.tom', 'docspecs-schema');
      final result = await _findSchemaByTypeInFolder(
        userSchemaDir,
        type,
        requestedVersion,
      );
      if (result != null) return result;
    }

    return null;
  }

  /// Synchronous version of [resolveByDocumentFilename].
  static DocSpecSchema? resolveByDocumentFilenameSync({
    required String documentFilename,
    String? documentText,
    String? documentPath,
    String? workspaceRoot,
  }) {
    final typeMatch = _dsFilenamePattern.firstMatch(documentFilename);
    if (typeMatch == null) return null;
    final type = typeMatch.group(1)!;

    String? requestedVersion;
    if (documentText != null) {
      final commentMatch = _docspecCommentPattern.firstMatch(documentText);
      if (commentMatch != null) {
        final schemaRef = commentMatch.group(1)!;
        final parts = schemaRef.split('/');
        if (parts.length == 2) {
          requestedVersion = parts[1];
        }
      }
    }

    if (documentPath != null) {
      final result = _findSchemaByTypeSync(
        type,
        documentPath,
        workspaceRoot,
        requestedVersion,
      );
      if (result != null) return result;
    }

    final home =
        Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
    if (home != null) {
      final userSchemaDir = path.join(home, '.tom', 'docspecs-schema');
      final result = _findSchemaByTypeInFolderSync(
        userSchemaDir,
        type,
        requestedVersion,
      );
      if (result != null) return result;
    }

    return null;
  }

  /// Extracts the document type from a `.ds.md` filename.
  ///
  /// Returns `null` if the filename doesn't match `<title>.<type>.ds.md`.
  static String? extractDocumentType(String filename) {
    final match = _dsFilenamePattern.firstMatch(filename);
    return match?.group(1);
  }

  /// Checks whether a filename matches the `<title>.<type>.ds.md` pattern.
  static bool isDocSpecDocument(String filename) {
    return _dsFilenamePattern.hasMatch(filename);
  }

  static Future<DocSpecSchema?> _findSchemaByType(
    String type,
    String documentPath,
    String? workspaceRoot,
    String? requestedVersion,
  ) async {
    var currentDir = path.dirname(documentPath);
    final stopAt = workspaceRoot ?? path.rootPrefix(documentPath);

    while (currentDir.length >= stopAt.length) {
      final schemaDir = path.join(currentDir, '.tom', 'docspecs-schema');
      final result = await _findSchemaByTypeInFolder(
        schemaDir,
        type,
        requestedVersion,
      );
      if (result != null) return result;

      final parent = path.dirname(currentDir);
      if (parent == currentDir) break;
      currentDir = parent;
    }
    return null;
  }

  static DocSpecSchema? _findSchemaByTypeSync(
    String type,
    String documentPath,
    String? workspaceRoot,
    String? requestedVersion,
  ) {
    var currentDir = path.dirname(documentPath);
    final stopAt = workspaceRoot ?? path.rootPrefix(documentPath);

    while (currentDir.length >= stopAt.length) {
      final schemaDir = path.join(currentDir, '.tom', 'docspecs-schema');
      final result = _findSchemaByTypeInFolderSync(
        schemaDir,
        type,
        requestedVersion,
      );
      if (result != null) return result;

      final parent = path.dirname(currentDir);
      if (parent == currentDir) break;
      currentDir = parent;
    }
    return null;
  }

  /// Find a schema folder ending with `.<type>` and load the best version.
  static Future<DocSpecSchema?> _findSchemaByTypeInFolder(
    String schemaDir,
    String type,
    String? requestedVersion,
  ) async {
    final dir = Directory(schemaDir);
    if (!await dir.exists()) return null;

    // Find subdirectory matching *.<type>
    await for (final entity in dir.list()) {
      if (entity is Directory) {
        final dirName = path.basename(entity.path);
        if (dirName.endsWith('.$type')) {
          return _loadBestSchemaFromFolder(entity, requestedVersion);
        }
      }
    }
    return null;
  }

  static DocSpecSchema? _findSchemaByTypeInFolderSync(
    String schemaDir,
    String type,
    String? requestedVersion,
  ) {
    final dir = Directory(schemaDir);
    if (!dir.existsSync()) return null;

    for (final entity in dir.listSync()) {
      if (entity is Directory) {
        final dirName = path.basename(entity.path);
        if (dirName.endsWith('.$type')) {
          return _loadBestSchemaFromFolderSync(entity, requestedVersion);
        }
      }
    }
    return null;
  }

  /// Load the best schema from a folder — requested version or most recent.
  static Future<DocSpecSchema?> _loadBestSchemaFromFolder(
    Directory folder,
    String? requestedVersion,
  ) async {
    final candidates = <({String path, String id, String version})>[];

    await for (final entity in folder.list()) {
      if (entity is File) {
        final filename = path.basename(entity.path);
        final parsed = SchemaFilenameParser.parse(filename);
        if (parsed != null) {
          candidates.add((
            path: entity.path,
            id: parsed.id,
            version: parsed.version,
          ));
        }
      }
    }

    if (candidates.isEmpty) return null;

    // If a specific version was requested, try to find it.
    if (requestedVersion != null) {
      final match = candidates
          .where((c) => c.version == requestedVersion)
          .firstOrNull;
      if (match != null) return SchemaLoader.load(match.path);
    }

    // Otherwise load the most recent version (highest version string).
    candidates.sort((a, b) => _compareVersions(b.version, a.version));
    return SchemaLoader.load(candidates.first.path);
  }

  static DocSpecSchema? _loadBestSchemaFromFolderSync(
    Directory folder,
    String? requestedVersion,
  ) {
    final candidates = <({String path, String id, String version})>[];

    for (final entity in folder.listSync()) {
      if (entity is File) {
        final filename = path.basename(entity.path);
        final parsed = SchemaFilenameParser.parse(filename);
        if (parsed != null) {
          candidates.add((
            path: entity.path,
            id: parsed.id,
            version: parsed.version,
          ));
        }
      }
    }

    if (candidates.isEmpty) return null;

    if (requestedVersion != null) {
      final match = candidates
          .where((c) => c.version == requestedVersion)
          .firstOrNull;
      if (match != null) return SchemaLoader.loadSync(match.path);
    }

    candidates.sort((a, b) => _compareVersions(b.version, a.version));
    return SchemaLoader.loadSync(candidates.first.path);
  }

  /// Compare semver-style version strings (e.g., "1.0", "2.1.0").
  static int _compareVersions(String a, String b) {
    final partsA = a.split('.').map(int.tryParse).toList();
    final partsB = b.split('.').map(int.tryParse).toList();
    final len = partsA.length > partsB.length ? partsA.length : partsB.length;
    for (var i = 0; i < len; i++) {
      final va = i < partsA.length ? (partsA[i] ?? 0) : 0;
      final vb = i < partsB.length ? (partsB[i] ?? 0) : 0;
      if (va != vb) return va.compareTo(vb);
    }
    return 0;
  }

  /// Searches local `.tom/docspecs-schema/` folders walking up from document path.
  static Future<DocSpecSchema?> _searchLocalFolders(
    String schemaId,
    String documentPath,
    String? workspaceRoot,
  ) async {
    var currentDir = path.dirname(documentPath);
    final stopAt = workspaceRoot ?? path.rootPrefix(documentPath);

    while (currentDir.length >= stopAt.length) {
      final schemaPath = await _findSchemaInFolder(
        path.join(currentDir, '.tom', 'docspecs-schema'),
        schemaId,
      );
      if (schemaPath != null) {
        return SchemaLoader.load(schemaPath);
      }

      final parent = path.dirname(currentDir);
      if (parent == currentDir) break;
      currentDir = parent;
    }

    return null;
  }

  /// Searches local folders synchronously.
  static DocSpecSchema? _searchLocalFoldersSync(
    String schemaId,
    String documentPath,
    String? workspaceRoot,
  ) {
    var currentDir = path.dirname(documentPath);
    final stopAt = workspaceRoot ?? path.rootPrefix(documentPath);

    while (currentDir.length >= stopAt.length) {
      final schemaPath = _findSchemaInFolderSync(
        path.join(currentDir, '.tom', 'docspecs-schema'),
        schemaId,
      );
      if (schemaPath != null) {
        return SchemaLoader.loadSync(schemaPath);
      }

      final parent = path.dirname(currentDir);
      if (parent == currentDir) break;
      currentDir = parent;
    }

    return null;
  }

  /// Searches the user schema folder.
  static Future<DocSpecSchema?> _searchUserFolder(String schemaId) async {
    final home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
    if (home == null) return null;

    final userSchemaDir = path.join(home, '.tom', 'docspecs-schema');
    final schemaPath = await _findSchemaInFolder(userSchemaDir, schemaId);
    if (schemaPath != null) {
      return SchemaLoader.load(schemaPath);
    }

    return null;
  }

  /// Searches user folder synchronously.
  static DocSpecSchema? _searchUserFolderSync(String schemaId) {
    final home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
    if (home == null) return null;

    final userSchemaDir = path.join(home, '.tom', 'docspecs-schema');
    final schemaPath = _findSchemaInFolderSync(userSchemaDir, schemaId);
    if (schemaPath != null) {
      return SchemaLoader.loadSync(schemaPath);
    }

    return null;
  }

  /// Finds a schema file in a folder (checks both direct and subfolder).
  static Future<String?> _findSchemaInFolder(
    String folderPath,
    String schemaId,
  ) async {
    final dir = Directory(folderPath);
    if (!await dir.exists()) return null;

    // Extract schema name (without version) for subfolder check
    final parsed = SchemaFilenameParser._versionPattern.firstMatch(schemaId);
    final schemaName = parsed?.group(1) ?? schemaId;
    final version = parsed?.group(2);

    // Build candidate filenames: both dash and dot separators
    final candidates = <String>[];
    for (final ext in schemaExtensions) {
      candidates.add('$schemaId$ext');
      if (version != null) {
        // Also try dot-separated version: name.version.ext
        candidates.add('$schemaName.$version$ext');
      }
    }

    // Check in subfolder first (e.g., .tom/docspecs-schema/quest-overview/)
    for (final candidate in candidates) {
      final subfolderPath = path.join(folderPath, schemaName, candidate);
      if (await File(subfolderPath).exists()) {
        return subfolderPath;
      }
    }

    // Check directly in folder
    for (final candidate in candidates) {
      final directPath = path.join(folderPath, candidate);
      if (await File(directPath).exists()) {
        return directPath;
      }
    }

    return null;
  }

  /// Finds schema file synchronously.
  static String? _findSchemaInFolderSync(
    String folderPath,
    String schemaId,
  ) {
    final dir = Directory(folderPath);
    if (!dir.existsSync()) return null;

    // Extract schema name (without version) for subfolder check
    final parsed = SchemaFilenameParser._versionPattern.firstMatch(schemaId);
    final schemaName = parsed?.group(1) ?? schemaId;
    final version = parsed?.group(2);

    // Build candidate filenames: both dash and dot separators
    final candidates = <String>[];
    for (final ext in schemaExtensions) {
      candidates.add('$schemaId$ext');
      if (version != null) {
        candidates.add('$schemaName.$version$ext');
      }
    }

    // Check in subfolder first
    for (final candidate in candidates) {
      final subfolderPath = path.join(folderPath, schemaName, candidate);
      if (File(subfolderPath).existsSync()) {
        return subfolderPath;
      }
    }

    // Check directly in folder
    for (final candidate in candidates) {
      final directPath = path.join(folderPath, candidate);
      if (File(directPath).existsSync()) {
        return directPath;
      }
    }

    return null;
  }
}

/// Discovers available schemas across all locations.
class SchemaDiscovery {
  /// Lists all available schemas from all locations.
  ///
  /// Returns schemas in priority order (local > user > builtin).
  /// Duplicates are removed, keeping the highest priority version.
  static Future<List<SchemaInfo>> listSchemas({
    String? documentPath,
    String? workspaceRoot,
  }) async {
    final schemas = <String, SchemaInfo>{}; // fullId -> info

    // Search local folders
    if (documentPath != null) {
      await _discoverLocalSchemas(
        schemas,
        documentPath,
        workspaceRoot,
      );
    }

    // Search user folder
    await _discoverUserSchemas(schemas);

    // Built-in schemas (placeholder)

    return schemas.values.toList();
  }

  /// Lists schemas synchronously.
  static List<SchemaInfo> listSchemasSync({
    String? documentPath,
    String? workspaceRoot,
  }) {
    final schemas = <String, SchemaInfo>{};

    if (documentPath != null) {
      _discoverLocalSchemasSync(schemas, documentPath, workspaceRoot);
    }

    _discoverUserSchemasSync(schemas);

    return schemas.values.toList();
  }

  /// Lists schemas from a specific folder.
  static Future<List<SchemaInfo>> listSchemasIn(String folderPath) async {
    final schemas = <SchemaInfo>[];
    await _discoverInFolder(schemas, folderPath, SchemaSource.local);
    return schemas;
  }

  /// Lists schemas from a specific folder synchronously.
  static List<SchemaInfo> listSchemasInSync(String folderPath) {
    final schemas = <SchemaInfo>[];
    _discoverInFolderSync(schemas, folderPath, SchemaSource.local);
    return schemas;
  }

  static Future<void> _discoverLocalSchemas(
    Map<String, SchemaInfo> schemas,
    String documentPath,
    String? workspaceRoot,
  ) async {
    var currentDir = path.dirname(documentPath);
    final stopAt = workspaceRoot ?? path.rootPrefix(documentPath);

    while (currentDir.length >= stopAt.length) {
      final schemaDir = path.join(currentDir, '.tom', 'docspecs-schema');
      final temp = <SchemaInfo>[];
      await _discoverInFolder(temp, schemaDir, SchemaSource.local);

      for (final info in temp) {
        schemas.putIfAbsent(info.fullId, () => info);
      }

      final parent = path.dirname(currentDir);
      if (parent == currentDir) break;
      currentDir = parent;
    }
  }

  static void _discoverLocalSchemasSync(
    Map<String, SchemaInfo> schemas,
    String documentPath,
    String? workspaceRoot,
  ) {
    var currentDir = path.dirname(documentPath);
    final stopAt = workspaceRoot ?? path.rootPrefix(documentPath);

    while (currentDir.length >= stopAt.length) {
      final schemaDir = path.join(currentDir, '.tom', 'docspecs-schema');
      final temp = <SchemaInfo>[];
      _discoverInFolderSync(temp, schemaDir, SchemaSource.local);

      for (final info in temp) {
        schemas.putIfAbsent(info.fullId, () => info);
      }

      final parent = path.dirname(currentDir);
      if (parent == currentDir) break;
      currentDir = parent;
    }
  }

  static Future<void> _discoverUserSchemas(
    Map<String, SchemaInfo> schemas,
  ) async {
    final home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
    if (home == null) return;

    final userSchemaDir = path.join(home, '.tom', 'docspecs-schema');
    final temp = <SchemaInfo>[];
    await _discoverInFolder(temp, userSchemaDir, SchemaSource.user);

    for (final info in temp) {
      schemas.putIfAbsent(info.fullId, () => info);
    }
  }

  static void _discoverUserSchemasSync(Map<String, SchemaInfo> schemas) {
    final home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
    if (home == null) return;

    final userSchemaDir = path.join(home, '.tom', 'docspecs-schema');
    final temp = <SchemaInfo>[];
    _discoverInFolderSync(temp, userSchemaDir, SchemaSource.user);

    for (final info in temp) {
      schemas.putIfAbsent(info.fullId, () => info);
    }
  }

  static Future<void> _discoverInFolder(
    List<SchemaInfo> schemas,
    String folderPath,
    SchemaSource source,
  ) async {
    final dir = Directory(folderPath);
    if (!await dir.exists()) return;

    await for (final entity in dir.list(recursive: true)) {
      if (entity is File) {
        final filename = path.basename(entity.path);
        final parsed = SchemaFilenameParser.parse(filename);
        if (parsed != null) {
          schemas.add(SchemaInfo(
            id: parsed.id,
            version: parsed.version,
            path: entity.path,
            source: source,
          ));
        }
      }
    }
  }

  static void _discoverInFolderSync(
    List<SchemaInfo> schemas,
    String folderPath,
    SchemaSource source,
  ) {
    final dir = Directory(folderPath);
    if (!dir.existsSync()) return;

    for (final entity in dir.listSync(recursive: true)) {
      if (entity is File) {
        final filename = path.basename(entity.path);
        final parsed = SchemaFilenameParser.parse(filename);
        if (parsed != null) {
          schemas.add(SchemaInfo(
            id: parsed.id,
            version: parsed.version,
            path: entity.path,
            source: source,
          ));
        }
      }
    }
  }
}
