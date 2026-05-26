#!/usr/bin/env python3
"""
validate_xhtml.py

Validate all .xhtml files in a directory (recursively) using lxml.
Outputs validation results (including errors) to a JSON file.

Usage:
    python validate_xhtml.py /path/to/folder
"""

import sys
import json
from pathlib import Path
from lxml import etree


def validate_file(file_path: Path):
    """
    Validate a single XHTML file for well-formedness and (optionally) DTD validation.

    Returns:
        dict with keys:
            - file (str)
            - valid (bool)
            - errors (list of dicts)
    """
    result = {
        "file": str(file_path),
        "valid": True,
        "errors": []
    }

    try:
        # Configure parser:
        # - dtd_validation=True enables DTD validation if DOCTYPE is present
        # - load_dtd=True allows loading referenced DTD
        # - no_network=True prevents fetching remote DTDs (safer)
        parser = etree.XMLParser(
        dtd_validation=False,
        load_dtd=True,
        no_network=True,
        recover=False
    )

        # Parse file
        etree.parse(str(file_path), parser)

    except etree.XMLSyntaxError as e:
        result["valid"] = False

        # Extract all errors from the error log
        for error in e.error_log:
            result["errors"].append({
                "line": error.line,
                "column": error.column,
                "message": error.message.strip()
            })

    except (OSError, IOError) as e:
        result["valid"] = False
        result["errors"].append({
            "line": None,
            "column": None,
            "message": f"I/O error: {str(e)}"
        })

    except Exception as e:
        result["valid"] = False
        result["errors"].append({
            "line": None,
            "column": None,
            "message": f"Unexpected error: {str(e)}"
        })

    return result


def find_xhtml_files(directory: Path):
    """Recursively find all .xhtml files in a directory."""
    return list(directory.rglob("*.xhtml"))


def main():
    if len(sys.argv) != 2:
        print("Usage: python validate_xhtml.py /path/to/folder")
        sys.exit(1)

    input_dir = Path(sys.argv[1])

    if not input_dir.exists() or not input_dir.is_dir():
        print(f"Error: '{input_dir}' is not a valid directory.")
        sys.exit(1)

    files = find_xhtml_files(input_dir)

    results = {"files": []}

    total = 0
    valid_count = 0
    invalid_count = 0

    for file_path in files:
        total += 1
        result = validate_file(file_path)

        if result["valid"]:
            valid_count += 1
        else:
            invalid_count += 1

        results["files"].append(result)

    # Optional summary
    results["summary"] = {
        "total_files": total,
        "valid_files": valid_count,
        "invalid_files": invalid_count
    }

    # Write JSON output
    output_file = Path("validation_results.json")
    try:
        with output_file.open("w", encoding="utf-8") as f:
            json.dump(results, f, indent=2, ensure_ascii=False)
        print(f"Validation complete. Results written to '{output_file}'.")
    except Exception as e:
        print(f"Failed to write JSON output: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()