import CoreLocation
import Cocoa
import MapboxStatic

/*:
 # MapboxStatic.swift
 
 MapboxStatic.swift makes it easy to connect your macOS Cocoa application to the [Mapbox Static Images API](https://docs.mapbox.com/api/maps/static-images/). Quickly generate a map snapshot – a static map image with overlays – by fetching it synchronously or asynchronously over the Web using first-class Swift or Objective-C data types.
 
 A snapshot is a flattened PNG or JPEG image, ideal for use in a table or image view, sharing service, printed document, or anyplace else you’d like a quick, custom map without the overhead of an interactive view. A static map is created in a single HTTP request. Overlays are added server-side.
 
 ## Usage
 
To generate a _snapshot_ from a Mapbox-hosted [style](https://www.mapbox.com/help/define-style/), you’ll need its [style URL](https://www.mapbox.com/help/define-style-url/). You can either choose a [Mapbox-designed style](https://docs.mapbox.com/api/maps/styles/#mapbox-styles) or design one yourself in [Mapbox Studio](https://www.mapbox.com/studio/styles/). You can use the same style in the Mapbox macOS SDK.
 
 You’ll also need an [access token](https://www.mapbox.com/help/define-access-token/) with the `styles:tiles` scope enabled in order to use this library. You can specify your access token inline or by setting the `MGLMapboxAccessToken` key in your application’s Info.plist file.
 */

let styleURL = URL(string: "mapbox://styles/mapbox/streets-v9")!
let accessToken = "pk.eyJ1IjoibWFwYm94IiwiYSI6ImNqMHFiNXN4ZDAxazMyd253cmt3a2hmN2cifQ.q0ntnAWEdwckfZnT0IEy5A"

/*:
 ## Basics
 
 The main static map class is `Snapshot`. To create a basic snapshot, create a `SnapshotOptions` object, specifying snapshot camera (viewpoint) and point size:
 */

var camera = SnapshotCamera(
    lookingAtCenter: CLLocationCoordinate2D(latitude: 45.52, longitude: -122.681944),
    zoomLevel: 13)
var options = SnapshotOptions(
    styleURL: styleURL,
    camera: camera,
    size: CGSize(width: 300, height: 200))
var snapshot = Snapshot(
    options: options,
    accessToken: accessToken)

/*:
 Then, you can either retrieve an image synchronously (blocking the calling thread):
 */
snapshot.image

/*:
 Or you can pass a completion handler to update the UI thread after the image is retrieved:
 */
let imageView = NSImageView(frame: CGRect(x: 0, y: 0, width: 300, height: 200))
snapshot.image { (image, error) in
    imageView.image = image
}

/*:
 If you’re using your own HTTP library or routines, you can also retrieve a snapshot’s `url` property.
 */
snapshot.url

/*:
 ## Overlays
 
 Overlays are where things get interesting! You can add [Maki markers](https://www.mapbox.com/maki-icons/), custom marker imagery, GeoJSON geometries, and even paths made of bare coordinates.
 
 You add overlays to the `overlays` field in the `SnapshotOptions` object. Here are some versions of our snapshot with various overlays added.
 
 ### Marker
 */
let markerOverlay = Marker(
    coordinate: CLLocationCoordinate2D(latitude: 45.52, longitude: -122.681944),
    size: .medium,
    iconName: "cafe")
markerOverlay.color = .brown
options.overlays = [markerOverlay]
snapshot = Snapshot(
    options: options,
    accessToken: accessToken)
snapshot.image

/*:
 ### Custom marker
 */
let customMarker = CustomMarker(
    coordinate: CLLocationCoordinate2D(latitude: 45.522, longitude: -122.69),
    url: URL(string: "https://docs.mapbox.com/help/img/screenshots/airport-15.png")!)
options.overlays = [customMarker]
snapshot = Snapshot(
    options: options,
    accessToken: accessToken)
snapshot.image

/*:
 ### GeoJSON
 */
let geoJSONOverlay: GeoJSON
do {
    let geoJSONURL = URL(string: "http://git.io/vCv9U")!
    let geoJSONString = try String(contentsOf: geoJSONURL, encoding: .utf8)
    geoJSONOverlay = GeoJSON(objectString: geoJSONString)
}
options.overlays = [geoJSONOverlay]
snapshot = Snapshot(
    options: options,
    accessToken: accessToken)
snapshot.image

/*:
 ### Path
 */
let path = Path(
    coordinates: [
        CLLocationCoordinate2D(
            latitude: 45.52475063103141,
            longitude: -122.68209457397461),
        CLLocationCoordinate2D(
            latitude: 45.52451009822193,
            longitude: -122.67488479614258),
        CLLocationCoordinate2D(
            latitude: 45.51681250530043,
            longitude: -122.67608642578126),
        CLLocationCoordinate2D(
            latitude: 45.51693278828882,
            longitude: -122.68999099731445),
        CLLocationCoordinate2D(
            latitude: 45.520300607576864,
            longitude: -122.68964767456055),
        CLLocationCoordinate2D(
            latitude: 45.52475063103141,
            longitude: -122.68209457397461),
    ])
path.strokeWidth = 2
path.strokeColor = .black
path.fillColor = NSColor.red.withAlphaComponent(0.25)
options.overlays = [path]
snapshot = Snapshot(
    options: options,
    accessToken: accessToken)
snapshot.image

/*:
 ## Other options
 
 ### Rotation and tilt
 
 To rotate and tilt a snapshot, set its camera’s heading and pitch:
 */
camera.heading = 45
camera.pitch = 60
options = SnapshotOptions(
    styleURL: styleURL,
    camera: camera,
    size: CGSize(width: 300, height: 200))
snapshot = Snapshot(
    options: options,
    accessToken: accessToken)
snapshot.image

/*:
 ### Auto-fitting features
 
 If you’re adding overlays to a snapshot, leave out the center coordinate and zoom level to automatically calculate the center and zoom level that best shows them off.
 */
options = SnapshotOptions(
    styleURL: styleURL,
    size: CGSize(width: 500, height: 300))
options.overlays = [path, geoJSONOverlay, markerOverlay, customMarker]
snapshot = Snapshot(
    options: options,
    accessToken: accessToken)
snapshot.image

/*:
 ### Attribution
 
 Be sure to [attribute your map](https://www.mapbox.com/help/attribution/) properly in your application. You can also [find out more](https://www.mapbox.com/about/maps/) about where Mapbox’s map data comes from.
 */
