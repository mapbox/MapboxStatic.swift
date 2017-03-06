#if os(OSX)
    import Cocoa
#elseif os(watchOS)
    import WatchKit
#else
    import UIKit
#endif

/**
 A structure defining the viewpoint from which a snapshot is taken.
 */
@objc(MBSnapshotCamera)
open class SnapshotCamera: NSObject {
    /**
     The geographic coordinate at the center of the snapshot.
     
     If the value of this property is `nil`, the `zoomLevel` property is ignored and a center coordinate and zoom level are automatically chosen to fit any overlays specified in the `overlays` property. If the `overlays` property is also empty, the behavior is undefined.
     */
    open var centerCoordinate: CLLocationCoordinate2D
    
    /**
     The zoom level of the snapshot.
     
     In addition to affecting the visual size and detail of features on the map, the zoom level may affect style properties that depend on the zoom level.
     
     `SnapshotCamera` zoom levels differ from `ClassicSnapshotOptions` zoom levels. At zoom level 0, the entire world map is 512 points wide and 512 points tall; at zoom level 1, it is 1,024×1,024 points; at zoom level 2, it is 2,048×2,048 points; and so on. When the map is tilted, the zoom level affects the viewing distance from the viewer to the center coordinate.
     
     The zoom level may not be less than 0 or greater than 20. Fractional zoom levels are rounded to two decimal places.
     */
    open var zoomLevel: CGFloat
    
    /**
     The heading measured in degrees clockwise from true north.
     */
    open var heading: CLLocationDirection?
    
    /**
     The pitch toward the horizon measured in degrees, with 0 degrees resulting in a two-dimensional map.
     
     The pitch may not be less than 0 or greater than 60.
     */
    open var pitch: CGFloat?
    
    /**
     Initializes a snapshot camera instance based on the given center coordinate and zoom level.
     
     - parameter centerCoordinate: The geographic coordinate on which the shapshot should be centered.
     - parameter zoomLevel: The zoom level of the snapshot.
     */
    init(lookingAtCenter centerCoordinate: CLLocationCoordinate2D, zoomLevel: CGFloat) {
        self.centerCoordinate = centerCoordinate
        self.zoomLevel = zoomLevel
    }
    
    open override var description: String {
        var components = [centerCoordinate.longitude, centerCoordinate.latitude, Double(zoomLevel)]
        if let heading = heading {
            components.append(heading)
        }
        if let pitch = pitch {
            components.append(Double(pitch))
        }
        return components.map { "\($0)" }.joined(separator: ",")
    }
}

/**
 A structure that determines what a snapshot depicts and how it is formatted. A static snapshot is made by compositing a [style](https://www.mapbox.com/help/define-style/) with optional overlays using the [Mapbox Static API](https://www.mapbox.com/api-documentation/#static). You can use a [Mapbox-designed style](https://www.mapbox.com/api-documentation/#styles) or design your own custom style using [Mapbox Studio](https://www.mapbox.com/studio/). You can only snapshot a style hosted by Mapbox.
 
 To generate a static, styled image of a tile set, especially a raster tile set, use a `Classic SnapshotOptions` object.
 
 The Static API always outputs images in true-color Portable Network Graphics (PNG) format. For other image formats, use a `ClassicSnapshotOptions` object.
 */
@objc(MBSnapshotOptions)
open class SnapshotOptions: NSObject, SnapshotOptionsProtocol {
    // MARK: Configuring the Map Data
    
    /**
     The [style URL](https://www.mapbox.com/help/define-style-url/) of the style to snapshot.
     
     Only `mapbox:` URLs are supported. You can only snapshot a style hosted by Mapbox, such as a [Mapbox-designed style](https://www.mapbox.com/api-documentation/#styles).
     */
    open var styleURL: URL
    
    /**
     An array of overlays to draw atop the map.
     
     The order in which the overlays are drawn on the map is undefined.
     */
    open var overlays: [Overlay] = []
    
    /**
     The identifier of the [style layer](https://www.mapbox.com/help/define-layer/) below which any overlays should be inserted.
     
     This property allows you to insert overlays at any level of the map, not necessarily at the top. For example, if you are adding `Path` overlays to the snapshot, you may want to place them below any [symbol layers](https://www.mapbox.com/mapbox-gl-js/style-spec/#layer-type) to ensure that street and point of interest labels remain legible.
     
     If this property is set to `nil`, any overlays are placed atop any layers defined by the style. By default, this property is set to `nil`.
     
     Layer identifiers are not guaranteed to exist across styles or different versions of the same style. To find out the layer identifiers in a particular style, view the style in [Mapbox Studio](https://www.mapbox.com/studio/).
     */
    open var identifierOfLayerAboveOverlays: String?
    
    /**
     The viewpoint from which the snapshot is taken.
     */
    open var camera: SnapshotCamera
    
    // MARK: Configuring the Image Output
    
    /**
     The logical size of the image to output, measured in points.
     
     The width may not be less than 1 point or greater than 1,280 points. Likewise, the height may not be less than 1 point or greater than 1,280 points.
     */
    open var size: CGSize
    
    #if os(OSX)
    /**
     The scale factor of the image.
     
     If you multiply the logical size of the image (stored in the `size` property) by the value in this property, you get the dimensions of the image in pixels.
     
     The default value of this property matches the natural scale factor associated with the main screen. However, only images with a scale factor of 1.0 or 2.0 are ever returned by the Static API, so a scale factor of 1.0 of less results in a 1× (standard-resolution) image, while a scale factor greater than 1.0 results in a 2× (high-resolution or Retina) image.
     */
    open var scale: CGFloat = NSScreen.main()?.backingScaleFactor ?? 1
    #elseif os(watchOS)
    /**
     The scale factor of the image.
     
     If you multiply the logical size of the image (stored in the `size` property) by the value in this property, you get the dimensions of the image in pixels.
     
     The default value of this property matches the natural scale factor associated with the screen. Images with a scale factor of 1.0 or 2.0 are ever returned by the Static API, so a scale factor of 1.0 of less results in a 1× (standard-resolution) image, while a scale factor greater than 1.0 results in a 2× (high-resolution or Retina) image.
     */
    open var scale: CGFloat = WKInterfaceDevice.current().screenScale
    #else
    /**
     The scale factor of the image.
     
     If you multiply the logical size of the image (stored in the `size` property) by the value in this property, you get the dimensions of the image in pixels.
     
     The default value of this property matches the natural scale factor associated with the main screen. However, only images with a scale factor of 1.0 or 2.0 are ever returned by the Static API, so a scale factor of 1.0 of less results in a 1× (standard-resolution) image, while a scale factor greater than 1.0 results in a 2× (high-resolution or Retina) image.
     */
    open var scale: CGFloat = UIScreen.main.scale
    #endif
    
    /**
     A Boolean determining whether the resulting image includes the Mapbox logo.
     
     When shown, the Mapbox logo is located in the lower-left corner of the image. By default, this property is set to `true`.
     */
    open var showsLogo = true
    
    /**
     A Boolean determining whether the resulting image includes legally required copyright notices.
     
     When shown, the attribution is located in the bottom-right corner of the image. By default, this property is set to `true`.
     
     - note: The Mapbox terms of service, which governs the use of Mapbox-hosted vector tiles and styles, [requires](https://www.mapbox.com/help/attribution/) these copyright notices to accompany any map that features Mapbox-designed styles, OpenStreetMap data, or other Mapbox data such as satellite or terrain data. If these requirements applies to the shapshot and you set this property to `false`, you must provide [proper attribution](https://www.mapbox.com/help/attribution/#static--print) near the snapshot.
     */
    open var showsAttribution = true
    
    /**
     Initializes a snapshot options instance that results in a snapshot centered at the given geographical coordinate and showing the given zoom level.
     
     - parameter styleURL: The [style URL](https://www.mapbox.com/help/define-style-url/) of the style to snapshot. Only `mapbox:` URLs are supported. You can only snapshot a style hosted by Mapbox, such as a [Mapbox-designed style](https://www.mapbox.com/api-documentation/#styles).
     - parameter centerCoordinate: The geographic coordinate at the center of the snapshot.
     - parameter zoomLevel: The zoom level of the snapshot.
     - parameter size: The logical size of the image to output, measured in points.
     */
    public init(styleURL: URL, camera: SnapshotCamera, size: CGSize) {
        self.styleURL = styleURL
        self.camera = camera
        self.size = size
    }
    
    /**
     The path of the HTTP request URL corresponding to the options in this instance.
     
     - returns: An HTTP URL path.
     */
    open var path: String {
        assert(styleURL.scheme == "mapbox", "Only mapbox: URLs are supported. See https://www.mapbox.com/help/define-style-url/ or https://www.mapbox.com/api-documentation/#styles for valid style URLs.")
        assert(styleURL.host == "styles", "Invalid mapbox: URL. See https://www.mapbox.com/help/define-style-url/ or https://www.mapbox.com/api-documentation/#styles for valid style URLs.")
        let styleIdentifierComponent = "\(styleURL.path)/static"
        
        assert(-90...90 ~= camera.centerCoordinate.latitude, "Center latitude must be between −90° and 90°.")
        assert(-180...180 ~= camera.centerCoordinate.latitude, "Center longitude must be between −180° and 180°.")
        assert(0...20 ~= camera.zoomLevel, "Zoom level must be between 0 and 20.")
        if let pitch = camera.pitch {
            assert(0...60 ~= pitch, "Pitch must be between 0° and 60°.")
        }
        
        assert(1...1_280 ~= size.width, "Width must be between 1 and 1,280 points.")
        assert(1...1_280 ~= size.height, "Height must be between 1 and 1,280 points.")
        
        assert(overlays.count <= 100, "maximum number of overlays is 100")
        
        let overlaysComponent: String
        if overlays.isEmpty {
            overlaysComponent = ""
        } else {
            overlaysComponent = "/" + overlays.map { return "\($0)" }.joined(separator: ",")
        }
        
        return "/styles/v1/\(styleIdentifierComponent)\(overlaysComponent)/\(camera)/\(Int(round(size.width)))x\(Int(round(size.height)))\(scale > 1 ? "@2x" : "")"
    }
    
    /**
     The query component of the HTTP request URL corresponding to the options in this instance.
     
     - returns: The query URL component as an array of name/value pairs.
     */
    open var params: [URLQueryItem] {
        var params: [URLQueryItem] = []
        if let identifierOfLayerAboveOverlays = identifierOfLayerAboveOverlays {
            params.append(URLQueryItem(name: "before_layer", value: identifierOfLayerAboveOverlays))
        }
        if !showsLogo {
            params.append(URLQueryItem(name: "logo", value: String(showsLogo)))
        }
        if !showsAttribution {
            params.append(URLQueryItem(name: "attribution", value: String(showsAttribution)))
        }
        return params
    }
}
