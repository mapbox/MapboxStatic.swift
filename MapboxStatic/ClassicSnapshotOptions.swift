#if os(OSX)
    import Cocoa
#elseif os(watchOS)
    import WatchKit
#else
    import UIKit
#endif

/**
 A structure that determines what a snapshot depicts and how it is formatted. A classic snapshot is made by compositing one or more [tile sets](https://www.mapbox.com/help/define-tileset/) with optional overlays using the [classic Mapbox Static API](https://www.mapbox.com/api-documentation/?language=Swift#static-classic).
 
 Typically, you use a `ClassicSnapshotOptions` object to generate a snapshot of a [raster tile set](https://www.mapbox.com/help/define-tileset/#raster-tilesets). If you use `ClassicSnapshotOptions` to display a [vector tile set](https://www.mapbox.com/help/define-tileset/#vector-tilesets), the snapshot image will depict a wireframe representation of the tile set. To generate a static, styled image of a vector tile set, use a `SnapshotOptions` object.
 */
@objc(MBClassicSnapshotOptions)
open class ClassicSnapshotOptions: NSObject, SnapshotOptionsProtocol {
    /**
     An image format supported by the classic Static API.
     */
    @objc(MBSnapshotFormat)
    public enum Format: Int, CustomStringConvertible {
        /// True-color Portable Network Graphics format.
        case png
        /// 32-color color-indexed Portable Network Graphics format.
        case png32
        /// 64-color color-indexed Portable Network Graphics format.
        case png64
        /// 128-color color-indexed Portable Network Graphics format.
        case png128
        /// 256-color color-indexed Portable Network Graphics format.
        case png256
        /// JPEG format at default quality.
        case jpeg
        /// JPEG format at 70% quality.
        case jpeg70
        /// JPEG format at 80% quality.
        case jpeg80
        /// JPEG format at 90% quality.
        case jpeg90
        
        public var description: String {
            switch self {
            case .png:
                return "png"
            case .png32:
                return "png32"
            case .png64:
                return "png64"
            case .png128:
                return "png128"
            case .png256:
                return "png256"
            case .jpeg:
                return "jpg"
            case .jpeg70:
                return "jpg70"
            case .jpeg80:
                return "jpg80"
            case .jpeg90:
                return "jpg90"
            }
        }
    }
    
    // MARK: Configuring the Map Data
    
    /**
     An array of [map identifiers](https://www.mapbox.com/help/define-map-id/) of the form `username.id`, identifying the [tile sets](https://www.mapbox.com/help/define-tileset/) to display in the snapshot. This array may not be empty.
     
     The order of the map identifiers in the array reflects their visible order in the snapshot, with the tile set identified at index 0 being the backmost tile set.
     */
    @objc open var mapIdentifiers: [String]
    
    /**
     An array of overlays to draw atop the map.
     
     The order in which the overlays are drawn on the map is undefined.
     */
    @objc open var overlays: [Overlay] = []
    
    /**
     The geographic coordinate at the center of the snapshot.
     
     If the value of this property is `nil`, the `zoomLevel` property is ignored and a center coordinate and zoom level are automatically chosen to fit any overlays specified in the `overlays` property. If the `overlays` property is also empty, the behavior is undefined.
     
     The default value of this property is `nil`.
     */
    open var centerCoordinate: CLLocationCoordinate2D?
    
    /**
     The zoom level of the snapshot.
     
     In addition to affecting the visual size and detail of features on the map, the zoom level may affect style properties that depend on the zoom level.
     
     `ClassicSnapshotOptions` zoom levels differ from `SnapshotCamera` zoom levels. At zoom level 0, the entire world map is 256 points wide and 256 points tall; at zoom level 1, it is 512×512 points; at zoom level 2, it is 1,024×1,024 points; and so on.
     */
    open var zoomLevel: Int?
    
    // MARK: Configuring the Image Output
    
    /**
     The format of the image to output.
     
     The default value of this property is `SnapshotOptions.Format.png`, causing the image to be output in true-color Portable Network Graphics format.
     */
    @objc open var format: Format = .png
    
    /**
     The logical size of the image to output, measured in points.
     */
    @objc open var size: CGSize
    
    #if os(OSX)
    /**
     The scale factor of the image.
     
     If you multiply the logical size of the image (stored in the `size` property) by the value in this property, you get the dimensions of the image in pixels.
     
     The default value of this property matches the natural scale factor associated with the main screen. However, only images with a scale factor of 1.0 or 2.0 are ever returned by the classic Static API, so a scale factor of 1.0 of less results in a 1× (standard-resolution) image, while a scale factor greater than 1.0 results in a 2× (high-resolution or Retina) image.
     */
    @objc open var scale: CGFloat = NSScreen.main?.backingScaleFactor ?? 1
    #elseif os(watchOS)
    /**
     The scale factor of the image.
     
     If you multiply the logical size of the image (stored in the `size` property) by the value in this property, you get the dimensions of the image in pixels.
     
     The default value of this property matches the natural scale factor associated with the screen. Images with a scale factor of 1.0 or 2.0 are ever returned by the classic Static API, so a scale factor of 1.0 of less results in a 1× (standard-resolution) image, while a scale factor greater than 1.0 results in a 2× (high-resolution or Retina) image.
     */
    @objc open var scale: CGFloat = WKInterfaceDevice.current().screenScale
    #else
    /**
     The scale factor of the image.
     
     If you multiply the logical size of the image (stored in the `size` property) by the value in this property, you get the dimensions of the image in pixels.
     
     The default value of this property matches the natural scale factor associated with the main screen. However, only images with a scale factor of 1.0 or 2.0 are ever returned by the classic Static API, so a scale factor of 1.0 of less results in a 1× (standard-resolution) image, while a scale factor greater than 1.0 results in a 2× (high-resolution or Retina) image.
     */
    @objc open var scale: CGFloat = UIScreen.main.scale
    #endif
    
    /**
     Initializes a snapshot options instance that causes a snapshotter object to automatically choose a center coordinate and zoom level that fits any overlays.
     
     After initializing a snapshot options instance with this initializer, set the `overlays` property to specify the overlays to fit the snapshot to.
     
     - parameter mapIdentifiers: An array of [map identifiers](https://www.mapbox.com/help/define-map-id/) of the form `username.id`, identifying the [tile sets](https://www.mapbox.com/help/define-tileset/) to display in the snapshot. This array may not be empty.
     - parameter size: The logical size of the image to output, measured in points.
     */
    @objc public init(mapIdentifiers: [String], size: CGSize) {
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
    @objc public init(mapIdentifiers: [String], centerCoordinate: CLLocationCoordinate2D, zoomLevel: Int, size: CGSize) {
        self.mapIdentifiers = mapIdentifiers
        self.centerCoordinate = centerCoordinate
        self.zoomLevel = zoomLevel
        self.size = size
    }
    
    /**
     The path of the HTTP request URL corresponding to the options in this instance.
     
     - returns: An HTTP URL path.
     */
    @objc open var path: String {
        assert(!mapIdentifiers.isEmpty, "At least one map identifier must be specified.")
        let tileSetComponent = mapIdentifiers.joined(separator: ",")
        
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
            overlaysComponent = "/" + overlays.map { return "\($0)" }.joined(separator: ",")
        }
        
        return "/v4/\(tileSetComponent)\(overlaysComponent)/\(position)/\(Int(round(size.width)))x\(Int(round(size.height)))\(scale > 1 ? "@2x" : "").\(format)"
    }
    
    /**
     The query component of the HTTP request URL corresponding to the options in this instance.
     
     - returns: The query URL component as an array of name/value pairs.
     */
    @objc open var params: [URLQueryItem] {
        return []
    }
}
