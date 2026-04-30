# bin

コマンドラインユーティリティ集。

## ansi_colorlist
ANSIエスケープシーケンスの色一覧を表示する。

## ansi_hexlist
ターミナル上でhexカラーをグリッド表示、または特定の色の周辺色を可視化する。

## as_ips
Auto Scaling Group内で稼働中のEC2インスタンスのプライベートIPアドレスを取得する。

## check_version.sh
指定したコマンドがインストールされているか、またそのバージョンが指定値と一致するかをチェックする。

## claude-hook-notify
Claude Codeのフックで、通知の送信とtmuxウィンドウの見た目を更新する。

## claude-session-preview
Claude CodeのセッションJSONLファイルをプレビュー・整形表示する。

## ccsync.sh
Claude Codeのアセット（skillsなど）をdotfilesに追加/リンク/一覧/削除して管理する。

## color
hexコード（例: `#RRGGBB`）でターミナルに色を表示する。

## dr
Dataformジョブを実行し（run/view）、JSON/CSV形式で出力する。

## file2slack
ファイルや標準入力をSlackに投稿する。

## fzf-toggle-exact
`fzf`の曖昧マッチと完全一致マッチを切り替える。

## gdocs2txt
Googleドキュメントをテキストに変換する。

## gdrive-folder-export
Googleドライブ上のHTML/Docsをファイルとしてダウンロードする。

## gsheet2csv
GoogleスプレッドシートをCSVとしてエクスポートする。

## glue-config-diff
AWS Lambda関数の設定を`diff-sofancy`で比較する。

## glue-diff
Lambda関数のコード（解凍済み）を`diff-sofancy`で比較する。

## gh-open-prs
指定したGitHubユーザーのオープンPRを取得し、リポジトリごとにまとめて表示する。

## jq2esc
エスケープシーケンスを変換する`jq`。

## lambda-config-diff
AWS Lambda関数の設定を`diff-sofancy`で比較する。

## lambda-diff
Lambda関数のコード（解凍済み）を`diff-sofancy`で比較する。

## mbsplit
マルチバイト文字を考慮してバイトサイズで分割する。

## monitor-mtg.sh
カメラ/マイクの利用を監視し、Switchbotデバイスをトリガーする。

## nrun
コマンドの終了コードに応じて、デスクトップ通知とtmux通知を送るラッパー。

## not_have_git_dir.sh
カレントディレクトリ配下で`.git`ディレクトリを持たないディレクトリをチェックする。

## notify
デスクトップ通知を送る（macOS/WSL対応）。

## runtimes
ruby・nodejs・python・golangの`starship`モジュールを高速に実行する。

## server
カレントディレクトリで静的サーバーを起動する。

## setup-monitor-mtg.sh
カメラ/マイクの利用を監視するsystemdユーザーサービスをセットアップする。

## switchbot
SwitchBot API v1.1 を直接叩いてデバイスを on/off する。`SWITCHBOT_TOKEN` / `SWITCHBOT_SECRET` / `SWITCHBOT_DEVICE_ID` を環境変数で渡す。Ruby gem 依存をやめたのでランタイム差し替えの影響を受けない。

## tms
現在のtmuxペインレイアウトをYAML設定ファイルに保存する。

## tm
保存済みのtmuxペインレイアウトをYAML設定ファイルから適用する。

## traceback
トレースバックユーティリティ。

## tmux-cpuused.sh
現在のCPU使用率（％）を計算する。

## tmux-delayed-bg-reset
一定時間後にtmuxペインのウィンドウスタイルをデフォルトに戻す。

## tmux-git-root-name
現在のgitリポジトリのルートディレクトリ名を返す。

## tmux-memused.sh
空きメモリ量を`GB`単位で表示する。

## tmux-open-selection
tmuxバッファ/セレクション内のURLやファイルをデフォルトのブラウザ/エディタで開く。

## tmux-window-name
絵文字、ディレクトリ名、gitブランチ情報を含むtmuxウィンドウ名を生成する。

## watch-server
ファイル監視用のシンプルなWebサーバー。

## watch_node_repl_history
`.node_repl_history`ファイルをシンタックスハイライト付きでターミナルに監視表示する。

## wcmd
ファイル変更時にコマンドを実行する。

## release-digest

各種サービスのRSS/Atomフィード (Google Cloud / AWS / Claude Code / GitHub Copilot など) から
直近N時間のリリース情報を取得し、`claude -p` で要約してMarkdownに保存する。

- ソース追加: `config/release-digest/sources.tsv` に `name<TAB>url` を1行追加
- 実行: `release-digest`
- 出力先: `~/release-digest/YYYY-MM-DD.md`

オプション環境変数:

- `RELEASE_DIGEST_HOURS` (default `24`): 過去何時間分を対象にするか
- `RELEASE_DIGEST_OUT_DIR` (default `~/release-digest`): 出力先ディレクトリ
- `RELEASE_DIGEST_LIMIT` (default `20`): ソースあたりLLMに渡すエントリ上限
- `RELEASE_DIGEST_MODEL` (default `sonnet`): `claude --model` に渡す値。空文字で省略
- `RELEASE_DIGEST_CONFIG`: 設定ファイルパスの上書き

cron例 (毎朝9時):

```
0 9 * * * /home/you/dotfiles/bin/release-digest >> /home/you/release-digest/cron.log 2>&1
```
