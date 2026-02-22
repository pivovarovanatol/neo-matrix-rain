import ScreenSaver

public class NeoMatrixView: ScreenSaverView {

    // MARK: – Configuration
    private let fontSize:  CGFloat = 22
    private let trailLen:  Int     = 24    // characters in the fading tail
    private let minSpeed:  Double  = 0.10  // rows per frame (slow)
    private let maxSpeed:  Double  = 0.35

    // Katakana + Cyrillic + digits
    private static let alphabet: [Character] = {
        let kata     = (0x30A0...0x30FF).compactMap { Unicode.Scalar($0).map(Character.init) }
        let cyrillic = (0x0400...0x04FF).compactMap { Unicode.Scalar($0).map(Character.init) }
        let digits   = Array("0123456789")
        return kata + cyrillic + digits
    }()

    // How often trail characters flicker: 0 = never, 1 = every frame
    private let flickerChance: Double = 0.01

    // MARK: – Per-column state
    private struct Column {
        var y:          Double
        var speed:      Double
        var active:     Bool       = true
        var pauseFor:   Int        = 0
        var trailChars: [Character] = []   // stored so they don't change every frame
    }
    private var columns: [Column] = []

    // MARK: – Pre-built drawing resources (created once, reused every frame)
    private var monoFont: NSFont!
    private var headAttrs: [NSAttributedString.Key: Any]!       // white
    private var trailAttrs: [[NSAttributedString.Key: Any]]!    // trailLen shades of green

    // MARK: – Timer
    private var displayTimer: Timer?

    // MARK: – Init
    public override init?(frame: NSRect, isPreview: Bool) {
        super.init(frame: frame, isPreview: isPreview)
    }
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    // MARK: – Lifecycle
    public override func startAnimation() {
        super.startAnimation()
        buildResources()
        resetColumns()

        let t = Timer(timeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.setNeedsDisplay(self.bounds)
        }
        RunLoop.main.add(t, forMode: .common)
        displayTimer = t
    }

    public override func stopAnimation() {
        displayTimer?.invalidate()
        displayTimer = nil
        super.stopAnimation()
    }

    private func buildResources() {
        monoFont = NSFont(name: "Courier New", size: fontSize)
                   ?? NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)

        headAttrs = [.font: monoFont!, .foregroundColor: NSColor.white]

        // Trail: index 0 = oldest/darkest, index trailLen-1 = just behind head/brightest
        trailAttrs = (0..<trailLen).map { j in
            let t = CGFloat(j) / CGFloat(trailLen - 1)
            // darkest ~0.07, brightest ~0.85 — stays in the green palette
            let g = 0.07 + t * 0.78
            return [.font: monoFont!, .foregroundColor: NSColor(red: 0, green: g, blue: 0.02, alpha: 1)]
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
    public override func draw(_ rect: NSRect) {
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }

        // Solid black background every frame — the trail is painted explicitly below
        ctx.setFillColor(CGColor(red: 0, green: 0, blue: 0, alpha: 1))
        ctx.fill(bounds)

        let numCols = max(1, Int(bounds.width / fontSize))
        if columns.count != numCols { resetColumns() }

        for i in 0..<columns.count {
            guard columns[i].active else {
                // Waiting to restart
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

            // ── Slowly flicker trail characters ─────────────────────────────
            for j in 0..<trailLen {
                if Double.random(in: 0...1) < flickerChance {
                    columns[i].trailChars[j] = randomChar()
                }
            }

            // ── Trail: draw from oldest (top) to newest (just above head) ──
            for j in 0..<trailLen {
                let trailRow = headRow - (trailLen - j)
                let py       = bounds.height - CGFloat(trailRow + 1) * fontSize
                guard py >= -fontSize && py <= bounds.height else { continue }

                (String(columns[i].trailChars[j]) as NSString).draw(
                    at: NSPoint(x: x, y: py),
                    withAttributes: trailAttrs[j])
            }

            // ── Head: bright white with green glow ──────────────────────────
            let headY = bounds.height - CGFloat(headRow + 1) * fontSize
            if headY >= -fontSize && headY <= bounds.height {
                ctx.saveGState()
                ctx.setShadow(offset: .zero, blur: 6,
                              color: CGColor(red: 0, green: 1, blue: 0.25, alpha: 1))
                (String(randomChar()) as NSString).draw(
                    at: NSPoint(x: x, y: headY),
                    withAttributes: headAttrs)
                ctx.restoreGState()
            }

            // ── Advance ─────────────────────────────────────────────────────
            columns[i].y += columns[i].speed

            if CGFloat(headRow) * fontSize > bounds.height + CGFloat(trailLen) * fontSize {
                columns[i].active   = false
                columns[i].pauseFor = Int.random(in: 20...80)  // 0.6–2.7 s pause
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
