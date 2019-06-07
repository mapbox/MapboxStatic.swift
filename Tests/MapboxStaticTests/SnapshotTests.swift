import Foundation
import XCTest
import OHHTTPStubs
import CoreLocation
@testable import MapboxStatic

class SnapshotTests: XCTestCase {
    override func tearDown() {
        OHHTTPStubs.removeAllStubs()
        super.tearDown()
    }
    
    let styleURL = URL(string: "mapbox://styles/mapbox/streets-v9")!
    
    func testConvertingAltitudes() {
        let tallSize = CGSize(width: 600, height: 1200)
        let midSize = CGSize(width: 600, height: 800)
        let shortSize = CGSize(width: 600, height: 400)
        
        XCTAssertLessThan(SnapshotCamera.zoomLevelForAltitude(1800, pitch: 0, latitude: 0, size: midSize), SnapshotCamera.zoomLevelForAltitude(1800, pitch: 0, latitude: 0, size: tallSize))
        XCTAssertGreaterThan(SnapshotCamera.zoomLevelForAltitude(1800, pitch: 0, latitude: 0, size: midSize), SnapshotCamera.zoomLevelForAltitude(1800, pitch: 0, latitude: 0, size: shortSize))
    }
    
    func testBasicMap() {
        let options = SnapshotOptions(styleURL: styleURL, size: CGSize(width: 200, height: 200))
        options.scale = 1
        
        stub(condition: isHost("api.mapbox.com")
            && isPath("/styles/v1/mapbox/streets-v9/static/auto/200x200")
            && containsQueryParams(["access_token": BogusToken])) { request in
                let path = Bundle(for: type(of: self)).path(forResource: "basic-gl", ofType: "png")!
                return fixture(filePath: path, headers: ["Content-Type": "image/png"])
        }
        
        stub(condition: isHost("api.mapbox.com")
            && isPath("/styles/v1/mapbox/streets-v9/static/auto/200x200@2x")
            && containsQueryParams(["access_token": BogusToken])) { request in
                let path = Bundle(for: type(of: self)).path(forResource: "basic-gl@2x", ofType: "png")!
                return fixture(filePath: path, headers: ["Content-Type": "image/png"])
        }
        
        let loDPIImage = Snapshot(options: options, accessToken: BogusToken).image
        XCTAssertNotNil(loDPIImage)
        XCTAssertEqual(loDPIImage?.size.width, 200)
        XCTAssertEqual(loDPIImage?.size.height, 200)
        
        options.scale = 2
        let hiDPIImage = Snapshot(options: options, accessToken: BogusToken).image
        XCTAssertNotNil(hiDPIImage)
        XCTAssertEqual(hiDPIImage?.size.width, 400, "LoDPI image should be half the width of HiDPI image.")
        XCTAssertEqual(hiDPIImage?.size.height, 400, "LoDPI image should be half the height of HiDPI image.")
    }
    
    func testCenter() {
        let camera = SnapshotCamera(lookingAtCenter: CLLocationCoordinate2D(latitude: 5.971389, longitude: 116.095278), zoomLevel: 0)
        let options = SnapshotOptions(styleURL: styleURL, camera: camera, size: CGSize(width: 200, height: 200))
        options.scale = 1
        
        stub(condition: isHost("api.mapbox.com")
            && isPath("/styles/v1/mapbox/streets-v9/static/116.095278,5.971389,0.0/200x200")
            && containsQueryParams(["access_token": BogusToken])) { request in
                let path = Bundle(for: type(of: self)).path(forResource: "center-gl", ofType: "png")!
                return fixture(filePath: path, headers: ["Content-Type": "image/png"])
        }
        
        XCTAssertNotNil(Snapshot(options: options, accessToken: BogusToken).image)
    }
    
    func testZoom() {
        let camera = SnapshotCamera(lookingAtCenter: CLLocationCoordinate2D(latitude: 0, longitude: 0), zoomLevel: 6)
        let options = SnapshotOptions(styleURL: styleURL, camera: camera, size: CGSize(width: 300, height: 300))
        options.scale = 1
        
        stub(condition: isHost("api.mapbox.com")
            && isPath("/styles/v1/mapbox/streets-v9/static/0.0,0.0,6.0/300x300")
            && containsQueryParams(["access_token": BogusToken])) { request in
                let path = Bundle(for: type(of: self)).path(forResource: "zoom-gl", ofType: "png")!
                return fixture(filePath: path, headers: ["Content-Type": "image/png"])
        }
        
        XCTAssertNotNil(Snapshot(options: options, accessToken: BogusToken).image)
    }
    
    func testRotate() {
        let camera = SnapshotCamera(lookingAtCenter: CLLocationCoordinate2D(latitude: 0, longitude: 0), zoomLevel: 0)
        camera.heading = 45
        let options = SnapshotOptions(styleURL: styleURL, camera: camera, size: CGSize(width: 300, height: 300))
        options.scale = 1
        
        stub(condition: isHost("api.mapbox.com")
            && isPath("/styles/v1/mapbox/streets-v9/static/0.0,0.0,0.0,45.0/300x300")
            && containsQueryParams(["access_token": BogusToken])) { request in
                let path = Bundle(for: type(of: self)).path(forResource: "rotate", ofType: "png")!
                return fixture(filePath: path, headers: ["Content-Type": "image/png"])
        }
        
        XCTAssertNotNil(Snapshot(options: options, accessToken: BogusToken).image)
    }
    
    func testTilt() {
        let camera = SnapshotCamera(lookingAtCenter: CLLocationCoordinate2D(latitude: 0, longitude: 0), zoomLevel: 0)
        camera.pitch = 60
        let options = SnapshotOptions(styleURL: styleURL, camera: camera, size: CGSize(width: 300, height: 300))
        options.scale = 1
        
        stub(condition: isHost("api.mapbox.com")
            && isPath("/styles/v1/mapbox/streets-v9/static/0.0,0.0,0.0,0.0,60.0/300x300")
            && containsQueryParams(["access_token": BogusToken])) { request in
                let path = Bundle(for: type(of: self)).path(forResource: "tilt", ofType: "png")!
                return fixture(filePath: path, headers: ["Content-Type": "image/png"])
        }
        
        XCTAssertNotNil(Snapshot(options: options, accessToken: BogusToken).image)
    }
    
    func testSize() {
        let min: UInt32 = 1
        let max: UInt32 = 1280
        
        let width = arc4random_uniform(max - min) + min
        let height = arc4random_uniform(max - min) + min
        
        let options = SnapshotOptions(
            styleURL: styleURL,
            size: CGSize(width: CGFloat(width), height: CGFloat(height)))
        options.scale = 1
        
        stub(condition: isHost("api.mapbox.com")
            && isPath("/styles/v1/mapbox/streets-v9/static/auto/\(width)x\(height)")
            && containsQueryParams(["access_token": BogusToken])) { request in
                let path = Bundle(for: type(of: self)).path(forResource: "basic-gl", ofType: "png")!
                return fixture(filePath: path, headers: ["Content-Type": "image/png"])
        }
        
        XCTAssertNotNil(Snapshot(options: options, accessToken: BogusToken).image)
        // Can’t test the image size here because the fixture is fixed-size but the tests chooses the size at random.
    }
    
    func testHidingLogo() {
        let options = SnapshotOptions(styleURL: styleURL, size: CGSize(width: 200, height: 200))
        options.showsLogo = false
        options.scale = 1
        
        stub(condition: isHost("api.mapbox.com")
            && isPath("/styles/v1/mapbox/streets-v9/static/auto/200x200")
            && containsQueryParams(["access_token": BogusToken, "logo": "false"])) { request in
                let path = Bundle(for: type(of: self)).path(forResource: "no-logo", ofType: "png")!
                return fixture(filePath: path, headers: ["Content-Type": "image/png"])
        }
        
        XCTAssertNotNil(Snapshot(options: options, accessToken: BogusToken).image)
    }
    
    func testHidingAttribution() {
        let options = SnapshotOptions(styleURL: styleURL, size: CGSize(width: 200, height: 200))
        options.showsAttribution = false
        options.scale = 1
        
        stub(condition: isHost("api.mapbox.com")
            && isPath("/styles/v1/mapbox/streets-v9/static/auto/200x200")
            && containsQueryParams(["access_token": BogusToken, "attribution": "false"])) { request in
                let path = Bundle(for: type(of: self)).path(forResource: "no-attribution", ofType: "png")!
                return fixture(filePath: path, headers: ["Content-Type": "image/png"])
        }
        
        XCTAssertNotNil(Snapshot(options: options, accessToken: BogusToken).image)
    }
}
