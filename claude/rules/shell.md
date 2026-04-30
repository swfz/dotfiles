---
name: shell
description: swfzのShell Script (Bash/Zsh)コーディングスタイルガイド。シェルスクリプトの生成・レビュー時に参照する。
paths:
  - "**/*.sh"
  - "**/*.bash"
  - "**/*.zsh"
  - "**/.bashrc"
  - "**/.bash_profile"
  - "**/.zshrc"
  - "**/.zprofile"
  - "**/.profile"
---

# swfz Shell Script スタイルガイド

Shell Script (Bash/Zsh) を書く・レビューするときの swfz の指針をまとめたルール集。

## 共通の哲学

- **実用性重視**: 複雑なデザインパターンより動くコードを優先
- **Bash優先、POSIX互換性は補助的**: `[[ ]]` などbash固有機能を積極活用
- **日本語を自然に使う**: コメントに日本語を使う
- **エラーハンドリング**: 新規スクリプトは `set -euo pipefail` で厳密に
- **UNIXツールの組み合わせ**: パイプでツールを繋ぐ哲学

---

## 基本設定

- shebang: `#!/bin/bash`（主流）
- 新規スクリプトでは冒頭に `set -euo pipefail` を記述
- スクリプト構造:
  1. shebang + set オプション
  2. グローバル定数定義
  3. ユーティリティ関数群
  4. メイン処理

## 変数命名

- グローバル定数: `UPPER_CASE`（`SCRIPT_DIR`, `DOTFILES_DIR`, `INTERVAL`）
- 関数内ローカル変数: `lowercase` + `local` キーワード
- `declare` で型を明示的に宣言

## クォート

- ダブルクォート主流（変数展開前提）
- パス参照は必ずダブルクォート: `"$HOME/dotfiles"`

## 関数定義

- `function name() { ... }` スタイル（`function` キーワード使用）
- Usage コメントを関数の前に記載: `# Usage: _fine_bar <pct>`

## 条件分岐

- Bash固有の `[[ ]]` を積極使用
- ファイルテスト: `-f`（ファイル）, `-d`（ディレクトリ）, `-e`（存在）, `-L`（シンボリックリンク）を正確に使い分け
- 文字列比較: `==`, `!=`
- 数値比較: `-gt`, `-lt`, `-eq`
- 空文字チェック: `-z "$var"`

## コマンド置換

- `$()` 形式を使用（バッククォートは使わない）
- ネスト: `"$(cd "$(dirname "$0")" && pwd)"`

## パイプとリダイレクション

- stdout/stderr 分離: `2>/dev/null`, `>&2`
- エラーメッセージは stderr へ: `echo "Error: ..." >&2`
- ヒアドキュメント: `<<EOF` でUsage表示

## ツール選好

- JSON: **jq**（高度なフィルタ・変換。`@csv`, `@sh` などのフォーマット関数も活用）
- YAML: **yq**
- テキスト処理: sed, awk, perl を柔軟に使い分け
- API: curl（`-s` でサイレント、`-L` でリダイレクト追従）
- ターミナル制御: `tput setaf`, `tput sgr0`
- パス操作: `basename`, `dirname`

## パターン

- 安全なシェル変数生成: `eval "$(jq -r '@sh "var=\(.field)"')"`
- ANSI色コード: `$'\033[38;2;R;G;Bm'` でTrue Color
- 配列操作: `SERVERS=( ... )` + `for server in ${SERVERS[@]}`
- スクリプトディレクトリ取得: `SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"`
- コマンド存在チェック: `which "$1" > /dev/null 2>&1`

## Zsh設定（.zshrc関連）

- プラグインマネージャー: **Zinit**
- `add-zsh-hook` でフック活用（`preexec`, `chpwd`, `precmd`）
- `autoload -Uz` で遅延読み込み
- `setopt` でオプション設定（`auto_cd`, `hist_ignore_dups` 等）
- `zstyle` で補完設定
- 設定ファイルは `$HOME/dotfiles/zsh/` からループで `source`

## コメント

- 日本語と英語の混在
- `# NOTE:` で注意事項
- Usage をヘッダコメントとして記載
- ソース引用: `# Source: https://...`

## コードレビュー時の観点

1. `set -euo pipefail` が設定されているか（新規スクリプト）
2. 変数がダブルクォートで囲まれているか
3. `[[ ]]` が使われているか（`[ ]` ではなく）
4. `$()` が使われているか（バッククォートではなく）
5. `function` キーワードが使われているか
6. エラーメッセージが stderr に出力されているか
7. `local` でローカル変数が宣言されているか
