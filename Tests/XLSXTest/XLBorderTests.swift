import Testing
@testable import XLSX

@Suite
struct XLBorderTests {
    @Test func readsBorderLinesFromElement() throws {
        let element = try XLSX.XMLElement(xmlString: """
            <border outline="0" diagonalUp="1" diagonalDown="1">
              <start style="dotted"/>
              <end style="hair"/>
              <left style="thin"><color rgb="FFFF0000"/></left>
              <right/>
              <top style="dashDot"/>
              <bottom style="mediumDashDot"><color theme="4" tint="0.25"/></bottom>
              <diagonal style="double"><color indexed="64"/></diagonal>
              <vertical style="dashed"/>
              <horizontal style="thick"/>
            </border>
            """)

        let border = XLBorder(element: element)

        #expect(border.outline == false)
        #expect(border.start == XLBorder.Line(style: .dotted))
        #expect(border.end == XLBorder.Line(style: .hair))
        #expect(border.left == XLBorder.Line(style: .thin, color: .rgb("FFFF0000")))
        #expect(border.right == XLBorder.Line())
        #expect(border.top == XLBorder.Line(style: .dashDot))
        #expect(border.bottom == XLBorder.Line(style: .mediumDashDot, color: .theme(4, tint: 0.25)))
        #expect(border.diagonal == XLBorder.Diagonal(
            directions: [.up, .down],
            line: XLBorder.Line(style: .double, color: .indexed(64))
        ))
        #expect(border.vertical == XLBorder.Line(style: .dashed))
        #expect(border.horizontal == XLBorder.Line(style: .thick))
    }

    @Test func writesBorderLinesToElement() {
        let border = XLBorder(
            outline: false,
            start: XLBorder.Line(style: .dotted),
            end: XLBorder.Line(style: .hair),
            left: XLBorder.Line(style: .thin, color: .rgb("FFFF0000")),
            right: XLBorder.Line(),
            top: XLBorder.Line(style: .dashDot),
            bottom: XLBorder.Line(style: .mediumDashDot, color: .theme(4, tint: 0.25)),
            diagonal: XLBorder.Diagonal(
                directions: [.up, .down],
                line: XLBorder.Line(style: .double, color: .indexed(64))
            ),
            vertical: XLBorder.Line(style: .dashed),
            horizontal: XLBorder.Line(style: .thick)
        )

        #expect(border.xmlElement().xmlString == #"<border outline="0" diagonalUp="1" diagonalDown="1"><start style="dotted"/><end style="hair"/><left style="thin"><color rgb="FFFF0000"/></left><right/><top style="dashDot"/><bottom style="mediumDashDot"><color theme="4" tint="0.25"/></bottom><diagonal style="double"><color indexed="64"/></diagonal><vertical style="dashed"/><horizontal style="thick"/></border>"#)
    }

    @Test func omitsDiagonalWithoutDirections() {
        let border = XLBorder(
            outline: nil,
            start: nil,
            end: nil,
            left: nil,
            right: nil,
            top: nil,
            bottom: nil,
            diagonal: XLBorder.Diagonal(
                directions: [],
                line: XLBorder.Line(style: .thin)
            ),
            vertical: nil,
            horizontal: nil
        )

        #expect(border.xmlElement().xmlString == "<border/>")
    }
}
