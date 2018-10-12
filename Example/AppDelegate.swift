import UIKit

#if swift(>=4.2)
typealias LaunchOptionsKey = UIApplication.LaunchOptionsKey
#else
typealias LaunchOptionsKey = UIApplicationLaunchOptionsKey
#endif

@UIApplicationMain

class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [LaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        window!.rootViewController = ViewController()
        window!.makeKeyAndVisible()
        return true
    }

}
