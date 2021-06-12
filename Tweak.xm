#import <UIKit/UIKit.h>
#import "spawn.h"
#define WIDTH [UIScreen mainScreen].bounds.size.width
#define HEIGHT [UIScreen mainScreen].bounds.size.height

@import MapKit;
UIViewController *infoPopoverController;

@interface PXNavigationTitleView: UIView <MKMapViewDelegate>
@property (strong, nonatomic) UIButton *info;
@end

@interface PUOneUpViewController: UIViewController
- (id)pu_debugCurrentAsset;
@end

@interface PUNavigationController: UINavigationController
- (UIViewController*)_currentToolbarViewController;
@end

@interface PHAsset: NSObject
@property (nonatomic, readonly) NSString *originalFilename; 
@property (nonatomic, readonly) NSData *locationData;  
@property (nonatomic, readonly) NSDate *creationDate; 
@property (nonatomic, readonly) CLLocation *location; 
- (CGSize)imageSize;
- (id)mainFileURL;
- (id)originalMetadataProperties;
- (id)originalImageProperties;
@end

@interface TelescopeInfoViewController : UIViewController <UIPopoverPresentationControllerDelegate>
@end

@implementation TelescopeInfoViewController
- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller traitCollection:(UITraitCollection *)traitCollection {
    return UIModalPresentationNone;
}
@end

@interface UILabel (Telescope)
- (void)setMarqueeRunning:(BOOL)arg1;
- (void)setMarqueeEnabled:(BOOL)arg1;
- (BOOL)marqueeEnabled;
- (BOOL)marqueeRunning;
@end

@interface UIView (Telescope)
- (id)_viewControllerForAncestor;
@end

%group Tweak
%hook PXNavigationTitleView
%property (strong, nonatomic) UIButton *info;
- (void)layoutSubviews { // Not ideal, but no other usual method seemed to work
    %orig;
    if (!self.info) {
        self.info = [[UIButton alloc] initWithFrame:self.bounds];
        [self.info setImage:[UIImage systemImageNamed:@"info.circle"] forState:UIControlStateNormal];
        [self.info.imageView setContentMode:UIViewContentModeScaleAspectFit];
        [self.info addTarget:self action:@selector(loadInfo) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.info];
    }
}
- (id)subtitle {
    return nil;
}
- (id)title {
    return nil;
}
- (void)viewDidDisappear{
    %orig;
    [(UIViewController *)[self _viewControllerForAncestor] dismissViewControllerAnimated:infoPopoverController completion:nil];
}
%new
- (void)loadInfo {
    PHAsset *asset = [(PUOneUpViewController *)[(PUNavigationController *)[self performSelector:@selector(_viewControllerForAncestor)] _currentToolbarViewController] pu_debugCurrentAsset];
    if (asset) {
        TelescopeInfoViewController *controller = [[TelescopeInfoViewController alloc] init];

        NSDictionary *properties = [asset originalImageProperties];
    
        infoPopoverController = [[UIViewController alloc] init];
        infoPopoverController.modalPresentationStyle = UIModalPresentationPopover;
        infoPopoverController.preferredContentSize = CGSizeMake(340, 400);

        UILabel *infoLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 10, 150, 60)];
        infoLabel.font = [UIFont boldSystemFontOfSize:30];
        infoLabel.text = @"Info";
        [infoPopoverController.view addSubview:infoLabel];

        UIButton *closeButton = [[UIButton alloc] initWithFrame:CGRectMake(275, 0, 80, 80)];
        [closeButton setImage:[UIImage systemImageNamed:@"xmark.circle.fill"] forState:UIControlStateNormal];
        [closeButton setTintColor:[UIColor secondaryLabelColor]];
        [closeButton addTarget:self action:@selector(closeView) forControlEvents:UIControlEventTouchUpInside];
        [infoPopoverController.view addSubview:closeButton];

        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
		[formatter setDateFormat:@"EEEE • MMM dd, YYYY • h:mm a"];
        UILabel *dateLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 60, 310, 40)];
        dateLabel.font = [UIFont systemFontOfSize:18];
        dateLabel.text = [formatter stringFromDate:asset.creationDate];
        [infoPopoverController.view addSubview:dateLabel];

        CGSize imageSize = [asset imageSize];
        NSDictionary *attributes;
        NSString *assetPath = [[[asset mainFileURL] absoluteString] stringByReplacingOccurrencesOfString:@"file://" withString:@""];
        float byteRepresentation;
        BOOL isDirectory;
        if ([[NSFileManager defaultManager] fileExistsAtPath:assetPath isDirectory:&isDirectory]) {
            attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:assetPath error:nil];
            byteRepresentation = (float)[[attributes objectForKey:NSFileSize] longLongValue] / (1024 * 1024);
        } else {
            byteRepresentation = 0;
        }

        UILabel *fileName = [[UILabel alloc] initWithFrame:CGRectMake(15, 90, 310, 40)];
        fileName.font = [UIFont systemFontOfSize:18];
        fileName.textColor = [UIColor secondaryLabelColor];
        fileName.text = [NSString stringWithFormat:@"%@ • %ix%i • %.02f MB", [[[[asset mainFileURL] absoluteString] stringByReplacingOccurrencesOfString:@"file://" withString:@""] lastPathComponent], (int)imageSize.width, (int)imageSize.height, byteRepresentation];
        [fileName setMarqueeEnabled:YES];
        [fileName setMarqueeRunning:YES];
        [infoPopoverController.view addSubview:fileName];

        UILabel *modelLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 120, 310, 40)];
        modelLabel.font = [UIFont systemFontOfSize:18];
        NSString *make = [[properties objectForKey:@"{TIFF}"] objectForKey:@"Make"];
        NSString *model = [[properties objectForKey:@"{TIFF}"] objectForKey:@"Model"];
        if (make != NULL && model != NULL) {
            modelLabel.text = [NSString stringWithFormat:@"%@ %@", make, model];
        } else {
            modelLabel.text = @"Camera model unknown";
        }
        [infoPopoverController.view addSubview:modelLabel];

        UILabel *lensInfo = [[UILabel alloc] initWithFrame:CGRectMake(15, 150, 310, 40)];
        lensInfo.textColor = [UIColor secondaryLabelColor];
        [lensInfo setMarqueeEnabled:YES];
        [lensInfo setMarqueeRunning:YES];
        NSString *lensInfoText = [[properties objectForKey:@"{Exif}"] objectForKey:@"LensModel"];
        if (lensInfoText != NULL) {
            lensInfo.text = lensInfoText;
        } else {
            lensInfo.text = @"Lens info unknown";   
        }
        [infoPopoverController.view addSubview:lensInfo];

        MKMapView *mapView = [[MKMapView alloc] initWithFrame:CGRectMake(15, 190, 310, 190)];
        mapView.showsUserLocation = YES;
        mapView.mapType = MKMapTypeStandard;
        mapView.delegate = self;
        mapView.layer.cornerRadius = 10;
        [infoPopoverController.view addSubview:mapView];

        UIButton *addressButton = [[UIButton alloc] initWithFrame:CGRectMake(15, 375, 310, 40)];
        [addressButton setTitleColor:[UIColor linkColor] forState:UIControlStateNormal];
        [addressButton addTarget:self action:@selector(openLink) forControlEvents:UIControlEventTouchUpInside];
		[infoPopoverController.view addSubview:addressButton];

        CLGeocoder *geocoder = [[CLGeocoder alloc]init];
        [geocoder reverseGeocodeLocation:asset.location completionHandler:^(NSArray *placemarks, NSError *error) {
            CLPlacemark *placemark = [placemarks lastObject];
            NSString *address = [NSString stringWithFormat:@"%@, %@, %@, %@", placemark.thoroughfare, placemark.locality, placemark.administrativeArea, placemark.postalCode];
            if (placemark.thoroughfare != NULL) {
                [addressButton setTitle:address forState:UIControlStateNormal];
            } else {
                [addressButton setTitle:@"" forState:UIControlStateNormal];
            }
        }];

        UIPopoverPresentationController *popover = infoPopoverController.popoverPresentationController;
        
        popover.delegate = controller;
        popover.permittedArrowDirections = UIPopoverArrowDirectionUp;
        popover.sourceView = self;
        popover.sourceRect = self.bounds;

        [(UIViewController *)[self _viewControllerForAncestor] presentViewController:infoPopoverController animated:YES completion:nil];
        // [[[[UIApplication sharedApplication] keyWindow] rootViewController] presentViewController:infoPopoverController animated:YES completion:nil];
    }
}
%new
- (void)mapView:(MKMapView *)aMapView didUpdateUserLocation:(MKUserLocation *)aUserLocation {

    MKCoordinateRegion region;
    region.span.latitudeDelta = 0.001;
    region.span.longitudeDelta = 0.001;

    PHAsset *asset = [(PUOneUpViewController *)[(PUNavigationController *)[self performSelector:@selector(_viewControllerForAncestor)] _currentToolbarViewController] pu_debugCurrentAsset];
    if (asset) {
        region.center.latitude = asset.location.coordinate.latitude;
        region.center.longitude = asset.location.coordinate.longitude;
    }

    [aMapView setRegion:region animated:YES];

    MKPlacemark *marker = [[MKPlacemark alloc] initWithCoordinate:asset.location.coordinate addressDictionary:nil];
    [aMapView addAnnotation:marker];
}
%new
- (void)openLink {
    PHAsset *asset = [(PUOneUpViewController *)[(PUNavigationController *)[self performSelector:@selector(_viewControllerForAncestor)] _currentToolbarViewController] pu_debugCurrentAsset];
    if (asset) {
        NSString *address = [NSString stringWithFormat:@"http://maps.apple.com/?sll=%f,%f", asset.location.coordinate.latitude, asset.location.coordinate.longitude];
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:address] options:@{} completionHandler:nil];
    }
}
%new
- (void)closeView {
    [(UIViewController *)[self _viewControllerForAncestor] dismissViewControllerAnimated:infoPopoverController completion:nil];
}
%end
%end

%ctor {
    %init(Tweak);
}

