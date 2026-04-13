#!/usr/bin/env python3
from __future__ import annotations

import ast
import pathlib
import sys


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


def parse_translations(source_text: str) -> list[tuple[str, list[tuple[str, str]]]]:
    marker = "private static let translations: [ResolvedLanguage: [String: String]] = ["
    start = source_text.find(marker)
    if start == -1:
        raise ValueError("Could not find CopybookTranslationCatalog translations dictionary")

    outer_start = source_text.find("[", start + len(marker) - 1)
    if outer_start == -1:
        raise ValueError("Could not find outer dictionary start")

    outer_block, _ = scan_balanced_brackets(source_text, outer_start)
    languages: list[tuple[str, list[tuple[str, str]]]] = []
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
        while identifier_end < len(outer_block) and (
            outer_block[identifier_end].isalnum() or outer_block[identifier_end] == "_"
        ):
            identifier_end += 1
        language_code = outer_block[identifier_start:identifier_end]

        colon_index = outer_block.find(":", identifier_end)
        if colon_index == -1:
            raise ValueError(f"Missing ':' after language {language_code}")
        nested_start = outer_block.find("[", colon_index)
        if nested_start == -1:
            raise ValueError(f"Missing nested dictionary for language {language_code}")

        nested_block, nested_end = scan_balanced_brackets(outer_block, nested_start)
        entries: list[tuple[str, str]] = []
        j = 1
        while j < len(nested_block) - 1:
            if nested_block[j].isspace() or nested_block[j] == ",":
                j += 1
                continue

            if nested_block[j] != '"':
                j += 1
                continue

            key_literal, key_end = read_string_literal(nested_block, j)
            k = key_end
            while k < len(nested_block) and nested_block[k].isspace():
                k += 1
            if k >= len(nested_block) or nested_block[k] != ":":
                j = key_end
                continue

            k += 1
            while k < len(nested_block) and nested_block[k].isspace():
                k += 1
            if not nested_block.startswith('"""', k) and nested_block[k] != '"':
                raise ValueError(f"Missing string value for key in {language_code}")

            value_literal, value_end = read_string_literal(nested_block, k)
            entries.append((decode_literal(key_literal), decode_literal(value_literal)))
            j = value_end

        languages.append((language_code, entries))
        i = nested_end

    return languages


def kotlin_string_literal(value: str) -> str:
    escaped = (
        value.replace("\\", "\\\\")
        .replace('"', '\\"')
        .replace("$", "\\$")
        .replace("\n", "\\n")
    )
    return f'"{escaped}"'


def render_kotlin(languages: list[tuple[str, list[tuple[str, str]]]]) -> str:
    lines = [
        "package org.entner.HitzeV.ui.copy",
        "",
        "import org.entner.HitzeV.model.ResolvedLanguage",
        "",
        "// Generated by scripts/generate_android_copybook_catalog.py. Do not edit manually.",
        "internal object CopybookTranslationCatalog {",
        "    fun translation(language: ResolvedLanguage, english: String): String? = translations[language]?.get(english)",
        "",
        "    private val translations: Map<ResolvedLanguage, Map<String, String>> = mapOf(",
    ]

    for index, (language_code, entries) in enumerate(languages):
        lines.append(f"        ResolvedLanguage.{language_code.upper()} to mapOf(")
        for key, value in entries:
            lines.append(f"            {kotlin_string_literal(key)} to {kotlin_string_literal(value)},")
        trailing = "," if index < len(languages) - 1 else ""
        lines.append(f"        ){trailing}")
    lines.extend(
        [
            "    )",
            "}",
        ]
    )
    return "\n".join(lines) + "\n"


def main() -> int:
    if len(sys.argv) != 3:
        print("usage: generate_android_copybook_catalog.py <swift_catalog> <kotlin_output>", file=sys.stderr)
        return 1

    swift_catalog = pathlib.Path(sys.argv[1])
    kotlin_output = pathlib.Path(sys.argv[2])
    languages = parse_translations(swift_catalog.read_text())
    kotlin_output.parent.mkdir(parents=True, exist_ok=True)
    kotlin_output.write_text(render_kotlin(languages))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
