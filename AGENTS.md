# AGENTS.md

## 言語

このリポジトリでは、ユーザー向けの説明、設計メモ、仕様書は日本語で書く。

## ドキュメント

- `docs/spec.md`
  - ライブラリの仕様を書く。
  - 決まったことだけを書く。
  - 未決定の案、将来のアイデア、調査メモはここに混ぜない。

- `docs/design-notes.md`
  - 検討中の設計案、未決定事項、将来的なアイデア、関連情報を書く。
  - `docs/spec.md` に移す前の作業メモとして使う。
  - 決定した内容は、必要に応じて `docs/spec.md` に移す。

## ソース構成

- 原則として 1 file 1 type にする。
- 型名は、属する領域が分かる prefix を付ける。OPC 領域の型は `OPC` prefix を付ける。
- memberwise initializer が必要な型では、可能な限り `@MemberwiseInit(.public)` を使う。
- struct の stored property は、健全性条件を守るために固定する必要がある場合を除き、`let` ではなく `var` にする。
- Swift の型メンバーは、先頭から inner type、initializer、stored property の順に定義する。inner type は initializer より前に置く。
- public API を extension で追加する場合は、`public extension` ではなく無指定の `extension` にし、公開する member 側に `public` を付ける。

## プロトコル表記

- protocol composition は、可能な限り `&` でつなげて書く。
- `Sendable` のようなプリミティブな性質を表す protocol を先に書く。
- 型宣言の conformance list など、Swift 構文上 `&` が使えない場所ではカンマ区切りにし、同じ順序規則に従う。

## import 順

- `MemberwiseInit` を使うファイルでは、`import MemberwiseInit` を `import Foundation` より先に書く。
- その他の import は、標準ライブラリ・システム module・外部依存の関係が読みやすくなる順に整理する。

## 対応プラットフォーム

- macOS と Linux の両方で動く実装にする。
- ZIP の展開には Apple 固有の `Compression` framework ではなく `libz` を使う。
