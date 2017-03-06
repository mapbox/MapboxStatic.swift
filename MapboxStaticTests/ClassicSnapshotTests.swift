import Foundation
import XCTest
import OHHTTPStubs
import CoreLocation
@testable import MapboxStatic

class ClassicSnapshotTests: XCTestCase {
    let mapIdentifiers = ["mapbox.mapbox-streets-v6"]
    let accessToken = "pk.feedCafeDadeDeadBeef-BadeBede.FadeCafeDadeDeed-BadeBede"
    let serviceHost = "api.mapbox.com"
    
    override func setUp() {
        super.setUp()
        OHHTTPStubs.removeAllStubs()
    }

    fileprivate func parseQueryString(_ request: URLRequest) -> Dictionary<String, String> {
        var result = Dictionary<String, String>()
        let pairs = request.url!.query!.components(separatedBy: "&")
        for pair in pairs {
            let parts = pair.components(separatedBy: "=")
            result[parts[0]] = parts[1]
        }
        return result
    }

    func testBasicMap() {
        // passed args
        let mapIDExp = expectation(description: "mapID should be passed")
        let sizeExp = expectation(description: "size should be passed")
        let accessTokenExp = expectation(description: "access token should be passed")

        // implicit args
        let versionExp = expectation(description: "API version should be v4")
        let formatExp = expectation(description: "format should default to PNG")
        let retinaExp = expectation(description: "retina should default to disabled")
        let overlaysExp = expectation(description: "overlays should default to empty")
        let autoFitExp = expectation(description: "auto-fit should default to enabled")

        let options = ClassicSnapshotOptions(mapIdentifiers: mapIdentifiers, size: CGSize(width: 200, height: 200))
        
        let scale: CGFloat
        #if os(OSX)
            scale = NSScreen.main()?.backingScaleFactor ?? 1
        #else
            scale = UIScreen.main.scale
        #endif

        stub(condition: isHost(serviceHost)
            && containsQueryParams(["access_token": accessToken])) { [unowned self] request in
            if let p = request.url?.pathComponents {
                if p[1] == "v4" {
                    versionExp.fulfill()
                }
                if p[2] == self.mapIdentifiers.joined(separator: ",") {
                    mapIDExp.fulfill()
                }
                if p[3] == "auto" {
                    overlaysExp.fulfill()
                    autoFitExp.fulfill()
                }
                if p[4].components(separatedBy: ".").first == "200x200" && scale == 1 {
                    retinaExp.fulfill()
                    sizeExp.fulfill()
                }
                else if p[4].components(separatedBy: ".").first == "200x200@2x" && scale > 1 {
                    retinaExp.fulfill()
                    sizeExp.fulfill()
                }
                if p[4].components(separatedBy: ".").last == "png" {
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

        _ = Snapshot(options: options, accessToken: accessToken).image

        waitForExpectations(timeout: 1, handler: nil)
    }

    func testCenter() {
        let center = CLLocationCoordinate2D(latitude: 5.971389, longitude: 116.095278)

        let centerExp = expectation(description: "center should get passed intact")

        let options = ClassicSnapshotOptions(
            mapIdentifiers: mapIdentifiers,
            centerCoordinate: center,
            zoomLevel: 0,
            size: CGSize(width: 200, height: 200))

        stub(condition: isHost(serviceHost)) { request in
            if let p = request.url?.pathComponents {
                let n = p[3].components(separatedBy: ",")
                if n[0] == String(center.longitude) && n[1] == String(center.latitude) {
                    centerExp.fulfill()
                }
            }

            return OHHTTPStubsResponse()
        }

        _ = Snapshot(options: options, accessToken: accessToken).image

        waitForExpectations(timeout: 1, handler: nil)
    }

    func testZoom() {
        let zoom = 6

        let zoomExp = expectation(description: "zoom should get passed intact")

        let options = ClassicSnapshotOptions(
            mapIdentifiers: mapIdentifiers,
            centerCoordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0),
            zoomLevel: zoom,
            size: CGSize(width: 300, height: 300))

        stub(condition: isHost(serviceHost)) { request in
            if let p = request.url?.pathComponents {
                let n = p[3].components(separatedBy: ",")
                if n[2] == String(zoom) {
                    zoomExp.fulfill()
                }
            }

            return OHHTTPStubsResponse()
        }

        _ = Snapshot(options: options, accessToken: accessToken).image

        waitForExpectations(timeout: 1, handler: nil)
    }

    func testSize() {
        let min: UInt32 = 1
        let max: UInt32 = 1280

        let width  = arc4random_uniform(max - min) + min
        let height = arc4random_uniform(max - min) + min

        let sizeExp = expectation(description: "size should pass intact for non-retina")

        let options = ClassicSnapshotOptions(
            mapIdentifiers: mapIdentifiers,
            size: CGSize(width: CGFloat(width), height: CGFloat(height)))
        options.scale = 1

        stub(condition: isHost(serviceHost)) { request in
            if let p = request.url?.pathComponents,
              let f = p.last,
              let s = f.components(separatedBy: ".").first?.components(separatedBy: "x"), s[0] == String(width) && s[1] == String(height) {
                    sizeExp.fulfill()
            }

            return OHHTTPStubsResponse()
        }

        _ = Snapshot(options: options, accessToken: accessToken).image

        waitForExpectations(timeout: 1, handler: nil)
    }

    func testFormats() {
        var expectations = [XCTestExpectation]()
        var optionses = [ClassicSnapshotOptions]()
        
        let allFormats: [ClassicSnapshotOptions.Format] = [
            .png, .png32, .png64, .png128, .png256,
            .jpeg, .jpeg70, .jpeg80, .jpeg90,
        ]
        
        for format in allFormats {
            let exp = expectation(description: "\(format.rawValue) extension should be requested")
            expectations.append(exp)

            let pathExtension: String
            switch format {
            case .png:
                pathExtension = "png"
            case .png32:
                pathExtension = "png32"
            case .png64:
                pathExtension = "png64"
            case .png128:
                pathExtension = "png128"
            case .png256:
                pathExtension = "png256"
            case .jpeg:
                pathExtension = "jpg"
            case .jpeg70:
                pathExtension = "jpg70"
            case .jpeg80:
                pathExtension = "jpg80"
            case .jpeg90:
                pathExtension = "jpg90"
            // If you get a “Switch must be exhaustive, consider adding a default clause” error here, allFormats is also missing a format.
            }
            stub(condition: isExtension(pathExtension)) { request in
                exp.fulfill()
                return OHHTTPStubsResponse()
            }

            let options = ClassicSnapshotOptions(
                mapIdentifiers: mapIdentifiers,
                size: CGSize(width: 200, height: 200))
            options.format = format
            optionses.append(options)
        }

        for options in optionses {
            _ = Snapshot(options: options, accessToken: accessToken).image
        }

        waitForExpectations(timeout: 1, handler: nil)
    }

    func testRetina() {
        let retinaExp = expectation(description: "retina should request @2x asset")

        let options = ClassicSnapshotOptions(
            mapIdentifiers: mapIdentifiers,
            size: CGSize(width: 200, height: 200))
        options.scale = 2

        stub(condition: isHost(serviceHost)) { request in
            if let p = request.url?.pathComponents,
              let f = p.last,
              let e = f.components(separatedBy: "@").last,
              let s = e.components(separatedBy: ".").first, s == "2x" {
                retinaExp.fulfill()
            }

            return OHHTTPStubsResponse()
        }

        _ = Snapshot(options: options, accessToken: accessToken).image

        waitForExpectations(timeout: 1, handler: nil)
    }

    func testOverlayBuiltinMarker() {
        let lat = 45.52
        let lon = -122.681944
        let size = "m"
        let label = "cafe"
        let color = Color.brown
        let colorRaw = "996633"

        let markerExp = expectation(description: "builtin marker argument should format Maki request properly")

        let markerOverlay = Marker(
            coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon),
            size: .medium,
            iconName: "cafe")
        markerOverlay.color = color

        let options = ClassicSnapshotOptions(
            mapIdentifiers: mapIdentifiers,
            size: CGSize(width: 200, height: 200))
        options.overlays = [markerOverlay]

        stub(condition: isHost(serviceHost)) { request in
            if let p = request.url?.pathComponents, p[3] == "pin-" + size + "-" + label +
                            "+" + colorRaw + "(\(lon),\(lat))" {
                markerExp.fulfill()
            }

            return OHHTTPStubsResponse()
        }

        _ = Snapshot(options: options, accessToken: accessToken).image

        waitForExpectations(timeout: 1, handler: nil)
    }

    func testOverlayCustomMarker() {
        let coordinate = CLLocationCoordinate2D(latitude: 45.522, longitude: -122.69)
        let markerURL = URL(string: "https://mapbox.com/guides/img/rocket.png")!
        let encodedMarker = "https:%2F%2Fmapbox.com%2Fguides%2Fimg%2Frocket.png"

        let markerExp = expectation(description: "custom marker argument should properly encode request")

        let customMarker = CustomMarker(
            coordinate: coordinate,
            url: markerURL)

        let options = ClassicSnapshotOptions(
            mapIdentifiers: mapIdentifiers,
            size: CGSize(width: 200, height: 200))
        options.overlays = [customMarker]

        stub(condition: isHost(serviceHost)) { request in
            // We need to examine the URL string here manually since URL.pathComponents
            // decodes the percent escaping, which does us no good.
            if let requestString = request.url?.absoluteString {
                let m = requestString.components(separatedBy: "/")
                if m[5] == "url-\(encodedMarker)(\(coordinate.longitude),\(coordinate.latitude))" {
                    markerExp.fulfill()
                }
            }

            return OHHTTPStubsResponse()
        }

        _ = Snapshot(options: options, accessToken: accessToken).image

        waitForExpectations(timeout: 1, handler: nil)
    }

    func testOverlayGeoJSON() {
        let geojsonURL = URL(string: "http://git.io/vCv9U")!
        let encodedGeoJSON = "geojson(%7B%0A%20%20%22type%22:%20%22FeatureCollection%22,%0A%20%20%22features%22:%20%5B%0A%20%20%20%20%7B%0A%20%20%20%20%20%20%22type%22:%20%22Feature%22,%0A%20%20%20%20%20%20%22properties%22:%20%7B%0A%20%20%20%20%20%20%20%20%22stroke%22:%20%22%2300f%22,%0A%20%20%20%20%20%20%20%20%22stroke-width%22:%203,%0A%20%20%20%20%20%20%20%20%22stroke-opacity%22:%201%0A%20%20%20%20%20%20%7D,%0A%20%20%20%20%20%20%22geometry%22:%20%7B%0A%20%20%20%20%20%20%20%20%22type%22:%20%22LineString%22,%0A%20%20%20%20%20%20%20%20%22coordinates%22:%20%5B%0A%20%20%20%20%20%20%20%20%20%20%5B%0A%20%20%20%20%20%20%20%20%20%20%20%20-122.69784450531006,%0A%20%20%20%20%20%20%20%20%20%20%20%2045.51863175803531%0A%20%20%20%20%20%20%20%20%20%20%5D,%0A%20%20%20%20%20%20%20%20%20%20%5B%0A%20%20%20%20%20%20%20%20%20%20%20%20-122.69091367721559,%0A%20%20%20%20%20%20%20%20%20%20%20%2045.52165369248977%0A%20%20%20%20%20%20%20%20%20%20%5D,%0A%20%20%20%20%20%20%20%20%20%20%5B%0A%20%20%20%20%20%20%20%20%20%20%20%20-122.68630027770996,%0A%20%20%20%20%20%20%20%20%20%20%20%2045.518917420477024%0A%20%20%20%20%20%20%20%20%20%20%5D,%0A%20%20%20%20%20%20%20%20%20%20%5B%0A%20%20%20%20%20%20%20%20%20%20%20%20-122.68509864807127,%0A%20%20%20%20%20%20%20%20%20%20%20%2045.51631633525551%0A%20%20%20%20%20%20%20%20%20%20%5D,%0A%20%20%20%20%20%20%20%20%20%20%5B%0A%20%20%20%20%20%20%20%20%20%20%20%20-122.68233060836793,%0A%20%20%20%20%20%20%20%20%20%20%20%2045.51950377568216%0A%20%20%20%20%20%20%20%20%20%20%5D%0A%20%20%20%20%20%20%20%20%5D%0A%20%20%20%20%20%20%7D%0A%20%20%20%20%7D%0A%20%20%5D%0A%7D)"

        let geojsonExp = expectation(description: "GeoJSON argument should properly encode request")

        stub(condition: isHost(geojsonURL.host!)) { request in
            return fixture(filePath: Bundle(for: type(of: self)).path(forResource: "polyline", ofType: "geojson")!,
                headers: nil)
        }

        let geojsonString = try! String(contentsOf: geojsonURL, encoding: .utf8)
        let geojsonOverlay = GeoJSON(objectString: geojsonString)

        let options = ClassicSnapshotOptions(
            mapIdentifiers: mapIdentifiers,
            size: CGSize(width: 200, height: 200))
        options.overlays = [geojsonOverlay]

        stub(condition: isHost(serviceHost)) { request in
            // We need to examine the URL string here manually since URL.pathComponents
            // decodes the percent escaping, which does us no good.
            if let requestString = request.url?.absoluteString {
                let m = requestString.components(separatedBy: "/")
                if m[5] == encodedGeoJSON {
                    geojsonExp.fulfill()
                }
            }

            return OHHTTPStubsResponse()
        }

        _ = Snapshot(options: options, accessToken: accessToken).image

        waitForExpectations(timeout: 1, handler: nil)
    }

    func testOverlayPath() {
        let strokeWidth = 2
        let strokeColor = Color.black
        let strokeColorRaw = "000000"
        let strokeOpacity = 0.75
        let fillColor = Color.red
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
            ])
        path.strokeWidth = strokeWidth
        path.strokeColor = strokeColor
        path.strokeOpacity = strokeOpacity
        path.fillColor = fillColor
        path.fillOpacity = fillOpacity

        let pathExp = expectation(description: "raw path argument should properly encode request")

        let options = ClassicSnapshotOptions(
            mapIdentifiers: mapIdentifiers,
            size: CGSize(width: 200, height: 200))
        options.overlays = [path]

        stub(condition: isHost(serviceHost)) { request in
            // We need to examine the URL string here manually since URL.pathComponents
            // decodes the percent escaping, which does us no good.
            if let requestString = request.url?.absoluteString {
                let p = requestString.components(separatedBy: "/")
                if p[5] == "path-\(strokeWidth)+\(strokeColorRaw)-\(strokeOpacity)+" +
                           "\(fillColorRaw)-\(fillOpacity)" + encodedPolyline {
                    pathExp.fulfill()
                }
            }

            return OHHTTPStubsResponse()
        }
        
        _ = Snapshot(options: options, accessToken: accessToken).image
        
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testAutoFit() {
        let autoFitExp = expectation(description: "auto-fit should pass correct argument")

        let markerOverlay = Marker(
            coordinate: CLLocationCoordinate2D(latitude: 45.52, longitude: -122.681944),
            size: .medium,
            iconName: "cafe")
        markerOverlay.color = .brown

        let options = ClassicSnapshotOptions(
            mapIdentifiers: mapIdentifiers,
            size: CGSize(width: 200, height: 200))
        options.overlays = [markerOverlay]

        stub(condition: isHost(serviceHost)) { request in
            if let p = request.url?.pathComponents, p[4] == "auto" {
                autoFitExp.fulfill()
            }

            return OHHTTPStubsResponse()
        }

        _ = Snapshot(options: options, accessToken: accessToken).image

        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testStandaloneMarker() {
        let size = "m"
        let label = "cafe"
        let color = Color.brown
        let colorRaw = "996633"
        
        let markerExp = expectation(description: "builtin marker argument should format Maki request properly")
        
        let options = MarkerOptions(
            size: .medium,
            iconName: "cafe")
        options.color = color
        
        stub(condition: isHost(serviceHost)) { request in
            let scaleSuffix = options.scale == 1 ? "" : "@2x"
            if let p = request.url?.pathComponents, p[3] == "pin-\(size)-\(label)+\(colorRaw)\(scaleSuffix).png" {
                markerExp.fulfill()
            }
            
            return OHHTTPStubsResponse()
        }
        
        _ = Snapshot(options: options, accessToken: accessToken).image
        
        waitForExpectations(timeout: 1, handler: nil)
    }
}
