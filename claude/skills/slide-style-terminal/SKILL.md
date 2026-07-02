---
name: slide-style-terminal
description: ターミナルウィンドウ風のエンジニア向けダークスライドデッキ (信号機ドット+パスのタイトルバー / ピンクの ❯ シェブロン見出し / tree コマンド風の結線ツリー箇条書き / ファイル名タブ付き多色コード / DuckDB CLI 風 ASCII テーブル出力 / powerline・tmux 風ステータスライン / 点滅カーソル / 16:9 レターボックス) を、単一 HTML で生成し Artifact として公開するスキル。「ターミナル風スライド」「あのダークなスライドスタイルで」「slide-style-terminal」「LT資料をあのスタイルで」などの依頼や、コマンド出力・SQL・コードを見せる技術系のプレゼン/LT/発表資料を作る場面で使う。GUI操作の集計レポート (drilldown-report / timeseries-report / gui-report) とは別物 (あちらはデータ可視化)。
---

# slide-style-terminal

エンジニア向け LT・技術発表のための **ターミナルウィンドウ風ダークスライド** を、
外部リソースに依存しない単一 HTML として生成する。Artifact 公開・ローカル閲覧の両方で使える。

## デザインの要点 (これがスタイルの本体)

| 要素 | 仕様 |
|------|------|
| スライド枠 | **ターミナルウィンドウ**化。信号機ドット + `swfz@mac: ~/talks/… — zsh` のタイトルバー、角丸・ドロップシャドウ |
| 背景 | デッキ外は `#12181f` + ビネット、スライド地は `#2b3646`。微かな**スキャンライン** |
| フォント | 等幅 (`ui-monospace` 系)。日本語はシステムのゴシックにフォールバック |
| 見出し | 先頭にピンクの `❯` シェブロン (`--accent #e23f7a`) + 白テキスト |
| 箇条書き | **`tree` コマンド風の結線**。縦スパイン `│` + エルボー `├`/`└` を CSS 罫線で描画。深いほど小さく淡く |
| コード | **ファイル名タブ**(`● users.json`)付き。中身にフィットする幅。多色シンタックス |
| 端末出力 | DuckDB CLI 風の **ASCII 罫線テーブル** を `<pre class="term">` に生貼り。行頭 `D`/`$`/`❯` は緑 |
| シンタックス色 | キーワード=ピンク `.kw` / 関数・キー=青 `.fn` / 文字列=緑 `.str` / 数値=琥珀 `.num` / コメント=灰斜体 `.com` |
| 2カラム | `.cols` で左右分割。左コード / 右出力などの対比に |
| 画像 | **白背景ボックス**に収める (`.figure img`)。下にシアン下線リンクの出典 |
| フッタ | 下端に **powerline / tmux 風ステータスライン** (`NORMAL` モード → `git:main` → ファイル名 → `utf-8` → `N/総数`)。矢印は Nerd Font ではなく CSS clip-path で描画 |
| タイトル | **ブート風プロンプト** (`❯ ./present.sh …`) + 大きな等幅タイトル + **点滅カーソル** |
| 版面 | **16:9 レターボックス**。container query (cqw/cqh) でウィンドウ幅に追従 |

色・レイアウトの実体はすべて `assets/template.html` の `:root` 変数と CSS にある。**まず読むこと。**

## ワークフロー

1. **`assets/template.html` を読む。** 全コンポーネントを含む動くリファレンスデッキ (DuckDB 例) を兼ねる。
2. **内容を差し替える。** タイトルスライド + 各スライドを、下記コンポーネントを組み合わせて作る。
   - 1トピック = 1 `<section class="slide">` → `<div class="slide-inner">` の中に `.win-bar` / `.win-body` / `.status` の3段。
   - `.win-bar` のパス表示と `.status` の `git:` ブランチ・ファイル名・モードは**発表テーマに合わせて書き換える**と世界観が締まる。
   - ページ番号は `.status` の `.seg--count` 内 `<span class="pageno">N</span>/総数` を更新。タイトルは `1`。
3. **画像は data: URI で埋め込む** (Artifact は外部URL・CDN・フォント読み込みを CSP でブロックする)。
   - ローカル画像 → base64 化して `<img src="data:image/png;base64,...">`。
4. **出力**
   - **Artifact 公開** (既定): このテンプレートは doctype/html/head/body を持たない**フラグメント**なので、そのまま Artifact ツールに渡せる。**先に `artifact-design` スキルを読む** (Artifact ツールの要件)。`favicon` は端末系の絵文字 (例 `🖥️` `⚡`) を渡す。
   - **ローカル HTML** で欲しい場合はファイルパスを渡す。WSL なので `file:///...` と `file://wsl.localhost/Ubuntu/...` の両方を返す。
5. **操作確認**: `← → / Space / PageUp・Down` でスライド移動できる。Artifact 公開後や画面確認が要る場合は Playwright で最低限の表示・キー操作を確認する。

## コンポーネント早見表

すべて `template.html` に実例がある。クラス名だけ抜粋:

- **ウィンドウ枠**: `.slide-inner` に `.win-bar`(信号機ドット `.dot.r/.y/.g` + `.win-title`) / `.win-body` / `.status` の3段
- **タイトル**: `.win-body` に `.boot`(プロンプト行) + `.title-main`(+`.cursor` 点滅) + `.title-sub`
- **見出し**: `<h2 class="head">…</h2>` (`❯` は ::before で自動付与)
- **ツリー箇条書き**: `<ul class="tree">` に `<li>` をネスト。結線は CSS 自動。コード語は `.kw`/`.fn`/`.str`/`.num`/`.com`/`.dim` で着色
- **コード**: `.code-wrap` に `.code-tab`(ファイル名) + `<pre class="code">`。中は色 span で装飾
- **端末出力**: `<pre class="term">` に ASCII テーブルを生貼り。プロンプト行は `<span class="p">`
- **2カラム**: `<div class="cols">` に子2つ
- **画像**: `<figure class="figure">` → `<img>` + `<figcaption>` (出典は `<a class="link">`)
- **ステータスライン**: `.status` に `.seg--mode` / `.seg--branch` / `.seg--file` / `.seg--spring`(伸縮) / `.seg--info` / `.seg--count`

## 注意

- **等幅フォントが世界観の核**。日本語も等幅系にフォールバックさせる (テンプレの `--mono` を触らない)。
- テキスト量が多いと 16:9 からはみ出る。`cqw`/`cqh` 基準なので**1スライドの情報量を絞る**のが正解 (元スタイルも余白が多い)。
- 端末出力の ASCII テーブルは**実際のコマンド出力を貼る**のが最も本物らしい。整形しすぎない。
- powerline 矢印・信号機ドットは **CSS だけで描画**している (Nerd Font に依存しない) ので Artifact でもそのまま出る。
- グラフや集計の可視化が主目的なら、このスキルではなく `drilldown-report` / `timeseries-report` を使う。
