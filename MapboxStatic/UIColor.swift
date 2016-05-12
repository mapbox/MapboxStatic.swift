import UIKit

internal extension UIColor {

    internal func toHexString() -> String {

        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0

        self.getRed(&r, green: &g, blue: &b, alpha: &a)

        r *= 255
        g *= 255
        b *= 255

        return NSString(format: "%02x%02x%02x", Int(r), Int(g), Int(b)) as String
    }

    internal class func colorWithHexString(hexString: String) -> UIColor {

        var hexString = hexString.stringByReplacingOccurrencesOfString("#", withString: "")

        if hexString.lengthOfBytesUsingEncoding(NSUTF8StringEncoding) == 3 {
            let r = Array(arrayLiteral: hexString)[0]
            let g = Array(arrayLiteral: hexString)[1]
            let b = Array(arrayLiteral: hexString)[2]

            hexString = r + r + g + g + b + b
        }

        if hexString.lengthOfBytesUsingEncoding(NSUTF8StringEncoding) == 6 {
            var r: CGFloat = 0
            var g: CGFloat = 0
            var b: CGFloat = 0

            var hexInt: UInt32 = 0

            if NSScanner(string: hexString).scanHexInt(&hexInt) {
                r = CGFloat((hexInt >> 16) & 0xff) / 255
                g = CGFloat((hexInt >> 8) & 0xff) / 255
                b = CGFloat(hexInt & 0xff) / 255

                return UIColor(red: r, green: g, blue: b, alpha: 1)
            }
        }

        return UIColor.blackColor()
    }
}
