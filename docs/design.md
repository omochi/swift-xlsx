# 設計メモ

## OPC XML file の扱い

OPC package 内の XML file は、内容の性質に応じて扱いを分ける。

完全に型付けした情報だけで扱える file は、読み込み時に XML から Swift の値へ変換し、保存時にはその値から XML を再生成する。未知の要素や属性を保持することは目的にしない。

一方で、未対応の情報を壊したくない file は、読み込み時の original XML を保持する。保存時には original XML を clone し、ライブラリが所有する既知の情報だけを差分更新する。未知の要素、未知の属性、既存の namespace prefix は可能な限り保持する。

例として workbook file は、シート一覧を `XLWorkbookFileSheet` として型付けして扱うが、workbook XML 全体を完全に再生成しない。既存の `<sheet>` 要素は `sheetId` で同一性を判定し、持っているシート情報だけを上書きまたは追加する。

## ストレージレイヤーとハンドルレイヤー

Excel の workbook / worksheet / row / cell は、永続化するデータ構造と、利用者が操作する API を分けて扱う。

ストレージレイヤーは、OPC package や XML file の内容を保持し、読み書きの責務を持つ。`XLWorksheetFile` は worksheet XML file に対応し、`columnByNumber` で列設定を、`rowByNumber` で存在する行を保持する。`XLColumnStorage` は列幅、列の既定セル書式、非表示やアウトラインなどの列属性を保持する。`XLRowStorage` は行の中のセルを `cellByColumn` で保持し、`XLCellStorage` はセルの値を保持する。

`XLWorksheetFile`、`XLColumnStorage`、`XLRowStorage`、`XLCellStorage` は参照型にする。これは、`worksheet.column(2).width = ...` や `worksheet.row(3).cell(column: 2).value = ...` のように、途中で得た column / row / cell を編集した時に元の worksheet file へ変更が反映されるようにするためである。

ハンドルレイヤーは、利用者向けの軽い値型 API として提供する。`XLWorkbook`、`XLWorksheet`、`XLColumn`、`XLRow`、`XLCell` は、必要な識別情報と対応する storage への参照を持つ。ハンドル自体は値として渡せるが、変更対象の実体は storage にある。

`XLWorksheet` は `XLWorksheetFile` を包み、列と行へのアクセサを提供する。`XLColumn` は列番号と `XLColumnStorage` を持つ。`XLRow` は `XLRowStorage` を包み、セルへのアクセサを提供する。`XLCell` は `XLCellAddress` と `XLCellStorage` を持つ。

worksheet XML の `<col style="...">` は列の既定セル書式であり、API では `XLColumn.format: XLCellFormat?` として扱う。保存時は cell と同じく `XLStylesFile.cellFormats` へ登録し、その index を `style` 属性へ書く。

作成を伴うアクセサと、既存要素だけを見るアクセサは分ける。`column(_:)`、`row(_:)`、`cell(...)` は存在しない column / row / cell を作成して返す。`existingColumn(_:)`、`existingRow(_:)`、`existingCell(...)` は存在する場合だけ返し、存在しない要素を作成しない。

存在する番号一覧は、`existingRowNumbers` と `existingColumnNumbers` でソート済み配列として返す。最大番号だけが必要な場合のために、`maxRowNumber` と `maxColumnNumber` も用意する。どちらも要素が存在しない場合は `nil` を返す。

worksheet XML へ書き戻す時は、storage の内容を既存 XML tree に差分反映する。列は `XLColumnStorage.Fields` を書き出し単位として扱い、連続する列の書き出し内容が同じ場合は 1 つの `<col min="..." max="...">` にまとめる。行やセルの既存 XML element は一度だけ走査して逆引きテーブルを作り、更新または作成した後で番号順に並べ直す。column と cell では列番号順、row では行番号順に並べる。デコードできない要素や、ライブラリが所有しない child node は別に保持し、既知要素の後ろへ戻す。

## Namespace prefix

XML namespace は prefix ではなく URI を正とする。

属性や要素を読む時は、`r:id` のような qualified name の文字列ではなく、local name と namespace URI で検索する。

namespace 付き属性を追加または更新する時は、呼び出し側が prefix を直接指定しない。対象の namespace URI から、スコープ内に登録済みの prefix を検索して使う。

対象 URI の prefix がまだ登録されていない場合は、希望する prefix を指定して namespace を確保する。ただし、その prefix が別 URI で既に使われている場合は既存定義を壊さず、`r2`, `r3`, `r4` のように suffix を増やして空いている prefix を使う。

default namespace は別扱いにする。default namespace は無 prefix 要素名の意味を決めるため、期待する URI と違う場合は上書きしてよい。
