---
name: typescript
description: swfzのTypeScript/JavaScriptコーディングスタイルガイド。TS/JS/React/Denoのコード生成・レビュー時に参照する。
paths:
  - "**/*.ts"
  - "**/*.tsx"
  - "**/*.js"
  - "**/*.jsx"
  - "**/*.mjs"
  - "**/*.cjs"
  - "**/package.json"
  - "**/tsconfig*.json"
---

# swfz TypeScript / JavaScript スタイルガイド

TypeScript/JavaScript (React/Deno含む) のコードを書く・レビューするときの swfz の指針をまとめたルール集。

## 共通の哲学

- **実用性重視**: 複雑なデザインパターンより動くコードを優先
- **プロジェクト規模に応じた設計**: 小規模ツールはフラット構造、大規模は層状構造
- **テスト重視**: Vitest + Testing Library を基本
- **日本語を自然に使う**: コメントに日本語を使う場面がある
- **エラーハンドリング**: 必要最低限だが的確に
- **不要な抽象化を避ける**: 3行の重複コードは許容。過度なDRYより可読性

---

## 基本設定

- **ESM** (`"type": "module"`)
- **strict: true** を必ず設定
- **pnpm** をパッケージマネージャーとして使用
- **Prettier**: `singleQuote: true`, `trailingComma: "all"`, `printWidth: 120`
- **moduleResolution**: `"bundler"`

## 型定義

- `interface` を優先（`type` はUnion型などで使用）
- ユーティリティ型: `Record<string, any>`, `Partial<T>`
- `as any` は限定的に
- `import type { ... }` で型インポートを分離

## フレームワーク選好

- フロントエンド: **React 18+** + **React Router v6** + **TailwindCSS** + **React Query (TanStack Query)**
- バックエンド: **Hono**（Cloudflare Workers）
- ランタイム検証: **Zod**
- ビルド: **Vite**（フロントエンド）、**esbuild**（Chrome拡張）、**Wrangler**（Workers）
- スクリプト: **Deno**（`jsr:@std/*` を活用）

## コンポーネント設計

- 関数コンポーネント + Hooks（クラスコンポーネントは使わない）
- カスタムHooksで複雑なロジックを分離（`usePageVisibility`, `useTimer` 等）
- Context APIでprop drilling回避
- `useRef` でタイマーIDなどのミュータブル値を保持

## APIクライアント

- Serviceオブジェクトパターン（`export const togglApi = { async getCurrentTimer() {...} }`)
- クラスベースのクライアントにはキャッシュ機能を内蔵
- ジェネリック型でレスポンス型を厳密に定義
- カスタム `ApiError` クラスでHTTPステータスを保持

## 状態管理

- React Query中心。サーバーステートとUIステートを明確に分離
- 省API型設計（ページ非表示時はポーリング停止、キャッシュ活用）
- `staleTime`, `gcTime` を適切に設定

## 非同期

- `async/await` を優先
- React Queryの `useMutation` で `onSuccess`/`onError` コールバック

## 命名

- 変数・関数: `camelCase`
- 定数: `UPPER_SNAKE_CASE`（オブジェクト形式 `const STALE_TIME = { CURRENT_TIMER: ... }`）
- ハンドラ: `handleXxx` / `onXxx`
- Hooks: `useXxx`

## インポート順序

1. 外部ライブラリ
2. ローカルモジュール（型: `import type { ... }`）
3. ローカルモジュール（値）
4. スタイルシート

## テスト

- **Vitest** + `@testing-library/react`
- `renderHook` でカスタムHooksをテスト
- Mockクライアント・Mockデータを分離ファイルで管理（`*-mock-client.ts`, `*-mock-data.ts`）

## ディレクトリ構造

```
src/
├── components/    # React コンポーネント（機能別サブフォルダ）
├── hooks/         # カスタムHooks
├── services/      # APIクライアント
├── types/         # 型定義
├── middleware/     # ミドルウェア
└── utils/         # ユーティリティ
```

## セキュリティ

- トークンはログ出力時に `[REDACTED]` で隠す
- CORS設定を明示的に記述
- 認証ヘッダは `Basic` + base64エンコード

## コメント

- インラインコメントは英語
- JSDocは実用的な場面のみ
- デバッグログ: `console.log('[PREFIX]', ...)` パターン

## コードレビュー時の観点

1. `strict: true` が有効か
2. サーバーステートがReact Query経由で管理されているか
3. 不要な `as any` がないか
4. カスタムHooksでロジックが適切に分離されているか
5. pnpm以外のパッケージマネージャーを使っていないか
6. インポートが型と値で分離されているか
