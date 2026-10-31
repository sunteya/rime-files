#!/usr/bin/env python3
"""Generate KeyTao two-character and phrase-combiner dictionaries from pinyin."""

from __future__ import annotations

import argparse
import json
import logging
import re
import unicodedata
from collections import defaultdict
from itertools import product
from pathlib import Path
from time import perf_counter

PINYIN_DICTIONARIES = [
    "repo/rime-wanxiang-data/dicts/diming.dict.yaml",
    "repo/rime-wanxiang-data/dicts/wuzhong.dict.yaml",
    "repo/rime-wanxiang-data/dicts/huaxue.dict.yaml",
    "repo/rime-wanxiang-data/dicts/yaopin.dict.yaml",
    "repo/rime-wanxiang-data/dicts/yixue.dict.yaml",
    "repo/rime-wanxiang-data/dicts/mingren.dict.yaml",
    "repo/rime-wanxiang-data/dicts/yiren.dict.yaml",
    "repo/rime-wanxiang-data/dicts/jichu.dict.yaml",
    "data/sogou/sogou.games.dict.yaml",
]
KAIKKI_DICTIONARY = "data/kaikki/zh.jsonl"
COMPOSITION_CONNECTORS = {"的", "地", "得", "或"}
COMPOSITION_SUFFIXES = {"的", "地", "得", "吧"}

ENTRY_RE = re.compile(r"^([^#\t]+)\t([^\t\s]+)(?:\t([^\t\s]+))?")
IMPORT_RE = re.compile(r"^\s*-\s+([^\s#]+)\s*(?:#.*)?$")
SINGLE_CODE_RE = re.compile(r"^[bcdefghjklmnpqrstwxyz]{2}([aiouv])[aiouv]*$")
CJK_RE = re.compile(r"[\u3400-\u4dbf\u4e00-\u9fff\uf900-\ufaff]")
# KeyTao sound-key map: https://pingshunhuangalex.gitbook.io/rime-xkjd/learn-xkjd/layouts
INITIAL_KEYS = {
    "b": "b",
    "p": "p",
    "m": "m",
    "f": "f",
    "d": "d",
    "t": "t",
    "n": "n",
    "l": "l",
    "g": "g",
    "k": "k",
    "h": "h",
    "j": "j",
    "q": "q",
    "x": "x",
    "r": "r",
    "z": "z",
    "c": "c",
    "s": "s",
    "w": "w",
    "y": "y",
    "sh": "e",
}
FINAL_KEYS = {
    "a": {"s"},
    "ai": {"h"},
    "an": {"f"},
    "ang": {"p"},
    "ao": {"z"},
    "e": {"e"},
    "ei": {"w"},
    "en": {"n"},
    "eng": {"r"},
    "er": {"j"},
    "i": {"k"},
    "ia": {"s"},
    "ian": {"m"},
    "iang": {"x"},
    "iao": {"c"},
    "ie": {"d"},
    "in": {"b"},
    "ing": {"g"},
    "iong": {"y"},
    "iu": {"q"},
    "o": {"l"},
    "ong": {"y"},
    "ou": {"d"},
    "u": {"j"},
    "ua": {"q"},
    "uai": {"g"},
    "uan": {"t"},
    "uang": {"x", "m"},
    "ui": {"b"},
    "un": {"w"},
    "uo": {"l"},
    "ü": {"l"},
    "üe": {"h"},
    "üan": {"t"},
    "ün": {"w"},
}
Y_FINALS = {
    "ya": "a",
    "ye": "e",
    "yao": "ao",
    "you": "ou",
    "yan": "an",
    "yin": "in",
    "yang": "ang",
    "ying": "ing",
    "yong": "ong",
    "yi": "i",
    "yu": "ü",
    "yue": "üe",
    "yuan": "üan",
    "yun": "ün",
}
W_FINALS = {
    "wa": "a",
    "wo": "o",
    "wai": "ai",
    "wei": "ei",
    "wan": "an",
    "wang": "ang",
    "wen": "en",
    "weng": "eng",
    "wu": "u",
}
ZERO_INITIAL_FINALS = {
    "a", "ai", "an", "ang", "ao", "e", "ei", "en", "eng", "er", "o", "ou"
}
CH_OUTER_FINALS = {"ai", "an", "ang", "en", "eng", "u", "un"}
CH_INNER_FINALS = {"a", "i", "ong", "ou", "ua", "uai", "uan", "uang", "ui", "uo"}
ZH_OUTER_FINALS = {"an", "ang", "ei", "en", "eng", "u", "un"}
ZH_INNER_FINALS = {"a", "i", "ong", "ou", "ua", "uai", "uan", "uang", "ui", "uo"}
# ch/zh use two possible initial keys for selected finals (飞键).


def dictionary_path(root: Path, name: str) -> Path:
    path = root / name
    if path.suffix == ".yaml":
        return path
    if path.name.endswith(".dict"):
        return path.with_suffix(".dict.yaml")
    return root / f"{name}.dict.yaml"


def dictionary_weight(columns: list[str]) -> str:
    if len(columns) < 3 or not columns[2].strip():
        return "100"
    return columns[2].strip()


def keep_higher_weight(weights: dict[str, str], key: str, weight: str) -> None:
    current = weights.get(key)
    numeric_weight = float(weight.removesuffix("N"))
    if current is None or numeric_weight > float(current.removesuffix("N")):
        weights[key] = weight


def dictionary_imports(lines: list[str]) -> list[str]:
    imports: list[str] = []
    reading_imports = False
    for line in lines:
        stripped = line.strip()
        if stripped == "...":
            break
        if not stripped or stripped.startswith("#"):
            continue
        if reading_imports:
            match = IMPORT_RE.match(line)
            if match:
                imports.append(match.group(1))
                continue
            reading_imports = False
        if stripped == "import_tables:":
            reading_imports = True
    return imports


def ensure_extra_import(path: Path) -> None:
    content = path.read_text(encoding="utf-8")
    lines = content.splitlines(keepends=True)
    start = next(index for index, line in enumerate(lines) if line.strip() == "import_tables:") + 1
    end = start
    imports: list[str] = []
    while end < len(lines):
        line = lines[end]
        stripped = line.strip()
        match = IMPORT_RE.match(line)
        if stripped and not stripped.startswith("#") and not match:
            break
        if not match or match.group(1) != "keytao.extra":
            imports.append(line)
        end += 1
    imports.append("  - keytao.extra\n")
    updated = "".join(lines[:start] + imports + lines[end:])
    if updated != content:
        path.write_text(updated, encoding="utf-8")
        logging.info("[主词典] 已将 keytao.extra 放到 import_tables 最后一项：%s", path)


def load_single_shapes(path: Path) -> dict[str, set[str]]:
    shapes: dict[str, set[str]] = defaultdict(set)
    for line in path.read_text(encoding="utf-8").splitlines():
        entry_match = ENTRY_RE.match(line)
        if not entry_match:
            continue
        text, code, _ = entry_match.groups()
        if len(text) != 1 or not CJK_RE.fullmatch(text):
            continue
        code_match = SINGLE_CODE_RE.fullmatch(code)
        if code_match:
            shapes[text].add(code_match.group(1))
    logging.info("[单字词典] 加载 %d 个字的形码首码", len(shapes))
    return shapes


def load_existing_words(
    path: Path,
    words: set[str],
    visited: set[Path],
    generated_paths: set[Path],
) -> None:
    path = path.resolve()
    if path in visited or path in generated_paths:
        return
    visited.add(path)

    logging.info("[已有词典] 读取词语：%s", path)
    lines = path.read_text(encoding="utf-8").splitlines()
    for raw_line in lines:
        entry_match = ENTRY_RE.match(raw_line)
        if not entry_match:
            continue
        text = entry_match.group(1)
        if chinese_length(text) >= 2 and len(text) == chinese_length(text):
            words.add(text)
    for imported in dictionary_imports(lines):
        load_existing_words(
            dictionary_path(path.parent, imported),
            words,
            visited,
            generated_paths,
        )


def chinese_length(text: str) -> int:
    return len(CJK_RE.findall(text))


def load_kaikki_words(path: Path) -> set[str]:
    words: set[str] = set()
    for line_number, raw_line in enumerate(path.read_text(encoding="utf-8").splitlines(), start=1):
        try:
            record = json.loads(raw_line)
        except json.JSONDecodeError as error:
            raise ValueError(f"{path} 第 {line_number} 行不是有效 JSON") from error
        word = record.get("word")
        if isinstance(word, str) and len(word) == chinese_length(word) and chinese_length(word) >= 2:
            words.add(word)
    logging.info("[Kaikki] 加载完成：%d 个词语", len(words))
    return words


def normalize_pinyin(syllable: str) -> str:
    decomposed = unicodedata.normalize("NFD", syllable.lower().replace("v", "ü"))
    without_tone = "".join(
        character
        for character in decomposed
        if not unicodedata.combining(character) or character == "\u0308"
    )
    return unicodedata.normalize("NFC", without_tone)


def initial_keys(initial: str, final: str) -> set[str]:
    if initial == "ch":
        keys = set()
        if final in CH_OUTER_FINALS or final in {"ao", "e"}:
            keys.add("j")
        if final in CH_INNER_FINALS or final in {"ao", "e"}:
            keys.add("w")
        return keys
    if initial == "zh":
        keys = set()
        if final in ZH_OUTER_FINALS or final in {"ai", "ao", "e"}:
            keys.add("q")
        if final in ZH_INNER_FINALS or final in {"ai", "ao", "e"}:
            keys.add("f")
        return keys
    key = INITIAL_KEYS.get(initial)
    return {key} if key else set()


def pinyin_syllable_codes(syllable: str) -> set[str]:
    syllable = normalize_pinyin(syllable)
    if syllable in Y_FINALS:
        initial, final = "y", Y_FINALS[syllable]
    elif syllable in W_FINALS:
        initial, final = "w", W_FINALS[syllable]
    elif syllable in ZERO_INITIAL_FINALS:
        initial, final = "x", syllable
    else:
        initial = next(
            (
                candidate
                for candidate in ("zh", "ch", "sh", *INITIAL_KEYS)
                if syllable.startswith(candidate)
            ),
            "",
        )
        if not initial:
            return set()
        final = syllable[len(initial):]
        if initial in {"j", "q", "x"}:
            final = {"u": "ü", "ue": "üe", "uan": "üan", "un": "ün"}.get(final, final)

    final_keys = FINAL_KEYS.get(final)
    if not final_keys:
        return set()
    return {
        initial_key + final_key
        for initial_key in initial_keys(initial, final)
        for final_key in final_keys
    }


def pinyin_word_codes(text: str, pinyin: str) -> set[str]:
    syllables = pinyin.split()
    if len(text) != chinese_length(text) or len(syllables) != len(text):
        return set()
    syllable_codes = [pinyin_syllable_codes(syllable) for syllable in syllables]
    if any(not codes for codes in syllable_codes):
        return set()
    return {"".join(parts) for parts in product(*syllable_codes)}


def load_pinyin_words(
    path: Path,
    words: dict[str, dict[str, str]],
    visited: set[Path],
    generated_paths: set[Path],
) -> None:
    path = path.resolve()
    if path in visited or path in generated_paths:
        return
    visited.add(path)

    logging.info("[拼音词典] 读取拼音：%s", path)
    previous_count = len(words)
    lines = path.read_text(encoding="utf-8").splitlines()
    for line_number, raw_line in enumerate(lines, start=1):
        columns = raw_line.split("\t")
        if len(columns) < 2 or not columns[0] or columns[0].startswith("#"):
            continue
        text, pinyin = columns[:2]
        if chinese_length(text) < 2:
            continue
        codes = pinyin_word_codes(text, pinyin)
        weight = dictionary_weight(columns)
        try:
            float(weight.removesuffix("N"))
        except ValueError:
            logging.warning("[拼音词典] 跳过非法权重：%s:%d，词语=%s，权重=%r", path, line_number, text, weight)
            continue
        for code in codes:
            keep_higher_weight(words[text], code, weight)
    logging.info("[拼音词典] 读取完成：%s，新增 %d 个词语", path.name, len(words) - previous_count)
    for imported in dictionary_imports(lines):
        load_pinyin_words(
            dictionary_path(path.parent, imported),
            words,
            visited,
            generated_paths,
        )


def generate_pinyin_aliases(
    words: dict[str, dict[str, str]],
    max_code_length: int,
    min_code_length: int,
    kaikki_words: set[str],
    keytao_words: set[str],
) -> dict[str, dict[str, str]]:
    aliases: dict[str, dict[str, str]] = defaultdict(dict)
    accepted_words: set[str] = set()
    composed_count = 0

    def add_aliases(word: str, codes: dict[str, str]) -> None:
        for code, weight in codes.items():
            if len(code) < min_code_length or (max_code_length and len(code) > max_code_length):
                continue
            aliases[code][word] = weight
            accepted_words.add(word)

    # Kaikki 词语必须先进入本轮长词集合，供后续过滤未知复合词使用。
    for word, codes in words.items():
        if chinese_length(word) < 3:
            continue
        if word in kaikki_words:
            add_aliases(word, codes)

    recognized_words = keytao_words | {
        word for word in words if chinese_length(word) >= 3 and word in kaikki_words
    }
    unknown_words = sorted(
        (
            (word, codes)
            for word, codes in words.items()
            if chinese_length(word) >= 3 and word not in kaikki_words
        ),
        key=lambda entry: chinese_length(entry[0]),
    )
    for word, codes in unknown_words:
        if is_composed_of_keytao_words(word, recognized_words):
            composed_count += 1
            continue
        add_aliases(word, codes)
        if word in accepted_words:
            recognized_words.add(word)
    logging.info(
        "[拼音词典] 生成 %d 个词语、%d 条编码",
        len(accepted_words),
        sum(map(len, aliases.values())),
    )
    logging.info(
        "[长词过滤] Kaikki 有效词 %d 个、可由已有词组成 %d 个",
        sum(1 for word in accepted_words if word in kaikki_words),
        composed_count,
    )
    return aliases


def is_composed_of_keytao_words(text: str, keytao_words: set[str]) -> bool:
    """Return whether text can be split into existing words and connectors.

    的、地、得 may connect words or follow the final word, but are not words
    themselves.
    """
    if text in keytao_words:
        return False

    reachable: set[tuple[int, int, bool]] = {(0, 0, False)}
    for index in range(len(text) + 1):
        for position, part_count, after_connector in tuple(reachable):
            if position != index:
                continue
            if position == len(text):
                if part_count >= 1 and (not after_connector or text[-1] in COMPOSITION_SUFFIXES):
                    return True
                continue
            if (
                part_count
                and not after_connector
                and text[position] in COMPOSITION_SUFFIXES
                and all(character in COMPOSITION_SUFFIXES for character in text[position:])
            ):
                return True
            if part_count and not after_connector and text[position] in COMPOSITION_CONNECTORS:
                reachable.add((position + 1, part_count, True))
            for end in range(position + 2, len(text) + 1):
                if text[position:end] in keytao_words:
                    reachable.add((end, min(part_count + 1, 2), False))
    return False


def generate_two_character_aliases(
    words: dict[str, dict[str, str]],
    shapes: dict[str, set[str]],
    existing_words: set[str],
) -> dict[str, dict[str, str]]:
    aliases: dict[str, dict[str, str]] = defaultdict(dict)
    existing_count = 0
    missing_shape_count = 0
    accepted_count = 0
    for word, codes in words.items():
        if len(word) != 2:
            continue
        if word in existing_words:
            existing_count += 1
            continue
        character_shapes = [shapes.get(character, set()) for character in word]
        if any(not variants for variants in character_shapes):
            missing_shape_count += 1
            continue
        suffixes = {"".join(parts) for parts in product(*character_shapes)}
        for code, weight in codes.items():
            for suffix in suffixes:
                aliases[code + suffix][word] = weight
        accepted_count += 1

    logging.info(
        "[二字词] 生成 %d 个词语、%d 条六码；跳过已有词 %d 个、缺少形码 %d 个",
        accepted_count,
        sum(map(len, aliases.values())),
        existing_count,
        missing_shape_count,
    )
    return aliases


def write_dictionary(
    path: Path,
    name: str,
    aliases: dict[str, dict[str, str]],
    imports: list[str],
) -> None:
    lines = [
        "# Rime dictionary",
        "# Generated by scripts/generate_keytao_dicts.py",
        "---",
        f"name: {name}",
        'version: "1.0"',
        "sort: by_weight",
    ]
    if imports:
        lines.append("import_tables:")
        lines.extend(f"  - {imported}" for imported in imports)
    lines.extend([
        "columns:",
        "  - text",
        "  - code",
        "  - weight",
        "...",
        "",
    ])

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
    parser.add_argument(
        "--output", default="phrase_combiner.dict.yaml", help="Phrase-combiner output path."
    )
    parser.add_argument(
        "--max-code-length",
        type=int,
        default=0,
        help="Optional phrase-combiner code length limit; 0 means unlimited.",
    )
    parser.add_argument(
        "--min-code-length", type=int, default=2, help="Minimum phrase-combiner code length."
    )
    args = parser.parse_args()

    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s %(levelname)s %(message)s",
        datefmt="%H:%M:%S",
    )
    started_at = perf_counter()
    root = args.root.resolve()
    base_source = root / "keytao.extended.dict.yaml"
    single_source = root / "repo/KeyTao/rime/keytao.single.dict.yaml"
    output = (root / args.output).resolve()
    ext_output = root / "keytao.extra.dict.yaml"
    kaikki_source = root / KAIKKI_DICTIONARY
    if output == ext_output:
        parser.error("phrase-combiner output must not be keytao.extra.dict.yaml")
    generated_paths = {output, ext_output}
    pinyin_sources = [dictionary_path(root, name) for name in PINYIN_DICTIONARIES]
    for source in [base_source, single_source, kaikki_source, *pinyin_sources]:
        if not source.is_file():
            parser.error(f"source dictionary not found: {source}")

    logging.info("========== KeyTao：加载单字形码及已有词语 ==========")
    shapes = load_single_shapes(single_source)
    existing_words: set[str] = set()
    load_existing_words(base_source, existing_words, set(), generated_paths)
    logging.info("[已有词典] 加载完成：%d 个词语", len(existing_words))

    kaikki_words = load_kaikki_words(kaikki_source)

    pinyin_words: dict[str, dict[str, str]] = defaultdict(dict)
    pinyin_visited: set[Path] = set()
    logging.info("========== 拼音词典：按拼音生成编码 ==========")
    for source in pinyin_sources:
        load_pinyin_words(source, pinyin_words, pinyin_visited, generated_paths)
    two_character_aliases = generate_two_character_aliases(
        pinyin_words,
        shapes,
        {word for word in existing_words if len(word) == 2},
    )
    composition_words = existing_words | {
        text
        for entries in two_character_aliases.values()
        for text in entries
    }
    pinyin_aliases = generate_pinyin_aliases(
        pinyin_words,
        args.max_code_length,
        args.min_code_length,
        kaikki_words,
        composition_words,
    )

    logging.info("========== 写入词典 ==========")
    logging.info("输出路径：%s", output)
    write_dictionary(output, "phrase_combiner", pinyin_aliases, ["phrase_combiner.user"])
    logging.info("输出路径：%s", ext_output)
    write_dictionary(ext_output, "keytao.extra", two_character_aliases, [])
    ensure_extra_import(base_source)
    logging.info("========== 生成完成 ==========")
    logging.info(
        "生成完成：%d 条词条，总耗时 %.2f 秒",
        sum(map(len, pinyin_aliases.values())) + sum(map(len, two_character_aliases.values())),
        perf_counter() - started_at,
    )


if __name__ == "__main__":
    main()
