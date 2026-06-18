import XLSXXML

extension XMLNamespaceURI {
    public static let spreadsheet = XMLNamespaceURI("http://schemas.openxmlformats.org/spreadsheetml/2006/main")
    public static let spreadsheetRevision = XMLNamespaceURI("http://schemas.microsoft.com/office/spreadsheetml/2014/revision")
    public static let markupCompatibility = XMLNamespaceURI("http://schemas.openxmlformats.org/markup-compatibility/2006")
    public static let officeRelationships = XMLNamespaceURI("http://schemas.openxmlformats.org/officeDocument/2006/relationships")
    public static let packageRelationships = XMLNamespaceURI("http://schemas.openxmlformats.org/package/2006/relationships")

    public static let officeDocument = XMLNamespaceURI("http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument")
    public static let sharedStrings = XMLNamespaceURI("http://schemas.openxmlformats.org/officeDocument/2006/relationships/sharedStrings")
    public static let styles = XMLNamespaceURI("http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles")
    public static let worksheet = XMLNamespaceURI("http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet")
}
