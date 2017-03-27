#if os(OSX)
    import Cocoa
#elseif os(watchOS)
    import WatchKit
#else
    import UIKit
#endif

/**
 A structure that configures a standalone marker image and how it is formatted. A standalone marker image is produced by the [classic Mapbox Static API](https://www.mapbox.com/api-documentation/?language=Swift#static-classic).
 */
@objc(MBMarkerOptions)
open class MarkerOptions: MarkerImage, SnapshotOptionsProtocol {
    #if os(OSX)
    /**
     The scale factor of the image.
     
     If you multiply the logical size of the image (stored in the `size` property) by the value in this property, you get the dimensions of the image in pixels.
     
     The default value of this property matches the natural scale factor associated with the main screen. However, only images with a scale factor of 1.0 or 2.0 are ever returned by the classic Static API, so a scale factor of 1.0 of less results in a 1× (standard-resolution) image, while a scale factor greater than 1.0 results in a 2× (high-resolution or Retina) image.
     */
    open var scale: CGFloat = NSScreen.main()?.backingScaleFactor ?? 1
    #elseif os(watchOS)
    /**
     The scale factor of the image.
     
     If you multiply the logical size of the image (stored in the `size` property) by the value in this property, you get the dimensions of the image in pixels.
     
     The default value of this property matches the natural scale factor associated with the screen. Images with a scale factor of 1.0 or 2.0 are ever returned by the classic Static API, so a scale factor of 1.0 of less results in a 1× (standard-resolution) image, while a scale factor greater than 1.0 results in a 2× (high-resolution or Retina) image.
     */
    open var scale: CGFloat = WKInterfaceDevice.current().screenScale
    #else
    /**
     The scale factor of the image.
     
     If you multiply the logical size of the image (stored in the `size` property) by the value in this property, you get the dimensions of the image in pixels.
     
     The default value of this property matches the natural scale factor associated with the main screen. However, only images with a scale factor of 1.0 or 2.0 are ever returned by the classic Static API, so a scale factor of 1.0 of less results in a 1× (standard-resolution) image, while a scale factor greater than 1.0 results in a 2× (high-resolution or Retina) image.
     */
    open var scale: CGFloat = UIScreen.main.scale
    #endif
    
    /**
     Initializes a marker options instance.
     
     - parameter size: The size of the marker.
     - parameter label: A label or Maki icon to place atop the pin.
     */
    fileprivate override init(size: Size, label: Label?) {
        super.init(size: size, label: label)
    }
    
    /**
     Initializes a marker options instance that results in a red marker labeled with an English letter.
     
     - parameter size: The size of the marker.
     - parameter letter: An English letter from A through Z to place atop the pin.
     */
    public convenience init(size: Size = .small, letter: UniChar) {
        self.init(size: size, label: .letter(Character(UnicodeScalar(letter)!)))
    }
    
    /**
     Initializes a marker options instance that results in a red marker labeled with a one- or two-digit number.
     
     - parameter size: The size of the marker.
     - parameter number: A number from 0 through 99 to place atop the pin.
     */
    public convenience init(size: Size = .small, number: Int) {
        self.init(size: size, label: .number(number))
    }
    
    /**
     Initializes a marker options instance that results in a red marker with a Maki icon.
     
     - parameter size: The size of the marker.
     - parameter iconName: The name of a [Maki](https://www.mapbox.com/maki-icons/) v0.5.0 icon to place atop the pin.
     */
    public convenience init(size: Size = .small, iconName: String) {
        self.init(size: size, label: .iconName(iconName))
    }
    
    /**
     The path of the HTTP request URL corresponding to the options in this instance.
     
     - returns: An HTTP URL path.
     */
    open var path: String {
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
    open var params: [URLQueryItem] {
        return []
    }
}
