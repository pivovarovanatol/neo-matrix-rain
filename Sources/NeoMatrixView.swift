import ScreenSaver

public class NeoMatrixView: ScreenSaverView {

    // MARK: – Configuration
    private let fontSize:     CGFloat = 22
    private let trailLen:     Int     = 24
    private let minSpeed:     Double  = 0.10
    private let maxSpeed:     Double  = 0.35
    private let flickerChance: Double = 0.01

    // Katakana + Cyrillic + digits
    private static let alphabet: [Character] = {
        let kata     = (0x30A0...0x30FF).compactMap { Unicode.Scalar($0).map(Character.init) }
        let cyrillic = (0x0400...0x04FF).compactMap { Unicode.Scalar($0).map(Character.init) }
        let digits   = Array("0123456789")
        return kata + cyrillic + digits
    }()

    // MARK: – Per-column state
    private struct Column {
        var y:          Double
        var speed:      Double
        var active:     Bool        = true
        var pauseFor:   Int         = 0
        var trailChars: [Character] = []
    }
    private var columns: [Column] = []

    // MARK: – Pre-built drawing resources
    private var monoFont:   NSFont!
    private var headAttrs:  [NSAttributedString.Key: Any]!
    private var trailAttrs: [[NSAttributedString.Key: Any]]!

    // MARK: – Init
    public override init?(frame: NSRect, isPreview: Bool) {
        super.init(frame: frame, isPreview: isPreview)
        animationTimeInterval = 1.0 / 30.0
    }
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        animationTimeInterval = 1.0 / 30.0
    }

    // MARK: – Lifecycle
    public override func startAnimation() {
        super.startAnimation()
        buildResources()
        resetColumns()
    }

    private func buildResources() {
        monoFont = NSFont(name: "Courier New", size: fontSize)
                   ?? NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)

        headAttrs = [.font: monoFont!, .foregroundColor: NSColor.white]

        trailAttrs = (0..<trailLen).map { j in
            let t = CGFloat(j) / CGFloat(trailLen - 1)
            let g = 0.07 + t * 0.78
            return [.font: monoFont!,
                    .foregroundColor: NSColor(red: 0, green: g, blue: 0.02, alpha: 1)]
        }
    }

    private func resetColumns() {
        let n    = max(1, Int(bounds.width / fontSize))
        let rows = Double(bounds.height / fontSize)
        columns = (0..<n).map { _ in
            Column(y:          -Double.random(in: 0...max(1, rows)),
                   speed:      minSpeed + Double.random(in: 0...(maxSpeed - minSpeed)),
                   trailChars: (0..<trailLen).map { _ in randomChar() })
        }
    }

    // MARK: – Drawing
    // animateOneFrame is called by the screensaver framework (with lockFocus already held).
    // draw(_:) is called by display() in the test app (also with lockFocus held).
    // Both funnel into renderFrame().
    public override func animateOneFrame() { renderFrame() }
    public override func draw(_ rect: NSRect) { renderFrame() }

    private func renderFrame() {
        guard monoFont != nil else { buildResources(); return }

        // Re-initialise columns if bounds changed (e.g. first real frame after launch)
        let numCols = max(1, Int(bounds.width / fontSize))
        if columns.count != numCols { resetColumns() }

        // Clear to black
        NSColor.black.setFill()
        NSBezierPath.fill(bounds)

        for i in 0..<columns.count {
            guard columns[i].active else {
                columns[i].pauseFor -= 1
                if columns[i].pauseFor <= 0 {
                    columns[i].y          = 0
                    columns[i].active     = true
                    columns[i].trailChars = (0..<trailLen).map { _ in randomChar() }
                }
                continue
            }

            let headRow = Int(columns[i].y)
            let x       = CGFloat(i) * fontSize

            // ── Trail ──────────────────────────────────────────────────────
            for j in 0..<trailLen {
                if Double.random(in: 0...1) < flickerChance {
                    columns[i].trailChars[j] = randomChar()
                }
                let trailRow = headRow - (trailLen - j)
                let py       = bounds.height - CGFloat(trailRow + 1) * fontSize
                guard py >= -fontSize && py <= bounds.height else { continue }

                (String(columns[i].trailChars[j]) as NSString)
                    .draw(at: NSPoint(x: x, y: py), withAttributes: trailAttrs[j])
            }

            // ── Head: white with green glow via NSShadow ───────────────────
            let headY = bounds.height - CGFloat(headRow + 1) * fontSize
            if headY >= -fontSize && headY <= bounds.height {
                NSGraphicsContext.current?.saveGraphicsState()
                let shadow = NSShadow()
                shadow.shadowColor      = NSColor(red: 0, green: 1, blue: 0.25, alpha: 1)
                shadow.shadowBlurRadius = 6
                shadow.shadowOffset     = .zero
                shadow.set()
                (String(randomChar()) as NSString)
                    .draw(at: NSPoint(x: x, y: headY), withAttributes: headAttrs)
                NSGraphicsContext.current?.restoreGraphicsState()
            }

            // ── Advance ────────────────────────────────────────────────────
            columns[i].y += columns[i].speed

            if CGFloat(headRow) * fontSize > bounds.height + CGFloat(trailLen) * fontSize {
                columns[i].active   = false
                columns[i].pauseFor = Int.random(in: 20...80)
            }
        }
    }

    private func randomChar() -> Character {
        Self.alphabet[Int.random(in: 0..<Self.alphabet.count)]
    }

    // MARK: – ScreenSaverView
    public override var hasConfigureSheet: Bool { false }
    public override var configureSheet: NSWindow? { nil }
}
