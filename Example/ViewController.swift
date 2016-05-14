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
        imageView.backgroundColor = UIColor.blackColor()
        view.addSubview(imageView)
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        let options = SnapshotOptions(
            mapIdentifiers: ["justin.tm2-basemap"],
            centerCoordinate: CLLocationCoordinate2D(latitude: 45, longitude: -122),
            zoomLevel: 6,
            size: imageView.bounds.size)
        Snapshot(options: options, accessToken: accessToken).image { [weak self] (image, error) in
            self?.imageView.image = image
        }

    }

}
