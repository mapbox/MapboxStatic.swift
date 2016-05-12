import CoreLocation
import UIKit

public enum MarkerSize: String {
    case Small  = "s"
    case Medium = "m"
    case Large  = "l"
}

public class Overlay {

    internal var requestString: String = ""

}

public class Marker: Overlay {

    public init(coordinate: CLLocationCoordinate2D,
         size: MarkerSize = .Small,
         label: String = "",
         color: UIColor = UIColor.redColor()) {

        super.init()

        requestString = "pin-"
        requestString += size.rawValue

        if label.lengthOfBytesUsingEncoding(NSUTF8StringEncoding) > 0 {
            requestString += "-" + label
        }

        requestString += "+" + color.toHexString()
        requestString += "(\(coordinate.longitude),\(coordinate.latitude))"

    }

}

public class CustomMarker: Overlay {

    public init(coordinate: CLLocationCoordinate2D,
         URLString: String) {

        super.init()

        requestString = "url-"
        requestString += URLString.stringByAddingPercentEncodingWithAllowedCharacters(StaticMap.allowedCharacterSet())!
        requestString += "(\(coordinate.longitude),\(coordinate.latitude))"
    }

}

public class GeoJSON: Overlay {

    public init(string: String) {

        super.init()

        requestString = "geojson("
        requestString += string.stringByAddingPercentEncodingWithAllowedCharacters(StaticMap.allowedCharacterSet())!
        requestString += ")"

    }

}

public class Path: Overlay {

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

        return output.stringByAddingPercentEncodingWithAllowedCharacters(StaticMap.allowedCharacterSet())!
    }

    public init(pathCoordinates: [CLLocationCoordinate2D],
         strokeWidth: Int = 1,
         strokeColor: UIColor = UIColor.colorWithHexString("555"),
         strokeOpacity: Double = 1.0,
         fillColor: UIColor = UIColor.colorWithHexString("555"),
         fillOpacity: Double = 0) {

        super.init()

        requestString = "path"
        requestString += "-\(strokeWidth)"
        requestString += "+" +  strokeColor.toHexString()
        requestString += "-\(strokeOpacity)"
        requestString += "+" + fillColor.toHexString()
        requestString += "-\(fillOpacity)"
        requestString += "("
        requestString += polylineEncode(pathCoordinates)
        requestString += ")"

    }

}
