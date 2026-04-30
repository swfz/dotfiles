---
name: go
description: swfzのGoコーディングスタイルガイド。Goのコード生成・レビュー時に参照する。
paths:
  - "**/*.go"
  - "**/go.mod"
  - "**/go.sum"
---

# swfz Go スタイルガイド

Goのコードを書く・レビューするときの swfz の指針をまとめたルール集。

## 共通の哲学

- **実用性重視**: 複雑なデザインパターンより動くコードを優先。ただし拡張性が必要な場合はファクトリーパターンや継承を使う
- **プロジェクト規模に応じた設計**: 小規模ツールはフラット構造、大規模は層状構造
- **テスト重視**: テーブル駆動テストを基本とする
- **日本語を自然に使う**: コメント、テストケース名に日本語を使う場面がある
- **エラーハンドリング**: 必要最低限だが的確に。エラーチェーンの保持を重視
- **不要な抽象化を避ける**: 3行の重複コードは許容。過度なDRYより可読性

---

## パッケージ構造

- 大規模: `cmd/` → `internal/app/` → `internal/api/` → `internal/models/` の層状構造
- 小規模: 単一 `package main` でファイルを機能別に分割（`cli.go`, `query.go` など）

## エラーハンドリング

- `fmt.Errorf("failed to ...: %w", err)` でエラーを包む
- エラーメッセージにHTTPステータスコードなどのコンテキストを含める
- 小規模ツールでは `log.Fatal()` で即終了も許容

## 命名

- 説明的な名前を優先（短い省略形は避ける）
- 型安全な列挙体: `type BotType string` + `const`
- 略語は大文字統一: `URL`, `SHA`, `GraphQL`

## インポート順序

1. 標準ライブラリ
2. 外部パッケージ
3. プロジェクト内パッケージ（空行で区切る）

## ライブラリ選好

- GitHub CLI統合: `github.com/cli/go-gh/v2`
- GraphQL: `github.com/shurcooL/graphql`
- TUI: `github.com/charmbracelet/bubbletea`, `lipgloss`
- テーブル: `github.com/olekukonko/tablewriter`
- インタラクティブ: `github.com/AlecAivazis/survey/v2`
- テスト: `github.com/stretchr/testify`
- CLIフラグ: 標準 `flag` パッケージ（cobraは使わない）

## テスト

- テーブル駆動テスト（`tests := []struct{...}{}`）
- `httpmock` でHTTPレスポンスをモック
- テストケース名は英語が基本、日本語も可
- モック: カスタムインターフェース定義でテスト可能性を確保

## 構造体設計

- フィールドはすべて公開（大文字開始）
- JSONタグ、GraphQLタグを活用
- ポインタレシーバは必要時のみ
- ネストされた構造体は匿名フィールドで定義

## 並行処理

- 複雑な並行制御は避ける
- `context.WithCancel` でキャンセル処理
- シグナルハンドリング用のゴルーチンは使う

## デバッグ出力

- `fmt.Fprintf(os.Stderr, "[DEBUG] ...")` パターンで統一
- Verbose フラグで制御

## コードレビュー時の観点

1. エラーが `%w` で適切にラップされているか
2. テーブル駆動テストになっているか
3. 不要なcobraやviper等の重いフレームワークを使っていないか
4. インポートが3グループに分かれているか
5. インターフェースがテスト可能性を高めているか
