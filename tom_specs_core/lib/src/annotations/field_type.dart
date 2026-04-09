/// Annotates a `String?` field with its semantic type — what the string
/// actually represents.
///
/// Applied to `String?` leaf fields.
///
/// Common values: `'int'`, `'double'`, `'date'`, `'time'`, `'datetime'`.
///
/// In the outline, shown as `fieldName @date` etc.
class FieldType {
  final String type;

  const FieldType(this.type);
}
