# AGENTS.md

## 言語

このリポジトリでは、ユーザー向けの説明、設計メモ、実装計画、ソースコード内のコメントは日本語で書く。

## ドキュメント

- `README.md`
  - 公開向けの説明を書く。
  - ライブラリの対応状況は `Feature Status` セクションに書く。機能を追加・削除・変更したときは、必要に応じてこの表も更新する。
- `docs/design.md`
  - 現在の設計方針や実装上の判断を書く。
  - XML/OPC の扱い、storage と handle の分担、namespace prefix の扱いなど、実装時に守る設計メモとして使う。

## ソース構成

- 原則として 1 file 1 type にする。
- 型名は、属する領域が分かる prefix を付ける。OPC 領域の型は `OPC` prefix を付ける。
- memberwise initializer が必要な型では、可能な限り `@MemberwiseInit(.public)` を使う。
- struct の stored property は、健全性条件を守るために固定する必要がある場合を除き、`let` ではなく `var` にする。
- Swift の型メンバーは、先頭から inner type、initializer、stored property の順に定義する。inner type は initializer より前に置く。
- public API を extension で追加する場合は、`public extension` ではなく無指定の `extension` にし、公開する member 側に `public` を付ける。
- 既存 API との互換性維持は優先しない。設計を変更するときは、互換用の typealias や wrapper API を残さず、利用側を新しい設計へ更新する。

## プロトコル表記

- protocol composition は、可能な限り `&` でつなげて書く。
- `Sendable` のようなプリミティブな性質を表す protocol を先に書く。
- 型宣言の conformance list など、Swift 構文上 `&` が使えない場所ではカンマ区切りにし、同じ順序規則に従う。

## import 順

- `MemberwiseInit` を使うファイルでは、`import MemberwiseInit` を `import Foundation` より先に書く。
- その他の import は、標準ライブラリ・システム module・外部依存の関係が読みやすくなる順に整理する。

## SwiftPM 実行

- `swift run` を実行するときは、SwiftPM 側の sandbox を無効にするため `--disable-sandbox` を付ける。

## XML 名前空間

- XML namespace は prefix ではなく URI を正として扱う。
- namespace URI から prefix を解決する処理は、対象ノードが親ノードへ接続された後に行う。
- `XMLElement.setAttribute(name:namespaceURI:value:)` や `namespacePrefix(for:)` は、対象要素から親方向へ namespace 宣言を探す。新しく作った detached element に対して、親へ `appendChild` / `insertChild` する前に呼ばない。
- `XMLUtils.patchChildren` の `makeElement` で作る要素は、`children` setter に渡されるまで親に接続されていない。ここで namespace 付き属性を書く必要がある場合は、先に親側で prefix を確保し、その prefix を渡して `XMLName(prefix:name:)` を作るか、要素を親へ接続してから URI 解決を行う。
- 既存 prefix は可能な限り保持する。希望する prefix が別 URI で使われている場合は既存定義を壊さず、`r2`, `r3` のように空いている prefix を使う。

## 対応プラットフォーム

- macOS と Linux の両方で動く実装にする。
- ZIP の展開には Apple 固有の `Compression` framework ではなく `libz` を使う。
