#!/usr/bin/env python3
"""Upload Rime configuration files or skins to File Browser."""

from __future__ import annotations

import argparse
import sys
from pathlib import Path
from urllib.error import HTTPError, URLError
from urllib.parse import quote, urlsplit, urlunsplit
from urllib.request import Request, urlopen


EXCLUDED_CONFIG_NAMES = {
    "README.md",
    "default.custom.yaml",
    "installation.yaml",
    "packages.conf",
    "squirrel.custom.yaml",
    "user.yaml",
}
CONFIG_DIRECTORIES = ("lua", "opencc", "user")


def api_base(target: str) -> str:
    parsed = urlsplit(target)
    if parsed.scheme not in {"http", "https"} or not parsed.netloc:
        raise ValueError("目标地址必须是 http:// 或 https:// 地址")

    path = parsed.path.rstrip("/")
    if "/api/resources" in path:
        base_path = path
    else:
        marker = "/files"
        marker_index = path.find(marker)
        if marker_index < 0:
            raise ValueError("目标地址应包含 /files/，例如 http://主机/files/Skins/")
        base_path = path[:marker_index] + "/api/resources" + path[marker_index + len(marker) :]

    return urlunsplit((parsed.scheme, parsed.netloc, base_path + "/", "", ""))


def target_url(value: str) -> str:
    parsed = urlsplit(value)
    if parsed.scheme not in {"http", "https"} or not parsed.netloc:
        raise ValueError("目标地址必须是完整的 http:// 或 https:// 地址")
    if not parsed.path or parsed.path == "/":
        raise ValueError("目标地址必须包含完整的 File Browser 路径，例如 http://主机/files/Skins/")
    return value


def upload_url(base: str, relative: Path) -> str:
    encoded_path = "/".join(quote(part, safe="") for part in relative.parts)
    return f"{base}{encoded_path}?override=true"


def fetch_anonymous_token(target: str) -> str:
    parsed = urlsplit(target)
    login_url = urlunsplit((parsed.scheme, parsed.netloc, "/api/login", "", ""))
    request = Request(
        login_url,
        data=b"{}",
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    with urlopen(request, timeout=120) as response:
        if response.status != 200:
            raise RuntimeError(f"HTTP {response.status}")
        token = response.read().decode("utf-8").strip()
    if not token:
        raise RuntimeError("响应中没有 Token")
    return token


def config_files(root: Path) -> list[tuple[Path, Path]]:
    files: list[tuple[Path, Path]] = []

    def included(relative: Path) -> bool:
        return (
            not any(part.startswith(".") for part in relative.parts)
            and relative.name not in EXCLUDED_CONFIG_NAMES
        )

    for path in root.iterdir():
        relative = path.relative_to(root)
        if path.is_file() and included(relative):
            files.append((path, relative))

    for directory in CONFIG_DIRECTORIES:
        directory_path = root / directory
        if not directory_path.is_dir():
            continue
        for path in directory_path.rglob("*"):
            relative = path.relative_to(root)
            if path.is_file() and included(relative):
                files.append((path, relative))

    return sorted(files, key=lambda item: item[1].as_posix())


def skin_files(root: Path) -> list[tuple[Path, Path]]:
    return sorted(
        (
            path,
            path.relative_to(root),
        )
        for path in root.rglob("*")
        if path.is_file()
    )


def upload_files(
    files: list[tuple[Path, Path]],
    target: str,
    fetch_token: bool,
) -> int:
    if not files:
        print("没有找到符合条件的文件。")
        return 0

    base = api_base(target)
    auth_token = None
    if fetch_token:
        try:
            auth_token = fetch_anonymous_token(target)
        except HTTPError as error:
            detail = error.read().decode("utf-8", errors="replace").strip()
            print(f"获取匿名 Token 失败: HTTP {error.code} {detail}", file=sys.stderr)
            return 1
        except (OSError, URLError, RuntimeError) as error:
            print(f"获取匿名 Token 失败: {error}", file=sys.stderr)
            return 1

    print(f"目标地址: {target}")
    print(f"待上传: {len(files)} 个文件")

    failed = 0
    for path, relative in files:
        headers = {"Content-Type": "application/octet-stream"}
        if auth_token:
            headers["X-Auth"] = auth_token

        try:
            request = Request(
                upload_url(base, relative),
                data=path.read_bytes(),
                headers=headers,
                method="POST",
            )
            with urlopen(request, timeout=120) as response:
                if response.status not in {200, 201, 204}:
                    raise RuntimeError(f"HTTP {response.status}")
            print(f"OK   {relative}")
        except HTTPError as error:
            failed += 1
            detail = error.read().decode("utf-8", errors="replace").strip()
            print(f"FAIL {relative}: HTTP {error.code} {detail}", file=sys.stderr)
        except (OSError, URLError, RuntimeError) as error:
            failed += 1
            print(f"FAIL {relative}: {error}", file=sys.stderr)

    succeeded = len(files) - failed
    print(f"完成：成功 {succeeded}，失败 {failed}")
    return 1 if failed else 0


def main() -> int:
    root = Path(__file__).resolve().parent.parent
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "kind",
        choices=("config", "skins"),
        help="config 上传配置文件；skins 同步 Skins/ 全部内容",
    )
    parser.add_argument(
        "target",
        help="完整的 File Browser 地址，例如 http://主机/files/Skins/",
    )
    parser.add_argument(
        "--anonymous-token",
        action="store_true",
        help="上传前获取一次匿名 Token，并通过 X-Auth 请求头上传",
    )
    args = parser.parse_args()

    source = (root / "Skins" if args.kind == "skins" else root).resolve()
    if not source.is_dir():
        parser.error(f"源目录不存在：{source}")

    files = skin_files(source) if args.kind == "skins" else config_files(source)
    try:
        target = target_url(args.target)
        return upload_files(files, target, args.anonymous_token)
    except ValueError as error:
        parser.error(str(error))
    return 2


if __name__ == "__main__":
    raise SystemExit(main())
