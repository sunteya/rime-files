#!/usr/bin/env python3
"""Sync Chinese entries from the English and Chinese Wiktionary editions."""

from __future__ import annotations

import argparse
import gzip
import json
import re
import subprocess
import sys
import unicodedata
import zlib
from dataclasses import asdict, dataclass
from datetime import datetime, timezone
from http.client import HTTPException
from pathlib import Path
from time import monotonic
from typing import TypedDict
from urllib.error import HTTPError
from urllib.request import Request, urlopen

DEFAULT_DIRECTORY = Path(__file__).resolve().parents[1] / "data" / "kaikki"
CHUNK_SIZE = 1024 * 1024
TIMEOUT = 60
PROCESSING_VERSION = 6
GENERIC_PINYIN_TAGS = {"Mandarin", "Pinyin", "Erhua", "toneless-final-syllable-variant"}
PINYIN_ANNOTATION_RE = re.compile(r"\([^()]*\)|（[^（）]*）|[\[［【].*")
PINYIN_SEPARATOR_RE = re.compile(r"[,，、;；/／]")
PINYIN_TEXT_RE = re.compile(r"[A-Za-z\u0300-\u036f '’ʼ·-]+")
POS_TITLES = {
    "adj": "形容词", "adv": "副词", "character": "汉字", "circumpos": "环置词",
    "classifier": "量词", "conj": "连词", "det": "限定词", "infix": "中缀",
    "interfix": "连接成分", "intj": "叹词", "name": "专有名词", "noun": "名词",
    "num": "数词", "particle": "助词", "phrase": "短语", "postp": "后置词",
    "prefix": "前缀", "prep": "介词", "pron": "代词", "proverb": "谚语",
    "punct": "标点符号", "romanization": "罗马字", "suffix": "后缀", "symbol": "符号",
    "verb": "动词",
}


@dataclass(frozen=True)
class Edition:
    code: str
    url: str
    filename: str
    extracted_filename: str


EN_EDITION = Edition("en", "https://kaikki.org/dictionary/raw-wiktextract-data.jsonl.gz", "en-extract.jsonl.gz", "en-zh-extract.jsonl")
ZH_EDITION = Edition("zh", "https://kaikki.org/dictionary/downloads/zh/zh-extract.jsonl.gz", "zh-extract.jsonl.gz", "zh-extract.jsonl")
EDITIONS = (EN_EDITION, ZH_EDITION)


class SourceRecord(TypedDict):
    url: str
    etag: str | None
    last_modified: str | None
    size: int


class Extraction(TypedDict):
    records: int
    zh_records: int


class DatasetMetadata(TypedDict, total=False):
    source: SourceRecord
    file: str
    downloaded_at: str
    extraction: Extraction


class ProcessingMetadata(TypedDict, total=False):
    format_version: int
    sources: dict[str, SourceRecord]
    lang_code: str
    records: int
    zh_records: int
    words: int
    unresolved_redirects: dict[str, list[str]]
    processed_at: str


class Metadata(TypedDict, total=False):
    sources: dict[str, DatasetMetadata]
    processing: ProcessingMetadata


class Sound(TypedDict, total=False):
    tags: list[str]
    zh_pron: str


class DictionaryEntry(TypedDict, total=False):
    word: str
    lang_code: str
    pos: str
    pos_title: str
    sounds: list[Sound]
    redirects: list[str]


class Reading(TypedDict):
    pos: str
    pos_title: str
    pinyin: list[str]


@dataclass(frozen=True)
class Source:
    url: str
    etag: str | None
    last_modified: str | None
    size: int

    def same_version(self, other: Source) -> bool:
        if self.url != other.url or self.size != other.size:
            return False
        if self.etag and other.etag:
            return self.etag == other.etag
        return bool(self.last_modified and self.last_modified == other.last_modified)

    def range_validator(self) -> str | None:
        if self.etag and not self.etag.startswith("W/"):
            return self.etag
        return self.last_modified


def read_source(path: Path) -> Source | None:
    if not path.exists():
        return None
    return Source(**json.loads(path.read_text(encoding="utf-8"))["source"])


def load_metadata(directory: Path) -> Metadata:
    path = directory / "metadata.json"
    if not path.exists():
        return {"sources": {}}
    metadata = json.loads(path.read_text(encoding="utf-8"))
    if "source" in metadata:
        metadata["sources"] = {"zh": {key: metadata.pop(key) for key in ("source", "file", "downloaded_at")}}
    return metadata


def local_source(edition: Edition, directory: Path, metadata: Metadata) -> Source | None:
    saved = metadata["sources"].get(edition.code)
    if saved is None:
        return None
    source = Source(**saved["source"])
    archive = directory / "raw" / edition.filename
    if source.url != edition.url or not archive.exists() or archive.stat().st_size != source.size:
        return None
    return source


def write_json(path: Path, data: object) -> None:
    temporary = path.with_name(path.name + ".tmp")
    temporary.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    temporary.replace(path)


def inspect_source(edition: Edition, saved: Source | None) -> Source | None:
    headers = {"Accept-Encoding": "identity", "User-Agent": "rime-kaikki-downloader/1.0"}
    if saved is not None:
        if saved.etag:
            headers["If-None-Match"] = saved.etag
        elif saved.last_modified:
            headers["If-Modified-Since"] = saved.last_modified
    try:
        with urlopen(Request(edition.url, headers=headers, method="HEAD"), timeout=TIMEOUT) as response:
            length = response.headers.get("Content-Length")
            if length is None:
                raise RuntimeError("服务器没有提供 Content-Length，无法安全校验下载长度")
            return Source(edition.url, response.headers.get("ETag"), response.headers.get("Last-Modified"), int(length))
    except HTTPError as error:
        if error.code != 304 or saved is None:
            raise
        error.close()
        return None


def transfer(source: Source, partial: Path, partial_metadata: Path) -> None:
    previous = read_source(partial_metadata)
    offset = 0
    validator = source.range_validator()
    if partial.exists() and previous is not None and previous.same_version(source) and validator:
        offset = partial.stat().st_size
        if offset > source.size:
            offset = 0
        elif offset == source.size:
            return

    headers = {"Accept-Encoding": "identity", "User-Agent": "rime-kaikki-downloader/1.0"}
    if offset:
        headers.update({"Range": f"bytes={offset}-", "If-Range": validator})

    with urlopen(Request(source.url, headers=headers), timeout=TIMEOUT) as response:
        if source.etag:
            unchanged = response.headers.get("ETag") == source.etag
        elif source.last_modified:
            unchanged = response.headers.get("Last-Modified") == source.last_modified
        else:
            unchanged = True
        if not unchanged:
            raise RuntimeError("检查后源文件又发生了变化，请重新运行")

        if response.status == 206:
            match = re.fullmatch(r"bytes (\d+)-(\d+)/(\d+)", response.headers.get("Content-Range", ""))
            if not offset or match is None or tuple(map(int, match.groups())) != (offset, source.size - 1, source.size):
                raise RuntimeError("服务器返回的续传范围不符合预期，未修改已有下载")
        elif response.status == 200:
            offset = 0
        else:
            raise RuntimeError(f"不支持的下载响应：HTTP {response.status}")

        length = response.headers.get("Content-Length")
        if length is not None and int(length) != source.size - offset:
            raise RuntimeError("服务器返回的文件长度发生变化，请重新运行")

        with partial.open("ab" if offset else "wb") as output:
            write_json(partial_metadata, {"source": asdict(source)})
            downloaded = offset
            last_report = 0.0
            try:
                while chunk := response.read(CHUNK_SIZE):
                    output.write(chunk)
                    downloaded += len(chunk)
                    now = monotonic()
                    if now - last_report >= 1:
                        print(f"\r下载进度：{downloaded / CHUNK_SIZE:.1f} / {source.size / CHUNK_SIZE:.1f} MiB", end="", file=sys.stderr, flush=True)
                        last_report = now
            finally:
                print(file=sys.stderr)

    if partial.stat().st_size != source.size:
        raise RuntimeError("下载尚未完成，已保留断点；重新运行即可续传")


def download(edition: Edition, source: Source, directory: Path) -> None:
    raw = directory / "raw"
    raw.mkdir(parents=True, exist_ok=True)
    destination = raw / edition.filename
    partial = raw / (edition.filename + ".part")
    partial_metadata = raw / (edition.filename + ".part.json")
    transfer(source, partial, partial_metadata)

    print("正在校验 gzip 完整性……")
    try:
        with gzip.open(partial, "rb") as data:
            while data.read(CHUNK_SIZE):
                pass
    except (gzip.BadGzipFile, EOFError, zlib.error) as error:
        partial.unlink()
        partial_metadata.unlink(missing_ok=True)
        raise RuntimeError("gzip 校验失败，已删除损坏的临时文件；请重新下载") from error

    partial.replace(destination)
    metadata = load_metadata(directory)
    metadata["sources"][edition.code] = {
        "source": asdict(source),
        "file": f"raw/{edition.filename}",
        "downloaded_at": datetime.now(timezone.utc).isoformat(),
    }
    metadata.pop("processing", None)
    write_json(directory / "metadata.json", metadata)
    partial_metadata.unlink(missing_ok=True)
    print(f"下载完成：{destination}")


def extract_pinyin(sounds: list[Sound]) -> list[str]:
    result: list[str] = []
    for sound in sounds:
        tags = set(sound.get("tags", []))
        if not {"Mandarin", "Pinyin"} <= tags or "phonetic" in tags:
            continue
        if "Standard-Chinese" not in tags and not tags <= GENERIC_PINYIN_TAGS:
            continue
        text = PINYIN_ANNOTATION_RE.sub("", sound["zh_pron"])
        for value in PINYIN_SEPARATOR_RE.split(text):
            pinyin = unicodedata.normalize("NFC", " ".join(value.split()))
            if PINYIN_TEXT_RE.fullmatch(unicodedata.normalize("NFD", pinyin)) and pinyin not in result:
                result.append(pinyin)
    return result


def merge_readings(target: dict[str, Reading], readings: dict[str, Reading]) -> None:
    for pos, reading in readings.items():
        if pos not in target:
            target[pos] = {**reading, "pinyin": list(reading["pinyin"])}
        else:
            if not target[pos]["pos_title"]:
                target[pos]["pos_title"] = reading["pos_title"]
            for pinyin in reading["pinyin"]:
                if pinyin not in target[pos]["pinyin"]:
                    target[pos]["pinyin"].append(pinyin)


def resolve_redirects(words: dict[str, dict[str, Reading]], redirects: dict[str, list[str]]) -> list[str]:
    resolved: dict[str, dict[str, Reading]] = {}
    for word, targets in redirects.items():
        readings: dict[str, Reading] = {}
        pending = list(reversed(targets))
        visited = {word}
        while pending:
            target = pending.pop()
            if target in visited:
                continue
            visited.add(target)
            merge_readings(readings, words.get(target, {}))
            pending.extend(reversed(redirects.get(target, [])))
        resolved[word] = readings

    unresolved: list[str] = []
    for word, readings in resolved.items():
        target = words.setdefault(word, {})
        merge_readings(target, readings)
        if not target:
            unresolved.append(word)
    return unresolved


def simplify_words(words: dict[str, dict[str, Reading]]) -> dict[str, dict[str, Reading]]:
    if not words:
        return {}
    try:
        result = subprocess.run(
            ["opencc", "-c", "t2s.json"],
            input="\n".join(words) + "\n",
            capture_output=True,
            encoding="utf-8",
            check=True,
        )
    except FileNotFoundError as error:
        raise RuntimeError("繁简转换需要已安装的 opencc 命令，请确认其位于 PATH 中") from error
    except subprocess.CalledProcessError as error:
        raise RuntimeError(f"OpenCC 繁简转换失败：{error.stderr.strip()}") from error

    converted = result.stdout.splitlines()
    if len(converted) != len(words):
        raise RuntimeError("OpenCC 输出行数与输入词数不一致，未更新加工结果")
    simplified: dict[str, dict[str, Reading]] = {}
    for readings, word in zip(words.values(), converted):
        target = simplified.setdefault(word, {})
        merge_readings(target, readings)
    return simplified


def extract(edition: Edition, directory: Path, metadata: Metadata) -> Path:
    archive = directory / "raw" / edition.filename
    extracted = directory / "raw" / edition.extracted_filename
    saved = metadata["sources"][edition.code]
    if saved.get("extraction") is not None and extracted.exists():
        return extracted
    temporary = extracted.with_name(extracted.name + ".tmp")
    records = 0
    zh_records = 0
    print(f"[{edition.code}] 正在解压并提取汉语数据……")
    try:
        with gzip.open(archive, "rb") as data, temporary.open("wb") as output:
            for records, line in enumerate(data, 1):
                try:
                    entry: DictionaryEntry = json.loads(line)
                except json.JSONDecodeError as error:
                    raise ValueError(f"{archive} 第 {records} 行不是有效 JSON") from error
                chinese = entry.get("lang_code") == "zh"
                zh_records += chinese
                if edition.code == "zh" or chinese:
                    output.write(line)
        temporary.replace(extracted)
        saved["extraction"] = {"records": records, "zh_records": zh_records}
        write_json(directory / "metadata.json", metadata)
    except (gzip.BadGzipFile, EOFError, zlib.error) as error:
        raise RuntimeError(f"本地 gzip 文件损坏，未更新提取结果：{archive}") from error
    finally:
        temporary.unlink(missing_ok=True)
    return extracted


def read_dictionary(path: Path) -> tuple[dict[str, dict[str, Reading]], dict[str, list[str]]]:
    words: dict[str, dict[str, Reading]] = {}
    redirects: dict[str, list[str]] = {}
    with path.open(encoding="utf-8") as data:
        for number, line in enumerate(data, 1):
            try:
                entry: DictionaryEntry = json.loads(line)
            except json.JSONDecodeError as error:
                raise ValueError(f"{path} 第 {number} 行不是有效 JSON") from error
            if entry.get("lang_code") != "zh":
                continue
            word = entry["word"]
            pos = entry.get("pos", "unknown")
            if pos == "soft-redirect":
                targets = redirects.setdefault(word, [])
                for target in entry.get("redirects", []):
                    if target not in targets:
                        targets.append(target)
                continue
            reading = words.setdefault(word, {}).setdefault(pos, {
                "pos": pos,
                "pos_title": entry.get("pos_title", POS_TITLES.get(pos, "")),
                "pinyin": [],
            })
            for pinyin in extract_pinyin(entry.get("sounds", [])):
                if pinyin not in reading["pinyin"]:
                    reading["pinyin"].append(pinyin)
    return words, redirects


def process(directory: Path) -> None:
    metadata = load_metadata(directory)
    snapshot: dict[str, SourceRecord] = {}
    for edition in EDITIONS:
        source = local_source(edition, directory, metadata)
        if source is None:
            raise RuntimeError(f"[{edition.code}] 本地词典不存在或不完整，请先使用 --update 下载或续传")
        snapshot[edition.code] = asdict(source)

    chinese = directory / "zh.jsonl"
    previous = metadata.get("processing", {})
    if previous.get("format_version") == PROCESSING_VERSION and previous.get("sources") == snapshot and chinese.exists() and all((directory / "raw" / edition.extracted_filename).exists() for edition in EDITIONS):
        print("双源汉语词典已合并，无需重复加工。")
        return

    words: dict[str, dict[str, Reading]] = {}
    unresolved: dict[str, list[str]] = {}
    records = 0
    zh_records = 0
    for edition in EDITIONS:
        path = extract(edition, directory, metadata)
        print(f"[{edition.code}] 正在整理词性、拼音和重定向……")
        edition_words, redirects = read_dictionary(path)
        unresolved[edition.code] = resolve_redirects(edition_words, redirects)
        for word, readings in edition_words.items():
            merge_readings(words.setdefault(word, {}), readings)
        records += metadata["sources"][edition.code]["extraction"]["records"]
        zh_records += metadata["sources"][edition.code]["extraction"]["zh_records"]

    words = simplify_words({word: readings for word, readings in words.items() if not re.fullmatch(r"[A-Za-z]+", word)})
    temporary = chinese.with_name(chinese.name + ".tmp")
    try:
        with temporary.open("w", encoding="utf-8") as output:
            for word, readings in words.items():
                if not readings:
                    readings["unknown"] = {"pos": "unknown", "pos_title": "", "pinyin": []}
                output.write(json.dumps({"word": word, "entries": list(readings.values())}, ensure_ascii=False) + "\n")
        temporary.replace(chinese)
        metadata["processing"] = {
            "format_version": PROCESSING_VERSION,
            "sources": snapshot,
            "lang_code": "zh",
            "records": records,
            "zh_records": zh_records,
            "words": len(words),
            "unresolved_redirects": unresolved,
            "processed_at": datetime.now(timezone.utc).isoformat(),
        }
        write_json(directory / "metadata.json", metadata)
    finally:
        temporary.unlink(missing_ok=True)
    print(f"汉语源记录：{zh_records} / {records}，汇总为 {len(words)} 个词，保存至 {chinese}")
    for code, missing in unresolved.items():
        if missing:
            print(f"警告：[{code}] {len(missing)} 个软重定向无法解析，详见 metadata.json 的 processing.unresolved_redirects。", file=sys.stderr)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument("--check", action="store_true", help="仅检查更新，不下载、不解压、不加工")
    mode.add_argument("--update", action="store_true", help="分别检查、下载或续传 en/zh 数据，然后合并汉语词条")
    parser.add_argument("--output-dir", type=Path, default=DEFAULT_DIRECTORY, help="数据目录，默认为项目下的 data/kaikki")
    args = parser.parse_args()
    directory = args.output_dir.expanduser().resolve()

    try:
        if not args.check and not args.update:
            print("使用本地双源词典，不检查远端更新。")
            process(directory)
            return 0
        metadata = load_metadata(directory)
        for edition in EDITIONS:
            saved = local_source(edition, directory, metadata)
            source = inspect_source(edition, saved)
            if source is None or (saved is not None and saved.same_version(source)):
                print(f"[{edition.code}] 远端未更新，保留本地词典。")
                continue
            print(f"[{edition.code}] 来源：{source.url}")
            print(f"文件修改时间：{source.last_modified}")
            print(f"ETag：{source.etag}")
            print(f"压缩大小：{source.size / CHUNK_SIZE:.1f} MiB")
            if args.check:
                print("有更新可下载。" if saved is not None else "尚无完整本地词典，可以下载。")
            else:
                download(edition, source, directory)
        if not args.check:
            process(directory)
        return 0
    except KeyboardInterrupt:
        print("\n已中断；使用 --update 可继续下载，普通运行可重新加工。", file=sys.stderr)
        return 130
    except (OSError, ValueError, HTTPException, RuntimeError) as error:
        print(f"失败：{error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
