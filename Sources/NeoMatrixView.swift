import ScreenSaver

public class NeoMatrixView: ScreenSaverView {

    // MARK: – Config
    private var config = NeoMatrixConfig.load()
    private var sheet:  NeoMatrixConfigSheet?

    // MARK: – Per-column state
    private struct Column {
        var y:          Double
        var speed:      Double
        var active:     Bool        = true
        var pauseFor:   Int         = 0
        var trailChars: [Character] = []
    }
    private var columns: [Column] = []

    // MARK: – Pre-built resources (rebuilt whenever config changes)
    private var monoFont:   NSFont?
    private var headAttrs:  [NSAttributedString.Key: Any] = [:]
    private var trailAttrs: [[NSAttributedString.Key: Any]] = []
    private var alphabet:   [Character] = []

    // MARK: – Init
    public override init?(frame: NSRect, isPreview: Bool) {
        super.init(frame: frame, isPreview: isPreview)
        animationTimeInterval = 1.0 / 30.0
    }
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        animationTimeInterval = 1.0 / 30.0
    }

    // MARK: – Config reload (called by config sheet after OK)
    func reloadConfig() {
        config   = NeoMatrixConfig.load()
        monoFont = nil  // triggers buildResources() next frame
        columns  = []   // triggers resetColumns() next frame
    }

    // MARK: – Lifecycle
    public override func startAnimation() {
        super.startAnimation()
        buildResources()
        resetColumns()
    }

    private func buildResources() {
        let sz   = CGFloat(config.fontSize)
        let font = NSFont(name: "Courier New", size: sz)
                   ?? NSFont.monospacedSystemFont(ofSize: sz, weight: .regular)
        monoFont   = font
        alphabet   = config.alphabet
        headAttrs  = [.font: font, .foregroundColor: config.headColor]
        trailAttrs = (0..<config.trailLen).map { j in
            let t = CGFloat(j) / CGFloat(max(1, config.trailLen - 1))
            return [.font: font, .foregroundColor: config.trailColor(at: t)]
        }
    }

    private func resetColumns() {
        let sz   = CGFloat(config.fontSize)
        let n    = max(1, Int(bounds.width / sz))
        let rows = Double(bounds.height / sz)
        columns = (0..<n).map { _ in
            Column(y:          -Double.random(in: 0...max(1, rows)),
                   speed:      config.minSpeed + Double.random(in: 0...(config.speed - config.minSpeed)),
                   trailChars: (0..<config.trailLen).map { _ in randomChar() })
        }
    }

    // MARK: – Rendering
    // animateOneFrame() calls display() so both paths go through draw(_:) → renderFrame(),
    // which is the same route the test app uses (and is known to work).
    public override func animateOneFrame() { display() }
    public override func draw(_ rect: NSRect) { renderFrame() }

    private func renderFrame() {
        // Lazy init — startAnimation() may not be called on modern macOS
        if monoFont == nil { buildResources() }
        if columns.isEmpty { resetColumns() }

        guard let ctx = NSGraphicsContext.current?.cgContext else { return }

        let sz      = CGFloat(config.fontSize)
        let numCols = max(1, Int(bounds.width / sz))
        if columns.count != numCols { resetColumns() }

        // Clear to black
        ctx.setFillColor(CGColor(red: 0, green: 0, blue: 0, alpha: 1))
        ctx.fill(bounds)

        for i in 0..<columns.count {
            guard columns[i].active else {
                columns[i].pauseFor -= 1
                if columns[i].pauseFor <= 0 {
                    columns[i].y          = 0
                    columns[i].active     = true
                    columns[i].trailChars = (0..<config.trailLen).map { _ in randomChar() }
                }
                continue
            }

            let headRow = Int(columns[i].y)
            let x       = CGFloat(i) * sz
            let tLen    = min(config.trailLen, min(trailAttrs.count, columns[i].trailChars.count))

            // ── Trail ──────────────────────────────────────────────────────
            for j in 0..<tLen {
                if Double.random(in: 0...1) < config.flickerChance {
                    columns[i].trailChars[j] = randomChar()
                }
                let trailRow = headRow - (tLen - j)
                let py       = bounds.height - CGFloat(trailRow + 1) * sz
                guard py >= -sz && py <= bounds.height else { continue }
                (String(columns[i].trailChars[j]) as NSString)
                    .draw(at: NSPoint(x: x, y: py), withAttributes: trailAttrs[j])
            }

            // ── Head: white with glow ──────────────────────────────────────
            let headY = bounds.height - CGFloat(headRow + 1) * sz
            if headY >= -sz && headY <= bounds.height {
                ctx.saveGState()
                ctx.setShadow(offset: .zero, blur: 6, color: config.glowColor)
                (String(randomChar()) as NSString)
                    .draw(at: NSPoint(x: x, y: headY), withAttributes: headAttrs)
                ctx.restoreGState()
            }

            // ── Advance ────────────────────────────────────────────────────
            columns[i].y += columns[i].speed
            if CGFloat(headRow) * sz > bounds.height + CGFloat(config.trailLen) * sz {
                columns[i].active   = false
                columns[i].pauseFor = Int.random(in: 20...80)
            }
        }
    }

    private func randomChar() -> Character {
        alphabet.isEmpty ? "0" : alphabet[Int.random(in: 0..<alphabet.count)]
    }

    // MARK: – ScreenSaverView config sheet
    public override var hasConfigureSheet: Bool { true }
    public override var configureSheet: NSWindow? {
        if sheet == nil { sheet = NeoMatrixConfigSheet(for: self) }
        sheet!.prepareToShow()
        return sheet!.panel
    }
}
