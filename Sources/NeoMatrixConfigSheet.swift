import Cocoa

final class NeoMatrixConfigSheet: NSObject {

    private(set) var panel: NSPanel!
    weak var owner: NeoMatrixView?

    private var pending = NeoMatrixConfig()

    // Controls – strong refs; the panel's view hierarchy also retains them
    private var speedSlider:    NSSlider!
    private var speedVal:       NSTextField!
    private var minSpdSlider:   NSSlider!
    private var minSpdVal:      NSTextField!
    private var sizeSlider:   NSSlider!
    private var sizeVal:      NSTextField!
    private var trailSlider:  NSSlider!
    private var trailVal:     NSTextField!
    private var flickSlider:  NSSlider!
    private var flickVal:     NSTextField!
    private var colorSeg:     NSSegmentedControl!
    private var katCheck:     NSButton!
    private var cyrCheck:     NSButton!
    private var digCheck:     NSButton!

    // MARK: – Init

    init(for view: NeoMatrixView) {
        owner   = view
        pending = NeoMatrixConfig.load()
        super.init()
        buildPanel()
    }

    // MARK: – Build

    private func buildPanel() {
        let W: CGFloat = 380
        let H: CGFloat = 450

        let p = NSPanel(contentRect: NSRect(x: 0, y: 0, width: W, height: H),
                        styleMask: [.titled], backing: .buffered, defer: true)
        p.title = "Neo Matrix Rain"
        panel = p

        let root = p.contentView!

        // ── helpers ──────────────────────────────────────────────────────

        func label(_ text: String, y: CGFloat) {
            let tf = NSTextField(frame: NSRect(x: 20, y: y, width: W - 40, height: 18))
            tf.isEditable = false; tf.isBordered = false; tf.backgroundColor = .clear
            tf.stringValue = text
            root.addSubview(tf)
        }

        func valueLabel(frame: NSRect, text: String) -> NSTextField {
            let tf = NSTextField(frame: frame)
            tf.isEditable = false; tf.isBordered = false
            tf.backgroundColor = .clear; tf.alignment = .right
            tf.stringValue = text
            root.addSubview(tf)
            return tf
        }

        func slider(y: CGFloat, min: Double, max: Double, val: Double, tag: Int) -> NSSlider {
            let s = NSSlider(frame: NSRect(x: 20, y: y, width: W - 90, height: 24))
            s.minValue = min; s.maxValue = max; s.doubleValue = val
            s.target = self; s.action = #selector(sliderMoved(_:)); s.tag = tag
            s.isContinuous = true
            root.addSubview(s)
            return s
        }

        // ── Max Speed  (label y=423, slider y=395) ───────────────────────
        label("Max Speed", y: 423)
        speedSlider = slider(y: 395, min: 0.05, max: 1.0, val: pending.speed, tag: 1)
        speedVal    = valueLabel(frame: NSRect(x: W-70, y: 395, width: 55, height: 24),
                                 text: String(format: "%.2f", pending.speed))

        // ── Min Speed %  (label y=367, slider y=339) ─────────────────────
        label("Min Speed  (% of max)", y: 367)
        minSpdSlider = slider(y: 339, min: 0.05, max: 1.0, val: pending.minSpeedPct, tag: 5)
        minSpdVal    = valueLabel(frame: NSRect(x: W-70, y: 339, width: 55, height: 24),
                                  text: "\(Int(pending.minSpeedPct * 100))%")

        // ── Character Size  (label y=311, slider y=283) ──────────────────
        label("Character Size  (also sets density)", y: 311)
        sizeSlider = slider(y: 283, min: 12, max: 40, val: pending.fontSize, tag: 2)
        sizeVal    = valueLabel(frame: NSRect(x: W-70, y: 283, width: 55, height: 24),
                                text: "\(Int(pending.fontSize))")

        // ── Trail Length  (label y=255, slider y=227) ────────────────────
        label("Trail Length", y: 255)
        trailSlider = slider(y: 227, min: 4, max: 64, val: Double(pending.trailLen), tag: 3)
        trailVal    = valueLabel(frame: NSRect(x: W-70, y: 227, width: 55, height: 24),
                                 text: "\(pending.trailLen)")

        // ── Flicker  (label y=199, slider y=171) ─────────────────────────
        label("Flicker", y: 199)
        flickSlider = slider(y: 171, min: 0, max: 0.15, val: pending.flickerChance, tag: 4)
        flickVal    = valueLabel(frame: NSRect(x: W-70, y: 171, width: 55, height: 24),
                                 text: String(format: "%.3f", pending.flickerChance))

        // ── Color scheme  (label y=143, segment y=113) ───────────────────
        label("Color", y: 143)
        let seg = NSSegmentedControl(labels: ["Green", "Blue", "Red", "White"],
                                     trackingMode: .selectOne,
                                     target: self, action: #selector(colorPicked(_:)))
        seg.frame = NSRect(x: 20, y: 113, width: W - 40, height: 26)
        seg.selectedSegment = pending.colorScheme
        root.addSubview(seg); colorSeg = seg

        // ── Characters  (label y=85, checkboxes y=57) ────────────────────
        label("Characters", y: 85)

        let kat = NSButton(checkboxWithTitle: "Katakana", target: self,
                           action: #selector(charToggled(_:)))
        kat.frame = NSRect(x: 20,  y: 57, width: 110, height: 24); kat.tag = 10
        kat.state = pending.useKatakana ? .on : .off
        root.addSubview(kat); katCheck = kat

        let cyr = NSButton(checkboxWithTitle: "Cyrillic", target: self,
                           action: #selector(charToggled(_:)))
        cyr.frame = NSRect(x: 140, y: 57, width: 100, height: 24); cyr.tag = 11
        cyr.state = pending.useCyrillic ? .on : .off
        root.addSubview(cyr); cyrCheck = cyr

        let dig = NSButton(checkboxWithTitle: "Digits", target: self,
                           action: #selector(charToggled(_:)))
        dig.frame = NSRect(x: 250, y: 57, width: 100, height: 24); dig.tag = 12
        dig.state = pending.useDigits ? .on : .off
        root.addSubview(dig); digCheck = dig

        // ── OK / Cancel  (y=15) ──────────────────────────────────────────
        let ok = NSButton(frame: NSRect(x: W - 110, y: 15, width: 80, height: 32))
        ok.title = "OK"; ok.keyEquivalent = "\r"; ok.bezelStyle = .rounded
        ok.target = self; ok.action = #selector(okTapped(_:))
        root.addSubview(ok)

        let cancel = NSButton(frame: NSRect(x: W - 200, y: 15, width: 80, height: 32))
        cancel.title = "Cancel"; cancel.keyEquivalent = "\u{1B}"; cancel.bezelStyle = .rounded
        cancel.target = self; cancel.action = #selector(cancelTapped(_:))
        root.addSubview(cancel)
    }

    // MARK: – Sync UI → pending config  (called each time sheet opens)

    func prepareToShow() {
        pending = NeoMatrixConfig.load()
        speedSlider.doubleValue  = pending.speed
        speedVal.stringValue     = String(format: "%.2f", pending.speed)
        minSpdSlider.doubleValue = pending.minSpeedPct
        minSpdVal.stringValue    = "\(Int(pending.minSpeedPct * 100))%"
        sizeSlider.doubleValue   = pending.fontSize
        sizeVal.stringValue      = "\(Int(pending.fontSize))"
        trailSlider.doubleValue  = Double(pending.trailLen)
        trailVal.stringValue     = "\(pending.trailLen)"
        flickSlider.doubleValue  = pending.flickerChance
        flickVal.stringValue     = String(format: "%.3f", pending.flickerChance)
        colorSeg.selectedSegment = pending.colorScheme
        katCheck.state = pending.useKatakana ? .on : .off
        cyrCheck.state = pending.useCyrillic ? .on : .off
        digCheck.state = pending.useDigits   ? .on : .off
    }

    // MARK: – Actions

    @objc private func sliderMoved(_ s: NSSlider) {
        switch s.tag {
        case 1:
            pending.speed        = s.doubleValue
            speedVal.stringValue = String(format: "%.2f", s.doubleValue)
        case 5:
            pending.minSpeedPct   = s.doubleValue
            minSpdVal.stringValue = "\(Int(s.doubleValue * 100))%"
        case 2:
            pending.fontSize    = s.doubleValue
            sizeVal.stringValue = "\(Int(s.doubleValue))"
        case 3:
            pending.trailLen    = Int(s.doubleValue)
            trailVal.stringValue = "\(Int(s.doubleValue))"
        case 4:
            pending.flickerChance = s.doubleValue
            flickVal.stringValue  = String(format: "%.3f", s.doubleValue)
        default: break
        }
    }

    @objc private func colorPicked(_ seg: NSSegmentedControl) {
        pending.colorScheme = seg.selectedSegment
    }

    @objc private func charToggled(_ btn: NSButton) {
        switch btn.tag {
        case 10: pending.useKatakana = (btn.state == .on)
        case 11: pending.useCyrillic = (btn.state == .on)
        case 12: pending.useDigits   = (btn.state == .on)
        default: break
        }
        // Always keep at least one set enabled
        if !pending.useKatakana && !pending.useCyrillic && !pending.useDigits {
            pending.useDigits = true
            digCheck.state = .on
        }
    }

    @objc private func okTapped(_ sender: Any) {
        pending.save()
        owner?.reloadConfig()
        panel.sheetParent?.endSheet(panel)
        panel.orderOut(nil)
    }

    @objc private func cancelTapped(_ sender: Any) {
        panel.sheetParent?.endSheet(panel)
        panel.orderOut(nil)
    }
}
