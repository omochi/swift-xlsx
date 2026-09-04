[English](README.md) | [日本語](README.ja.md)

# swift-xlsx

`swift-xlsx` は `.xlsx` ファイルを読み書きするための Swift ライブラリです。OOXML の spreadsheet 形式、その下にある OPC package 構造、そして workbook / worksheet / cell / formula / style / validation / protection を扱う小さな Swift API に焦点を当てています。

このプロジェクトはまだ初期段階ですが、ライブラリとして使える形を目指しています。サンプルは実際の Swift コードから生成され、可能な範囲で package part を保持し、XML / OPC 層もデバッグしやすい形で残しています。

## 目標

実装では、application code から使いやすい interface、理解しやすいシンプルな内部コード、workbook の読み書きを高速に行うための効率的な動作を重視しています。

## インストール

`swift-xlsx` を package dependency に追加し、`XLSX` product に依存してください。

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/omochi/swift-xlsx.git", branch: "main"),
],
targets: [
    .target(
        name: "YourTarget",
        dependencies: [
            .product(name: "XLSX", package: "swift-xlsx"),
        ]
    ),
]
```

## サンプル workbook を試す

このライブラリが現在どのような workbook を書けるかを見る一番早い方法は、サンプル workbook を生成して `example.xlsx` を開くことです。

```console
swift run xlsx-tool example-documents temp
open temp/example.xlsx
```

このサンプルを生成しているコードは [`Sources/XLSXExamples/XLExampleDocuments.swift`](Sources/XLSXExamples/XLExampleDocuments.swift) にあります。数式、列幅、数値形式、フォント、塗りつぶし、罫線、データ validation、パスワード付き sheet protection、sheet の非表示状態を示す sheet を生成します。

## クイックスタート

document を作り、worksheet を追加し、いくつかの cell に値を書いて `.xlsx` ファイルとして保存します。

```swift
import Foundation
import XLSX

let document = XLDocument()
let worksheet = try document.workbook.appendWorksheet(name: "Sheet1")

worksheet.cell(row: 1, column: 1).value = .text("Hello")
worksheet.cell(row: 1, column: 2).value = .number(42)
worksheet.cell(row: 2, column: 2).formula = .regular("SUM(B1:B1)")

try document.save(to: URL(fileURLWithPath: "example.xlsx"))
```

既存 workbook は `XLDocument.open(url:)` で開き、workbook や worksheet の handle から編集して、再度保存できます。

workbook にまだ library が model 化していない機能が含まれている場合でも、`swift-xlsx` は可能な範囲で元の package part や未知の XML content を保持し、未対応機能もある程度 round-trip できるようにしています。

```swift
import Foundation
import XLSX

let url = URL(fileURLWithPath: "input.xlsx")
let document = try XLDocument.open(url: url)
let worksheet = try document.workbook.appendWorksheet(name: "Generated")

worksheet.cell(row: 1, column: 1).value = .text("Created by swift-xlsx")

try document.save(to: URL(fileURLWithPath: "output.xlsx"))
```

## 機能の対応状況

下の表では、大まかな互換性レベルではなく具体的な機能を並べています。「対応」は public API または内部で使われている読み書き経路がある機能、「未対応」は現時点で library API として model 化していない機能を表します。

| 領域 | 対応 | 未対応 |
| --- | --- | --- |
| Workbook | 作成、オープン、保存 | 計算 engine、暗号化、macro |
| Worksheet | sheet の追加、削除、改名、非表示、既存 sheet の読み込み、上端の行と左端の列の固定 | Chart sheet、dialog sheet |
| Cell | Shared string と inline string の plain text と rich text、ふりがなの run と property、数値、真偽値、日付、数式、数式の cache 値 | コメント、hyperlink |
| Row | Sparse な row と cell の storage | 行の高さ、grouping、行の非表示 |
| Column | 列幅、列の style、列の非表示 | Grouping |
| Number format | 組み込み format、custom format string | Locale を考慮した完全な format 評価 |
| Font | 太字、斜体、取り消し線、size、名前、色 | Theme font、下線の variant、垂直位置 |
| Fill | Pattern fill、型付きの色 | Gradient fill、theme color の解決 |
| Border | 各辺と対角線の border、line style | Theme color の解決、高度な border semantics |
| Cell format | Cell 単位の style、style collection、named cell style、protection | Conditional formatting、完全な style 継承 |
| Data validation | List validation、validation range | Validation option の完全な対応 |
| Sheet protection | Sheet protection flag、password hash 情報、SHA-512 password hash の生成 | Workbook protection、legacy password hash の生成 |
| Package structure | OPC relationship、content type、shared string、未知の file の保持 | Digital signature、custom XML extension の型付き API |
| Media と object | - | 画像、drawing、chart、pivot table、table、slicer |

## 設計メモ

`swift-xlsx` は FoundationXML を避け、XML parsing に [`xylem`](https://github.com/compnerd/xylem) を使っています。これは FoundationXML の bug を避け、package 全体で XML の扱いを予測しやすくするための意図的な選択です。

ZIP 層は Apple 固有の compression API ではなく、小さな system library target 経由で zlib を使います。file format の層を portable かつ明示的に保つことを目指しています。

## Command line tool

この package には `xlsx-tool` も含まれています。

`example-documents` は現在の library API を示すサンプル workbook を生成します。

```console
swift run xlsx-tool example-documents temp
```

`extract` と `pack` は、この library の開発作業を補助するための command です。`.xlsx` を package file 群へ展開し、展開済み package directory から `.xlsx` を作り直します。

```console
swift run xlsx-tool extract input.xlsx --output extracted
swift run xlsx-tool pack extracted --output output.xlsx
```

## 必要な環境

この package は SwiftPM で build され、現在は Swift 6.3 を対象にしています。macOS と Linux を support し、`.xlsx` の ZIP package を読み書きするために zlib が必要です。

## ライセンス

MIT ライセンスです。
