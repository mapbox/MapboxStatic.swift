# MapboxStatic

[![Build Status](https://www.bitrise.io/app/faa9d29af3e2ce7a.svg?token=_oJK999amHl5HlK3a82PZA&branch=master)](https://www.bitrise.io/app/faa9d29af3e2ce7a)

MapboxGeocoder.swift makes it easy to connect your iOS, tvOS, or watchOS application to the [classic Mapbox Static API](https://www.mapbox.com/api-documentation/#static-classic). Quickly generate a static map image with overlays, asynchronous imagery fetching, and first-class Swift data types.

Static maps are flattened PNG or JPG images, ideal for use in table views, image views, and anyplace else you'd like a quick, custom map without the overhead of an interactive view. They are created in one HTTP request, so overlays are all added *server-side*. 

## Installation 

Embed `MapboxStatic.framework` into your application target, then `import MapboxStatic` or `@import MapboxStatic;`.

## Usage

You will need a [map ID](https://www.mapbox.com/foundations/glossary/#mapid) from a [custom map style](https://www.mapbox.com/foundations/customizing-the-map) on your Mapbox account. You will also need an [access token](https://www.mapbox.com/developers/api/#access-tokens) in order to use the API. 

### Basics

The main map class is `MapboxStaticMap`. To create a basic map, specify the center, [zoom level](https://www.mapbox.com/guides/how-web-maps-work/#tiles-and-zoom-levels), and pixel size: 

```swift
import MapboxStatic

let map = MapboxStaticMap(
    mapID: "<#your map ID#>",
    center: CLLocationCoordinate2D(latitude: 45.52, longitude: -122.681944),
    zoom: 13,
    size: CGSize(width: 200, height: 200),
    accessToken: "<#your access token#>"
)
```

Then, to retrieve an image, you can do it either synchronously (blocking the calling thread): 

```swift
self.imageView.image = map.image
```

![](./screenshots/map.png)

Or you can pass a completion handler to update the UI thread after the image is retrieved: 

```swift
map.imageWithCompletionHandler { image in
    imageView.image = image
}
```

If you're using your own HTTP library or routines, you can also retrieve a map object's `requestURL` property. 

```swift
let requestURLToFetch = map.requestURL
```

### Overlays

Overlays are where things get interesting! You can add [Maki markers](https://www.mapbox.com/maki/), custom marker imagery, GeoJSON geometries, and even paths made of bare coordinates. 

You pass overlays as the `overlays: [Overlay]` parameter during map creation. Here are some versions of our map with various overlays added. 

#### Marker

```swift
let markerOverlay = MapboxStaticMap.Marker(
    coordinate: CLLocationCoordinate2D(latitude: 45.52, longitude: -122.681944),
    size: .Medium,
    label: "cafe",
    color: UIColor.brownColor()
)
```

![](./screenshots/marker.png)

#### Custom Marker

```swift
let customMarker = MapboxStaticMap.CustomMarker(
    coordinate: CLLocationCoordinate2D(latitude: 45.522, longitude: -122.69),
    URLString: "https://mapbox.com/guides/img/rocket.png"
)
```

![](./screenshots/custom.png)

#### GeoJSON

```swift
var geojsonOverlay: MapboxStaticMap.GeoJSON!

do {
    let geojsonURL = NSURL(string: "http://git.io/vCv9U")
    let geojsonString = try NSString(contentsOfURL: geojsonURL!, encoding: NSUTF8StringEncoding)
    geojsonOverlay = MapboxStaticMap.GeoJSON(string: geojsonString as String)
}
```

![](./screenshots/geojson.png)

#### Path

```swift
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
    strokeWidth: 2,
    strokeColor: UIColor.blackColor(),
    fillColor: UIColor.redColor(),
    fillOpacity: 0.25
)
```

![](./screenshots/path.png)

### Other options

#### Auto-fitting features

If you're adding overlays to your map, you can use the `autoFitFeatures` flag to automatically calculate the center and zoom that best shows them off. 

```swift
let map = MapboxStaticMap(
    mapID: <your map ID>,
    size: CGSize(width: 500, height: 300),
    accessToken: <your API token>,
    overlays: [path, geojsonOverlay, markerOverlay, customMarker],
    autoFitFeatures: true
)
```

![](screenshots/autofit.png)

#### File format & quality

When creating a map, you can also specify PNG or JPEG image format as well as various [bandwidth-saving image qualities](https://www.mapbox.com/api-documentation/#retrieve-a-static-map-image).

#### Attribution

Be sure to [attribute your map](https://www.mapbox.com/api-documentation/#static-classic) properly in your app. You can also [find out more](https://www.mapbox.com/about/maps/) about where Mapbox's map data comes from. 

### Tests

To run the included unit tests, you need to use [CocoaPods](http://cocoapods.org) to install the dependencies. 

1. `pod install`
1. `open MapboxStatic.xcworkspace`
1. `Command+U` or `xcodebuild test`

### More info

For more info about the Mapbox static maps API, check out the [web service documentation](https://www.mapbox.com/api-documentation/#static-classic). 
