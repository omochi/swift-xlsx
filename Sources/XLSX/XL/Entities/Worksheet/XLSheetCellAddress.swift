import MemberwiseInit

@MemberwiseInit(.public)
public struct XLSheetCellAddress: Sendable & Hashable & LosslessStringConvertible {
    public init?(_ description: String) {
        guard let separatorIndex = Self.sheetCellSeparatorIndex(in: description) else {
            return nil
        }

        let sheetNameText = String(description[..<separatorIndex])
        let cellAddressText = String(description[description.index(after: separatorIndex)...])
        guard !cellAddressText.isEmpty,
              let sheetName = Self.parseSheetName(sheetNameText),
              let cellAddress = XLCellAddress(cellAddressText)
        else {
            return nil
        }

        self.sheetName = sheetName
        self.cellAddress = cellAddress
    }

    public var sheetName: String
    public var cellAddress: XLCellAddress

    public var description: String {
        Self.description(sheetName: sheetName) + "!" + cellAddress.description
    }

    static func sheetCellSeparatorIndex(in description: String) -> String.Index? {
        if description.first == "'" {
            var index = description.index(after: description.startIndex)
            while index < description.endIndex {
                if description[index] == "'" {
                    let nextIndex = description.index(after: index)
                    if nextIndex < description.endIndex,
                       description[nextIndex] == "'" {
                        index = description.index(after: nextIndex)
                        continue
                    }
                    guard nextIndex < description.endIndex,
                          description[nextIndex] == "!"
                    else {
                        return nil
                    }
                    return nextIndex
                }
                index = description.index(after: index)
            }
            return nil
        }

        return description.firstIndex(of: "!")
    }

    static func parseSheetName(_ text: String) -> String? {
        guard !text.isEmpty else {
            return nil
        }

        if text.first == "'" {
            guard text.last == "'",
                  text.count >= 2
            else {
                return nil
            }

            let content = text.dropFirst().dropLast()
            var sheetName = ""
            var index = content.startIndex
            while index < content.endIndex {
                if content[index] == "'" {
                    let nextIndex = content.index(after: index)
                    guard nextIndex < content.endIndex,
                          content[nextIndex] == "'"
                    else {
                        return nil
                    }
                    sheetName.append("'")
                    index = content.index(after: nextIndex)
                } else {
                    sheetName.append(content[index])
                    index = content.index(after: index)
                }
            }

            return sheetName.isEmpty ? nil : sheetName
        }

        guard text.firstIndex(of: "'") == nil else {
            return nil
        }
        return text
    }

    static func description(sheetName: String) -> String {
        precondition(!sheetName.isEmpty, "XLSheetCellAddress sheetName must not be empty.")

        if sheetName.allSatisfy(isUnquotedSheetNameCharacter) {
            return sheetName
        }

        return "'" + sheetName.replacingOccurrences(of: "'", with: "''") + "'"
    }

    private static func isUnquotedSheetNameCharacter(_ character: Character) -> Bool {
        return character.isLetter || character.isNumber || character == "_"
    }
}
