"""claude/skills/ci-watch/scripts/detect_failures.py のテスト。

gh の呼び出しは detect_failures.run を差し替えて偽の JSON を返すので、gh もネットワークも使わない。
実行: python3 -m unittest discover -s tests -p 'test_*.py'
"""
import importlib.util
import io
import json
import sys
import unittest
from contextlib import redirect_stderr, redirect_stdout
from pathlib import Path
from unittest import mock

SCRIPT = Path(__file__).resolve().parent.parent / "claude/skills/ci-watch/scripts/detect_failures.py"
_spec = importlib.util.spec_from_file_location("detect_failures", SCRIPT)
assert _spec is not None and _spec.loader is not None
detect_failures = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(detect_failures)


def make_run(workflow_id, conclusion, status="completed", run_id=None):
    run_id = run_id if run_id is not None else workflow_id * 100
    return {
        "workflow_id": workflow_id,
        "name": f"wf{workflow_id}",
        "id": run_id,
        "html_url": f"https://github.com/swfz/repo/actions/runs/{run_id}",
        "status": status,
        "conclusion": conclusion,
        "event": "push",
        "created_at": "2026-10-20T00:00:00Z",
    }


def runs_response(*runs):
    return json.dumps({"workflow_runs": list(runs)})


class FakeGh:
    """gh の引数リストの要素(リポジトリ名や API パス)と完全一致したら対応する stdout を返す偽の run()。"""

    def __init__(self, responses):
        self.responses = responses

    def __call__(self, cmd):
        for key, out in self.responses.items():
            if key in cmd:
                return out
        return None


class LatestFailuresTest(unittest.TestCase):
    def latest_failures(self, *runs):
        fake = FakeGh({"repos/swfz/repo/actions/runs?branch=main&per_page=100": runs_response(*runs)})
        with mock.patch.object(detect_failures, "run", fake):
            return detect_failures.latest_failures("swfz", "repo", "main", 100)

    def test_同一ワークフローは先頭の_completed_run_だけを見る(self):
        # API は新しい順。新しい success の後ろにある古い failure は過去の失敗なので拾わない
        result = self.latest_failures(make_run(1, "success", run_id=2), make_run(1, "failure", run_id=1))
        self.assertEqual(result, [])

        # 新しい方が failure なら、古い success があっても拾う
        result = self.latest_failures(make_run(1, "failure", run_id=2), make_run(1, "success", run_id=1))
        self.assertEqual([f["run_id"] for f in result], [2])

    def test_in_progress_と_queued_はスキップして次の_completed_を見る(self):
        result = self.latest_failures(
            make_run(1, None, status="in_progress", run_id=3),
            make_run(1, None, status="queued", run_id=2),
            make_run(1, "failure", run_id=1),
        )
        self.assertEqual([f["run_id"] for f in result], [1])

    def test_cancelled_と_skipped_と_neutral_は失敗に数えない(self):
        result = self.latest_failures(make_run(1, "cancelled"), make_run(2, "skipped"), make_run(3, "neutral"))
        self.assertEqual(result, [])

    def test_failure_と_timed_out_と_startup_failure_は拾う(self):
        result = self.latest_failures(
            make_run(1, "failure"), make_run(2, "timed_out"), make_run(3, "startup_failure"), make_run(4, "success")
        )
        self.assertEqual(
            [(f["workflow"], f["conclusion"]) for f in result],
            [("wf1", "failure"), ("wf2", "timed_out"), ("wf3", "startup_failure")],
        )
        self.assertEqual(
            result[0],
            {
                "workflow": "wf1",
                "run_id": 100,
                "url": "https://github.com/swfz/repo/actions/runs/100",
                "conclusion": "failure",
                "event": "push",
                "created_at": "2026-10-20T00:00:00Z",
            },
        )

    def test_失敗が無ければ空(self):
        self.assertEqual(self.latest_failures(make_run(1, "success"), make_run(2, "success")), [])
        self.assertEqual(self.latest_failures(), [])

    def test_gh_が失敗したら空(self):
        with mock.patch.object(detect_failures, "run", FakeGh({})):
            self.assertEqual(detect_failures.latest_failures("swfz", "repo", "main", 100), [])


class ListReposTest(unittest.TestCase):
    REPOS = json.dumps(
        [
            {"name": "active", "defaultBranchRef": {"name": "main"}, "isArchived": False, "isFork": False},
            {"name": "archived", "defaultBranchRef": {"name": "main"}, "isArchived": True, "isFork": False},
            {"name": "fork", "defaultBranchRef": {"name": "master"}, "isArchived": False, "isFork": True},
            {"name": "empty", "defaultBranchRef": None, "isArchived": False, "isFork": False},
        ]
    )

    def list_repos(self, include_forks=False, include_archived=False):
        with mock.patch.object(detect_failures, "run", FakeGh({"list": self.REPOS})):
            return detect_failures.list_repos("swfz", 500, include_forks, include_archived)

    def test_既定では_archived_と_fork_と空リポジトリを除く(self):
        self.assertEqual(self.list_repos(), [("active", "main")])

    def test_オプションで_fork_と_archived_を含める(self):
        self.assertEqual(
            self.list_repos(include_forks=True, include_archived=True),
            [("active", "main"), ("archived", "main"), ("fork", "master")],
        )

    def test_gh_が失敗したら終了コード_1_で終わる(self):
        with mock.patch.object(detect_failures, "run", FakeGh({})):
            with self.assertRaises(SystemExit) as cm:
                detect_failures.list_repos("swfz", 500, False, False)
        self.assertEqual(cm.exception.code, 1)


class ResolveReposTest(unittest.TestCase):
    def test_解決できたリポジトリだけを返す(self):
        fake = FakeGh(
            {
                "swfz/ok": json.dumps({"defaultBranchRef": {"name": "main"}}),
                "swfz/empty": json.dumps({"defaultBranchRef": None}),
            }
        )
        with mock.patch.object(detect_failures, "run", fake):
            result = detect_failures.resolve_repos("swfz", ["ok", "empty", "missing"])
        self.assertEqual(result, [("ok", "main")])


class MainTest(unittest.TestCase):
    def run_main(self, argv, responses):
        stdout, stderr = io.StringIO(), io.StringIO()
        with (
            mock.patch.object(detect_failures, "run", FakeGh(responses)),
            mock.patch.object(sys, "argv", ["detect_failures.py", *argv]),
            redirect_stdout(stdout),
            redirect_stderr(stderr),
        ):
            detect_failures.main()
        return json.loads(stdout.getvalue()), stderr.getvalue()

    def test_失敗のあったリポジトリだけが出力に入る(self):
        result, stderr = self.run_main(
            ["--repos", "red", "green"],
            {
                "swfz/red": json.dumps({"defaultBranchRef": {"name": "main"}}),
                "swfz/green": json.dumps({"defaultBranchRef": {"name": "master"}}),
                "repos/swfz/red/actions/runs?branch=main&per_page=100": runs_response(make_run(1, "failure")),
                "repos/swfz/green/actions/runs?branch=master&per_page=100": runs_response(make_run(1, "success")),
            },
        )
        self.assertEqual([r["repo"] for r in result], ["swfz/red"])
        self.assertEqual(result[0]["default_branch"], "main")
        self.assertEqual([f["conclusion"] for f in result[0]["failures"]], ["failure"])
        self.assertIn("checked 2 repos, 1 with failures", stderr)

    def test_失敗が無ければ空配列を出力する(self):
        result, _ = self.run_main(
            ["--repos", "green"],
            {
                "swfz/green": json.dumps({"defaultBranchRef": {"name": "main"}}),
                "repos/swfz/green/actions/runs?branch=main&per_page=100": runs_response(make_run(1, "success")),
            },
        )
        self.assertEqual(result, [])

    def test_repos_未指定なら一覧を取得して巡回する(self):
        result, _ = self.run_main(
            [],
            {
                "list": json.dumps(
                    [{"name": "red", "defaultBranchRef": {"name": "main"}, "isArchived": False, "isFork": False}]
                ),
                "repos/swfz/red/actions/runs?branch=main&per_page=100": runs_response(make_run(1, "timed_out")),
            },
        )
        self.assertEqual([r["repo"] for r in result], ["swfz/red"])


if __name__ == "__main__":
    unittest.main()
