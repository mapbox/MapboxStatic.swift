#if os(OSX)
    import Cocoa
    typealias Color = NSColor
#else
    import UIKit
    typealias Color = UIColor
#endif

internal extension Color {
    @nonobjc func toHexString() -> String {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0

        let color: Color
        #if os(OSX)
        color = usingColorSpaceName(NSColorSpaceName.calibratedRGB)!
        #else
            color = self
        #endif
        color.getRed(&r, green: &g, blue: &b, alpha: &a)

        r *= 255
        g *= 255
        b *= 255

        return NSString(format: "%02x%02x%02x", Int(r), Int(g), Int(b)) as String
    }
    
    #if !os(macOS)
    internal var alphaComponent: CGFloat {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        
        getRed(&r, green: &g, blue: &b, alpha: &a)
        
        return a
    }
    #endif

    convenience init(hexString: String) {
        var hexString = hexString.replacingOccurrences(of: "#", with: "")

        if hexString.count == 3 {
            let digits = Array(hexString)
            hexString = "\(digits[0])\(digits[0])\(digits[1])\(digits[1])\(digits[2])\(digits[2])"
        }

        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        
        if hexString.count == 6 {
            var hexInt: UInt32 = 0

            if Scanner(string: hexString).scanHexInt32(&hexInt) {
                r = CGFloat((hexInt >> 16) & 0xff) / 255
                g = CGFloat((hexInt >> 8) & 0xff) / 255
                b = CGFloat(hexInt & 0xff) / 255
            }
        }

        #if os(OSX)
            self.init(calibratedRed: r, green: g, blue: b, alpha: 1)
        #else
            self.init(red: r, green: g, blue: b, alpha: 1)
        #endif
    }
}
