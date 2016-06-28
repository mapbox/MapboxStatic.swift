#if os(OSX)
    import Cocoa
#elseif os(watchOS)
    import WatchKit
#else
    import UIKit
#endif

typealias JSONDictionary = [String: AnyObject]

/// Indicates that an error occurred in MapboxStatic.
public let MBStaticErrorDomain = "MBStaticErrorDomain"

/// The Mapbox access token specified in the main application bundle’s Info.plist.
let defaultAccessToken = NSBundle.mainBundle().objectForInfoDictionaryKey("MGLMapboxAccessToken") as? String

/// The user agent string for any HTTP requests performed directly within this library.
let userAgent: String = {
    var components: [String] = []
    
    if let appName = NSBundle.mainBundle().infoDictionary?["CFBundleName"] as? String ?? NSBundle.mainBundle().infoDictionary?["CFBundleIdentifier"] as? String {
        let version = NSBundle.mainBundle().infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        components.append("\(appName)/\(version)")
    }
    
    let libraryBundle: NSBundle? = NSBundle(forClass: Snapshot.self)
    
    if let libraryName = libraryBundle?.infoDictionary?["CFBundleName"] as? String, version = libraryBundle?.infoDictionary?["CFBundleShortVersionString"] as? String {
        components.append("\(libraryName)/\(version)")
    }
    
    let system: String
    #if os(OSX)
        system = "macOS"
    #elseif os(iOS)
        system = "iOS"
    #elseif os(watchOS)
        system = "watchOS"
    #elseif os(tvOS)
        system = "tvOS"
    #elseif os(Linux)
        system = "Linux"
    #endif
    let systemVersion = NSProcessInfo().operatingSystemVersion
    components.append("\(system)/\(systemVersion.majorVersion).\(systemVersion.minorVersion).\(systemVersion.patchVersion)")
    
    let chip: String
    #if arch(x86_64)
        chip = "x86_64"
    #elseif arch(arm)
        chip = "arm"
    #elseif arch(arm64)
        chip = "arm64"
    #elseif arch(i386)
        chip = "i386"
    #endif
    components.append("(\(chip))")
    
    return components.joinWithSeparator(" ")
}()

@objc(MBSnapshotOptionsProtocol)
public protocol SnapshotOptionsProtocol: NSObjectProtocol {
    var path: String { get }
    var params: [NSURLQueryItem] { get }
}

/**
 A structure that determines what a snapshot depicts and how it is formatted.
 */
@objc(MBSnapshotOptions)
public class SnapshotOptions: NSObject, SnapshotOptionsProtocol {
    /**
     An image format supported by the classic Static API.
     */
    @objc(MBSnapshotFormat)
    public enum Format: Int {
        /// True-color Portable Network Graphics format.
        case PNG
        /// 32-color color-indexed Portable Network Graphics format.
        case PNG32
        /// 64-color color-indexed Portable Network Graphics format.
        case PNG64
        /// 128-color color-indexed Portable Network Graphics format.
        case PNG128
        /// 256-color color-indexed Portable Network Graphics format.
        case PNG256
        /// JPEG format at default quality.
        case JPEG
        /// JPEG format at 70% quality.
        case JPEG70
        /// JPEG format at 80% quality.
        case JPEG80
        /// JPEG format at 90% quality.
        case JPEG90
    }
    
    // MARK: Configuring the Map Data
    
    /**
     An array of [map identifiers](https://www.mapbox.com/help/define-map-id/) of the form `username.id`, identifying the [tile sets](https://www.mapbox.com/help/define-tileset/) to display in the snapshot. This array may not be empty.
     
     The order of the map identifiers in the array reflects their visible order in the snapshot, with the tile set identified at index 0 being the backmost tile set.
     */
    public var mapIdentifiers: [String]
    
    /**
     An array of overlays to draw atop the map.
     
     The order in which the overlays are drawn on the map is undefined.
     */
    public var overlays: [Overlay] = []
    
    /**
     The geographic coordinate at the center of the snapshot.
     
     If the value of this property is `nil`, the `zoomLevel` property is ignored and a center coordinate and zoom level are automatically chosen to fit any overlays specified in the `overlays` property. If the `overlays` property is also empty, the behavior is undefined.
     
     The default value of this property is `nil`.
     */
    public var centerCoordinate: CLLocationCoordinate2D?
    
    /**
     The zoom level of the snapshot.
     
     In addition to affecting the visual size and detail of features on the map, the zoom level may affect style properties that depend on the zoom level.
     
     At zoom level 0, the entire world map is 256 points wide and 256 points tall; at zoom level 1, it is 512×512 points; at zoom level 2, it is 1,024×1,024 points; and so on.
     */
    public var zoomLevel: Int?
    
    // MARK: Configuring the Image Output
    
    /**
     The format of the image to output.
     
     The default value of this property is `SnapshotOptions.Format.PNG`, causing the image to be output in true-color Portable Network Graphics format.
     */
    public var format: Format = .PNG
    
    /**
     The logical size of the image to output, measured in points.
     */
    public var size: CGSize
    
    #if os(OSX)
    /**
     The scale factor of the image.
     
     If you multiply the logical size of the image (stored in the `size` property) by the value in this property, you get the dimensions of the image in pixels.
     
     The default value of this property matches the natural scale factor associated with the main screen. However, only images with a scale factor of 1.0 or 2.0 are ever returned by the classic Static API, so a scale factor of 1.0 of less results in a 1× (standard-resolution) image, while a scale factor greater than 1.0 results in a 2× (high-resolution or Retina) image.
     */
    public var scale: CGFloat = NSScreen.mainScreen()?.backingScaleFactor ?? 1
    #elseif os(watchOS)
    /**
     The scale factor of the image.
     
     If you multiply the logical size of the image (stored in the `size` property) by the value in this property, you get the dimensions of the image in pixels.
     
     The default value of this property matches the natural scale factor associated with the screen. Images with a scale factor of 1.0 or 2.0 are ever returned by the classic Static API, so a scale factor of 1.0 of less results in a 1× (standard-resolution) image, while a scale factor greater than 1.0 results in a 2× (high-resolution or Retina) image.
     */
    public var scale: CGFloat = WKInterfaceDevice.currentDevice().screenScale
    #else
    /**
     The scale factor of the image.
     
     If you multiply the logical size of the image (stored in the `size` property) by the value in this property, you get the dimensions of the image in pixels.
     
     The default value of this property matches the natural scale factor associated with the main screen. However, only images with a scale factor of 1.0 or 2.0 are ever returned by the classic Static API, so a scale factor of 1.0 of less results in a 1× (standard-resolution) image, while a scale factor greater than 1.0 results in a 2× (high-resolution or Retina) image.
     */
    public var scale: CGFloat = UIScreen.mainScreen().scale
    #endif
    
    /**
     Initializes a snapshot options instance that causes a snapshotter object to automatically choose a center coordinate and zoom level that fits any overlays.
     
     After initializing a snapshot options instance with this initializer, set the `overlays` property to specify the overlays to fit the snapshot to.
     
     - parameter mapIdentifiers: An array of [map identifiers](https://www.mapbox.com/help/define-map-id/) of the form `username.id`, identifying the [tile sets](https://www.mapbox.com/help/define-tileset/) to display in the snapshot. This array may not be empty.
     - parameter size: The logical size of the image to output, measured in points.
     */
    public init(mapIdentifiers: [String], size: CGSize) {
        self.mapIdentifiers = mapIdentifiers
        self.size = size
    }
    
    /**
     Initializes a snapshot options instance that results in a snapshot centered at the given geographical coordinate and showing the given zoom level.
     
     - parameter mapIdentifiers: An array of [map identifiers](https://www.mapbox.com/help/define-map-id/) of the form `username.id`, identifying the [tile sets](https://www.mapbox.com/help/define-tileset/) to display in the snapshot. This array may not be empty.
     - parameter centerCoordinate: The geographic coordinate at the center of the snapshot.
     - parameter zoomLevel: The zoom level of the snapshot.
     - parameter size: The logical size of the image to output, measured in points.
     */
    public init(mapIdentifiers: [String], centerCoordinate: CLLocationCoordinate2D, zoomLevel: Int, size: CGSize) {
        self.mapIdentifiers = mapIdentifiers
        self.centerCoordinate = centerCoordinate
        self.zoomLevel = zoomLevel
        self.size = size
    }
    
    /**
     The path of the HTTP request URL corresponding to the options in this instance.
     
     - returns: An HTTP URL path.
     */
    public var path: String {
        assert(!mapIdentifiers.isEmpty, "At least one map identifier must be specified.")
        let tileSetComponent = mapIdentifiers.joinWithSeparator(",")
        
        let position: String
        if let centerCoordinate = centerCoordinate {
            position = "\(centerCoordinate.longitude),\(centerCoordinate.latitude),\(zoomLevel ?? 0)"
        } else {
            position = "auto"
        }
        
        if let zoomLevel = zoomLevel {
            assert(zoomLevel >= 0,  "minimum zoom is 0")
            assert(zoomLevel <= 20, "maximum zoom is 20")
        }
        
        assert(size.width <= 1_280, "maximum width is 1,280 points")
        assert(size.height <= 1_280, "maximum height is 1,280 points")
        
        assert(overlays.count <= 100, "maximum number of overlays is 100")
        
        let overlaysComponent: String
        if overlays.isEmpty {
            overlaysComponent = ""
        } else {
            overlaysComponent = "/" + overlays.map { return "\($0)" }.joinWithSeparator(",")
        }
        
        let formatComponent: String
        switch format {
        case .PNG:
            formatComponent = "png"
        case .PNG32:
            formatComponent = "png32"
        case .PNG64:
            formatComponent = "png64"
        case .PNG128:
            formatComponent = "png128"
        case .PNG256:
            formatComponent = "png256"
        case .JPEG:
            formatComponent = "jpg"
        case .JPEG70:
            formatComponent = "jpg70"
        case .JPEG80:
            formatComponent = "jpg80"
        case .JPEG90:
            formatComponent = "jpg90"
        }
        
        return "/v4/\(tileSetComponent)\(overlaysComponent)/\(position)/\(Int(round(size.width)))x\(Int(round(size.height)))\(scale > 1 ? "@2x" : "").\(formatComponent)"
    }
    
    /**
     The query component of the HTTP request URL corresponding to the options in this instance.
     
     - returns: The query URL component as an array of name/value pairs.
     */
    public var params: [NSURLQueryItem] {
        return []
    }
}

/**
 A structure that configures a standalone marker image and how it is formatted.
 */
@objc(MBMarkerOptions)
public class MarkerOptions: MarkerImage, SnapshotOptionsProtocol {
    #if os(OSX)
    /**
     The scale factor of the image.
     
     If you multiply the logical size of the image (stored in the `size` property) by the value in this property, you get the dimensions of the image in pixels.
     
     The default value of this property matches the natural scale factor associated with the main screen. However, only images with a scale factor of 1.0 or 2.0 are ever returned by the classic Static API, so a scale factor of 1.0 of less results in a 1× (standard-resolution) image, while a scale factor greater than 1.0 results in a 2× (high-resolution or Retina) image.
     */
    public var scale: CGFloat = NSScreen.mainScreen()?.backingScaleFactor ?? 1
    #elseif os(watchOS)
    /**
     The scale factor of the image.
     
     If you multiply the logical size of the image (stored in the `size` property) by the value in this property, you get the dimensions of the image in pixels.
     
     The default value of this property matches the natural scale factor associated with the screen. Images with a scale factor of 1.0 or 2.0 are ever returned by the classic Static API, so a scale factor of 1.0 of less results in a 1× (standard-resolution) image, while a scale factor greater than 1.0 results in a 2× (high-resolution or Retina) image.
     */
    public var scale: CGFloat = WKInterfaceDevice.currentDevice().screenScale
    #else
    /**
     The scale factor of the image.
     
     If you multiply the logical size of the image (stored in the `size` property) by the value in this property, you get the dimensions of the image in pixels.
     
     The default value of this property matches the natural scale factor associated with the main screen. However, only images with a scale factor of 1.0 or 2.0 are ever returned by the classic Static API, so a scale factor of 1.0 of less results in a 1× (standard-resolution) image, while a scale factor greater than 1.0 results in a 2× (high-resolution or Retina) image.
     */
    public var scale: CGFloat = UIScreen.mainScreen().scale
    #endif
    
    /**
     Initializes a marker options instance.
     
     - parameter size: The size of the marker.
     - parameter label: A label or Maki icon to place atop the pin.
     */
    private override init(size: Size, label: Label?) {
        super.init(size: size, label: label)
    }
    
    /**
     Initializes a marker options instance that results in a red marker labeled with an English letter.
     
     - parameter size: The size of the marker.
     - parameter letter: An English letter from A through Z to place atop the pin.
     */
    public convenience init(size: Size = .Small, letter: UniChar) {
        self.init(size: size, label: .Letter(Character(UnicodeScalar(letter))))
    }
    
    /**
     Initializes a marker options instance that results in a red marker labeled with a one- or two-digit number.
     
     - parameter size: The size of the marker.
     - parameter number: A number from 0 through 99 to place atop the pin.
     */
    public convenience init(size: Size = .Small, number: Int) {
        self.init(size: size, label: .Number(number))
    }
    
    /**
     Initializes a marker options instance that results in a red marker with a Maki icon.
     
     - parameter size: The size of the marker.
     - parameter iconName: The name of a [Maki](https://www.mapbox.com/maki-icons/) icon to place atop the pin.
     */
    public convenience init(size: Size = .Small, iconName: String) {
        self.init(size: size, label: .IconName(iconName))
    }
    
    /**
     The path of the HTTP request URL corresponding to the options in this instance.
     
     - returns: An HTTP URL path.
     */
    public var path: String {
        let labelComponent: String
        if let label = label {
            labelComponent = "-\(label)"
        } else {
            labelComponent = ""
        }
        
        return "/v4/marker/pin-\(size)\(labelComponent)+\(color.toHexString())\(scale > 1 ? "@2x" : "").png"
    }
    
    /**
     The query component of the HTTP request URL corresponding to the options in this instance.
     
     - returns: The query URL component as an array of name/value pairs.
     */
    public var params: [NSURLQueryItem] {
        return []
    }
}

/**
 A `Snapshot` instance represents a static snapshot of a map made by compositing one or more [raster tile sets](https://www.mapbox.com/help/define-tileset/#raster-tilesets) with optional overlays. With a snapshot instance, you can synchronously or asynchronously generate an image based on the options you provide via an HTTP request, or you can get the URL used to make this request. The image is obtained on demand from the [classic Mapbox Static API](https://www.mapbox.com/api-documentation/?language=Swift#static-classic).
 
 The snapshot image can be used in an image view (`UIImage` on iOS and tvOS, `NSImage` on OS X, `WKImage` on watchOS). To add interactivity, use the `MGLMapView` class provided by the [Mapbox iOS SDK](https://www.mapbox.com/ios-sdk/) or [Mapbox OS X SDK](https://github.com/mapbox/mapbox-gl-native/tree/master/platform/osx/). See the “[Custom raster style](https://www.mapbox.com/ios-sdk/examples/raster-styles/)” example to display a raster tile set in an `MGLMapView`.
 
 If you use `Snapshot` to display a [vector tile set](https://www.mapbox.com/help/define-tileset/#vector-tilesets), the snapshot image will depict a wireframe representation of the tile set. To generate a static, styled image of a vector tile set, use the [vector Mapbox Static API](https://www.mapbox.com/api-documentation/?language=Swift#static).
 */
@objc(MBSnapshot)
public class Snapshot: NSObject {
    #if os(OSX)
    public typealias Image = NSImage
    #else
    public typealias Image = UIImage
    #endif
    
    /**
     A closure (block) that processes the results of a snapshot request.
     
     - parameter image: The image data that was generated, or `nil` if an error occurred.
     - parameter error: The error that occurred, or `nil` if the snapshot was generated successfully.
     */
    public typealias CompletionHandler = (image: Image?, error: NSError?) -> Void
    
    /// Options that determine the contents and format of the output image.
    public let options: SnapshotOptionsProtocol
    
    /// The API endpoint to request the image from.
    private var apiEndpoint: String
    
    /// The Mapbox access token to associate the request with.
    private let accessToken: String
    
    /**
     Initializes a newly created snapshot instance with the given options and an optional access token and host.
     
     - parameter options: Options that determine the contents and format of the output image.
     - parameter accessToken: A Mapbox [access token](https://www.mapbox.com/help/define-access-token/). If an access token is not specified when initializing the snapshot object, it should be specified in the `MGLMapboxAccessToken` key in the main application bundle’s Info.plist.
     - parameter host: An optional hostname to the server API. The classic Mapbox Static API endpoint is used by default.
     */
    public init(options: SnapshotOptionsProtocol, accessToken: String?, host: String?) {
        let accessToken = accessToken ?? defaultAccessToken
        assert(accessToken != nil && !accessToken!.isEmpty, "A Mapbox access token is required. Go to <https://www.mapbox.com/studio/account/tokens/>. In Info.plist, set the MGLMapboxAccessToken key to your access token, or use the Snapshot(options:accessToken:host:) initializer.")
        
        self.options = options
        self.accessToken = accessToken!
        
        let baseURLComponents = NSURLComponents()
        baseURLComponents.scheme = "https"
        baseURLComponents.host = host ?? "api.mapbox.com"
        self.apiEndpoint = baseURLComponents.string!
    }
    
    /**
     Initializes a newly created snapshot instance with the given options and an optional access token.
     
     The snapshot instance sends requests to the classic Mapbox Static API endpoint.
     
     - parameter options: Options that determine the contents and format of the output image.
     - parameter accessToken: A Mapbox [access token](https://www.mapbox.com/help/define-access-token/). If an access token is not specified when initializing the snapshot object, it should be specified in the `MGLMapboxAccessToken` key in the main application bundle’s Info.plist.
     */
    public convenience init(options: SnapshotOptionsProtocol, accessToken: String?) {
        self.init(options: options, accessToken: accessToken, host: nil)
    }
    
    /**
     Initializes a newly created snapshot instance with the given options and the default access token.
     
     The snapshot instance sends requests to the classic Mapbox Static API endpoint.
     
     - parameter options: Options that determine the contents and format of the output image.
     */
    public convenience init(options: SnapshotOptionsProtocol) {
        self.init(options: options, accessToken: nil)
    }
    
    /**
     The HTTP URL used to fetch the snapshot image from the API.
     */
    public var URL: NSURL {
        let components = NSURLComponents()
        components.queryItems = params
        return NSURL(string: "\(apiEndpoint)\(options.path)?\(components.percentEncodedQuery!)")!
    }
    
    /**
     The query component of the HTTP request URL corresponding to the options in this instance.
     
     - returns: The query URL component as an array of name/value pairs.
     */
    private var params: [NSURLQueryItem] {
        return options.params + [
            NSURLQueryItem(name: "access_token", value: accessToken),
        ]
    }
    
    /**
     Returns an image based on the options in the `options` property.
     
     - attention: This property’s getter retrieves the image synchronously over a network connection, blocking the thread on which it is called. If a connection error or server error occurs, the getter returns `nil`. Consider using the asynchronous `image(completionHandler:)` method instead to avoid blocking the calling thread and to get more details about any error that may occur.
     */
    public var image: Image? {
        if let data = NSData(contentsOfURL: URL) {
            return Image(data: data)
        } else {
            return nil
        }
    }
    
    /**
     Submits the request to create a snapshot image and delivers the results to the given closure.
     
     This method retrieves the image asynchronously over a network connection. If a connection error or server error occurs, details about the error are passed into the given completion handler in lieu of an image.
     
     On OS X, you may need the same snapshot image at both Retina and non-Retina resolutions to accommodate different displays being connected to the computer. To obtain images at both resolutions, create two different `Snapshot` instances, each with a different `scale` option.
     
     - parameter completionHandler: The closure (block) to call with the resulting image. This closure is executed on the application’s main thread.
     - returns: The data task used to perform the HTTP request. If, while waiting for the completion handler to execute, you no longer want the resulting image, cancel this task.
     */
    public func image(completionHandler handler: CompletionHandler) -> NSURLSessionDataTask {
        let request = NSMutableURLRequest(URL: URL)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request) { (data, response, error) in
            var json: JSONDictionary = [:]
            var image: Image?
            if let data = data {
                do {
                    json = try NSJSONSerialization.JSONObjectWithData(data, options: []) as? JSONDictionary ?? json
                } catch {
                    image = Image(data: data)
                }
            }
            
            let apiMessage = json["message"] as? String
            guard image != nil && error == nil && apiMessage == nil else {
                let apiError = Snapshot.descriptiveError(json, response: response, underlyingError: error)
                dispatch_async(dispatch_get_main_queue()) {
                    handler(image: nil, error: apiError)
                }
                return
            }
            
            dispatch_async(dispatch_get_main_queue()) {
                handler(image: image, error: nil)
            }
        }
        task.resume()
        return task
    }
    
    /**
     Returns an error that supplements the given underlying error with additional information from the an HTTP response’s body or headers.
     */
    private static func descriptiveError(json: JSONDictionary, response: NSURLResponse?, underlyingError error: NSError?) -> NSError {
        var userInfo = error?.userInfo ?? [:]
        if let response = response as? NSHTTPURLResponse {
            var failureReason: String? = nil
            var recoverySuggestion: String? = nil
            switch response.statusCode {
            case 429:
                if let timeInterval = response.allHeaderFields["x-rate-limit-interval"] as? NSTimeInterval, maximumCountOfRequests = response.allHeaderFields["x-rate-limit-limit"] as? UInt {
                    let intervalFormatter = NSDateComponentsFormatter()
                    intervalFormatter.unitsStyle = .Full
                    let formattedInterval = intervalFormatter.stringFromTimeInterval(timeInterval)
                    let formattedCount = NSNumberFormatter.localizedStringFromNumber(maximumCountOfRequests, numberStyle: .DecimalStyle)
                    failureReason = "More than \(formattedCount) requests have been made with this access token within a period of \(formattedInterval)."
                }
                if let rolloverTimestamp = response.allHeaderFields["x-rate-limit-reset"] as? Double {
                    let date = NSDate(timeIntervalSince1970: rolloverTimestamp)
                    let formattedDate = NSDateFormatter.localizedStringFromDate(date, dateStyle: .LongStyle, timeStyle: .FullStyle)
                    recoverySuggestion = "Wait until \(formattedDate) before retrying."
                }
            default:
                failureReason = json["message"] as? String
            }
            userInfo[NSLocalizedFailureReasonErrorKey] = failureReason ?? userInfo[NSLocalizedFailureReasonErrorKey] ?? NSHTTPURLResponse.localizedStringForStatusCode(error?.code ?? -1)
            userInfo[NSLocalizedRecoverySuggestionErrorKey] = recoverySuggestion ?? userInfo[NSLocalizedRecoverySuggestionErrorKey]
        }
        userInfo[NSUnderlyingErrorKey] = error
        return NSError(domain: error?.domain ?? MBStaticErrorDomain, code: error?.code ?? -1, userInfo: userInfo)
    }
}
