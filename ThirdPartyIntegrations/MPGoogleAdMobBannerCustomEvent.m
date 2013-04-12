//
//  MPGoogleAdMobBannerCustomEvent.m
//  MoPub
//
//  Copyright (c) 2013 MoPub. All rights reserved.
//

#import "MPGoogleAdMobBannerCustomEvent.h"
#import "MPLogging.h"
#import "MPInstanceProvider.h"

@interface MPInstanceProvider (AdMobBanners)

- (GADBannerView *)buildGADBannerViewWithFrame:(CGRect)frame;
- (GADRequest *)buildGADRequest;

@end

@implementation MPInstanceProvider (AdMobBanners)

- (GADBannerView *)buildGADBannerViewWithFrame:(CGRect)frame
{
    return [[[GADBannerView alloc] initWithFrame:frame] autorelease];
}

- (GADRequest *)buildGADRequest
{
    return [GADRequest request];
}

@end

////////////////////////////////////////////////////////////////////////////////////////////////////

@interface MPGoogleAdMobBannerCustomEvent ()

@property (nonatomic, retain) GADBannerView *adBannerView;

@end


@implementation MPGoogleAdMobBannerCustomEvent

- (id)init
{
    self = [super init];
    if (self)
    {
        self.adBannerView = [[MPInstanceProvider sharedProvider] buildGADBannerViewWithFrame:CGRectZero];
        self.adBannerView.delegate = self;
    }
    return self;
}

- (void)customEventDidUnload
{
    self.adBannerView.delegate = nil;
    [[_adBannerView retain] autorelease];
    self.adBannerView = nil;
    [super customEventDidUnload];
}

- (void)requestAdWithSize:(CGSize)size customEventInfo:(NSDictionary *)info
{
    self.adBannerView.frame = [self frameForCustomEventInfo:info];
    self.adBannerView.adUnitID = [info objectForKey:@"adUnitID"];
    self.adBannerView.rootViewController = [self.delegate viewControllerForPresentingModalView];

    GADRequest *request = [[MPInstanceProvider sharedProvider] buildGADRequest];

    CLLocation *location = self.delegate.location;
    if (location) {
        [request setLocationWithLatitude:location.coordinate.latitude
                               longitude:location.coordinate.longitude
                                accuracy:location.horizontalAccuracy];
    }

    // Here, you can specify a list of devices that will receive test ads.
    // See: http://code.google.com/mobile/ads/docs/ios/intermediate.html#testdevices
    request.testDevices = [NSArray arrayWithObjects:
                           GAD_SIMULATOR_ID,
                           // more UDIDs here,
                           nil];

    [self.adBannerView loadRequest:request];
}

- (CGRect)frameForCustomEventInfo:(NSDictionary *)info
{
    CGFloat width = [[info objectForKey:@"adWidth"] floatValue];
    CGFloat height = [[info objectForKey:@"adHeight"] floatValue];

    if (width < GAD_SIZE_320x50.width && height < GAD_SIZE_320x50.height) {
        width = GAD_SIZE_320x50.width;
        height = GAD_SIZE_320x50.height;
    }
    return CGRectMake(0, 0, width, height);
}

#pragma mark -
#pragma mark GADBannerViewDelegate methods

- (void)adViewDidReceiveAd:(GADBannerView *)bannerView
{
    [self.delegate bannerCustomEvent:self didLoadAd:self.adBannerView];
}

- (void)adView:(GADBannerView *)bannerView
didFailToReceiveAdWithError:(GADRequestError *)error
{
    [self.delegate bannerCustomEvent:self didFailToLoadAdWithError:error];
}

- (void)adViewWillPresentScreen:(GADBannerView *)bannerView
{
    [self.delegate bannerCustomEventWillBeginAction:self];
}

- (void)adViewDidDismissScreen:(GADBannerView *)bannerView
{
    [self.delegate bannerCustomEventDidFinishAction:self];
}

- (void)adViewWillLeaveApplication:(GADBannerView *)bannerView
{
    [self.delegate bannerCustomEventWillLeaveApplication:self];
}

@end