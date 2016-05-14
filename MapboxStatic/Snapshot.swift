import CoreLocation
#if os(iOS)
    import UIKit
#elseif os(OSX)
    import Cocoa
#endif

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

/**
 A structure that determines what a snapshot depicts and how it is formatted.
 */
public struct SnapshotOptions {
    // MARK: Configuring the Map Data
    
    /**
     An array of [map identifiers](https://www.mapbox.com/help/define-map-id/) of the form `username.id`, identifying the [tile sets](https://www.mapbox.com/help/define-tileset/) to display in the snapshot. This array may not be empty.
     
     The order of the map identifiers in the array reflects their visible order in the snapshot, with the tile set identified at index 0 being the backmost tile set.
     */
    public var mapIdentifiers: [String]
    public var overlays: [Overlay] = []
    public var centerCoordinate: CLLocationCoordinate2D? = nil
    public var zoomLevel: Int?
    
    // MARK: Configuring the Image Output
    
    public var format: SnapshotFormat = .PNG
    public var size: CGSize
    #if os(iOS)
    public var scale: CGFloat = UIScreen.mainScreen().scale
    #elseif os(OSX)
    public var scale: CGFloat = NSScreen.mainScreen()?.backingScaleFactor ?? 1
    #endif
    public var showsAttribution: Bool = true
    public var showsLogo: Bool = true
    
    public init(mapIdentifiers: [String], size: CGSize) {
        self.mapIdentifiers = mapIdentifiers
        self.size = size
    }
    
    public init(mapIdentifiers: [String], centerCoordinate: CLLocationCoordinate2D, zoomLevel: Int, size: CGSize) {
        self.mapIdentifiers = mapIdentifiers
        self.centerCoordinate = centerCoordinate
        self.zoomLevel = zoomLevel
        self.size = size
    }
    
    private var path: String {
        assert(!mapIdentifiers.isEmpty, "At least one map identifier must be specified.")
        let tileSetComponent = mapIdentifiers.joinWithSeparator(",")
        
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
        
        return "/v4/\(tileSetComponent)\(overlaysComponent)/\(position)/\(Int(round(size.width)))x\(Int(round(size.height)))\(scale > 1 ? "@2x" : "").\(format.rawValue)"
    }
    
    private var params: [NSURLQueryItem] {
        return [
            NSURLQueryItem(name: "attribution", value: "\(showsAttribution)"),
            NSURLQueryItem(name: "logo", value: "\(showsLogo)"),
        ]
    }
}

public struct Snapshot {
    #if os(iOS)
    public typealias Image = UIImage
    #elseif os(OSX)
    public typealias Image = NSImage
    #endif
    public typealias CompletionHandler = (Image?, NSError?) -> Void
    
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
    
    public var image: Image? {
        if let data = NSData(contentsOfURL: requestURL) {
            return Image(data: data)
        } else {
            return nil
        }
    }
    
    public func image(completionHandler handler: CompletionHandler) -> NSURLSessionDataTask {
        let task = NSURLSession.sharedSession().dataTaskWithURL(requestURL) { (data, response, error) in
            if let error = error {
                dispatch_async(dispatch_get_main_queue()) {
                    handler(nil, error)
                }
            } else {
                let image = Image(data: data!)
                dispatch_async(dispatch_get_main_queue()) {
                    handler(image, nil)
                }
            }
        }
        task.resume()
        return task
    }
}
