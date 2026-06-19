#!/usr/bin/env python3
"""対象HTMLの </body> 直前にコメントレイヤーを注入する。
使い方: python inject.py <input.html> [output.html]
output 省略時は <input>.commented.html を同じディレクトリに出力。
</body> が無いHTMLには </html> 直前、それも無ければ末尾に追記する。"""
import sys, os

def main():
    if len(sys.argv) < 2:
        sys.exit("usage: inject.py <input.html> [output.html]")
    src = sys.argv[1]
    layer = os.path.join(os.path.dirname(os.path.abspath(__file__)), "comment-layer.html")
    if len(sys.argv) >= 3:
        out = sys.argv[2]
    else:
        base, ext = os.path.splitext(src)
        out = base + ".commented" + (ext or ".html")

    html = open(src, encoding="utf-8").read()
    if "rc-panel" in html and "review-comments" in html:
        sys.exit("既にコメントレイヤーが注入済みのようです: " + src)
    snippet = open(layer, encoding="utf-8").read()

    low = html.lower()
    idx = low.rfind("</body>")
    if idx == -1:
        idx = low.rfind("</html>")
    block = "\n" + snippet + "\n"
    html = html[:idx] + block + html[idx:] if idx != -1 else html + block

    open(out, "w", encoding="utf-8").write(html)
    print(out)

if __name__ == "__main__":
    main()
