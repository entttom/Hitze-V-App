#!/usr/bin/env python3
from __future__ import annotations

import argparse
import ast
import pathlib
import sys


REPO_ROOT = pathlib.Path(__file__).resolve().parents[1]
ANDROID_COPYBOOK = REPO_ROOT / "Android" / "app" / "src" / "main" / "java" / "org" / "entner" / "HitzeV" / "ui" / "copy" / "Copybook.kt"
IOS_CATALOG = REPO_ROOT / "iOS" / "Hitze-V" / "Hitze-V" / "CopybookTranslationCatalog.swift"

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

ANDROID_SUPPLEMENTAL_KEYS = {
    "Adjust appearance, language, and legal details.",
    "Language",
    "Set a label and then search for an address in Austria.",
    "So that we can warn you in time about dangerous heat levels at your workplaces, we need your permission for push notifications. Please allow them in the next step.",
}


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


def required_english_keys() -> set[str]:
    source = ANDROID_COPYBOOK.read_text()
    keys: set[str] = set()

    def collect(function_name: str) -> None:
        needle = f"{function_name}("
        index = 0
        while True:
            index = source.find(needle, index)
            if index == -1:
                return

            cursor = index + len(needle)
            while cursor < len(source) and source[cursor].isspace():
                cursor += 1
            if not source.startswith('"""', cursor) and source[cursor] != '"':
                index = cursor
                continue

            _, cursor = read_string_literal(source, cursor)
            while cursor < len(source) and source[cursor].isspace():
                cursor += 1
            if cursor >= len(source) or source[cursor] != ",":
                index = cursor
                continue

            cursor += 1
            while cursor < len(source) and source[cursor].isspace():
                cursor += 1
            if not source.startswith('"""', cursor) and source[cursor] != '"':
                index = cursor
                continue

            english_literal, cursor = read_string_literal(source, cursor)
            english = decode_literal(english_literal)
            if r"\(" in english:
                continue
            keys.add(english)
            index = cursor

    collect("t")
    collect("bulletLines")
    return keys


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
    result = parse_dictionary_keys(IOS_CATALOG.read_text(), "translations")
    for code in LANGUAGE_CODES:
        result.setdefault(code, set()).update(ANDROID_SUPPLEMENTAL_KEYS)
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
        print("Android Copybook localization audit passed.")
        return 0

    print("Android Copybook localization audit found missing keys:")
    for code, missing in missing_by_language.items():
        print(f"- {code}: {len(missing)} missing")
        for key in missing[:5]:
            print(f"  - {key.splitlines()[0]}")

    return 1 if args.strict else 0


if __name__ == "__main__":
    raise SystemExit(main())
