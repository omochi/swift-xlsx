// style の collect は CaseIterable の定義順で実行される。
// cellFormats のような依存側の record は、参照先の storage より後ろに置く。
public enum XLStyleCollectionStage: CaseIterable {
    case numberFormats
    case fonts
    case fills
    case borders
    case cellStyleFormats
    case cellFormats
}
