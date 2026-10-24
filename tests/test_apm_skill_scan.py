"""bin/apm-skill-scan のテスト。

skill-scanner と git は呼ばず、apm.yml の解釈・指摘の正規化・ベースライン照合だけを確かめる。
実行: python3 -m unittest discover -s tests -p 'test_*.py'
"""
import importlib.machinery
import importlib.util
import unittest
from collections import Counter
from pathlib import Path

SCRIPT = Path(__file__).resolve().parent.parent / "bin/apm-skill-scan"
_loader = importlib.machinery.SourceFileLoader("apm_skill_scan", str(SCRIPT))
_spec = importlib.util.spec_from_loader("apm_skill_scan", _loader)
assert _spec is not None
apm_skill_scan = importlib.util.module_from_spec(_spec)
_loader.exec_module(apm_skill_scan)

SHA_A = "a" * 40
SHA_B = "b" * 40

MANIFEST = f"""name: sawafuji
targets:
  - claude
dependencies:
  apm:
    - owner/repo/skills/foo#{SHA_A} # v1.0.0
    # コメント行は飛ばす
    - other/single#{SHA_B}
  mcp: []
includes: auto
"""


def finding(rule_id="RULE", file="SKILL.md", snippet="x", severity="LOW"):
    return apm_skill_scan.Finding(rule_id, file, snippet, severity, "title")


class ParseDepsTest(unittest.TestCase):
    def test_reads_only_apm_dependencies(self):
        deps = apm_skill_scan.parse_deps(MANIFEST)
        self.assertEqual(
            deps,
            [
                apm_skill_scan.Dep("owner/repo", "skills/foo", SHA_A),
                apm_skill_scan.Dep("other/single", "", SHA_B),
            ],
        )

    def test_names(self):
        sub, single = apm_skill_scan.parse_deps(MANIFEST)
        self.assertEqual(sub.name, "owner/repo/skills/foo")
        self.assertEqual(sub.skill_name, "foo")
        self.assertEqual(single.name, "other/single")
        self.assertEqual(single.skill_name, "single")

    def test_rejects_unpinned_dependency(self):
        text = "dependencies:\n  apm:\n    - owner/repo/skills/foo#main\n"
        with self.assertRaisesRegex(apm_skill_scan.ScanError, "SHA"):
            apm_skill_scan.parse_deps(text)

    def test_ignores_trailing_comment_on_keys(self):
        text = f"dependencies:  # 第三者スキル\n  apm:  # apm\n    - owner/repo#{SHA_A} # v1.0.0\n"
        self.assertEqual(apm_skill_scan.parse_deps(text), [apm_skill_scan.Dep("owner/repo", "", SHA_A)])

    def test_rejects_empty_dependencies(self):
        for text in ("dependencies:\n  apm: []\n  mcp: []\n", "deps:\n  apm:\n    - owner/repo\n"):
            with self.subTest(text=text), self.assertRaisesRegex(apm_skill_scan.ScanError, "1 件も"):
                apm_skill_scan.parse_deps(text)

    def test_rejects_dependency_without_ref(self):
        text = "dependencies:\n  apm:\n    - owner/repo\n"
        with self.assertRaises(apm_skill_scan.ScanError):
            apm_skill_scan.parse_deps(text)


class ParseFindingsTest(unittest.TestCase):
    def test_normalizes_and_keeps_duplicates(self):
        report = {
            "findings": [
                {"rule_id": "R", "file_path": "a.js", "line_number": 3, "snippet": "  call()  ", "severity": "HIGH", "title": "t"},
                {"rule_id": "R", "file_path": "a.js", "line_number": 9, "snippet": "call()", "severity": "HIGH", "title": "t"},
                {"rule_id": "M", "file_path": "SKILL.md", "line_number": None, "snippet": None, "severity": "INFO", "title": "t"},
            ]
        }
        self.assertEqual(
            apm_skill_scan.parse_findings(report),
            [
                apm_skill_scan.Finding("M", "SKILL.md", "", "INFO", "t"),
                apm_skill_scan.Finding("R", "a.js", "call()", "HIGH", "t"),
                apm_skill_scan.Finding("R", "a.js", "call()", "HIGH", "t"),
            ],
        )


class CompareTest(unittest.TestCase):
    def test_known_findings_pass(self):
        f = finding()
        new, stale = apm_skill_scan.compare({"dep": [f]}, {"dep": Counter([f.key])})
        self.assertEqual(new, {})
        self.assertEqual(stale, {})

    def test_line_shift_is_still_known(self):
        # 照合キーに行番号を含めないので、同じ snippet なら既知扱いになる
        f = finding(snippet="call()")
        new, _ = apm_skill_scan.compare({"dep": [f]}, {"dep": Counter([("RULE", "SKILL.md", "call()")])})
        self.assertEqual(new, {})

    def test_unknown_findings_are_reported(self):
        known, unknown = finding(snippet="old"), finding(snippet="new")
        new, _ = apm_skill_scan.compare({"dep": [known, unknown]}, {"dep": Counter([known.key])})
        self.assertEqual(new, {"dep": [unknown]})

    def test_new_dependency_has_no_baseline(self):
        f = finding()
        new, _ = apm_skill_scan.compare({"dep": [f]}, {})
        self.assertEqual(new, {"dep": [f]})

    def test_baseline_is_scoped_per_dependency(self):
        f = finding()
        new, _ = apm_skill_scan.compare({"dep": [f]}, {"other": Counter([f.key])})
        self.assertEqual(new, {"dep": [f]})

    def test_extra_finding_with_same_key_is_reported(self):
        # snippet を持たない指摘は同じキーに潰れるので、件数が増えた分を未確認にする
        f = finding(rule_id="MANIFEST", snippet="")
        new, _ = apm_skill_scan.compare({"dep": [f, f]}, {"dep": Counter([f.key])})
        self.assertEqual(new, {"dep": [f]})

    def test_stale_entries(self):
        gone = ("GONE", "a.js", "x")
        new, stale = apm_skill_scan.compare({"dep": []}, {"dep": Counter([gone])})
        self.assertEqual(new, {})
        self.assertEqual(stale, {"dep": {gone}})


class BaselineRoundTripTest(unittest.TestCase):
    def test_dump_then_load(self):
        import json
        import tempfile

        results = {"b": [finding(snippet="2")], "a": [finding(snippet="1")]}
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "baseline.json"
            path.write_text(apm_skill_scan.dump_baseline(results))
            self.assertEqual(list(json.loads(path.read_text())), ["a", "b"])
            self.assertEqual(
                apm_skill_scan.load_baseline(path),
                {"a": Counter([("RULE", "SKILL.md", "1")]), "b": Counter([("RULE", "SKILL.md", "2")])},
            )

    def test_missing_baseline_is_empty(self):
        self.assertEqual(apm_skill_scan.load_baseline(Path("/nonexistent/baseline.json")), {})


if __name__ == "__main__":
    unittest.main()
