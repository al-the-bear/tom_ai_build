/// The section-path grammar shared by the in-memory [SpecDocument] and the
/// meta-model traversal ([SpecReflection]).
///
/// A path is the globally-unique address of a node in a concrete document. It
/// is exactly the grammar the editor writes values under (see
/// `tom_specs_editor`'s document tree), so a saved document and a freshly
/// resolved path agree segment-for-segment:
///
///   * the **root** is the document root's *section segment* — its
///     `@SectionId` when present, otherwise the root class name;
///   * a **child field** appends `/<segment>`, where the field's section
///     segment is its `@SectionId` when present, otherwise the field name;
///   * a **complex / section** field collapses into its target class: the
///     class's own children hang directly off the field's path (no extra
///     segment);
///   * a **list item** appends `-<seq>` to the list field's path (no `/`),
///     where `seq` is the per-list monotonic sequence number — so item paths
///     read `…/<listSegment>-1`, `…/<listSegment>-2`, ….
///
/// Form-field values are *not* path segments: a `@Form` section is one path
/// (the form field's path) whose individual fields are sub-keys inside the
/// document's form store, addressed by form-field name rather than by path.
///
/// Keeping this grammar in one place lets the runtime resolve any document path
/// back to its meta-model field/class without re-deriving the segment names.
library;

/// The path separator between section segments.
const String kSpecPathSeparator = '/';

/// Joins [parent] with a child [segment] using the path separator.
String specPathJoin(String parent, String segment) =>
    '$parent$kSpecPathSeparator$segment';

/// Splits [path] into its `/`-separated segments. A list-item sequence suffix
/// (`<segment>-3`) stays attached to its segment — it is part of the segment,
/// not a separate level.
List<String> specPathSegments(String path) => path.split(kSpecPathSeparator);

/// The path of the [seq]-th item appended to the list at [listPath]
/// (`"$listPath-$seq"`), matching [SpecDocument.addListItem].
String listItemPath(String listPath, int seq) => '$listPath-$seq';

/// Splits a list-item [segment] into its base segment and sequence number when
/// it ends in `-<digits>`, or returns `null` when it carries no numeric suffix.
///
/// The numeric suffix is what disambiguates a list item from an ordinary
/// segment whose name happens to contain a hyphen (e.g. a `@SectionId` like
/// `PD00-ROL`): only an all-digit tail counts.
({String base, int seq})? splitListItemSegment(String segment) {
  final dash = segment.lastIndexOf('-');
  if (dash <= 0 || dash == segment.length - 1) return null;
  final tail = segment.substring(dash + 1);
  final seq = int.tryParse(tail);
  if (seq == null) return null;
  return (base: segment.substring(0, dash), seq: seq);
}
