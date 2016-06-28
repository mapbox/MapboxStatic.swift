import UIKit

@UIApplicationMain

class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject : AnyObject]? = [:]) -> Bool {
        window = UIWindow(frame: UIScreen.main().bounds)
        window!.rootViewController = ViewController()
        window!.makeKeyAndVisible()
        return true
    }

}
