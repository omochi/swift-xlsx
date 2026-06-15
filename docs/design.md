# 設計メモ

## OPC XML file の扱い

OPC package 内の XML file は、内容の性質に応じて扱いを分ける。

完全に型付けした情報だけで扱える file は、読み込み時に XML から Swift の値へ変換し、保存時にはその値から XML を再生成する。未知の要素や属性を保持することは目的にしない。

一方で、未対応の情報を壊したくない file は、読み込み時の original XML を保持する。保存時には original XML を clone し、ライブラリが所有する既知の情報だけを差分更新する。未知の要素、未知の属性、既存の namespace prefix は可能な限り保持する。

例として workbook file は、シート一覧を `XLWorkbookFileSheet` として型付けして扱うが、workbook XML 全体を完全に再生成しない。既存の `<sheet>` 要素は `sheetId` で同一性を判定し、持っているシート情報だけを上書きまたは追加する。

## Namespace prefix

XML namespace は prefix ではなく URI を正とする。

属性や要素を読む時は、`r:id` のような qualified name の文字列ではなく、local name と namespace URI で検索する。

namespace 付き属性を追加または更新する時は、呼び出し側が prefix を直接指定しない。対象の namespace URI から、スコープ内に登録済みの prefix を検索して使う。

対象 URI の prefix がまだ登録されていない場合は、希望する prefix を指定して namespace を確保する。ただし、その prefix が別 URI で既に使われている場合は既存定義を壊さず、`r2`, `r3`, `r4` のように suffix を増やして空いている prefix を使う。

default namespace は別扱いにする。default namespace は無 prefix 要素名の意味を決めるため、期待する URI と違う場合は上書きしてよい。
