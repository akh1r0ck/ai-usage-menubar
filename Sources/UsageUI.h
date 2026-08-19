#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, UsageService) {
    UsageServiceCodex,
    UsageServiceClaude,
};

FOUNDATION_EXPORT NSNotificationName const UsageSettingsDidChangeNotification;

@interface UsageSettingsStore : NSObject
+ (instancetype)sharedStore;
@property (nonatomic) NSString *fontFamily;
@property (nonatomic) CGFloat menuBarFontSize;
@property (nonatomic) CGFloat detailFontSize;
@property (nonatomic) NSFontWeight fontWeight;
@property (nonatomic) BOOL monospacedDigits;
@property (nonatomic) double cautionThreshold;
@property (nonatomic) double warningThreshold;
@property (nonatomic) NSTimeInterval refreshInterval;
@property (nonatomic) BOOL autoRefreshEnabled;
@property (nonatomic) BOOL refreshWhenOpened;
@property (nonatomic) BOOL showServiceName;
@property (nonatomic) BOOL displayRemaining;
@property (nonatomic) BOOL showPercentSign;
@property (nonatomic) BOOL showResetTime;
@property (nonatomic) BOOL showTokenUsage;
@property (nonatomic) BOOL showContextUsage;
@property (nonatomic) BOOL showModel;
@property (nonatomic) BOOL showUpdatedTime;
@property (nonatomic) BOOL cautionNotificationEnabled;
@property (nonatomic) BOOL warningNotificationEnabled;
@property (nonatomic) NSString *theme;
@property (nonatomic) BOOL use24HourTime;
@property (nonatomic) BOOL useDigitGrouping;
- (NSColor *)accentColorForService:(UsageService)service;
- (void)setAccentColor:(NSColor *)color forService:(UsageService)service;
- (NSColor *)normalColor;
- (NSColor *)cautionColor;
- (NSColor *)warningColor;
- (void)setNormalColor:(NSColor *)color;
- (void)setCautionColor:(NSColor *)color;
- (void)setWarningColor:(NSColor *)color;
- (BOOL)exportSettingsToURL:(NSURL *)url error:(NSError **)error;
- (BOOL)importSettingsFromURL:(NSURL *)url error:(NSError **)error;
- (void)resetToDefaults;
@end

FOUNDATION_EXPORT NSFont *UsageFont(CGFloat size, NSFontWeight weight);
FOUNDATION_EXPORT NSFont *UsageDetailFont(CGFloat baseSize, NSFontWeight weight);
FOUNDATION_EXPORT NSColor *UsageColor(double value);
FOUNDATION_EXPORT NSColor *UsageColorWithMinimumContrast(NSColor *color, NSColor *background);
FOUNDATION_EXPORT double UsageContrastRatio(NSColor *a, NSColor *b);
FOUNDATION_EXPORT NSAttributedString *UsageStatusTitle(UsageService service, NSString *value, NSColor *valueColor);
FOUNDATION_EXPORT NSString *UsageMenuValue(double usedPercent);
FOUNDATION_EXPORT BOOL UsageSetLaunchAtLogin(BOOL enabled, NSError **error);
FOUNDATION_EXPORT BOOL UsageLaunchAtLoginEnabled(void);
FOUNDATION_EXPORT void UsageApplyTheme(void);
FOUNDATION_EXPORT NSString *UsageFormattedDate(NSDate *date, BOOL includeSeconds);
FOUNDATION_EXPORT NSString *UsageFormattedInteger(long long value);

@interface UsageBar : NSView
@property (nonatomic) double value;
@end

@interface UsageSettingsWindowController : NSWindowController
- (instancetype)initWithService:(UsageService)service;
@end

@interface UsageNotificationController : NSObject
- (instancetype)initWithService:(UsageService)service;
- (void)evaluateUsedPercent:(double)percent resetIdentifier:(NSString *)identifier;
- (void)sendTestNotification;
@end

NS_ASSUME_NONNULL_END
