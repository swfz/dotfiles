# /// script
# requires-python = ">=3.10"
# dependencies = ["fonttools>=4.50", "brotli"]
# ///
"""style-journal: 公開前にWebフォントをサブセット化してHTMLに埋め込む。

Artifact は外部フォントCDNをCSPでブロックするため、文書で実際に使って
いる文字だけに絞った woff2 を data URI として <style> に埋め込む。

    uv run embed_fonts.py <html-file>

- フォントは google/fonts (GitHub) からダウンロードし、ローカルにキャッシュする
  (~/.cache/style-journal-fonts。書けない環境では $TMPDIR 配下)
- 再実行すると埋め込みブロックを差し替える (冪等)。本文を編集したら公開前に再実行すること
- 埋め込み後もシステムフォントのフォールバックは残るため、スクリプトを
  実行しない/できない場合でも文書は読める
"""

import base64
import io
import re
import sys
import urllib.parse
import urllib.request
from pathlib import Path

RAW_BASE = "https://raw.githubusercontent.com/google/fonts/main/"

# family はテンプレートの --serif/--sans/--mono が先頭で参照する名前。
# ローカルにインストールされた同名フォントを覆い隠さないよう "Embedded" を付ける
FONTS = [
    ("Shippori Mincho Embedded", "400", "ofl/shipporimincho/ShipporiMincho-Regular.ttf"),
    ("Shippori Mincho Embedded", "600", "ofl/shipporimincho/ShipporiMincho-SemiBold.ttf"),
    ("Noto Sans JP Embedded", "100 900", "ofl/notosansjp/NotoSansJP[wght].ttf"),
    ("JetBrains Mono Embedded", "100 800", "ofl/jetbrainsmono/JetBrainsMono[wght].ttf"),
]

START = "<!-- embedded-fonts:start -->"
END = "<!-- embedded-fonts:end -->"

# 本文に無くても後からの微修正で登場しやすい文字は常に含めておく
# (サブセットに無い文字はフォールバック書体で混植になってしまうため)
ALWAYS_KEEP_RANGES = [
    (0x0020, 0x007E),  # ASCII
    (0x2000, 0x206F),  # 一般句読点 (— … ‰ など)
    (0x3000, 0x30FF),  # CJK記号・かな
    (0xFF01, 0xFF65),  # 全角英数・記号
]


def cache_dir() -> Path:
    for base in (Path.home() / ".cache", Path(__import__("tempfile").gettempdir())):
        d = base / "style-journal-fonts"
        try:
            d.mkdir(parents=True, exist_ok=True)
            (d / ".w").write_text("")
            (d / ".w").unlink()
            return d
        except OSError:
            continue
    raise SystemExit("キャッシュディレクトリを作成できない")


def fetch(path: str) -> Path:
    dst = cache_dir() / Path(path).name
    if dst.exists() and dst.stat().st_size > 0:
        return dst
    url = RAW_BASE + urllib.parse.quote(path)
    print(f"  ダウンロード: {url}")
    with urllib.request.urlopen(url) as r:
        dst.write_bytes(r.read())
    return dst


def collect_chars(html: str) -> str:
    chars = set(html)
    for lo, hi in ALWAYS_KEEP_RANGES:
        chars.update(chr(c) for c in range(lo, hi + 1))
    return "".join(sorted(chars))


def subset_woff2(ttf: Path, text: str) -> bytes:
    from fontTools.subset import Options, Subsetter, load_font, save_font

    opts = Options()
    opts.flavor = "woff2"
    opts.hinting = False
    opts.desubroutinize = True
    opts.layout_features = ["*"]  # palt / kern / liga を残す
    font = load_font(str(ttf), opts)
    ss = Subsetter(options=opts)
    ss.populate(text=text)
    ss.subset(font)
    buf = io.BytesIO()
    save_font(font, buf, opts)
    return buf.getvalue()


def build_style_block(text: str) -> str:
    faces = []
    total = 0
    for family, weight, path in FONTS:
        data = subset_woff2(fetch(path), text)
        total += len(data)
        b64 = base64.b64encode(data).decode("ascii")
        print(f"  {family} {weight}: {len(data) // 1024} KB (woff2)")
        faces.append(
            f'@font-face {{ font-family: "{family}"; font-weight: {weight}; '
            f'font-style: normal; font-display: swap; '
            f'src: url(data:font/woff2;base64,{b64}) format("woff2"); }}'
        )
    print(f"  合計: {total // 1024} KB (base64化で約1.33倍)")
    return (
        f"{START}\n<style>\n/* embed_fonts.py が生成。手で編集せず、本文を変えたら再実行する */\n"
        + "\n".join(faces)
        + f"\n</style>\n{END}"
    )


def main() -> None:
    if len(sys.argv) != 2:
        raise SystemExit(f"usage: uv run {Path(sys.argv[0]).name} <html-file>")
    target = Path(sys.argv[1])
    html = target.read_text(encoding="utf-8")

    # 旧埋め込みブロックは文字収集の前に除去する (冪等な再実行)
    bare = re.sub(re.escape(START) + r".*?" + re.escape(END), "", html, flags=re.S)
    block = build_style_block(collect_chars(bare))

    if START in html:
        out = re.sub(re.escape(START) + r".*?" + re.escape(END), block, html, flags=re.S)
    elif (m := re.search(r"</title>", bare, flags=re.I)) is not None:
        out = bare[: m.end()] + "\n" + block + bare[m.end():]
    else:
        out = block + "\n" + bare

    target.write_text(out, encoding="utf-8")
    print(f"埋め込み完了: {target} ({len(out) // 1024} KB)")


if __name__ == "__main__":
    main()
