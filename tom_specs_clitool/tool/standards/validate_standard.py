"""Validates a document emitted by `irspecs emit` against its standard's
vendored meta-schema, offline (README.md in this folder)."""
import glob
import json
import os
import sys

from jsonschema import Draft7Validator, Draft202012Validator
from referencing import Registry, Resource

HERE = os.path.dirname(os.path.abspath(__file__))

SCHEMAS = {
    "openapi": ("openapi-3.1/schema-base-2022-10-07.json", Draft202012Validator),
    "jsonschema": ("jsonschema-2020-12/schema.json", Draft202012Validator),
    "asyncapi": ("asyncapi-3.0.0/asyncapi-3.0.0.json", Draft7Validator),
}


def registry():
    reg = Registry()
    for path in glob.glob(os.path.join(HERE, "**", "*.json"), recursive=True):
        with open(path, encoding="utf-8") as f:
            contents = json.load(f)
        if "$id" in contents:
            reg = reg.with_resource(
                contents["$id"].rstrip("#"), Resource.from_contents(contents)
            )
    return reg


def main(argv):
    if len(argv) != 3 or argv[1] not in SCHEMAS:
        print(__doc__)
        print("usage: validate_standard.py <%s> <document.json>" % "|".join(SCHEMAS))
        return 2
    schema_file, validator = SCHEMAS[argv[1]]
    with open(os.path.join(HERE, schema_file), encoding="utf-8") as f:
        schema = json.load(f)
    with open(argv[2], encoding="utf-8") as f:
        document = json.load(f)
    errors = sorted(
        validator(schema, registry=registry()).iter_errors(document),
        key=lambda e: list(e.absolute_path),
    )
    for e in errors:
        print("/".join(str(p) for p in e.absolute_path) or "(root)", "-", e.message)
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
