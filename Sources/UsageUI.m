#import "UsageUI.h"
#import <ServiceManagement/ServiceManagement.h>
#import <UserNotifications/UserNotifications.h>
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>

NSNotificationName const UsageSettingsDidChangeNotification = @"UsageSettingsDidChangeNotification";
static NSString *const SharedDefaultsSuite = @"jp.local.ai-usage.shared";
static NSString *UsageDefaultsSuite(void) { return NSProcessInfo.processInfo.environment[@"AI_USAGE_DEFAULTS_SUITE"]?:SharedDefaultsSuite; }
static NSUserDefaults *UsageDefaults(void) { static NSUserDefaults *d;static dispatch_once_t once;dispatch_once(&once,^{d=[[NSUserDefaults alloc]initWithSuiteName:UsageDefaultsSuite()];});return d; }

static NSString *const FontFamilyKey = @"appearance.fontFamily";
static NSString *const MenuFontSizeKey = @"appearance.menuBarFontSize";
static NSString *const DetailFontSizeKey = @"appearance.detailFontSize";
static NSString *const FontWeightKey = @"appearance.fontWeight";
static NSString *const MonospacedDigitsKey = @"appearance.monospacedDigits";
static NSString *const CautionThresholdKey = @"appearance.cautionThreshold";
static NSString *const WarningThresholdKey = @"appearance.warningThreshold";
static NSString *const RefreshIntervalKey = @"general.refreshInterval";
static NSString *const AutoRefreshKey = @"general.autoRefreshEnabled";
static NSString *const RefreshWhenOpenedKey = @"general.refreshWhenOpened";
static NSString *const ShowServiceNameKey = @"display.showServiceName";
static NSString *const DisplayRemainingKey = @"display.displayRemaining";
static NSString *const ShowPercentSignKey = @"display.showPercentSign";
static NSString *const ShowResetTimeKey = @"display.showResetTime";
static NSString *const ShowTokenUsageKey = @"display.showTokenUsage";
static NSString *const ShowContextUsageKey = @"display.showContextUsage";
static NSString *const ShowModelKey = @"display.showModel";
static NSString *const ShowUpdatedTimeKey = @"display.showUpdatedTime";
static NSString *const CautionNotificationKey = @"notification.cautionEnabled";
static NSString *const WarningNotificationKey = @"notification.warningEnabled";
static NSString *const ThemeKey = @"appearance.theme";
static NSString *const Use24HourKey = @"general.use24HourTime";
static NSString *const DigitGroupingKey = @"general.useDigitGrouping";

@implementation UsageSettingsStore

+ (instancetype)sharedStore {
    static UsageSettingsStore *store; static dispatch_once_t once;
    dispatch_once(&once, ^{ store = [UsageSettingsStore new]; [store registerDefaults]; });
    return store;
}

- (void)registerDefaults {
    [UsageDefaults() registerDefaults:@{
        @"settings.schemaVersion": @1, FontFamilyKey: @"SF Pro Rounded",
        MenuFontSizeKey: @13, DetailFontSizeKey: @12, FontWeightKey: @(NSFontWeightRegular),
        MonospacedDigitsKey: @YES, CautionThresholdKey: @60, WarningThresholdKey: @85,
        RefreshIntervalKey: @5, AutoRefreshKey: @YES, RefreshWhenOpenedKey: @YES, ShowServiceNameKey: @YES, DisplayRemainingKey: @NO,
        ShowPercentSignKey: @YES, ShowResetTimeKey: @YES, ShowTokenUsageKey: @YES,
        ShowContextUsageKey: @YES, ShowModelKey: @YES, ShowUpdatedTimeKey: @YES,
        CautionNotificationKey: @NO, WarningNotificationKey: @NO,
        ThemeKey: @"system", Use24HourKey: @YES, DigitGroupingKey: @YES,
        @"color.codexAccent": @"0.000,0.478,1.000,1.000",
        @"color.claudeAccent": @"0.686,0.321,0.871,1.000",
        @"color.normal": @"0.204,0.780,0.349,1.000",
        @"color.caution": @"1.000,0.584,0.000,1.000",
        @"color.warning": @"1.000,0.231,0.188,1.000"
    }];
}

- (void)changed { [NSNotificationCenter.defaultCenter postNotificationName:UsageSettingsDidChangeNotification object:self];[NSDistributedNotificationCenter.defaultCenter postNotificationName:UsageSettingsDidChangeNotification object:NSBundle.mainBundle.bundleIdentifier userInfo:nil deliverImmediately:YES]; }
- (NSString *)fontFamily { return [UsageDefaults() stringForKey:FontFamilyKey]; }
- (void)setFontFamily:(NSString *)v { [UsageDefaults() setObject:v forKey:FontFamilyKey]; [self changed]; }
- (CGFloat)menuBarFontSize { return [UsageDefaults() doubleForKey:MenuFontSizeKey]; }
- (void)setMenuBarFontSize:(CGFloat)v { [UsageDefaults() setDouble:MAX(11, MIN(15, v)) forKey:MenuFontSizeKey]; [self changed]; }
- (CGFloat)detailFontSize { return [UsageDefaults() doubleForKey:DetailFontSizeKey]; }
- (void)setDetailFontSize:(CGFloat)v { [UsageDefaults() setDouble:MAX(10, MIN(24, v)) forKey:DetailFontSizeKey]; [self changed]; }
- (NSFontWeight)fontWeight { return [UsageDefaults() doubleForKey:FontWeightKey]; }
- (void)setFontWeight:(NSFontWeight)v { [UsageDefaults() setDouble:v forKey:FontWeightKey]; [self changed]; }
- (BOOL)monospacedDigits { return [UsageDefaults() boolForKey:MonospacedDigitsKey]; }
- (void)setMonospacedDigits:(BOOL)v { [UsageDefaults() setBool:v forKey:MonospacedDigitsKey]; [self changed]; }
- (double)cautionThreshold { return [UsageDefaults() doubleForKey:CautionThresholdKey]; }
- (void)setCautionThreshold:(double)v { [UsageDefaults() setDouble:MAX(1, MIN(v, self.warningThreshold - 1)) forKey:CautionThresholdKey]; [self changed]; }
- (double)warningThreshold { return [UsageDefaults() doubleForKey:WarningThresholdKey]; }
- (void)setWarningThreshold:(double)v { [UsageDefaults() setDouble:MAX(self.cautionThreshold + 1, MIN(100, v)) forKey:WarningThresholdKey]; [self changed]; }
- (NSTimeInterval)refreshInterval { return [UsageDefaults() doubleForKey:RefreshIntervalKey]; }
- (void)setRefreshInterval:(NSTimeInterval)v { [UsageDefaults() setDouble:v forKey:RefreshIntervalKey]; [self changed]; }
#define BOOL_SETTING(getter, setter, key) - (BOOL)getter { return [UsageDefaults() boolForKey:key]; } - (void)setter:(BOOL)v { [UsageDefaults() setBool:v forKey:key]; [self changed]; }
BOOL_SETTING(showServiceName, setShowServiceName, ShowServiceNameKey)
BOOL_SETTING(autoRefreshEnabled, setAutoRefreshEnabled, AutoRefreshKey)
BOOL_SETTING(refreshWhenOpened, setRefreshWhenOpened, RefreshWhenOpenedKey)
BOOL_SETTING(displayRemaining, setDisplayRemaining, DisplayRemainingKey)
BOOL_SETTING(showPercentSign, setShowPercentSign, ShowPercentSignKey)
BOOL_SETTING(showResetTime, setShowResetTime, ShowResetTimeKey)
BOOL_SETTING(showTokenUsage, setShowTokenUsage, ShowTokenUsageKey)
BOOL_SETTING(showContextUsage, setShowContextUsage, ShowContextUsageKey)
BOOL_SETTING(showModel, setShowModel, ShowModelKey)
BOOL_SETTING(showUpdatedTime, setShowUpdatedTime, ShowUpdatedTimeKey)
BOOL_SETTING(cautionNotificationEnabled, setCautionNotificationEnabled, CautionNotificationKey)
BOOL_SETTING(warningNotificationEnabled, setWarningNotificationEnabled, WarningNotificationKey)
BOOL_SETTING(use24HourTime, setUse24HourTime, Use24HourKey)
BOOL_SETTING(useDigitGrouping, setUseDigitGrouping, DigitGroupingKey)
#undef BOOL_SETTING
- (NSString *)theme { return [UsageDefaults() stringForKey:ThemeKey]; }
- (void)setTheme:(NSString *)v { [UsageDefaults() setObject:v forKey:ThemeKey];[self changed]; }

- (NSColor *)colorForKey:(NSString *)key {
    NSArray *c = [[UsageDefaults() stringForKey:key] componentsSeparatedByString:@","];
    if (c.count != 4) return NSColor.labelColor;
    return [NSColor colorWithSRGBRed:[c[0] doubleValue] green:[c[1] doubleValue] blue:[c[2] doubleValue] alpha:[c[3] doubleValue]];
}
- (void)setColor:(NSColor *)color key:(NSString *)key {
    NSColor *c = [color colorUsingColorSpace:NSColorSpace.sRGBColorSpace] ?: color;
    NSString *value = [NSString stringWithFormat:@"%.4f,%.4f,%.4f,%.4f", c.redComponent, c.greenComponent, c.blueComponent, c.alphaComponent];
    [UsageDefaults() setObject:value forKey:key]; [self changed];
}
- (NSColor *)accentColorForService:(UsageService)s { return [self colorForKey:s == UsageServiceCodex ? @"color.codexAccent" : @"color.claudeAccent"]; }
- (void)setAccentColor:(NSColor *)c forService:(UsageService)s { [self setColor:c key:s == UsageServiceCodex ? @"color.codexAccent" : @"color.claudeAccent"]; }
- (NSColor *)normalColor { return [self colorForKey:@"color.normal"]; }
- (NSColor *)cautionColor { return [self colorForKey:@"color.caution"]; }
- (NSColor *)warningColor { return [self colorForKey:@"color.warning"]; }
- (void)setNormalColor:(NSColor *)c { [self setColor:c key:@"color.normal"]; }
- (void)setCautionColor:(NSColor *)c { [self setColor:c key:@"color.caution"]; }
- (void)setWarningColor:(NSColor *)c { [self setColor:c key:@"color.warning"]; }
- (NSArray<NSString *> *)settingKeys { return @[FontFamilyKey,MenuFontSizeKey,DetailFontSizeKey,FontWeightKey,MonospacedDigitsKey,CautionThresholdKey,WarningThresholdKey,RefreshIntervalKey,AutoRefreshKey,RefreshWhenOpenedKey,ShowServiceNameKey,DisplayRemainingKey,ShowPercentSignKey,ShowResetTimeKey,ShowTokenUsageKey,ShowContextUsageKey,ShowModelKey,ShowUpdatedTimeKey,CautionNotificationKey,WarningNotificationKey,ThemeKey,Use24HourKey,DigitGroupingKey,@"color.codexAccent",@"color.claudeAccent",@"color.normal",@"color.caution",@"color.warning"]; }
- (BOOL)exportSettingsToURL:(NSURL *)url error:(NSError **)error { NSMutableDictionary *values=[NSMutableDictionary dictionaryWithObject:@1 forKey:@"settings.schemaVersion"];for(NSString *key in self.settingKeys){id value=[UsageDefaults() objectForKey:key];if(value)values[key]=value;}NSData *data=[NSJSONSerialization dataWithJSONObject:values options:NSJSONWritingPrettyPrinted|NSJSONWritingSortedKeys error:error];return data?[data writeToURL:url options:NSDataWritingAtomic error:error]:NO; }
- (BOOL)importSettingsFromURL:(NSURL *)url error:(NSError **)error { NSData *data=[NSData dataWithContentsOfURL:url options:0 error:error];NSDictionary *values=data?[NSJSONSerialization JSONObjectWithData:data options:0 error:error]:nil;if(![values isKindOfClass:NSDictionary.class]||[values[@"settings.schemaVersion"] integerValue]!=1){if(error)*error=[NSError errorWithDomain:@"UsageSettings" code:1 userInfo:@{NSLocalizedDescriptionKey:@"対応していない設定ファイルです。"}];return NO;}for(NSString *key in self.settingKeys){id value=values[key];if(value)[UsageDefaults() setObject:value forKey:key];}[self changed];return YES; }
- (void)resetToDefaults {
    for (NSString *key in @[FontFamilyKey, MenuFontSizeKey, DetailFontSizeKey, FontWeightKey, MonospacedDigitsKey, CautionThresholdKey, WarningThresholdKey, RefreshIntervalKey, AutoRefreshKey, RefreshWhenOpenedKey, ShowServiceNameKey, DisplayRemainingKey, ShowPercentSignKey, ShowResetTimeKey, ShowTokenUsageKey, ShowContextUsageKey, ShowModelKey, ShowUpdatedTimeKey, CautionNotificationKey, WarningNotificationKey, ThemeKey, Use24HourKey, DigitGroupingKey, @"color.codexAccent", @"color.claudeAccent", @"color.normal", @"color.caution", @"color.warning"])
        [UsageDefaults() removeObjectForKey:key];
    [self changed];
}
@end

NSFont *UsageFont(CGFloat size, NSFontWeight weight) {
    UsageSettingsStore *s = UsageSettingsStore.sharedStore;
    NSFont *font = nil;
    if ([s.fontFamily isEqualToString:@"System"]) font = [NSFont systemFontOfSize:size weight:weight];
    else if ([s.fontFamily isEqualToString:@"Monospaced"]) font = [NSFont monospacedSystemFontOfSize:size weight:weight];
    else font = [NSFont fontWithName:s.fontFamily size:size];
    if (!font) { NSFont *base = [NSFont systemFontOfSize:size weight:weight]; NSFontDescriptor *d = [base.fontDescriptor fontDescriptorWithDesign:NSFontDescriptorSystemDesignRounded]; font = d ? [NSFont fontWithDescriptor:d size:size] : base; }
    if (s.monospacedDigits) { NSFontDescriptor *d = [font.fontDescriptor fontDescriptorByAddingAttributes:@{NSFontFeatureSettingsAttribute: @[@{NSFontFeatureTypeIdentifierKey:@6, NSFontFeatureSelectorIdentifierKey:@0}]}]; font = [NSFont fontWithDescriptor:d size:size] ?: font; }
    return font;
}

NSFont *UsageDetailFont(CGFloat baseSize, NSFontWeight weight) {
    CGFloat scale = UsageSettingsStore.sharedStore.detailFontSize / 12.0;
    return UsageFont(MAX(9, baseSize * scale), weight);
}

static double LinearComponent(double c){return c<=0.04045?c/12.92:pow((c+0.055)/1.055,2.4);}
static void ColorComponents(NSColor *color,CGFloat *r,CGFloat *g,CGFloat *b,CGFloat *a){NSColor *c=[color colorUsingColorSpace:NSColorSpace.genericRGBColorSpace];[c getRed:r green:g blue:b alpha:a];}
static double Luminance(NSColor *color){CGFloat r=0,g=0,b=0,a=0;ColorComponents(color,&r,&g,&b,&a);return 0.2126*LinearComponent(r)+0.7152*LinearComponent(g)+0.0722*LinearComponent(b);}
double UsageContrastRatio(NSColor *a,NSColor *b){double x=Luminance(a),y=Luminance(b);return (MAX(x,y)+0.05)/(MIN(x,y)+0.05);}
NSColor *UsageColorWithMinimumContrast(NSColor *color,NSColor *background){if(UsageContrastRatio(color,background)>=4.5)return color;BOOL light=Luminance(background)>0.5;CGFloat r=0,g=0,b=0,a=0,tr=0,tg=0,tb=0,ta=0;ColorComponents(color,&r,&g,&b,&a);NSColor *target=light?NSColor.blackColor:NSColor.whiteColor;ColorComponents(target,&tr,&tg,&tb,&ta);for(NSInteger step=1;step<=20;step++){CGFloat f=step/20.0;NSColor *candidate=[NSColor colorWithSRGBRed:r*(1-f)+tr*f green:g*(1-f)+tg*f blue:b*(1-f)+tb*f alpha:a];if(UsageContrastRatio(candidate,background)>=4.5)return candidate;}return target;}
NSColor *UsageColor(double value) { UsageSettingsStore *s=UsageSettingsStore.sharedStore;NSColor *raw=value<s.cautionThreshold?s.normalColor:(value<s.warningThreshold?s.cautionColor:s.warningColor);return UsageColorWithMinimumContrast(raw,NSColor.windowBackgroundColor); }
NSAttributedString *UsageStatusTitle(UsageService service, NSString *value, NSColor *valueColor) {
    UsageSettingsStore *s=UsageSettingsStore.sharedStore; NSString *name=s.showServiceName?(service==UsageServiceCodex?@"Codex ":@"Claude "):@"";
    NSMutableAttributedString *t=[[NSMutableAttributedString alloc] initWithString:name attributes:@{NSFontAttributeName:UsageFont(s.menuBarFontSize,NSFontWeightSemibold),NSForegroundColorAttributeName:[s accentColorForService:service]}];
    [t appendAttributedString:[[NSAttributedString alloc] initWithString:value attributes:@{NSFontAttributeName:UsageFont(s.menuBarFontSize,NSFontWeightBold),NSForegroundColorAttributeName:valueColor}]]; return t;
}

NSString *UsageMenuValue(double usedPercent) { UsageSettingsStore *s=UsageSettingsStore.sharedStore;double value=s.displayRemaining?100.0-usedPercent:usedPercent;return [NSString stringWithFormat:s.showPercentSign?@"%.0f%%":@"%.0f",MAX(0,value)]; }

BOOL UsageLaunchAtLoginEnabled(void) { return SMAppService.mainAppService.status==SMAppServiceStatusEnabled; }
BOOL UsageSetLaunchAtLogin(BOOL enabled, NSError **error) { return enabled?[SMAppService.mainAppService registerAndReturnError:error]:[SMAppService.mainAppService unregisterAndReturnError:error]; }
void UsageApplyTheme(void) { NSString *theme=UsageSettingsStore.sharedStore.theme;if([theme isEqualToString:@"light"])NSApp.appearance=[NSAppearance appearanceNamed:NSAppearanceNameAqua];else if([theme isEqualToString:@"dark"])NSApp.appearance=[NSAppearance appearanceNamed:NSAppearanceNameDarkAqua];else if([theme isEqualToString:@"highContrast"])NSApp.appearance=[NSAppearance appearanceNamed:NSAppearanceNameAccessibilityHighContrastAqua];else NSApp.appearance=nil; }
NSString *UsageFormattedDate(NSDate *date,BOOL seconds) { NSDateFormatter *f=[NSDateFormatter new];f.locale=[NSLocale localeWithLocaleIdentifier:@"ja_JP"];BOOL h24=UsageSettingsStore.sharedStore.use24HourTime;f.dateFormat=seconds?(h24?@"M月d日 H:mm:ss":@"M月d日 h:mm:ss a"):(h24?@"M月d日 H:mm":@"M月d日 h:mm a");return [f stringFromDate:date]; }
NSString *UsageFormattedInteger(long long value) { NSNumberFormatter *f=[NSNumberFormatter new];f.numberStyle=UsageSettingsStore.sharedStore.useDigitGrouping?NSNumberFormatterDecimalStyle:NSNumberFormatterNoStyle;return [f stringFromNumber:@(value)]; }

@interface UsageNotificationController () <UNUserNotificationCenterDelegate> @property UsageService service; @end
@implementation UsageNotificationController
- (instancetype)initWithService:(UsageService)s { if((self=[super init])){_service=s;}return self; }
- (void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions options))completionHandler { completionHandler(UNNotificationPresentationOptionBanner|UNNotificationPresentationOptionList|UNNotificationPresentationOptionSound); }
- (void)evaluateUsedPercent:(double)p resetIdentifier:(NSString *)identifier {
    UsageSettingsStore *s=UsageSettingsStore.sharedStore;NSString *level=nil;
    if(p>=s.warningThreshold&&s.warningNotificationEnabled)level=@"warning";else if(p>=s.cautionThreshold&&s.cautionNotificationEnabled)level=@"caution";if(!level)return;
    NSString *service=self.service==UsageServiceCodex?@"Codex":@"Claude";NSString *key=[NSString stringWithFormat:@"notification.sent.%@.%@.%@",service,identifier?:@"unknown",level];if([UsageDefaults() boolForKey:key])return;[UsageDefaults() setBool:YES forKey:key];
    UNUserNotificationCenter *center=UNUserNotificationCenter.currentNotificationCenter;[center requestAuthorizationWithOptions:UNAuthorizationOptionAlert|UNAuthorizationOptionSound completionHandler:^(BOOL granted,NSError *error){if(!granted){[UsageDefaults() removeObjectForKey:key];return;}UNMutableNotificationContent *content=[UNMutableNotificationContent new];content.title=[NSString stringWithFormat:@"%@ 使用率",service];content.body=[NSString stringWithFormat:@"使用率が%.0f%%に達しました。",p];content.sound=UNNotificationSound.defaultSound;UNNotificationRequest *request=[UNNotificationRequest requestWithIdentifier:key content:content trigger:nil];[center addNotificationRequest:request withCompletionHandler:^(NSError *error){if(error)[UsageDefaults() removeObjectForKey:key];}];}];
}
- (void)sendTestNotification { UNUserNotificationCenter *center=UNUserNotificationCenter.currentNotificationCenter;[center requestAuthorizationWithOptions:UNAuthorizationOptionAlert|UNAuthorizationOptionSound completionHandler:^(BOOL granted,NSError *error){if(!granted)return;UNMutableNotificationContent *content=[UNMutableNotificationContent new];content.title=@"AI Usage Menubar 通知テスト";content.body=@"通知は正常に設定されています。";content.sound=UNUserNotificationCenter.currentNotificationCenter?UNNotificationSound.defaultSound:nil;[center addNotificationRequest:[UNNotificationRequest requestWithIdentifier:[NSString stringWithFormat:@"test.%@",NSUUID.UUID.UUIDString] content:content trigger:nil] withCompletionHandler:nil];}]; }
@end

@implementation UsageBar
- (void)setValue:(double)v { _value=v; self.needsDisplay=YES; }
- (void)drawRect:(NSRect)r { NSRect b=NSInsetRect(self.bounds,1,4); NSBezierPath *bg=[NSBezierPath bezierPathWithRoundedRect:b xRadius:5 yRadius:5]; [NSColor.quaternaryLabelColor setFill];[bg fill];double f=MAX(0,MIN(1,self.value/100));if(!f)return;b.size.width*=f;[UsageColor(self.value) setFill];[[NSBezierPath bezierPathWithRoundedRect:b xRadius:5 yRadius:5] fill]; }
@end

@interface UsageSettingsWindowController ()
@property UsageService service; @property NSPopUpButton *font; @property NSSlider *menuSize; @property NSSlider *detailSize; @property NSPopUpButton *weight; @property NSButton *digits; @property NSColorWell *accent; @property NSColorWell *normal; @property NSColorWell *caution; @property NSColorWell *warning; @property NSSlider *cautionLevel; @property NSSlider *warningLevel; @property NSPopUpButton *interval; @property NSTextField *preview;
@property NSButton *showService; @property NSButton *remaining; @property NSButton *percentSign; @property NSButton *showReset; @property NSButton *showTokens; @property NSButton *showContext; @property NSButton *showModel; @property NSButton *showUpdated; @property NSButton *cautionNotify; @property NSButton *warningNotify; @property NSButton *launchAtLogin;
@property NSPopUpButton *themeButton; @property NSButton *time24; @property NSButton *digitGrouping;
@property NSButton *autoRefresh; @property NSButton *refreshOnOpen;
@end

@implementation UsageSettingsWindowController
- (instancetype)initWithService:(UsageService)service {
    NSWindow *w=[[NSWindow alloc] initWithContentRect:NSMakeRect(0,0,620,560) styleMask:NSWindowStyleMaskTitled|NSWindowStyleMaskClosable|NSWindowStyleMaskResizable backing:NSBackingStoreBuffered defer:NO];
    if((self=[super initWithWindow:w])){_service=service;w.title=@"AI Usage 設定";[w center];[self build];}return self;
}
- (NSTextField *)heading:(NSString *)s { NSTextField *l=[NSTextField labelWithString:s];l.font=[NSFont systemFontOfSize:13 weight:NSFontWeightSemibold];return l; }
- (NSView *)row:(NSString *)name control:(NSView *)control { NSTextField *l=[NSTextField labelWithString:name];[l.widthAnchor constraintEqualToConstant:170].active=YES;NSStackView *r=[NSStackView stackViewWithViews:@[l,control]];r.orientation=NSUserInterfaceLayoutOrientationHorizontal;r.alignment=NSLayoutAttributeCenterY;r.spacing=12;return r; }
- (NSTabViewItem *)tab:(NSString *)title views:(NSArray<NSView *> *)views { NSTabViewItem *item=[[NSTabViewItem alloc]initWithIdentifier:title];item.label=title;NSView *view=[NSView new];NSStackView *stack=[NSStackView stackViewWithViews:views];stack.orientation=NSUserInterfaceLayoutOrientationVertical;stack.alignment=NSLayoutAttributeLeading;stack.spacing=12;stack.edgeInsets=NSEdgeInsetsMake(20,20,20,20);stack.translatesAutoresizingMaskIntoConstraints=NO;[view addSubview:stack];[NSLayoutConstraint activateConstraints:@[[stack.leadingAnchor constraintEqualToAnchor:view.leadingAnchor],[stack.trailingAnchor constraintLessThanOrEqualToAnchor:view.trailingAnchor],[stack.topAnchor constraintEqualToAnchor:view.topAnchor]]];item.view=view;return item; }
- (void)build {
    UsageSettingsStore *s=UsageSettingsStore.sharedStore;
    self.font=[[NSPopUpButton alloc]init];[self.font addItemsWithTitles:@[@"System",@"SF Pro",@"SF Pro Rounded",@"Monospaced",@"Avenir Next"]];[self.font selectItemWithTitle:s.fontFamily];
    self.menuSize=[NSSlider sliderWithValue:s.menuBarFontSize minValue:11 maxValue:15 target:self action:@selector(change:)];self.detailSize=[NSSlider sliderWithValue:s.detailFontSize minValue:10 maxValue:24 target:self action:@selector(change:)];
    self.weight=[[NSPopUpButton alloc]init];[self.weight addItemsWithTitles:@[@"標準",@"中太",@"太字"]];[self.weight selectItemAtIndex:s.fontWeight>=NSFontWeightBold?2:(s.fontWeight>=NSFontWeightMedium?1:0)];
    self.digits=[NSButton checkboxWithTitle:@"数字を等幅で表示" target:self action:@selector(change:)];self.digits.state=s.monospacedDigits;
    self.accent=[NSColorWell new];self.accent.color=[s accentColorForService:self.service];self.normal=[NSColorWell new];self.normal.color=s.normalColor;self.caution=[NSColorWell new];self.caution.color=s.cautionColor;self.warning=[NSColorWell new];self.warning.color=s.warningColor;
    for(NSColorWell *well in @[self.accent,self.normal,self.caution,self.warning]){well.target=self;well.action=@selector(change:);}
    self.cautionLevel=[NSSlider sliderWithValue:s.cautionThreshold minValue:1 maxValue:98 target:self action:@selector(change:)];self.warningLevel=[NSSlider sliderWithValue:s.warningThreshold minValue:2 maxValue:100 target:self action:@selector(change:)];
    self.interval=[[NSPopUpButton alloc]init];for(NSNumber *n in @[@1,@5,@15,@30,@60]){NSString *title=n.integerValue<60?[NSString stringWithFormat:@"%@秒",n]:@"1分";[self.interval addItemWithTitle:title];self.interval.lastItem.representedObject=n;} for(NSMenuItem *i in self.interval.itemArray)if([i.representedObject doubleValue]==s.refreshInterval)[self.interval selectItem:i];
    for(NSControl *c in @[self.font,self.weight,self.interval]){c.target=self;c.action=@selector(change:);}
    self.preview=[NSTextField labelWithString:self.service==UsageServiceCodex?@"Codex 61%":@"Claude 61%"];
    self.showService=[NSButton checkboxWithTitle:@"サービス名" target:self action:@selector(change:)];self.showService.state=s.showServiceName;
    self.remaining=[NSButton checkboxWithTitle:@"残量で表示" target:self action:@selector(change:)];self.remaining.state=s.displayRemaining;
    self.percentSign=[NSButton checkboxWithTitle:@"%記号" target:self action:@selector(change:)];self.percentSign.state=s.showPercentSign;
    self.showReset=[NSButton checkboxWithTitle:@"リセット日時" target:self action:@selector(change:)];self.showReset.state=s.showResetTime;
    self.showTokens=[NSButton checkboxWithTitle:@"トークン使用量" target:self action:@selector(change:)];self.showTokens.state=s.showTokenUsage;
    self.showContext=[NSButton checkboxWithTitle:@"コンテキスト使用率" target:self action:@selector(change:)];self.showContext.state=s.showContextUsage;
    self.showModel=[NSButton checkboxWithTitle:@"モデル名" target:self action:@selector(change:)];self.showModel.state=s.showModel;
    self.showUpdated=[NSButton checkboxWithTitle:@"最終更新日時" target:self action:@selector(change:)];self.showUpdated.state=s.showUpdatedTime;
    self.cautionNotify=[NSButton checkboxWithTitle:@"注意しきい値で通知" target:self action:@selector(change:)];self.cautionNotify.state=s.cautionNotificationEnabled;
    self.warningNotify=[NSButton checkboxWithTitle:@"警告しきい値で通知" target:self action:@selector(change:)];self.warningNotify.state=s.warningNotificationEnabled;
    NSButton *testNotification=[NSButton buttonWithTitle:@"通知をテスト" target:self action:@selector(testNotification:)];
    self.launchAtLogin=[NSButton checkboxWithTitle:@"Macログイン時に自動起動" target:self action:@selector(change:)];self.launchAtLogin.state=UsageLaunchAtLoginEnabled();
    self.autoRefresh=[NSButton checkboxWithTitle:@"自動更新" target:self action:@selector(change:)];self.autoRefresh.state=s.autoRefreshEnabled;self.refreshOnOpen=[NSButton checkboxWithTitle:@"ポップオーバーを開いたときに更新" target:self action:@selector(change:)];self.refreshOnOpen.state=s.refreshWhenOpened;
    self.themeButton=[NSPopUpButton new];NSArray *themes=@[@[@"システム",@"system"],@[@"ライト",@"light"],@[@"ダーク",@"dark"],@[@"高コントラスト",@"highContrast"]];for(NSArray *entry in themes){[self.themeButton addItemWithTitle:entry[0]];self.themeButton.lastItem.representedObject=entry[1];if([entry[1] isEqualToString:s.theme])[self.themeButton selectItem:self.themeButton.lastItem];}self.themeButton.target=self;self.themeButton.action=@selector(change:);
    self.time24=[NSButton checkboxWithTitle:@"24時間表記" target:self action:@selector(change:)];self.time24.state=s.use24HourTime;self.digitGrouping=[NSButton checkboxWithTitle:@"数値を桁区切り" target:self action:@selector(change:)];self.digitGrouping.state=s.useDigitGrouping;
    NSButton *reset=[NSButton buttonWithTitle:@"デフォルトに戻す" target:self action:@selector(reset:)];
    NSButton *exportButton=[NSButton buttonWithTitle:@"設定を書き出す…" target:self action:@selector(exportSettings:)];NSButton *importButton=[NSButton buttonWithTitle:@"設定を読み込む…" target:self action:@selector(importSettings:)];NSStackView *transfer=[NSStackView stackViewWithViews:@[exportButton,importButton]];transfer.spacing=8;
    NSButton *openData=[NSButton buttonWithTitle:@"データフォルダを開く" target:self action:@selector(openDataFolder:)];NSButton *copyDiagnostics=[NSButton buttonWithTitle:@"診断情報をコピー" target:self action:@selector(copyDiagnostics:)];NSStackView *diagnosticButtons=[NSStackView stackViewWithViews:@[openData,copyDiagnostics]];diagnosticButtons.spacing=8;
    NSStackView *menuOptions=[NSStackView stackViewWithViews:@[self.showService,self.remaining,self.percentSign]];menuOptions.spacing=12;
    NSStackView *detailOptions=[NSStackView stackViewWithViews:@[self.showReset,self.showTokens,self.showContext,self.showModel,self.showUpdated]];detailOptions.orientation=NSUserInterfaceLayoutOrientationVertical;detailOptions.spacing=4;
    NSTabView *tabs=[NSTabView new];tabs.translatesAutoresizingMaskIntoConstraints=NO;
    [tabs addTabViewItem:[self tab:@"一般" views:@[[self heading:@"更新"],self.autoRefresh,[self row:@"更新間隔" control:self.interval],self.refreshOnOpen,self.launchAtLogin,[self heading:@"日時と数値"],self.time24,self.digitGrouping,reset]]];
    [tabs addTabViewItem:[self tab:@"外観" views:@[[self heading:@"変更はすぐ反映されます"],[self row:@"テーマ" control:self.themeButton],[self row:@"フォント" control:self.font],[self row:@"メニューバーサイズ" control:self.menuSize],[self row:@"詳細画面サイズ" control:self.detailSize],[self row:@"太さ" control:self.weight],self.digits,[self row:@"アクセントカラー" control:self.accent],[self row:@"通常／注意／警告" control:[NSStackView stackViewWithViews:@[self.normal,self.caution,self.warning]]],[self row:@"注意しきい値" control:self.cautionLevel],[self row:@"警告しきい値" control:self.warningLevel],[self heading:@"ライブプレビュー"],self.preview]]];
    [tabs addTabViewItem:[self tab:@"表示項目" views:@[[self heading:@"メニューバー"],menuOptions,[self heading:@"詳細画面"],detailOptions]]];
    [tabs addTabViewItem:[self tab:@"通知" views:@[[self heading:@"同じ利用枠では一度だけ通知します"],self.cautionNotify,self.warningNotify,testNotification]]];
    [tabs addTabViewItem:[self tab:@"データ" views:@[[self heading:self.service==UsageServiceCodex?@"Codexセッションをローカルから読み取ります":@"Claude Code statusLineのローカルキャッシュを読み取ります"],[NSTextField wrappingLabelWithString:@"会話本文は処理せず、追加の外部通信も行いません。"],diagnosticButtons,[self heading:@"設定の移行"],transfer]]];
    [tabs addTabViewItem:[self tab:@"詳細" views:@[[self heading:@"診断"],[NSTextField wrappingLabelWithString:[self diagnosticText]]]]];
    [self.window.contentView addSubview:tabs];[NSLayoutConstraint activateConstraints:@[[tabs.leadingAnchor constraintEqualToAnchor:self.window.contentView.leadingAnchor constant:12],[tabs.trailingAnchor constraintEqualToAnchor:self.window.contentView.trailingAnchor constant:-12],[tabs.topAnchor constraintEqualToAnchor:self.window.contentView.topAnchor constant:12],[tabs.bottomAnchor constraintEqualToAnchor:self.window.contentView.bottomAnchor constant:-12]]];[self updatePreview];
}
- (void)change:(id)sender {
    UsageSettingsStore *s=UsageSettingsStore.sharedStore;
    if(sender==self.font)s.fontFamily=self.font.titleOfSelectedItem;
    else if(sender==self.menuSize)s.menuBarFontSize=self.menuSize.doubleValue;
    else if(sender==self.detailSize)s.detailFontSize=self.detailSize.doubleValue;
    else if(sender==self.weight)s.fontWeight=self.weight.indexOfSelectedItem==2?NSFontWeightBold:(self.weight.indexOfSelectedItem==1?NSFontWeightMedium:NSFontWeightRegular);
    else if(sender==self.digits)s.monospacedDigits=self.digits.state==NSControlStateValueOn;
    else if(sender==self.accent)[s setAccentColor:self.accent.color forService:self.service];
    else if(sender==self.normal)[s setNormalColor:self.normal.color];
    else if(sender==self.caution)[s setCautionColor:self.caution.color];
    else if(sender==self.warning)[s setWarningColor:self.warning.color];
    else if(sender==self.cautionLevel){s.cautionThreshold=self.cautionLevel.doubleValue;self.cautionLevel.doubleValue=s.cautionThreshold;}
    else if(sender==self.warningLevel){s.warningThreshold=self.warningLevel.doubleValue;self.warningLevel.doubleValue=s.warningThreshold;}
    else if(sender==self.interval)s.refreshInterval=[self.interval.selectedItem.representedObject doubleValue];
    else if(sender==self.showService)s.showServiceName=self.showService.state==NSControlStateValueOn;
    else if(sender==self.remaining)s.displayRemaining=self.remaining.state==NSControlStateValueOn;
    else if(sender==self.percentSign)s.showPercentSign=self.percentSign.state==NSControlStateValueOn;
    else if(sender==self.showReset)s.showResetTime=self.showReset.state==NSControlStateValueOn;
    else if(sender==self.showTokens)s.showTokenUsage=self.showTokens.state==NSControlStateValueOn;
    else if(sender==self.showContext)s.showContextUsage=self.showContext.state==NSControlStateValueOn;
    else if(sender==self.showModel)s.showModel=self.showModel.state==NSControlStateValueOn;
    else if(sender==self.showUpdated)s.showUpdatedTime=self.showUpdated.state==NSControlStateValueOn;
    else if(sender==self.cautionNotify)s.cautionNotificationEnabled=self.cautionNotify.state==NSControlStateValueOn;
    else if(sender==self.warningNotify)s.warningNotificationEnabled=self.warningNotify.state==NSControlStateValueOn;
    else if(sender==self.launchAtLogin){NSError *error=nil;BOOL enabled=self.launchAtLogin.state==NSControlStateValueOn;if(!UsageSetLaunchAtLogin(enabled,&error)){self.launchAtLogin.state=!enabled;NSAlert *alert=[NSAlert new];alert.messageText=@"ログイン時起動を変更できませんでした";alert.informativeText=error.localizedDescription?:@"アプリをApplicationsフォルダへ移動して再試行してください。";[alert beginSheetModalForWindow:self.window completionHandler:nil];}}
    else if(sender==self.themeButton){s.theme=self.themeButton.selectedItem.representedObject;UsageApplyTheme();}
    else if(sender==self.time24)s.use24HourTime=self.time24.state==NSControlStateValueOn;
    else if(sender==self.digitGrouping)s.useDigitGrouping=self.digitGrouping.state==NSControlStateValueOn;
    else if(sender==self.autoRefresh)s.autoRefreshEnabled=self.autoRefresh.state==NSControlStateValueOn;
    else if(sender==self.refreshOnOpen)s.refreshWhenOpened=self.refreshOnOpen.state==NSControlStateValueOn;
    [self updatePreview];
}
- (void)updatePreview { UsageSettingsStore *s=UsageSettingsStore.sharedStore;self.autoRefresh.state=s.autoRefreshEnabled;self.refreshOnOpen.state=s.refreshWhenOpened;self.preview.attributedStringValue=UsageStatusTitle(self.service,UsageMenuValue(61),UsageColor(61));self.preview.font=UsageFont(s.detailFontSize,s.fontWeight); }
- (void)reloadControls { UsageSettingsStore *s=UsageSettingsStore.sharedStore;for(NSMenuItem *item in self.themeButton.itemArray)if([item.representedObject isEqualToString:s.theme])[self.themeButton selectItem:item];self.time24.state=s.use24HourTime;self.digitGrouping.state=s.useDigitGrouping;[self.font selectItemWithTitle:s.fontFamily];self.menuSize.doubleValue=s.menuBarFontSize;self.detailSize.doubleValue=s.detailFontSize;[self.weight selectItemAtIndex:s.fontWeight>=NSFontWeightBold?2:(s.fontWeight>=NSFontWeightMedium?1:0)];self.digits.state=s.monospacedDigits;self.accent.color=[s accentColorForService:self.service];self.normal.color=s.normalColor;self.caution.color=s.cautionColor;self.warning.color=s.warningColor;self.cautionLevel.doubleValue=s.cautionThreshold;self.warningLevel.doubleValue=s.warningThreshold;self.showService.state=s.showServiceName;self.remaining.state=s.displayRemaining;self.percentSign.state=s.showPercentSign;self.showReset.state=s.showResetTime;self.showTokens.state=s.showTokenUsage;self.showContext.state=s.showContextUsage;self.showModel.state=s.showModel;self.showUpdated.state=s.showUpdatedTime;self.cautionNotify.state=s.cautionNotificationEnabled;self.warningNotify.state=s.warningNotificationEnabled;[self updatePreview]; }
- (void)reset:(id)sender { [UsageSettingsStore.sharedStore resetToDefaults];[self reloadControls];self.autoRefresh.state=UsageSettingsStore.sharedStore.autoRefreshEnabled;self.refreshOnOpen.state=UsageSettingsStore.sharedStore.refreshWhenOpened; }
- (void)showError:(NSError *)error { NSAlert *alert=[NSAlert new];alert.messageText=@"設定を処理できませんでした";alert.informativeText=error.localizedDescription?:@"不明なエラー";[alert beginSheetModalForWindow:self.window completionHandler:nil]; }
- (void)exportSettings:(id)sender { NSSavePanel *panel=[NSSavePanel savePanel];panel.nameFieldStringValue=@"ai-usage-settings.json";panel.allowedContentTypes=@[[UTType typeWithFilenameExtension:@"json"]];[panel beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse result){if(result!=NSModalResponseOK)return;NSError *error=nil;if(![UsageSettingsStore.sharedStore exportSettingsToURL:panel.URL error:&error])[self showError:error];}]; }
- (void)importSettings:(id)sender { NSOpenPanel *panel=[NSOpenPanel openPanel];panel.allowedContentTypes=@[[UTType typeWithFilenameExtension:@"json"]];panel.allowsMultipleSelection=NO;[panel beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse result){if(result!=NSModalResponseOK)return;NSError *error=nil;if(![UsageSettingsStore.sharedStore importSettingsFromURL:panel.URL error:&error]){[self showError:error];return;}[self reloadControls];}]; }
- (NSURL *)dataURL { NSURL *home=NSFileManager.defaultManager.homeDirectoryForCurrentUser;return self.service==UsageServiceCodex?[home URLByAppendingPathComponent:@".codex/sessions" isDirectory:YES]:[home URLByAppendingPathComponent:@".claude" isDirectory:YES]; }
- (NSString *)diagnosticText { NSURL *data=self.dataURL;BOOL exists=[NSFileManager.defaultManager fileExistsAtPath:data.path];NSString *version=[NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"]?:@"development";return [NSString stringWithFormat:@"アプリ: %@ %@\n設定スキーマ: 1\nデータ: %@\n状態: %@\n外部通信: なし\n会話本文の処理: なし",self.service==UsageServiceCodex?@"Codex Usage":@"Claude Usage",version,data.path,exists?@"検出済み":@"未検出"]; }
- (void)openDataFolder:(id)sender { NSURL *url=self.dataURL;if(![NSFileManager.defaultManager fileExistsAtPath:url.path])url=url.URLByDeletingLastPathComponent;[NSWorkspace.sharedWorkspace openURL:url]; }
- (void)copyDiagnostics:(id)sender { NSPasteboard *pasteboard=NSPasteboard.generalPasteboard;[pasteboard clearContents];[pasteboard setString:[self diagnosticText] forType:NSPasteboardTypeString]; }
- (void)testNotification:(id)sender { [[[UsageNotificationController alloc]initWithService:self.service] sendTestNotification]; }
@end
