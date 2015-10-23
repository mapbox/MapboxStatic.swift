import UIKit
import CoreLocation

class ViewController: UIViewController {

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

        let map = MapboxStaticMap(
            mapID: "justin.tm2-basemap",
            center: CLLocationCoordinate2D(latitude: 45, longitude: -122),
            zoom: 6,
            size: imageView.bounds.size,
            accessToken: accessToken,
            retina: (UIScreen.mainScreen().scale > 1))

        map.imageWithCompletionHandler { [unowned self] image in
            self.imageView.image = image
        }

    }

}
