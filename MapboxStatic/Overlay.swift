import CoreLocation
#if os(OSX)
    import Cocoa
#else
    import UIKit
#endif

let allowedCharacterSet: NSCharacterSet = {
    let characterSet = NSCharacterSet.URLQueryAllowedCharacterSet().mutableCopy() as! NSMutableCharacterSet
    characterSet.removeCharactersInString("/")
    return characterSet
}()

/**
 A feature that can be drawn atop the map.
 */
public protocol Overlay: CustomStringConvertible {
    var description: String { get }
}

/**
 A feature centered over a specific geographic coordinate.
 */
public protocol Point: Overlay {
    /// The geographic coordinate to place the point at.
    var coordinate: CLLocationCoordinate2D { get }
}

/**
 A pin-shaped marker placed at a specific point on the map.
 
 The Maki icon set is [open source](https://github.com/mapbox/maki/) and [dedicated to the public domain](https://creativecommons.org/publicdomain/zero/1.0/).
 */
public struct Marker: Point {
    #if os(OSX)
    public typealias Color = NSColor
    #else
    public typealias Color = UIColor
    #endif
    
    /**
     The size of a marker.
     */
    public enum Size: String {
        /// Small.
        case Small  = "s"
        /// Medium.
        case Medium = "m"
        /// Large.
        case Large  = "l"
    }
    
    /// Something simple that can be placed atop a marker.
    public enum Label: CustomStringConvertible {
        /// A lowercase English letter from A through Z. An uppercase letter is automatically converted to a lowercase letter.
        case Letter(Character)
        /// A number from 0 through 99.
        case Number(Int)
        /// The name of a [Maki](https://www.mapbox.com/maki-icons/) icon.
        case IconName(String)
        
        public var description: String {
            switch self {
            case .Letter(let letter):
                let lower = "\(letter)".lowercaseString
                assert(letter >= "a" && letter <= "z")
                return lower
            case .Number(let number):
                assert(number >= 0 && number < 100)
                return "\(number)"
            case .IconName(let name):
                return "\(name)"
            }
        }
    }
    
    /// The geographic coordinate to place the marker at.
    public let coordinate: CLLocationCoordinate2D
    
    /**
     The size of the marker.
     
     By default, the marker is small.
     */
    public let size: Size
    
    /**
     A label or Maki icon to place atop the pin.
     
     By default, the marker has no label.
     */
    public let label: Label?
    
    /**
     The color of the pin part of the marker.
     
     By default, the marker is red.
     */
    public let color: Color
    
    /**
     Initializes a marker with the given options.
     
     - parameter coordinate: The geographic coordinate to place the marker at.
     - parameter size: The size of the marker.
     - parameter label: A label or Maki icon to place atop the pin.
     */
    public init(coordinate: CLLocationCoordinate2D,
                size: Size = .Small,
                label: Label? = nil,
                color: Color = .redColor()) {
        self.coordinate = coordinate
        self.size = size
        self.label = label
        self.color = color
    }
    
    public var description: String {
        let labelComponent: String
        if let label = label {
            labelComponent = "-\(label)"
        } else {
            labelComponent = ""
        }
        return "pin-\(size.rawValue)\(labelComponent)+\(color.toHexString())(\(coordinate.longitude),\(coordinate.latitude))"
    }
}

/**
 A custom, online image placed at a specific point on the map.
 
 The marker image is always centered on the specified location. When creating an asymmetric marker like a pin, make sure that the tip of the pin is at the center of the image.
 */
public struct CustomMarker: Overlay {
    /// The geographic coordinate to place the marker at.
    public let coordinate: CLLocationCoordinate2D
    
    /**
     The HTTP or HTTPS URL of the image.
     
     The API caches custom marker images according to the `Expires` and `Cache-Control` headers. If you host the image on your own server, make sure that at least one of these headers is set to an proper value to prevent repeated requests for the image.
     */
    public let URL: NSURL
    
    /**
     Initializes a marker with the given coordinate and image URL.
     
     - parameter coordinate: The geographic coordinate to place the marker at.
     - parameter URL: The HTTP or HTTPS URL of the image.
     */
    public init(coordinate: CLLocationCoordinate2D, URL: NSURL) {
        self.coordinate = coordinate
        self.URL = URL
    }
    
    public var description: String {
        let escapedURL = URL.absoluteString.stringByAddingPercentEncodingWithAllowedCharacters(allowedCharacterSet)!
        return "url-\(escapedURL)(\(coordinate.longitude),\(coordinate.latitude))"
    }
}

/**
 A geographic object in [GeoJSON](https://www.mapbox.com/help/define-geojson/) format.
 
 GeoJSON features may be styled according to the [simplestyle specification](https://github.com/mapbox/simplestyle-spec).
 */
public struct GeoJSON: Overlay {
    /// String representation of the GeoJSON object to display.
    public let objectString: String
    
    public var description: String {
        let escapedObjectString = objectString.stringByAddingPercentEncodingWithAllowedCharacters(allowedCharacterSet)!
        return "geojson(\(escapedObjectString))"
    }
    
    /**
     Initializes a [GeoJSON](https://www.mapbox.com/help/define-geojson/) overlay with the given GeoJSON object.
     
     - parameter object: A valid GeoJSON object.
     - throws: If the given object is not a valid JSON object. This initializer does not check whether the object is valid GeoJSON, but invalid GeoJSON will cause the request to fail.
     */
    public init(object: [String: AnyObject]) throws {
        let data = try NSJSONSerialization.dataWithJSONObject(object, options: [])
        objectString = String(data: data, encoding: NSUTF8StringEncoding)!
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
public struct Path: Overlay {
    #if os(OSX)
    public typealias Color = NSColor
    #else
    public typealias Color = UIColor
    #endif
    
    /**
     An array of geographic coordinates defining the path of the overlay.
     */
    public let coordinates: [CLLocationCoordinate2D]
    
    /**
     The stroke width of the overlay, measured in points.
     
     By default, the overlay is 1 point wide.
     */
    public let strokeWidth: Int
    
    /**
     The stroke color of the overlay.
     
     By default, the overlay is stroked with Davy’s gray (33% white).
     */
    public let strokeColor: Color
    
    /**
     The stroke opacity of the overlay, expressed as a percentage such that 0.0 is completely transparent and 1.0 is completely opaque.
     
     By default, the overlay’s stroke is completely opaque.
     */
    public let strokeOpacity: Double
    
    /**
     The fill color of the overlay.
     
     By default, the overlay is filled with Davy’s gray (33% white).
     */
    public let fillColor: Color
    
    /**
     The fill opacity of the overlay, expressed as a percentage such that 0.0 is completely transparent and 1.0 is completely opaque.
     
     By default, the overlay’s fill is completely transparent.
     */
    public let fillOpacity: Double
    
    /**
     Initializes a polyline or polygon overlay with the given options.
     
     - parameter coordinates: An array of geographic coordinates defining the path of the overlay.
     - parameter strokeWidth: The stroke width of the overlay, measured in points.
     - parameter strokeColor: The stroke color of the overlay.
     - parameter strokeOpacity: The stroke opacity of the overlay, expressed as a percentage such that 0.0 is completely transparent and 1.0 is completely opaque.
     - parameter fillColor: The fill color of the overlay.
     - parameter fillOpacity: The fill opacity of the overlay, expressed as a percentage such that 0.0 is completely transparent and 1.0 is completely opaque.
     */
    public init(coordinates: [CLLocationCoordinate2D],
                strokeWidth: Int = 1,
                strokeColor: Color = Color(hexString: "555"),
                strokeOpacity: Double = 1.0,
                fillColor: Color = Color(hexString: "555"),
                fillOpacity: Double = 0) {
        self.coordinates = coordinates
        self.strokeWidth = strokeWidth
        self.strokeColor = strokeColor
        self.strokeOpacity = strokeOpacity
        self.fillColor = fillColor
        self.fillOpacity = fillOpacity
    }
    
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

        return output.stringByAddingPercentEncodingWithAllowedCharacters(allowedCharacterSet)!
    }
    
    public var description: String {
        let encodedPolyline = polylineEncode(coordinates)
        return "path-\(strokeWidth)+\(strokeColor.toHexString())-\(strokeOpacity)+\(fillColor.toHexString())-\(fillOpacity)(\(encodedPolyline))"
    }
}
