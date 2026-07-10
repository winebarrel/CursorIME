import AppKit

/// A small fixed "あ" badge, shown only while Japanese input is active.
final class BadgeView: NSView {
    override func draw(_: NSRect) {
        let radius = bounds.height / 4
        let path = NSBezierPath(roundedRect: bounds, xRadius: radius, yRadius: radius)
        NSColor.systemBlue.setFill()
        path.fill()

        let style = NSMutableParagraphStyle()
        style.alignment = .center
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: bounds.height * 0.55, weight: .bold),
            .foregroundColor: NSColor.white,
            .paragraphStyle: style,
        ]

        let string = "あ" as NSString
        let size = string.size(withAttributes: attrs)
        let rect = NSRect(
            x: 0,
            y: (bounds.height - size.height) / 2,
            width: bounds.width,
            height: size.height
        )
        string.draw(in: rect, withAttributes: attrs)
    }
}
