#!/usr/bin/env python3
"""swfz 配下リポジトリのデフォルトブランチ CI 失敗を検出する。

各リポジトリについて、デフォルトブランチ上で「ワークフローごとの最新の完了 run」を取得し、
conclusion が failure / timed_out / startup_failure のものだけを抽出する。
GitHub Actions の run 一覧は新しい順に返るため、ワークフローごとに最初に現れた
completed run をその時点の最新状態とみなす(in_progress / queued はスキップ)。

出力は失敗のあったリポジトリのみの JSON 配列(標準出力 or --output)。
失敗がゼロなら空配列を出力する。これにより呼び出し側は「対応不要」を機械的に判定できる。

使い方:
    python3 detect_failures.py                       # swfz の全リポを巡回
    python3 detect_failures.py --repos dotfiles foo  # 特定リポのみ
    python3 detect_failures.py --output /tmp/ci.json # ファイルに保存
"""
import argparse
import json
import subprocess
import sys

# 「落ちている」とみなす conclusion。cancelled / skipped / neutral は意図的に除外する。
FAIL_CONCLUSIONS = {"failure", "timed_out", "startup_failure"}


def run(cmd):
    """コマンドを実行して stdout を返す。失敗時は警告を出して None。"""
    r = subprocess.run(cmd, capture_output=True, text=True)
    if r.returncode != 0:
        print(f"[warn] command failed: {' '.join(cmd)}\n{r.stderr.strip()}", file=sys.stderr)
        return None
    return r.stdout


def list_repos(owner, limit, include_forks, include_archived):
    """owner 配下のリポジトリ(name, default_branch)の一覧を返す。"""
    out = run([
        "gh", "repo", "list", owner,
        "--limit", str(limit),
        "--json", "name,defaultBranchRef,isArchived,isFork",
    ])
    if out is None:
        sys.exit(1)

    targets = []
    for r in json.loads(out):
        if r.get("isArchived") and not include_archived:
            continue
        if r.get("isFork") and not include_forks:
            continue
        ref = r.get("defaultBranchRef")
        if not ref:  # コミットの無い空リポジトリ
            continue
        targets.append((r["name"], ref["name"]))
    return targets


def resolve_repos(owner, names):
    """明示指定された repo 名について default branch を解決する。"""
    targets = []
    for name in names:
        out = run(["gh", "repo", "view", f"{owner}/{name}", "--json", "defaultBranchRef"])
        if out is None:
            continue
        ref = json.loads(out).get("defaultBranchRef")
        if ref:
            targets.append((name, ref["name"]))
    return targets


def latest_failures(owner, repo, branch, per_page):
    """repo のデフォルトブランチで、ワークフローごとの最新 completed run のうち失敗を返す。"""
    path = f"repos/{owner}/{repo}/actions/runs?branch={branch}&per_page={per_page}"
    out = run(["gh", "api", path])
    if out is None:
        return []

    runs = json.loads(out).get("workflow_runs", [])
    latest = {}  # workflow_id -> 最新の completed run
    for r in runs:
        if r.get("status") != "completed":
            continue
        wid = r.get("workflow_id")
        if wid not in latest:  # API は新しい順なので最初の completed が最新
            latest[wid] = r

    failures = []
    for r in latest.values():
        if r.get("conclusion") in FAIL_CONCLUSIONS:
            failures.append({
                "workflow": r.get("name"),
                "run_id": r.get("id"),
                "url": r.get("html_url"),
                "conclusion": r.get("conclusion"),
                "event": r.get("event"),
                "created_at": r.get("created_at"),
            })
    return failures


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--owner", default="swfz", help="対象オーナー(default: swfz)")
    ap.add_argument("--limit", type=int, default=500, help="リポジトリ取得上限")
    ap.add_argument("--per-page", type=int, default=100, help="リポジトリあたりの run 取得件数")
    ap.add_argument("--repos", nargs="*", help="特定リポジトリ名のみを対象にする(指定時は一覧取得をスキップ)")
    ap.add_argument("--include-forks", action="store_true", help="fork も対象に含める")
    ap.add_argument("--include-archived", action="store_true", help="archived も対象に含める")
    ap.add_argument("--output", help="結果 JSON の出力先(未指定なら標準出力)")
    args = ap.parse_args()

    if args.repos:
        targets = resolve_repos(args.owner, args.repos)
    else:
        targets = list_repos(args.owner, args.limit, args.include_forks, args.include_archived)

    results = []
    for name, branch in targets:
        fails = latest_failures(args.owner, name, branch, args.per_page)
        if fails:
            results.append({
                "repo": f"{args.owner}/{name}",
                "default_branch": branch,
                "failures": fails,
            })

    print(f"[info] checked {len(targets)} repos, {len(results)} with failures", file=sys.stderr)

    payload = json.dumps(results, ensure_ascii=False, indent=2)
    if args.output:
        with open(args.output, "w") as f:
            f.write(payload)
        print(f"[info] wrote {args.output}", file=sys.stderr)
    else:
        print(payload)


if __name__ == "__main__":
    main()
