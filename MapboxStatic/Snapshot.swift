import CoreLocation
import UIKit

public enum SnapshotFormat: String {
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

public struct SnapshotOptions {
    // MARK: Configuring the Map Data
    
    public var mapIdentifier: String
    public var overlays: [Overlay] = []
    public var centerCoordinate: CLLocationCoordinate2D? = nil
    public var zoomLevel: Int?
    
    // MARK: Configuring the Image Output
    
    public var format: SnapshotFormat = .PNG
    public var size: CGSize
    public var scale: CGFloat = UIScreen.mainScreen().scale
    public var showsAttribution: Bool = true
    public var showsLogo: Bool = true
    
    public init(mapIdentifier: String, size: CGSize) {
        self.mapIdentifier = mapIdentifier
        self.size = size
    }
    
    public init(mapIdentifier: String, centerCoordinate: CLLocationCoordinate2D, zoomLevel: Int, size: CGSize) {
        self.mapIdentifier = mapIdentifier
        self.centerCoordinate = centerCoordinate
        self.zoomLevel = zoomLevel
        self.size = size
    }
    
    private var path: String {
        let position: String
        if let centerCoordinate = centerCoordinate {
            position = "\(centerCoordinate.longitude),\(centerCoordinate.latitude),\(zoomLevel ?? 0)"
        } else {
            position = "auto"
        }
        
        let overlaysComponent: String
        if overlays.isEmpty {
            overlaysComponent = ""
        } else {
            overlaysComponent = "/" + overlays.map { return "\($0)" }.joinWithSeparator(",")
        }
        
        return "/v4/\(mapIdentifier)\(overlaysComponent)/\(position)/\(Int(round(size.width)))x\(Int(round(size.height)))\(scale > 1 ? "@2x" : "").\(format.rawValue)"
    }
    
    private var params: [NSURLQueryItem] {
        return [
            NSURLQueryItem(name: "attribution", value: "\(showsAttribution)"),
            NSURLQueryItem(name: "logo", value: "\(showsLogo)"),
        ]
    }
}

public typealias SnapshotCompletionHandler = (UIImage?, NSError?) -> Void

public struct Snapshot {
    private var apiEndpoint: String = "https://api.mapbox.com"
    private let accessToken: String
    
    public let options: SnapshotOptions
    
    /**
     Initializes a newly created snapshot object with the given options and an optional access token.
     
     - param options: Options that determine the output and the data depicted in that output.
     - param accessToken: A Mapbox access token.
     - param host: An optional hostname to the server API. The classic Mapbox Static API endpoint is used by default.
     */
    public init(options: SnapshotOptions, accessToken: String, host: String? = nil) {
        self.options = options
        self.accessToken = accessToken
        if let host = host {
            let baseURLComponents = NSURLComponents()
            baseURLComponents.scheme = "https"
            baseURLComponents.host = host
            apiEndpoint = baseURLComponents.string ?? apiEndpoint
        }
        
        if let zoomLevel = options.zoomLevel {
            assert(zoomLevel >= 0,  "minimum zoom is 0")
            assert(zoomLevel <= 20, "maximum zoom is 20")
        }
        
        assert(options.scale == 1 || options.scale == 2, "scale must be 1× or 2×")
        
        assert(options.size.width  * options.scale <= 1_280, "maximum width is 1,280 pixels (640 points @2×)")
        assert(options.size.height * options.scale <= 1_280, "maximum height is 1,280 pixels (640 points @2×)")
        
        assert(options.overlays.count <= 100, "maximum number of overlays is 100")
    }
    
    /**
     Initializes a newly created snapshot object with the given options and the default access token.
     
     The default access token is specified by the `MGLMapboxAccessToken` key in the main application bundle’s Info.plist.
     
     - param options: Options that determine the output and the data depicted in that output.
     - param host: An optional hostname to the server API. The classic Mapbox Static API endpoint is used by default.
     */
    public init(options: SnapshotOptions, host: String? = nil) {
        let accessToken = NSBundle.mainBundle().objectForInfoDictionaryKey("MGLMapboxAccessToken") as? String
        assert(accessToken != nil, "A Mapbox access token is required. Go to <https://www.mapbox.com/studio/account/tokens/>. In Info.plist, set the MGLMapboxAccessToken key to your access token, or use the Snapshot(options:accessToken:host:) initializer.")
        self.init(options: options, accessToken: accessToken ?? "", host: host)
    }
    
    public var requestURL: NSURL {
        let components = NSURLComponents()
        components.queryItems = params
        return NSURL(string: "\(apiEndpoint)\(options.path)?\(components.percentEncodedQuery!)")!
    }
    
    private var params: [NSURLQueryItem] {
        return options.params + [
            NSURLQueryItem(name: "access_token", value: accessToken),
        ]
    }
    
    public var image: UIImage? {
        if let data = NSData(contentsOfURL: requestURL) {
            return UIImage(data: data)
        } else {
            return nil
        }
    }
    
    public func image(completionHandler handler: SnapshotCompletionHandler) -> NSURLSessionDataTask {
        let task = NSURLSession.sharedSession().dataTaskWithURL(requestURL) { (data, response, error) in
            if let error = error {
                dispatch_async(dispatch_get_main_queue()) {
                    handler(nil, error)
                }
            } else {
                let image = UIImage(data: data!)
                dispatch_async(dispatch_get_main_queue()) {
                    handler(image, nil)
                }
            }
        }
        task.resume()
        return task
    }
}
