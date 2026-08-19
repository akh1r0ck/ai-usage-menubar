#import <Cocoa/Cocoa.h>
#import <UserNotifications/UserNotifications.h>
#import "UsageUI.h"
#import "UsageProvider.h"

#define ModernFont UsageDetailFont
static NSAttributedString *CodexTitle(NSString *value, NSColor *color) { return UsageStatusTitle(UsageServiceCodex, value, color); }

@interface AppDelegate : NSObject <NSApplicationDelegate>
@property NSStatusItem *statusItem;
@property NSPopover *popover;
@property NSTextField *percentLabel;
@property NSTextField *periodLabel;
@property NSTextField *resetLabel;
@property NSTextField *tokenLabel;
@property NSTextField *contextLabel;
@property NSTextField *updatedLabel;
@property UsageBar *bar;
@property NSTimer *timer;
@property UsageSettingsWindowController *settingsWindow;
@property UsageNotificationController *notificationController;
@property id<UsageProvider> provider;
@end

@implementation AppDelegate
- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    [NSApp setActivationPolicy:NSApplicationActivationPolicyAccessory];
    UsageApplyTheme();
    self.notificationController=[[UsageNotificationController alloc]initWithService:UsageServiceCodex];
    UNUserNotificationCenter.currentNotificationCenter.delegate=(id)self.notificationController;
    self.provider=[CodexUsageProvider new];
    self.statusItem = [NSStatusBar.systemStatusBar statusItemWithLength:NSVariableStatusItemLength];
    self.statusItem.button.attributedTitle = CodexTitle(@"--%", NSColor.secondaryLabelColor);
    self.statusItem.button.toolTip = @"ChatGPT / Codex 使用量";
    self.statusItem.button.target = self;
    self.statusItem.button.action = @selector(togglePopover:);
    [self buildPopover];
    [self refresh];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(screensChanged:) name:NSApplicationDidChangeScreenParametersNotification object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(settingsChanged:) name:UsageSettingsDidChangeNotification object:nil];
    [NSDistributedNotificationCenter.defaultCenter addObserver:self selector:@selector(settingsChanged:) name:UsageSettingsDidChangeNotification object:nil];
    [self restartTimer];
}

- (void)screensChanged:(NSNotification *)notification {
    // NSStatusBar mirrors the item to every macOS menu bar. Reinsert it after
    // displays are connected/disconnected so the system refreshes every copy.
    NSAttributedString *title = self.statusItem.button.attributedTitle;
    [NSStatusBar.systemStatusBar removeStatusItem:self.statusItem];
    self.statusItem = [NSStatusBar.systemStatusBar statusItemWithLength:NSVariableStatusItemLength];
    self.statusItem.button.attributedTitle = title;
    self.statusItem.button.toolTip = @"ChatGPT / Codex 使用量";
    self.statusItem.button.target = self;
    self.statusItem.button.action = @selector(togglePopover:);
    [self refresh];
}

- (NSTextField *)label:(NSString *)text size:(CGFloat)size color:(NSColor *)color {
    NSTextField *label = [NSTextField labelWithString:text];
    label.font = ModernFont(size, NSFontWeightRegular);
    if (color) label.textColor = color;
    return label;
}

- (void)buildPopover {
    NSTextField *title = [self label:@"ChatGPT / Codex 使用量" size:15 color:nil];
    title.font = ModernFont(16, NSFontWeightBold);
    title.textColor = NSColor.systemBlueColor;
    self.percentLabel = [self label:@"読み込み中…" size:30 color:nil];
    self.percentLabel.font = ModernFont(30, NSFontWeightBold);
    self.periodLabel = [self label:@"" size:12 color:NSColor.secondaryLabelColor];
    self.resetLabel = [self label:@"" size:12 color:NSColor.secondaryLabelColor];
    self.tokenLabel = [self label:@"" size:12 color:nil];
    self.contextLabel = [self label:@"" size:12 color:nil];
    self.updatedLabel = [self label:@"" size:10 color:NSColor.tertiaryLabelColor];
    UsageSettingsStore *display=UsageSettingsStore.sharedStore;
    self.resetLabel.hidden=!display.showResetTime;self.tokenLabel.hidden=!display.showTokenUsage;self.contextLabel.hidden=!display.showContextUsage;self.updatedLabel.hidden=!display.showUpdatedTime;
    self.bar = [UsageBar new]; self.bar.translatesAutoresizingMaskIntoConstraints = NO;
    [self.bar.heightAnchor constraintEqualToConstant:16].active = YES;

    NSButton *settings = [NSButton buttonWithTitle:@"設定…" target:self action:@selector(openSettings:)];
    NSButton *refresh = [NSButton buttonWithTitle:@"更新" target:self action:@selector(refresh)];
    NSButton *quit = [NSButton buttonWithTitle:@"終了" target:NSApp action:@selector(terminate:)];
    NSStackView *buttons = [NSStackView stackViewWithViews:@[settings, refresh, quit]];
    buttons.spacing = 8; buttons.distribution = NSStackViewDistributionFillEqually;

    NSStackView *stack = [NSStackView stackViewWithViews:@[title, self.percentLabel, self.periodLabel, self.bar, self.resetLabel, self.tokenLabel, self.contextLabel, self.updatedLabel, buttons]];
    stack.orientation = NSUserInterfaceLayoutOrientationVertical;
    stack.alignment = NSLayoutAttributeLeading; stack.spacing = 8;
    stack.edgeInsets = NSEdgeInsetsMake(16, 16, 16, 16);
    stack.translatesAutoresizingMaskIntoConstraints = NO;

    NSViewController *controller = [NSViewController new];
    controller.view = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 320, 255)];
    [controller.view addSubview:stack];
    [NSLayoutConstraint activateConstraints:@[
        [stack.leadingAnchor constraintEqualToAnchor:controller.view.leadingAnchor],
        [stack.trailingAnchor constraintEqualToAnchor:controller.view.trailingAnchor],
        [stack.topAnchor constraintEqualToAnchor:controller.view.topAnchor],
        [self.bar.widthAnchor constraintEqualToConstant:288],
        [buttons.widthAnchor constraintEqualToConstant:288]
    ]];
    self.popover = [NSPopover new]; self.popover.contentViewController = controller;
    self.popover.behavior = NSPopoverBehaviorTransient;
}

- (void)openSettings:(id)sender { if(!self.settingsWindow)self.settingsWindow=[[UsageSettingsWindowController alloc]initWithService:UsageServiceCodex];[self.settingsWindow showWindow:nil];[NSApp activateIgnoringOtherApps:YES]; }
- (void)restartTimer { [self.timer invalidate];self.timer=nil;if(UsageSettingsStore.sharedStore.autoRefreshEnabled)self.timer=[NSTimer scheduledTimerWithTimeInterval:UsageSettingsStore.sharedStore.refreshInterval target:self selector:@selector(refresh) userInfo:nil repeats:YES]; }
- (void)settingsChanged:(NSNotification *)notification { if([notification.object isKindOfClass:NSString.class]&&[notification.object isEqualToString:NSBundle.mainBundle.bundleIdentifier])return;UsageApplyTheme();[self restartTimer]; [self buildPopover]; [self refresh]; }

- (void)togglePopover:(id)sender {
    if (self.popover.shown) [self.popover performClose:nil];
    else { if(UsageSettingsStore.sharedStore.refreshWhenOpened)[self refresh]; [self.popover showRelativeToRect:self.statusItem.button.bounds ofView:self.statusItem.button preferredEdge:NSRectEdgeMinY]; }
}

- (void)refresh {
    UsageSnapshot *snapshot=[self.provider currentSnapshot:nil];
    if (!snapshot.available) { self.statusItem.button.attributedTitle = CodexTitle(@"--%", NSColor.secondaryLabelColor);self.statusItem.button.accessibilityLabel=@"Codex使用率、データなし"; self.percentLabel.stringValue = @"データなし"; self.percentLabel.textColor = NSColor.secondaryLabelColor; self.periodLabel.stringValue = @"Codexでメッセージを送ると表示されます"; return; }
    double percent = snapshot.primaryPercent;
    self.bar.value = percent;
    self.statusItem.button.attributedTitle = CodexTitle(UsageMenuValue(percent), UsageColor(percent));
    self.statusItem.button.accessibilityLabel=[NSString stringWithFormat:@"Codex使用率%.0fパーセント、残り%.0fパーセント",percent,100-percent];
    self.percentLabel.stringValue = UsageSettingsStore.sharedStore.displayRemaining?[NSString stringWithFormat:@"%.0f%% 残り",100-percent]:[NSString stringWithFormat:@"%.0f%% 使用",percent];
    self.percentLabel.textColor = UsageColor(percent);
    NSInteger minutes = snapshot.windowMinutes;
    NSString *plan = snapshot.plan;
    NSString *duration = minutes % 10080 == 0 ? [NSString stringWithFormat:@"%ld週間", (long)(minutes / 10080)] : (minutes % 1440 == 0 ? [NSString stringWithFormat:@"%ld日間", (long)(minutes / 1440)] : [NSString stringWithFormat:@"%ld時間", (long)(minutes / 60)]);
    self.periodLabel.stringValue = [NSString stringWithFormat:@"%@・%@の利用枠", plan, duration];
    NSTimeInterval reset = snapshot.primaryReset;
    [self.notificationController evaluateUsedPercent:percent resetIdentifier:[NSString stringWithFormat:@"%.0f",reset]];
    self.resetLabel.stringValue = reset ? [NSString stringWithFormat:@"リセット: %@", [self formatted:[NSDate dateWithTimeIntervalSince1970:reset]]] : @"リセット時刻: --";
    long long total = snapshot.totalTokens;
    long long context = snapshot.contextWindow;
    self.tokenLabel.stringValue = [NSString stringWithFormat:@"累計トークン  %@", UsageFormattedInteger(total)];
    self.contextLabel.stringValue = [NSString stringWithFormat:@"現在の文脈    %.0f%%（上限 %@）", context ? 100.0 * total / context : 0, UsageFormattedInteger(context)];
    self.updatedLabel.stringValue = [NSString stringWithFormat:@"最終記録: %@", [self formatted:snapshot.updatedAt]];
}

- (NSString *)formatted:(NSDate *)date { return UsageFormattedDate(date,NO); }
@end

int main(void) {
    @autoreleasepool { NSApplication *app = NSApplication.sharedApplication; AppDelegate *delegate = [AppDelegate new]; app.delegate = delegate; [app run]; }
    return 0;
}
