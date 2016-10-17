#if os(OSX)
    import Cocoa
#else
    import UIKit
#endif

let allowedCharacterSet: CharacterSet = {
    // this causes a runtime exception with Xcode 8 beta 1
//    var allowedCharacters = CharacterSet.urlPathAllowed
//    allowedCharacters.remove(charactersIn: "/)")
//    return allowedCharacters
    
    return CharacterSet(charactersIn: "/)").inverted
}()

/**
 A feature that can be drawn atop the map.
 */
@objc(MBOverlay)
public protocol Overlay: NSObjectProtocol {}

/**
 A feature centered over a specific geographic coordinate.
 */
@objc(MBPoint)
public protocol Point: Overlay {
    /// The geographic coordinate to place the point at.
    var coordinate: CLLocationCoordinate2D { get }
}

/**
 A pin-shaped marker image.
 */
@objc(MBMarkerImage)
public class MarkerImage: NSObject {
    /**
     The size of a marker.
     */
    @objc(MBMarkerSize)
    public enum Size: Int, CustomStringConvertible {
        /// Small.
        case small
        /// Medium.
        case medium
        /// Large.
        case large
        
        public var description: String {
            switch self {
            case .small:
                return "s"
            case .medium:
                return "m"
            case .large:
                return "l"
            }
        }
    }
    
    /// Something simple that can be placed atop a marker.
    public enum Label: CustomStringConvertible {
        /// A lowercase English letter from A through Z. An uppercase letter is automatically converted to a lowercase letter.
        case letter(Character)
        /// A number from 0 through 99.
        case number(Int)
        /// The name of a [Maki](https://www.mapbox.com/maki-icons/) icon.
        case iconName(String)
        
        public var description: String {
            switch self {
            case .letter(let letter):
                let lower = "\(letter)".lowercased()
                assert(letter >= "a" && letter <= "z")
                return lower
            case .number(let number):
                assert(number >= 0 && number < 100)
                return "\(number)"
            case .iconName(let name):
                return "\(name)"
            }
        }
    }
    
    /**
     The size of the marker.
     
     By default, the marker is small.
     */
    public var size: Size
    
    /**
     A label or Maki icon to place atop the pin.
     
     By default, the marker has no label.
     */
    public var label: Label?
    
    #if os(OSX)
    /**
     The color of the pin part of the marker.
     
     By default, the marker is red.
     */
    public var color: NSColor = .red
    #else
    /**
     The color of the pin part of the marker.
     
     By default, the marker is red.
     */
    public var color: UIColor = .red
    #endif
    
    /**
     Initializes a red marker image with the given options.
     
     - parameter size: The size of the marker.
     - parameter label: A label or Maki icon to place atop the pin.
     */
    internal init(size: Size, label: Label?) {
        self.size = size
        self.label = label
    }
}

/**
 A pin-shaped marker placed at a specific point on the map.
 */
@objc(MBMarker)
public class Marker: MarkerImage, Point {
    /// The geographic coordinate to place the marker at.
    public var coordinate: CLLocationCoordinate2D
    
    /**
     Initializes a red marker with the given options.
     
     - parameter coordinate: The geographic coordinate to place the marker at.
     - parameter size: The size of the marker.
     - parameter label: A label or Maki icon to place atop the pin.
     */
    private init(coordinate: CLLocationCoordinate2D,
                 size: Size = .small,
                 label: Label?) {
        self.coordinate = coordinate
        super.init(size: size, label: label)
    }
    
    /**
     Initializes a red marker labeled with an English letter.
     
     - parameter coordinate: The geographic coordinate to place the marker at.
     - parameter size: The size of the marker.
     - parameter letter: An English letter from A through Z to place atop the pin.
     */
    public convenience init(coordinate: CLLocationCoordinate2D,
                            size: Size = .small,
                            letter: UniChar) {
        self.init(coordinate: coordinate, size: size, label: .letter(Character(UnicodeScalar(letter)!)))
    }
    
    /**
     Initializes a red marker labeled with a one- or two-digit number.
     
     - parameter coordinate: The geographic coordinate to place the marker at.
     - parameter size: The size of the marker.
     - parameter number: A number from 0 through 99 to place atop the pin.
     */
    public convenience init(coordinate: CLLocationCoordinate2D,
                            size: Size = .small,
                            number: Int) {
        self.init(coordinate: coordinate, size: size, label: .number(number))
    }
    
    /**
     Initializes a red marker with a [Maki](https://www.mapbox.com/maki-icons/) icon.
     
     The Maki icon set is [open source](https://github.com/mapbox/maki/) and [dedicated to the public domain](https://creativecommons.org/publicdomain/zero/1.0/).
     
     - parameter coordinate: The geographic coordinate to place the marker at.
     - parameter size: The size of the marker.
     - parameter iconName: The name of a [Maki](https://www.mapbox.com/maki-icons/) icon to place atop the pin.
     */
    public convenience init(coordinate: CLLocationCoordinate2D,
                            size: Size = .small,
                            iconName: String) {
        self.init(coordinate: coordinate, size: size, label: .iconName(iconName))
    }
    
    public override var description: String {
        let labelComponent: String
        if let label = label {
            labelComponent = "-\(label)"
        } else {
            labelComponent = ""
        }
        
        return "pin-\(size)\(labelComponent)+\(color.toHexString())(\(coordinate.longitude),\(coordinate.latitude))"
    }
}

/**
 A custom, online image placed at a specific point on the map.
 
 The marker image is always centered on the specified location. When creating an asymmetric marker like a pin, make sure that the tip of the pin is at the center of the image.
 */
@objc(MBCustomMarker)
public class CustomMarker: NSObject, Overlay {
    /// The geographic coordinate to place the marker at.
    public var coordinate: CLLocationCoordinate2D
    
    /**
     The HTTP or HTTPS URL of the image.
     
     The API caches custom marker images according to the `Expires` and `Cache-Control` headers. If you host the image on your own server, make sure that at least one of these headers is set to an proper value to prevent repeated requests for the image.
     */
    public var url: URL
    
    /**
     Initializes a marker with the given coordinate and image URL.
     
     - parameter coordinate: The geographic coordinate to place the marker at.
     - parameter URL: The HTTP or HTTPS URL of the image.
     */
    public init(coordinate: CLLocationCoordinate2D, url: URL) {
        self.coordinate = coordinate
        self.url = url
    }
    
    public override var description: String {
        let escapedURL = url.absoluteString.addingPercentEncoding(withAllowedCharacters: allowedCharacterSet)!
        return "url-\(escapedURL)(\(coordinate.longitude),\(coordinate.latitude))"
    }
}

/**
 A geographic object in [GeoJSON](https://www.mapbox.com/help/define-geojson/) format.
 
 GeoJSON features may be styled according to the [simplestyle specification](https://github.com/mapbox/simplestyle-spec).
 */
@objc(MBGeoJSON)
public class GeoJSON: NSObject, Overlay {
    /// String representation of the GeoJSON object to display.
    public var objectString: String
    
    var pm: String? {
        get {
            return self.pm
        }
        set(newValue) {
            self.pm = newValue
        }
    }
    
    public override var description: String {
        let escapedObjectString = objectString.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlPathAllowed)!
        return "geojson(\(escapedObjectString))"
    }
    
    /**
     Initializes a [GeoJSON](https://www.mapbox.com/help/define-geojson/) overlay with the given GeoJSON object.
     
     - parameter object: A valid GeoJSON object.
     - returns: A GeoJSON overlay, or `nil` if the given object is not a valid JSON object. This initializer does not check whether the object is valid GeoJSON, but invalid GeoJSON will cause the request to fail.
     */
    public init?(object: [String: AnyObject]) {
        // This should be a throwing initializer rather than a failiable initializer, but inheriting from Objective-C triggers a warning: no calls to throwing functions occur within 'try' expression
        guard let data = try? JSONSerialization.data(withJSONObject: object, options: []) else {
            return nil
        }
        objectString = String(data: data, encoding: String.Encoding.utf8)!
    }
    
    /**
     Initializes a [GeoJSON](https://www.mapbox.com/help/define-geojson/) overlay with the given string representation of a GeoJSON object.
     
     This initializer does not check whether the object is valid JSON or GeoJSON, but invalid JSON or GeoJSON will cause the request to fail. To perform basic JSON validation (but not GeoJSON validation), use the `init(object:)` initializer.
     
     - parameter objectString: The string representation of a valid GeoJSON object.
     */
    public init(objectString: String) {
        self.objectString = objectString
    }
}

/**
 A polyline or polygon placed along a path atop the map.
 */
@objc(MBPath)
public class Path: NSObject, Overlay {
    /**
     An array of geographic coordinates defining the path of the overlay.
     */
    public var coordinates: [CLLocationCoordinate2D]
    
    /**
     The stroke width of the overlay, measured in points.
     
     By default, the overlay is 1 point wide.
     */
    public var strokeWidth: Int = 1
    
    #if os(OSX)
    /**
     The stroke color of the overlay.
     
     By default, the overlay is stroked with Davy’s gray (33% white).
     */
    public var strokeColor = NSColor(hexString: "555")
    
    /**
     The fill color of the overlay.
     
     By default, the overlay is filled with Davy’s gray (33% white).
     */
    public var fillColor = NSColor(hexString: "555")
    #else
    /**
     The stroke color of the overlay.
     
     By default, the overlay is stroked with Davy’s gray (33% white).
     */
    public var strokeColor = UIColor(hexString: "555")
    
    /**
     The fill color of the overlay.
     
     By default, the overlay is filled with Davy’s gray (33% white).
     */
    public var fillColor = UIColor(hexString: "555")
    #endif
    
    /**
     The stroke opacity of the overlay, expressed as a percentage such that 0.0 is completely transparent and 1.0 is completely opaque.
     
     By default, the overlay’s stroke is completely opaque.
     */
    public var strokeOpacity: Double = 1
    
    /**
     The fill opacity of the overlay, expressed as a percentage such that 0.0 is completely transparent and 1.0 is completely opaque.
     
     By default, the overlay’s fill is completely transparent.
     */
    public var fillOpacity: Double = 0
    
    /**
     Initializes a polyline overlay with the given vertices.
     
     The polyline is 1 point wide and stroked with Davy’s gray (33% white).
     
     To turn the overlay into a polygon, close the path by ensuring that the first and last coordinates are the same. To fill the polygon, set the `fillOpacity` property to a value greater than 0.0.
     
     - parameter coordinates: An array of geographic coordinates defining the path of the overlay.
     */
    public init(coordinates: [CLLocationCoordinate2D]) {
        self.coordinates = coordinates
    }
    
    /**
     Initializes a polyline overlay with the given vertices, stored in a C array.
     
     The polyline is 1 point wide and stroked with Davy’s gray (33% white).
     
     To turn the overlay into a polygon, close the path by ensuring that the first and last coordinates are the same. To fill the polygon, set the `fillOpacity` property to a value greater than 0.0.
     
     - parameter coordinates: An array of geographic coordinates defining the path of the overlay.
     
     - note: This initializer is intended for Objective-C usage. In Swift code, use the `init(coordinates:)` initializer.
     */
    public init(coordinates: UnsafePointer<CLLocationCoordinate2D>, count: UInt) {
        var convertedCoordinates: [CLLocationCoordinate2D] = []
        for i in 0..<count {
            convertedCoordinates.append(coordinates.advanced(by: Int(i)).pointee)            
        }
        self.coordinates = convertedCoordinates
    }
    
    /**
     The number of vertices.
     
     - note: This initializer is intended for Objective-C usage. In Swift code, use the `coordinates.count` property.
     */
    public var coordinateCount: UInt {
        return UInt(coordinates.count)
    }
    
    /**
     Retrieves the vertices.
     
     - parameter coordinates: A pointer to a C array of `CLLocationCoordinate2D` instances. On output, this array contains all the vertices of the overlay.
     
     - precondition: `coordinates` must be large enough to hold `coordinateCount` instances of `CLLocationCoordinate2D`.
     
     - note: This initializer is intended for Objective-C usage. In Swift code, use the `coordinates` property.
     */
    public func getCoordinates(_ coordinates: UnsafeMutablePointer<CLLocationCoordinate2D>) {
        for i in 0..<self.coordinates.count {
            coordinates.advanced(by: i).pointee = self.coordinates[i]
        }
    }
    
    // based on https://github.com/mapbox/polyline
    private func polylineEncode(_ coordinates: [CLLocationCoordinate2D]) -> String {

        func encodeCoordinate(_ coordinate: CLLocationDegrees) -> String {

            var c = Int(round(coordinate * 1e5))

            c = c << 1

            if c < 0 {
                c = ~c
            }

            var output = ""

            while c >= 0x20 {
                output += String(describing: UnicodeScalar((0x20 | (c & 0x1f)) + 63))
                c = c >> 5
            }

            output += String(describing: UnicodeScalar(c + 63))

            return output
        }

        var output = encodeCoordinate(coordinates[0].latitude) + encodeCoordinate(coordinates[0].longitude)

        for i in 1 ..< coordinates.count {
            let a = coordinates[i]
            let b = coordinates[i - 1]
            output += encodeCoordinate(a.latitude - b.latitude)
            output += encodeCoordinate(a.longitude - b.longitude)
        }

        return output
    }
    
    public override var description: String {
        let encodedPolyline = polylineEncode(coordinates).addingPercentEncoding(withAllowedCharacters: CharacterSet.urlPathAllowed)!
        return "path-\(strokeWidth)+\(strokeColor.toHexString())-\(strokeOpacity)+\(fillColor.toHexString())-\(fillOpacity)(\(encodedPolyline))"
    }
}
