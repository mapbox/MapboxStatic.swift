import UIKit
import CoreLocation
import MapboxStatic

class ViewController: UIViewController {
    // You can also specify the access token with the `MGLMapboxAccessToken` key in Info.plist.
    let accessToken = "pk.eyJ1IjoianVzdGluIiwiYSI6IlpDbUJLSUEifQ.4mG8vhelFMju6HpIY-Hi5A"
    var imageView: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()

        imageView = UIImageView(frame: view.bounds)
        imageView.backgroundColor = UIColor.black()
        view.addSubview(imageView)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let options = SnapshotOptions(
            mapIdentifiers: ["justin.tm2-basemap"],
            centerCoordinate: CLLocationCoordinate2D(latitude: 45.522, longitude: -122.69),
            zoomLevel: 15,
            size: imageView.bounds.size)
        
        let url = URL(string: "https://www.mapbox.com/help/img/screenshots/rocket.png")
        let customMarker = CustomMarker(
            coordinate: CLLocationCoordinate2D(latitude: 45.522, longitude: -122.69),
            url: url!)
        
        let geojsonOverlay: GeoJSON
        let geojsonURL = NSURL(string: "http://git.io/vCv9U") as! URL
        let gjs = try! NSString(contentsOf: geojsonURL, usedEncoding: nil)
        geojsonOverlay = GeoJSON(objectString: gjs as String)
        
        options.overlays = [customMarker, geojsonOverlay]
        
        _ = Snapshot(options: options, accessToken: accessToken).image { [weak self] (image, error) in
            guard error == nil else {
                print(error)
                return
            }
            
            self?.imageView.image = image
        }

    }

}
