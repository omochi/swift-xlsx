[English](README.md) | [日本語](README.ja.md)

# swift-xlsx

`swift-xlsx` is a Swift library for reading, editing, and writing `.xlsx` files. It focuses on the OOXML spreadsheet format, the OPC package structure underneath it, and a small Swift API for workbook, worksheet, cell, formula, style, validation, and protection data.

The project is still early, but it already aims to be useful as a library: examples are generated from real Swift code, package parts are preserved where possible, and the XML/OPC layers are kept visible enough to make the implementation debuggable.

## Goals

The implementation is guided by three priorities: an interface that is easy to use from application code, simple internal code that stays understandable, and efficient behavior for fast workbook reading and writing.

## Installation

Add `swift-xlsx` to your package dependencies and depend on the `XLSX` product.

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

```console
swift run xlsx-tool example-documents temp
open temp/example.xlsx
```

The code that creates this sample is in [`Sources/XLSXExamples/XLExampleDocuments.swift`](Sources/XLSXExamples/XLExampleDocuments.swift). It writes sheets for cell values, formulas, column settings, number formats, fonts, fills, borders, data validation, cell styles, sheet and cell protection, freeze panes, and hidden and very hidden sheet states. The complete coverage matrix and manual Microsoft Excel checklist are in [`docs/example-workbook.md`](docs/example-workbook.md) (Japanese).

## Quick Start

Create a document, append a worksheet, write a few cells, and save it as an `.xlsx` file.

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

When a workbook contains features that are not modeled by the library yet, `swift-xlsx` still tries to keep the original package parts and unknown XML content intact where possible, so unsupported features can round-trip to some extent.

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

| Area | Supported | Not Supported |
| --- | --- | --- |
| Workbooks | Create, open, save | Calculation engine, encryption, macros |
| Worksheets | Add, remove, rename, mark sheets as hidden or very hidden, read existing sheets, freeze top rows and left columns | Chartsheets, dialog sheets |
| Cells | Plain and rich text in shared and inline strings, phonetic runs and properties, numbers, booleans, dates, errors, regular and shared formulas, cached formula values | Comments, hyperlinks, typed array and data-table formula editing |
| Rows | Sparse row and cell storage | Row heights, grouping, hidden rows |
| Columns | Column widths, column styles, hidden and best-fit columns, outline level, collapsed and phonetic attributes | High-level grouping operations |
| Number formats | Built-in formats, custom format strings | Full locale-aware format evaluation |
| Fonts | Bold, italic, strike, condense, extend, outline, shadow, size, name, typed color | Typed theme fonts, underline variants, vertical alignment |
| Fills | Pattern fills, typed colors | Gradient fills, theme color resolution |
| Borders | Side borders, diagonal borders, line styles | Theme color resolution, advanced border semantics |
| Cell formats | Cell-level styles, style collection, named cell styles, protection | Conditional formatting, full style inheritance |
| Data validation | Whole number, decimal, list, date, time, text length, and custom validation; validation ranges; prompt and error options | Full validation option coverage |
| Sheet protection | Sheet protection flags, password hash info, SHA-512 password hash generation | Workbook protection, legacy password hash generation |
| Package structure | OPC relationships, content types, shared strings, unknown file preservation | Digital signatures, typed APIs for custom XML extensions |
| Media and objects | - | Images, drawings, charts, pivot tables, tables, slicers |

## Design Notes

`swift-xlsx` avoids FoundationXML and uses [`xylem`](https://github.com/compnerd/xylem) for XML parsing. This is a deliberate choice to avoid FoundationXML bugs and to keep XML handling predictable across the package.

The ZIP layer uses zlib through a small system library target instead of Apple-only compression APIs. The goal is to keep the file format layers portable and explicit.

## Command Line Tool

The package also includes `xlsx-tool`.

`example-documents` generates sample workbooks that demonstrate the current library API.

```console
swift run xlsx-tool example-documents temp
```

`extract` and `pack` are development helpers for this library. They expand an `.xlsx` file into package files and rebuild an `.xlsx` file from an extracted package directory.

```console
swift run xlsx-tool extract input.xlsx --output extracted
swift run xlsx-tool pack extracted --output output.xlsx
```

## Requirements

The package is built with SwiftPM and currently targets Swift 6.3. It supports macOS and Linux, and requires zlib to read and write `.xlsx` ZIP packages.

## License

MIT
