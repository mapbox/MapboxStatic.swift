#import "ViewController.h"

@import CoreLocation;
@import MapboxStatic;

// You can also specify the access token with the `MGLMapboxAccessToken` key in Info.plist.
static NSString * const AccessToken = @"pk.eyJ1IjoibWFwYm94IiwiYSI6ImNqMHFiNXN4ZDAxazMyd253cmt3a2hmN2cifQ.q0ntnAWEdwckfZnT0IEy5A";

@interface ViewController ()

@property (nonatomic, strong) UIImageView *imageView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.imageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
    self.imageView.backgroundColor = [UIColor blackColor];
    [self.view addSubview:self.imageView];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    NSURL *styleURL = [NSURL URLWithString:@"mapbox://styles/mapbox/streets-v9"];
    MBSnapshotCamera *camera = [MBSnapshotCamera cameraLookingAtCenterCoordinate:CLLocationCoordinate2DMake(45, -122)
                                                                       zoomLevel:6];
    MBSnapshotOptions *options = [[MBSnapshotOptions alloc] initWithStyleURL:styleURL
                                                                      camera:camera
                                                                        size:self.imageView.bounds.size];
    CLLocationCoordinate2D coords[] = {
        CLLocationCoordinate2DMake(45, -122),
        CLLocationCoordinate2DMake(45, -124),
    };
    MBPath *path = [[MBPath alloc] initWithCoordinates:coords count:sizeof(coords) / sizeof(coords[0])];
    options.overlays = @[path];
    MBSnapshot *snapshot = [[MBSnapshot alloc] initWithOptions:options accessToken:AccessToken];
    __weak typeof(self) weakSelf = self;
    [snapshot imageWithCompletionHandler:^(UIImage * _Nullable image, NSError * _Nullable error) {
        typeof(weakSelf) strongSelf = weakSelf;
        strongSelf.imageView.image = image;
    }];
}

@end
