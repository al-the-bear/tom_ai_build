package tom_som_runtime;

/** What a resolved path lands on in the model. */
public enum SpecNodeKind {
  ROOT("root"),
  COMPLEX("complex"),
  SECTION("section"),
  LIST("list"),
  LIST_ITEM_COMPLEX("listItemComplex"),
  LIST_ITEM_SCALAR("listItemScalar"),
  FORM("form"),
  CONTENT("content"),
  ENUM_VALUE("enumValue"),
  SCALAR("scalar");

  public final String value;

  SpecNodeKind(String value) {
    this.value = value;
  }
}
