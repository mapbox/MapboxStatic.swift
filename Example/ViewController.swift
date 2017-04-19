import UIKit
import CoreLocation
import MapboxStatic

class ViewController: UIViewController {
    // You can also specify the access token with the `MGLMapboxAccessToken` key in Info.plist.
    let accessToken = "pk.eyJ1IjoibWFwYm94IiwiYSI6ImNqMHFiNXN4ZDAxazMyd253cmt3a2hmN2cifQ.q0ntnAWEdwckfZnT0IEy5A"
    var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imageView = UIImageView(frame: view.bounds)
        imageView.backgroundColor = .black
        view.addSubview(imageView)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        let coordinates = [CLLocationCoordinate2D(latitude: 45.4562, longitude: -122.8793),
                           CLLocationCoordinate2D(latitude: 45.4562, longitude: -122.4645),
                           CLLocationCoordinate2D(latitude: 45.6582, longitude: -122.4645),
                           CLLocationCoordinate2D(latitude: 45.6582, longitude: -122.8793),
                           CLLocationCoordinate2D(latitude: 45.4562, longitude: -122.8793)]
        
        let path = Path(coordinates: coordinates)
        path.fillColor = UIColor.red.withAlphaComponent(0.5)
        path.strokeColor = UIColor.green.withAlphaComponent(0.5)
        
        let camera = SnapshotCamera(lookingAtCenter: CLLocationCoordinate2D(latitude: 45, longitude: -122), zoomLevel: 6)
        let options = SnapshotOptions(
            styleURL: URL(string: "mapbox://styles/mapbox/streets-v9")!,
            camera: camera,
            size: imageView.bounds.size)
        
        options.overlays.append(path)
        
        _ = Snapshot(options: options, accessToken: accessToken).image { [weak self] (image, error) in
            if let error = error {
                print(error)
                return
            }
            
            self?.imageView.image = image
        }
    }
}
