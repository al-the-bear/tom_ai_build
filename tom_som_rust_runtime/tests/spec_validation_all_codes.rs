//! `SPEC_VALIDATION_ALL_CODES` must list every `SPEC_VALIDATION_CODE_*`
//! constant, in declaration order: it is the enumerable vocabulary a
//! constant-based port owes its readers in place of an enum, and a code added
//! without it would be invisible to every tool that enumerates the list.

use tom_som_rust_runtime::SPEC_VALIDATION_ALL_CODES;

#[test]
fn lists_every_declared_code_in_order() {
    let source = include_str!("../src/spec_validator.rs");
    let declared: Vec<&str> = source
        .lines()
        .filter_map(|line| line.strip_prefix("pub const SPEC_VALIDATION_CODE_"))
        .filter_map(|rest| rest.split('"').nth(1))
        .collect();
    assert!(
        !declared.is_empty(),
        "no SPEC_VALIDATION_CODE_* constants were read"
    );
    assert_eq!(SPEC_VALIDATION_ALL_CODES.to_vec(), declared);
}
