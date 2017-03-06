import XCTest
import OHHTTPStubs
import CoreLocation
import Foundation
@testable import MapboxStatic

#if os(OSX)
    typealias Color = NSColor
#else
    typealias Color = UIColor
#endif

class MapboxStaticTests: XCTestCase {
    override func setUp() {
        super.setUp()
        
        // Make sure tests run in all time zones
        NSTimeZone.default = TimeZone(secondsFromGMT: 0)!
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
