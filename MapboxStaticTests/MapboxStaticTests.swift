import XCTest
import OHHTTPStubs
import CoreLocation
import Foundation
import MapboxStatic

#if os(iOS)
    typealias Color = UIColor
#elseif os(OSX)
    typealias Color = NSColor
#endif

class MapboxStaticTests: XCTestCase {
    let mapIdentifiers = ["justin.o0mbikn2"]
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
        let formatExp = expectationWithDescription("format should default to PNG")
        let retinaExp = expectationWithDescription("retina should default to disabled")
        let overlaysExp = expectationWithDescription("overlays should default to empty")
        let autoFitExp = expectationWithDescription("auto-fit should default to enabled")

        let options = SnapshotOptions(mapIdentifiers: mapIdentifiers, size: CGSize(width: 200, height: 200))
        
        let scale: CGFloat
        #if os(iOS)
            scale = UIScreen.mainScreen().scale
        #elseif os(OSX)
            scale = NSScreen.mainScreen()?.backingScaleFactor ?? 1
        #endif

        stub(isHost(serviceHost)) { [unowned self] request in
            if let p = request.URL?.pathComponents {
                if p[1] == "v4" {
                    versionExp.fulfill()
                }
                if p[2] == self.mapIdentifiers.joinWithSeparator(",") {
                    mapIDExp.fulfill()
                }
                if p[3] == "auto" {
                    overlaysExp.fulfill()
                    autoFitExp.fulfill()
                }
                if p[4].componentsSeparatedByString(".").first == "200x200" && scale == 1 {
                    retinaExp.fulfill()
                    sizeExp.fulfill()
                }
                else if p[4].componentsSeparatedByString(".").first == "200x200@2x" && scale > 1 {
                    retinaExp.fulfill()
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
            }

            return OHHTTPStubsResponse()
        }

        Snapshot(options: options, accessToken: accessToken).image

        waitForExpectationsWithTimeout(1, handler: nil)
    }

    func testCenter() {
        let center = CLLocationCoordinate2D(latitude: 5.971389, longitude: 116.095278)

        let centerExp = expectationWithDescription("center should get passed intact")

        let options = SnapshotOptions(
            mapIdentifiers: mapIdentifiers,
            centerCoordinate: center,
            zoomLevel: 0,
            size: CGSize(width: 200, height: 200))

        stub(isHost(serviceHost)) { request in
            if let p = request.URL?.pathComponents {
                let n = p[3].componentsSeparatedByString(",")
                if n[0] == String(center.longitude) && n[1] == String(center.latitude) {
                    centerExp.fulfill()
                }
            }

            return OHHTTPStubsResponse()
        }

        Snapshot(options: options, accessToken: accessToken).image

        waitForExpectationsWithTimeout(1, handler: nil)
    }

    func testZoom() {
        let zoom = 6

        let zoomExp = expectationWithDescription("zoom should get passed intact")

        let options = SnapshotOptions(
            mapIdentifiers: mapIdentifiers,
            centerCoordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0),
            zoomLevel: zoom,
            size: CGSize(width: 300, height: 300))

        stub(isHost(serviceHost)) { request in
            if let p = request.URL?.pathComponents {
                let n = p[3].componentsSeparatedByString(",")
                if n[2] == String(zoom) {
                    zoomExp.fulfill()
                }
            }

            return OHHTTPStubsResponse()
        }

        Snapshot(options: options, accessToken: accessToken).image

        waitForExpectationsWithTimeout(1, handler: nil)
    }

    func testSize() {
        let min: UInt32 = 1
        let max: UInt32 = 1280

        let width  = arc4random_uniform(max - min) + min
        let height = arc4random_uniform(max - min) + min

        let sizeExp = expectationWithDescription("size should pass intact for non-retina")

        var options = SnapshotOptions(
            mapIdentifiers: mapIdentifiers,
            size: CGSize(width: CGFloat(width), height: CGFloat(height)))
        options.scale = 1

        stub(isHost(serviceHost)) { request in
            if let p = request.URL?.pathComponents,
              f = p.last,
              s = f.componentsSeparatedByString(".").first?.componentsSeparatedByString("x")
              where s[0] == String(width) && s[1] == String(height) {
                    sizeExp.fulfill()
            }

            return OHHTTPStubsResponse()
        }

        Snapshot(options: options, accessToken: accessToken).image

        waitForExpectationsWithTimeout(1, handler: nil)
    }

    func testFormats() {
        var expectations = [XCTestExpectation]()
        var optionses = [SnapshotOptions]()
        
        let allFormats: [SnapshotFormat] = [
            .PNG, .PNG32, .PNG64, .PNG128, .PNG256,
            .JPEG, .JPEG70, .JPEG80, .JPEG90,
        ]
        switch allFormats[0] {
        case .PNG, .PNG32, .PNG64, .PNG128, .PNG256,
             .JPEG, .JPEG70, .JPEG80, .JPEG90:
            break
        // If you get a “Switch must be exhaustive, consider adding a default clause” error here, allFormats is missing a format.
        }
        
        for format in allFormats {
            let exp = expectationWithDescription("\(format.rawValue) extension should be requested")
            expectations.append(exp)

            stub(isExtension(format.rawValue)) { request in
                exp.fulfill()
                return OHHTTPStubsResponse()
            }

            var options = SnapshotOptions(
                mapIdentifiers: mapIdentifiers,
                size: CGSize(width: 200, height: 200))
            options.format = format
            optionses.append(options)
        }

        for options in optionses {
            Snapshot(options: options, accessToken: accessToken).image
        }

        waitForExpectationsWithTimeout(1, handler: nil)
    }

    func testRetina() {
        let retinaExp = expectationWithDescription("retina should request @2x asset")

        var options = SnapshotOptions(
            mapIdentifiers: mapIdentifiers,
            size: CGSize(width: 200, height: 200))
        options.scale = 2

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

        Snapshot(options: options, accessToken: accessToken).image

        waitForExpectationsWithTimeout(1, handler: nil)
    }

    func testOverlayBuiltinMarker() {
        let lat = 45.52
        let lon = -122.681944
        let size = Marker.Size.Medium
        let label = "cafe"
        let color = Color.brownColor()
        let colorRaw = "996633"

        let markerExp = expectationWithDescription("builtin marker argument should format Maki request properly")

        let markerOverlay = Marker(
            coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon),
            size: size,
            label: .IconName("cafe"),
            color: color)

        var options = SnapshotOptions(
            mapIdentifiers: mapIdentifiers,
            size: CGSize(width: 200, height: 200))
        options.overlays = [markerOverlay]

        stub(isHost(serviceHost)) { request in
            if let p = request.URL?.pathComponents
              where p[3] == "pin-" + size.rawValue + "-" + label +
                            "+" + colorRaw + "(\(lon),\(lat))" {
                markerExp.fulfill()
            }

            return OHHTTPStubsResponse()
        }

        Snapshot(options: options, accessToken: accessToken).image

        waitForExpectationsWithTimeout(1, handler: nil)
    }

    func testOverlayCustomMarker() {
        let coordinate = CLLocationCoordinate2D(latitude: 45.522, longitude: -122.69)
        let markerURL = NSURL(string: "https://mapbox.com/guides/img/rocket.png")!
        let encodedMarker = "https:%2F%2Fmapbox.com%2Fguides%2Fimg%2Frocket.png"

        let markerExp = expectationWithDescription("custom marker argument should properly encode request")

        let customMarker = CustomMarker(
            coordinate: coordinate,
            URL: markerURL)

        var options = SnapshotOptions(
            mapIdentifiers: mapIdentifiers,
            size: CGSize(width: 200, height: 200))
        options.overlays = [customMarker]

        stub(isHost(serviceHost)) { request in
            // We need to examine the URL string here manually since NSURL.pathComponents()
            // decodes the percent escaping, which does us no good.
            if let requestString = request.URL?.absoluteString {
                let m = requestString.componentsSeparatedByString("/")
                if m[5] == "url-\(encodedMarker)(\(coordinate.longitude),\(coordinate.latitude))" {
                    markerExp.fulfill()
                }
            }

            return OHHTTPStubsResponse()
        }

        Snapshot(options: options, accessToken: accessToken).image

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
        let geojsonOverlay = GeoJSON(objectString: geojsonString as String)

        var options = SnapshotOptions(
            mapIdentifiers: mapIdentifiers,
            size: CGSize(width: 200, height: 200))
        options.overlays = [geojsonOverlay]

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

        Snapshot(options: options, accessToken: accessToken).image

        waitForExpectationsWithTimeout(1, handler: nil)
    }

    func testOverlayPath() {
        let strokeWidth = 2
        let strokeColor = Color.blackColor()
        let strokeColorRaw = "000000"
        let strokeOpacity = 0.75
        let fillColor = Color.redColor()
        let fillColorRaw = "ff0000"
        let fillOpacity = 0.25
        let encodedPolyline = "(upztG%60jxkVn@al@bo@nFWzuAaTcAyZen@)"

        let path = Path(
            coordinates: [
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

        var options = SnapshotOptions(
            mapIdentifiers: mapIdentifiers,
            size: CGSize(width: 200, height: 200))
        options.overlays = [path]

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
        
        Snapshot(options: options, accessToken: accessToken).image
        
        waitForExpectationsWithTimeout(1, handler: nil)
    }

    func testAutoFit() {
        let autoFitExp = expectationWithDescription("auto-fit should pass correct argument")

        let markerOverlay = Marker(
            coordinate: CLLocationCoordinate2D(latitude: 45.52, longitude: -122.681944),
            size: .Medium,
            label: .IconName("cafe"),
            color: .brownColor())

        var options = SnapshotOptions(
            mapIdentifiers: mapIdentifiers,
            size: CGSize(width: 200, height: 200))
        options.overlays = [markerOverlay]

        stub(isHost(serviceHost)) { request in
            if let p = request.URL?.pathComponents
              where p[4] == "auto" {
                autoFitExp.fulfill()
            }

            return OHHTTPStubsResponse()
        }

        Snapshot(options: options, accessToken: accessToken).image

        waitForExpectationsWithTimeout(1, handler: nil)
    }

}
