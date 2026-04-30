---
name: python
description: swfzのPythonコーディングスタイルガイド。Pythonのコード生成・レビュー時に参照する。
paths:
  - "**/*.py"
  - "**/Pipfile"
  - "**/pyproject.toml"
  - "**/requirements*.txt"
---

# swfz Python スタイルガイド

Pythonのコードを書く・レビューするときの swfz の指針をまとめたルール集。

## 共通の哲学

- **実用性重視**: ツール・スクリプト性が高いプロジェクトでは柔軟に
- **プロジェクト規模に応じた設計**: 大規模データ処理ではファクトリーパターンと関数型パイプラインで整理
- **テスト重視**: unittestでサンプルデータを活用
- **日本語を自然に使う**: コメント、出力メッセージに日本語を積極的に使う
- **エラーハンドリング**: 必要最低限だが的確に
- **不要な抽象化を避ける**: 3行の重複コードは許容。過度なDRYより可読性

---

## 型ヒント

- 使用は最小限（プロトタイプ・スクリプト重視）
- 外部ライブラリの型定義が不完全な場合は `# type: ignore` で対応

## 命名

- 変数・関数: `snake_case`
- クラス: `PascalCase`
- 定数: `UPPER_SNAKE_CASE`
- 単一文字変数は避け、意味のある名前を使う

## 文字列

- **f-string** を優先
- 複数行文字列は `+` 演算子で連結
- 日本語テキストを含む処理が多い

## パッケージ管理

- **Pipenv**（Pipfile）または **pip** + `requirements.txt`
- バージョンピンニングは必要に応じて
- shebang: `#!/usr/bin/env python3`

## エラーハンドリング

- 最小限。本当に必要な部分だけ
- `KeyboardInterrupt` のハンドリングは行う
- Noneチェック: `value or ''` でデフォルト化

## テスト

- **unittest** フレームワーク
- `setUpClass` で共通データ準備
- `subTest` でパラメタライズ
- `sample_input/` にテストデータ配置
- `coverage` でカバレッジ計測

## 設計パターン

- ファクトリーパターン（`globals()` で動的クラスルックアップ）
- 継承で共通インターフェース（`transform()`, `bot_event()`, `available()` 等）
- Apache Beam ではパイプ演算子（`|`, `>>`）による関数型記述

## インポート順序

1. 標準ライブラリ
2. 外部ライブラリ
3. ローカルモジュール（相対インポート `.module`）

## ライブラリ選好

- データ処理: Apache Beam, numpy
- API: requests, openai
- GCP: google-cloud-bigquery, google-cloud-storage
- CLI引数: argparse
- 音声: soundcard, soundfile

## 並行処理

- `threading` + `queue` でスレッド間通信
- `threading.Event()` で停止シグナル

## デバッグ

- `print('[Info] ...')` パターンで進捗通知
- `pprint` で構造化データの確認

## コメント

- 日本語コメントを多用
- `# NOTE:` で既知の制限事項を記録
- ドキストリングは使用しない（コードが自明であるべき）

## コードレビュー時の観点

1. f-stringが使われているか（`.format()` や `%` ではなく）
2. ファクトリーパターンで拡張性が確保されているか
3. 不要な型ヒントで可読性が下がっていないか
4. テストデータが適切にファイル管理されているか
5. 日本語コメント・出力が自然か
