#if os(OSX)
    import Cocoa
    typealias Color = NSColor
#else
    import UIKit
    typealias Color = UIColor
#endif

internal extension Color {
    internal func toHexString() -> String {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0

        let color: Color
        #if os(OSX)
            color = colorUsingColorSpaceName(NSCalibratedRGBColorSpace)!
        #else
            color = self
        #endif
        color.getRed(&r, green: &g, blue: &b, alpha: &a)

        r *= 255
        g *= 255
        b *= 255

        return NSString(format: "%02x%02x%02x", Int(r), Int(g), Int(b)) as String
    }

    convenience init(hexString: String) {
        var hexString = hexString.stringByReplacingOccurrencesOfString("#", withString: "")

        if hexString.lengthOfBytesUsingEncoding(NSUTF8StringEncoding) == 3 {
            let r = Array(arrayLiteral: hexString)[0]
            let g = Array(arrayLiteral: hexString)[1]
            let b = Array(arrayLiteral: hexString)[2]

            hexString = r + r + g + g + b + b
        }

        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        
        if hexString.lengthOfBytesUsingEncoding(NSUTF8StringEncoding) == 6 {
            var hexInt: UInt32 = 0

            if NSScanner(string: hexString).scanHexInt(&hexInt) {
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
