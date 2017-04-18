#if os(OSX)
    import Cocoa
#elseif os(watchOS)
    import WatchKit
#else
    import UIKit
#endif

typealias JSONDictionary = [String: Any]

/// Indicates that an error occurred in MapboxStatic.
public let MBStaticErrorDomain = "MBStaticErrorDomain"

/// The Mapbox access token specified in the main application bundle’s Info.plist.
let defaultAccessToken = Bundle.main.object(forInfoDictionaryKey: "MGLMapboxAccessToken") as? String

/// The user agent string for any HTTP requests performed directly within this library.
let userAgent: String = {
    var components: [String] = []
    
    if let appName = Bundle.main.infoDictionary?["CFBundleName"] as? String ?? Bundle.main.infoDictionary?["CFBundleIdentifier"] as? String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        components.append("\(appName)/\(version)")
    }
    
    let libraryBundle = Bundle(for: Snapshot.self)
    
    if let libraryName = libraryBundle.infoDictionary?["CFBundleName"] as? String, let version = libraryBundle.infoDictionary?["CFBundleShortVersionString"] as? String {
        components.append("\(libraryName)/\(version)")
    }
    
    let system: String
    #if os(OSX)
        system = "macOS"
    #elseif os(iOS)
        system = "iOS"
    #elseif os(watchOS)
        system = "watchOS"
    #elseif os(tvOS)
        system = "tvOS"
    #elseif os(Linux)
        system = "Linux"
    #endif
    let systemVersion = ProcessInfo().operatingSystemVersion
    components.append("\(system)/\(systemVersion.majorVersion).\(systemVersion.minorVersion).\(systemVersion.patchVersion)")
    
    let chip: String
    #if arch(x86_64)
        chip = "x86_64"
    #elseif arch(arm)
        chip = "arm"
    #elseif arch(arm64)
        chip = "arm64"
    #elseif arch(i386)
        chip = "i386"
    #endif
    components.append("(\(chip))")
    
    return components.joined(separator: " ")
}()

@objc(MBSnapshotOptionsProtocol)
public protocol SnapshotOptionsProtocol: NSObjectProtocol {
    var path: String { get }
    var params: [URLQueryItem] { get }
}

/**
 A `Snapshot` instance represents a static snapshot of a map with optional overlays. With a snapshot instance, you can synchronously or asynchronously generate an image based on the options you provide via an HTTP request, or you can get the URL used to make this request. The image is obtained on demand from the [Mapbox Static API](https://www.mapbox.com/api-documentation/#static) or the [classic Mapbox Static API](https://www.mapbox.com/api-documentation/?language=Swift#static-classic), depending on whether you use a `SnapshotOptions` object or a `ClassicSnapshotOptions` object.
 
 The snapshot image can be used in an image view (`UIImage` on iOS and tvOS, `NSImage` on macOS, `WKImage` on watchOS). The image does not respond to user gestures. To add interactivity, use the [Mapbox iOS SDK](https://www.mapbox.com/ios-sdk/) or [Mapbox macOS SDK](https://github.com/mapbox/mapbox-gl-native/tree/master/platform/macos/), which can optionally display raster tiles.
 */
@objc(MBSnapshot)
open class Snapshot: NSObject {
    #if os(OSX)
    public typealias Image = NSImage
    #else
    public typealias Image = UIImage
    #endif
    
    /**
     A closure (block) that processes the results of a snapshot request.
     
     - parameter image: The image data that was generated, or `nil` if an error occurred.
     - parameter error: The error that occurred, or `nil` if the snapshot was generated successfully.
     */
    public typealias CompletionHandler = (_ image: Image?, _ error: NSError?) -> Void
    
    /// Options that determine the contents and format of the output image.
    open let options: SnapshotOptionsProtocol
    
    /// The API endpoint to request the image from.
    internal var apiEndpoint: URL
    
    /// The Mapbox access token to associate the request with.
    internal let accessToken: String
    
    /**
     Initializes a newly created snapshot instance with the given options and an optional access token and host.
     
     - parameter options: Options that determine the contents and format of the output image.
     - parameter accessToken: A Mapbox [access token](https://www.mapbox.com/help/define-access-token/). If an access token is not specified when initializing the snapshot object, it should be specified in the `MGLMapboxAccessToken` key in the main application bundle’s Info.plist.
     - parameter host: An optional hostname to the server API. The official Mapbox API endpoint is used by default.
     */
    public init(options: SnapshotOptionsProtocol, accessToken: String?, host: String?) {
        let accessToken = accessToken ?? defaultAccessToken
        assert(accessToken != nil && !accessToken!.isEmpty, "A Mapbox access token is required. Go to <https://www.mapbox.com/studio/account/tokens/>. In Info.plist, set the MGLMapboxAccessToken key to your access token, or use the Snapshot(options:accessToken:host:) initializer.")
        
        self.options = options
        self.accessToken = accessToken!
        
        var baseURLComponents = URLComponents()
        baseURLComponents.scheme = "https"
        baseURLComponents.host = host ?? "api.mapbox.com"
        apiEndpoint = baseURLComponents.url!
    }
    
    /**
     Initializes a newly created snapshot instance with the given options and an optional access token.
     
     The snapshot instance sends requests to the official Mapbox API endpoint.
     
     - parameter options: Options that determine the contents and format of the output image.
     - parameter accessToken: A Mapbox [access token](https://www.mapbox.com/help/define-access-token/). If an access token is not specified when initializing the snapshot object, it should be specified in the `MGLMapboxAccessToken` key in the main application bundle’s Info.plist.
     */
    public convenience init(options: SnapshotOptionsProtocol, accessToken: String?) {
        self.init(options: options, accessToken: accessToken, host: nil)
    }
    
    /**
     Initializes a newly created snapshot instance with the given options and the default access token.
     
     The snapshot instance sends requests to the official Mapbox API endpoint.
     
     - parameter options: Options that determine the contents and format of the output image.
     */
    public convenience init(options: SnapshotOptionsProtocol) {
        self.init(options: options, accessToken: nil)
    }
    
    /**
     The HTTP URL used to fetch the snapshot image from the API.
     */
    open var url: URL {
        var components = URLComponents()
        components.queryItems = params
        return URL(string: "\(options.path)?\(components.percentEncodedQuery!)", relativeTo: apiEndpoint)!
    }
    
    /**
     The query component of the HTTP request URL corresponding to the options in this instance.
     
     - returns: The query URL component as an array of name/value pairs.
     */
    fileprivate var params: [URLQueryItem] {
        return options.params + [
            URLQueryItem(name: "access_token", value: accessToken),
        ]
    }
    
    /**
     Returns an image based on the options in the `options` property.
     
     - attention: This property’s getter retrieves the image synchronously over a network connection, blocking the thread on which it is called. If a connection error or server error occurs, the getter returns `nil`. Consider using the asynchronous `image(completionHandler:)` method instead to avoid blocking the calling thread and to get more details about any error that may occur.
     */
    open var image: Image? {
        if let data = try? Data(contentsOf: url) {
            return Image(data: data)
        } else {
            return nil
        }
    }
    
    /**
     Submits the request to create a snapshot image and delivers the results to the given closure.
     
     This method retrieves the image asynchronously over a network connection. If a connection error or server error occurs, details about the error are passed into the given completion handler in lieu of an image.
     
     On macOS, you may need the same snapshot image at both Retina and non-Retina resolutions to accommodate different displays being connected to the computer. To obtain images at both resolutions, create two different `Snapshot` instances, each with a different `scale` option.
     
     - parameter completionHandler: The closure (block) to call with the resulting image. This closure is executed on the application’s main thread.
     - returns: The data task used to perform the HTTP request. If, while waiting for the completion handler to execute, you no longer want the resulting image, cancel this task.
     */
    open func image(completionHandler handler: @escaping CompletionHandler) -> URLSessionDataTask {
        var request = URLRequest(url: url)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            var json: JSONDictionary = [:]
            var image: Image?
            if let data = data {
                if response?.mimeType == "application/json" {
                    do {
                        json = try JSONSerialization.jsonObject(with: data, options: []) as? JSONDictionary ?? json
                    } catch {
                        assert(false, "Invalid data")
                    }
                } else {
                    image = Image(data: data)
                }
            }
            
            let apiMessage = json["message"] as? String
            guard image != nil && error == nil && apiMessage == nil else {
                let apiError = Snapshot.descriptiveError(json, response: response, underlyingError: error as NSError?)
                DispatchQueue.main.async {
                    handler(nil, apiError)
                }
                return
            }
            
            DispatchQueue.main.async {
                handler(image, nil)
            }
        }
        task.resume()
        return task
    }
    
    /**
     Returns an error that supplements the given underlying error with additional information from the an HTTP response’s body or headers.
     */
    static func descriptiveError(_ json: JSONDictionary, response: URLResponse?, underlyingError error: NSError?) -> NSError {
        var userInfo = error?.userInfo ?? [:]
        if let response = response as? HTTPURLResponse {
            var failureReason: String? = nil
            var recoverySuggestion: String? = nil
            switch response.statusCode {
            case 429:
                if let timeInterval = response.rateLimitInterval, let maximumCountOfRequests = response.rateLimit {
                    let intervalFormatter = DateComponentsFormatter()
                    intervalFormatter.unitsStyle = .full
                    let formattedInterval = intervalFormatter.string(from: timeInterval) ?? "\(timeInterval) seconds"
                    let formattedCount = NumberFormatter.localizedString(from: maximumCountOfRequests as NSNumber, number: .decimal)
                    failureReason = "More than \(formattedCount) requests have been made with this access token within a period of \(formattedInterval)."
                }
                if let rolloverTime = response.rateLimitResetTime {
                    let formattedDate = DateFormatter.localizedString(from: rolloverTime, dateStyle: .long, timeStyle: .full)
                    recoverySuggestion = "Wait until \(formattedDate) before retrying."
                }
            default:
                failureReason = json["message"] as? String
            }
            userInfo[NSLocalizedFailureReasonErrorKey] = failureReason ?? userInfo[NSLocalizedFailureReasonErrorKey] ?? HTTPURLResponse.localizedString(forStatusCode: error?.code ?? -1)
            userInfo[NSLocalizedRecoverySuggestionErrorKey] = recoverySuggestion ?? userInfo[NSLocalizedRecoverySuggestionErrorKey]
        }
        if let error = error {
            userInfo[NSUnderlyingErrorKey] = error
        }
        return NSError(domain: error?.domain ?? MBStaticErrorDomain, code: error?.code ?? -1, userInfo: userInfo)
    }
}

extension HTTPURLResponse {
    var rateLimit: UInt? {
        guard let limit = allHeaderFields["X-Rate-Limit-Limit"] as? String else {
            return nil
        }
        return UInt(limit)
    }
    
    var rateLimitInterval: TimeInterval? {
        guard let interval = allHeaderFields["X-Rate-Limit-Interval"] as? String else {
            return nil
        }
        return TimeInterval(interval)
    }
    
    var rateLimitResetTime: Date? {
        guard let resetTime = allHeaderFields["X-Rate-Limit-Reset"] as? String else {
            return nil
        }
        guard let resetTimeNumber = Double(resetTime) else {
            return nil
        }
        return Date(timeIntervalSince1970: resetTimeNumber)
    }
}
