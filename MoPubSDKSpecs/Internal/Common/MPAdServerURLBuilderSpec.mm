#import "MPAdServerURLBuilder.h"
#import "MPConstants.h"
#import "MPIdentityProvider.h"
#import "MPGlobal.h"
#import <CoreLocation/CoreLocation.h>

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

static BOOL advertisingTrackingEnabled = YES;

@implementation MPAdServerURLBuilder (Spec)

+ (BOOL)advertisingTrackingEnabled
{
    return advertisingTrackingEnabled;
}

@end


SPEC_BEGIN(MPAdServerURLBuilderSpec)

describe(@"MPAdServerURLBuilder", ^{
    __block NSURL *URL;
    __block NSString *expected;

    describe(@"base case", ^{
        it(@"should have the right things", ^{
            URL = [MPAdServerURLBuilder URLWithAdUnitID:@"guy"
                                               keywords:nil
                                          locationArray:nil
                                                testing:YES];
            expected = [NSString stringWithFormat:@"http://testing.ads.mopub.com/m/ad?v=8&udid=%@&id=guy&nv=%@",
                        [MPIdentityProvider identifier],
                        MP_SDK_VERSION];
            URL.absoluteString should contain(expected);

            URL = [MPAdServerURLBuilder URLWithAdUnitID:@"guy"
                                               keywords:nil
                                          locationArray:nil
                                                testing:NO];
            expected = [NSString stringWithFormat:@"http://ads.mopub.com/m/ad?v=8&udid=%@&id=guy&nv=%@",
                        [MPIdentityProvider identifier],
                        MP_SDK_VERSION];
            URL.absoluteString should contain(expected);
        });
    });

    it(@"should process keywords", ^{
        [UIPasteboard removePasteboardWithName:@"fb_app_attribution"];
        URL = [MPAdServerURLBuilder URLWithAdUnitID:@"guy"
                                           keywords:@"  something with whitespace,another  "
                                      locationArray:nil
                                            testing:YES];
        URL.absoluteString should contain(@"&q=something%20with%20whitespace,another");

        URL = [MPAdServerURLBuilder URLWithAdUnitID:@"guy"
                                           keywords:nil
                                      locationArray:nil
                                            testing:YES];
        URL.absoluteString should_not contain(@"&q=");

        UIPasteboard *pb = [UIPasteboard pasteboardWithName:@"fb_app_attribution" create:YES];
        pb.string = @"from zuckerberg with love";
        URL = [MPAdServerURLBuilder URLWithAdUnitID:@"guy"
                                           keywords:@"a=1"
                                      locationArray:nil
                                            testing:YES];
        URL.absoluteString should contain(@"&q=a=1,FBATTRID:from%20zuckerberg%20with%20love");
    });

    it(@"should process orientation", ^{
        [[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationPortrait];
        URL = [MPAdServerURLBuilder URLWithAdUnitID:@"guy"
                                           keywords:nil
                                      locationArray:nil
                                            testing:YES];
        URL.absoluteString should contain(@"&o=p");

        [[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationLandscapeRight];
        URL = [MPAdServerURLBuilder URLWithAdUnitID:@"guy"
                                           keywords:nil
                                      locationArray:nil
                                            testing:YES];
        URL.absoluteString should contain(@"&o=l");
    });

    it(@"should process scale factor", ^{
        URL = [MPAdServerURLBuilder URLWithAdUnitID:@"guy"
                                           keywords:nil
                                      locationArray:nil
                                            testing:YES];

        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"&sc=\\d\\.0"
                                                                               options:0
                                                                                 error:NULL];
        [regex numberOfMatchesInString:URL.absoluteString options:0 range:NSMakeRange(0, URL.absoluteString.length)] should equal(1);
    });

    it(@"should process time zone", ^{
        URL = [MPAdServerURLBuilder URLWithAdUnitID:@"guy"
                                           keywords:nil
                                      locationArray:nil
                                            testing:YES];

        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"&z=[-+]\\d{4}"
                                                                               options:0
                                                                                 error:NULL];
        [regex numberOfMatchesInString:URL.absoluteString options:0 range:NSMakeRange(0, URL.absoluteString.length)] should equal(1);
    });

    it(@"should process location", ^{
        URL = [MPAdServerURLBuilder URLWithAdUnitID:@"guy"
                                           keywords:nil
                                      locationArray:nil
                                            testing:YES];
        URL.absoluteString should_not contain(@"&ll=");

        URL = [MPAdServerURLBuilder URLWithAdUnitID:@"guy"
                                           keywords:nil
                                      locationArray:@[@10.1, @(-40.23), @100213]
                                            testing:YES];
        URL.absoluteString should_not contain(@"&ll=");


        URL = [MPAdServerURLBuilder URLWithAdUnitID:@"guy"
                                           keywords:nil
                                      locationArray:@[@10.1, @(-40.23)]
                                            testing:YES];
        URL.absoluteString should contain(@"&ll=10.1,-40.23");

        URL = [MPAdServerURLBuilder URLWithAdUnitID:@"guy"
                                           keywords:nil
                                           location:[[[CLLocation alloc] initWithLatitude:10.1 longitude:-40.23] autorelease]
                                            testing:YES];
        URL.absoluteString should contain(@"&ll=10.1,-40.23");
    });

    it(@"should have mraid", ^{
        URL = [MPAdServerURLBuilder URLWithAdUnitID:@"guy"
                                           keywords:nil
                                      locationArray:nil
                                            testing:YES];
        URL.absoluteString should contain(@"&mr=1");
    });

    it(@"should turn advertisingTrackingEnabled into DNT", ^{
        URL = [MPAdServerURLBuilder URLWithAdUnitID:@"guy"
                                           keywords:nil
                                      locationArray:nil
                                            testing:YES];
        URL.absoluteString should_not contain(@"&dnt=");

        advertisingTrackingEnabled = NO;
        URL = [MPAdServerURLBuilder URLWithAdUnitID:@"guy"
                                           keywords:nil
                                      locationArray:nil
                                            testing:YES];
        URL.absoluteString should contain(@"&dnt=1");

        advertisingTrackingEnabled = YES;
    });
});

SPEC_END
