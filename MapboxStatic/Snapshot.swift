import CoreLocation
#if os(OSX)
    import Cocoa
#else
    import UIKit
#endif

/**
 A structure that determines what a snapshot depicts and how it is formatted.
 */
public struct SnapshotOptions {
    /**
     An image format supported by the classic Static API.
     */
    public enum Format: String {
        /**
         True-color Portable Network Graphics format.
         */
        case PNG = "png"
        /// 32-color color-indexed Portable Network Graphics format.
        case PNG32 = "png32"
        /// 64-color color-indexed Portable Network Graphics format.
        case PNG64 = "png64"
        /// 128-color color-indexed Portable Network Graphics format.
        case PNG128 = "png128"
        /// 256-color color-indexed Portable Network Graphics format.
        case PNG256 = "png256"
        /// JPEG format at default quality.
        case JPEG = "jpg"
        /// JPEG format at 70% quality.
        case JPEG70 = "jpg70"
        /// JPEG format at 80% quality.
        case JPEG80 = "jpg80"
        /// JPEG format at 90% quality.
        case JPEG90 = "jpg90"
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
    
    /**
     The query component of the HTTP request URL corresponding to the options in this instance.
     
     - returns: The query URL component as an array of name/value pairs.
     */
    private var params: [NSURLQueryItem] {
        return []
    }
}

/**
 A `Snapshot` instance represents a static snapshot of a map made by compositing one or more [raster tile sets](https://www.mapbox.com/help/define-tileset/#raster-tilesets) with optional overlays. With a snapshot instance, you can synchronously or asynchronously generate an image based on the options you provide via an HTTP request, or you can get the URL used to make this request. The image is obtained on demand from the [classic Mapbox Static API](https://www.mapbox.com/api-documentation/?language=Swift#static-classic).
 
 The snapshot image can be used in an image view. To add interactivity, use the `MGLMapView` class provided by the [Mapbox iOS SDK](https://www.mapbox.com/ios-sdk/) or [Mapbox OS X SDK](https://github.com/mapbox/mapbox-gl-native/tree/master/platform/osx/). See the “[Custom raster style](https://www.mapbox.com/ios-sdk/examples/raster-styles/)” example to display a raster tile set in an `MGLMapView`.
 
 If you use `Snapshot` to display a [vector tile set](https://www.mapbox.com/help/define-tileset/#vector-tilesets), the snapshot image will depict a wireframe representation of the tile set. To generate a static, styled image of a vector tile set, use the [vector Mapbox Static API](https://www.mapbox.com/api-documentation/?language=Swift#static).
 */
public struct Snapshot {
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
    public let options: SnapshotOptions
    
    /// The API endpoint to request the image from.
    private var apiEndpoint: String = "https://api.mapbox.com"
    
    /// The Mapbox access token to associate the request with.
    private let accessToken: String
    
    /// The Mapbox access token specified in the main application bundle’s Info.plist.
    private static let defaultAccessToken = NSBundle.mainBundle().objectForInfoDictionaryKey("MGLMapboxAccessToken") as? String
    
    /**
     Initializes a newly created snapshot instance with the given options and an optional access token.
     
     - parameter options: Options that determine the contents and format of the output image.
     - parameter accessToken: A Mapbox [access token](https://www.mapbox.com/help/define-access-token/). If an access token is not specified when initializing the snapshot object, it should be specified in the `MGLMapboxAccessToken` key in the main application bundle’s Info.plist.
     - parameter host: An optional hostname to the server API. The classic Mapbox Static API endpoint is used by default.
     */
    public init(options: SnapshotOptions, accessToken: String = defaultAccessToken ?? "", host: String? = nil) {
        assert(!accessToken.isEmpty, "A Mapbox access token is required. Go to <https://www.mapbox.com/studio/account/tokens/>. In Info.plist, set the MGLMapboxAccessToken key to your access token, or use the Snapshot(options:accessToken:host:) initializer.")
        
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
     The HTTP URL used to fetch the snapshot image from the API.
     */
    public var requestURL: NSURL {
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
        if let data = NSData(contentsOfURL: requestURL) {
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
        let task = NSURLSession.sharedSession().dataTaskWithURL(requestURL) { (data, response, error) in
            if let error = error {
                dispatch_async(dispatch_get_main_queue()) {
                    handler(image: nil, error: error)
                }
            } else {
                let image = Image(data: data!)
                dispatch_async(dispatch_get_main_queue()) {
                    handler(image: image, error: nil)
                }
            }
        }
        task.resume()
        return task
    }
}
