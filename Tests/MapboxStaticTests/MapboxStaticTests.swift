import XCTest
import OHHTTPStubs
import CoreLocation
import Foundation
@testable import MapboxStatic

let BogusToken = "pk.feedCafeDadeDeadBeef-BadeBede.FadeCafeDadeDeed-BadeBede"

class MapboxStaticTests: XCTestCase {
    override func setUp() {
        super.setUp()
        
        // Make sure tests run in all time zones
        NSTimeZone.default = TimeZone(secondsFromGMT: 0)!
    }
    
    func testConfiguration() {
        let styleURL = URL(string: "mapbox://styles/mapbox/streets-v9")!
        let camera = SnapshotCamera(lookingAtCenter: CLLocationCoordinate2D(latitude: 0, longitude: 0), zoomLevel: 0)
        let options = SnapshotOptions(styleURL: styleURL, camera: camera, size: CGSize(width: 200, height: 200))
        let snapshot = Snapshot(options: options, accessToken: BogusToken)
        
        XCTAssertEqual(snapshot.accessToken, BogusToken)
        XCTAssertEqual(snapshot.apiEndpoint.absoluteString, "https://api.mapbox.com")
    }
    
    func testRateLimitErrorParsing() {
        let json = ["message" : "Hit rate limit"]
        
        let url = URL(string: "https://api.mapbox.com")!
        let headerFields = ["X-Rate-Limit-Interval" : "60", "X-Rate-Limit-Limit" : "600", "X-Rate-Limit-Reset" : "1479460584"]
        let response = HTTPURLResponse(url: url, statusCode: 429, httpVersion: nil, headerFields: headerFields)
        
        let error: NSError? = nil
        
        let resultError = Snapshot.descriptiveError(json, response: response, underlyingError: error)
        
        XCTAssertEqual(resultError.localizedFailureReason, "More than 600 requests have been made with this access token within a period of 1 minute.")
        XCTAssertEqual(resultError.localizedRecoverySuggestion, "Wait until November 18, 2016 at 9:16:24 AM GMT before retrying.")
    }
}
