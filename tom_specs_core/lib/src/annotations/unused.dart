/// Marks a `content` field as unused — section text is not expected and will
/// be ignored by tooling.
///
/// Applied to the `content` field of classes where the section serves only as
/// a structural container for subsections, with no narrative text of its own.
class Unused {
  const Unused();
}
