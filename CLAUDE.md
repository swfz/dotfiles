# CLAUDE.md

swfz の dotfiles。シェル・エディタ・ターミナルの設定と、それらを各マシンへ配る ansible、自作の CLI・スクリプトを置いている。

## ディレクトリ構成

| パス | 役割 |
|---|---|
| `ansible/` | 環境構築の playbook(`mac.yml` / `ubuntu.yml` / `codespace.yml`)と roles。dotfiles の symlink 配置(`--tags deploy`)もここで行う。ansible / ansible-lint / yamllint は `pyproject.toml` + `uv.lock` で固定 |
| `bin/` | 自作スクリプト。PATH に通して使う。個別の説明は `bin/README.md` |
| `claude/` | Claude Code / Codex に配布するアセット(skills, rules, statusline など)。このリポジトリ用の指示ではない。`bin/ccsync.sh link` で `~/.claude`(skills は `~/.agents/skills` にも)へ symlink される |
| `codex/` | Codex 固有のアセット(`codex/agents/*.toml`)。`bin/ccsync.sh` で配布される |
| `config/` | `~/.config` 配下に置く設定(mise, nvim, starship, bat, ssh, apm) |
| `src/rdpick/` | Raindrop.io の検索結果を整形出力する Go 製 CLI。詳細は `src/rdpick/README.md` |
| `tests/` | シェルスクリプトのテスト(`tests/ccsync_test.sh`, `tests/tmux_layout_test.sh`) |
| `vimrc/` | `.vimrc` から読み込む設定とプラグイン設定 |
| `zsh/` | `.zshrc` から読み込む alias / 関数 / hooks / 環境変数 |
| `hooks/` | git hooks。`post-merge` で `ccsync.sh link` を自動実行する |
| `.github/workflows/` | CI(下記) |

ルート直下の `.zshrc` / `.vimrc` / `.tmux.conf` などは ansible の deploy タグでホームディレクトリへ symlink される。

## コマンド

### テスト

```sh
bash tests/ccsync_test.sh
bash tests/statusline_test.sh
bash tests/claude_session_test.sh
bash tests/tmux_layout_test.sh  # bin/tm, bin/tms。yq と jq が必要
(cd src/rdpick && go vet ./... && go test ./...)
```

### lint / フォーマット

```sh
# ansible(uv で固定したバージョンを使う)
cd ansible
uv sync --locked
uv run yamllint .
uv run ansible-lint mac.yml ubuntu.yml codespace.yml

# Python の型チェック(リポジトリルートで実行。対象は pyproject.toml の [tool.mypy] files)
uv sync --locked
uv run mypy

# Go(バージョンは CI と同じ v2.14.0)
cd src/rdpick
mise x golangci-lint@2.14.0 -- golangci-lint run ./...

# シェルスクリプト(設定は .editorconfig。CI と同じ v3.14.1)
git ls-files -z | xargs -0 mise x shfmt@3.14.1 -- shfmt -f | xargs mise x shfmt@3.14.1 -- shfmt --apply-ignore -d
```

### rdpick のビルド

```sh
cd src/rdpick
go build -o ../../bin/rdpick .
```

実行には環境変数 `RAINDROP_TOKEN`(Raindrop の Test token)が必要。

### セットアップ(環境を変更するので確認なしに実行しない)

```sh
cd ansible
ansible-playbook -i hosts -c local mac.yml --extra-vars "user='$(whoami)'"                        # mac
ansible-playbook -i localhost, -c local ubuntu.yml --extra-vars "user='$(whoami)'" --ask-become-pass  # ubuntu
ansible-playbook -i localhost, -c local ubuntu.yml --extra-vars "user='$(whoami)'" --ask-become-pass --tags deploy  # symlink だけ
```

- `setup.sh` は GitHub Codespaces 用。apt で ansible を入れて `codespace.yml` を流し、既存の `~/.zshrc` を `~/.zshrc.bak` に退避する
- Claude Code / Codex のアセット配布は `bin/ccsync.sh link`(README の「Claude Code / Codex asset sync」参照)

## 環境変数

マシン固有の値は `~/.localrc` に書く(`.zshrc` から読み込まれる)。項目と用途は `.localrc.sample` を参照。

## CI

| workflow | トリガー | 検証内容 |
|---|---|---|
| `test.yml` | master への push / PR | `ccsync`(tests/ccsync_test.sh)、`statusline`(tests/statusline_test.sh)、`claude-session`(tests/claude_session_test.sh)、`tmux-layout`(tests/tmux_layout_test.sh)、`shfmt`(全シェルスクリプトの差分)、`rdpick`(go vet / go test / golangci-lint)、`python-typecheck`(mypy) |
| `ci-ansible.yml` | `ansible/**` `config/mise/**` 変更時の push / PR、週次 | yamllint / ansible-lint、ubuntu で tag ごと(deploy / init / tool / mise)と mac で playbook を実際に実行 |
| `update-versions.yml` | 週次 | jo / zsh の新バージョンを検知して `ansible/versions_vars.yml` 更新の PR を作る |
