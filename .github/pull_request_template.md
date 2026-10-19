## 概要

<!-- 何をなぜ変えたか -->

## 関連 Issue

<!-- Closes #123 -->

## 確認したこと

<!-- 実行したテスト・lint コマンドと結果。該当するものを残す -->

- [ ] `bash tests/ccsync_test.sh`
- [ ] `cd src/rdpick && go vet ./... && go test ./...`
- [ ] `cd ansible && uv run yamllint . && uv run ansible-lint mac.yml ubuntu.yml codespace.yml`
