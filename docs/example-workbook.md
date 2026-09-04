# Example workbook

`example.xlsx` は、`swift-xlsx` の public API から新規生成できる機能を、Microsoft Excel で目視・操作確認するためのサンプルです。

生成元は `Sources/XLSXExamples/XLExampleDocuments.swift` です。`example.xlsx` 自体を手作業で編集せず、生成元と `Tests/XLSXTest/Resources/example-documents/example/` の fixture を同期します。

## 対応範囲

| Sheet | 主な確認対象 |
| --- | --- |
| `formula` | 通常数式、shared formula、数値と文字列の cache 値 |
| `column` | 列幅、列の既定 style、hidden、best fit、outline level、collapsed |
| `number format` | 組み込み number format と custom format |
| `font` | Font の型付き property と color |
| `fill` | すべての `XLFill.PatternType` |
| `border` | Border の方向、対角線、すべての `XLBorder.LineStyle` |
| `data validation` | List、整数、小数、日付、時刻、文字列長、custom、複数 range、prompt、error |
| `password` | SHA-512 password hash、sheet protection、locked / unlocked cell、hidden formula |
| `hidden` | Hidden sheet |
| `cell value` | Plain text、rich text、ふりがな、数値、真偽値、日付、error |
| `freeze panes` | 上端の行と左端の列の固定 |
| `cell style` | Named cell style と複数 property を組み合わせた cell format |
| `very hidden` | Very hidden sheet |

次の機能は保存後の workbook の見た目だけでは確認できないため、`example.xlsx` の対応対象にしません。

- `open`、`removeWorksheet`、`existing*` accessor などの操作 API
- 既存 package part や未知の XML content の保持
- High-level document 保存では shared string になるため、inline string の直接生成
- Raw XML を保持する array formula、data-table formula、gradient fill、font の未型付け property
- Worksheet の最大 row / column 定数や address の parse / format

これらは対象の unit test で確認します。

## 自動テスト

repo root から次を実行します。

```console
cd swift-xlsx
swift test --disable-sandbox --filter ExampleDocumentsTests
swift test --disable-sandbox
```

`ExampleDocumentsTests` は、生成された OPC package と抽出済み fixture の一致に加えて、各 sheet に意図した API 設定が含まれることを検証します。

## Microsoft Excel で開く

repo root から次を実行します。

```console
cd swift-xlsx
output_dir="$(mktemp -d /tmp/swift-xlsx-example.XXXXXX)"
swift run --disable-sandbox xlsx-tool example-documents "$output_dir"
open -a "Microsoft Excel" "$output_dir/example.xlsx"
```

Excel が file の修復を通知した場合は、その時点で失敗です。修復済み file を使って後続項目を成功扱いにしません。

## Sheet ごとの確認手順

### `formula`

1. `B4` が `60` と表示され、数式 bar に `=SUM(B1:B3)` が表示されることを確認します。
2. `D1:D3` が `20`、`40`、`60` と表示されることを確認します。
3. `D1:D3` の数式が、それぞれ同じ shared formula group から `=B1*2`、`=B2*2`、`=B3*2` として扱われることを確認します。
4. `B6` が `10` と表示され、数式 bar に `=TEXT(B1,"0")` が表示されることを確認します。

### `column`

1. `A:C` の列幅が 10、20、30 の順に広くなることを確認します。
2. `D` 列に既定の percent style が設定され、同じ cell format を持つ `D1` が `13%` と表示されることを確認します。列の style 属性は fixture の XML でも確認します。
3. 列見出しが `D` の次に `F` となり、`E` が hidden であることを確認します。
4. `F1` に `column E is hidden` と表示されることを確認します。
5. `G` の best fit、`H` の outline level、`I` の collapsed 属性が保存されていることを、列の表示と outline UI で確認します。Excel の UI に現れない属性は fixture の XML で確認します。

### `number format`

1. `C1:C13` で、整数、小数、桁区切り、percent、日付、時刻、経過時間、text の表示を確認します。
2. `C15` が `2025ねん 6がつ 17にち` と表示されることを確認します。

Excel の locale により、組み込み日付と時刻の区切り文字や月日の順序は変わって構いません。値の種類と意味が維持されていることを確認します。

### `font`

1. `A1:A14` を順に確認し、太字、斜体、取り消し線、condense、extend、outline、shadow、size、font name、RGB、indexed、theme、tint、automatic color が反映されていることを確認します。
2. Excel や使用 font によって視覚差が小さい property は、cell の書式設定でも値を確認します。

### `fill`

1. `A1:A19` にすべての `XLFill.PatternType` 名があることを確認します。
2. `B1:B19` で、対応する pattern fill が表示されることを確認します。
3. `none` は無地、`solid` は単色、その他は名前に対応する pattern になっていることを確認します。

### `border`

1. `B2:B20` で、start、end、left、right、top、bottom、対角線 3 種、四辺の medium border を確認します。
2. `D1:D14` にすべての `XLBorder.LineStyle` 名があることを確認します。
3. `E1:E14` の下 border が、対応する line style になっていることを確認します。

### `data validation`

1. `B2` の drop-down に Apple、Banana、Cherry が表示されることを確認します。
2. `B10:B12` にも同じ list validation が設定されていることを確認します。
3. `B3:B8` を順に選択し、input message が表示されることを確認します。
4. 次の invalid value を入力し、指定した stop / warning / information error が表示されることを確認します。確認後は undo します。
   - `B3`: `11`
   - `B4`: `1.5`
   - `B5`: `2100-01-01`
   - `B6`: `18:00`
   - `B7`: 11 文字以上の text
   - `B8`: `3`

### `password`

1. `B3` を編集しようとすると protection error になることを確認します。
2. 黄色の `B4` は編集できることを確認し、確認後は undo します。
3. `B5` は値 `2` を表示する一方、数式 bar に式が表示されないことを確認します。
4. Review tab から sheet protection を解除するとき、password `swift-xlsx` が使えることを確認します。確認後は保存せず閉じます。

### `hidden` と `very hidden`

1. Sheet tab の Unhide dialog に `hidden` が表示されることを確認します。
2. `very hidden` は Unhide dialog に表示されないことを確認します。
3. `hidden` を一度表示し、`A1` に `hidden` と書かれていることを確認します。確認後は保存せず閉じます。

### `cell value`

1. `B1` に plain text が表示されることを確認します。
2. `B2` の `bold` が太字、`red` が赤で、1 cell 内の rich text として表示されることを確認します。
3. `B3` に `漢字` と `かんじ` のふりがなが表示されることを確認します。表示されない場合は Home tab の phonetic guide 表示を有効にして再確認します。
4. `B4:B8` に、数値、`TRUE`、`FALSE`、日付、`#N/A` がそれぞれの値 type として表示されることを確認します。

### `freeze panes`

1. 下方向へ scroll し、row 1 が表示されたままになることを確認します。
2. 右方向へ scroll し、column A が表示されたままになることを確認します。
3. View tab の Freeze Panes が有効になっていることを確認します。

### `cell style`

1. `B1` が青い背景の太字 white text で `13%` と表示されることを確認します。
2. Home tab の Cell Styles に `Example Percent` があることを確認します。
3. `B3` が桁区切りと小数 2 桁、赤い太字、薄い赤の fill、double bottom border で表示されることを確認します。

## 確認結果の記録

確認時は、次を記録します。

- Microsoft Excel の version
- macOS または Windows の version
- 修復通知の有無
- 各 sheet の成功 / 失敗
- locale 依存の表示差
- 失敗した cell address と screenshot

目視で成功したことと、fixture / unit test が成功したことは分けて記録します。
