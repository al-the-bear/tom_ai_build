//! `CodeSpecsExtractSet::from_directory` — a run's extract folder read from
//! disk. Every `scopeCases` entry of the shared corpus
//! (`codespecs_record_cases.json`) is written into its own folder, together
//! with the files the reader must pass over (an `.extract.md` view, an
//! unrelated file, a sub-folder named like an extract), and the set read from
//! the folder must equal `from_files` over the same files in name order — the
//! order `from_directory` documents. Cases whose sources sit in several
//! folders are not one listing and are left to the conformance runner. A
//! missing folder is refused.

use std::fs;
use std::path::PathBuf;

use tom_som_rust_runtime::json::Json;
use tom_som_rust_runtime::CodeSpecsExtractSet;

fn corpus_cases() -> Vec<Json> {
    let path = PathBuf::from(env!("CARGO_MANIFEST_DIR"))
        .join("../tom_som_conformance/corpus/codespecs_record_cases.json");
    let text = fs::read_to_string(&path).expect("read codespecs_record_cases.json");
    let table = Json::parse(&text).expect("parse codespecs_record_cases.json");
    table
        .get("scopeCases")
        .and_then(|v| v.as_array())
        .expect("scopeCases")
        .to_vec()
}

fn case_files(case: &Json) -> Vec<(String, String)> {
    case.get("files")
        .and_then(|v| v.as_array())
        .expect("a files list")
        .iter()
        .map(|pair| {
            let pair = pair.as_array().expect("a [name, text] pair");
            (
                pair[0].as_str().expect("a name").to_string(),
                pair[1].as_str().expect("a text").to_string(),
            )
        })
        .collect()
}

/// A fresh folder under cargo's per-target scratch directory.
fn scratch(name: &str) -> PathBuf {
    let dir = PathBuf::from(env!("CARGO_TARGET_TMPDIR"))
        .join("codespecs_extract_directory")
        .join(name);
    if dir.exists() {
        fs::remove_dir_all(&dir).expect("clear the scratch folder");
    }
    fs::create_dir_all(&dir).expect("create the scratch folder");
    dir
}

#[test]
fn from_directory_reads_what_from_files_reads() {
    let cases = corpus_cases();
    assert!(!cases.is_empty(), "the corpus has scope cases");
    let mut read = 0;
    for (n, case) in cases.iter().enumerate() {
        let name = case.get("name").and_then(|v| v.as_str()).unwrap_or("?");
        let files = case_files(case);
        // A case whose sources sit in several folders (`a/gate.verdicts.yaml`,
        // `copy/CE-FM.extract.yaml`) is not one directory's listing.
        if files.iter().any(|(file, _)| file.contains('/')) {
            continue;
        }
        read += 1;
        let dir = scratch(&format!("case_{}", n));
        // Written in reverse, so a reader that took the listing's order would
        // differ from one that sorts by name.
        for (file, text) in files.iter().rev() {
            fs::write(dir.join(file), text).expect("write a case file");
        }
        fs::write(dir.join("CE-FM.extract.md"), "# a rendered view\n").unwrap();
        fs::write(dir.join("notes.txt"), "not an extract\n").unwrap();
        fs::create_dir_all(dir.join("CE-ZZ.extract.yaml")).unwrap();

        let mut sorted = files.clone();
        sorted.sort_by(|a, b| a.0.cmp(&b.0));
        let want = CodeSpecsExtractSet::from_files(sorted);
        let got = CodeSpecsExtractSet::from_directory(&dir);
        match (&want, &got) {
            (Ok(w), Ok(g)) => assert_eq!(g, w, "case {:?}", name),
            (Err(w), Err(g)) => assert_eq!(g.message, w.message, "case {:?}", name),
            _ => panic!(
                "case {:?}: from_files {:?}, from_directory {:?}",
                name, want, got
            ),
        }
        if let Some(error) = case
            .get("expect")
            .and_then(|e| e.get("error"))
            .and_then(|e| e.as_str())
        {
            let message = got.expect_err("the case expects an error").message;
            assert!(message.contains(error), "case {:?}: {}", name, message);
        }
    }
    assert!(
        read >= 6,
        "only {} single-folder scope cases were read",
        read
    );
}

#[test]
fn from_directory_refuses_a_missing_folder() {
    let dir = scratch("missing").join("absent");
    let err = CodeSpecsExtractSet::from_directory(&dir).expect_err("a missing folder");
    assert!(
        err.message.starts_with("extract directory not found: "),
        "{}",
        err.message
    );
}

#[test]
fn from_directory_of_an_empty_folder_is_an_empty_set() {
    let dir = scratch("empty");
    fs::write(dir.join("README.md"), "nothing here\n").unwrap();
    let got = CodeSpecsExtractSet::from_directory(&dir);
    assert_eq!(
        got,
        CodeSpecsExtractSet::from_files(Vec::<(String, String)>::new())
    );
}
