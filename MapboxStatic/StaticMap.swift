import CoreLocation
import UIKit

public class StaticMap {

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

        public static let allValues = [PNG, PNG256, PNG128, PNG64, PNG32, JPEG, JPEG90, JPEG80, JPEG70]
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

    internal class func allowedCharacterSet() -> NSMutableCharacterSet {
        let characterSet = NSCharacterSet.URLQueryAllowedCharacterSet().mutableCopy() as! NSMutableCharacterSet
        characterSet.removeCharactersInString("/")
        return characterSet
    }

    public init(mapID: String,
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

}
