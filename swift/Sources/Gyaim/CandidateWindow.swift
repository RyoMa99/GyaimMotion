import Cocoa

/// キャレットの下に出す候補ウィンドウ。背景は元実装と同じ candwin.png。
final class CandidateWindow: NSPanel {
    private let textView: NSTextView

    init() {
        let background = Bundle.main.image(forResource: "candwin")
        let size = background?.size ?? NSSize(width: 241, height: 126)
        textView = NSTextView(frame: NSRect(x: 16, y: 16, width: size.width - 32, height: size.height - 40))
        super.init(contentRect: NSRect(origin: .zero, size: size),
                   styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        level = .statusBar
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        isMovableByWindowBackground = true

        let imageView = NSImageView(frame: NSRect(origin: .zero, size: size))
        imageView.image = background
        imageView.imageScaling = .scaleAxesIndependently
        textView.drawsBackground = false
        textView.isEditable = false
        textView.isSelectable = false
        textView.font = .systemFont(ofSize: 14)
        textView.textColor = .black
        contentView = imageView
        imageView.addSubview(textView)
    }

    func show(_ words: [String], below lineRect: NSRect) {
        textView.string = words.joined(separator: " ")
        setFrameOrigin(NSPoint(x: lineRect.minX - 15, y: lineRect.minY - frame.height - 4))
        orderFront(nil)
    }
}
