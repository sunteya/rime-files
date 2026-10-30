#!/usr/bin/env python3
"""Generate the offline dictionary used by the KeyTao phrase combiner."""

from __future__ import annotations

import argparse
import logging
import re
from collections import defaultdict
from pathlib import Path
from time import perf_counter

EXTRA_DICTIONARIES = [
    "keytao.phrase.dict.yaml",
    "cn_dicts/ext.dict.yaml",
    "cn_dicts/tencent.dict.yaml",
]

ENTRY_RE = re.compile(r"^([^#\t]+)\t([^\t\s]+)(?:\t([^\t\s]+))?")
IMPORT_RE = re.compile(r"^\s*-\s+([^\s#]+)\s*$")
CODE_RE = re.compile(r"^[a-z]+$")
CJK_RE = re.compile(r"[\u3400-\u4dbf\u4e00-\u9fff\uf900-\ufaff]")


def dictionary_path(root: Path, name: str) -> Path:
    path = root / name
    if path.suffix == ".yaml":
        return path
    if path.name.endswith(".dict"):
        return path.with_suffix(".dict.yaml")
    return root / f"{name}.dict.yaml"


def load_base_codes(
    path: Path,
    codes: dict[str, set[str]],
    visited: set[Path],
    generated_name: str,
) -> None:
    path = path.resolve()
    if path in visited or path.name == generated_name:
        return
    if not path.is_file():
        return
    visited.add(path)

    logging.info("[基础词典] 读取编码：%s", path)
    previous_count = len(codes)
    imports: list[str] = []
    for raw_line in path.read_text(encoding="utf-8").splitlines():
        import_match = IMPORT_RE.match(raw_line)
        if import_match:
            imports.append(import_match.group(1))

        entry_match = ENTRY_RE.match(raw_line)
        if not entry_match:
            continue

        text, code, _ = entry_match.groups()
        if len(text) not in (1, 2):
            continue
        required_length = len(text) * 2
        if CODE_RE.fullmatch(code) and len(code) >= required_length:
            codes[text].add(code[:required_length])

    logging.info("[基础词典] 读取完成：%s，新增 %d 个基础词条", path.name, len(codes) - previous_count)
    root = path.parent
    for imported in imports:
        load_base_codes(
            dictionary_path(root, imported),
            codes,
            visited,
            generated_name,
        )


def load_extra_words(
    path: Path,
    words: set[str],
    visited: set[Path],
    generated_name: str,
) -> None:
    path = path.resolve()
    if path in visited or path.name == generated_name:
        return
    if not path.is_file():
        return
    visited.add(path)

    logging.info("[扩展词典] 读取文字：%s", path)
    previous_count = len(words)
    imports: list[str] = []
    for raw_line in path.read_text(encoding="utf-8").splitlines():
        import_match = IMPORT_RE.match(raw_line)
        if import_match:
            imports.append(import_match.group(1))

        text, separator, _ = raw_line.partition("\t")
        if separator and text and not text.startswith("#"):
            words.add(text)
    logging.info("[扩展词典] 读取完成：%s，新增 %d 个词语", path.name, len(words) - previous_count)
    for imported in imports:
        load_extra_words(
            dictionary_path(path.parent, imported),
            words,
            visited,
            generated_name,
        )


def chinese_length(text: str) -> int:
    return len(CJK_RE.findall(text))


def generate_aliases(
    words: set[str],
    codes: dict[str, set[str]],
    max_code_length: int,
    min_code_length: int,
) -> dict[str, dict[str, int]]:
    aliases: dict[str, dict[str, int]] = defaultdict(dict)
    entry_count = 0
    logging.info("========== 开始组词 ==========")
    logging.info("待处理词语：%d 个", len(words))

    for processed, word in enumerate(words):
        if processed and processed % 10000 == 0:
            logging.info("组词进度：%d/%d，已生成 %d 条词条", processed, len(words), entry_count)
        characters = list(word)
        if chinese_length(word) < 3:
            continue

        length = len(characters)
        segmentations: dict[int, tuple[int, set[str]]] = {length: (0, {""})}
        for position in range(length - 1, -1, -1):
            best_count = length + 1
            best_codes: set[str] = set()
            for end in range(position + 1, min(position + 2, length) + 1):
                segment = "".join(characters[position:end])
                variants = {
                    code for code in codes.get(segment, set()) if len(code) >= min_code_length
                }
                if not variants:
                    continue
                suffix_count, suffix_codes = segmentations[end]
                count = suffix_count + 1
                if not suffix_codes or count > best_count:
                    continue
                if count < best_count:
                    best_count = count
                    best_codes.clear()
                best_codes.update(code + suffix for code in variants for suffix in suffix_codes)
            segmentations[position] = (best_count, best_codes)

        for code in segmentations[0][1]:
            if max_code_length == 0 or len(code) <= max_code_length:
                aliases[code][word] = 100
                entry_count += 1

    logging.info("组词完成：已处理 %d 个词语，生成 %d 条词条", len(words), entry_count)
    return aliases


def write_dictionary(path: Path, aliases: dict[str, dict[str, int]]) -> None:
    lines = [
        "# Rime dictionary",
        "# Generated by scripts/generate_phrase_combiner.py",
        "---",
        "name: phrase_combiner",
        'version: "1.0"',
        "sort: original",
        "import_tables:",
        "  - phrase_combiner.user",
        "columns:",
        "  - text",
        "  - code",
        "  - weight",
        "...",
        "",
    ]

    rows = [
        (text, code, weight)
        for code, entries in aliases.items()
        for text, weight in entries.items()
    ]
    rows.sort(key=lambda row: (row[0], row[1]))
    for text, code, weight in rows:
        lines.append(f"{text}\t{code}\t{weight}")

    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--root",
        type=Path,
        default=Path(__file__).resolve().parent.parent,
    )
    parser.add_argument("--output", default="phrase_combiner.dict.yaml")
    parser.add_argument(
        "--max-code-length",
        type=int,
        default=0,
        help="Optional output limit; 0 means unlimited.",
    )
    parser.add_argument("--min-code-length", type=int, default=2)
    args = parser.parse_args()

    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s %(levelname)s %(message)s",
        datefmt="%H:%M:%S",
    )
    started_at = perf_counter()
    root = args.root.resolve()
    base_source = root / "keytao.extended.dict.yaml"
    extra_sources = [root / name for name in EXTRA_DICTIONARIES]
    for source in [base_source, *extra_sources]:
        if not source.is_file():
            parser.error(f"source dictionary not found: {source}")

    codes: dict[str, set[str]] = defaultdict(set)
    generated_name = Path(args.output).name
    logging.info("========== 基础词典：加载编码 ==========")
    load_base_codes(base_source, codes, set(), generated_name)
    logging.info(
        "[基础词典] 加载完成：%d 个基础词条，%d 个基础编码",
        len(codes),
        sum(len(variants) for variants in codes.values()),
    )

    words: set[str] = set()
    visited: set[Path] = set()
    logging.info("========== 扩展词典：加载待生成词语 ==========")
    for source in extra_sources:
        load_extra_words(source, words, visited, generated_name)
    logging.info("[扩展词典] 加载完成：%d 个去重词语", len(words))

    aliases = generate_aliases(
        words,
        codes,
        args.max_code_length,
        args.min_code_length,
    )
    output = root / args.output
    logging.info("========== 写入词典 ==========")
    logging.info("输出路径：%s", output)
    write_dictionary(output, aliases)
    logging.info("========== 生成完成 ==========")
    logging.info(
        "生成完成：%d 条词条，总耗时 %.2f 秒",
        sum(len(entries) for entries in aliases.values()),
        perf_counter() - started_at,
    )


if __name__ == "__main__":
    main()
