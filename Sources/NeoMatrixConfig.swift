import ScreenSaver
import Cocoa

private let kBundleID = "com.neo.matrix.rain"

struct NeoMatrixConfig {

    var speed:         Double = 0.35   // max column speed (rows/frame)
    var minSpeedPct:   Double = 0.30   // min speed as fraction of max (5%–100%)
    var fontSize:      Double = 22     // pt; also governs column density
    var trailLen:      Int    = 24     // characters in the green tail
    var flickerChance: Double = 0.01   // probability a trail char mutates each frame
    var colorScheme:   Int    = 0      // 0 green  1 blue  2 red  3 white
    var useKatakana:   Bool   = true
    var useCyrillic:   Bool   = true
    var useDigits:     Bool   = true

    // MARK: – Persistence

    static func load() -> NeoMatrixConfig {
        guard let d = ScreenSaverDefaults(forModuleWithName: kBundleID) else {
            return NeoMatrixConfig()
        }
        d.register(defaults: [
            "speed": 0.35, "minSpeedPct": 0.30, "fontSize": 22.0, "trailLen": 24,
            "flickerChance": 0.01, "colorScheme": 0,
            "useKatakana": true, "useCyrillic": true, "useDigits": true,
        ])
        var c = NeoMatrixConfig()
        c.speed         = d.double(forKey: "speed")
        c.minSpeedPct   = max(0.05, min(1.0, d.double(forKey: "minSpeedPct")))
        c.fontSize      = d.double(forKey: "fontSize")
        c.trailLen      = max(4, d.integer(forKey: "trailLen"))
        c.flickerChance = d.double(forKey: "flickerChance")
        c.colorScheme   = d.integer(forKey: "colorScheme")
        c.useKatakana   = d.bool(forKey: "useKatakana")
        c.useCyrillic   = d.bool(forKey: "useCyrillic")
        c.useDigits     = d.bool(forKey: "useDigits")
        return c
    }

    func save() {
        guard let d = ScreenSaverDefaults(forModuleWithName: kBundleID) else { return }
        d.set(speed,         forKey: "speed")
        d.set(minSpeedPct,   forKey: "minSpeedPct")
        d.set(fontSize,      forKey: "fontSize")
        d.set(trailLen,      forKey: "trailLen")
        d.set(flickerChance, forKey: "flickerChance")
        d.set(colorScheme,   forKey: "colorScheme")
        d.set(useKatakana,   forKey: "useKatakana")
        d.set(useCyrillic,   forKey: "useCyrillic")
        d.set(useDigits,     forKey: "useDigits")
        d.synchronize()
    }

    // MARK: – Derived

    var minSpeed: Double { speed * minSpeedPct }

    var alphabet: [Character] {
        var chars: [Character] = []
        if useKatakana { chars += (0x30A0...0x30FF).compactMap { Unicode.Scalar($0).map(Character.init) } }
        if useCyrillic { chars += (0x0400...0x04FF).compactMap { Unicode.Scalar($0).map(Character.init) } }
        if useDigits   { chars += Array("0123456789") }
        return chars.isEmpty ? Array("01") : chars
    }

    func trailColor(at t: CGFloat) -> NSColor {
        let b = 0.07 + t * 0.78
        switch colorScheme {
        case 1:  return NSColor(red: 0,  green: b * 0.3, blue: b,        alpha: 1) // blue
        case 2:  return NSColor(red: b,  green: 0,       blue: b * 0.02, alpha: 1) // red
        case 3:  return NSColor(white: b,                                alpha: 1) // white
        default: return NSColor(red: 0,  green: b,       blue: 0.02,     alpha: 1) // green
        }
    }

    var headColor: NSColor { .white }

    var glowColor: CGColor {
        switch colorScheme {
        case 1:  return CGColor(red: 0,   green: 0.3, blue: 1.0,  alpha: 1)
        case 2:  return CGColor(red: 1,   green: 0.1, blue: 0.1,  alpha: 1)
        case 3:  return CGColor(red: 0.7, green: 0.7, blue: 1.0,  alpha: 1)
        default: return CGColor(red: 0,   green: 1,   blue: 0.25, alpha: 1)
        }
    }
}
