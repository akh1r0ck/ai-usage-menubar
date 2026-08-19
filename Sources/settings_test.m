#import <Cocoa/Cocoa.h>
#import "UsageUI.h"

static void Require(BOOL condition, NSString *message) {
    if (!condition) { NSLog(@"FAILED: %@", message); exit(1); }
}

int main(void) {
    @autoreleasepool {
        UsageSettingsStore *store = UsageSettingsStore.sharedStore;
        [store resetToDefaults];
        Require(store.cautionThreshold == 60, @"default caution threshold");
        Require(store.warningThreshold == 85, @"default warning threshold");
        Require(store.autoRefreshEnabled && store.refreshWhenOpened, @"default refresh behavior");
        Require([UsageMenuValue(61) isEqualToString:@"61%"], @"default menu value");

        store.warningThreshold = 95;
        store.cautionThreshold = 90;
        Require(store.cautionThreshold == 90 && store.warningThreshold == 95, @"custom thresholds");
        store.displayRemaining = YES;
        store.showPercentSign = NO;
        store.theme = @"dark";
        store.use24HourTime = NO;
        store.useDigitGrouping = NO;
        Require([UsageMenuValue(61) isEqualToString:@"39"], @"remaining menu value");
        Require(UsageContrastRatio(UsageColorWithMinimumContrast(NSColor.systemOrangeColor,NSColor.whiteColor),NSColor.whiteColor)>=4.5,@"light contrast");
        Require(UsageContrastRatio(UsageColorWithMinimumContrast(NSColor.systemBlueColor,NSColor.blackColor),NSColor.blackColor)>=4.5,@"dark contrast");

        NSURL *url = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:@"ai-usage-settings-test.json"]];
        NSError *error = nil;
        Require([store exportSettingsToURL:url error:&error], error.localizedDescription ?: @"export");
        [store resetToDefaults];
        Require([store importSettingsFromURL:url error:&error], error.localizedDescription ?: @"import");
        Require(store.cautionThreshold == 90 && store.displayRemaining && [store.theme isEqualToString:@"dark"] && !store.use24HourTime && !store.useDigitGrouping, @"imported values");
        [[NSFileManager defaultManager] removeItemAtURL:url error:nil];
        [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:NSProcessInfo.processInfo.environment[@"AI_USAGE_DEFAULTS_SUITE"]];
    }
    return 0;
}
