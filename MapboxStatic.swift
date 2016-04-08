import CoreLocation
import Foundation
import UIKit

private extension UIColor {

    private func toHexString() -> String {

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

    private class func colorWithHexString(hexString: String) -> UIColor {

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

public class MapboxStaticMap {

    private let requestURLStringBase = "https://api.mapbox.com/v4/"

    public enum ImageFormat: String {
        case PNG    = "png"
        case PNG256 = "png256"
        case PNG128 = "png128"
        case PNG64  = "png64"
        case PNG32  = "png32"
        case JPEG   = "jpg"
        case JPEG90 = "jpg90"
        case JPEG80 = "jpg80"
        case JPEG70 = "jpg70"

        static let allValues = [PNG, PNG256, PNG128, PNG64, PNG32, JPEG, JPEG90, JPEG80, JPEG70]
    }

    private(set) var requestURL: NSURL

    public var image: UIImage? {
        get {
            if let data = NSData(contentsOfURL: self.requestURL) {
                return UIImage(data: data)
            } else {
                return nil
            }
        }
    }

    public func imageWithCompletionHandler(handler: (UIImage? -> Void)) {
        let task = NSURLSession.sharedSession().dataTaskWithURL(requestURL, completionHandler: { (data: NSData?, response: NSURLResponse?, error: NSError?) in
            let image = UIImage(data: data!)
            dispatch_async(dispatch_get_main_queue()) {
                handler(image)
            }
        })
        task.resume()
    }

    private class func allowedCharacterSet() -> NSMutableCharacterSet {
        let characterSet = NSCharacterSet.URLQueryAllowedCharacterSet().mutableCopy() as! NSMutableCharacterSet
        characterSet.removeCharactersInString("/")
        return characterSet
    }

    init(mapID: String,
         center: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 0, longitude: 0),
         zoom: Int = 0,
         size: CGSize,
         accessToken: String,
         format: ImageFormat = .PNG,
         retina: Bool = false,
         overlays: [Overlay] = [],
         autoFitFeatures: Bool = false) {

        assert(zoom >= 0,  "minimum zoom is 0")
        assert(zoom <= 20, "maximum zoom is 20")

        assert(size.width  <= 640 * (retina ? 1 : 2), "maximum width is 1280px (640px for retina)")
        assert(size.height <= 640 * (retina ? 1 : 2), "maximum height is 1280px (640px for retina)")

        assert(overlays.count <= 100, "maximum number of overlays is 100")

        var requestURLString = requestURLStringBase
        requestURLString += mapID
        requestURLString += "/"

        if overlays.count > 0 {
            requestURLString += overlays.map({ return $0.requestString }).joinWithSeparator(",")
            requestURLString += "/"
        }

        if autoFitFeatures {
            requestURLString += "auto/"
        } else {
            requestURLString += "\(center.longitude),\(center.latitude),\(zoom)/"
        }

        requestURLString += "\(Int(size.width))x\(Int(size.height))"
        requestURLString += (retina ? "@2x" : "")
        requestURLString += "."
        requestURLString += format.rawValue
        requestURLString += "?access_token="
        requestURLString += accessToken

        requestURL = NSURL(string: requestURLString)!
    }

    public enum MarkerSize: String {
        case Small  = "s"
        case Medium = "m"
        case Large  = "l"
    }

    public class Overlay {

        private var requestString: String = ""

    }

    public class Marker: Overlay {

        init(coordinate: CLLocationCoordinate2D,
             size: MarkerSize = .Small,
             label: String = "",
             color: UIColor = UIColor.redColor()) {

            super.init()

            requestString = "pin-"
            requestString += size.rawValue

            if label.lengthOfBytesUsingEncoding(NSUTF8StringEncoding) > 0 {
                requestString += "-" + label
            }

            requestString += "+" + color.toHexString()
            requestString += "(\(coordinate.longitude),\(coordinate.latitude))"

        }

    }

    public class CustomMarker: Overlay {

        init(coordinate: CLLocationCoordinate2D,
             URLString: String) {

            super.init()

            requestString = "url-"
            requestString += URLString.stringByAddingPercentEncodingWithAllowedCharacters(MapboxStaticMap.allowedCharacterSet())!
            requestString += "(\(coordinate.longitude),\(coordinate.latitude))"
        }

    }

    public class GeoJSON: Overlay {

        init(string: String) {

            super.init()

            requestString = "geojson("
            requestString += string.stringByAddingPercentEncodingWithAllowedCharacters(MapboxStaticMap.allowedCharacterSet())!
            requestString += ")"

        }

    }

    public class Path: Overlay {

        // based on https://github.com/mapbox/polyline

        private func polylineEncode(coordinates: [CLLocationCoordinate2D]) -> String {

            func encodeCoordinate(let coordinate: CLLocationDegrees) -> String {

                var c = Int(round(coordinate * 1e5))

                c = c << 1

                if c < 0 {
                    c = ~c
                }

                var output = ""

                while c >= 0x20 {
                    output += String(UnicodeScalar((0x20 | (c & 0x1f)) + 63))
                    c = c >> 5
                }

                output += String(UnicodeScalar(c + 63))

                return output
            }

            var output = encodeCoordinate(coordinates[0].latitude) + encodeCoordinate(coordinates[0].longitude)

            for i in 1 ..< coordinates.count {
                let a = coordinates[i]
                let b = coordinates[i - 1]
                output += encodeCoordinate(a.latitude - b.latitude)
                output += encodeCoordinate(a.longitude - b.longitude)
            }

            return output.stringByAddingPercentEncodingWithAllowedCharacters(MapboxStaticMap.allowedCharacterSet())!
        }

        init(pathCoordinates: [CLLocationCoordinate2D],
             strokeWidth: Int = 1,
             strokeColor: UIColor = UIColor.colorWithHexString("555"),
             strokeOpacity: Double = 1.0,
             fillColor: UIColor = UIColor.colorWithHexString("555"),
             fillOpacity: Double = 0) {

            super.init()

            requestString = "path"
            requestString += "-\(strokeWidth)"
            requestString += "+" +  strokeColor.toHexString()
            requestString += "-\(strokeOpacity)"
            requestString += "+" + fillColor.toHexString()
            requestString += "-\(fillOpacity)"
            requestString += "("
            requestString += polylineEncode(pathCoordinates)
            requestString += ")"

        }

    }

}
