import Foundation
import XCTest
import OHHTTPStubs
import CoreLocation
@testable import MapboxStatic

class ClassicSnapshotTests: XCTestCase {
    override func tearDown() {
        OHHTTPStubs.removeAllStubs()
        super.tearDown()
    }
    
    func testBasicMap() {
        let options = ClassicSnapshotOptions(mapIdentifiers: ["mapbox.mapbox-streets-v6"], size: CGSize(width: 200, height: 200))
        options.scale = 1
        
        stub(condition: isHost("api.mapbox.com")
            && isPath("/v4/mapbox.mapbox-streets-v6/auto/200x200.png")
            && containsQueryParams(["access_token": BogusToken])) { request in
                let path = Bundle(for: type(of: self)).path(forResource: "basic", ofType: "png")!
                return fixture(filePath: path, headers: ["Content-Type": "image/png"])
        }
        
        stub(condition: isHost("api.mapbox.com")
            && isPath("/v4/mapbox.mapbox-streets-v6/auto/200x200@2x.png")
            && containsQueryParams(["access_token": BogusToken])) { request in
                let path = Bundle(for: type(of: self)).path(forResource: "basic@2x", ofType: "png")!
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
        let options = ClassicSnapshotOptions(
            mapIdentifiers: ["mapbox.mapbox-streets-v6"],
            centerCoordinate: CLLocationCoordinate2D(latitude: 5.971389, longitude: 116.095278),
            zoomLevel: 0,
            size: CGSize(width: 200, height: 200))
        options.scale = 1
        
        stub(condition: isHost("api.mapbox.com")
            && isPath("/v4/mapbox.mapbox-streets-v6/116.095278,5.971389,0/200x200.png")
            && containsQueryParams(["access_token": BogusToken])) { request in
                let path = Bundle(for: type(of: self)).path(forResource: "center", ofType: "png")!
                return fixture(filePath: path, headers: ["Content-Type": "image/png"])
        }
        
        XCTAssertNotNil(Snapshot(options: options, accessToken: BogusToken).image)
    }
    
    func testZoom() {
        let options = ClassicSnapshotOptions(
            mapIdentifiers: ["mapbox.mapbox-streets-v6"],
            centerCoordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0),
            zoomLevel: 6,
            size: CGSize(width: 300, height: 300))
        options.scale = 1
        
        stub(condition: isHost("api.mapbox.com")
            && isPath("/v4/mapbox.mapbox-streets-v6/0.0,0.0,6/300x300.png")
            && containsQueryParams(["access_token": BogusToken])) { request in
                let path = Bundle(for: type(of: self)).path(forResource: "zoom", ofType: "png")!
                return fixture(filePath: path, headers: ["Content-Type": "image/png"])
        }
        
        XCTAssertNotNil(Snapshot(options: options, accessToken: BogusToken).image)
    }
    
    func testSize() {
        let min: UInt32 = 1
        let max: UInt32 = 1280
        
        let width = arc4random_uniform(max - min) + min
        let height = arc4random_uniform(max - min) + min
        
        let options = ClassicSnapshotOptions(
            mapIdentifiers: ["mapbox.mapbox-streets-v6"],
            size: CGSize(width: CGFloat(width), height: CGFloat(height)))
        options.scale = 1
        
        stub(condition: isHost("api.mapbox.com")
            && isPath("/v4/mapbox.mapbox-streets-v6/auto/\(width)x\(height).png")
            && containsQueryParams(["access_token": BogusToken])) { request in
                let path = Bundle(for: type(of: self)).path(forResource: "basic", ofType: "png")!
                return fixture(filePath: path, headers: ["Content-Type": "image/png"])
        }
        
        XCTAssertNotNil(Snapshot(options: options, accessToken: BogusToken).image)
        // Can’t test the image size here because the fixture is fixed-size but the tests chooses the size at random.
    }
    
    func testFormats() {
        let allFormats: [ClassicSnapshotOptions.Format] = [
            .png, .png32, .png64, .png128, .png256,
            .jpeg, .jpeg70, .jpeg80, .jpeg90,
        ]
        
        for format in allFormats {
            let pathExtension: String
            let mimeType: String
            switch format {
            case .png:
                pathExtension = "png"
                mimeType = "image/png"
            case .png32:
                pathExtension = "png32"
                mimeType = "image/png"
            case .png64:
                pathExtension = "png64"
                mimeType = "image/png"
            case .png128:
                pathExtension = "png128"
                mimeType = "image/png"
            case .png256:
                pathExtension = "png256"
                mimeType = "image/png"
            case .jpeg:
                pathExtension = "jpg"
                mimeType = "image/jpeg"
            case .jpeg70:
                pathExtension = "jpg70"
                mimeType = "image/jpeg"
            case .jpeg80:
                pathExtension = "jpg80"
                mimeType = "image/jpeg"
            case .jpeg90:
                pathExtension = "jpg90"
                mimeType = "image/jpeg"
                // If you get a “Switch must be exhaustive, consider adding a default clause” error here, allFormats is also missing a format.
            }
            
            testFormat(format, pathExtension: pathExtension, mimeType: mimeType)
        }
    }
    
    func testFormat(_ format: ClassicSnapshotOptions.Format, pathExtension: String, mimeType: String) {
        let options = ClassicSnapshotOptions(
            mapIdentifiers: ["mapbox.streets"],
            size: CGSize(width: 200, height: 200))
        options.format = format
        options.scale = 1
        
        stub(condition: isHost("api.mapbox.com")
            && pathStartsWith("/v4/mapbox.streets/auto/200x200")
            && isExtension(pathExtension)
            && containsQueryParams(["access_token": BogusToken])) { request in
                let path = Bundle(for: type(of: self)).path(forResource: "format", ofType: pathExtension)!
                return fixture(filePath: path, headers: ["Content-Type": mimeType])
        }
        
        XCTAssertNotNil(Snapshot(options: options, accessToken: BogusToken).image)
    }
    
    func testStandaloneMarker() {
        let options = MarkerOptions(size: .medium, iconName: "cafe")
        options.color = .brown
        options.scale = 1
        
        let hexColor: String
        #if os(macOS)
            hexColor = "865226"
        #else
            hexColor = "996633"
        #endif
        stub(condition: isHost("api.mapbox.com")
            && isPath("/v4/marker/pin-m-cafe+\(hexColor).png")
            && containsQueryParams(["access_token": BogusToken])) { request in
                let path = Bundle(for: type(of: self)).path(forResource: "cafe", ofType: "png")!
                return fixture(filePath: path, headers: ["Content-Type": "image/png"])
        }
        
        XCTAssertNotNil(Snapshot(options: options, accessToken: BogusToken).image)
    }
}
