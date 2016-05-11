import XCTest
import OHHTTPStubs
import CoreLocation
import Foundation
import MapboxStatic

class MapboxGeocoderTests: XCTestCase {

    let mapID = "justin.o0mbikn2"
    let accessToken = "pk.eyJ1IjoianVzdGluIiwiYSI6IlpDbUJLSUEifQ.4mG8vhelFMju6HpIY-Hi5A"
    let serviceHost = "api.mapbox.com"

    override func setUp() {
        super.setUp()
        OHHTTPStubs.removeAllStubs()
    }

    private func parseQueryString(request: NSURLRequest) -> Dictionary<String, String> {
        var result = Dictionary<String, String>()
        let pairs = request.URL!.query!.componentsSeparatedByString("&")
        for pair in pairs {
            let parts = pair.componentsSeparatedByString("=")
            result[parts[0]] = parts[1]
        }
        return result
    }

    func testBasicMap() {
        // passed args
        let mapIDExp = expectationWithDescription("mapID should be passed")
        let sizeExp = expectationWithDescription("size should be passed")
        let accessTokenExp = expectationWithDescription("access token should be passed")

        // implicit args
        let versionExp = expectationWithDescription("API version should be v4")
        let centerExp = expectationWithDescription("center should default to Null Island")
        let zoomExp = expectationWithDescription("zoom should default to z0")
        let formatExp = expectationWithDescription("format should default to PNG")
        let retinaExp = expectationWithDescription("retina should default to disabled")
        let overlaysExp = expectationWithDescription("overlays should default to empty")
        let autoFitExp = expectationWithDescription("auto-fit should default to disabled")

        let map = MapboxStaticMap(mapID: mapID,
            size: CGSize(width: 200, height: 200),
            accessToken: accessToken)

        stub(isHost(serviceHost)) { [unowned self] request in
            if let p = request.URL?.pathComponents {
                if p[1] == "v4" {
                    versionExp.fulfill()
                }
                if p[2] == self.mapID {
                    mapIDExp.fulfill()
                }
                if p[3].componentsSeparatedByString(",")[0] == "0.0" &&
                   p[3].componentsSeparatedByString(",")[1] == "0.0" {
                    centerExp.fulfill()
                }
                if p[3].componentsSeparatedByString(",")[2] == "0" {
                    zoomExp.fulfill()
                }
                if p[4].componentsSeparatedByString(".").first == "200x200" {
                    sizeExp.fulfill()
                }
                if p[4].componentsSeparatedByString(".").last == "png" {
                    formatExp.fulfill()
                }
            }

            let query = self.parseQueryString(request)
            if query["access_token"] == self.accessToken {
                accessTokenExp.fulfill()
            }
            if query.keys.contains("access_token") && query.count == 1 {
                retinaExp.fulfill()
                overlaysExp.fulfill()
                autoFitExp.fulfill()
            }

            return OHHTTPStubsResponse()
        }

        map.image

        waitForExpectationsWithTimeout(1, handler: nil)
    }

    func testCenter() {
        let lat = 5.971389
        let lon = 116.095278

        let centerExp = expectationWithDescription("center should get passed intact")

        let map = MapboxStaticMap(mapID: mapID,
            center: CLLocationCoordinate2D(latitude: lat, longitude: lon),
            size: CGSize(width: 400, height: 400),
            accessToken: accessToken)

        stub(isHost(serviceHost)) { request in
            if let p = request.URL?.pathComponents {
                let n = p[3].componentsSeparatedByString(",")
                if n[0] == String(lon) && n[1] == String(lat) {
                    centerExp.fulfill()
                }
            }

            return OHHTTPStubsResponse()
        }

        map.image

        waitForExpectationsWithTimeout(1, handler: nil)
    }

    func testZoom() {
        let zoom = 6

        let zoomExp = expectationWithDescription("zoom should get passed intact")

        let map = MapboxStaticMap(mapID: mapID,
            zoom: zoom,
            size: CGSize(width: 300, height: 300),
            accessToken: accessToken)

        stub(isHost(serviceHost)) { request in
            if let p = request.URL?.pathComponents {
                let n = p[3].componentsSeparatedByString(",")
                if n[2] == String(zoom) {
                    zoomExp.fulfill()
                }
            }

            return OHHTTPStubsResponse()
        }

        map.image

        waitForExpectationsWithTimeout(1, handler: nil)
    }

    func testSize() {
        let min: UInt32 = 1
        let max: UInt32 = 1280

        let width  = arc4random_uniform(max - min) + min
        let height = arc4random_uniform(max - min) + min

        let sizeExp = expectationWithDescription("size should pass intact for non-retina")

        let map = MapboxStaticMap(mapID: mapID,
            size: CGSize(width: CGFloat(width), height: CGFloat(height)),
            accessToken: accessToken)

        stub(isHost(serviceHost)) { request in
            if let p = request.URL?.pathComponents,
              let f = p.last,
              let s = f.componentsSeparatedByString(".").first?.componentsSeparatedByString("x")
              where s[0] == String(width) && s[1] == String(height) {
                    sizeExp.fulfill()
            }

            return OHHTTPStubsResponse()
        }

        map.image

        waitForExpectationsWithTimeout(1, handler: nil)
    }

    func testFormats() {
        var expectations = [XCTestExpectation]()
        var maps = [MapboxStaticMap]()

        for format in MapboxStaticMap.ImageFormat.allValues {
            let exp = expectationWithDescription("\(format.rawValue) extension should be requested")
            expectations.append(exp)

            stub(isExtension(format.rawValue)) { request in
                exp.fulfill()
                return OHHTTPStubsResponse()
            }

            maps.append(MapboxStaticMap(mapID: mapID,
                size: CGSize(width: 200, height: 200),
                accessToken: accessToken,
                format: format))
        }

        for map in maps {
            map.image
        }

        waitForExpectationsWithTimeout(1, handler: nil)
    }

    func testRetina() {
        let retinaExp = expectationWithDescription("retina should request @2x asset")

        let map = MapboxStaticMap(mapID: mapID,
            size: CGSize(width: 200, height: 200),
            accessToken: accessToken,
            retina: true)

        stub(isHost(serviceHost)) { request in
            if let p = request.URL?.pathComponents,
              let f = p.last,
              let e = f.componentsSeparatedByString("@").last,
              let s = e.componentsSeparatedByString(".").first
              where s == "2x" {
                retinaExp.fulfill()
            }

            return OHHTTPStubsResponse()
        }

        map.image

        waitForExpectationsWithTimeout(1, handler: nil)
    }

    func testOverlayBuiltinMarker() {
        let lat = 45.52
        let lon = -122.681944
        let size = MapboxStaticMap.MarkerSize.Medium
        let label = "cafe"
        let color = UIColor.brownColor()
        let colorRaw = "996633"

        let markerExp = expectationWithDescription("builtin marker argument should format Maki request properly")

        let markerOverlay = MapboxStaticMap.Marker(
            coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon),
            size: size,
            label: label,
            color: color)

        let map = MapboxStaticMap(mapID: mapID,
            size: CGSize(width: 200, height: 200),
            accessToken: accessToken,
            overlays: [markerOverlay])

        stub(isHost(serviceHost)) { request in
            if let p = request.URL?.pathComponents
              where p[3] == "pin-" + size.rawValue + "-" + label +
                            "+" + colorRaw + "(\(lon),\(lat))" {
                markerExp.fulfill()
            }

            return OHHTTPStubsResponse()
        }

        map.image

        waitForExpectationsWithTimeout(1, handler: nil)
    }

    func testOverlayCustomMarker() {
        let lat = 45.522
        let lon = -122.69
        let markerURL = NSURL(string: "https://mapbox.com/guides/img/rocket.png")!
        let encodedMarker = "https:%2F%2Fmapbox.com%2Fguides%2Fimg%2Frocket.png"

        let markerExp = expectationWithDescription("custom marker argument should properly encode request")

        let customMarker = MapboxStaticMap.CustomMarker(
            coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon),
            URLString: markerURL.absoluteString)

        let map = MapboxStaticMap(mapID: mapID,
            size: CGSize(width: 200, height: 200),
            accessToken: accessToken,
            overlays: [customMarker])

        stub(isHost(serviceHost)) { request in
            // We need to examine the URL string here manually since NSURL.pathComponents()
            // decodes the percent escaping, which does us no good.
            if let requestString = request.URL?.absoluteString {
                let m = requestString.componentsSeparatedByString("/")
                if m[5] == "url-\(encodedMarker)(\(lon),\(lat))" {
                    markerExp.fulfill()
                }
            }

            return OHHTTPStubsResponse()
        }

        map.image

        waitForExpectationsWithTimeout(1, handler: nil)
    }

    func testOverlayGeoJSON() {
        let geojsonURL = NSURL(string: "http://git.io/vCv9U")!
        let encodedGeoJSON = "geojson(%7B%0A%20%20%22type%22:%20%22FeatureCollection%22,%0A%20%20%22features%22:%20%5B%0A%20%20%20%20%7B%0A%20%20%20%20%20%20%22type%22:%20%22Feature%22,%0A%20%20%20%20%20%20%22properties%22:%20%7B%0A%20%20%20%20%20%20%20%20%22stroke%22:%20%22%2300f%22,%0A%20%20%20%20%20%20%20%20%22stroke-width%22:%203,%0A%20%20%20%20%20%20%20%20%22stroke-opacity%22:%201%0A%20%20%20%20%20%20%7D,%0A%20%20%20%20%20%20%22geometry%22:%20%7B%0A%20%20%20%20%20%20%20%20%22type%22:%20%22LineString%22,%0A%20%20%20%20%20%20%20%20%22coordinates%22:%20%5B%0A%20%20%20%20%20%20%20%20%20%20%5B%0A%20%20%20%20%20%20%20%20%20%20%20%20-122.69784450531006,%0A%20%20%20%20%20%20%20%20%20%20%20%2045.51863175803531%0A%20%20%20%20%20%20%20%20%20%20%5D,%0A%20%20%20%20%20%20%20%20%20%20%5B%0A%20%20%20%20%20%20%20%20%20%20%20%20-122.69091367721559,%0A%20%20%20%20%20%20%20%20%20%20%20%2045.52165369248977%0A%20%20%20%20%20%20%20%20%20%20%5D,%0A%20%20%20%20%20%20%20%20%20%20%5B%0A%20%20%20%20%20%20%20%20%20%20%20%20-122.68630027770996,%0A%20%20%20%20%20%20%20%20%20%20%20%2045.518917420477024%0A%20%20%20%20%20%20%20%20%20%20%5D,%0A%20%20%20%20%20%20%20%20%20%20%5B%0A%20%20%20%20%20%20%20%20%20%20%20%20-122.68509864807127,%0A%20%20%20%20%20%20%20%20%20%20%20%2045.51631633525551%0A%20%20%20%20%20%20%20%20%20%20%5D,%0A%20%20%20%20%20%20%20%20%20%20%5B%0A%20%20%20%20%20%20%20%20%20%20%20%20-122.68233060836793,%0A%20%20%20%20%20%20%20%20%20%20%20%2045.51950377568216%0A%20%20%20%20%20%20%20%20%20%20%5D%0A%20%20%20%20%20%20%20%20%5D%0A%20%20%20%20%20%20%7D%0A%20%20%20%20%7D%0A%20%20%5D%0A%7D)"

        let geojsonExp = expectationWithDescription("GeoJSON argument should properly encode request")

        stub(isHost(geojsonURL.host!)) { request in
            return fixture(NSBundle(forClass: self.dynamicType).pathForResource("polyline", ofType: "geojson")!,
                headers: nil)
        }

        let geojsonString = try! NSString(contentsOfURL: geojsonURL, encoding: NSUTF8StringEncoding)
        let geojsonOverlay = MapboxStaticMap.GeoJSON(string: geojsonString as String)

        let map = MapboxStaticMap(mapID: mapID,
            size: CGSize(width: 200, height: 200),
            accessToken: accessToken,
            overlays: [geojsonOverlay])

        stub(isHost(serviceHost)) { request in
            // We need to examine the URL string here manually since NSURL.pathComponents()
            // decodes the percent escaping, which does us no good.
            if let requestString = request.URL?.absoluteString {
                let m = requestString.componentsSeparatedByString("/")
                if m[5] == encodedGeoJSON {
                    geojsonExp.fulfill()
                }
            }

            return OHHTTPStubsResponse()
        }

        map.image

        waitForExpectationsWithTimeout(1, handler: nil)
    }

    func testOverlayPath() {
        let strokeWidth = 2
        let strokeColor = UIColor.blackColor()
        let strokeColorRaw = "000000"
        let strokeOpacity = 0.75
        let fillColor = UIColor.redColor()
        let fillColorRaw = "ff0000"
        let fillOpacity = 0.25
        let encodedPolyline = "(upztG%60jxkVn@al@bo@nFWzuAaTcAyZen@)"

        let path = MapboxStaticMap.Path(
            pathCoordinates: [
                CLLocationCoordinate2D(
                    latitude: 45.52475063103141, longitude: -122.68209457397461
                ),
                CLLocationCoordinate2D(
                    latitude: 45.52451009822193, longitude: -122.67488479614258
                ),
                CLLocationCoordinate2D(
                    latitude: 45.51681250530043, longitude: -122.67608642578126
                ),
                CLLocationCoordinate2D(
                    latitude: 45.51693278828882, longitude: -122.68999099731445
                ),
                CLLocationCoordinate2D(
                    latitude: 45.520300607576864, longitude: -122.68964767456055
                ),
                CLLocationCoordinate2D(
                    latitude: 45.52475063103141, longitude: -122.68209457397461
                )
            ],
            strokeWidth: strokeWidth,
            strokeColor: strokeColor,
            strokeOpacity: strokeOpacity,
            fillColor: fillColor,
            fillOpacity: fillOpacity)

        let pathExp = expectationWithDescription("raw path argument should properly encode request")

        let map = MapboxStaticMap(mapID: mapID,
            size: CGSize(width: 200, height: 200),
            accessToken: accessToken,
            overlays: [path])

        stub(isHost(serviceHost)) { request in
            // We need to examine the URL string here manually since NSURL.pathComponents()
            // decodes the percent escaping, which does us no good.
            if let requestString = request.URL?.absoluteString {
                let p = requestString.componentsSeparatedByString("/")
                if p[5] == "path-\(strokeWidth)+\(strokeColorRaw)-\(strokeOpacity)+" +
                           "\(fillColorRaw)-\(fillOpacity)" + encodedPolyline {
                    pathExp.fulfill()
                }
            }

            return OHHTTPStubsResponse()
        }
        
        map.image
        
        waitForExpectationsWithTimeout(1, handler: nil)
    }

    func testAutoFit() {
        let autoFitExp = expectationWithDescription("auto-fit should pass correct argument")

        let markerOverlay = MapboxStaticMap.Marker(
            coordinate: CLLocationCoordinate2D(latitude: 45.52, longitude: -122.681944),
            size: .Medium,
            label: "cafe",
            color: UIColor.brownColor())

        let map = MapboxStaticMap(mapID: mapID,
            size: CGSize(width: 200, height: 200),
            accessToken: accessToken,
            overlays: [markerOverlay],
            autoFitFeatures: true)

        stub(isHost(serviceHost)) { request in
            if let p = request.URL?.pathComponents
              where p[4] == "auto" {
                autoFitExp.fulfill()
            }

            return OHHTTPStubsResponse()
        }

        map.image

        waitForExpectationsWithTimeout(1, handler: nil)
    }

}
