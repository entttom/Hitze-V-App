#!/usr/bin/env python3
from __future__ import annotations

import argparse
import ast
import pathlib
import re
import sys


APP_ROOT = pathlib.Path(__file__).resolve().parents[1] / "iOS" / "Hitze-V" / "Hitze-V"
CONTENT_VIEW = APP_ROOT / "ContentView.swift"
CATALOG = APP_ROOT / "CopybookTranslationCatalog.swift"

LANGUAGE_CODES = [
    "bg",
    "da",
    "et",
    "fi",
    "fr",
    "el",
    "ga",
    "it",
    "hr",
    "lv",
    "lt",
    "mt",
    "nl",
    "pl",
    "pt",
    "ro",
    "sv",
    "sk",
    "sl",
    "es",
    "cs",
    "hu",
    "tr",
]


def decode_literal(literal: str) -> str:
    if literal.startswith('"""'):
        body = literal[3:-3]
        lines = body.splitlines()
        while lines and not lines[0].strip():
            lines.pop(0)
        while lines and not lines[-1].strip():
            lines.pop()
        indent = min((len(line) - len(line.lstrip()) for line in lines if line.strip()), default=0)
        return "\n".join(line[indent:] for line in lines)
    return ast.literal_eval(literal)


def required_english_keys() -> set[str]:
    source = "\n".join(path.read_text() for path in APP_ROOT.glob("*.swift"))
    string_pattern = r'("""(?:.|\n)*?"""|"(?:[^"\\]|\\.)*")'
    patterns = [
        re.compile(r"t\(\s*" + string_pattern + r"\s*,\s*" + string_pattern + r"\s*\)", re.S),
        re.compile(r"bulletLines\(\s*" + string_pattern + r"\s*,\s*" + string_pattern + r"\s*\)", re.S),
    ]

    keys: set[str] = set()
    for pattern in patterns:
        for match in pattern.finditer(source):
            english = decode_literal(match.group(2))
            if r"\(" in english:
                continue
            keys.add(english)
    return keys


def scan_balanced_brackets(text: str, start_index: int) -> tuple[str, int]:
    depth = 0
    i = start_index
    in_string = False
    in_triple = False

    while i < len(text):
        if in_triple:
            if text.startswith('"""', i):
                in_triple = False
                i += 3
            else:
                i += 1
            continue

        if in_string:
            if text[i] == "\\":
                i += 2
                continue
            if text[i] == '"':
                in_string = False
            i += 1
            continue

        if text.startswith('"""', i):
            in_triple = True
            i += 3
            continue

        if text[i] == '"':
            in_string = True
            i += 1
            continue

        if text[i] == "[":
            depth += 1
        elif text[i] == "]":
            depth -= 1
            if depth == 0:
                return text[start_index:i + 1], i + 1

        i += 1

    raise ValueError("Unbalanced bracket block")


def read_string_literal(text: str, start_index: int) -> tuple[str, int]:
    if text.startswith('"""', start_index):
        i = start_index + 3
        while i < len(text):
            if text.startswith('"""', i):
                return text[start_index:i + 3], i + 3
            i += 1
        raise ValueError("Unterminated triple-quoted string")

    i = start_index + 1
    while i < len(text):
        if text[i] == "\\":
            i += 2
            continue
        if text[i] == '"':
            return text[start_index:i + 1], i + 1
        i += 1

    raise ValueError("Unterminated string literal")


def parse_dictionary_keys(source_text: str, dictionary_name: str) -> dict[str, set[str]]:
    result: dict[str, set[str]] = {code: set() for code in LANGUAGE_CODES}
    marker = f"private static let {dictionary_name}: [ResolvedLanguage: [String: String]] = ["
    start = source_text.find(marker)
    if start == -1:
        return result

    outer_start = source_text.find("[", start + len(marker) - 1)
    if outer_start == -1:
        return result

    outer_block, _ = scan_balanced_brackets(source_text, outer_start)
    i = 1
    while i < len(outer_block) - 1:
        if outer_block[i].isspace() or outer_block[i] == ",":
            i += 1
            continue

        if outer_block[i] != ".":
            i += 1
            continue

        identifier_start = i + 1
        while identifier_start < len(outer_block) and outer_block[identifier_start].isspace():
            identifier_start += 1
        identifier_end = identifier_start
        while identifier_end < len(outer_block) and (outer_block[identifier_end].isalnum() or outer_block[identifier_end] == "_"):
            identifier_end += 1
        language_code = outer_block[identifier_start:identifier_end]
        if language_code not in result:
            i = identifier_end
            continue

        colon_index = outer_block.find(":", identifier_end)
        if colon_index == -1:
            break
        nested_start = outer_block.find("[", colon_index)
        if nested_start == -1:
            break

        nested_block, nested_end = scan_balanced_brackets(outer_block, nested_start)
        j = 1
        while j < len(nested_block) - 1:
            if nested_block[j] == '"':
                literal, literal_end = read_string_literal(nested_block, j)
                k = literal_end
                while k < len(nested_block) and nested_block[k].isspace():
                    k += 1
                if k < len(nested_block) and nested_block[k] == ":":
                    result[language_code].add(decode_literal(literal))
                j = literal_end
                continue
            j += 1

        i = nested_end

    return result


def available_keys() -> dict[str, set[str]]:
    result: dict[str, set[str]] = {code: set() for code in LANGUAGE_CODES}

    content_view_text = CONTENT_VIEW.read_text()
    for dictionary_name in ("translations", "longTextTranslations"):
        parsed = parse_dictionary_keys(content_view_text, dictionary_name)
        for code, keys in parsed.items():
            result.setdefault(code, set()).update(keys)

    if CATALOG.exists():
        catalog_text = CATALOG.read_text()
        parsed = parse_dictionary_keys(catalog_text, "translations")
        for code, keys in parsed.items():
            result.setdefault(code, set()).update(keys)

    return result


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--strict", action="store_true")
    args = parser.parse_args()

    required = required_english_keys()
    catalog = available_keys()

    missing_by_language: dict[str, list[str]] = {}
    for code in LANGUAGE_CODES:
        present = catalog.get(code, set())
        missing = sorted(required - present)
        if missing:
            missing_by_language[code] = missing

    if not missing_by_language:
        print("Copybook localization audit passed.")
        return 0

    print("Copybook localization audit found missing keys:")
    for code, missing in missing_by_language.items():
        print(f"- {code}: {len(missing)} missing")
        for key in missing[:5]:
            print(f"  - {key.splitlines()[0]}")
        if len(missing) > 5:
            print("  - ...")

    if args.strict:
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
