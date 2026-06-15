# 実装計画

## セル値の型付け

セル値の型付けは、文字列の保存形式とセル値 API を分けて進める。

`sharedStrings.xml` と `inlineStr` は XML 上のシリアライズ戦略として扱い、利用者向けのセル値ではどちらも文字列として表す。保存時は文字列を `sharedStrings.xml` に集約し、worksheet のセルは `t="s"` と shared string index で書く。

数式はセル値そのものではなく、セルが持つ別の状態として扱う。`t="str"` は formula string result を表すため、値としては文字列にまとめつつ、roundtrip のためには `<f>` を保持できるようにする。

## 進める順番

### 1. sharedStrings.xml のストレージ実装

`sharedStrings.xml` を読むための storage 型を追加する。

この段階では、shared string table の index と plain text の対応を扱う。rich text はまず plain text に畳み込む。既存 file がない document でも、保存時に必要なら shared strings part と relationship と content type を作成できるようにする。

worksheet の読み書きから直接 shared strings を触らず、document package 側で shared strings storage を保持する。

### 2. `XLCellValue` の実装

`XLCellValue(rawValue:)` をやめ、XLSX のセル値として必要な型を enum で表す。

最初に扱う case は、number、boolean、string、error、date とする。文字列は shared string、inline string、formula string result の保存形式に関係なく同じ case にまとめる。

worksheet 読み込み時は、`t` 属性とセルの child element から `XLCellValue` を復元する。保存時は `.string` を shared strings に登録し、worksheet には shared string index を書く。

### 3. formula の実装

セルの `<f>` を保持するための型を追加し、`XLCellStorage` が値とは別に formula を持てるようにする。

この段階では、式テキストの roundtrip を優先する。formula の詳細属性や shared formula の完全な意味解釈は、必要になるまで広げない。

既存セルを書き戻す時に、ライブラリが値だけを更新しても `<f>` が不意に消えないようにする。

### 4. formula string の実装

`t="str"` を formula string result として扱う。

読み込み時は、`<f>` を formula として保持し、`<v>` は `.string` の cached result として読む。保存時は、formula があり cached result が文字列の場合に `t="str"` を書けるようにする。

通常の文字列セルは引き続き shared strings へ集約し、`t="str"` は formula の cached result にだけ使う。
