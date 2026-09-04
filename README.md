# swift-xlsx

`swift-xlsx` is a Swift library for reading, editing, and writing `.xlsx` files. It focuses on the OOXML spreadsheet format, the OPC package structure underneath it, and a small Swift API for workbook, worksheet, cell, formula, style, validation, and protection data.

`swift-xlsx` は `.xlsx` ファイルを読み書きするための Swift ライブラリです。OOXML の spreadsheet 形式、その下にある OPC package 構造、そして workbook / worksheet / cell / formula / style / validation / protection を扱う小さな Swift API に焦点を当てています。

The project is still early, but it already aims to be useful as a library: examples are generated from real Swift code, package parts are preserved where possible, and the XML/OPC layers are kept visible enough to make the implementation debuggable.

このプロジェクトはまだ初期段階ですが、ライブラリとして使える形を目指しています。サンプルは実際の Swift コードから生成され、可能な範囲で package part を保持し、XML/OPC 層もデバッグしやすい形で残しています。

## Goals

The implementation is guided by three priorities: an interface that is easy to use from application code, simple internal code that stays understandable, and efficient behavior for fast workbook reading and writing.

実装では、application code から使いやすい interface、理解しやすいシンプルな内部コード、workbook の読み書きを高速に行うための効率的な動作を重視しています。

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

The code that creates this sample is in [`Sources/XLSXExamples/XLExampleDocuments.swift`](Sources/XLSXExamples/XLExampleDocuments.swift). It writes sheets for formulas, column widths, number formats, fonts, fills, borders, data validation, password-protected sheet protection, and hidden sheet state.

このサンプルを生成しているコードは [`Sources/XLSXExamples/XLExampleDocuments.swift`](Sources/XLSXExamples/XLExampleDocuments.swift) にあります。数式、列幅、数値形式、フォント、塗りつぶし、罫線、データ validation、パスワード付き sheet protection、シートの非表示状態の sheet を生成します。

## Quick Start

Create a document, append a worksheet, write a few cells, and save it as an `.xlsx` file.

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

Existing workbooks can also be opened through `XLDocument.open(url:)`, edited through the workbook and worksheet handles, and saved again.

既存 workbook は `XLDocument.open(url:)` で開き、workbook や worksheet の handle から編集して、再度保存できます。

When a workbook contains features that are not modeled by the library yet, `swift-xlsx` still tries to keep the original package parts and unknown XML content intact where possible, so unsupported features can round-trip to some extent.

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

## Feature Status

The table below lists concrete features rather than broad compatibility levels. `Supported` means the library has a public or internally exercised path for reading and/or writing that feature. `Not Supported` means the feature is not currently modeled as a library API.

下の表では、大まかな互換性レベルではなく具体的な機能を並べています。`Supported` は public API または内部で使われている読み書き経路がある機能、`Not Supported` は現時点で library API として model 化していない機能を表します。

| Area | Supported | Not Supported |
| --- | --- | --- |
| Workbooks | Create, open, save | Calculation engine, encryption, macros |
| Worksheets | Add, remove, rename, hide sheets, read existing sheets, freeze top rows and left columns | Chartsheets, dialog sheets |
| Cells | Plain and rich text in shared and inline strings, phonetic runs and properties, numbers, booleans, dates, formulas, cached formula values | Comments, hyperlinks |
| Rows | Sparse row and cell storage | Row heights, grouping, hidden rows |
| Columns | Column widths, column styles, hidden columns | Grouping |
| Number formats | Built-in formats, custom format strings | Full locale-aware format evaluation |
| Fonts | Bold, italic, strike, size, name, color | Theme fonts, underline variants, vertical alignment |
| Fills | Pattern fills, typed colors | Gradient fills, theme color resolution |
| Borders | Side borders, diagonal borders, line styles | Theme color resolution, advanced border semantics |
| Cell formats | Cell-level styles, style collection, named cell styles, protection | Conditional formatting, full style inheritance |
| Data validation | List validation, validation ranges | Full validation option coverage |
| Sheet protection | Sheet protection flags, password hash info, SHA-512 password hash generation | Workbook protection, legacy password hash generation |
| Package structure | OPC relationships, content types, shared strings, unknown file preservation | Digital signatures, typed APIs for custom XML extensions |
| Media and objects | - | Images, drawings, charts, pivot tables, tables, slicers |

## Design Notes

`swift-xlsx` avoids FoundationXML and uses [`xylem`](https://github.com/compnerd/xylem) for XML parsing. This is a deliberate choice to avoid FoundationXML bugs and to keep XML handling predictable across the package.

`swift-xlsx` は FoundationXML を避け、XML parsing に [`xylem`](https://github.com/compnerd/xylem) を使っています。これは FoundationXML の bug を避け、package 全体で XML の扱いを予測しやすくするための意図的な選択です。

The ZIP layer uses zlib through a small system library target instead of Apple-only compression APIs. The goal is to keep the file format layers portable and explicit.

ZIP 層は Apple 固有の compression API ではなく、小さな system library target 経由で zlib を使います。file format の層を portable かつ明示的に保つことを目指しています。

## Command Line Tool

The package also includes `xlsx-tool`.

この package には `xlsx-tool` も含まれています。

`example-documents` generates sample workbooks that demonstrate the current library API.

`example-documents` は現在の library API を示す sample workbook を生成します。

```console
swift run xlsx-tool example-documents temp
```

`extract` and `pack` are development helpers for this library. They expand an `.xlsx` file into package files and rebuild an `.xlsx` file from an extracted package directory.

`extract` と `pack` は、この library の開発作業を補助するための command です。`.xlsx` を package file 群へ展開し、展開済み package directory から `.xlsx` を作り直します。

```console
swift run xlsx-tool extract input.xlsx --output extracted
swift run xlsx-tool pack extracted --output output.xlsx
```

## Requirements

The package is built with SwiftPM and currently targets Swift 6.3. It supports macOS and Linux, and requires zlib to read and write `.xlsx` ZIP packages.

この package は SwiftPM で build され、現在は Swift 6.3 を対象にしています。macOS と Linux を support し、`.xlsx` の ZIP package を読み書きするために zlib が必要です。

## License

MIT

MIT ライセンスです。
