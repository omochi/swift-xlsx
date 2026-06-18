# swift-xlsx

`swift-xlsx` is a Swift library for reading, editing, and writing `.xlsx` files. It focuses on the OOXML spreadsheet format, the OPC package structure underneath it, and a small Swift API for workbook, worksheet, cell, formula, style, and validation data.

`swift-xlsx` は `.xlsx` ファイルを読み書きするための Swift ライブラリです。OOXML の spreadsheet 形式、その下にある OPC package 構造、そして workbook / worksheet / cell / formula / style / validation を扱う小さな Swift API に焦点を当てています。

The project is still early, but it already aims to be useful as a library: examples are generated from real Swift code, package parts are preserved where possible, and the XML/OPC layers are kept visible enough to make the implementation debuggable.

このプロジェクトはまだ初期段階ですが、ライブラリとして使える形を目指しています。サンプルは実際の Swift コードから生成され、可能な範囲で package part を保持し、XML/OPC 層もデバッグしやすい形で残しています。

## Installation

Add `swift-xlsx` to your package dependencies and depend on the `XLSX` product.

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

## Try the Example Workbook

The fastest way to see what the library currently writes is to generate the example workbooks and open `example.xlsx`.

このライブラリが現在どのような workbook を書けるかを見る一番早い方法は、example workbook を生成して `example.xlsx` を開くことです。

```console
swift run xlsx-tool example-documents temp
open temp/example.xlsx
```

The code that creates this sample is in [`Sources/XLSXExamples/XLExampleDocuments.swift`](Sources/XLSXExamples/XLExampleDocuments.swift). It writes sheets for formulas, column widths, number formats, fonts, fills, borders, and data validation.

このサンプルを生成しているコードは [`Sources/XLSXExamples/XLExampleDocuments.swift`](Sources/XLSXExamples/XLExampleDocuments.swift) にあります。数式、列幅、数値形式、フォント、塗りつぶし、罫線、データ validation の sheet を生成します。

## Quick Start

Create a document, append a worksheet, write a few cells, and save it as an `.xlsx` file.

document を作り、worksheet を追加し、いくつかの cell に値を書いて `.xlsx` ファイルとして保存します。

```swift
import Foundation
import XLSX

let document = XLDocument()
let worksheet = try document.workbook.appendWorksheet(name: "Sheet1")

worksheet.cell(row: 1, column: 1).value = .string("Hello")
worksheet.cell(row: 1, column: 2).value = .number(42)
worksheet.cell(row: 2, column: 2).formula = .regular("SUM(B1:B1)")

try document.save(to: URL(fileURLWithPath: "example.xlsx"))
```

Existing workbooks can also be opened through `XLDocument.open(url:)`, edited through the workbook and worksheet handles, and saved again.

既存 workbook は `XLDocument.open(url:)` で開き、workbook や worksheet の handle から編集して、再度保存できます。

```swift
import Foundation
import XLSX

let url = URL(fileURLWithPath: "input.xlsx")
let document = try XLDocument.open(url: url)
let worksheet = try document.workbook.appendWorksheet(name: "Generated")

worksheet.cell(row: 1, column: 1).value = .string("Created by swift-xlsx")

try document.save(to: URL(fileURLWithPath: "output.xlsx"))
```

## Feature Status

The supported surface is intentionally small for now. The table below describes the current direction rather than a complete Excel compatibility claim.

現在の対応範囲は意図的に小さくしています。下の表は Excel 全機能への互換性を主張するものではなく、今の実装の方向性を示すものです。

| Area | Status |
| --- | --- |
| Create and save workbooks | Supported |
| Open existing workbooks | Supported |
| Worksheets | Partial |
| Cell strings and numbers | Partial |
| Formulas | Partial |
| Column widths | Partial |
| Number formats | Partial |
| Fonts, fills, and borders | Partial |
| Data validation | Partial |
| Shared strings | Supported |
| Charts, images, pivot tables, macros | Not supported |

## Design Notes

`swift-xlsx` avoids FoundationXML and uses [`xylem`](https://github.com/compnerd/xylem) for XML parsing. This is a deliberate choice to avoid FoundationXML bugs and to keep XML handling predictable across the package.

`swift-xlsx` は FoundationXML を避け、XML parsing に [`xylem`](https://github.com/compnerd/xylem) を使っています。これは FoundationXML の bug を避け、package 全体で XML の扱いを予測しやすくするための意図的な選択です。

The ZIP layer uses zlib through a small system library target instead of Apple-only compression APIs. The goal is to keep the file format layers portable and explicit.

ZIP 層は Apple 固有の compression API ではなく、小さな system library target 経由で zlib を使います。file format の層を portable かつ明示的に保つことを目指しています。

## Command Line Tool

The package also includes `xlsx-tool`, a small development and inspection tool for working with `.xlsx` files.

この package には `.xlsx` ファイルを扱うための小さな開発・確認用 tool として `xlsx-tool` も含まれています。

```console
swift run xlsx-tool example-documents temp
swift run xlsx-tool extract input.xlsx --output extracted
swift run xlsx-tool pack extracted --output output.xlsx
```

`example-documents` generates sample workbooks, `extract` expands an `.xlsx` file into its package files, and `pack` builds an `.xlsx` file from an extracted package directory.

`example-documents` は sample workbook を生成し、`extract` は `.xlsx` を package file 群へ展開し、`pack` は展開済み package directory から `.xlsx` を作ります。

## Requirements

The package is built with SwiftPM and currently targets Swift 6.3. It requires zlib to read and write `.xlsx` ZIP packages.

この package は SwiftPM で build され、現在は Swift 6.3 を対象にしています。`.xlsx` の ZIP package を読み書きするために zlib が必要です。
