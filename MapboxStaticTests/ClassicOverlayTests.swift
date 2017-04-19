import Foundation
import XCTest
import OHHTTPStubs
import CoreLocation
@testable import MapboxStatic

#if os(OSX)
    typealias Color = NSColor
#else
    typealias Color = UIColor
#endif

class ClassicOverlayTests: XCTestCase {
    override func tearDown() {
        OHHTTPStubs.removeAllStubs()
        super.tearDown()
    }
    
    func testBuiltinMarker() {
        let markerOverlay = Marker(
            coordinate: CLLocationCoordinate2D(latitude: 45.52, longitude: -122.681944),
            size: .medium,
            iconName: "cafe")
        markerOverlay.color = .brown
        
        let options = ClassicSnapshotOptions(
            mapIdentifiers: ["mapbox.streets"],
            size: CGSize(width: 200, height: 200))
        options.overlays = [markerOverlay]
        options.scale = 1
        
        stub(condition: isHost("api.mapbox.com")
            && isPath("/v4/mapbox.streets/pin-m-cafe+996633(-122.681944,45.52)/auto/200x200.png")
            && containsQueryParams(["access_token": BogusToken])) { request in
                let path = Bundle(for: type(of: self)).path(forResource: "marker", ofType: "png")!
                return fixture(filePath: path, headers: ["Content-Type": "image/png"])
        }
        
        XCTAssertNotNil(Snapshot(options: options, accessToken: BogusToken).image)
    }
    
    func testCustomMarker() {
        let coordinate = CLLocationCoordinate2D(latitude: 45.522, longitude: -122.69)
        let markerURL = URL(string: "https://www.mapbox.com/help/img/screenshots/rocket.png")!
        
        let customMarker = CustomMarker(coordinate: coordinate, url: markerURL)
        
        let options = ClassicSnapshotOptions(
            mapIdentifiers: ["mapbox.streets"],
            size: CGSize(width: 200, height: 200))
        options.overlays = [customMarker]
        options.scale = 1
        
        stub(condition: isHost("api.mapbox.com")
            && isPath("/v4/mapbox.streets/url-\(markerURL)(-122.69,45.522)/auto/200x200.png")
            && containsQueryParams(["access_token": BogusToken])) { request in
                let path = Bundle(for: type(of: self)).path(forResource: "rocket", ofType: "png")!
                return fixture(filePath: path, headers: ["Content-Type": "image/png"])
        }
        
        XCTAssertNotNil(Snapshot(options: options, accessToken: BogusToken).image)
    }
    
    func testGeoJSONString() {
        let geoJSONURL = Bundle(for: type(of: self)).url(forResource: "polyline", withExtension: "geojson")!
        
        let geoJSONString = try! String(contentsOf: geoJSONURL, encoding: .utf8)
        let geoJSONOverlay = GeoJSON(objectString: geoJSONString)
        
        let options = ClassicSnapshotOptions(
            mapIdentifiers: ["mapbox.streets"],
            size: CGSize(width: 200, height: 200))
        options.overlays = [geoJSONOverlay]
        options.scale = 1
        
        stub(condition: isHost("api.mapbox.com")
            && isPath("/v4/mapbox.streets/geojson(\(geoJSONString))/auto/200x200.png")
            && containsQueryParams(["access_token": BogusToken])) { request in
                let path = Bundle(for: type(of: self)).path(forResource: "geojson", ofType: "png")!
                return fixture(filePath: path, headers: ["Content-Type": "image/png"])
        }
        
        XCTAssertNotNil(Snapshot(options: options, accessToken: BogusToken).image)
    }
    
    func testGeoJSONObject() {
        let geoJSONURL = Bundle(for: type(of: self)).url(forResource: "polyline", withExtension: "geojson")!
        
        let data = try! Data(contentsOf: geoJSONURL)
        let geoJSON = try! JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
        let geoJSONOverlay = try! GeoJSON(object: geoJSON)
        
        let options = ClassicSnapshotOptions(
            mapIdentifiers: ["mapbox.streets"],
            size: CGSize(width: 200, height: 200))
        options.overlays = [geoJSONOverlay]
        options.scale = 1
        
        let geoJSONString = "{\"type\":\"FeatureCollection\",\"features\":[{\"type\":\"Feature\",\"properties\":{\"stroke-width\":3,\"stroke-opacity\":1,\"stroke\":\"#00f\"},\"geometry\":{\"type\":\"LineString\",\"coordinates\":[[-122.6978445053101,45.51863175803531],[-122.6909136772156,45.52165369248977],[-122.68630027771,45.51891742047702],[-122.6850986480713,45.51631633525551],[-122.6823306083679,45.51950377568216]]}}]}"
        
        stub(condition: isHost("api.mapbox.com")
            && isPath("/v4/mapbox.streets/geojson(\(geoJSONString))/auto/200x200.png")
            && containsQueryParams(["access_token": BogusToken])) { request in
                let path = Bundle(for: type(of: self)).path(forResource: "geojson", ofType: "png")!
                return fixture(filePath: path, headers: ["Content-Type": "image/png"])
        }
        
        XCTAssertNotNil(Snapshot(options: options, accessToken: BogusToken).image)
    }
    
    func testPath() {
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
        path.strokeWidth = 2
        path.strokeColor = Color.black.withAlphaComponent(0.75)
        path.fillColor = Color.red.withAlphaComponent(0.25)
        
        let options = ClassicSnapshotOptions(
            mapIdentifiers: ["mapbox.streets"],
            size: CGSize(width: 200, height: 200))
        options.overlays = [path]
        options.scale = 1
        
        let encodedPolyline = "upztG`jxkVn@al@bo@nFWzuAaTcAyZen@"
        
        stub(condition: isHost("api.mapbox.com")
            && isPath("/v4/mapbox.streets/path-2+000000-0.75+ff0000-0.25(\(encodedPolyline))/auto/200x200.png")
            && containsQueryParams(["access_token": BogusToken])) { request in
                let path = Bundle(for: type(of: self)).path(forResource: "path", ofType: "png")!
                return fixture(filePath: path, headers: ["Content-Type": "image/png"])
        }
        
        XCTAssertNotNil(Snapshot(options: options, accessToken: BogusToken).image)
    }
}
