package tom_som_runtime;

/**
 * A structural error in a {@code *.docspecs.yaml} file: wrong/unsupported
 * format version, a key that does not match the metadata tree at its position,
 * a malformed value shape, or (on encode) document values the tree cannot
 * place — a faithful port of {@code spec_document_yaml.dart} /
 * {@code spec_document_yaml.ts}.
 *
 * <p>{@link #getMessage()} says what went wrong, naming the offending path/key
 * where applicable.
 */
public final class SpecYamlFormatException extends RuntimeException {
  private static final long serialVersionUID = 1L;

  public SpecYamlFormatException(String message) {
    super(message);
  }
}
